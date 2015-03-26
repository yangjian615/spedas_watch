;+
;PROCEDURE:	mvn_sta_qf14_load
;PURPOSE:	
;	Loads quality flag bit 14 into static apid common blocks - set to 1 during anomolous ion suppression
;
pro mvn_sta_qf14_load

  
  ;;--------------------------------------------------------
  ;;STATIC APIDs
  apid=['2a','c0','c2','c4','c8',$
        'ca','cc','cd','ce','cf','d0',$
        'd1','d2','d3','d4','d6','d7',$
        'd8','d9','da','db']

  ;;--------------------------------------------------------
  ;;Declare all the common block arrays
  common mvn_2a,mvn_2a_ind,mvn_2a_dat
  common mvn_c0,mvn_c0_ind,mvn_c0_dat
  common mvn_c2,mvn_c2_ind,mvn_c2_dat
  common mvn_c4,mvn_c4_ind,mvn_c4_dat
  common mvn_c6,mvn_c6_ind,mvn_c6_dat
  common mvn_c8,mvn_c8_ind,mvn_c8_dat
  common mvn_ca,mvn_ca_ind,mvn_ca_dat
  common mvn_cc,mvn_cc_ind,mvn_cc_dat
  common mvn_cd,mvn_cd_ind,mvn_cd_dat
  common mvn_ce,mvn_ce_ind,mvn_ce_dat
  common mvn_cf,mvn_cf_ind,mvn_cf_dat
  common mvn_d0,mvn_d0_ind,mvn_d0_dat
  common mvn_d1,mvn_d1_ind,mvn_d1_dat
  common mvn_d2,mvn_d2_ind,mvn_d2_dat
  common mvn_d3,mvn_d3_ind,mvn_d3_dat
  common mvn_d4,mvn_d4_ind,mvn_d4_dat
  common mvn_d6,mvn_d6_ind,mvn_d6_dat
  common mvn_d7,mvn_d7_ind,mvn_d7_dat
  common mvn_d8,mvn_d8_ind,mvn_d8_dat
  common mvn_d9,mvn_d9_ind,mvn_d9_dat
  common mvn_da,mvn_da_ind,mvn_da_dat
  common mvn_db,mvn_db_ind,mvn_db_dat


  ;;------------------------
  ;;Define bit
  bit14mask=2^14  
  bit14zero=2^14-1

  ;;------------------------
  ;;Orbit selection 
  ;;All orbits: 713-753
  ;;Odd orbits: 754-1e5
  ;;(except 755,759,823,841)

; do apid c6 then interpolate for all other apids
	qf_c6 = mvn_c6_dat.quality_flag
	tm_c6 = mvn_c6_dat.time
	md_c6 = mvn_c6_dat.mode
        orb = round(mvn_orbit_num(time=tm_c6))

;	store_data,'mvn_sta_c6_quality_flag_old',data={x:tm_c6,y:qf_c6}
;	options,'mvn_sta_c6_quality_flag_old',tplot_routine='bitplot',psym = 1,symsize=1

	ind = where((md_c6 eq 1 or md_c6 eq 2) and $
		((orb ge 713 and orb le 753) or $
		((((orb mod 2) eq 1) and orb gt 754) and $
		((orb ne 755) and (orb ne 759) and (orb ne 823) and (orb ne 841)) )   ),count)

	if count eq 0 then begin
		qf_c6 = qf_c6 and bit14zero
		mvn_c6_dat.quality_flag = qf_c6
		store_data,'mvn_sta_c6_quality_flag',data={x:tm_c6,y:qf_c6}
		options,'mvn_sta_c6_quality_flag',tplot_routine='bitplot',psym = 1,symsize=1
		return
	endif else begin
		qf_c6 = qf_c6 and bit14zero
		qf_c6[ind] = qf_c6[ind] or bit14mask
		mvn_c6_dat.quality_flag = qf_c6
		qf_bm = intarr(n_elements(tm_c6))
		qf_bm[ind] = bit14mask
		store_data,'mvn_sta_c6_quality_flag',data={x:tm_c6+2.,y:qf_c6}
		options,'mvn_sta_c6_quality_flag',tplot_routine='bitplot',psym = 1,symsize=1
	endelse

  ;;------------------------
  ;;Loop through all APIDs except c6
  nn_apid=n_elements(apid)
  for api=0, nn_apid-1 do begin
     temp=execute('nn7=size(mvn_'+apid[api]+'_dat,/type)')
     if nn7 eq 8 then begin
        temp=execute('time=mvn_'+apid[api]+'_dat.time')
        temp=execute('qf=mvn_'+apid[api]+'_dat.quality_flag')
	qf = qf and bit14zero 
	bm = interp(qf_bm,tm_c6,time)
	ind = where ((bm ne bit14mask) and (bm ne 0),count)				; if interpolated, assume bit14=0 - works best for missing c6 packets
; print,api,'  ',apid[api],' ',count,' ',minmax(bm)
	if count gt 0 then bm[ind] = 0
	bm = fix(round(bm))
	temp=execute('mvn_'+apid[api]+'_dat.quality_flag = (qf or bm)')
     endif
  endfor


end
