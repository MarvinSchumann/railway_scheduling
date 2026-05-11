#!/usr/bin/env python3
"""
Track Visualizer — reads tracks.lp and draws each track type
using its connects/5 rules.

Usage:
    python visualize_tracks.py [path/to/tracks.lp]

Defaults to "tracks.lp" in the current directory.
"""

import re
import sys
import math
import tkinter as tk
from tkinter import ttk
from collections import defaultdict

# ── colour palette ────────────────────────────────────────────────────────────
BG          = "#1e1e2e"
PANEL_BG    = "#2a2a3e"
TILE_BG     = "#16213e"
RAIL_COLOR  = "#c0a060"
RAIL_SHADOW = "#7a6030"
SLEEPER_COL = "#5a4030"
ARROW_COL   = "#60d0ff"
TEXT_FG     = "#e0e0f0"
LABEL_FG    = "#a0a0c0"
BORDER_COL  = "#3a3a5a"
HIGHLIGHT   = "#ff6b6b"

# ── direction helpers ─────────────────────────────────────────────────────────
DIR_ANGLE = {"n": 270, "e": 0, "s": 90, "w": 180}   # degrees (SVG / canvas)
DIR_VEC   = {"n": (0, -1), "e": (1, 0), "s": (0, 1), "w": (-1, 0)}

TRACK_TYPE_NAMES = {
    0: "No track",
    1: "Straight track",
    2: "Simple switch",
    3: "Diamond crossing",
    4: "Single-slip switch",
    5: "Double-slip switch",
    6: "Symmetrical switch",
    7: "Dead end",
}

# ── parser ────────────────────────────────────────────────────────────────────

def parse_lp(path: str):
    """
    Return:
      tracks      : {track_id: [(from_dir, dr, dc, to_dir), ...]}
      ordered_ids : track IDs in the order they first appear in the file
    """
    pattern = re.compile(
        r"connects\(\s*(\d+)\s*,\s*([nsew])\s*,\s*(-?\d+)\s*,\s*(-?\d+)\s*,\s*([nsew])\s*\)"
    )
    tracks: dict[int, list[tuple]] = defaultdict(list)
    ordered_ids: list[int] = []
    with open(path) as fh:
        for line in fh:
            line = line.split("%")[0]
            for m in pattern.finditer(line):
                tid  = int(m.group(1))
                fdir = m.group(2)
                dr   = int(m.group(3))
                dc   = int(m.group(4))
                tdir = m.group(5)
                if tid not in tracks:
                    ordered_ids.append(tid)
                tracks[tid].append((fdir, dr, dc, tdir))
    return dict(tracks), ordered_ids


def infer_track_type(tid: int, connections: list) -> int:
    """Best-effort mapping from numeric id → track type 0-7 using the PDF table."""
    type_ids = {
        0:  {0},
        1:  {32800, 1025, 4608, 16386, 72, 2064},
        2:  {37408, 17411, 32872, 3089, 49186, 1097, 34864, 5633},
        3:  {33825},
        4:  {38433, 50211, 33897, 35889},
        5:  {38505, 52275},
        6:  {20994, 16458, 2136, 6672},
        7:  {8192, 4, 128, 256},
    }
    for t, ids in type_ids.items():
        if tid in ids:
            return t
    return -1   # unknown


# ── canvas drawing ────────────────────────────────────────────────────────────

SIZE   = 160        # canvas pixels per tile
HALF   = SIZE // 2
RAIL_W = 10         # rail half-width in pixels
SLEEP_W = 18        # sleeper half-length
SLEEP_H = 5
SLEEP_GAP = 18


def angle_rad(d: str) -> float:
    return math.radians(DIR_ANGLE[d])


def edge_point(d: str, frac: float = 1.0):
    """Canvas (x, y) at fraction `frac` along the edge for direction d."""
    ang = angle_rad(d)
    return (HALF + frac * HALF * math.cos(ang),
            HALF + frac * HALF * math.sin(ang))


