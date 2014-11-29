;+
;PROCEDURE:	mvn_sta_dead_load
;PURPOSE:	
;	Loads dead-time arrays into apid common blocks for science data products
;
;KEYWORDS:
;	check:		0,1		if set, prints diagnostic data
;
;CREATED BY:	J. McFadden
;VERSION:	1
;LAST MODIFICATION:  14/11/25
;MOD HISTORY:
;
;NOTES:	  
;	Program assumes that "mvn_sta_l0_load" or "mvn_sta_l2_load,/test" has been run 
;	Program assumes Apids c0,c2,c4,c6,c8,ca,cd,cf,d3,d4,d8,da all have 4 second cadence
;	If at some future date we are forced into slower cadence measurements, 
;		then code used for apid cc can be adapted to the above apids.
;-
pro mvn_sta_dead_load,check=check

	common mvn_c8,mvn_c8_ind,mvn_c8_dat 
	common mvn_d8,mvn_d8_ind,mvn_d8_dat 
	common mvn_da,mvn_da_ind,mvn_da_dat 

if size(mvn_c8_dat,/type) eq 0 or size(mvn_d8_dat,/type) eq 0 or size(mvn_da_dat,/type) eq 0 then begin
	print,'Error - apid c8,d8,da data must be loaded, run mvn_sta_l2_load.pro first'
	return
endif


npts = n_elements(mvn_da_dat.time)
rate = dblarr(npts,64,16)
dead = dblarr(npts,64,16)
d1 = mvn_c8_dat.dead1			; 420 ns, fully qualified events
d2 = mvn_c8_dat.dead2			; 660 ns, unqualified events
d3 = mvn_c8_dat.dead3			; 460 ns, stop no start events (and stop then start events)

