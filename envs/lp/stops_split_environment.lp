% Coupling WITH intermediate stops: two trains share a stop, then split.
%
%   T1: (2,5) --s-\                                          goal_A (5,12)
%                  v                             /--e-- . -- . -- E0
%   T0: (5,2) =e==[1097]== . == . ==[X:(5,8)]==[5633]
%                  merge      shared approach     fork \--s
%                                                        v
%                                                   . . . E1  goal_B (8,9)
%
% Both trains must serve the intermediate stop X = (5,8), so they COUPLE on the
% shared approach into X.  After X their routes fork (train 0 east to (5,12),
% train 1 south to (8,9)) -> their next targets differ -> they UNCOUPLE at X.

global(30).

train(0). start(0,(5,2),0,e). stop(0,1,(5,8)). end(0,(5,12),30). speed(0,1).
train(1). start(1,(2,5),0,s). stop(1,1,(5,8)). end(1,(8,9),30).  speed(1,1).

% ── shared trunk / approach (row 5) ───────────────────────────────────────────
cell((5,2),  1025).
cell((5,3),  1025).
cell((5,4),  1025).
cell((5,5),  1097).    % north merge: train 1 comes down col 5 and joins eastbound
cell((5,6),  1025).
cell((5,7),  1025).
cell((5,8),  1025).    % X = shared intermediate stop
cell((5,9),  5633).    % fork: continue east (train 0) OR turn south (train 1)
cell((5,10), 1025).
cell((5,11), 1025).
cell((5,12), 1025).    % goal_A (train 0)

% ── north branch feeding the merge (train 1's approach, col 5) ────────────────
cell((2,5),  32800).
cell((3,5),  32800).
cell((4,5),  32800).

% ── south branch after the fork (train 1's exit, col 9) ───────────────────────
cell((6,9),  32800).
cell((7,9),  32800).
cell((8,9),  32800).   % goal_B (train 1)
