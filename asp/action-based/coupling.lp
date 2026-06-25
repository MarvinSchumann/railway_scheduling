% ── Coupling for the action-based encoding (wait + follow, no merge) ──────────
%
% Port of encoding_connect.lp to the action/Flatland representation. Two trains
% that share a destination must form a convoy: one waits for the other, then
% follows directly behind it to the goal. They never occupy the same cell and
% never merge into a single train.
%
% Positions come from pathfinding.lp's `at/4` (driven by the `do/3` move
% choice), so `connected` below is a pure observation — no circular support.
% Requires the `wait` offset added in transitions.lp so a train can actually
% hold its position to let the other pass.

% Two trains may couple only if they share the exact same destination cell.
can_couple(A, B) :-
    train(A), train(B), A != B,
    end(A, (X,Y), _), end(B, (X,Y), _).

% Follower B is directly behind leader A at T: B now sits on the cell A held
% the previous step (B stepped into A's just-vacated cell on the same path).
connected(A, B, T) :-
    can_couple(A, B),
    at(A, (X,Y), _, T-1),
    at(B, (X,Y), _, T).

% A couple has formed at some point, in either leader/follower order.
coupled(A, B) :- connected(A, B, _).
coupled(A, B) :- connected(B, A, _).

% Trains that can couple MUST couple -> forces the leader to wait until the
% trailing train has pulled up directly behind it.
:- can_couple(A, B), A < B, not coupled(A, B).

% Once coupled, stay coupled while the leader is still on the map: the follower
% keeps stepping into the leader's vacated cell each tick (a convoy).
:- connected(A, B, T),
   at(A, _, _, T+1),
   not connected(A, B, T+1).

% The framework's pathfinding has no objective, so a feasible plan may let a
% train dawdle. Minimise total arrival time to keep the convoy tight (trains
% move as soon as they legally can).
#minimize { T@1, ID : done(ID, T) }.