for i=0l,npts-1 do begin

	min_c8 = min(abs(mvn_c8_dat.time-mvn_da_dat.time[i]),ind_c8)
	min_d8 = min(abs(mvn_d8_dat.time-mvn_da_dat.time[i]),ind_d8)

	if keyword_set(check) and (min_c8 gt 2. or min_d8 gt 2.) then begin
		print,'No matching data at: ',time_string(mvn_da_dat.time[i]),' c8_delta_time= ',min_c8,' d8_delta_time= ',min_d8
		print,'		Using nearest matching data'
	endif

	da = reform(mvn_da_dat.rates[i,*])*16.#replicate(1.,16)
	c8 = reform(replicate(1.,2)#reform(mvn_c8_dat.data[ind_c8,*,*],512),64,16)
	ct = total(c8,2)#replicate(1.,16) > 0.0001
	r1 = mvn_d8_dat.rates[ind_d8,7]/mvn_d8_dat.rates[ind_d8,4]		; fully qualified processed events 
	r2 = mvn_d8_dat.rates[ind_d8,6]/mvn_d8_dat.rates[ind_d8,4]		; rejected events, unqualified events 
	r3 = mvn_d8_dat.rates[ind_d8,5]/mvn_d8_dat.rates[ind_d8,4]		; stop no start
	r4 = (1.-r1-r2-r3)>0.							; stop then start events

	tmp = da*c8/ct 
	dtmp = (da[*,0]-total(tmp,2))#replicate(1./16,16)
	
	rate[i,*,*] = (tmp + dtmp) >0.
;	rate[i,*,*] = tmp

	dead2 = (d1*r1+d2*r2+d3*(r3+r4))*rate[i,*,*]*1.e-9 
	if max(dead2) gt .95 then begin
		print,'Error - dead time correction too large, limiting to x20, time=',time_string(mvn_da_dat.time[i])
		dead2 = dead2 <.95
	endif
	dead[i,*,*] = 1./(1.-dead2)

	if keyword_set(check) and (i mod 1000) eq 0 then print,total(da[*,0]),total(rate[i,*,*]),total(dtmp),minmax(dead[i,*,*])
	if keyword_set(check) and (i mod 1000) eq 0 then print,minmax(da),minmax(rate[i,*,*]),minmax(dtmp),minmax(dead[i,*,*]*rate[i,*,*])
	if keyword_set(check) and (i mod 1000) eq 0 then print,'   '
endfor

print,'Minimum and maximum dead time corrections in array =',minmax(dead)

;  Science data product common blocks
 
	common mvn_c0,mvn_c0_ind,mvn_c0_dat 
	common mvn_c2,mvn_c2_ind,mvn_c2_dat 
	common mvn_c4,mvn_c4_ind,mvn_c4_dat 
	common mvn_c6,mvn_c6_ind,mvn_c6_dat 
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

time = mvn_da_dat.time


if size(mvn_c0_dat,/type) eq 8 then begin
	print,'Adding dead time to apid c0'
	
	dat = mvn_c0_dat
	nenergy = dat.nenergy
	avg_nrg = 64/nenergy
	ndef = dat.ndef
	avg_def = 16/ndef
	nanode = dat.nanode
	avg_an = 16/nanode
	nbins = dat.nbins
	nmass = dat.nmass

	npts = n_elements(dat.time)
	qf_tmp = intarr(npts)
	dead_tmp = dblarr(npts,nenergy*nbins*nmass)

	for i=0,npts-1 do begin
		min_da = min(abs(time-dat.time[i]),ind_da)

;		poor dead-time correction quality flag at bit 0
		if min_da gt 2. then begin
			qf_tmp[i] = 1
			if keyword_set(check) then print,'Apid c0 dead time out of sync, delta time =',min_da,' time =',time_string(dat.time[i])
		endif
		dt = reform(dead[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
		tmp1 = total(total(dt^2,3),1)/total(total(dt,3),1) 
		tmp2 = reform(tmp1,nenergy*ndef) # replicate(1.,nanode*nmass)
		dead_tmp[i,*] = reform(tmp2,nenergy*nbins*nmass)
	endfor
	
	if keyword_set(check) then print,'# QF set, npts =',total(qf_tmp),npts
	if keyword_set(check) then print,'c0 min & max dead times =',minmax(dead_tmp)
	print,'# QF set, npts =',total(qf_tmp),npts
	print,'c0 min & max dead times =',minmax(dead_tmp)
	
	mvn_c0_dat.quality_flag = 2*(mvn_c0_dat.quality_flag/2) + qf_tmp
	mvn_c0_dat.dead[*] = dead_tmp[*]		

endif


if size(mvn_c2_dat,/type) eq 8 then begin
	print,'Adding dead time to apid c2'
	
	dat = mvn_c2_dat
	nenergy = dat.nenergy
	avg_nrg = 64/nenergy
	ndef = dat.ndef
	avg_def = 16/ndef
	nanode = dat.nanode
	avg_an = 16/nanode
	nbins = dat.nbins
	nmass = dat.nmass

	npts = n_elements(dat.time)
	qf_tmp = intarr(npts)
	dead_tmp = dblarr(npts,nenergy*nbins*nmass)

	for i=0,npts-1 do begin
		min_da = min(abs(time-dat.time[i]),ind_da)

;		poor dead-time correction quality flag at bit 0
		if min_da gt 2. then begin
			qf_tmp[i] = 1
			if keyword_set(check) then print,'Apid c2 dead time out of sync, delta time =',min_da,' time =',time_string(dat.time[i])
		endif
		dt = reform(dead[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
		tmp1 = total(total(dt^2,3),1)/total(total(dt,3),1) 
		tmp2 = reform(tmp1,nenergy*ndef) # replicate(1.,nanode*nmass)
		dead_tmp[i,*] = reform(tmp2,nenergy*nbins*nmass)
	endfor
	
	if keyword_set(check) then print,'# QF set, npts =',total(qf_tmp),npts
	if keyword_set(check) then print,'c2 min & max dead times =',minmax(dead_tmp)
	print,'# QF set, npts =',total(qf_tmp),npts
	print,'c2 min & max dead times =',minmax(dead_tmp)
	
	mvn_c2_dat.quality_flag = 2*(mvn_c2_dat.quality_flag/2) + qf_tmp
	mvn_c2_dat.dead[*] = dead_tmp[*]		

endif


if size(mvn_c4_dat,/type) eq 8 then begin
	print,'Adding dead time to apid c4'
	
	dat = mvn_c4_dat
	nenergy = dat.nenergy
	avg_nrg = 64/nenergy
	ndef = dat.ndef
	avg_def = 16/ndef
	nanode = dat.nanode
	avg_an = 16/nanode
	nbins = dat.nbins
	nmass = dat.nmass

	npts = n_elements(dat.time)
	qf_tmp = intarr(npts)
	dead_tmp = dblarr(npts,nenergy*nbins*nmass)

	for i=0,npts-1 do begin
		min_da = min(abs(time-dat.time[i]),ind_da)

;		poor dead-time correction quality flag at bit 0
		if min_da gt 2. then begin
			qf_tmp[i] = 1
			if keyword_set(check) then print,'Apid c4 dead time out of sync, delta time =',min_da,' time =',time_string(dat.time[i])
		endif
		dt = reform(dead[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
		tmp1 = total(total(dt^2,3),1)/total(total(dt,3),1) 
		tmp2 = reform(tmp1,nenergy*ndef) # replicate(1.,nanode*nmass)
		dead_tmp[i,*] = reform(tmp2,nenergy*nbins*nmass)
	endfor
	
	if keyword_set(check) then print,'# QF set, npts =',total(qf_tmp),npts
	if keyword_set(check) then print,'c4 min & max dead times =',minmax(dead_tmp)
	print,'# QF set, npts =',total(qf_tmp),npts
	print,'c4 min & max dead times =',minmax(dead_tmp)
	
	mvn_c4_dat.quality_flag = 2*(mvn_c4_dat.quality_flag/2) + qf_tmp
	mvn_c4_dat.dead[*] = dead_tmp[*]		

endif


if size(mvn_c6_dat,/type) eq 8 then begin
	print,'Adding dead time to apid c6'
	
	dat = mvn_c6_dat
	nenergy = dat.nenergy
	avg_nrg = 64/nenergy
	ndef = dat.ndef
	avg_def = 16/ndef
	nanode = dat.nanode
	avg_an = 16/nanode
	nbins = dat.nbins
	nmass = dat.nmass

	npts = n_elements(dat.time)
	qf_tmp = intarr(npts)
	dead_tmp = dblarr(npts,nenergy*nbins*nmass)

	for i=0,npts-1 do begin
		min_da = min(abs(time-dat.time[i]),ind_da)

;		poor dead-time correction quality flag at bit 0
		if min_da gt 2. then begin
			qf_tmp[i] = 1
			if keyword_set(check) then print,'Apid c6 dead time out of sync, delta time =',min_da,' time =',time_string(dat.time[i])
		endif
		dt = reform(dead[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
		tmp1 = total(total(dt^2,3),1)/total(total(dt,3),1) 
		tmp2 = reform(tmp1,nenergy*ndef) # replicate(1.,nanode*nmass)
		dead_tmp[i,*] = reform(tmp2,nenergy*nbins*nmass)
	endfor
	
	if keyword_set(check) then print,'# QF set, npts =',total(qf_tmp),npts
	if keyword_set(check) then print,'c6 min & max dead times =',minmax(dead_tmp)
	print,'# QF set, npts =',total(qf_tmp),npts
	print,'c6 min & max dead times =',minmax(dead_tmp)
	
	mvn_c6_dat.quality_flag = 2*(mvn_c6_dat.quality_flag/2) + qf_tmp
	mvn_c6_dat.dead[*] = dead_tmp[*]		

endif


if size(mvn_c8_dat,/type) eq 8 then begin
	print,'Adding dead time to apid c8'
	
	dat = mvn_c8_dat
	nenergy = dat.nenergy
	avg_nrg = 64/nenergy
	ndef = dat.ndef
	avg_def = 16/ndef
	nanode = dat.nanode
	avg_an = 16/nanode
	nbins = dat.nbins
	nmass = dat.nmass

	npts = n_elements(dat.time)
	qf_tmp = intarr(npts)
	dead_tmp = dblarr(npts,nenergy*nbins*nmass)

	for i=0,npts-1 do begin
		min_da = min(abs(time-dat.time[i]),ind_da)

;		poor dead-time correction quality flag at bit 0
		if min_da gt 2. then begin
			qf_tmp[i] = 1
			if keyword_set(check) then print,'Apid c8 dead time out of sync, delta time =',min_da,' time =',time_string(dat.time[i])
		endif
		dt = reform(dead[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
		tmp1 = total(total(dt^2,3),1)/total(total(dt,3),1) 
		tmp2 = reform(tmp1,nenergy*ndef) # replicate(1.,nanode*nmass)
		dead_tmp[i,*] = reform(tmp2,nenergy*nbins*nmass)
	endfor
	
	if keyword_set(check) then print,'# QF set, npts =',total(qf_tmp),npts
	if keyword_set(check) then print,'c8 min & max dead times =',minmax(dead_tmp)
	print,'# QF set, npts =',total(qf_tmp),npts
	print,'c8 min & max dead times =',minmax(dead_tmp)
	
	mvn_c8_dat.quality_flag = 2*(mvn_c8_dat.quality_flag/2) + qf_tmp
	mvn_c8_dat.dead[*] = dead_tmp[*]		

endif


if size(mvn_ca_dat,/type) eq 8 then begin
	print,'Adding dead time to apid ca'
	
	dat = mvn_ca_dat
	nenergy = dat.nenergy
	avg_nrg = 64/nenergy
	ndef = dat.ndef
	avg_def = 16/ndef
	nanode = dat.nanode
	avg_an = 16/nanode
	nbins = dat.nbins
	nmass = dat.nmass

	npts = n_elements(dat.time)
	qf_tmp = intarr(npts)
	dead_tmp = dblarr(npts,nenergy*nbins*nmass)

	for i=0,npts-1 do begin
		min_da = min(abs(time-dat.time[i]),ind_da)

;		poor dead-time correction quality flag at bit 0
		if min_da gt 2. then begin
			qf_tmp[i] = 1
			if keyword_set(check) then print,'Apid ca dead time out of sync, delta time =',min_da,' time =',time_string(dat.time[i])
		endif
		dt = reform(dead[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
		tmp1 = total(total(dt^2,3),1)/total(total(dt,3),1) 
		tmp2 = reform(tmp1,nenergy*ndef) # replicate(1.,nanode*nmass)
		dead_tmp[i,*] = reform(tmp2,nenergy*nbins*nmass)
	endfor
	
	if keyword_set(check) then print,'# QF set, npts =',total(qf_tmp),npts
	if keyword_set(check) then print,'ca min & max dead times =',minmax(dead_tmp)
	print,'# QF set, npts =',total(qf_tmp),npts
	print,'ca min & max dead times =',minmax(dead_tmp)
	
	mvn_ca_dat.quality_flag = 2*(mvn_ca_dat.quality_flag/2) + qf_tmp
	mvn_ca_dat.dead[*] = dead_tmp[*]		

endif


if size(mvn_cc_dat,/type) eq 8 then begin
	print,'Adding dead time to apid cc'
		
	dat = mvn_cc_dat
	nenergy = dat.nenergy
	avg_nrg = 64/nenergy
	ndef = dat.ndef
	avg_def = 16/ndef
	nanode = dat.nanode
	avg_an = 16/nanode
	nbins = dat.nbins
	nmass = dat.nmass

	npts = n_elements(dat.time)
	qf_tmp = intarr(npts)
	dead_tmp = dblarr(npts,nenergy*nbins*nmass)

	for i=0,npts-1 do begin
		min_da1 = min(abs(time-dat.time[i]),ind_da1)
		min_da2 = min(abs(time-dat.end_time[i]-4.),ind_da2)
		avg_da = ind_da2-ind_da1+1

;		poor dead-time correction quality flag at bit 0
		if min_da1 gt 2. or min_da2 gt 2. then begin
			qf_tmp[i] = 1
			if keyword_set(check) then print,'Apid cc dead time out of sync, delta time =',min_da1,min_da2,' time =',time_string(dat.time[i])
		endif
		dt = reform(dead[ind_da1:ind_da2,*,*],avg_da,avg_nrg,nenergy,avg_def,ndef)
		tmp1 = total(total(total(dt^2,4),2),1)/total(total(total(dt,4),2),1) 
		tmp2 = reform(tmp1,nenergy*ndef) # replicate(1.,nanode*nmass)
		dead_tmp[i,*] = reform(tmp2,nenergy*nbins*nmass)
	endfor
	
	if keyword_set(check) then print,'# QF set, npts =',total(qf_tmp),npts
	if keyword_set(check) then print,'cc min & max dead times =',minmax(dead_tmp)
	print,'# QF set, npts =',total(qf_tmp),npts
	print,'cc min & max dead times =',minmax(dead_tmp)
	
	mvn_cc_dat.quality_flag = 2*(mvn_cc_dat.quality_flag/2) + qf_tmp
	mvn_cc_dat.dead[*] = dead_tmp[*]		

endif


if size(mvn_cd_dat,/type) eq 8 then begin
	print,'Adding dead time to apid cd'
	
	dat = mvn_cd_dat
	nenergy = dat.nenergy
	avg_nrg = 64/nenergy
	ndef = dat.ndef
	avg_def = 16/ndef
	nanode = dat.nanode
	avg_an = 16/nanode
	nbins = dat.nbins
	nmass = dat.nmass

	npts = n_elements(dat.time)
	qf_tmp = intarr(npts)
	dead_tmp = dblarr(npts,nenergy*nbins*nmass)

	for i=0,npts-1 do begin
		min_da = min(abs(time-dat.time[i]),ind_da)

;		poor dead-time correction quality flag at bit 0
		if min_da gt 2. then begin
			qf_tmp[i] = 1
			if keyword_set(check) then print,'Apid cd dead time out of sync, delta time =',min_da,' time =',time_string(dat.time[i])
		endif
		dt = reform(dead[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
		tmp1 = total(total(dt^2,3),1)/total(total(dt,3),1) 
		tmp2 = reform(tmp1,nenergy*ndef) # replicate(1.,nanode*nmass)
		dead_tmp[i,*] = reform(tmp2,nenergy*nbins*nmass)
	endfor
	
	if keyword_set(check) then print,'# QF set, npts =',total(qf_tmp),npts
	if keyword_set(check) then print,'cd min & max dead times =',minmax(dead_tmp)
	print,'# QF set, npts =',total(qf_tmp),npts
	print,'cd min & max dead times =',minmax(dead_tmp)
	
	mvn_cd_dat.quality_flag = 2*(mvn_cd_dat.quality_flag/2) + qf_tmp
	mvn_cd_dat.dead[*] = dead_tmp[*]		

endif


if size(mvn_ce_dat,/type) eq 8 then begin
	print,'Adding dead time to apid ce'

	dat = mvn_ce_dat
	nenergy = dat.nenergy
	avg_nrg = 64/nenergy
	ndef = dat.ndef
	avg_def = 16/ndef
	nanode = dat.nanode
	avg_an = 16/nanode
	nbins = dat.nbins
	nmass = dat.nmass

	npts = n_elements(dat.time)
	qf_tmp = intarr(npts)
	dead_tmp = dblarr(npts,nenergy*nbins*nmass)

	for i=0,npts-1 do begin
		min_da1 = min(abs(time-dat.time[i]),ind_da1)
		min_da2 = min(abs(time-dat.end_time[i]-4.),ind_da2)
		avg_da = ind_da2-ind_da1+1

;		poor dead-time correction quality flag at bit 0
		if min_da1 gt 2. or min_da2 gt 2. then begin
			qf_tmp[i] = 1
			if keyword_set(check) then print,'Apid ce dead time out of sync, delta time =',min_da1,min_da2,' time =',time_string(dat.time[i])
		endif
		dt = reform(dead[ind_da1:ind_da2,*,*],avg_da,avg_nrg,nenergy,avg_def,ndef)
		tmp1 = total(total(total(dt^2,4),2),1)/total(total(total(dt,4),2),1) 
		tmp2 = reform(tmp1,nenergy*ndef) # replicate(1.,nanode*nmass)
		dead_tmp[i,*] = reform(tmp2,nenergy*nbins*nmass)
	endfor
	
	if keyword_set(check) then print,'# QF set, npts =',total(qf_tmp),npts
	if keyword_set(check) then print,'ce min & max dead times =',minmax(dead_tmp)
	print,'# QF set, npts =',total(qf_tmp),npts
	print,'ce min & max dead times =',minmax(dead_tmp)
	
	mvn_ce_dat.quality_flag = 2*(mvn_ce_dat.quality_flag/2) + qf_tmp
	mvn_ce_dat.dead[*] = dead_tmp[*]		

endif


if size(mvn_cf_dat,/type) eq 8 then begin
	print,'Adding dead time to apid cf'
	
	dat = mvn_cf_dat
	nenergy = dat.nenergy
	avg_nrg = 64/nenergy
	ndef = dat.ndef
	avg_def = 16/ndef
	nanode = dat.nanode
	avg_an = 16/nanode
	nbins = dat.nbins
	nmass = dat.nmass

	npts = n_elements(dat.time)
	qf_tmp = intarr(npts)
	dead_tmp = dblarr(npts,nenergy*nbins*nmass)

	for i=0,npts-1 do begin
		min_da = min(abs(time-dat.time[i]),ind_da)

;		poor dead-time correction quality flag at bit 0
		if min_da gt 2. then begin
			qf_tmp[i] = 1
			if keyword_set(check) then print,'Apid cf dead time out of sync, delta time =',min_da,' time =',time_string(dat.time[i])
		endif
		dt = reform(dead[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
		tmp1 = total(total(dt^2,3),1)/total(total(dt,3),1) 
		tmp2 = reform(tmp1,nenergy*ndef) # replicate(1.,nanode*nmass)
		dead_tmp[i,*] = reform(tmp2,nenergy*nbins*nmass)
	endfor
	
	if keyword_set(check) then print,'# QF set, npts =',total(qf_tmp),npts
	if keyword_set(check) then print,'cf min & max dead times =',minmax(dead_tmp)
	print,'# QF set, npts =',total(qf_tmp),npts
	print,'cf min & max dead times =',minmax(dead_tmp)
	
	mvn_cf_dat.quality_flag = 2*(mvn_cf_dat.quality_flag/2) + qf_tmp
	mvn_cf_dat.dead[*] = dead_tmp[*]		

endif


if size(mvn_d0_dat,/type) eq 8 then begin
	print,'Adding dead time to apid d0'
	
	dat = mvn_d0_dat
	nenergy = dat.nenergy
	avg_nrg = 64/nenergy
	ndef = dat.ndef
	avg_def = 16/ndef
	nanode = dat.nanode
	avg_an = 16/nanode
	nbins = dat.nbins
	nmass = dat.nmass

	npts = n_elements(dat.time)
	qf_tmp = intarr(npts)
	dead_tmp = dblarr(npts,nenergy*nbins*nmass)

	for i=0,npts-1 do begin
		min_da1 = min(abs(time-dat.time[i]),ind_da1)
		min_da2 = min(abs(time-dat.end_time[i]-4.),ind_da2)
		avg_da = ind_da2-ind_da1+1

;		poor dead-time correction quality flag at bit 0
		if min_da1 gt 2. or min_da2 gt 2. then begin
			qf_tmp[i] = 1
			if keyword_set(check) then print,'Apid d0 dead time out of sync, delta time =',min_da1,min_da2,' time =',time_string(dat.time[i])
		endif
		dt = reform(dead[ind_da1:ind_da2,*,*],avg_da,avg_nrg,nenergy,avg_def,ndef)
		tmp1 = total(total(total(dt^2,4),2),1)/total(total(total(dt,4),2),1) 
		tmp2 = reform(tmp1,nenergy*ndef) # replicate(1.,nanode*nmass)
		dead_tmp[i,*] = reform(tmp2,nenergy*nbins*nmass)
	endfor
	
	if keyword_set(check) then print,'# QF set, npts =',total(qf_tmp),npts
	if keyword_set(check) then print,'d0 min & max dead times =',minmax(dead_tmp)
	print,'# QF set, npts =',total(qf_tmp),npts
	print,'d0 min & max dead times =',minmax(dead_tmp)
	
	mvn_d0_dat.quality_flag = 2*(mvn_d0_dat.quality_flag/2) + qf_tmp
	mvn_d0_dat.dead[*] = dead_tmp[*]		

endif


if size(mvn_d1_dat,/type) eq 8 then begin
	print,'Adding dead time to apid d1'
	
	dat = mvn_d1_dat
	nenergy = dat.nenergy
	avg_nrg = 64/nenergy
	ndef = dat.ndef
	avg_def = 16/ndef
	nanode = dat.nanode
	avg_an = 16/nanode
	nbins = dat.nbins
	nmass = dat.nmass

	npts = n_elements(dat.time)
	qf_tmp = intarr(npts)
	dead_tmp = dblarr(npts,nenergy*nbins*nmass)

	for i=0,npts-1 do begin
		min_da1 = min(abs(time-dat.time[i]),ind_da1)
		min_da2 = min(abs(time-dat.end_time[i]-4.),ind_da2)
		avg_da = ind_da2-ind_da1+1

;		poor dead-time correction quality flag at bit 0
		if min_da1 gt 2. or min_da2 gt 2. then begin
			qf_tmp[i] = 1
			if keyword_set(check) then print,'Apid d1 dead time out of sync, delta time =',min_da1,min_da2,' time =',time_string(dat.time[i])
		endif
		dt = reform(dead[ind_da1:ind_da2,*,*],avg_da,avg_nrg,nenergy,avg_def,ndef)
		tmp1 = total(total(total(dt^2,4),2),1)/total(total(total(dt,4),2),1) 
		tmp2 = reform(tmp1,nenergy*ndef) # replicate(1.,nanode*nmass)
		dead_tmp[i,*] = reform(tmp2,nenergy*nbins*nmass)
	endfor
	
	if keyword_set(check) then print,'# QF set, npts =',total(qf_tmp),npts
	if keyword_set(check) then print,'d1 min & max dead times =',minmax(dead_tmp)
	print,'# QF set, npts =',total(qf_tmp),npts
	print,'d1 min & max dead times =',minmax(dead_tmp)
	
	mvn_d1_dat.quality_flag = 2*(mvn_d1_dat.quality_flag/2) + qf_tmp
	mvn_d1_dat.dead[*] = dead_tmp[*]		

endif


if size(mvn_d2_dat,/type) eq 8 then begin
	print,'Adding dead time to apid d2'
	
	dat = mvn_d2_dat
	nenergy = dat.nenergy
	avg_nrg = 64/nenergy
	ndef = dat.ndef
	avg_def = 16/ndef
	nanode = dat.nanode
	avg_an = 16/nanode
	nbins = dat.nbins
	nmass = dat.nmass

	npts = n_elements(dat.time)
	qf_tmp = intarr(npts)
	dead_tmp = dblarr(npts,nenergy*nbins*nmass)

	for i=0,npts-1 do begin
		min_da1 = min(abs(time-dat.time[i]),ind_da1)
		min_da2 = min(abs(time-dat.end_time[i]-4.),ind_da2)
		avg_da = ind_da2-ind_da1+1

;		poor dead-time correction quality flag at bit 0
		if min_da1 gt 2. or min_da2 gt 2. then begin
			qf_tmp[i] = 1
			if keyword_set(check) then print,'Apid d2 dead time out of sync, delta time =',min_da1,min_da2,' time =',time_string(dat.time[i])
		endif
		dt = reform(dead[ind_da1:ind_da2,*,*],avg_da,avg_nrg,nenergy,avg_def,ndef)
		tmp1 = total(total(total(dt^2,4),2),1)/total(total(total(dt,4),2),1) 
		tmp2 = reform(tmp1,nenergy*ndef) # replicate(1.,nanode*nmass)
		dead_tmp[i,*] = reform(tmp2,nenergy*nbins*nmass)
	endfor
	
	if keyword_set(check) then print,'# QF set, npts =',total(qf_tmp),npts
	if keyword_set(check) then print,'d2 min & max dead times =',minmax(dead_tmp)
	print,'# QF set, npts =',total(qf_tmp),npts
	print,'d2 min & max dead times =',minmax(dead_tmp)
	
	mvn_d2_dat.quality_flag = 2*(mvn_d2_dat.quality_flag/2) + qf_tmp
	mvn_d2_dat.dead[*] = dead_tmp[*]		

endif


if size(mvn_d3_dat,/type) eq 8 then begin
	print,'Adding dead time to apid d3'
		
	dat = mvn_d3_dat
	nenergy = dat.nenergy
	avg_nrg = 64/nenergy
	ndef = dat.ndef
	avg_def = 16/ndef
	nanode = dat.nanode
	avg_an = 16/nanode
	nbins = dat.nbins
	nmass = dat.nmass

	npts = n_elements(dat.time)
	qf_tmp = intarr(npts)
	dead_tmp = dblarr(npts,nenergy*nbins*nmass)

	for i=0,npts-1 do begin
		min_da = min(abs(time-dat.time[i]),ind_da)

;		poor dead-time correction quality flag at bit 0
		if min_da gt 2. then begin
			qf_tmp[i] = 1
			if keyword_set(check) then print,'Apid d3 dead time out of sync, delta time =',min_da,' time =',time_string(dat.time[i])
		endif
		dt = reform(dead[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
		tmp1 = total(total(dt^2,3),1)/total(total(dt,3),1) 
		tmp2 = reform(tmp1,nenergy*ndef) # replicate(1.,nanode*nmass)
		dead_tmp[i,*] = reform(tmp2,nenergy*nbins*nmass)
	endfor
	
	if keyword_set(check) then print,'# QF set, npts =',total(qf_tmp),npts
	if keyword_set(check) then print,'d3 min & max dead times =',minmax(dead_tmp)
	print,'# QF set, npts =',total(qf_tmp),npts
	print,'d3 min & max dead times =',minmax(dead_tmp)
	
	mvn_d3_dat.quality_flag = 2*(mvn_d3_dat.quality_flag/2) + qf_tmp
	mvn_d3_dat.dead[*] = dead_tmp[*]		

endif


if size(mvn_d4_dat,/type) eq 8 then begin
	print,'Adding dead time to apid d4'
	
	dat = mvn_d4_dat
	nenergy = dat.nenergy
	avg_nrg = 64/nenergy
	ndef = dat.ndef
	avg_def = 16/ndef
	nanode = dat.nanode
	avg_an = 16/nanode
	nbins = dat.nbins
	nmass = dat.nmass

	npts = n_elements(dat.time)
	qf_tmp = intarr(npts)
	dead_tmp = dblarr(npts,nenergy*nbins*nmass)

	for i=0,npts-1 do begin
		min_da = min(abs(time-dat.time[i]),ind_da)

;		poor dead-time correction quality flag at bit 0
		if min_da gt 2. then begin
			qf_tmp[i] = 1
			if keyword_set(check) then print,'Apid d4 dead time out of sync, delta time =',min_da,' time =',time_string(dat.time[i])
		endif
		dt = reform(dead[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
		tmp1 = total(total(dt^2,3),1)/total(total(dt,3),1) 
		tmp2 = reform(tmp1,nenergy*ndef) # replicate(1.,nanode*nmass)
		dead_tmp[i,*] = reform(tmp2,nenergy*nbins*nmass)
	endfor
	
	if keyword_set(check) then print,'# QF set, npts =',total(qf_tmp),npts
	if keyword_set(check) then print,'d4 min & max dead times =',minmax(dead_tmp)
	print,'# QF set, npts =',total(qf_tmp),npts
	print,'d4 min & max dead times =',minmax(dead_tmp)
	
	mvn_d4_dat.quality_flag = 2*(mvn_d4_dat.quality_flag/2) + qf_tmp
	mvn_d4_dat.dead[*] = dead_tmp[*]		

endif


end
