% Bigger coupling test: THREE trains, one shared goal, one convoy.
%
% An eastbound trunk (row 5) runs to the shared goal (5,20). Three trains reach
% it from three different places and must line up into a single convoy:
%
%   T1:  (1,2) ---e--->  . . .  ---\                (top branch, curves down)
%                                   v
%   T0:  (5,2) ===e===============[1097]==========[17411]=======> (5,20)  GOAL
%                                                    ^
%   T2:  (9,2) ---e--->  . . . . .  ---/            (bottom branch, curves up)
%
%   [1097]  = (5,6)  simple switch: merges a train coming down from the north
%   [17411] = (5,10) simple switch: merges a train coming up from the south
%   both also pass straight-through eastbound trunk traffic.
%
% All three share goal (5,20) -> convoy_compatible -> they form a 3-chain.

global(50).

train(0). start(0,(5,2),0,e). end(0,(5,20),50). speed(0,1).
train(1). start(1,(1,2),0,e). end(1,(5,20),50). speed(1,1).
train(2). start(2,(9,2),0,e). end(2,(5,20),50). speed(2,1).

% ── trunk (row 5), eastbound to the goal ──────────────────────────────────────
cell((5,2),  1025).
cell((5,3),  1025).
cell((5,4),  1025).
cell((5,5),  1025).
cell((5,6),  1097).    % north merge (down-branch joins here)
cell((5,7),  1025).
cell((5,8),  1025).
cell((5,9),  1025).
cell((5,10), 17411).   % south merge (up-branch joins here)
cell((5,11), 1025).
cell((5,12), 1025).
cell((5,13), 1025).
cell((5,14), 1025).
cell((5,15), 1025).
cell((5,16), 1025).
cell((5,17), 1025).
cell((5,18), 1025).
cell((5,19), 1025).
cell((5,20), 1025).    % shared goal

% ── top branch (train 1): east along row 1, curve down col 6, into the merge ──
cell((1,2),  1025).
cell((1,3),  1025).
cell((1,4),  1025).
cell((1,5),  1025).
cell((1,6),  4608).    % curve  E -> S  (heading east, bends south)
cell((2,6),  32800).
cell((3,6),  32800).
cell((4,6),  32800).

% ── bottom branch (train 2): east along row 9, curve up col 10, into the merge ─
cell((9,2),  1025).
cell((9,3),  1025).
cell((9,4),  1025).
cell((9,5),  1025).
cell((9,6),  1025).
cell((9,7),  1025).
cell((9,8),  1025).
cell((9,9),  1025).
cell((9,10), 2064).    % curve  E -> N  (heading east, bends north)
cell((8,10), 32800).
cell((7,10), 32800).
cell((6,10), 32800).
