% Simple test case with 2 trains on straight tracks

% Environment definition
global(20).

% Train definitions
train(0).
train(1).

% Start positions and times
start(0, (0,0), 0, e).
start(1, (0,2), 0, e).

% Goal positions and max times
end(0, (0,5), 20).
end(1, (0,5), 20).

% Track cells (simple horizontal straight track)
cell((0,0), 1025).
cell((0,1), 1025).
cell((0,2), 1025).
cell((0,3), 1025).
cell((0,4), 1025).
cell((0,5), 1025).

cell((1,0), 1025).
cell((1,1), 1025).
cell((1,2), 1025).
cell((1,3), 1025).
cell((1,4), 1025).
cell((1,5), 1025).

cell((2,0), 1025).
cell((2,1), 1025).
cell((2,2), 1025).
cell((2,3), 1025).
cell((2,4), 1025).
cell((2,5), 1025).

