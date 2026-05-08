global(10).

train(0). start(0,(0,0),0,e).    end(0,(0,2),20).    speed(0,1).

cell((0,0), 1025).
cell((0,1), 1025).
cell((0,2), 1025).

on(T,Cell,Time) :-
    train(T),
    start(T,Cell,Time,_).

on(T,(X,Y1),Time+1) :-
    on(T,(X,Y),Time),
    Y1 = Y + 1,
    cell((X,Y1),_).

reached(T) :-
    on(T,Cell,Time),
    end(T,Cell,MaxTime),
    Time <= MaxTime.

:- train(T), not reached(T).