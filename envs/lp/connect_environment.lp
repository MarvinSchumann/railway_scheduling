% Test environment for coupling (see encoding_connect.lp).
%
% Two trains approach a junction from different directions (one from the top
% row, one from the bottom row), both heading for the SAME goal. They cannot
% both take the junction cell at once, so one WAITS for the other, then follows
% directly behind it as a convoy to the goal — they never merge.
%
%        col:   0     1     2     3     4     5
%   row 0:    T0 --- . --- \
%   row 1:                  J --- . --- . --- E   (shared goal)
%   row 2:    T1 --- . --- /
%
%   J = (1,2) symmetrical junction: accepts a train from above (s->e) and a
%       train from below (n->e), both leaving eastbound.

global(20).

% Both trains share the same goal (1,5) -> they are allowed to couple.
train(0). start(0,(0,0),0,e). end(0,(1,9),20). speed(0,1).
train(1). start(1,(2,2),0,e). end(1,(1,9),20). speed(1,1).

% ── track layout ──────────────────────────────────────────────────────────────
% top approach (row 0)
cell((0,0), 1025). 
cell((0,1), 1025).
cell((0,2), 1025).
cell((0,3), 1025).
cell((0,4), 4608).    % curve E -> S (down toward the junction)

% junction + shared eastbound line (row 1)
cell((1,4), 16458).   % vertical symmetrical switch: (s->e) and (n->e)
cell((1,5), 1025).
cell((1,6), 1025).
cell((1,7), 1025).  
cell((1,8), 1025).
cell((1,9), 1025).  % shared goal

% bottom approach (row 2)
cell((2,2), 1025).
cell((2,3), 1025).
cell((2,4), 2064).    % curve E -> N (up toward the junction)
