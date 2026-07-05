% ==============================================================================
% TRACK CONNECTIONS  (n / s / w / e direction model)
% ==============================================================================
% A cell of a given track Type is described by connection(Type, (In, Out)):
% a train entering the cell from side `In` may leave it toward side `Out`.
% Sides are named by the direction one would travel to cross them:
%   n = up (row - 1), s = down (row + 1), w = left (col - 1), e = right (col + 1)
%
% Every connection is bidirectional, so the closing rule below mirrors each
% pair.  The concrete Type numbers are the Flatland 16-bit transition codes.
% (Track definitions provided by the course; kept verbatim so movement matches
%  the Flatland simulator exactly.)
% ==============================================================================

% Track Type 1 - Straight
connection(32800,   (n,s)).
connection(1025,    (w,e)).

% Track Type 8 - Curve
connection(4608,    (s,w)).
connection(16386,   (e,s)).
connection(72,      (n,e)).
connection(2064,    (w,n)).

% Track Type 2 - Simple switch (left)
connection(37408,   (n,s)).
connection(37408,   (s,w)).
connection(17411,   (w,e)).
connection(17411,   (e,s)).
connection(32872,   (n,s)).
connection(32872,   (n,e)).
connection(3089,    (w,e)).
connection(3089,    (w,n)).

% Track Type 9 - Simple switch (right)
connection(49186,   (n,s)).
connection(49186,   (e,s)).
connection(1097,    (w,e)).
connection(1097,    (n,e)).
connection(34864,   (n,s)).
connection(34864,   (w,n)).
connection(5633,    (w,e)).
connection(5633,    (s,w)).

% Track Type 3 - Diamond crossing
connection(33825,   (n,s)).
connection(33825,   (w,e)).

% Track Type 4 - Single-slip switch
connection(38433,   (n,s)).
connection(38433,   (w,e)).
connection(38433,   (s,w)).
connection(50211,   (n,s)).
connection(50211,   (w,e)).
connection(50211,   (e,s)).
connection(33897,   (n,s)).
connection(33897,   (w,e)).
connection(33897,   (n,e)).
connection(35889,   (n,s)).
connection(35889,   (w,e)).
connection(35889,   (w,n)).

% Track Type 5 - Double-slip switch
connection(38505,   (n,s)).
connection(38505,   (w,e)).
connection(38505,   (n,e)).
connection(38505,   (s,w)).
connection(52275,   (n,s)).
connection(52275,   (w,e)).
connection(52275,   (e,s)).
connection(52275,   (w,n)).

% Track Type 6 - Symmetrical switch
connection(20994,   (e,s)).
connection(20994,   (s,w)).
connection(16458,   (n,e)).
connection(16458,   (e,s)).
connection(2136,    (w,n)).
connection(2136,    (n,e)).
connection(6672,    (s,w)).
connection(6672,    (w,n)).

% tracks may be traversed in either direction
connection(Type, (D2,D1)) :- connection(Type, (D1,D2)).

% ==============================================================================
% DIRECTION HELPERS
% ==============================================================================

% the four compass directions
dir(n). dir(s). dir(w). dir(e).

% move(Dir, DRow, DCol): stepping one cell toward Dir
move(n, -1,  0).
move(s,  1,  0).
move(w,  0, -1).
move(e,  0,  1).

% opposite directions (used to turn a heading into the side it entered from)
inverse(n,s). inverse(s,n). inverse(w,e). inverse(e,w).

% left / right 90-degree turns
turn_left(n,w). turn_right(n,e).
turn_left(w,s). turn_right(w,n).
turn_left(s,e). turn_right(s,w).
turn_left(e,n). turn_right(e,s).

% switch(Type, Heading): a train heading `Heading` on a cell of this Type faces a
% real choice (more than one possible exit) -> a left/right decision, not a plain
% forward.  Anything else (straight, curve) is a single forced continuation.
switch(Type, Heading) :-
    connection(Type, _),
    dir(From),
    inverse(From, Heading),
    #count{ To : connection(Type, (From, To)) } > 1.
