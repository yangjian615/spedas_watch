;+
;PROCEDURE: 
;	mvn_scpot_defaults
;
;PURPOSE:
;	Sets defaults for mvn_scpot and related routines.  These are stored
;   in a common block (mvn_scpot_com).
; 
;AUTHOR: 
;	David L. Mitchell
;
;CALLING SEQUENCE: 
;	mvn_scpot_defaults
;
;INPUTS: 
;   none - simply sets defaults for the common block.
;
;KEYWORDS:
;   ERANGE:    Energy range over which to search for the potential.
;              Default = [3.,30.]
;
;   THRESH:    Threshold for the minimum slope: d(logF)/d(logE). 
;              Default = 0.05
;
;              A smaller value includes more data and extends the range 
;              over which you can estimate the potential, but at the 
;              expense of making more errors.
;
;   MINFLUX:   Minimum peak energy flux.  Default = 1e6.
;
;   DEMAX:     The largest allowable energy width of the spacecraft 
;              potential feature.  This excludes features not related
;              to the spacecraft potential at higher energies (often 
;              observed downstream of the shock).  Default = 6 eV.
;
;   ABINS:     When using 3D spectra, specify which anode bins to 
;              include in the analysis: 0 = no, 1 = yes.
;              Default = replicate(1,16)
;
;   DBINS:     When using 3D spectra, specify which deflection bins to
;              include in the analysis: 0 = no, 1 = yes.
;              Default = replicate(1,6)
;
;   OBINS:     When using 3D spectra, specify which solid angle bins to
;              include in the analysis: 0 = no, 1 = yes.
;              Default = reform(ABINS#DBINS,96).  Takes precedence over
;              ABINS and OBINS.
;
;   MASK_SC:   Mask the spacecraft blockage.  This is in addition to any
;              masking specified by the above three keywords.
;              Default = 1 (yes).
;
;   BADVAL:    If the algorithm cannot estimate the potential, then set it
;              to this value.  Units = volts.  Default = NaN.
;
;   MIN_LPW_POT : Minumum valid LPW potential.
;
;   MAXALT:    Maximum altitude for replacing SWE/LPW and SWE+ potentials
;              with SWE- or STA- potentials.
;
;   MAXDT:     Maximum time gap to interpolate across.  Default = 64 sec.
;
;   LIST:      Take no action.  Just list the defaults.
;
;OUTPUTS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2017-07-31 15:51:52 -0700 (Mon, 31 Jul 2017) $
; $LastChangedRevision: 23740 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/mvn_scpot_defaults.pro $
;
;-

pro mvn_scpot_defaults, erange=erange2, thresh=thresh2, dEmax=dEmax2, $
               abins=abins, dbins=dbins, obins=obins2, mask_sc=mask_sc, $
               badval=badval2, minflux=minflux2, maxdt=maxdt2, $
               maxalt=maxalt2, min_lpw_pot=min_lpw_pot2, list=list

  @mvn_swe_com
  @mvn_scpot_com

; List the defaults

  if keyword_set(list) then begin
    print, ""
    if (size(Espan,/type) ne 0) then begin
      print, "mvn_scpot_com"
      print, "  erange: ", Espan
      print, "  thresh: ", thresh
      print, "  dEmax:  ", dEmax
      print, "  minflux: ", minflux
      print, "  badval:  ", badval
      print, "  maxalt:  ", maxalt
      print, "  min_lpw_pot: ", min_lpw_pot
    endif else print, "mvn_scpot_com: defaults not set"
    print, ""

    return
  endif

; Defaults for the SWE+ method

  Espan = [3.,30.]        ; energy search range
  thresh = 0.05           ; minimum value of d(logF)/d(logE)
  dEmax = 6.              ; maximum width of d(logF)/d(logE)
  minflux = 1.e6          ; minimum 40-eV energy flux
  obins = swe_sc_mask     ; FOV mask when 3D data are used

; Other defaults

  badval = !values.f_nan  ; fill value for potential when no method works
  maxalt = 1000.          ; maximum altitude for replacing SWE/LPW and SWE+ potentials
  min_lpw_pot = -25.      ; minimum valid LPW potential
  maxdt = 64D             ; maximum time gap to interpolate over

; Override defaults by keyword.  Affects all routines that use mvn_scpot_com.

  if (n_elements(erange2)  gt 1) then Espan = float(minmax(erange2))
  if (size(thresh2,/type)  gt 0) then thresh = float(thresh2)
  if (size(dEmax2,/type)   gt 0) then dEmax = float(dEmax2)
  if (size(minflux2,/type) gt 0) then minflux = float(minflux2)
  if (size(badval2,/type)  gt 0) then badval = float(badval2)
  if (size(maxalt2,/type)  gt 0) then maxalt = float(maxalt2)
  if (size(min_lpw_pot2,/type) gt 0) then min_lpw_pot = float(min_lpw_pot2)

  if ((size(obins,/type) eq 0) or keyword_set(abins) or keyword_set(dbins) or $
      keyword_set(obins2) or (size(mask_sc,/type) ne 0)) then begin
    if (n_elements(abins)  ne 16) then abins = replicate(1B, 16)
    if (n_elements(dbins)  ne  6) then dbins = replicate(1B, 6)
    if (n_elements(obins2) ne 96) then begin
      obins = replicate(1B, 96, 2)
      obins[*,0] = reform(abins # dbins, 96)
      obins[*,1] = obins[*,0]
    endif else obins = byte(obins2 # [1B,1B])
    if (size(mask_sc,/type) eq 0) then mask_sc = 1
    if keyword_set(mask_sc) then obins = swe_sc_mask * obins
  endif

  return

end
