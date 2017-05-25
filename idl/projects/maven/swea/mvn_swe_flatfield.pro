;+
;FUNCTION:   mvn_swe_flatfield
;PURPOSE:
;  Maintains the angular sensitivity calibration and provides a means to
;  enable and disable the correction.  See mvn_swe_fovcal for details.
;  You can choose only one action: ON, OFF, or SET.  If you don't specify
;  an action, no change is made, and the routine only reports its current
;  state.
;
;  Calibrations are performed in the solar wind, using the strahl as a
;  calibration beam.  As the magnetic field direction changes, different
;  parts of the FOV are "illuminated".  Electron 3D distributions are 
;  corrected for spacecraft potential and transformed to the plasma rest
;  frame (using SWIA data), where the gyrotropy condition applies.
;  Correction factors are then determined for each of the 96 angular bins
;  that symmetrizes the angular distribution with respect to the magnetic
;  field direction.  To date, the solar wind calibration periods are:
;
;      1 : 2014-10-27 to 2015-03-14
;      2 : 2015-06-10 to 2015-10-15
;      3 : 2015-12-13 to 2016-04-05
;      4 : 2016-05-29 to 2016-10-06
;      5 : 2016-11-28 to 2017-03-15
;
;  Solar wind periods 1 and 3 yield calibrations that are very similar.
;  These are combined into a single FOV calibration.  Solar wind period
;  2 occurred when the SWEA MCP bias was not optimized.  The lower MCP
;  gain results in a measurably different FOV sensitivity.
;
;  Once set, a configuration is persistent within the current IDL session 
;  until changed with this routine.
;
;USAGE:
;  ff = mvn_swe_flatfield(time)
;
;INPUTS:
;       time:         Specify the time (in any format accepted by time_double)
;                     for calculating the flatfield correction.
;
;KEYWORDS:
;       NOMINAL:      Enable the nominal correction.
;
;       SET:          Set the flatfield to this 96-element array.
;
;       OFF:          Disable the correction.
;
;       SILENT:       Don't print any warnings or messages.
;
;       INIT:         Reinitialize the flatfield common block.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2017-05-08 17:28:38 -0700 (Mon, 08 May 2017) $
; $LastChangedRevision: 23281 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_flatfield.pro $
;
;CREATED BY:    David L. Mitchell  2016-09-28
;FILE: mvn_swe_flatfield.pro
;-
function mvn_swe_flatfield, time, nominal=nominal, off=off, set=set, silent=silent, $
                            calnum=calnum, init=init

  @mvn_swe_com
  common swe_flatfield_com, cc_t, kmax, swe_ff

; Initialize the common block, if necessary

  if ((size(cc_t,/type) eq 0) or (keyword_set(init))) then begin
    kmax = 5
    swe_ff = replicate(1.,96,kmax+1)

