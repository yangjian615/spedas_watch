;+
;PROCEDURE:   mvn_swe_flatfield
;PURPOSE:
;  Maintains the angular sensitivity calibration and provides a means to
;  enable and disable the correction.  See mvn_swe_fovcal for details.
;  You can choose only one action: ON, OFF, or SET.  If you don't specify
;  an action, no change is made, and the routine only reports its current
;  state.
;
;  Once set, a configuration is persistent within the current IDL session 
;  until changed with this routine.
;
;USAGE:
;  mvn_swe_flatfield
;
;INPUTS:
;
;KEYWORDS:
;       ON:           Enable the nominal correction.
;
;       OFF:          Disable the correction.
;
;       SET:          Set the flatfield to this 96-element array.
;
;       SILENT:       Don't print any warnings or messages.
;
;       VALUE:        Named variable to hold the current values of 
;                     the 96 correction factors.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2016-10-18 15:26:25 -0700 (Tue, 18 Oct 2016) $
; $LastChangedRevision: 22135 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_flatfield.pro $
;
;CREATED BY:    David L. Mitchell  2016-09-28
;FILE: mvn_swe_flatfield.pro
;-
pro mvn_swe_flatfield, on=on, off=off, set=set, silent=silent, value=value

  @mvn_swe_com

; Process keywords to determine configuration
  
  if keyword_set(off) then begin
    swe_ff_state = 0
    swe_ogf = replicate(1.,96)
    set = 0
    on = 0
  endif

  if (n_elements(set) eq 96) then begin
    swe_ff_state = 2
    swe_ogf = float(reform(set,96))
    on = 0
  endif

; Set the correction factors based in in-flight calibrations

  if keyword_set(on) then begin
    swe_ff_state = 1

;   Solar wind periods 1 and 3

    swe_ogf1 = [1.000000 , 1.000000 , 1.000000 , 1.000000 , 0.877457 , 0.811684 , $
                0.974663 , 1.090681 , 0.827977 , 0.967138 , 0.909398 , 0.922703 , $
                0.945339 , 0.948781 , 1.000000 , 1.000000 , 1.000000 , 1.000000 , $
                1.000000 , 0.783953 , 0.799805 , 1.092878 , 1.146659 , 1.180665 , $
                1.182206 , 1.184594 , 1.181406 , 1.187459 , 1.206050 , 1.207419 , $
                1.047321 , 1.000000 , 1.143603 , 0.924350 , 1.062616 , 1.136479 , $
                1.116603 , 1.066938 , 1.072600 , 1.103179 , 1.117220 , 1.131237 , $
                1.139877 , 1.115340 , 1.163150 , 1.130877 , 1.161046 , 1.125834 , $
                1.059624 , 1.052342 , 1.071056 , 1.041820 , 1.035182 , 1.006385 , $
                1.006550 , 1.055105 , 1.036097 , 1.043844 , 1.038166 , 1.040221 , $
                1.077861 , 1.084966 , 1.074460 , 1.061238 , 0.975567 , 0.895757 , $
                0.951097 , 1.016743 , 0.968444 , 0.912867 , 0.882519 , 0.989250 , $
                0.922384 , 0.934497 , 0.932417 , 0.982760 , 0.994461 , 0.962354 , $
                0.937530 , 0.976744 , 0.905537 , 0.893543 , 1.010918 , 0.975263 , $
                0.880372 , 0.875369 , 0.816213 , 0.848975 , 0.805380 , 0.804108 , $
                0.827322 , 0.816978 , 0.853364 , 0.873930 , 0.807642 , 0.816381    ]

;   Solar wind period 2

    swe_ogf2 = [1.000000 , 1.000000 , 1.000000 , 1.000000 , 0.843759 , 0.847640 , $
                1.012098 , 1.040983 , 0.920816 , 0.891987 , 1.009085 , 0.941170 , $
                0.956725 , 0.939590 , 1.000000 , 1.000000 , 1.000000 , 1.000000 , $
                1.000000 , 0.800859 , 0.847728 , 1.114847 , 1.129818 , 1.180432 , $
                1.238382 , 1.208319 , 1.288248 , 1.216799 , 1.231647 , 1.224439 , $
                1.061229 , 1.000000 , 1.063657 , 0.915567 , 1.067387 , 1.159760 , $
                1.115952 , 1.077909 , 1.038859 , 1.075989 , 1.147254 , 1.146370 , $
                1.206158 , 1.133052 , 1.166090 , 1.135227 , 1.120028 , 1.131254 , $
                0.969063 , 1.061918 , 1.076491 , 1.034339 , 1.063753 , 1.023416 , $
                0.972541 , 1.052139 , 1.066577 , 1.045153 , 1.100232 , 1.049866 , $
                1.073862 , 1.073398 , 1.026498 , 1.054168 , 0.882796 , 0.900291 , $
                0.926829 , 1.004274 , 0.980802 , 0.925713 , 0.866614 , 0.972181 , $
                0.930074 , 0.936041 , 1.018903 , 1.005275 , 0.980403 , 0.943584 , $
                0.892110 , 0.946561 , 0.839612 , 0.854615 , 0.961791 , 0.964480 , $
                0.845180 , 0.864971 , 0.795987 , 0.797220 , 0.837243 , 0.796571 , $
                0.882287 , 0.838460 , 0.869388 , 0.861001 , 0.769619 , 0.813524    ]

    swe_ogf = swe_ogf1
  endif

; Make a copy of the current correction values

  value = swe_ogf

; Report the flatfield configuration

  if not keyword_set(silent) then begin
    case swe_ff_state of
      0 : print,"Flatfield correction disabled"
      1 : print,"Flatfield correction enabled"
      2 : print,"User-defined flatfield correction"
    endcase
  endif

  return

end
