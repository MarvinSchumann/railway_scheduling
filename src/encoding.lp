% Time domain
time(0..T) :- global(T).

% Directions
dir(n; e; s; w).

% Initial position
pos(Train, X, Y, 0) :-
    start(Train, (X,Y), 0, _).

% Neighbor relation (grid movement)
next((X,Y), n, (X,Y1)) :- Y1 = Y-1.
next((X,Y), s, (X,Y1)) :- Y1 = Y+1.
next((X,Y), e, (X1,Y)) :- X1 = X+1.
next((X,Y), w, (X1,Y)) :- X1 = X-1.

% Movement (very simple, no track constraints yet)
pos(T, X2, Y2, Time+1) :-
    pos(T, X1, Y1, Time),
    next((X1,Y1), D, (X2,Y2)),
    time(Time), time(Time+1).

% Each train has exactly one position at each time
1 { pos(T, X, Y, Time) : cell((X,Y), _) } 1 :-
    train(T), time(Time).

% Prevent two trains occupying the same cell
:- pos(T1, X, Y, Time),
   pos(T2, X, Y, Time),
   T1 != T2.

% Prevent head-on swap collisions
:- pos(T1, X1, Y1, Time),
   pos(T2, X2, Y2, Time),
   pos(T1, X2, Y2, Time+1),
   pos(T2, X1, Y1, Time+1),
   T1 != T2.

% Goal condition 
reached(T) :-
    pos(T, X, Y, Time),
    end(T, (X,Y), _, _).

:- train(T), not reached(T).