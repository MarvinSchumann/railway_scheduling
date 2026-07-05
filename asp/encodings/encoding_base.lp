% ==============================================================================
% BASE ENCODING  -  route every train from its start to its goal
% ==============================================================================
% Depends on connections.lp for: connection/2, move/3, inverse/2, dir/1,
%                                 turn_left/2, turn_right/2, switch/2.
%
% State is tracked as   on(Train, Row, Col, Time, Heading)   on a single time
% axis shared by all trains (so collisions are checked in real Flatland time).
% A train appears on its start cell at its departure time and then, each step,
% either advances along a rail-legal transition or holds its cell, until it
% first reaches its goal.
% ==============================================================================

% ------------------------------------------------------------------------------
% TIME & TRANSITIONS
% ------------------------------------------------------------------------------
time(0..Max) :- global(Max).

% step(Type, Heading, NewHeading, DRow, DCol): on a cell of this Type, a train
% heading `Heading` may leave heading `NewHeading`, moving by (DRow,DCol).
% A train that heads H entered its current cell from side inverse(H); the rail
% then permits leaving toward NewHeading.
step(Type, H, NH, DR, DC) :-
    connection(Type, (In, NH)),
    inverse(H, In),
    move(NH, DR, DC).

% ------------------------------------------------------------------------------
% MOVEMENT
% ------------------------------------------------------------------------------
% a train occupies its start cell at its departure time
on(ID, R, C, Depart, H) :- start(ID, (R,C), Depart, H).

% each active step: advance along exactly one legal transition, or wait in place
{ on(ID, R+DR, C+DC, T+1, NH) : step(Type, H, NH, DR, DC), cell((R+DR,C+DC), _)
; on(ID, R, C, T+1, H) } = 1 :-
    on(ID, R, C, T, H),
    cell((R,C), Type),
    time(T+1),
    active(ID, T).

% ------------------------------------------------------------------------------
% ARRIVAL
% ------------------------------------------------------------------------------
% a train sits on its goal cell (and did the step before, too)
held_at_goal(ID, T) :-
    on(ID, R, C, T, _),
    end(ID, (R,C), _),
    on(ID, R, C, T-1, _).

% the moment a train first reaches its goal
first_arrival(ID, T) :-
    on(ID, R, C, T, _),
    end(ID, (R,C), _),
    not held_at_goal(ID, T).

% a train keeps moving until (and including) its first arrival
active(ID, T) :-
    on(ID, _, _, T, _),
    not first_arrival(ID, T).

reached(ID) :- first_arrival(ID, _).

% ------------------------------------------------------------------------------
% CONSTRAINTS
% ------------------------------------------------------------------------------
% every train must reach its goal
:- train(ID), not reached(ID).

% no two trains share a cell at the same time
:- on(ID1, R, C, T, _), on(ID2, R, C, T, _), ID1 < ID2.

% no two trains swap cells (drive through one another) between T and T+1
:- on(ID1, R1, C1, T, _), on(ID1, R2, C2, T+1, _),
   on(ID2, R2, C2, T, _), on(ID2, R1, C1, T+1, _),
   ID1 < ID2, (R1,C1) != (R2,C2).

% ------------------------------------------------------------------------------
% OBJECTIVE
% ------------------------------------------------------------------------------
% get every train to its goal as early as possible
#minimize { T@1, ID : first_arrival(ID, T) }.

% ==============================================================================
% ACTION OUTPUT   action(train(ID), Action, Time),  Action in
%                 {move_forward, move_left, move_right, wait}
% ==============================================================================
% Flatland timing (matches the canonical example in envs / test.lp):
%   - times 0 .. Depart-1 : wait   (train not yet released)
%   - time  Depart        : move_forward, which spawns the train on its start cell
%   - each modelled transition on(T) -> on(T+1) becomes the action at time T+1
% A left/right action is only emitted at a real switch; on straight track and on
% curves the rail forces the continuation, so those are plain move_forward.
% ------------------------------------------------------------------------------

% waits before release
action(train(ID), wait, T) :- start(ID, _, Depart, _), time(T), T < Depart.

% release: spawn onto the start cell
action(train(ID), move_forward, Depart) :- start(ID, _, Depart, _).

% a train that stays on its cell from T to T+1 is waiting
same_cell(ID, T) :- on(ID, R, C, T, _), on(ID, R, C, T+1, _).
action(train(ID), wait, T+1) :- same_cell(ID, T).

% a turn taken at a switch
action(train(ID), move_left, T+1) :-
    on(ID, R, C, T, H), on(ID, _, _, T+1, NH),
    not same_cell(ID, T),
    cell((R,C), Type), switch(Type, H),
    turn_left(H, NH).

action(train(ID), move_right, T+1) :-
    on(ID, R, C, T, H), on(ID, _, _, T+1, NH),
    not same_cell(ID, T),
    cell((R,C), Type), switch(Type, H),
    turn_right(H, NH).

% any other advance is a forward move
action(train(ID), move_forward, T+1) :-
    on(ID, _, _, T, _), on(ID, _, _, T+1, _),
    not same_cell(ID, T),
    not action(train(ID), move_left, T+1),
    not action(train(ID), move_right, T+1).

#show action/3.
