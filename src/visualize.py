import clingo
import matplotlib.pyplot as plt
import matplotlib.patches as patches
import matplotlib.animation as animation
from collections import defaultdict

# ── 1. Solve ──────────────────────────────────────────────────────────────────

ctl = clingo.Control()
ctl.load("encoding.lp")
ctl.load("tracks.lp")
ctl.load("first_enviroment.lp")
ctl.ground([("base", [])])

optimal_model = None
with ctl.solve(yield_=True) as handle:
    for model in handle:
        optimal_model = model.symbols(shown=True)

if optimal_model is None:
    print("No solution found")
    exit()

# ── 2. Parse atoms ────────────────────────────────────────────────────────────

cells       = {}
train_steps = defaultdict(dict)
starts      = {}   # train_id -> (x, y)
ends        = {}   # train_id -> (x, y)
num_trains  = 0

for atom in optimal_model:
    if atom.name == "cell":
        coord = atom.arguments[0]
        x = coord.arguments[0].number
        y = coord.arguments[1].number
        track_type = atom.arguments[1].number
        if track_type != 0:
            cells[(x, y)] = track_type

    elif atom.name == "on":
        t    = atom.arguments[0].number
        x    = atom.arguments[1].number
        y    = atom.arguments[2].number
        time = atom.arguments[3].number
        train_steps[t][time] = (x, y)
        num_trains = max(num_trains, t + 1)

    elif atom.name == "start":
        t     = atom.arguments[0].number
        coord = atom.arguments[1]
        x     = coord.arguments[0].number
        y     = coord.arguments[1].number
        starts[t] = (x, y)

    elif atom.name == "end":
        t     = atom.arguments[0].number
        coord = atom.arguments[1]
        x     = coord.arguments[0].number
        y     = coord.arguments[1].number
        ends[t] = (x, y)

max_time = max(t for steps in train_steps.values() for t in steps)

# ── 3. Layout ─────────────────────────────────────────────────────────────────

all_x = [x for x, y in cells]
all_y = [y for x, y in cells]
min_x, max_x = min(all_x), max(all_x)
min_y, max_y = min(all_y), max(all_y)

CELL = 1.0
PAD  = 0.5

COLORS = ["#e94560", "#0f9b8e", "#f5a623", "#7b68ee", "#50c878"]

fig, ax = plt.subplots(figsize=(14, 4))
ax.set_aspect("equal")
ax.set_xlim(min_y - PAD, max_y + 1 + PAD)
ax.set_ylim(-max_x - 1 - PAD, -min_x + PAD)
ax.axis("off")
ax.set_facecolor("#1a1a2e")
fig.patch.set_facecolor("#1a1a2e")

# ── 4. Draw track cells ───────────────────────────────────────────────────────

for (x, y) in cells:
    rect = patches.FancyBboxPatch(
        (y, -x - CELL), CELL, CELL,
        boxstyle="round,pad=0.05",
        linewidth=0,
        facecolor="#3a3a5c",
    )
    ax.add_patch(rect)

# ── 5. Draw start and end markers ─────────────────────────────────────────────
# Multiple trains can share a cell, so group them and draw one pip per train.

start_cells = defaultdict(list)  # (x,y) -> [train_ids]
end_cells   = defaultdict(list)

for t in range(num_trains):
    if t in starts:
        start_cells[starts[t]].append(t)
    if t in ends:
        end_cells[ends[t]].append(t)

def draw_markers(cell_dict, symbol):
    """
    symbol = 'S' for start (top-left corner of cell),
             'E' for end   (top-right corner of cell).
    Each train gets a small colored square.
    """
    for (x, y), trains in cell_dict.items():
        n   = len(trains)
        cx  = y + (0.18 if symbol == "S" else 0.82)
        cy  = -x - 0.18
        for i, t in enumerate(trains):
            offset = i * 0.22
            color  = COLORS[t % len(COLORS)]
            sq = patches.FancyBboxPatch(
                (cx - 0.09, cy - offset - 0.28), 0.18, 0.18,
                boxstyle="round,pad=0.02",
                linewidth=1.2,
                edgecolor="white",
                facecolor=color,
                alpha=0.85,
                zorder=4,
            )
            ax.add_patch(sq)
            ax.text(
                cx, cy - offset - 0.19,
                symbol,
                ha="center", va="center",
                fontsize=5, fontweight="bold",
                color="white", zorder=5,
            )

draw_markers(start_cells, "S")
draw_markers(end_cells,   "E")

# ── 6. Train circles ─────────────────────────────────────────────────────────

train_circles = []
train_labels  = []

for t in range(num_trains):
    color = COLORS[t % len(COLORS)]
    x0, y0 = train_steps[t][0]
    circle = plt.Circle(
        (y0 + 0.5, -x0 - 0.5), 0.32,
        color=color, zorder=5
    )
    ax.add_patch(circle)
    label = ax.text(
        y0 + 0.5, -x0 - 0.5, str(t),
        ha="center", va="center",
        fontsize=8, fontweight="bold",
        color="white", zorder=6
    )
    train_circles.append(circle)
    train_labels.append(label)

time_text = ax.text(
    0.01, 0.97, "t = 0",
    transform=ax.transAxes,
    fontsize=11, color="white",
    va="top"
)

# ── 7. Animate ────────────────────────────────────────────────────────────────

def update(frame):
    time_text.set_text(f"t = {frame}")
    for t in range(num_trains):
        times = train_steps[t]
        actual_time = min(frame, max(times))
        x, y = times[actual_time]
        train_circles[t].center = (y + 0.5, -x - 0.5)
        train_labels[t].set_position((y + 0.5, -x - 0.5))
    return train_circles + train_labels + [time_text]

ani = animation.FuncAnimation(
    fig, update,
    frames=range(max_time + 1),
    interval=300,
    blit=True
)

plt.tight_layout()
plt.show()
