% make a train start on starting position
on(T, X, Y, Time, Orient) :-
    train(T),
    start(T, (X,Y), Time, Orient).

% train is active until it first arrives
active(T, Time) :-
    on(T, _, _, Time, _),
    not first_arrival(T, Time).

active(T, Time) :-
    first_arrival(T, ArrTime),
    on(T, _, _, Time, _),
    Time < ArrTime.

% only move active trains
{ on(T, NX, NY, Time+1, NewOrient) :
    connects(TrackType, Orient, DX, DY, NewOrient),
    NX = X + DX, NY = Y + DY, cell((NX,NY), _)
; on(T, X, Y, Time+1, Orient) } = 1 :-
    on(T, X, Y, Time, Orient),
    cell((X,Y), TrackType),
    global(Max),
    Time < Max,
    active(T, Time).

% define what it means to reach a goal
reached(T) :-
    on(T, X, Y, Time, _),
    end(T, (X,Y), MaxTime),
    Time <= MaxTime.

% first arrival: at goal but wasn't there the step before
first_arrival(T, Time) :-
    on(T, X, Y, Time, _),
    end(T, (X,Y), _),
    not on(T, X, Y, Time-1, _).

% simulation done when all trains have arrived
all_done(Time) :-
    Time = #max { A : first_arrival(_, A) },
    NTrains = #count { T : train(T) },
    NArrived = #count { T : first_arrival(T, _) },
    NTrains = NArrived.

% make sure every train reaches its goal
:- train(T), not reached(T).

#minimize { Time@1, T : first_arrival(T, Time) }.