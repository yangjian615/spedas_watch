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
;LAST MODIFICATION:  15/03/02
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
;			15/02/25	major modifications to mcp droop correction
;NOTES:	  
;	Program assumes that "mvn_sta_l0_load" or "mvn_sta_l2_load,/test" has been run 
;	Program requires c0,c8,d8,da packets are available at 4 sec cadence
;	Program assumes Apids c2,c4,c6,ca,cd,cf,d3,d4 all have 4 second cadence
;		If at some future date we are forced into slower cadence measurements, 
;		then code used for apid cc can be adapted to the above apids.
;
;-
pro mvn_sta_dead_load,check=check,test=test,dead_droop=dead_droop,dead_rate=dead_rate

	common mvn_c0,mvn_c0_ind,mvn_c0_dat 
	common mvn_c8,mvn_c8_ind,mvn_c8_dat 
	common mvn_ca,mvn_ca_ind,mvn_ca_dat 
	common mvn_d8,mvn_d8_ind,mvn_d8_dat 
	common mvn_d9,mvn_d9_ind,mvn_d9_dat 
	common mvn_da,mvn_da_ind,mvn_da_dat 

; the following calibration efficiencies are not yet used to correct efficiencies by anode
;	instead, the instantaneous measured efficiencies from apid d8,d9,da are used
; eff = qual/trst = (1. + (1.-eff_start)(1.-eff_stop)) * eff_start * eff_stop
; assume anode 11 has same eff as anode 10 since they come as a pair
; calibration determined from
; pathname = '' & append_array, pathname, 'maven/prelaunch/sta/prelaunch/20130717_223852_fm_cal3_15kV_2keV_swp_0yaw_rot_n169to191/commonBlock_20130717_223852_.dat'
;		start_eff	stop_eff	start*stop	qual/trst	eff		qual		trst		bkg
eff_cal=fltarr(16,8)
eff_cal[0,*]  = [0.71618793,	0.39585779,	0.28350858,	0.32738033,	0.33211976,	54114.0,	168180.,	2886.0146]
eff_cal[1,*]  = [0.70179802,	0.40439033,	0.28380033,	0.33147972,	0.33420667,	52720.0,	161850.,	2805.5797]
eff_cal[2,*]  = [0.65494520,	0.41142500,	0.26946083,	0.32983319,	0.32418580,	58242.0,	179535.,	2954.8311]
eff_cal[3,*]  = [0.64706734,	0.42016500,	0.27187505,	0.33357006,	0.32751230,	53853.0,	164457.,	3012.6568]
eff_cal[4,*]  = [0.75086690,	0.39918736,	0.29973658,	0.34358835,	0.34460184,	61229.0,	181286.,	3081.4733]
eff_cal[5,*]  = [0.71146882,	0.40867430,	0.29075902,	0.34179605,	0.34036713,	65345.0,	194332.,	3150.7367]
eff_cal[6,*]  = [0.74215617,	0.42814479,	0.31775030,	0.36585302,	0.36460237,	57806.0,	160947.,	2943.6596]
eff_cal[7,*]  = [0.71052176,	0.42067975,	0.29890212,	0.35421054,	0.34902818,	57711.0,	165941.,	3012.4761]
eff_cal[8,*]  = [0.74730978,	0.44689782,	0.33397111,	0.38536636,	0.38064809,	65789.0,	173926.,	3207.9348]
eff_cal[9,*]  = [0.75801029,	0.43510004,	0.32981031,	0.37683031,	0.37489537,	68024.0,	183667.,	3150.7367]
eff_cal[10,*] = [0.68096973,	0.33963898,	0.23128386,	0.28701702,	0.28000963,	44183.0,	156813.,	2874.3963]
eff_cal[11,*] = [0.68096973,	0.33963898,	0.23128386,	0.28701702,	0.28000963,	44183.0,	156813.,	2874.3963]
eff_cal[12,*] = [0.70702238,	0.41743409,	0.29513525,	0.34727843,	0.34550857,	58910.0,	172577.,	2943.6596]
eff_cal[13,*] = [0.65591447,	0.42595970,	0.27939313,	0.33817375,	0.33457857,	55204.0,	166323.,	3081.4733]
eff_cal[14,*] = [0.68126999,	0.42288018,	0.28809558,	0.34021118,	0.34108944,	48966.0,	146814.,	2885.7485]
eff_cal[15,*] = [0.69060158,	0.42679990,	0.29474869,	0.34436476,	0.34702154,	50263.0,	148833.,	2874.3963]


