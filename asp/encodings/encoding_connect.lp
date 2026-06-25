% ==============================================================================
% INITIALIZATION & STATE DEFINITIONS
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

% Only move active trains (leader or follower picks its own legal move or stays).
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
% COUPLING (trains queue up and follow, no merging)
% ==============================================================================

% Waiting budget for forming a convoy: the "too long" threshold. If letting one
% train slot in directly behind the other would need a total wait of max_wait or
% MORE steps, the trains do NOT couple and run independently instead. Editable
% here, or override on the command line with  -c max_wait=N .
#const max_wait = 5.

% Two trains may couple iff they share the exact same destination.
can_couple(T1, T2) :-
    train(T1), train(T2), T1 < T2,
    end(T1, (X,Y), _), end(T2, (X,Y), _).

% For each candidate pair, optionally pick an order: lead(L,F) = L leads, F trails.
% (Upper bound 1 => at most one direction, and the pair may also stay uncoupled.)
{ lead(T1,T2) ; lead(T2,T1) } 1 :- can_couple(T1,T2).

coupled(T1,T2) :- can_couple(T1,T2), lead(T1,T2).
coupled(T1,T2) :- can_couple(T1,T2), lead(T2,T1).

% Follower F is directly behind leader L at Time: F now sits on the cell L
% occupied the previous step (it stepped into the leader's just-vacated cell).
following(L, F, Time) :-
    lead(L, F),
    on(L, X, Y, Time-1, _),
    on(F, X, Y, Time, _).

% The convoy first forms at this time (used to couple as early as possible).
join(L, F, Time) :-
    following(L, F, Time),
    not following(L, F, Time-1).

% A chosen leader must actually have its follower behind it at some point.
:- lead(L, F), not following(L, F, _).

% Once the convoy has formed, the follower must STAY exactly one cell behind the
% leader for as long as the leader is still active (a convoy, never a merge and
% never a widening gap).
:- following(L, F, Time),
   active(L, Time),
   global(Max), Time < Max,
   not following(L, F, Time+1).

% A train that stays on its cell for a step (while active) is idling/waiting.
idle(T, Time) :-
    on(T, X, Y, Time, _),
    on(T, X, Y, Time+1, _),
    active(T, Time).

% Forming a convoy costs waiting (the leader holds for the follower to slot in).
% max_wait is the "too long" threshold: if forming the convoy would need a total
% wait of max_wait OR MORE steps, the pair must NOT couple -- nobody waits and
% the trains run independently instead. (So max_wait=5 forbids a 5-step wait.)
couple_member(T1, T2, T1) :- coupled(T1, T2).
couple_member(T1, T2, T2) :- coupled(T1, T2).
:- coupled(T1, T2),
   #count{ T, Time : couple_member(T1, T2, T), idle(T, Time) } >= max_wait.


% ==============================================================================
% SAFETY CONSTRAINTS
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


% ==============================================================================
% OPTIMIZATION (lexicographic, highest priority first)
% ==============================================================================

% 1. Couple whenever it is feasible within the waiting budget (coupling is
%    mandatory unless it would cost too much waiting -> handled by max_wait).
#maximize { 1@3, T1, T2 : coupled(T1, T2) }.

% 2. Form each convoy as early as possible.
#minimize { Time@2, L, F : join(L, F, Time) }.

% 3. Get every train to its goal as early as possible.
#minimize { Time@1, T : first_arrival(T, Time) }.
