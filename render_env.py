"""
Render the STATIC layout of a hand-authored Flatland `.lp` (no solving):
the rail grid plus every train's start (S), ordered intermediate stops (1,2,..)
and goal (G), so infeasible routes can be inspected visually.

Usage:
    python render_env.py envs/lp/final_test_env.lp
"""
import os
import re
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

from render_lp import parse_lp, build_env, DIR
from flatland.utils.rendertools import RenderTool

TRAIN_COLORS = [(220, 30, 30), (30, 90, 220), (20, 160, 60), (230, 140, 0),
                (150, 30, 200), (0, 160, 170)]


def parse_stops(path):
    text = open(path).read()
    stops = {}
    for i, k, r, c in re.findall(r"stop\((\d+),(\d+),\((\d+),(\d+)\)\)", text):
        stops.setdefault(int(i), []).append((int(k), (int(r), int(c))))
    for i in stops:
        stops[i] = [cell for _, cell in sorted(stops[i])]
    return stops


def render(lp_path):
    grid, starts, ends, horizon, width, height = parse_lp(lp_path)
    stops = parse_stops(lp_path)

    env = build_env(grid, starts, ends, width, height, horizon)
    rt = RenderTool(env, gl="PILSVG")
    rt.reset()
    rt.render_env(show=False, show_observations=False, show_predictions=False)
    os.makedirs("tmp/frames", exist_ok=True)
    fn = "tmp/frames/env_layout.png"
    rt.gl.save_image(fn)

    img = Image.open(fn).convert("RGB")
    draw = ImageDraw.Draw(img)
    tile = img.width / width          # pixels per cell
    r = max(6, int(tile * 0.28))
    try:
        font = ImageFont.truetype("modules/LiberationMono-Regular.ttf", int(tile * 0.4))
    except IOError:
        font = ImageFont.load_default()

    def center(cell):
        row, col = cell
        return (col * tile + tile / 2, row * tile + tile / 2)

    def dot(cell, color, label):
        x, y = center(cell)
        draw.ellipse([x - r, y - r, x + r, y + r], fill=color, outline="white", width=2)
        w = draw.textlength(label, font=font)
        draw.text((x - w / 2, y - r * 0.85), label, fill="white", font=font)

    for i in sorted(starts):
        color = TRAIN_COLORS[i % len(TRAIN_COLORS)]
        route = [starts[i][0]] + stops.get(i, []) + [ends[i]]
        # thin line through the ordered waypoints
        pts = [center(c) for c in route]
        draw.line(pts, fill=color, width=2)
        dot(starts[i][0], color, "S%d" % i)
        for k, cell in enumerate(stops.get(i, []), start=1):
            dot(cell, color, str(k))
        dot(ends[i], color, "G%d" % i)

    img.save(fn)
    print(f"wrote {fn}  ({width}x{height} grid, {len(starts)} trains)")
    for i in sorted(starts):
        route = [starts[i][0]] + stops.get(i, []) + [ends[i]]
        print(f"  train {i}: " + " -> ".join(str(c) for c in route))


if __name__ == "__main__":
    render(sys.argv[1])
