;+
;PROCEDURE:   mvn_swe_addsta
;PURPOSE:
;  Loads STATIC data and creates tplot variables using STATIC code.
;  By default APID's c0, c6, and ca are loaded.  This is sufficient
;  to generate energy and mass spectra, and to calculate densities
;  of O+ and O2+.  Optionally, you can also load additional APID's.
;
;USAGE:
;  mvn_swe_addsta
;
;INPUTS:
;    None:          Data are loaded based on timespan.
;
;KEYWORDS:
;    APID:          Additional APID's to load.  This procedure always 
;                   loads c0, c6, and ca.  For example, set this keyword
;                   to 'd0' (4D distributions) or 'd1' (4D distributions,
;                   burst) in order to calculate velocity distributions.
;
;    NO1:           Calculate O+ density from STATIC data using moments.
;                   Method is from McFadden's key parameter code.  This
;                   routine attempts to correct for spacecraft potential 
;                   and ion suppression.  Use with caution!
;
;    NO2:           Calculate O2+ density from STATIC data using moments.
;                   Method is from McFadden's key parameter code.  This
;                   routine attempts to correct for spacecraft potential 
;                   and ion suppression.  Use with caution!
;
;    PANS:          Named variable to hold a space delimited string containing
;                   the tplot variable(s) created.
;
;    ADISC:         Enable anode-dependent ion suppression correction.
;                   This is experimental and uses test code for STATIC.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2017-04-04 17:54:53 -0700 (Tue, 04 Apr 2017) $
; $LastChangedRevision: 23103 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_addsta.pro $
;
;CREATED BY:    David L. Mitchell  03/18/14
;-
pro mvn_swe_addsta, apid=apid, nO1=nO1, nO2=nO2, pans=pans, adisc=adisc

; Enable the anode-dependent ion suppression algorithm

  common mvn_sta_kk3_anode, kk3_anode

  kk3_anode = keyword_set(adisc)
  if (kk3_anode) then begin
    uinfo = get_login_info()
    if (uinfo.user_name ne 'mitchell') then begin
      print,"Please contact DLM if you want to use this option."
      kk3_anode = 0
    endif
  endif

  if (kk3_anode) then begin
    kk3 = mvn_sta_get_kk3(mean(timerange()))
    isuppress = 'nbc_4d'
    print,'Using attenuator-dependent ion suppression correction.'
    print,'kk3 = ',kk3
  endif else begin
    print,'Using basic ion suppression correction.'
    isuppress = 'nb_4d'
  endelse

; Load STATIC data

  sta_apid = ['c0','c6','ca']
  if (size(apid,/type) eq 7) then sta_apid = [sta_apid, apid]
  if (keyword_set(nO2) or keyword_set(nO1)) then dopot = 1 else dopot = 0

  mvn_sta_l2_load, sta_apid=sta_apid
  if (dopot) then begin
    kk2 = mvn_sta_get_kk2(mean(timerange()))
    if (kk2 gt 4.) then begin
      msg = string("Warning: STATIC ion suppression factor = ",kk2,format='(a,f3.1)')
      print,msg
      tplot_options,'title',msg
    endif
    mvn_sta_scpot_load
  endif
  mvn_sta_l2_tplot,/replace
  
  pans = ''
  
  get_data, 'mvn_sta_c0_E', index=i
  if (i gt 0) then begin
    pans = pans + ' ' + 'mvn_sta_c0_E'
    ylim,'mvn_sta_c0_E',4e-1,4e4
    options,'mvn_sta_c0_E','ytitle','sta c6!CEnergy!CeV'
  endif

  get_data, 'mvn_sta_c6_M', index=i
  if (i gt 0) then begin
    pans = pans + ' ' + 'mvn_sta_c6_M'
    options,'mvn_sta_c6_M','ytitle','sta c6!CMass!Camu'
  endif

  if (dopot) then begin
    get_data,'mvn_sta_c6_mode',data=tmp7
    ind_mode = where(tmp7.y ne 1 and tmp7.y ne 2, count)
  endif

; Calculate the O2+ density with ion suppression and s/c potential corrections

  if keyword_set(nO2) then begin

    mass_o2 = [25.,40.]
    m_o2 = 32.
    engy_o2 = [0.,100.]
    min_o2 = 25
    
    get_4dt,isuppress,'mvn_sta_get_c6',mass=mass_o2,name='mvn_sta_O2+_raw_density',$
            energy=engy_o2,m_int=m_o2,mincnt=min_o2
    options,'mvn_sta_O2+_raw_density',ytitle='sta c6!C O2+!C!C1/cm!U3',colors=6
    ylim,'mvn_sta_O2+_raw_density',10,100000,1
    get_data,'mvn_sta_O2+_raw_density',data=tmp
    if (count gt 0L) then tmp.y[ind_mode] = !Values.F_NAN
    store_data,'mvn_sta_O2+_raw_density',data=tmp
      
    pans = pans + ' ' + 'mvn_sta_O2+_raw_density'

  endif
  
  if keyword_set(nO1) then begin

	mass_o = [14.,20.]
	m_o = 16.
	engy_o = [0.,100.]
	min_o = 25
    
	get_4dt,isuppress,'mvn_sta_get_c6',mass=mass_o,name='mvn_sta_O+_raw_density',$
	        energy=engy_o,m_int=m_o,mincnt=min_o
	options,'mvn_sta_O+_raw_density',ytitle='sta c6!C  O+!C!C1/cm!U3',colors=4
	ylim,'mvn_sta_O+_raw_density',10,100000,1
	get_data,'mvn_sta_O+_raw_density',data=tmp
	if (count gt 0L) then tmp.y[ind_mode] = !Values.F_NAN
	store_data,'mvn_sta_O+_raw_density',data=tmp
      
    pans = pans + ' ' + 'mvn_sta_O+_raw_density'

  endif

  pans = strtrim(strcompress(pans),2)

  return
  
end