;   Solar wind calibration period 1  (2014-10-27 to 2015-03-14).

    swe_ff[*,1] = [1.000000 , 1.000000 , 1.000000 , 1.000000 , 0.877457 , 0.811684 , $
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

;   Solar wind calibration period 2  (2015-06-10 to 2015-10-15)

    swe_ff[*,2] = [1.000000 , 1.000000 , 1.000000 , 1.000000 , 0.843759 , 0.847640 , $
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

;   Solar wind calibration period 3  (2015-12-13 to 2016-04-05)

    swe_ff[*,3] = swe_ff[*,1]

;   Solar wind calibration periods 4 and 5  (2016-05-29 to 2017-13-15)
;   Results for periods 4 and 5 are very similar, so take the average and use for both.

    swe_ff[*,4] = [1.000000 , 1.000000 , 1.000000 , 1.000000 , 0.798163 , 0.808012 , $
                   0.992406 , 0.950617 , 0.876472 , 0.787930 , 0.953732 , 0.852237 , $
                   0.912070 , 0.901292 , 1.000000 , 1.000000 , 1.000000 , 1.000000 , $
                   1.000000 , 0.834263 , 0.810969 , 1.124497 , 1.127557 , 1.150475 , $
                   1.170787 , 1.149840 , 1.218544 , 1.189635 , 1.207079 , 1.192402 , $
                   1.003308 , 1.000000 , 0.970352 , 0.900612 , 1.089938 , 1.189959 , $
                   1.136835 , 1.093950 , 1.066742 , 1.082937 , 1.111103 , 1.119639 , $
                   1.155815 , 1.113576 , 1.153024 , 1.115599 , 1.124175 , 1.099895 , $
                   0.902138 , 1.055424 , 1.060409 , 1.066833 , 1.043402 , 1.043368 , $
                   1.000236 , 1.049426 , 1.036941 , 1.035782 , 1.082483 , 1.048728 , $
                   1.092556 , 1.085310 , 1.038241 , 1.034077 , 0.871543 , 0.911349 , $
                   0.944749 , 1.018215 , 1.000593 , 0.965242 , 0.903822 , 0.998244 , $
                   0.929005 , 0.936736 , 1.004803 , 1.040540 , 1.027748 , 0.989425 , $
                   0.960017 , 1.032292 , 0.865536 , 0.880691 , 0.997307 , 1.011359 , $
                   0.888254 , 0.913448 , 0.855490 , 0.848276 , 0.850046 , 0.814710 , $
                   0.921029 , 0.872874 , 0.934441 , 0.924436 , 0.836592 , 0.881278    ]

;   Solar wind calibration periods 4 and 5  (2016-05-29 to 2017-13-15)

    swe_ff[*,5] = swe_ff[*,4]

;   Centers of solar wind calibration periods 1-5

    tt = time_double(['2014-12-22','2015-08-02','2016-01-28','2016-08-22','2017-01-13'])
    cc_t = mvn_swe_crosscal(tt,/silent)

  endif

; Process keywords to determine configuration

  blab = ~keyword_set(silent)

; Only one configuration at a time.  Precedence: off, set, nominal.

  if keyword_set(nominal) then swe_ff_state = 1
  if (n_elements(set) eq 96) then begin
    swe_ff_state = 2
    swe_ff[*,0] = float(reform(set,96))/mean(set,/nan)
  endif
  if keyword_set(off) then swe_ff_state = 0

; Handle the easy cases first

  if (swe_ff_state eq 2) then swe_ogf = swe_ff[*,0] else swe_ogf = replicate(1.,96)

; Set the correction factors based on in-flight calibrations

  if ((swe_ff_state eq 1) and (size(time,/type) ne 0)) then begin

;   Interpolate between angular calibrations based on SWEA MCP gain, as inferred
;   from SWE-SWI cross calibration factor.

    t = time_double(time)
    cc = (mvn_swe_crosscal(t,/silent))[0]

    if (t lt t_mcp[5]) then begin
      frac = (((cc - cc_t[0])/(cc_t[1] - cc_t[0])) > 0.) < 1.
      swe_ogf = swe_ff[*,1]*(1. - frac) + swe_ff[*,2]*frac
    endif

    if ((t ge t_mcp[5]) and (t lt t_mcp[6])) then begin
      frac = (((cc - cc_t[2])/(cc_t[3] - cc_t[2])) > 0.) < 1.
      swe_ogf = swe_ff[*,3]*(1. - frac) + swe_ff[*,4]*frac
    endif

    if (t ge t_mcp[6]) then swe_ogf = swe_ff[*,5]

;   Override this with a specific calibration, if requested --> for testing

    if keyword_set(calnum) then swe_ogf = swe_ff[*,(calnum > 0) < kmax]

;   Enforce normalization to unity

    swe_ogf /= mean(swe_ogf)

  endif

; Report the flatfield configuration

  if (blab) then begin
    case swe_ff_state of
      0 : print,"Flatfield correction disabled"
      1 : print,"Flatfield correction enabled"
      2 : print,"User-defined flatfield correction"
    endcase
  endif

  return, swe_ogf

end