def draw_rail_line(canvas, x1, y1, x2, y2):
    """Draw a pair of parallel rails along the given spine."""
    dx, dy = x2 - x1, y2 - y1
    length = math.hypot(dx, dy) or 1
    nx, ny = -dy / length, dx / length   # normal
    for sign in (-1, 1):
        ox, oy = sign * RAIL_W * nx, sign * RAIL_W * ny
        canvas.create_line(x1 + ox, y1 + oy, x2 + ox, y2 + oy,
                           fill=RAIL_SHADOW, width=3)
        canvas.create_line(x1 + ox, y1 + oy, x2 + ox, y2 + oy,
                           fill=RAIL_COLOR, width=2)
    # sleepers
    steps = max(3, int(length / SLEEP_GAP))
    for i in range(steps + 1):
        t = i / steps
        mx, my = x1 + t * dx, y1 + t * dy
        sx, sy = SLEEP_W * nx, SLEEP_W * ny
        canvas.create_line(mx - sx, my - sy, mx + sx, my + sy,
                           fill=SLEEPER_COL, width=SLEEP_H)


def draw_rail_curve(canvas, entry_face: str, exit_face: str, n_seg: int = 24):
    """
    Draw a proper 90-degree circular arc between two adjacent faces.
    The arc centre is the shared corner of the two faces; radius = HALF.
    Two parallel rails + sleepers are drawn, just like draw_rail_line.
    """
    # Shared corner (arc centre) for each face pair
    arc_centre = {
        ("n", "e"): (SIZE, 0),    ("e", "n"): (SIZE, 0),
        ("n", "w"): (0,    0),    ("w", "n"): (0,    0),
        ("s", "e"): (SIZE, SIZE), ("e", "s"): (SIZE, SIZE),
        ("s", "w"): (0,  SIZE),   ("w", "s"): (0,  SIZE),
    }
    cx, cy = arc_centre[(entry_face, exit_face)]
    R = HALF  # radius from corner to face midpoint

    # Compute start/end angles from arc centre to each face midpoint
    p1 = edge_point(entry_face)
    p2 = edge_point(exit_face)
    a1 = math.atan2(p1[1] - cy, p1[0] - cx)
    a2 = math.atan2(p2[1] - cy, p2[0] - cx)

    # Always sweep the short way (90 degrees inward)
    diff = (a2 - a1 + math.pi) % (2 * math.pi) - math.pi
    angles = [a1 + diff * i / n_seg for i in range(n_seg + 1)]

    def arc_pts(r_off):
        return [(cx + (R + r_off) * math.cos(a),
                 cy + (R + r_off) * math.sin(a)) for a in angles]

    # Two rails offset inward/outward from the arc spine
    for r_off in (-RAIL_W, +RAIL_W):
        pts = arc_pts(r_off)
        for i in range(len(pts) - 1):
            canvas.create_line(pts[i][0], pts[i][1], pts[i+1][0], pts[i+1][1],
                               fill=RAIL_SHADOW, width=3)
            canvas.create_line(pts[i][0], pts[i][1], pts[i+1][0], pts[i+1][1],
                               fill=RAIL_COLOR, width=2)

    # Sleepers across the arc spine
    spine = arc_pts(0)
    for i in range(0, len(spine) - 1, 3):
        ax, ay = spine[i]
        # normal at this point = radial direction outward from centre
        nr = math.atan2(ay - cy, ax - cx)
        nx, ny = math.cos(nr), math.sin(nr)
        canvas.create_line(ax - SLEEP_W * nx, ay - SLEEP_W * ny,
                           ax + SLEEP_W * nx, ay + SLEEP_W * ny,
                           fill=SLEEPER_COL, width=SLEEP_H)


OPPOSITE = {"n": "s", "s": "n", "e": "w", "w": "e"}


def is_straight(d1: str, d2: str) -> bool:
    return OPPOSITE.get(d1) == d2


