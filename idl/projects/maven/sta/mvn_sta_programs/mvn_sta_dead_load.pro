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
;			14/12/20	changed algorithm to corrected valid events deadtime
;						Deadtime = total(valid*dead,averaged)/total(valid,averaged)
;						where "valid" are the valid events
;							valid(energy,def) is extrapolated from apid c0 and c8
;						where "dead" is determined by rates 
;							dead(energy,def) is extrapolated from apid da and c8
;							dead calculation also uses apid d8 to determine relative amounts event types (see d1,d2,d3 in code)
;						where "averaged" accounts for averaging over energy or deflection
;			15/01/17	added mcp droop correction
;NOTES:	  
;	Program assumes that "mvn_sta_l0_load" or "mvn_sta_l2_load,/test" has been run 
;	Program requires c0,c8,d8,da packets are available at 4 sec cadence
;	Program assumes Apids c2,c4,c6,ca,cd,cf,d3,d4 all have 4 second cadence
;		If at some future date we are forced into slower cadence measurements, 
;		then code used for apid cc can be adapted to the above apids.
;
;-
pro mvn_sta_dead_load,check=check,dead_droop=dead_droop

	common mvn_c0,mvn_c0_ind,mvn_c0_dat 
	common mvn_c8,mvn_c8_ind,mvn_c8_dat 
	common mvn_ca,mvn_ca_ind,mvn_ca_dat 
	common mvn_d8,mvn_d8_ind,mvn_d8_dat 
	common mvn_da,mvn_da_ind,mvn_da_dat 

if size(mvn_c0_dat,/type) eq 0 or size(mvn_c8_dat,/type) eq 0 or size(mvn_ca_dat,/type) eq 0 or size(mvn_d8_dat,/type) eq 0 or size(mvn_da_dat,/type) eq 0 then begin
	print,'Error - apid c0,c8,ca,d8,da data must be loaded, run mvn_sta_l2_load.pro first'
	return
endif


npts = n_elements(mvn_da_dat.time)
rate = dblarr(npts,64,16)
dead = dblarr(npts,64,16)
droop = dblarr(npts,64,16)
valid = dblarr(npts,64,16)
qual = intarr(npts)
d1 = mvn_c8_dat.dead1						; 420 ns, fully qualified events
d2 = mvn_c8_dat.dead2						; 660 ns, unqualified events
d3 = mvn_c8_dat.dead3						; 460 ns, stop no start events (and stop then start events)

if not keyword_set(dead_droop) then dead_droop=1000.		; this was empirically determined from data on 20150107-1520UT, seems good to ~10% 

