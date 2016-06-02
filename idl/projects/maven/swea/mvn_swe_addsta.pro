;+
;PROCEDURE:   mvn_swe_addsta
;PURPOSE:
;  Loads STATIC data and creates tplot variables using STATIC code.
;
;USAGE:
;  mvn_swe_addswi
;
;INPUTS:
;    None:          Data are loaded based on timespan.
;
;KEYWORDS:
;    NO2:           Calculate O2+ density from STATIC data using moments.
;                   Method is from McFadden's key parameter code.
;                   Warning: not all corrections applied.
;
;    SC_POT:        If set, estimate the spacecraft potential and ion suppression
;                   correction factor.
;
;    PANS:          Named variable to hold a space delimited string containing
;                   the tplot variable(s) created.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2016-06-01 17:35:10 -0700 (Wed, 01 Jun 2016) $
; $LastChangedRevision: 21253 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_addsta.pro $
;
;CREATED BY:    David L. Mitchell  03/18/14
;-
pro mvn_swe_addsta, nO2=nO2, sc_pot=sc_pot, pans=pans

  mvn_sta_l2_load, sta_apid=['c0','c6','ca']
  if (keyword_set(sc_pot) or keyword_set(nO2)) then mvn_sta_scpot_load
  mvn_sta_l2_tplot,/replace
  
  pans = ''
  
  get_data, 'mvn_sta_c0_E', index=i
  if (i gt 0) then pans = pans + ' ' + 'mvn_sta_c0_E'

  get_data, 'mvn_sta_c6_M', index=i
  if (i gt 0) then pans = pans + ' ' + 'mvn_sta_c6_M'
    
  if keyword_set(nO2) then begin
    get_data,'mvn_sta_c6_mode',data=tmp7
    ind_mode = where(tmp7.y ne 1 and tmp7.y ne 2, count)

    mass_o2 = [25.,40.]
    m_o2 = 32.
    engy_o2 = [0.,100.]
    min_o2 = 25

    get_4dt,'nb_4d','mvn_sta_get_c6',mass=mass_o2,name='mvn_sta_O2+_raw_density',$
            energy=engy_o2,m_int=m_o2,mincnt=min_o2
;   get_4dt,'v_4d','mvn_sta_get_c6',mass=mass_o2,name='mvn_sta_O2+_raw_velocity',$
;           energy=engy_o2,m_int=m_o2,mincnt=min_o2
    options,'mvn_sta_O2+_raw_density',ytitle='sta c6!C O2+!C!C1/cm!U3',colors=6
    ylim,'mvn_sta_O2+_raw_density',10,100000,1
    get_data,'mvn_sta_O2+_raw_density',data=tmp
    if (count gt 0L) then tmp.y[ind_mode] = !Values.F_NAN
    store_data,'mvn_sta_O2+_raw_density',data=tmp
      
    pans = pans + ' ' + 'mvn_sta_O2+_raw_density'

  endif

  pans = strtrim(strcompress(pans),2)

  return
  
end