def draw_connection(canvas, entry_dir: str, to_dir: str):
    """
    entry_dir = travel direction entering this tile  (e.g. 'n' = moving north)
    to_dir    = travel direction entering the neighbour = exit face of this tile

    entry_face = OPPOSITE[entry_dir]  (the face the train came through)
    exit_face  = to_dir               (the face the train exits through)
    """
    entry_face = OPPOSITE[entry_dir]
    exit_face  = to_dir
    if is_straight(entry_face, exit_face):
        p1 = edge_point(entry_face)
        p2 = edge_point(exit_face)
        draw_rail_line(canvas, *p1, *p2)
    else:
        draw_rail_curve(canvas, entry_face, exit_face)


def draw_arrows(canvas, connections):
    """Draw a cyan inward arrow on every entry face."""
    seen = set()
    for (entry_dir, dr, dc, tdir) in connections:
        entry_face = OPPOSITE[entry_dir]   # actual face the train enters through
        if entry_face in seen:
            continue
        seen.add(entry_face)
        x, y  = edge_point(entry_face, 0.78)
        # arrow points inward = opposite of the face normal
        ang   = angle_rad(entry_face) + math.pi
        alen  = 14
        ax, ay = x + alen * math.cos(ang), y + alen * math.sin(ang)
        canvas.create_line(x, y, ax, ay, fill=ARROW_COL, width=2,
                           arrow=tk.LAST, arrowshape=(8, 10, 4))
        lx = x + 20 * math.cos(angle_rad(entry_face))
        ly = y + 20 * math.sin(angle_rad(entry_face))
        canvas.create_text(lx, ly, text=entry_face.upper(),
                           fill=ARROW_COL, font=("Courier", 9, "bold"))


def draw_track_tile(canvas, connections):
    """Render one track tile onto `canvas`."""
    canvas.config(bg=TILE_BG)
    canvas.create_oval(10, 10, SIZE-10, SIZE-10, outline=BORDER_COL, width=1)

    # Deduplicate: (entry, to_dir) and its reverse (opposite(to_dir), opposite(entry))
    # represent the same physical rail segment — draw it once.
    drawn: set[tuple[str, str]] = set()
    for (entry_dir, dr, dc, to_dir) in connections:
        entry_face = OPPOSITE[entry_dir]
        exit_face  = to_dir
        canon = tuple(sorted([entry_face, exit_face]))
        if canon in drawn:
            continue
        drawn.add(canon)
        draw_connection(canvas, entry_dir, to_dir)

    draw_arrows(canvas, connections)
    canvas.create_oval(HALF-4, HALF-4, HALF+4, HALF+4,
                       fill=BORDER_COL, outline="")


# ── GUI ───────────────────────────────────────────────────────────────────────

