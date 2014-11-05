;+
;PROCEDURE: 
;	mvn_swe_shape_par
;PURPOSE:
;	Calculates SWEA energy shape parameter and stores it as a TPLOT variable.
;AUTHOR: 
;	David L. Mitchell
;CALLING SEQUENCE: 
;	mvn_swe_shape_par
;INPUTS: 
;
;KEYWORDS:
;   PANS:      Named variable to return tplot variable created
;
;OUTPUTS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2014-10-31 12:38:13 -0700 (Fri, 31 Oct 2014) $
; $LastChangedRevision: 16102 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_shape_par.pro $
;
;-

pro mvn_swe_shape_par, pans=pans

  compile_opt idl2

  @mvn_swe_com
  
  common mvn_shape_par, df_iono
  
  if (size(df_iono,/type) eq 0) then begin
    df_iono = [-0.2280,  0.3775,  0.4587,  0.0689, -0.0861, -0.0140,  0.0622,  0.0958, $
                0.1089,  0.1106,  0.0483,  0.0071,  0.0467,  0.0470,  0.0293,  0.0571, $
                0.0638,  0.0452,  0.0865,  0.1886,  0.3264,  0.2966,  0.1527,  0.0861, $
                0.0845,  0.1114,  0.1573,  0.1719,  0.1376,  0.0232, -0.0524,  0.0109, $
                0.0525,  0.0743,  0.1065,  0.1232,  0.0928,  0.0521,  0.0392,  0.0192, $
               -0.0191, -0.0712, -0.1264, -0.1769, -0.2073, -0.2146, -0.2251]
  endif
  
  npts = n_elements(mvn_swe_engy)

  if (npts eq 0L) then begin
    print,"No SWEA SPEC data."
    pans = ''
    return
  endif

  old_units = mvn_swe_engy[0].units_name
  mvn_swe_convert_units, mvn_swe_engy, 'eflux'

  t = mvn_swe_engy.time
  e = mvn_swe_engy.energy
  f = mvn_swe_engy.data
  
  n_e = n_elements(df_iono)
  indx = indgen(n_e) + (64 - n_e)

  e = e[indx,*]
  f = alog10(f[indx,*])

; Filter out bad spectra

  gndx = round(total(finite(f),1))
  gndx = where(gndx eq n_e, npts)
  t = t[gndx]
  e = e[*,gndx]
  f = f[*,gndx]

; Take first derivative of log(eflux) w.r.t. log(E)

  df = f
  for i=0L,(npts-1L) do df[*,i] = deriv(f[*,i])

; Calculate electron energy shape parameter

  par = df - (df_iono # replicate(1., npts))
  indx = where(e[*,0] lt 100.)
  par = total(abs(par[indx,*]),1)

  store_data,'mvn_swe_shape_par',data={x:t, y:par}
  pans = 'mvn_swe_shape_par'
  
  mvn_swe_convert_units, mvn_swe_engy, old_units

  return

end
