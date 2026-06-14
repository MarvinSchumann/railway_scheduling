% ==============================================================================
% ORIGINAL LOGIC: INITIALIZATION & STATE DEFINITIONS
% ==============================================================================

% Make a train start on starting position
on(T, X, Y, Time, Orient) :-
    train(T),
    start(T, (X,Y), Time, Orient).

% Helper: train was already at its goal the previous step
was_at_goal(T, Time) :-
    on(T, X, Y, Time, _),
    end(T, (X,Y), _),
    on(T, X, Y, Time-1, _).

% First arrival: at goal but wasn't there the step before
first_arrival(T, Time) :-
    on(T, X, Y, Time, _),
    end(T, (X,Y), _),
    not was_at_goal(T, Time).

% Train is active until it first arrives
active(T, Time) :-
    on(T, _, _, Time, _),
    not first_arrival(T, Time).

% Only move active trains (standard movement — every train, leader or follower,
% picks its own legal move or stays put).
{ on(T, NX, NY, Time+1, NewOrient) :
    connects(TrackType, Orient, DX, DY, NewOrient),
    NX = X + DX, NY = Y + DY, cell((NX,NY), _)
;
  on(T, X, Y, Time+1, Orient) } = 1 :-
    on(T, X, Y, Time, Orient),
    cell((X,Y), TrackType),
    global(Max),
    Time < Max,
    active(T, Time).


% ==============================================================================
% NEW LOGIC: COUPLING (trains queue up and follow, no merging)
% ==============================================================================

% Two trains can couple only if they share the exact same destination.
can_couple(T1, T2) :-
    train(T1), train(T2), T1 != T2,
    end(T1, (X,Y), _), end(T2, (X,Y), _).

% T2 is directly behind T1 at Time: T2 now sits on the cell T1 occupied the
% previous step (it has stepped into the leader's just-vacated cell).
%
% NOTE: positions here come purely from the standard movement rule above, so
% this is an *observation* — there is no circular support between `connected`
% and `on` (the bug in the previous version, which made the program UNSAT).
connected(T1, T2, Time) :-
    can_couple(T1, T2),
    on(T1, X, Y, Time-1, _),
    on(T2, X, Y, Time, _),
    active(T2, Time).

% An (unordered) couple has formed at some point — in either leader/follower order.
coupled(T1, T2) :- connected(T1, T2, _).
coupled(T1, T2) :- connected(T2, T1, _).


% ==============================================================================
% ORIGINAL LOGIC: SAFETY CONSTRAINTS & OPTIMIZATION
% ==============================================================================

% Two active trains cannot be on the same cell at the same time
% (this is what keeps the follower one cell *behind*, never overlapping).
:- train(T1), train(T2), T1 < T2,
   on(T1, X, Y, Time, _),
   on(T2, X, Y, Time, _),
   active(T1, Time),
   active(T2, Time).

% Two active trains cannot swap positions (pass through each other)
:- train(T1), train(T2), T1 < T2,
   on(T1, X1, Y1, Time, _),
   on(T2, X2, Y2, Time, _),
   on(T1, X2, Y2, Time+1, _),
   on(T2, X1, Y1, Time+1, _),
   active(T1, Time),
   active(T2, Time),
   X1 != X2.

:- train(T1), train(T2), T1 < T2,
   on(T1, X1, Y1, Time, _),
   on(T2, X2, Y2, Time, _),
   on(T1, X2, Y2, Time+1, _),
   on(T2, X1, Y1, Time+1, _),
   active(T1, Time),
   active(T2, Time),
   Y1 != Y2.

% Define what it means to reach a goal
reached(T) :-
    on(T, X, Y, Time, _),
    end(T, (X,Y), MaxTime),
    Time <= MaxTime.

% Make sure every train reaches its goal
:- train(T), not reached(T).

#minimize { Time@1, T : first_arrival(T, Time) }.


% ==============================================================================
% NEW LOGIC: COUPLING CONSTRAINTS
% ==============================================================================

% Trains that can couple MUST couple at some point. This forces the leading
% train to wait until the trailing one has caught up to right behind it.
:- can_couple(T1, T2), T1 < T2, not coupled(T1, T2).

% Once coupled, stay coupled: while the leader is still active and moving, the
% follower must remain directly behind it (a convoy, not a merge). The follower
% keeps stepping into the leader's vacated cell each tick.
:- connected(T1, T2, Time),
   active(T1, Time),
   global(Max), Time < Max,
   not connected(T1, T2, Time+1).
