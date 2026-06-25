% ── Coupling demo environment (action-based, Flatland framework fact format) ──
%
% Two trains head for the SAME goal (1,4) from different directions and funnel
% through the junction cell (1,2). One waits for the other at the junction,
% then follows directly behind it to the goal — a convoy, not a merge.
%
% Coordinates are (row, col); cell/2 carries the raw Flatland transition bitmap.

global(30).

train(0). start(0,(1,1),0,e). end(0,(1,4),30). speed(0,1).
train(1). start(1,(0,2),0,s). end(1,(1,4),30). speed(1,1).

cell((0,2), 32800).   % vertical straight (train 1's approach from the north)
cell((1,1), 1025).    % horizontal straight (train 0's approach from the west)
cell((1,2), 33897).   % single-slip junction: (e,f) for train 0, (s,l) for train 1
cell((1,3), 1025).
cell((1,4), 1025).    % shared goal
