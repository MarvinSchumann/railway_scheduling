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


% ==============================================================================
% NEW LOGIC: COUPLING (Trains connecting with each other)
% ==============================================================================

% Two trains can only couple if they share the exact same destination.
can_couple(T1, T2) :-
    train(T1), train(T2), T1 != T2,
    end(T1, (X,Y), _), end(T2, (X,Y), _).

% Coupling condition: T2 catches up to T1.
% This happens when T2 reaches the position at 'Time' that T1 occupied 
% in the previous step (Time-1), provided they share the same goal.
connected(T1, T2, Time) :-
    can_couple(T1, T2),
    on(T1, X1, Y1, Time-1, _),
    on(T2, X1, Y1, Time, _),
    global(Max), Time <= Max.

% The connection persists in subsequent time steps as long as T1 is active.
connected(T1, T2, Time+1) :-
    connected(T1, T2, Time),
    active(T1, Time),
    global(Max), Time < Max.


% ==============================================================================
% MODIFIED & NEW MOVEMENT RULES
% ==============================================================================

% If T2 is coupled to T1, its movement is strictly dictated by T1.
% T2 follows T1 like a wagon, moving into T1's current position in the next step.
on(T2, X, Y, Time+1, Orient) :-
    connected(T1, T2, Time+1),
    on(T1, X, Y, Time, Orient),
    active(T2, Time).

% MODIFIED ORIGINAL RULE: 
% Only move active trains. A train can ONLY choose its move freely via this choice rule 
% if it is NOT coupled to another train in the next time step.
{ on(T, NX, NY, Time+1, NewOrient) :
    connects(TrackType, Orient, DX, DY, NewOrient),
    NX = X + DX, NY = Y + DY, cell((NX,NY), _)
;
  on(T, X, Y, Time+1, Orient) } = 1 :-
    on(T, X, Y, Time, Orient),
    cell((X,Y), TrackType),
    global(Max),
    Time < Max,
    active(T, Time),
    % MODIFICATION: Prevents Clingo from generating independent moves for a coupled trailing train
    not connected(_, T, Time+1).


% ==============================================================================
% ORIGINAL LOGIC: SAFETY CONSTRAINTS & OPTIMIZATION
% ==============================================================================

% Two active trains cannot be on the same cell at the same time
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
% NEW LOGIC: COUPLING CONSTRAINT
% ==============================================================================

% Hard constraint: If two trains are capable of coupling, they MUST connect 
% at some point before reaching the goal. This forces the front train to wait.
:- can_couple(T1, T2), T1 < T2, not connected(T1, T2, _).