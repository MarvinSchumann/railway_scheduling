"""
Render a hand-authored Flatland `.lp` environment (clingo facts) as a GIF.

Unlike solve.py (which needs a pickled RailEnv), this builds a RailEnv straight
from the `cell/2`, `train/1`, `start/4`, `end/3` facts, solves it with the ASP
encoding in asp/params.py, and animates the resulting `on/5` state sequence.

Usage:
    python render_lp.py envs/lp/long_connect_environment.lp
"""
import os
import re
import sys
import time

import numpy as np
import clingo
import imageio.v2 as imageio
from PIL import Image, ImageDraw, ImageFont

from asp import params
from flatland.envs.rail_generators import (
    rail_from_grid_transition_map, RailGridTransitionMap, RailEnvTransitions)
from flatland.envs.line_generators import BaseLineGen
from flatland.envs.rail_env import RailEnv
from flatland.envs.observations import GlobalObsForRailEnv
from flatland.envs.rail_trainrun_data_structures import Waypoint
from flatland.envs.timetable_utils import Line
from flatland.core.grid.grid4 import Grid4TransitionsEnum
from flatland.utils.rendertools import RenderTool

DIR = {"n": 0, "e": 1, "s": 2, "w": 3}


def parse_lp(path):
    """Pull grid, agents and horizon out of a clingo facts file."""
    text = open(path).read()
    cells = {(int(r), int(c)): int(v)
             for r, c, v in re.findall(r"cell\(\((\d+),(\d+)\),\s*(\d+)\)", text)}
    starts = {int(i): ((int(r), int(c)), int(t), d)
              for i, r, c, t, d in re.findall(
                  r"start\((\d+),\((\d+),(\d+)\),(\d+),([nswe])\)", text)}
    ends = {int(i): (int(r), int(c))
            for i, r, c in re.findall(r"end\((\d+),\((\d+),(\d+)\)", text)}
    horizon = int(re.search(r"global\((\d+)\)", text).group(1))

    height = max(r for r, _ in cells) + 1
    width = max(c for _, c in cells) + 1
    grid = np.zeros((height, width), dtype=np.uint16)
    for (r, c), v in cells.items():
        grid[r, c] = v
    return grid, starts, ends, horizon, width, height


def solve(lp_path):
    """Run the encoding and return the on/5 timeline of the optimal model."""
    ctl = clingo.Control(["--opt-mode=optN"])
    for f in params.primary + params.secondary:
        ctl.load(f)
    ctl.load(lp_path)
    ctl.add("base", [], "#show on/5.")
    ctl.ground([("base", [])])

    best = {}
    with ctl.solve(yield_=True) as handle:
        for model in handle:
            if not model.optimality_proven and handle.get().unknown:
                pass
            positions = {}
            for atom in model.symbols(shown=True):
                if atom.name == "on":
                    tid, r, c, t, d = atom.arguments
                    positions[(tid.number, t.number)] = (
                        r.number, c.number, str(d))
            best = positions  # keep the latest (== best under optN)
    return best


class PlanLineGen(BaseLineGen):
    """Minimal line generator that seeds agents at their real start/target."""

    def __init__(self, starts, ends):
        super().__init__()
        self.starts, self.ends = starts, ends

    def generate(self, rail, num_agents, hints=None, num_resets=0, np_random=None):
        waypoints, speeds = {}, []
        for i in range(num_agents):
            (pos, _t, d) = self.starts[i]
            target = self.ends[i]
            waypoints[i] = [[Waypoint(pos, Grid4TransitionsEnum(DIR[d]))],
                            [Waypoint(target, None)]]
            speeds.append(1.0)
        return Line(agent_waypoints=waypoints, agent_speeds=speeds)


def build_env(grid, starts, ends, width, height, horizon):
    rgtm = RailGridTransitionMap(width=width, height=height,
                                 transitions=RailEnvTransitions(), grid=grid)
    env = RailEnv(width=width, height=height,
                  rail_generator=rail_from_grid_transition_map(rgtm),
                  line_generator=PlanLineGen(starts, ends),
                  number_of_agents=len(starts),
                  obs_builder_object=GlobalObsForRailEnv(),
                  remove_agents_at_target=True)
    env.reset()
    env._max_episode_steps = horizon
    return env


def render(lp_path):
    grid, starts, ends, horizon, width, height = parse_lp(lp_path)
    plan = solve(lp_path)
    if not plan:
        print("UNSATISFIABLE — no plan to render.")
        return

    env = build_env(grid, starts, ends, width, height, horizon)
    last_t = max(t for _, t in plan)

    os.makedirs("tmp/frames", exist_ok=True)
    rt = RenderTool(env, gl="PILSVG")
    images = []
    for t in range(0, last_t + 1):
        for i, agent in enumerate(env.agents):
            if (i, t) in plan:
                r, c, d = plan[(i, t)]
                agent.current_configuration = ((r, c), DIR[d])
            else:
                agent.current_configuration = None  # off map (arrived / not departed)
        rt.reset()
        rt.render_env(show=False, show_observations=False, show_predictions=False)
        fn = f"tmp/frames/lp_frame_{t:04d}.png"
        rt.gl.save_image(fn)

        with Image.open(fn) as img:
            draw = ImageDraw.Draw(img)
            fs = int(min(img.width, img.height) * 0.10)
            try:
                font = ImageFont.truetype("modules/LiberationMono-Regular.ttf", fs)
            except IOError:
                font = ImageFont.load_default()
            box = font.getbbox(str(t))
            pos = (img.width - (box[2] - box[0]) - 10, 10)
            for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1), (-1, -1), (-1, 1), (1, -1), (1, 1)]:
                draw.text((pos[0] + dx, pos[1] + dy), str(t), fill="black", font=font)
            draw.text(pos, str(t), fill="red", font=font)
            img.save(fn)
        images.append(imageio.imread(fn))

    stamp = time.time()
    out = f"output/{stamp}"
    os.makedirs(out, exist_ok=True)
    imageio.mimsave(f"{out}/animation.gif", images, format="GIF", loop=0, duration=400)
    print(f"wrote {out}/animation.gif  ({len(images)} frames)")


if __name__ == "__main__":
    render(sys.argv[1])
