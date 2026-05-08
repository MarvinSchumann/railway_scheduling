global(10).

train(0). start(0,(0,0),0,e).    end(0,(0,2),20).    speed(0,1).

% straight horizontal track (E<->W)
cell((0,0), 1025).
cell((0,1), 1025).
cell((0,2), 1025).
transition(1025, e, e).

delta(e, 1, 0).

time(0..H) :- global(H).

at(Train, X, Y, Dir, 0) :- start(Train, (X,Y), 0, Dir).

at(Train, NX, NY, NDir, T+1) :-
    at(Train, X, Y, Dir, T),
    time(T+1),
    cell((X,Y), Type),
    transition(Type, Dir, NDir),
    delta(NDir, DX, DY),
    NX = X + DX,
    NY = Y + DY.

#show at/5.