;if size(mvn_c0_dat,/type) eq 0 or size(mvn_c8_dat,/type) eq 0 or size(mvn_ca_dat,/type) eq 0 or $
;	size(mvn_d8_dat,/type) eq 0 or size(mvn_d9_dat,/type) eq 0 or size(mvn_da_dat,/type) eq 0 then begin
if size(mvn_c0_dat,/type) ne 8 or size(mvn_c8_dat,/type) ne 8 or size(mvn_ca_dat,/type) ne 8 or $
	size(mvn_d8_dat,/type) ne 8 or size(mvn_d9_dat,/type) ne 8 or size(mvn_da_dat,/type) ne 8 then begin
	print,'Error - apid c0,c8,ca,d8,d9,da data must be loaded, run mvn_sta_l2_load.pro first'
	return
endif

time = mvn_da_dat.time
npts = n_elements(mvn_da_dat.time)
rate = dblarr(npts,64,16)
dead = dblarr(npts,64,16)
droop = dblarr(npts,64,16)
valid = dblarr(npts,64,16)
qual = intarr(npts)
eff_start = fltarr(npts)
eff_stop = fltarr(npts)
eff_qual = fltarr(npts)
eff_total = fltarr(npts)
eff_expected = fltarr(npts)
pk1_droop = fltarr(npts)
pk2_droop = fltarr(npts)
pk3_droop = fltarr(npts)
d1 = mvn_c8_dat.dead1						; 420 ns, fully qualified events
d2 = mvn_c8_dat.dead2						; 660 ns, unqualified events
d3 = mvn_c8_dat.dead3						; 460 ns, stop no start events (and stop then start events)

max_droop = fltarr(npts)
max_dead = fltarr(npts)

if not keyword_set(dead_droop) then dead_droop=800.		; this was empirically determined from data on 20150107-1520UT, seems good to ~10% 
if not keyword_set(dead_rate) then dead_rate=1.e5		; this was empirically determined from data on 20150107-1520UT, seems good to ~10% 
st_def = .70							; default start efficiency at low rates
sp_def = .47							; default stop efficiency at low rates

if keyword_set(test) then begin
	get_data,'mvn_sta_d8_R1_Qual',data=tmp1
	get_data,'mvn_sta_c6_tot',data=tmp2
	d8 = interp(tmp2.y,tmp2.x,tmp1.x)
	store_data,'mvn_sta_fq_eff',data={x:tmp1.x,y:d8/(4.*tmp1.y+.001)}
	ylim,'mvn_sta_fq_eff',.1,1.1,1
endif

