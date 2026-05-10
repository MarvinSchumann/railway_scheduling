global(10).

train(0). start(0,(0,0),0,e).    end(0,(0,2),20).    speed(0,1).

%track definition
cell((0,0), 1025).
cell((0,1), 1025).
cell((0,2), 1025).

%=============================================================
%track logic
connects(1025, e,  0,  1, e).       % type 1025: straight horizontal track
connects(1025, w,  0,  -1, w).      %  -||-
connects(32800, n,  -1, 0, n).      % type 32800: straight vertical track
connects(32800, s,  1, 0, s).       %  -||-

connects(4608, e, -1, 0, s).        % type 4608: curve N->W, E->S
connects(4608, n, 0, -1, w).        %  -||-

connects(16386, n, 0, 1, e).        % type 16386: curve N->E, W->S
connects(16386, w, 1, 0, s).        %  -||-

connects(72, s, 0, 1, e).           % type 72: curve S->E, W->N
connects(72, w, -1, 0, n).          %  -||-

connects(2064, e, -1, 0, n).        % type 2064: curve E->N, S->W
connects(2064, s, 0, -1, w).        %  -||-




%=============================================================

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