class TrackViewer(tk.Tk):
    def __init__(self, tracks: dict, ordered_ids: list):
        super().__init__()
        self.title("Track Visualizer — tracks.lp")
        self.configure(bg=BG)
        self.resizable(True, True)
        self.tracks = tracks
        self.ordered_ids = ordered_ids
        self._build_ui()

    def _build_ui(self):
        # ── header ──
        hdr = tk.Frame(self, bg=BG)
        hdr.pack(fill="x", padx=20, pady=(16, 4))
        tk.Label(hdr, text="Track Visualizer", bg=BG, fg=TEXT_FG,
                 font=("Helvetica", 18, "bold")).pack(side="left")
        tk.Label(hdr, text=f"  {len(self.tracks)} track types loaded",
                 bg=BG, fg=LABEL_FG, font=("Helvetica", 11)).pack(side="left", pady=4)

        # ── scrollable canvas area ──
        outer = tk.Frame(self, bg=BG)
        outer.pack(fill="both", expand=True, padx=12, pady=8)

        vsb = ttk.Scrollbar(outer, orient="vertical")
        vsb.pack(side="right", fill="y")
        hsb = ttk.Scrollbar(outer, orient="horizontal")
        hsb.pack(side="bottom", fill="x")

        self.scroll_canvas = tk.Canvas(outer, bg=BG, highlightthickness=0,
                                       yscrollcommand=vsb.set,
                                       xscrollcommand=hsb.set)
        self.scroll_canvas.pack(fill="both", expand=True)
        vsb.config(command=self.scroll_canvas.yview)
        hsb.config(command=self.scroll_canvas.xview)

        self.inner = tk.Frame(self.scroll_canvas, bg=BG)
        self.scroll_canvas.create_window((0, 0), window=self.inner, anchor="nw")
        self.inner.bind("<Configure>",
                        lambda e: self.scroll_canvas.configure(
                            scrollregion=self.scroll_canvas.bbox("all")))

        # mousewheel scroll
        self.scroll_canvas.bind_all("<MouseWheel>",
            lambda e: self.scroll_canvas.yview_scroll(-1*(e.delta//120), "units"))

        self._populate()

    def _populate(self):
        # Group by track type, preserving the file order within each group.
        # Also preserve the order in which track types first appear in the file.
        groups: dict[int, list] = defaultdict(list)
        type_order: list[int] = []
        for tid in self.ordered_ids:
            conns = self.tracks[tid]
            ttype = infer_track_type(tid, conns)
            if ttype not in groups:
                type_order.append(ttype)
            groups[ttype].append((tid, conns))

        COLS = 4

        for ttype in type_order:
            items = groups[ttype]
            type_name = TRACK_TYPE_NAMES.get(ttype, f"Unknown type {ttype}")

            # group header
            gh = tk.Frame(self.inner, bg=BG)
            gh.pack(fill="x", padx=8, pady=(18, 4))
            tk.Label(gh,
                     text=f"  Track Type #{ttype}  —  {type_name}",
                     bg=PANEL_BG, fg=TEXT_FG,
                     font=("Helvetica", 13, "bold"),
                     padx=10, pady=6).pack(fill="x")

            # tile grid
            grid = tk.Frame(self.inner, bg=BG)
            grid.pack(fill="x", padx=16, pady=4)

            for idx, (tid, conns) in enumerate(items):
                col = idx % COLS
                row = idx // COLS

                cell = tk.Frame(grid, bg=PANEL_BG,
                                bd=0, relief="flat",
                                highlightthickness=1,
                                highlightbackground=BORDER_COL)
                cell.grid(row=row, column=col, padx=8, pady=8, sticky="n")

                # track canvas
                c = tk.Canvas(cell, width=SIZE, height=SIZE,
                               bg=TILE_BG, highlightthickness=0)
                c.pack(padx=6, pady=6)
                draw_track_tile(c, conns)

                # ID label
                tk.Label(cell, text=f"ID: {tid}",
                         bg=PANEL_BG, fg=HIGHLIGHT,
                         font=("Courier", 10, "bold")).pack()

                # connection list
                conn_frame = tk.Frame(cell, bg=PANEL_BG)
                conn_frame.pack(padx=6, pady=(0, 6))
                for (fdir, dr, dc, tdir) in conns:
                    txt = f"{fdir.upper()} → ({dr:+},{dc:+}) → {tdir.upper()}"
                    tk.Label(conn_frame, text=txt,
                             bg=PANEL_BG, fg=LABEL_FG,
                             font=("Courier", 8)).pack(anchor="w")

        # unknown group label if any
        if -1 in groups:
            tk.Label(self.inner, text="⚠  Unrecognised IDs (not in PDF table)",
                     bg=BG, fg=HIGHLIGHT, font=("Helvetica", 11)).pack(
                         anchor="w", padx=16, pady=(12, 0))


# ── entry point ───────────────────────────────────────────────────────────────

def main():
    path = sys.argv[1] if len(sys.argv) > 1 else "tracks.lp"
    try:
        tracks, ordered_ids = parse_lp(path)
    except FileNotFoundError:
        print(f"Error: cannot open '{path}'")
        sys.exit(1)

    if not tracks:
        print("No connects/5 facts found — check the file path / format.")
        sys.exit(1)

    print(f"Loaded {len(tracks)} track IDs from '{path}'")
    for tid in ordered_ids:
        conns = tracks[tid]
        ttype = infer_track_type(tid, conns)
        name  = TRACK_TYPE_NAMES.get(ttype, "unknown")
        print(f"  {tid:6d}  type={ttype}  ({name})  {len(conns)} connection(s)")

    app = TrackViewer(tracks, ordered_ids)
    app.mainloop()


if __name__ == "__main__":
    main()