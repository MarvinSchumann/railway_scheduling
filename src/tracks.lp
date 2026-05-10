%track logic
connects(1025, e,  0,  1, e).       % type 1025 and 32800: straight horizontal track
connects(1025, w,  0,  -1, w).      %  -||-
connects(32800, n,  -1, 0, n).      %  -||-
connects(32800, s,  1, 0, s).       %  -||-

connects(4608, e,  1,  0, s).       % type 4608: going east → go south (increase row)
connects(4608, n,  0, -1, w).       %  -||-

connects(16386, n, 0, 1, e).        % type 16386: curve N->E, W->S
connects(16386, w, 1, 0, s).        %  -||-

connects(72, s, 0, 1, e).           % type 72: curve S->E, W->N
connects(72, w, -1, 0, n).          %  -||-

connects(2064, e, -1, 0, n).        % type 2064: curve E->N, S->W
connects(2064, s, 0, -1, w).        %  -||-

connects(3089, e, 0, 1, e).         % type 3089: straight horizontal track with switch
connects(3089, w, 0, -1, w).        %  -||-
connects(3089, s, 0, -1, w).        %  -||-
connects(3089, e, -1, 0, n).        %  -||-

connects(1097, e, 0, 1, e).         % type 1097: straight horizontal track with switch
connects(1097, w, 0, -1, w).        %  -||-
connects(1097, w, -1, 0, n).        %  -||-
connects(1097, s, 0, 1, e).         %  -||-