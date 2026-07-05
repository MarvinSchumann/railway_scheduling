% ==============================================================================
% Translate the on/4 state sequence produced by encoding_connect.lp into
% Flatland action/3 atoms understood by the flatlands_visualisation framework.
%
%   action(train(ID), Action, Time).   Action in {move_forward, move_left,
%                                                  move_right, wait}
%
% Timing (verified empirically against flatland-rl 4.2.4, remove_agents_at_target):
%   - A train departs at time N = its `start` time.
%   - Actions at times 0..N are `wait`; the action at N+1 is `move_forward`,
%     which SPAWNS the train onto its start cell.
%   - Thereafter the model transition (time K -> K+1) is realised by the
%     Flatland action issued at time N+K+2.
%
% Every move in this environment is a single forced continuation (each train has
% exactly one route; the only real decision is wait vs. move), so `move_forward`
% correctly follows curves and the junction. The encoding's coupling logic shows
% up purely as `wait` actions while a train holds for its partner.
% ==============================================================================

ready(T, N) :- start(T, _, N, _).

% forced waits up to the departure time, then a forward to enter the map
action(train(T), wait, S)          :- ready(T, N), S = 0..N.
action(train(T), move_forward, N+1) :- ready(T, N).

% helpers over the on/4 timeline
has_time(T, K)  :- on(T, _, _, K, _).
same_cell(T, K) :- on(T, X, Y, K, _), on(T, X, Y, K+1, _).

% model transition K -> K+1  ==>  Flatland action at time N+K+2
action(train(T), wait, N+K+2) :-
    start(T, _, N, _), same_cell(T, K).
action(train(T), move_forward, N+K+2) :-
    start(T, _, N, _), has_time(T, K), has_time(T, K+1), not same_cell(T, K).

#show action/3.
