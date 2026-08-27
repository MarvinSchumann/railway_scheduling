% Grand finale: 3 trains, 2 intermediate stops, couple -> split -> re-couple.
%
%   T0: S1 -> S2 -> G0        T1: S1 -> S2 -> G        T2: S1 -> G
%
% After S1 the line forks: T0+T1 stay on the main line to serve S2, while T2
% peels off onto a lower detour of similar length.  The detour rejoins the main
% line just before the goal, where T1 (past S2, past T0's exit) re-couples with
% T2 and they finish together.  Balanced lengths keep both trains still running
% when they share the goal, so the re-coupling episode actually exists.
%
%   row3:                              G0(3,8)
%                                       ^
%   row5: ..S1(5,4)=[e/s fork]= . =S2(5,7)=[e/n fork]=[merge]= . =G(5,11)
%                     |                                  ^
%   row6:             \__ detour: (6,5)=e=...=(6,9) up __/
%
global(26).

train(0). start(0,(5,1),0,e). stop(0,1,(5,4)). stop(0,2,(5,7)). end(0,(3,8),26).  speed(0,1).
train(1). start(1,(5,2),0,e). stop(1,1,(5,4)). stop(1,2,(5,7)). end(1,(5,11),26). speed(1,1).
train(2). start(2,(5,3),0,e). stop(2,1,(5,4)).                  end(2,(5,11),26). speed(2,1).

% ── main line (row 5) ─────────────────────────────────────────────────────────
cell((5,1),  1025).    % T0 start
cell((5,2),  1025).    % T1 start
cell((5,3),  1025).    % T2 start
cell((5,4),  1025).    % S1  (all three serve)
cell((5,5),  5633).    % fork: east (T0,T1 -> S2) OR south (T2 detour)
cell((5,6),  1025).
cell((5,7),  1025).    % S2  (T0,T1 serve)
cell((5,8),  3089).    % fork: north (T0 -> G0) OR east (T1 -> G)
cell((5,9),  17411).   % merge: T2 rejoins from the south
cell((5,10), 1025).
cell((5,11), 1025).    % G  (shared goal of T1 and T2)

% ── T0 branch north to its own goal G0 ────────────────────────────────────────
cell((4,8),  32800).
cell((3,8),  1025).    % G0 (T0 goal)

% ── T2 detour (row 6): south off the fork, east, back up into the merge ───────
cell((6,5),  72).      % curve  S -> E
cell((6,6),  1025).
cell((6,7),  1025).
cell((6,8),  1025).
cell((6,9),  2064).    % curve  E -> N
