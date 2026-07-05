% ==============================================================================
% COUPLING  -  trains heading to the same place form a convoy and run connected
% ==============================================================================
% Layers on top of encoding_base.lp (needs: on/5, active/2, first_arrival/2,
% end/3, train/1, global/1) and connections.lp.  The base already routes every
% train to its goal without collisions; this module additionally lets trains
% that share a destination line up one behind another and travel as one unit.
%
% A convoy is a CHAIN, so it scales to 3+ trains:
%
%        ahead(B,A)      ahead(C,B)
%     A <---------- B <---------- C          (A leads, B trails A, C trails B)
%
% Each train trails at most one train and is trailed by at most one, and cycles
% are forbidden -- so links can only ever compose into straight convoys, never
% merges or loops, no matter how many trains share the goal.
%
% Two clearly-marked EXTENSION SEAMS keep this ready for "stops"/checkpoints:
%   (1) convoy_compatible/2 -- who is allowed in a convoy together
%   (2) link_active/3 + uncouple/3 -- how long a link must hold
% Redefining those (per next-stop instead of per final-goal) is all the future
% uncoupling-at-stops feature needs; the spatial invariant below stays as is.
% ==============================================================================

% how long a convoy may stall while forming (total idle steps per member).
% override on the command line with  -c max_wait=N .
#const max_wait = 15.

% ------------------------------------------------------------------------------
% CONVOY STRUCTURE
% ------------------------------------------------------------------------------

% -- EXTENSION SEAM (1): two trains are allowed in the same convoy.
%    today: identical final destination.
%    later (stops): identical *next stop* -> just redefine this predicate.
convoy_compatible(F, L) :-
    train(F), train(L), F != L,
    end(F, (X,Y), _), end(L, (X,Y), _).

% ahead(F, L): train L runs immediately in front of follower F.
% Each train chooses at most one train to fall in behind.
{ ahead(F, L) : convoy_compatible(F, L) } 1 :- train(F).

% a train can have at most one direct follower (no merging two tails into one)
:- ahead(F1, L), ahead(F2, L), F1 < F2.

% transitive "somewhere behind" + acyclicity  =>  links form proper chains only
behind(F, L) :- ahead(F, L).
behind(F, L) :- ahead(F, M), behind(M, L).
:- behind(F, F).

% adjacency within a convoy (symmetric, handy for objectives / future rules)
coupled(F, L) :- ahead(F, L).
coupled(L, F) :- ahead(F, L).
in_convoy(T)  :- coupled(T, _).

% ------------------------------------------------------------------------------
% SPATIAL CONVOY INVARIANT  (a follower rides one cell behind its leader)
% ------------------------------------------------------------------------------
% F properly trails L at time T when F now sits on the cell L held one step
% earlier -- i.e. F stepped into the leader's just-vacated cell.
trailing(F, L, T) :-
    ahead(F, L),
    on(L, X, Y, T-1, _),
    on(F, X, Y, T, _).

% a declared link must be realised on the track at some point
:- ahead(F, L), not trailing(F, L, _).

% -- EXTENSION SEAM (2): the link is "engaged" (invariant enforced) at time T.
%    today: engaged while the leader is still moving; a convoy with a shared
%    final goal therefore never splits before arrival.
%    later (stops): assert uncouple(F,L,T) from the moment the shared route ends
%    at a stop, and the follower is free to peel off afterwards.
link_active(F, L, T) :-
    ahead(F, L),
    active(L, T),
    not uncouple(F, L, T).

% once formed, the follower must keep trailing for as long as the link is engaged
:- trailing(F, L, T),
   link_active(F, L, T),
   global(Max), T < Max,
   not trailing(F, L, T+1).

% the step at which a convoy link first forms (used to couple early)
join(F, L, T) :-
    trailing(F, L, T),
    not trailing(F, L, T-1).

% ------------------------------------------------------------------------------
% WAITING BUDGET
% ------------------------------------------------------------------------------
% a train idles when it holds its cell for a step while still active
idle(T, Time) :-
    on(T, X, Y, Time, _),
    on(T, X, Y, Time+1, _),
    active(T, Time).

% forming a convoy may cost some waiting, but not more than max_wait steps for
% any single member -- otherwise the trains run independently instead
:- in_convoy(T), #count{ Time : idle(T, Time) } >= max_wait.

% ------------------------------------------------------------------------------
% OBJECTIVES  (added on top of the base's "arrive early" at priority 1)
% ------------------------------------------------------------------------------
% 2. couple as many trains as feasible (prefer longer / more convoys)
#maximize { 1@3, F, L : ahead(F, L) }.
% 3. form each convoy as early as possible
#minimize { T@2, F, L : join(F, L, T) }.