for i=0l,npts-1 do begin

	min_c0 = min(abs(mvn_c0_dat.time-mvn_da_dat.time[i]),ind_c0)
	min_c8 = min(abs(mvn_c8_dat.time-mvn_da_dat.time[i]),ind_c8)
	min_ca = min(abs(mvn_ca_dat.time-mvn_da_dat.time[i]),ind_ca)
	min_d8 = min(abs(mvn_d8_dat.time-mvn_da_dat.time[i]),ind_d8)

	if (min_c0 gt 2. or min_c8 gt 2. or min_ca gt 2. or min_d8 gt 2.) then begin
		if keyword_set(check) then print,'No matching data at: ',time_string(mvn_da_dat.time[i]),' c0_delta_time= ',min_c0,' c8_delta_time= ',min_c8,' ca_delta_time= ',min_ca,' d8_delta_time= ',min_d8
		if keyword_set(check) then print,'		Using nearest matching data'
		qual[i]=qual[i]+16
	endif

	c0 = 1.*reform(mvn_c0_dat.data[ind_c0,*,0]+mvn_c0_dat.data[ind_c0,*,1])#replicate(1.,16)	; apid c0 is valid counts vs energy, averaged over mass
	da = 1.*reform(mvn_da_dat.rates[i,*])*16.#replicate(1.,16)					; apid da is a rate (Hz), *16. keeps it a rate when normalized below by c8/ct
	c8 = 1.*reform(replicate(1.,2)#reform(mvn_c8_dat.data[ind_c8,*,*],512),64,16)

	ca = total(reform(mvn_ca_dat.data[ind_ca,*,*],16,4,16),2)
	ca1 = fltarr(16) 
	for j=0,15 do ca1[j] = max(ca[j,*]/total(ca[j,*]))
	ca2 = reform(replicate(1.,4)#ca1,64)#replicate(1.,16)

	ct = 1.*total(c8,2)#replicate(1.,16) > 0.0001
	r1 = mvn_d8_dat.rates[ind_d8,7]/mvn_d8_dat.rates[ind_d8,4]				; fully qualified processed events 
	r2 = mvn_d8_dat.rates[ind_d8,6]/mvn_d8_dat.rates[ind_d8,4]				; rejected events, unqualified events 
	r3 = mvn_d8_dat.rates[ind_d8,5]/mvn_d8_dat.rates[ind_d8,4]				; stop no start
	r4 = (1.-r1-r2-r3)>0.									; stop then start events
		
	tmp = da*c8/ct 										; da rate vs E -> rate per accum 
	dtmp = (da[*,0]-total(tmp,2))#replicate(1./16,16)					; corrects for small round off error

	tmp7 = c0*c8/ct 										; da rate vs E -> rate per accum 
	dtmp7 = (c0[*,0]-total(tmp7,2))#replicate(1./16,16)					; corrects for small round off error
	
	rate[i,*,*] = (tmp + dtmp) >0.								; gets rid of round off errors

	valid[i,*,*] = (tmp7 + dtmp7) >0.							; gets rid of round off errors

	dead2 = (d1*r1+d2*r2+d3*(r3+r4))*rate[i,*,*]*1.e-9 
	if max(dead2) gt .95 then begin
		print,'Error - dead time correction too large, limiting to x20, time=',time_string(mvn_da_dat.time[i])
		dead2 = dead2 <.95
	endif
	dead[i,*,*] = 1./(1.-dead2)

	droop[i,*,*] = 1./(1.-(dead_droop*rate[i,*,*]*ca2*1.e-9 < .9))				; this is an empirical formula

	if keyword_set(check) and (i mod 1000) eq 0 then print,total(da[*,0]),total(rate[i,*,*]),total(dtmp),minmax(dead[i,*,*])
	if keyword_set(check) and (i mod 1000) eq 0 then print,minmax(da)
	if keyword_set(check) and (i mod 1000) eq 0 then print,'rate',minmax(rate[i,*,*]),minmax(dtmp)
	if keyword_set(check) and (i mod 1000) eq 0 then print,'dead',minmax(dead2)
	if keyword_set(check) and (i mod 1000) eq 0 then print,'dead_droop ',minmax(dead_droop*rate[i,*,*]*ca2*1.e-9),total(dead_droop*rate[i,*,*]*ca2*1.e-9)/(64.*16.)

	if (max(dead[i,*,*])  gt 2.0) then qual[i]=qual[i]+4					; we may want to change this
	if (max(droop[i,*,*]) gt 2.0) then qual[i]=qual[i]+8					; we may want to change this

endfor

if keyword_set(check) then print,minmax(dead)
if keyword_set(check) then print,minmax(droop)

dead = dead * droop

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

;		rt_dt = reform(rate[ind_da,*,*]*dead[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
;		rt = reform(rate[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
		rt_dt = reform(valid[ind_da,*,*]*dead[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
		rt = reform(valid[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
		tmp1 = reform(total(total(rt_dt,3),1),nenergy*ndef) # replicate(1.,nanode*nmass)
		tmp2 = reform(total(total(rt,3),1),nenergy*ndef) # replicate(1.,nanode*nmass) 

		dead_tmp[i,*] = reform(tmp1/(tmp2>.0001),nenergy*ndef*nanode*nmass) > 1.
		qf_tmp[i] = qual[ind_da]
	endfor
	
	if keyword_set(check) then print,'# QF set, npts =',total(qf_tmp),npts
	if keyword_set(check) then print,'c0 min & max dead times =',minmax(dead_tmp)
	print,'# QF set, npts =',total(qf_tmp),npts
	print,'c0 min & max dead times =',minmax(dead_tmp)
	
	mvn_c0_dat.quality_flag = (mvn_c0_dat.quality_flag and 32739) or qf_tmp
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

;		rt_dt = reform(rate[ind_da,*,*]*dead[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
;		rt = reform(rate[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
		rt_dt = reform(valid[ind_da,*,*]*dead[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
		rt = reform(valid[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
		tmp1 = reform(total(total(rt_dt,3),1),nenergy*ndef) # replicate(1.,nanode*nmass)
		tmp2 = reform(total(total(rt,3),1),nenergy*ndef) # replicate(1.,nanode*nmass) 

		dead_tmp[i,*] = reform(tmp1/(tmp2>.0001),nenergy*ndef*nanode*nmass) > 1.
		qf_tmp[i] = qual[ind_da]
	endfor
	
	if keyword_set(check) then print,'# QF set, npts =',total(qf_tmp),npts
	if keyword_set(check) then print,'c2 min & max dead times =',minmax(dead_tmp)
	print,'# QF set, npts =',total(qf_tmp),npts
	print,'c2 min & max dead times =',minmax(dead_tmp)
	
	mvn_c2_dat.quality_flag = (mvn_c2_dat.quality_flag and 32739) or qf_tmp
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

;		rt_dt = reform(rate[ind_da,*,*]*dead[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
;		rt = reform(rate[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
		rt_dt = reform(valid[ind_da,*,*]*dead[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
		rt = reform(valid[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
		tmp1 = reform(total(total(rt_dt,3),1),nenergy*ndef) # replicate(1.,nanode*nmass)
		tmp2 = reform(total(total(rt,3),1),nenergy*ndef) # replicate(1.,nanode*nmass) 

		dead_tmp[i,*] = reform(tmp1/(tmp2>.0001),nenergy*ndef*nanode*nmass) > 1.
		qf_tmp[i] = qual[ind_da]
	endfor
	
	if keyword_set(check) then print,'# QF set, npts =',total(qf_tmp),npts
	if keyword_set(check) then print,'c4 min & max dead times =',minmax(dead_tmp)
	print,'# QF set, npts =',total(qf_tmp),npts
	print,'c4 min & max dead times =',minmax(dead_tmp)
	
	mvn_c4_dat.quality_flag = (mvn_c4_dat.quality_flag and 32739) or qf_tmp
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

;		rt_dt = reform(rate[ind_da,*,*]*dead[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
;		rt = reform(rate[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
		rt_dt = reform(valid[ind_da,*,*]*dead[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
		rt = reform(valid[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
		tmp1 = reform(total(total(rt_dt,3),1),nenergy*ndef) # replicate(1.,nanode*nmass)
		tmp2 = reform(total(total(rt,3),1),nenergy*ndef) # replicate(1.,nanode*nmass) 

		dead_tmp[i,*] = reform(tmp1/(tmp2>.0001),nenergy*ndef*nanode*nmass) > 1.
		qf_tmp[i] = qual[ind_da]
	endfor
	
	if keyword_set(check) then print,'# QF set, npts =',total(qf_tmp),npts
	if keyword_set(check) then print,'c6 min & max dead times =',minmax(dead_tmp)
	print,'# QF set, npts =',total(qf_tmp),npts
	print,'c6 min & max dead times =',minmax(dead_tmp)
	
	mvn_c6_dat.quality_flag = (mvn_c6_dat.quality_flag and 32739) or qf_tmp
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

;		rt_dt = reform(rate[ind_da,*,*]*dead[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
;		rt = reform(rate[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
		rt_dt = reform(valid[ind_da,*,*]*dead[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
		rt = reform(valid[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
		tmp1 = reform(total(total(rt_dt,3),1),nenergy*ndef) # replicate(1.,nanode*nmass)
		tmp2 = reform(total(total(rt,3),1),nenergy*ndef) # replicate(1.,nanode*nmass) 

		dead_tmp[i,*] = reform(tmp1/(tmp2>.0001),nenergy*ndef*nanode*nmass) > 1.
		qf_tmp[i] = qual[ind_da]
	endfor
	
	if keyword_set(check) then print,'# QF set, npts =',total(qf_tmp),npts
	if keyword_set(check) then print,'c8 min & max dead times =',minmax(dead_tmp)
	print,'# QF set, npts =',total(qf_tmp),npts
	print,'c8 min & max dead times =',minmax(dead_tmp)
	
	mvn_c8_dat.quality_flag = (mvn_c8_dat.quality_flag and 32739) or qf_tmp
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

;		rt_dt = reform(rate[ind_da,*,*]*dead[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
;		rt = reform(rate[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
		rt_dt = reform(valid[ind_da,*,*]*dead[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
		rt = reform(valid[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
		tmp1 = reform(total(total(rt_dt,3),1),nenergy*ndef) # replicate(1.,nanode*nmass)
		tmp2 = reform(total(total(rt,3),1),nenergy*ndef) # replicate(1.,nanode*nmass) 

		dead_tmp[i,*] = reform(tmp1/(tmp2>.0001),nenergy*ndef*nanode*nmass) > 1.
		qf_tmp[i] = qual[ind_da]
	endfor
	
	if keyword_set(check) then print,'# QF set, npts =',total(qf_tmp),npts
	if keyword_set(check) then print,'ca min & max dead times =',minmax(dead_tmp)
	print,'# QF set, npts =',total(qf_tmp),npts
	print,'ca min & max dead times =',minmax(dead_tmp)
	
	mvn_ca_dat.quality_flag = (mvn_ca_dat.quality_flag and 32739) or qf_tmp
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
		min_da2 = min(abs(time-dat.end_time[i]+4.),ind_da2)
		avg_da = ind_da2-ind_da1+1

;		rt_dt = reform(rate[ind_da1:ind_da2,*,*]*dead[ind_da1:ind_da2,*,*],avg_da,avg_nrg,nenergy,avg_def,ndef)
;		rt = reform(rate[ind_da1:ind_da2,*,*],avg_da,avg_nrg,nenergy,avg_def,ndef)
		rt_dt = reform(valid[ind_da1:ind_da2,*,*]*dead[ind_da1:ind_da2,*,*],avg_da,avg_nrg,nenergy,avg_def,ndef)
		rt = reform(valid[ind_da1:ind_da2,*,*],avg_da,avg_nrg,nenergy,avg_def,ndef)
		tmp1 = reform(total(total(total(rt_dt,4),2),1),nenergy*ndef) # replicate(1.,nanode*nmass)
		tmp2 = reform(total(total(total(rt,4),2),1),nenergy*ndef) # replicate(1.,nanode*nmass) 

		dead_tmp[i,*] = reform(tmp1/(tmp2>.0001),nenergy*ndef*nanode*nmass) > 1.
		for j=ind_da1,ind_da2 do qf_tmp[i] = (qf_tmp[i] or qual[j])
	endfor
	
	if keyword_set(check) then print,'# QF set, npts =',total(qf_tmp),npts
	if keyword_set(check) then print,'cc min & max dead times =',minmax(dead_tmp)
	print,'# QF set, npts =',total(qf_tmp),npts
	print,'cc min & max dead times =',minmax(dead_tmp)
	
	mvn_cc_dat.quality_flag = (mvn_cc_dat.quality_flag and 32739) or qf_tmp
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

;		rt_dt = reform(rate[ind_da,*,*]*dead[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
;		rt = reform(rate[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
		rt_dt = reform(valid[ind_da,*,*]*dead[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
		rt = reform(valid[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
		tmp1 = reform(total(total(rt_dt,3),1),nenergy*ndef) # replicate(1.,nanode*nmass)
		tmp2 = reform(total(total(rt,3),1),nenergy*ndef) # replicate(1.,nanode*nmass) 

		dead_tmp[i,*] = reform(tmp1/(tmp2>.0001),nenergy*ndef*nanode*nmass) > 1.
		qf_tmp[i] = qual[ind_da]
	endfor
	
	if keyword_set(check) then print,'# QF set, npts =',total(qf_tmp),npts
	if keyword_set(check) then print,'cd min & max dead times =',minmax(dead_tmp)
	print,'# QF set, npts =',total(qf_tmp),npts
	print,'cd min & max dead times =',minmax(dead_tmp)
	
	mvn_cd_dat.quality_flag = (mvn_cd_dat.quality_flag and 32739) or qf_tmp
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
		min_da2 = min(abs(time-dat.end_time[i]+4.),ind_da2)
		avg_da = ind_da2-ind_da1+1

;		rt_dt = reform(rate[ind_da1:ind_da2,*,*]*dead[ind_da1:ind_da2,*,*],avg_da,avg_nrg,nenergy,avg_def,ndef)
;		rt = reform(rate[ind_da1:ind_da2,*,*],avg_da,avg_nrg,nenergy,avg_def,ndef)
		rt_dt = reform(valid[ind_da1:ind_da2,*,*]*dead[ind_da1:ind_da2,*,*],avg_da,avg_nrg,nenergy,avg_def,ndef)
		rt = reform(valid[ind_da1:ind_da2,*,*],avg_da,avg_nrg,nenergy,avg_def,ndef)
		tmp1 = reform(total(total(total(rt_dt,4),2),1),nenergy*ndef) # replicate(1.,nanode*nmass)
		tmp2 = reform(total(total(total(rt,4),2),1),nenergy*ndef) # replicate(1.,nanode*nmass) 

		dead_tmp[i,*] = reform(tmp1/(tmp2>.0001),nenergy*ndef*nanode*nmass) > 1.
		for j=ind_da1,ind_da2 do qf_tmp[i] = (qf_tmp[i] or qual[j])
	endfor
	
	if keyword_set(check) then print,'# QF set, npts =',total(qf_tmp),npts
	if keyword_set(check) then print,'ce min & max dead times =',minmax(dead_tmp)
	print,'# QF set, npts =',total(qf_tmp),npts
	print,'ce min & max dead times =',minmax(dead_tmp)
	
	mvn_ce_dat.quality_flag = (mvn_ce_dat.quality_flag and 32739) or qf_tmp
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

;		rt_dt = reform(rate[ind_da,*,*]*dead[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
;		rt = reform(rate[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
		rt_dt = reform(valid[ind_da,*,*]*dead[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
		rt = reform(valid[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
		tmp1 = reform(total(total(rt_dt,3),1),nenergy*ndef) # replicate(1.,nanode*nmass)
		tmp2 = reform(total(total(rt,3),1),nenergy*ndef) # replicate(1.,nanode*nmass) 

		dead_tmp[i,*] = reform(tmp1/(tmp2>.0001),nenergy*ndef*nanode*nmass) > 1.
		qf_tmp[i] = qual[ind_da]
	endfor
	
	if keyword_set(check) then print,'# QF set, npts =',total(qf_tmp),npts
	if keyword_set(check) then print,'cf min & max dead times =',minmax(dead_tmp)
	print,'# QF set, npts =',total(qf_tmp),npts
	print,'cf min & max dead times =',minmax(dead_tmp)
	
	mvn_cf_dat.quality_flag = (mvn_cf_dat.quality_flag and 32739) or qf_tmp
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
		min_da2 = min(abs(time-dat.end_time[i]+4.),ind_da2)
		avg_da = ind_da2-ind_da1+1

;		rt_dt = reform(rate[ind_da1:ind_da2,*,*]*dead[ind_da1:ind_da2,*,*],avg_da,avg_nrg,nenergy,avg_def,ndef)
;		rt = reform(rate[ind_da1:ind_da2,*,*],avg_da,avg_nrg,nenergy,avg_def,ndef)
		rt_dt = reform(valid[ind_da1:ind_da2,*,*]*dead[ind_da1:ind_da2,*,*],avg_da,avg_nrg,nenergy,avg_def,ndef)
		rt = reform(valid[ind_da1:ind_da2,*,*],avg_da,avg_nrg,nenergy,avg_def,ndef)
		tmp1 = reform(total(total(total(rt_dt,4),2),1),nenergy*ndef) # replicate(1.,nanode*nmass)
		tmp2 = reform(total(total(total(rt,4),2),1),nenergy*ndef) # replicate(1.,nanode*nmass) 

		dead_tmp[i,*] = reform(tmp1/(tmp2>.0001),nenergy*ndef*nanode*nmass) > 1.
		for j=ind_da1,ind_da2 do qf_tmp[i] = (qf_tmp[i] or qual[j])
	endfor
	
	if keyword_set(check) then print,'# QF set, npts =',total(qf_tmp),npts
	if keyword_set(check) then print,'d0 min & max dead times =',minmax(dead_tmp)
	print,'# QF set, npts =',total(qf_tmp),npts
	print,'d0 min & max dead times =',minmax(dead_tmp)
	
	mvn_d0_dat.quality_flag = (mvn_d0_dat.quality_flag and 32739) or qf_tmp
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
		min_da2 = min(abs(time-dat.end_time[i]+4.),ind_da2)
		avg_da = ind_da2-ind_da1+1

;		rt_dt = reform(rate[ind_da1:ind_da2,*,*]*dead[ind_da1:ind_da2,*,*],avg_da,avg_nrg,nenergy,avg_def,ndef)
;		rt = reform(rate[ind_da1:ind_da2,*,*],avg_da,avg_nrg,nenergy,avg_def,ndef)
		rt_dt = reform(valid[ind_da1:ind_da2,*,*]*dead[ind_da1:ind_da2,*,*],avg_da,avg_nrg,nenergy,avg_def,ndef)
		rt = reform(valid[ind_da1:ind_da2,*,*],avg_da,avg_nrg,nenergy,avg_def,ndef)
		tmp1 = reform(total(total(total(rt_dt,4),2),1),nenergy*ndef) # replicate(1.,nanode*nmass)
		tmp2 = reform(total(total(total(rt,4),2),1),nenergy*ndef) # replicate(1.,nanode*nmass) 

		dead_tmp[i,*] = reform(tmp1/(tmp2>.0001),nenergy*ndef*nanode*nmass) > 1.
		for j=ind_da1,ind_da2 do qf_tmp[i] = (qf_tmp[i] or qual[j])
	endfor
	
	if keyword_set(check) then print,'# QF set, npts =',total(qf_tmp),npts
	if keyword_set(check) then print,'d1 min & max dead times =',minmax(dead_tmp)
	print,'# QF set, npts =',total(qf_tmp),npts
	print,'d1 min & max dead times =',minmax(dead_tmp)
	
	mvn_d1_dat.quality_flag = (mvn_d1_dat.quality_flag and 32739) or qf_tmp
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
		min_da2 = min(abs(time-dat.end_time[i]+4.),ind_da2)
		avg_da = ind_da2-ind_da1+1

;		rt_dt = reform(rate[ind_da1:ind_da2,*,*]*dead[ind_da1:ind_da2,*,*],avg_da,avg_nrg,nenergy,avg_def,ndef)
;		rt = reform(rate[ind_da1:ind_da2,*,*],avg_da,avg_nrg,nenergy,avg_def,ndef)
		rt_dt = reform(valid[ind_da1:ind_da2,*,*]*dead[ind_da1:ind_da2,*,*],avg_da,avg_nrg,nenergy,avg_def,ndef)
		rt = reform(valid[ind_da1:ind_da2,*,*],avg_da,avg_nrg,nenergy,avg_def,ndef)
		tmp1 = reform(total(total(total(rt_dt,4),2),1),nenergy*ndef) # replicate(1.,nanode*nmass)
		tmp2 = reform(total(total(total(rt,4),2),1),nenergy*ndef) # replicate(1.,nanode*nmass) 

		dead_tmp[i,*] = reform(tmp1/(tmp2>.0001),nenergy*ndef*nanode*nmass) > 1.
		for j=ind_da1,ind_da2 do qf_tmp[i] = (qf_tmp[i] or qual[j])
	endfor
	
	if keyword_set(check) then print,'# QF set, npts =',total(qf_tmp),npts
	if keyword_set(check) then print,'d2 min & max dead times =',minmax(dead_tmp)
	print,'# QF set, npts =',total(qf_tmp),npts
	print,'d2 min & max dead times =',minmax(dead_tmp)
	
	mvn_d2_dat.quality_flag = (mvn_d2_dat.quality_flag and 32739) or qf_tmp
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

;		rt_dt = reform(rate[ind_da,*,*]*dead[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
;		rt = reform(rate[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
		rt_dt = reform(valid[ind_da,*,*]*dead[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
		rt = reform(valid[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
		tmp1 = reform(total(total(rt_dt,3),1),nenergy*ndef) # replicate(1.,nanode*nmass)
		tmp2 = reform(total(total(rt,3),1),nenergy*ndef) # replicate(1.,nanode*nmass) 

		dead_tmp[i,*] = reform(tmp1/(tmp2>.0001),nenergy*ndef*nanode*nmass) > 1.
		qf_tmp[i] = qual[ind_da]
	endfor
	
	if keyword_set(check) then print,'# QF set, npts =',total(qf_tmp),npts
	if keyword_set(check) then print,'d3 min & max dead times =',minmax(dead_tmp)
	print,'# QF set, npts =',total(qf_tmp),npts
	print,'d3 min & max dead times =',minmax(dead_tmp)
	
	mvn_d3_dat.quality_flag = (mvn_d3_dat.quality_flag and 32739) or qf_tmp
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

;		rt_dt = reform(rate[ind_da,*,*]*dead[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
;		rt = reform(rate[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
		rt_dt = reform(valid[ind_da,*,*]*dead[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
		rt = reform(valid[ind_da,*,*],avg_nrg,nenergy,avg_def,ndef)
		tmp1 = reform(total(total(rt_dt,3),1),nenergy*ndef) # replicate(1.,nanode*nmass)
		tmp2 = reform(total(total(rt,3),1),nenergy*ndef) # replicate(1.,nanode*nmass) 

		dead_tmp[i,*] = reform(tmp1/(tmp2>.0001),nenergy*ndef*nanode*nmass) > 1.
		qf_tmp[i] = qual[ind_da]
	endfor
	
	if keyword_set(check) then print,'# QF set, npts =',total(qf_tmp),npts
	if keyword_set(check) then print,'d4 min & max dead times =',minmax(dead_tmp)
	print,'# QF set, npts =',total(qf_tmp),npts
	print,'d4 min & max dead times =',minmax(dead_tmp)
	
	mvn_d4_dat.quality_flag = (mvn_d4_dat.quality_flag and 32739) or qf_tmp
	mvn_d4_dat.dead[*] = dead_tmp[*]		

endif


end
