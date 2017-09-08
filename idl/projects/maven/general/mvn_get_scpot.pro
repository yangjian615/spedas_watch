;+
;FUNCTION: 
;	mvn_get_scpot
;
;PURPOSE:
;	Given a time, returns the spacecraft potential.  Only works after
;   the potentials have been restored/calculated by mvn_scpot.
; 
;AUTHOR: 
;	David L. Mitchell
;
;CALLING SEQUENCE: 
;	pot = mvn_get_scpot(time)
;
;INPUTS: 
;   time:      Time or array of times for getting the potential, in
;              any format accepted by time_double().
;
;KEYWORDS:
;   MAXDT:     Maximum gap to interpolate across.  Default = 32 sec.
;
;   BADVAL:    Fill value for invalid potentials.  Default = NaN.
;
;OUTPUTS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2017-09-07 11:38:06 -0700 (Thu, 07 Sep 2017) $
; $LastChangedRevision: 23908 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/mvn_get_scpot.pro $
;
;-

function mvn_get_scpot, time, maxdt=maxdt

  @mvn_swe_com

  if not keyword_set(maxdt) then maxdt = 32D
  if (size(badval,/type) eq 0) then badval = !values.f_nan

  npot = n_elements(swe_sc_pot)
  ntime = n_elements(time)

  case (ntime) of
     0   : begin
             print,'MVN_GET_SCPOT: You must supply a time!'
             return, badval
           end
     1   : pot = badval
    else : pot = replicate(badval, ntime)
  endcase

  if (npot lt 2) then begin
    print,'MVN_GET_SCPOT: Potential not determined!  Use mvn_scpot first.'
    return, pot
  endif

  t = time_double(time)
  tmin = min(swe_sc_pot.time, max=tmax)
  indx = where((t ge tmin) and (t le tmax), ngud, ncomplement=nbad)
  if (nbad gt 0L) then begin
    pct = 100.*float(nbad)/float(ntime)
    if (pct gt 5.) then begin
      msg = strtrim(round(pct),2)
      print,'MVN_GET_SCPOT: ',msg,'% of input times are out of range.'
    endif
  endif

  if (ngud gt 0L) then begin
    pot[indx] = interp(swe_sc_pot.potential, swe_sc_pot.time, t[indx])

    nndx = nn(swe_sc_pot.time, t[indx])
    gap = where(abs(t[indx] - swe_sc_pot[nndx].time) gt maxdt, count)
    if (count gt 0L) then begin
      pot[indx[gap]] = badval
      print,'MVN_GET_SCPOT: Some gaps exist.'
    endif
  endif

  return, pot

end
