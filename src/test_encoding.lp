% ============================================================
% Flatland Track Transitions (decoded from bitfield)
% ============================================================

% Type 1025  - Straight horizontal (E<->W)
transition(1025,  e, e).
transition(1025,  w, w).

% Type 32800 - Straight vertical (N<->S)
transition(32800, n, n).
transition(32800, s, s).

% Type 16386 - Curve: N->E, W->S
transition(16386, n, e).
transition(16386, w, s).

% Type 4608  - Curve: N->W, E->S
transition(4608,  n, w).
transition(4608,  e, s).

% Type 72    - Curve: S->E, W->N
transition(72,    s, e).
transition(72,    w, n).

% Type 2064  - Curve: E->N, S->W
transition(2064,  e, n).
transition(2064,  s, w).

% Type 1097  - Junction: E->E, S->E, W->N, W->W
transition(1097,  e, e).
transition(1097,  s, e).
transition(1097,  w, n).
transition(1097,  w, w).

% Type 3089  - Junction: E->N, E->E, S->W, W->W
transition(3089,  e, n).
transition(3089,  e, e).
transition(3089,  s, w).
transition(3089,  w, w).

% ============================================================
% Direction deltas
% ============================================================
delta(n,  0, -1).
delta(s,  0,  1).
delta(e,  1,  0).
delta(w, -1,  0).

% ============================================================
% Train movement
% ============================================================
time(0..H) :- global(H).

% Unpack start
at(Train, X, Y, Dir, 0) :- start(Train, (X,Y), 0, Dir).

% Move at each step
at(Train, NX, NY, NDir, T+1) :-
    at(Train, X, Y, Dir, T),
    time(T+1),
    cell((X,Y), Type),
    transition(Type, Dir, NDir),
    delta(NDir, DX, DY),
    NX = X + DX,
    NY = Y + DY.

% Train can wait (stay in place, keep orientation)
at(Train, X, Y, Dir, T+1) :-
    at(Train, X, Y, Dir, T),
    time(T+1).

% ============================================================
% Goal
% ============================================================
reached(Train, T) :- at(Train, X, Y, _, T), goal(Train, (X,Y), _).

:- train(Train), not reached(Train, _).

% ============================================================
% Output
% ============================================================
#show at/5.
#show reached/2.