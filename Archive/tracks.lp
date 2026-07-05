%track type 1: Straight tracks
connects(1025, e,  0,  1, e).        % type 1025 and 32800: straight horizontal track
connects(1025, w,  0,  -1, w).       %  -||-
connects(32800, n,  -1, 0, n).       %  -||-
connects(32800, s,  1, 0, s).        %  -||-

connects(4608, e,  1,  0, s).        % type 4608: going east → go south (increase row)
connects(4608, n,  0, -1, w).        %  -||-

connects(16386, n, 0, 1, e).         % type 16386: curve N->E, W->S
connects(16386, w, 1, 0, s).         %  -||-

connects(72, s, 0, 1, e).            % type 72: curve S->E, W->N
connects(72, w, -1, 0, n).           %  -||-

connects(2064, e, -1, 0, n).         % type 2064: curve E->N, S->W
connects(2064, s, 0, -1, w).         %  -||-

%track type 2: simple switch
connects(37408, n, 0, -1, w).        % type 37408: straight vertical track with switch
connects(37408, n, -1, 0, n).        %  -||-
connects(37408, s, 1, 0, s).         %  -||-
connects(37408, e, 1, 0, s).         %  -||-

connects(17411, n, 0, 1, e).         % type 17411: straight horizontal track with switch 
connects(17411, e, 0, 1, e).         %  -||-
connects(17411, w, 0, -1, w).        %  -||-
connects(17411, w, 1, 0, s).         %  -||-

connects(32872, s, 1, 0, s).         % type 32872: straight vertical track with switch
connects(32872, n, -1, 0, n).        %  -||-
connects(32872, s, 0, 1, e).         %  -||-
connects(32872, w, -1, 0, n).        %  -||-

connects(3089, e, 0, 1, e).          % type 3089: straight horizontal track with switch
connects(3089, w, 0, -1, w).         %  -||-
connects(3089, s, 0, -1, w).         %  -||-
connects(3089, e, -1, 0, n).         %  -||-

connects(49186, n, -1, 0, n).        % type 49186: straight vertical track with switch
connects(49186, s, 1, 0, s).         %  -||-
connects(49186, n, 0, 1, e).         %  -||-
connects(49186, w, 1, 0, s).         %  -||-

connects(1097, e, 0, 1, e).          % type 1097: straight horizontal track with switch
connects(1097, w, 0, -1, w).         %  -||-
connects(1097, w, -1, 0, n).         %  -||-
connects(1097, s, 0, 1, e).          %  -||-

connects(34864, n, -1, 0, n).        % type 34864: straight vertical track with switch
connects(34864, s, 1, 0, s).         %  -||-
connects(34864, s, 0, -1, w).        %  -||-
connects(34864, e, -1, 0, n).        %  -||-

connects(5633, n, 0, -1, w).         % type 17427: straight horizontal track with switch
connects(5633, e, 1, 0, s).          %  -||-
connects(5633, e, 0, 1, e).          %  -||-
connects(5633, w, 0, -1, w).         %  -||-


%track type 3: Diamond crossing
connects(33825, n, -1, 0, n).        % type 33825: two crossing tracks, no interconnection
connects(33825, s, 1, 0, s).         %  -||-
connects(33825, e, 0, 1, e).         %  -||-
connects(33825, w, 0, -1, w).        %  -||-

%track type 4: single-slip switch
connects(38433, n, -1, 0, n).        % type 33825: two crossing tracks + W -> S connection
connects(38433, s, 1, 0, s).         %  -||-
connects(38433, e, 0, 1, e).         %  -||-
connects(38433, w, 0, -1, w).        %  -||-
connects(38433, e, 1, 0, s).         %  -||-
connects(38433, n, 0, -1, w).        %  -||-

connects(50211, n, -1, 0, n).        % type 50211: two crossing tracks + S -> E connection
connects(50211, s, 1, 0, s).         %  -||-
connects(50211, e, 0, 1, e).         %  -||-
connects(50211, w, 0, -1, w).        %  -||-
connects(50211, n, 0, 1, e).         %  -||-
connects(50211, w, 1, 0, s).         %  -||-

connects(33897, n, -1, 0, n).        % type 33897: two crossing tracks + N -> E connection
connects(33897, s, 1, 0, s).         %  -||-
connects(33897, e, 0, 1, e).         %  -||-
connects(33897, w, 0, -1, w).        %  -||-
connects(33897, s, 0, 1, e).         %  -||-
connects(33897, w, -1, 0, n).        %  -||-

connects(35889, n, -1, 0, n).        % type 35889: two crossing tracks + W -> N connection
connects(35889, s, 1, 0, s).         %  -||-
connects(35889, e, 0, 1, e).         %  -||-
connects(35889, w, 0, -1, w).        %  -||-
connects(35889, e, -1, 0, n).        %  -||-
connects(35889, s, 0, -1, w).        %  -||-

%track type 5: double-slip switch
connects(38505, n, -1, 0, n).        % type 38505: two crossing tracks + W <-> S + N<->E connections
connects(38505, s, 1, 0, s).         %  -||-
connects(38505, e, 0, 1, e).         %  -||-
connects(38505, w, 0, -1, w).        %  -||-
connects(38505, e, 1, 0, s).         %  -||-
connects(38505, n, 0, -1, w).        %  -||-
connects(38505, s, 0, 1, e).         %  -||-
connects(38505, w, -1, 0, n).        %  -||-

connects(52275, n, -1, 0, n).        % type 52275: two crossing tracks + W <-> N + S<->E connectionsconnects(38505, s, 1, 0, s).         %  -||-
connects(52275, e, 0, 1, e).         %  -||-
connects(52275, w, 0, -1, w).        %  -||-
connects(52275, s, 1, 0, s).         %  -||-
connects(52275, n, 0, 1, e).         %  -||-
connects(52275, w, 1, 0, s).         %  -||-
connects(52275, e, -1, 0, n).        %  -||-
connects(52275, s, 0, -1, w).        %  -||-

%track type 6: symmetrical switch
connects(20994, e, 1, 0, s).         % type 20994: horizontal symmetrical switch down
connects(20994, w, 1, 0, s).         %  -||-
connects(20994, n, 0, -1, w).        %  -||-
connects(20994, n, 0, 1, e).         %  -||-

connects(16458, s, 0, 1, e).         %  type 16458: vertical symmetrical switch right
connects(16458, n, 0, 1, e).         %  -||-
connects(16458, w, -1, 0, n).        %  -||-
connects(16458, w, 1, 0, s).         %  -||-

connects(2136, e, -1, 0, n).         %  type 16466: horizontal symmetrical switch up
connects(2136, w, -1, 0, n).         %  -||-
connects(2136, s, 0, 1, e).          %  -||-
connects(2136, s, 0, -1, w).         %  -||-

connects(6672, s, 0, -1, w).         %  type 16464: vertical symmetrical switch left
connects(6672, n, 0, -1, w).         %  -||-
connects(6672, e, -1, 0, n).         %  -||-
connects(6672, e, 1, 0, s).          %  -||-