;+
;PROCEDURE:   swe_snap_layout
;PURPOSE:
;  Puts snapshot windows in convenient, non-overlapping locations, 
;  depending on display hardware.
;
;USAGE:
;  swe_snap_layout, layout
;
;INPUTS:
;       layout:        Integer specifying the layout:
;
;                        0 --> Default.  No fixed window positions.
;                        1 --> Macbook 1440x900 with Dell 1920x1200 (above)
;                        2 --> Twin Dell 1920x1200 (left, right)
;                        3 --> Macbook 1440x900 with ViewSonic 1680x1050 (above)
;                        4 --> Macbook 1440x900 with Samsung 1600x900 (left)
;                        5 --> Macbook 1440x900 (below) with twin Dell 1920x1200 (left, right)
;
;KEYWORDS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2014-09-15 12:58:24 -0700 (Mon, 15 Sep 2014) $
; $LastChangedRevision: 15795 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/swe_snap_layout.pro $
;
;CREATED BY:    David L. Mitchell  07-24-12
;-
pro swe_snap_layout, layout

  common snap_layout, Dopt, Sopt, Popt, Nopt, Copt, Eopt, Hopt
  
  if (data_type(layout) eq 0) then begin
    print,"Hardware-dependent positions for snapshot windows (optional)."
    print,"  0 --> Default.  No fixed window positions."
    print,"  1 --> Macbook 1440x900 with Dell 1920x1200 (above)"
    print,"  2 --> Twin Dell 1920x1200 (left, right)"
    print,"  3 --> Macbook 1440x900 with ViewSonic 1680x1050 (above)"
    print,"  4 --> Macbook 1440x900 with Samsung 1600x900 (left)"
    print,"  5 --> Macbook 1440x900 (below) with twin Dell 1920x1200 (left, right)"
    print,""
    layout = 0
    read, layout, prompt='Layout > '
  endif

  case layout[0] of

    1    : begin  ; Macbook 1440x900 with Dell 1920x1200 (above)
             Dopt = {xsize:800, ysize:600, xpos:300,  ypos:-600}  ; 3D
             Sopt = {xsize:450, ysize:600, xpos:1130, ypos:-600}

             Popt = {xsize:800, ysize:600, xpos:300,  ypos:-600}  ; PAD
             Nopt = {xsize:450, ysize:600, xpos:1130, ypos:-600}
             Copt = {xsize:500, ysize:700, xpos:1000, ypos:-700}

             Eopt = {xsize:400, ysize:600, xpos:720,  ypos:-600}  ; SPEC
             Hopt = {xsize:225, ysize:545, xpos:480, ypos:-600}
           end
    
    2    : begin  ; Twin Dell 1920x1200 (left, right)
             Dopt = {xsize:800, ysize:600, xpos:1120, ypos:640}  ; 3D
             Sopt = {xsize:450, ysize:600, xpos:880,  ypos:500}

             Popt = {xsize:800, ysize:600, xpos:1120, ypos:640}  ; PAD
             Nopt = {xsize:450, ysize:600, xpos:880,  ypos:500}
             Copt = {xsize:500, ysize:700, xpos:1000, ypos:-700}

             Eopt = {xsize:400, ysize:600, xpos:1120, ypos:640}  ; SPEC
             Hopt = {xsize:200, ysize:545, xpos:880,  ypos:500}
           end
    
    3    : begin  ; Macbook 1440x900 with ViewSonic 1680x1050 (above)
             Dopt = {xsize:800, ysize:600, xpos:240,  ypos:-600}  ; 3D
             Sopt = {xsize:450, ysize:600, xpos:1100, ypos:-600}

             Popt = {xsize:800, ysize:600, xpos:240,  ypos:-600}  ; PAD
             Nopt = {xsize:600, ysize:450, xpos:1050, ypos:-600}
             Copt = {xsize:500, ysize:700, xpos:1000, ypos:-700}

             Eopt = {xsize:400, ysize:600, xpos:240,  ypos:-600}  ; SPEC
             Hopt = {xsize:200, ysize:545, xpos:700,  ypos:-540}
           end
    
    4    : begin  ; Macbook 1440x900 with Samsung 1600x900 (left)
             Dopt = {xsize:800, ysize:600, xpos:1600, ypos:300}  ; 3D
             Sopt = {xsize:450, ysize:600, xpos:2420, ypos:300}

             Popt = {xsize:800, ysize:600, xpos:1600, ypos:300}  ; PAD
             Nopt = {xsize:600, ysize:450, xpos:2420, ypos:450}
             Copt = {xsize:500, ysize:700, xpos:1000, ypos:-700}

             Eopt = {xsize:400, ysize:600, xpos:1600, ypos:300}  ; SPEC
             Hopt = {xsize:200, ysize:545, xpos:2020, ypos:355}
           end
    
    5    : begin  ; Macbook 1440x900 with Twin Dell 1920x1200 (left, right)
             Dopt = {xsize:800, ysize:600, xpos:1920+100, ypos:640}  ; 3D
             Sopt = {xsize:450, ysize:600, xpos:1920+1000, ypos:640}

             Popt = {xsize:800, ysize:600, xpos:1920+100, ypos:640}  ; PAD
             Nopt = {xsize:600, ysize:450, xpos:1920+1000, ypos:640}
             Copt = {xsize:500, ysize:700, xpos:1000, ypos:-700}

             Eopt = {xsize:400, ysize:600, xpos:1920+100, ypos:640}  ; SPEC
             Hopt = {xsize:200, ysize:545, xpos:1920+600, ypos:640}
           end
    
    else : begin  ; Default.  No fixed window positions
             Dopt = {xsize:800, ysize:600, xpos:0, ypos:0}  ; 3D
             Sopt = {xsize:450, ysize:600, xpos:0, ypos:0}

             Popt = {xsize:800, ysize:600, xpos:0, ypos:0}  ; PAD
             Nopt = {xsize:600, ysize:450, xpos:0, ypos:0}
             Copt = {xsize:500, ysize:700, xpos:0, ypos:0}

             Eopt = {xsize:400, ysize:600, xpos:0, ypos:0}  ; SPEC
             Hopt = {xsize:200, ysize:545, xpos:0, ypos:0}
           end

  endcase

  return

end