for i=0l,npts-1 do begin

	min_c0 = min(abs(mvn_c0_dat.time-time[i]),ind_c0)
	min_c8 = min(abs(mvn_c8_dat.time-time[i]),ind_c8)
	min_ca = min(abs(mvn_ca_dat.time-time[i]),ind_ca)
	min_d8 = min(abs(mvn_d8_dat.time-time[i]),ind_d8)
	min_d9 = min(abs(mvn_d9_dat.time-time[i]),ind_d9)

	if (min_c0 gt 2. or min_c8 gt 2. or min_ca gt 2. or min_d8 gt 2.) then begin
		if keyword_set(check) then print,'No matching data at: ',time_string(time[i]),' c0_delta_time= ',min_c0,' c8_delta_time= ',min_c8,' ca_delta_time= ',min_ca,' d8_delta_time= ',min_d8
		if keyword_set(check) then print,'		Using nearest matching data'
		qual[i]=qual[i]+16
	endif

	c0 = 1.d*reform(mvn_c0_dat.data[ind_c0,*,0]+mvn_c0_dat.data[ind_c0,*,1])#replicate(1.,16)	; apid c0 is valid counts vs energy, averaged over mass
	da = 1.d*reform(mvn_da_dat.rates[i,*])*16.#replicate(1.,16)					; apid da is a rate (Hz), *16. keeps it a rate when normalized below by c8/ct
	c8 = 1.d*reform(replicate(1.,2)#reform(mvn_c8_dat.data[ind_c8,*,*],512),64,16)

	ca = total(reform(mvn_ca_dat.data[ind_ca,*,*],16,4,16),2)				; assume dist of cnts on anode independent of deflectors
	ca1 = fltarr(16) 
	ef1 = fltarr(16) 
	for j=0,15 do begin
		ca1[j] = max(ca[j,*]/(total(ca[j,*])+1.))>(1./16.)
	endfor
	ca2 = reform(replicate(1.,4)#ca1,64)#replicate(1.,16)					; correction for mcp droop to account for dist of cnts over anodes
	ef1 = total(ca*(replicate(1.,16)#reform(eff_cal[*,4])),2)/total(ca,2)
	ef2 = reform(replicate(1.,4)#ef1,64)#replicate(1.,16)					; correction for nominal efficiency to account for dist of cnts over anodes

	ef3 = total(mvn_c0_dat.data[ind_c0,*,*])/(4.*mvn_d8_dat.rates[ind_d8,7])		; x4 converts rates to counts

	ct = 1.*total(c8,2)#replicate(1.,16) > 0.0001
	r1 = mvn_d8_dat.rates[ind_d8,7]/mvn_d8_dat.rates[ind_d8,4]				; fully qualified processed events 
	r2 = mvn_d8_dat.rates[ind_d8,6]/mvn_d8_dat.rates[ind_d8,4]				; rejected events, unqualified events 
	r3 = mvn_d8_dat.rates[ind_d8,5]/mvn_d8_dat.rates[ind_d8,4]				; stop no start
	r4 = (1.-r1-r2-r3)>0.									; stop then start events

; calculate average efficiencies of TOF to account for MCP droop at high count rates
	rt = mvn_d8_dat.rates[ind_d8,4]
	fq = mvn_d8_dat.rates[ind_d8,7]
	ab = mvn_d8_dat.rates[ind_d8,10]
	cd = mvn_d8_dat.rates[ind_d8,11]
	ab_bk = min(mvn_d9_dat.rates[ind_d9,10,*]) > 25.
	cd_bk = min(mvn_d9_dat.rates[ind_d9,11,*]) > 90.
	ef_sp = 0.2 > (fq/((ab-ab_bk)>(fq+0.00001))) < .6							; efficiency - may need mod
	ef_st = 0.2 > (fq/((cd-cd_bk)>(fq+0.00001))) < .8							; efficiency - may need mod

; smooth out statistical fluctuations at low count rates
	ef_sp = (ef_sp*fq + sp_def*50.)/(fq+50.)	
	ef_st = (ef_st*fq + st_def*50.)/(fq+50.)

; use default efficiencies at very low count rates
	if (fq lt 100.) then begin								; use default efficiencies for low event rates
		ef_sp = sp_def
		ef_st = st_def
		ef3 = .65
	endif
	
; calculate total efficiency (including events where both start and stop are missed)
	ef_tl = (1. + (1.-ef_st)*(1.-ef_sp))*ef_st*ef_sp						

; store efficiencies for tplot variables (only used if test keyword is set)
	eff_start[i] = ef_st	
	eff_stop[i]  = ef_sp
	eff_qual[i]  = ef3	
	eff_total[i] = ef_tl
		
; fill the rate and valid event arrays 
	tmp = da*c8/ct 										; da rate vs E -> rate per accum 
	dtmp = (da[*,0]-total(tmp,2))#replicate(1./16,16)					; corrects for small round off error

	tmp7 = c0*c8/ct 									; da rate vs E -> rate per accum 
	dtmp7 = (c0[*,0]-total(tmp7,2))#replicate(1./16,16)					; corrects for small round off error
	
	rate[i,*,*] = (tmp + dtmp) >0.								; gets rid of round off errors

	valid[i,*,*] = (tmp7 + dtmp7) >0.							; gets rid of round off errors

	eff_expected[i] = total(rate[i,*,*]*ef2)/total(rate[i,*,*])	

; fill the electronic deadtime array
	dead2 = (d1*r1+d2*r2+d3*(r3+r4))*rate[i,*,*]*1.e-9 
	if max(dead2) gt .95 then begin
		print,'Error - dead time correction too large, limiting to x20, time=',time_string(time[i])
		dead2 = dead2 <.95
	endif
	dead[i,*,*] = 1./(1.-dead2)

; these arrays are only used for testing algorithms 

	pk1 = (1.+tanh((7500)*rate[i,*,*]*ca2*1.e-9 -5.))/2. 
	pk1[*]=1.
	pk1_droop[i] = max(pk1)

	xx = (dead_droop)*rate[i,*,*]*ca2*1.e-9
	pk2 = (1.-exp(-xx)) 
	pk2_droop[i] = max(pk2)
	pk3_droop[i] = max(xx)

; this is an empirical formula that corrects for MCP droop at high rates
;    a dozen algorithms with various parameters were tried using density variations across attenuator changes at periapsis in Jan 2015
;	dead_droop is effectively the dead_time of MCP droop
;	dead_rate is a minimum counting rate that must be exceeded before droop sets in
;    several different values for dead_rate and dead_droop were tried 
;    the below algorithm worked well for dead_droop=800 and dead_rate=1.e5 
; the algorithm worked well for solar wind even for corrections as large and a factor of 10
;    no attempt was made to fine tune the algorithm since other non-linear responses come into play
;    the algorithm fails to account for a broad angle beam over many anodes - but these rarely occur with significant dead time
;    the algorithm fails to deal with variations in efficiency with anode and instead uses the average efficiency
;    most residual density shifts during attenuator changes can be attributed to coarse energy samples and narrow energy beams 

	droop[i,*,*] = (1./ef3)*(.28/ef_tl)*(1./(1.-(dead_droop*((rate[i,*,*]-dead_rate)>1.)*1.e-9 < .9)))	

if min(droop[i,*,*]) lt 0. then print,'STATIC MCP Droop calculation error:',i,' ',time_string(time[i]),' sp_def/ef_sp=',(sp_def/ef_sp),' st_def/ef_st=',(st_def/ef_st),minmax(rate[i,*,*]),minmax(ca2)

	if keyword_set(check) and (i mod 1000) eq 0 then print,total(da[*,0]),total(rate[i,*,*]),total(dtmp),minmax(dead[i,*,*])
	if keyword_set(check) and (i mod 1000) eq 0 then print,minmax(da)
	if keyword_set(check) and (i mod 1000) eq 0 then print,'rate',minmax(rate[i,*,*]),minmax(dtmp)
	if keyword_set(check) and (i mod 1000) eq 0 then print,'dead',minmax(dead2)
	if keyword_set(check) and (i mod 1000) eq 0 then print,'dead_droop ',minmax(dead_droop*rate[i,*,*]*ca2*1.e-9),total(dead_droop*rate[i,*,*]*ca2*1.e-9)/(64.*16.)

	if (max(dead[i,*,*])  gt 2.0) then qual[i]=qual[i]+4					; we may want to change this
	if (max(droop[i,*,*]) gt 2.0) then qual[i]=qual[i]+8					; we may want to change this

	max_droop[i]=max(droop[i,*,*])
	max_dead[i]=max(dead[i,*,*])

endfor

if keyword_set(test) then print,'min-max of dead= ',minmax(dead)
if keyword_set(test) then print,'min-max of droop= ',minmax(droop)

; combine both dead time and droop into a single dead time array

dead = dead * droop

if keyword_set(test) then print,'Minimum and maximum dead time corrections in array =',minmax(dead)

;  Science data product common blocks
 
;	common mvn_c0,mvn_c0_ind,mvn_c0_dat 
	common mvn_c2,mvn_c2_ind,mvn_c2_dat 
	common mvn_c4,mvn_c4_ind,mvn_c4_dat 
	common mvn_c6,mvn_c6_ind,mvn_c6_dat 
;	common mvn_ca,mvn_ca_ind,mvn_ca_dat 
	common mvn_cc,mvn_cc_ind,mvn_cc_dat 
	common mvn_cd,mvn_cd_ind,mvn_cd_dat 
	common mvn_ce,mvn_ce_ind,mvn_ce_dat 
	common mvn_cf,mvn_cf_ind,mvn_cf_dat 
	common mvn_d0,mvn_d0_ind,mvn_d0_dat 
	common mvn_d1,mvn_d1_ind,mvn_d1_dat 
	common mvn_d2,mvn_d2_ind,mvn_d2_dat 
	common mvn_d3,mvn_d3_ind,mvn_d3_dat 
	common mvn_d4,mvn_d4_ind,mvn_d4_dat 

; these tplot variables are for testing

if keyword_set(test) then begin

	loadct2,43
	cols=get_colors()

	store_data,'mvn_sta_max_dead',data={x:time+2.,y:max_dead}
	store_data,'mvn_sta_max_droop',data={x:time+2.,y:max_droop}
		options,'mvn_sta_max_droop',colors=cols.red
	store_data,'mvn_sta_max_dead_droop',data=['mvn_sta_max_dead','mvn_sta_max_droop']
		ylim,'mvn_sta_max_dead_droop',.5,20.,1

	store_data,'mvn_sta_dl_eff_start',data={x:time+2.,y:eff_start}
		options,'mvn_sta_dl_eff_start',colors=cols.green
	store_data,'mvn_sta_dl_eff_stop',data={x:time+2.,y:eff_stop}
		options,'mvn_sta_dl_eff_stop',colors=cols.red
	store_data,'mvn_sta_dl_eff_total',data={x:time+2.,y:eff_total}
	store_data,'mvn_sta_dl_eff_expected',data={x:time+2.,y:eff_expected}
		options,'mvn_sta_dl_eff_expected',colors=cols.magenta
	store_data,'mvn_sta_dl_eff',data=['mvn_sta_dl_eff_total','mvn_sta_dl_eff_start','mvn_sta_dl_eff_stop','mvn_sta_dl_eff_expected']
		ylim,'mvn_sta_dl_eff',.1,1,1

	store_data,'mvn_sta_pk1_droop',data={x:time+2.,y:pk1_droop}
		ylim,'mvn_sta_pk1_droop',-.1,1.1,0
	store_data,'mvn_sta_pk2_droop',data={x:time+2.,y:pk2_droop*1.01}
		ylim,'mvn_sta_pk2_droop',-.1,1.1,0 & options,'mvn_sta_pk2_droop',colors=cols.red
	store_data,'mvn_sta_pk3_droop',data={x:time+2.,y:pk3_droop}
		ylim,'mvn_sta_pk3_droop',-.1,1.1,0 & options,'mvn_sta_pk3_droop',colors=cols.magenta
	store_data,'mvn_sta_pk12_droop',data={x:time+2.,y:pk1_droop*pk2_droop}
		ylim,'mvn_sta_pk12_droop',-.1,1.1,0 & options,'mvn_sta_pk12_droop',colors=cols.green
	store_data,'mvn_sta_pk_droop',data=['mvn_sta_pk1_droop','mvn_sta_pk2_droop','mvn_sta_pk3_droop','mvn_sta_pk12_droop']
		ylim,'mvn_sta_pk_droop',-.1,1.1,0

endif


; Add the dead time to the data arrays


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
