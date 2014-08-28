;+
; NAME: rbsp_efw_burst_fa_rotate_crib
; SYNTAX: 
; PURPOSE: Rotate RBSP EFW burst data to field-aligned coordinates
; INPUT: 
; OUTPUT: 
; KEYWORDS: 
; HISTORY: Created by Aaron W Breneman, Univ. Minnesota  4/10/2014
; VERSION: 
;   $LastChangedBy: aaronbreneman $
;   $LastChangedDate: 2014-07-16 10:41:35 -0700 (Wed, 16 Jul 2014) $
;   $LastChangedRevision: 15582 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/examples/rbsp_efw_burst_fa_rotate_crib.pro $
;-
; cindy tried to make work on B1. It doesn't get past making the search coil in mgse; nothing in the e_b1 tplot quantities


	;Select to bandpass data or not
	bandpass_data = 'n'
	fmin = 100. ;Hz
	fmax = 10000. 


	rbsp_efw_init

	date = '2013-06-08'   ;Wave at 4 Hz
	timespan,date

	;Define timerange for loading of burst waveform
	;(CURRENTLY NEED AT LEAST 1 SEC OF BURST FOR MGSE TRANSFORMATION TO WORK!!!)
	t0 = date + '/04:00'
	t1 = date + '/05:00'

	probe='b'
	rbspx = 'rbsp'+probe

	dt = time_double(t1) - time_double(t0)

	;Make tplot plots looks pretty
	charsz_plot = 0.8  ;character size for plots
	charsz_win = 1.2  
	!p.charsize = charsz_win
	tplot_options,'xmargin',[20.,15.]
	tplot_options,'ymargin',[3,6]
	tplot_options,'xticklen',0.08
	tplot_options,'yticklen',0.02
	tplot_options,'xthick',2
	tplot_options,'ythick',2
	tplot_options,'labflag',-1	

 
;--------------------------------------------------------------------------------
;Find the GSE coordinates of the sc spin axis. This will be used to transform the 
;Mag data from GSE -> MGSE coordinates
;--------------------------------------------------------------------------------


	;Load spice kernels and get antenna pointing direction
	rbsp_load_spice_kernels

	rbsp_efw_position_velocity_crib,/no_spice_load,/noplot
	get_data,rbspx+'_spinaxis_direction_gse',data=wsc_GSE	



;------------------------------------------------------
;Get EMFISIS DC mag data in GSE
;------------------------------------------------------

	;Load EMFISIS data (defaults to 'hires', but can also choose '1sec' or '4sec')
	rbsp_load_emfisis,probe=probe,coord='gse',cadence='hires',level='l3'
	;rbsp_load_emfisis,probe=probe,coord='gse',cadence='4sec',level='l3'


	;Transform the Mag data to MGSE coordinates
	get_data,rbspx+'_emfisis_l3_hires_gse_Mag',data=tmpp
	;get_data,rbspx+'_emfisis_l3_4sec_gse_Mag',data=tmpp

	wsc_GSE_tmp = [[interpol(wsc_GSE.y[*,0],wsc_GSE.x,tmpp.x)],$
				   [interpol(wsc_GSE.y[*,1],wsc_GSE.x,tmpp.x)],$
				   [interpol(wsc_GSE.y[*,2],wsc_GSE.x,tmpp.x)]]

	rbsp_gse2mgse,rbspx+'_emfisis_l3_hires_gse_Mag',reform(wsc_GSE_tmp),newname=rbspx+'_Mag_mgse'
	;rbsp_gse2mgse,rbspx+'_emfisis_l3_4sec_gse_Mag',reform(wsc_GSE_tmp),newname=rbspx+'_Mag_mgse'


;----------------------------------------------------------
;Load burst data
;----------------------------------------------------------

	dt2 = time_double(t1) - time_double(t0)
	timespan,t0,dt2,/seconds


	rbsp_load_efw_waveform_partial,probe=probe,type='calibrated',datatype=['mscb2']
	rbsp_load_efw_waveform_partial,probe=probe,type='calibrated',datatype=['vb2']
		

	copy_data,rbspx+'_efw_mscb2',rbspx+'_efw_mscb2_uvw'
	store_data,rbspx+'_efw_mscb2',/delete
	
	;Create E-field variables (mV/m)
	trange = timerange()
	print,time_string(trange)
	cp0 = rbsp_efw_get_cal_params(trange[0])

	if probe eq 'a' then cp = cp0.a else cp = cp0.b


	boom_length = cp.boom_length
	boom_shorting_factor = cp.boom_shorting_factor

	get_data,rbspx+'_efw_vb2',data=dd
	e12 = 1000.*(dd.y[*,0]-dd.y[*,1])/boom_length[0]
	e34 = 1000.*(dd.y[*,2]-dd.y[*,3])/boom_length[1]
	e56 = 1000.*(dd.y[*,4]-dd.y[*,5])/boom_length[2]
	
	;SET 56 COMPONENT TO ZERO
	e56[*] = 0.
	
	
	eb1= [[e12],[e34],[e56]]
	store_data,rbspx+'_efw_eb2_uvw',data={x:dd.x,y:eb1}
	
	tplot,[rbspx+'_efw_eb2_uvw',rbspx+'_efw_mscb2_uvw']
	
	;Convert from UVW (spinning sc) to MGSE coord
	rbsp_uvw_to_mgse,probe,rbspx+'_efw_mscb2_uvw',/no_spice_load,/nointerp,/no_offset	
	rbsp_uvw_to_mgse,probe,rbspx+'_efw_eb2_uvw',/no_spice_load,/nointerp,/no_offset	
	
	copy_data,rbspx+'_efw_eb2_uvw_mgse',rbspx+'_efw_eb2_mgse'
	copy_data,rbspx+'_efw_mscb2_uvw_mgse',rbspx+'_efw_mscb2_mgse'

	tplot,[rbspx+'_efw_eb2_mgse',rbspx+'_efw_mscb2_mgse']

	split_vec,rbspx+'_efw_eb2_mgse'
	split_vec,rbspx+'_efw_mscb2_mgse'

	;Check to see how things look (MGSEx is spin axis)
	tplot,[rbspx+'_efw_eb2_mgse_x',rbspx+'_efw_eb2_mgse_y',rbspx+'_efw_eb2_mgse_z']
stop
	tplot,[rbspx+'_efw_mscb2_mgse_x',rbspx+'_efw_mscb2_mgse_y',rbspx+'_efw_mscb2_mgse_z']
stop


	;--------
	;These are the variables we will be working with
	varM = rbspx+'_efw_mscb2_mgse'
	varE = rbspx+'_efw_eb2_mgse'


	if bandpass_data eq 'y' then begin


		get_data,varE,data=dat
		srt = 1/(dat.x[1] - dat.x[0])
		tmp = vector_bandpass(dat.y,srt,fmin,fmax)
		store_data,varE+'_bp',data={x:dat.x,y:tmp}

		get_data,varM,data=dat
		srt = 1/(dat.x[1] - dat.x[0])
		tmp = vector_bandpass(dat.y,srt,fmin,fmax)
		store_data,varM+'_bp',data={x:dat.x,y:tmp}

		varM = varM + '_bp'
		varE = varE + '_bp'

	endif



;------------------------------------------------------------------
;For each searchcoil burst chunk, rotate to FA coord and run Chaston's routine
;------------------------------------------------------------------


	get_data,varM,data=varr


	;Separate the bursts by comparing the delta-time b/t each
	;data point to 1/samplerate

	dt = varr.x - shift(varr.x,1)
	dt = dt[1:n_elements(dt)-1]

	;.compile ~/Desktop/code/Aaron/RBSP/sample_rate.pro

	sr = sample_rate(varr.x,out_med_av=medavg)
	store_data,varM+'_samplerate',data={x:varr.x,y:sr}
	store_data,varM+'_samplerate_diff',data={x:varr.x,y:abs(sr-medavg[0])}
	tplot,[varM,varM+'_samplerate',varM+'_samplerate_diff']

stop

	threshold = 1/medavg
	goo = where(abs(dt) ge 2*threshold[1])


	nchunks = n_elements(goo)
	b = 0L
	q = 0L

	;left and right location of each burst chunk
	chunkL = [0,goo+1]
	chunkR = [goo-1,n_elements(sr)-1]




	Burstdata = [[0.],[0.],[0.]]
	Bursttimes = 0d
	theta_kb = 0.
	thetatimes = 0d
	dtheta_kb = 0.
	minvar_eigs = [[0.],[0.],[0.]]
	emax2eint = 0.
	eint2emin = 0.
	emax_vec_minvar = [[0.],[0.],[0.]]
	eint_vec_minvar = [[0.],[0.],[0.]]
	emin_vec_minvar = [[0.],[0.],[0.]]

	waveangle = replicate(0.,[1,128])
	powspec = replicate(0.,[1,128]) 
	degpol = replicate(0.,[1,128])
	elliptict = replicate(0.,[1,128])
	helicit = replicate(0.,[1,128])
	pspec3 = replicate(0.,[1,128,3])
	chastontimes = 0d

	for i=0,nchunks-1 do begin

		t0z = varr.x[chunkL[i]]
		t1z = varr.x[chunkR[i]]

		vb = tsample(varM,[t0z,t1z],times=tb)
		vm = tsample(rbspx+'_Mag_mgse',[t0z,t1z],times=tm)

		store_data,varM+'_tmp',data={x:tb,y:vb}
		store_data,rbspx+'_Mag_mgse_tmp',data={x:tm,y:vm}
	

		tplot,[varM+'_tmp',rbspx+'_Mag_mgse_tmp']
		tlimit,t0z,t1z

		;Rotate each chunk to FA/minvar coord
		fa = rbsp_rotate_field_2_vec(varM+'_tmp',rbspx+'_Mag_mgse_tmp')

		tplot,[varM+'_tmp_FA_minvar',rbspx+'_Mag_mgse_tmp']


		get_data,varM+'_tmp_FA_minvar',data=dtmp
		Burstdata = [Burstdata,dtmp.y]
		Bursttimes = [Bursttimes,dtmp.x]

		get_data,'theta_kb',data=dtmp
		theta_kb = [theta_kb,dtmp.y]
		thetatimes = [thetatimes,dtmp.x]
		get_data,'dtheta_kb',data=dtmp
		dtheta_kb = [dtheta_kb,dtmp.y]
		get_data,'emax2eint',data=dtmp
		emax2eint = [emax2eint,dtmp.y]
		get_data,'eint2emin',data=dtmp
		eint2emin = [eint2emin,dtmp.y]
		get_data,'minvar_eigenvalues',data=dtmp
		minvar_eigs = [minvar_eigs,dtmp.y]
		get_data,'emax_vec_minvar',data=dtmp
		emax_vec_minvar = [emax_vec_minvar,dtmp.y]
		get_data,'eint_vec_minvar',data=dtmp
		eint_vec_minvar = [eint_vec_minvar,dtmp.y]
		get_data,'emin_vec_minvar',data=dtmp
		emin_vec_minvar = [emin_vec_minvar,dtmp.y]


		;-------
	
		;Run Chaston crib on each chunk	
		twavpol,varM+'_tmp_FA_minvar',prefix='tmp'


		;change wave normal angle to degrees
		get_data,'tmp'+'_waveangle',data=dtmp
		dtmp.y = dtmp.y/!dtor	
		waveangle = [waveangle,dtmp.y]
		chastontimes = [chastontimes,dtmp.x]	
	
		get_data,'tmp'+'_powspec',data=dtmp
		powspec = [powspec,dtmp.y]
		get_data,'tmp'+'_degpol',data=dtmp
		degpol = [degpol,dtmp.y]
		get_data,'tmp'+'_elliptict',data=dtmp
		elliptict = [elliptict,dtmp.y]
		get_data,'tmp'+'_helict',data=dtmp
		helicit = [helicit,dtmp.y]
		get_data,'tmp'+'_pspec3',data=dtmp
		pspec3 = [pspec3,dtmp.y]
	
	
	endfor


	freqvals = dtmp.v
	varM = varM + '_FA_minvar'

	;Store the field-aligned burst data
	nn = n_elements(bursttimes)-1
	store_data,varM,data={x:Bursttimes[1:nn],y:Burstdata[1:nn,*]}

	;Store the minvar analysis variables
	nn = n_elements(thetatimes)-1
	store_data,varM+'_theta_kb',data={x:thetatimes[1:nn],y:theta_kb[1:nn]}
	store_data,varM+'_dtheta_kb',data={x:thetatimes[1:nn],y:dtheta_kb[1:nn]}
	store_data,varM+'_emax2eint',data={x:thetatimes[1:nn],y:emax2eint[1:nn]}
	store_data,varM+'_eint2emin',data={x:thetatimes[1:nn],y:eint2emin[1:nn]}
	store_data,varM+'_minvar_eigenvalues',data={x:thetatimes[1:nn],y:minvar_eigs[1:nn]}
	store_data,varM+'_emax_vec_minvar',data={x:thetatimes[1:nn],y:emax_vec_minvar[1:nn]}
	store_data,varM+'_eint_vec_minvar',data={x:thetatimes[1:nn],y:eint_vec_minvar[1:nn]}
	store_data,varM+'_emin_vec_minvar',data={x:thetatimes[1:nn],y:emin_vec_minvar[1:nn]}


	options,varM+'_theta_kb','ytitle',rbspx+ '!CWave normal!Cangle'
	options,varM+'_dtheta_kb','ytitle',rbspx+'!CWave normal!Cangle!Cuncertainty'
	
	ylim,[varM+'_emax2eint',varM+'_eint2emin'],0,50
	ylim,varM+'_dtheta_kb',0,50


	tplot,[varM,varM+'_theta_kb',varM+'_emax2eint',varM+'_eint2emin']

	;Store the Chaston crib variables
	nn = n_elements(chastontimes)-1
	store_data,varM+'_waveangle',data={x:chastontimes[1:nn],y:waveangle[1:nn,*],v:freqvals}
	store_data,varM+'_powspec',data={x:chastontimes[1:nn],y:powspec[1:nn,*],v:freqvals}
	store_data,varM+'_degpol',data={x:chastontimes[1:nn],y:degpol[1:nn,*],v:freqvals}
	store_data,varM+'_elliptict',data={x:chastontimes[1:nn],y:elliptict[1:nn,*],v:freqvals}
	store_data,varM+'_helicit',data={x:chastontimes[1:nn],y:helicit[1:nn,*],v:freqvals}
	store_data,varM+'_pspec3',data={x:chastontimes[1:nn],y:pspec3[1:nn,*,*],v:freqvals}


	ylim,[varM+'_powspec',$
			varM+'_degpol',$
			varM+'_waveangle',$
			varM+'_elliptict',$
			varM+'_helicit',$
			varM+'_pspec3'],100,8000,1

	zlim,varM+'_waveangle',0,90,0
	zlim,varM+'_powspec',1d-9,1d-4,1
	zlim,varM+'_pspec3',1d-9,1d-4,1

	;eliminate data under a certain deg of polarization threshold
	minpol = 0.5

	get_data,varM+'_degpol',data=degp
	goo = where(degp.y le minpol)
	if goo[0] ne -1 then degp.y[goo] = !values.f_nan
	store_data,varM+'_degpol',data=degp
	get_data,varM+'_powspec',data=tmp
	if goo[0] ne -1 then tmp.y[goo] = !values.f_nan
	store_data,varM+'_powspec',data=tmp
	get_data,varM+'_waveangle',data=tmp
	if goo[0] ne -1 then tmp.y[goo] = !values.f_nan
	store_data,varM+'_waveangle',data=tmp
	get_data,varM+'_elliptict',data=tmp
	if goo[0] ne -1 then tmp.y[goo] = !values.f_nan
	store_data,varM+'_elliptict',data=tmp
	get_data,varM+'_helicit',data=tmp
	if goo[0] ne -1 then tmp.y[goo] = !values.f_nan
	store_data,varM+'_helicit',data=tmp

	tplot,[varM,$
			varM+'_powspec',$
			varM+'_degpol',$
			varM+'_waveangle',$
			varM+'_elliptict',$
			varM+'_helict',$
			varM+'_pspec3']


	;remove unnecessary variables
	store_data,['theta_kb','dtheta_kb','minvar_eigenvalues','emax2eint','eint2emin','emax_vec_minvar','eint_vec_minvar','emin_vec_minvar'],/delete


	split_vec,varM
	ylim,[varM+'_x',varM+'_y',varM+'_z'],0,0

	;Plot FA coord. z-hat is field direction
	tlimit,t0,t1
	tplot,[varM+'_x',varM+'_y',varM+'_z']
stop
	;plot wave normal angle from min variance analysis
	
	tplot,[varM,varM+'_theta_kb',varM+'_dtheta_kb',varM+'_emax2eint',varM+'_eint2emin']
stop
	tplot,[varM,varM+'_theta_kb',varM+'_dtheta_kb',varM+'_x',varM+'_y',varM+'_z']

stop








;------------------------------------------------------------------
;For each Efield burst chunk, rotate to FA coord and run Chaston's routine
;------------------------------------------------------------------


	get_data,varE,data=varr


	;Separate the bursts by comparing the delta-time b/t each
	;data point to 1/samplerate

	dt = varr.x - shift(varr.x,1)
	dt = dt[1:n_elements(dt)-1]

	;.compile ~/Desktop/code/Aaron/RBSP/sample_rate.pro

	sr = sample_rate(varr.x,out_med_av=medavg)
	store_data,varE+'_samplerate',data={x:varr.x,y:sr}
	store_data,varE+'_samplerate_diff',data={x:varr.x,y:abs(sr-medavg[0])}
	;tplot,[varE,varE+'_samplerate',varE+'_samplerate_diff']
	
stop

	threshold = 1/medavg
	goo = where(abs(dt) ge 2*threshold[1])


	nchunks = n_elements(goo)
	b = 0L
	q = 0L
	
	;left and right location of each burst chunk
	chunkL = [0,goo+1]
	chunkR = [goo-1,n_elements(sr)-1]




	Burstdata = [[0.],[0.],[0.]]
	Bursttimes = 0d
	theta_kb = 0.
	thetatimes = 0d
	dtheta_kb = 0.
	minvar_eigs = [[0.],[0.],[0.]]
	emax2eint = 0.
	eint2emin = 0.
	emax_vec_minvar = [[0.],[0.],[0.]]
	eint_vec_minvar = [[0.],[0.],[0.]]
	emin_vec_minvar = [[0.],[0.],[0.]]

	waveangle = replicate(0.,[1,128])
	powspec = replicate(0.,[1,128]) 
	degpol = replicate(0.,[1,128])
	elliptict = replicate(0.,[1,128])
	helicit = replicate(0.,[1,128])
	pspec3 = replicate(0.,[1,128,3])
	chastontimes = 0d

	for i=0,nchunks-1 do begin

		t0z = varr.x[chunkL[i]]
		t1z = varr.x[chunkR[i]]

		vb = tsample(varE,[t0z,t1z],times=tb)
		vm = tsample(rbspx+'_Mag_mgse',[t0z,t1z],times=tm)

		store_data,varE+'_tmp',data={x:tb,y:vb}
		store_data,rbspx+'_Mag_mgse_tmp',data={x:tm,y:vm}
	

		tplot,[varE+'_tmp',rbspx+'_Mag_mgse_tmp']
		tlimit,t0z,t1z

		;Rotate each chunk to FA/minvar coord
		fa = rbsp_rotate_field_2_vec(varE+'_tmp',rbspx+'_Mag_mgse_tmp')

		tplot,[varE+'_tmp_FA_minvar',rbspx+'_Mag_mgse_tmp']


		get_data,varE+'_tmp_FA_minvar',data=dtmp
		Burstdata = [Burstdata,dtmp.y]
		Bursttimes = [Bursttimes,dtmp.x]

		get_data,'theta_kb',data=dtmp
		theta_kb = [theta_kb,dtmp.y]
		thetatimes = [thetatimes,dtmp.x]
		get_data,'dtheta_kb',data=dtmp
		dtheta_kb = [dtheta_kb,dtmp.y]
		get_data,'emax2eint',data=dtmp
		emax2eint = [emax2eint,dtmp.y]
		get_data,'eint2emin',data=dtmp
		eint2emin = [eint2emin,dtmp.y]
		get_data,'minvar_eigenvalues',data=dtmp
		minvar_eigs = [minvar_eigs,dtmp.y]
		get_data,'emax_vec_minvar',data=dtmp
		emax_vec_minvar = [emax_vec_minvar,dtmp.y]
		get_data,'eint_vec_minvar',data=dtmp
		eint_vec_minvar = [eint_vec_minvar,dtmp.y]
		get_data,'emin_vec_minvar',data=dtmp
		emin_vec_minvar = [emin_vec_minvar,dtmp.y]


		;-------
	
		;Run Chaston crib on each chunk	
		twavpol,varE+'_tmp_FA_minvar',prefix='tmp'


		;change wave normal angle to degrees
		get_data,'tmp'+'_waveangle',data=dtmp
		dtmp.y = dtmp.y/!dtor	
		waveangle = [waveangle,dtmp.y]
		chastontimes = [chastontimes,dtmp.x]	
	
		get_data,'tmp'+'_powspec',data=dtmp
		powspec = [powspec,dtmp.y]
		get_data,'tmp'+'_degpol',data=dtmp
		degpol = [degpol,dtmp.y]
		get_data,'tmp'+'_elliptict',data=dtmp
		elliptict = [elliptict,dtmp.y]
		get_data,'tmp'+'_helict',data=dtmp
		helicit = [helicit,dtmp.y]
		get_data,'tmp'+'_pspec3',data=dtmp
		pspec3 = [pspec3,dtmp.y]
	
	
	endfor


	freqvals = dtmp.v
	varE = varE + '_FA_minvar'

	;Store the field-aligned burst data
	nn = n_elements(bursttimes)-1
	store_data,varE,data={x:Bursttimes[1:nn],y:Burstdata[1:nn,*]}

	;Store the minvar analysis variables
	nn = n_elements(thetatimes)-1
	store_data,varE+'_theta_kb',data={x:thetatimes[1:nn],y:theta_kb[1:nn]}
	store_data,varE+'_dtheta_kb',data={x:thetatimes[1:nn],y:dtheta_kb[1:nn]}
	store_data,varE+'_emax2eint',data={x:thetatimes[1:nn],y:emax2eint[1:nn]}
	store_data,varE+'_eint2emin',data={x:thetatimes[1:nn],y:eint2emin[1:nn]}
	store_data,varE+'_minvar_eigenvalues',data={x:thetatimes[1:nn],y:minvar_eigs[1:nn]}
	store_data,varE+'_emax_vec_minvar',data={x:thetatimes[1:nn],y:emax_vec_minvar[1:nn]}
	store_data,varE+'_eint_vec_minvar',data={x:thetatimes[1:nn],y:eint_vec_minvar[1:nn]}
	store_data,varE+'_emin_vec_minvar',data={x:thetatimes[1:nn],y:emin_vec_minvar[1:nn]}


	options,varE+'_theta_kb','ytitle',rbspx+ '!CWave normal!Cangle'
	options,varE+'_dtheta_kb','ytitle',rbspx+'!CWave normal!Cangle!Cuncertainty'
	
	ylim,[varE+'_emax2eint',varE+'_eint2emin'],0,50
	ylim,varE+'_dtheta_kb',0,50


	tplot,[varE,varE+'_theta_kb',varE+'_emax2eint',varE+'_eint2emin']

	;Store the Chaston crib variables
	nn = n_elements(chastontimes)-1
	store_data,varE+'_waveangle',data={x:chastontimes[1:nn],y:waveangle[1:nn,*],v:freqvals}
	store_data,varE+'_powspec',data={x:chastontimes[1:nn],y:powspec[1:nn,*],v:freqvals}
	store_data,varE+'_degpol',data={x:chastontimes[1:nn],y:degpol[1:nn,*],v:freqvals}
	store_data,varE+'_elliptict',data={x:chastontimes[1:nn],y:elliptict[1:nn,*],v:freqvals}
	store_data,varE+'_helicit',data={x:chastontimes[1:nn],y:helicit[1:nn,*],v:freqvals}
	store_data,varE+'_pspec3',data={x:chastontimes[1:nn],y:pspec3[1:nn,*,*],v:freqvals}


	ylim,[varE+'_powspec',$
			varE+'_degpol',$
			varE+'_waveangle',$
			varE+'_elliptict',$
			varE+'_helicit',$
			varE+'_pspec3'],100,8000,1

	zlim,varE+'_waveangle',0,90,0
	zlim,varE+'_powspec',1d-9,1d-4,1
	zlim,varE+'_pspec3',1d-9,1d-4,1

	;eliminate data under a certain deg of polarization threshold
	minpol = 0.5

	get_data,varE+'_degpol',data=degp
	goo = where(degp.y le minpol)
	if goo[0] ne -1 then degp.y[goo] = !values.f_nan
	store_data,varE+'_degpol',data=degp
	get_data,varE+'_powspec',data=tmp
	if goo[0] ne -1 then tmp.y[goo] = !values.f_nan
	store_data,varE+'_powspec',data=tmp
	get_data,varE+'_waveangle',data=tmp
	if goo[0] ne -1 then tmp.y[goo] = !values.f_nan
	store_data,varE+'_waveangle',data=tmp
	get_data,varE+'_elliptict',data=tmp
	if goo[0] ne -1 then tmp.y[goo] = !values.f_nan
	store_data,varE+'_elliptict',data=tmp
	get_data,varE+'_helicit',data=tmp
	if goo[0] ne -1 then tmp.y[goo] = !values.f_nan
	store_data,varE+'_helicit',data=tmp

	tplot,[varE,$
			varE+'_powspec',$
			varE+'_degpol',$
			varE+'_waveangle',$
			varE+'_elliptict',$
			varE+'_helict',$
			varE+'_pspec3']


	;remove unnecessary variables
	store_data,['theta_kb','dtheta_kb','minvar_eigenvalues','emax2eint','eint2emin','emax_vec_minvar','eint_vec_minvar','emin_vec_minvar'],/delete


	split_vec,varE

	;Plot FA coord. z-hat is field direction
	ylim,[varE+'_x',varE+'_y',varE+'_z'],0,0
	tplot,[varE+'_x',varE+'_y',varE+'_z']
	tlimit,t0,t1
stop
	;plot wave normal angle from min variance analysis
	;ylim,[varE,varE+'_theta_kb',varE+'_dtheta_kb',varE+'_emax2eint',varE+'_eint2emin'],0,0

	
	tplot,[varE,varE+'_theta_kb',varE+'_dtheta_kb',varE+'_emax2eint',varE+'_eint2emin']
stop
	tplot,[varE,varE+'_theta_kb',varE+'_dtheta_kb',varE+'_x',varE+'_y',varE+'_z']

stop
;-----------------------------------------------------------------------------------



;***************************************
;***************************************

;I HAVEN'T MODIFIED ANYTHING BEYOND THIS POINT 
;TO ANALYZE THE INDIVIDUAL BURSTS

;***************************************
;***************************************



;----------------------------------------------------
;Plot FFTs
;----------------------------------------------------


	;Call program that plots FFTs, hodograms
	
	fftlims =  {xlog:1,xrange:[10,4000]} ;limits for the FFT
	hodlims = {xrange:[-0.2,0.2],yrange:[-0.2,0.2]}
		
	plot_wavestuff,varM,/psd,/hod,$
		/nodelete,$    ;keep tplot variables around
		extra_psd=fftlims,$
		extra_hod=hodlims

stop

;-----------------------------------------------------
;PLOT CROSS-CORRELATIONS
;-----------------------------------------------------
	
var1 = varM
var2 = varE

vardim1 = 1  ;use this y-dim for var1 (x=0, y=1, z=2)
vardim2 = 2	 ;use this y-dim for var2 (x=0, y=1, z=2)


;get both variables on the same time cadence
tinterpol_mxn,var2,var1,newname=var2 + '_for_correlation'
copy_data,var1,var1 + '_for_correlation'

var1 = var1 + '_for_correlation'
var2 = var2 + '_for_correlation'


;The following calculates the cross-phase and coherence between Ey-mgse and Ez-mgse 
;The function cross_spec_tplot return a multiple dimention array with the following structure. [[E_FREQUENCE_coordinate],[PHASE_E1_E2],[COHERENCE_E1_E2],[Aver_Pow_E_1],[Aver_Pow_E_2]]
Results=cross_spec_tplot(var1,vardim1,var2,vardim2,t0,t1,sub_interval=3,overlap_index=4)
Time_rbsp=strmid(time_string(t0z),0,10)+'_'+strmid(time_string(t0z),11,2)+strmid(time_string(t0z),14,2)+'UT'+'_to_'+strmid(time_string(t1),0,10)+'_'+strmid(time_string(t1),11,2)+strmid(time_string(t1),14,2)+'UT'

freqrange = [0,4000]   ;Hz

;Plot the cross-phase and coherence in a .ps file
;Popen,rbspx+'_'+timerbsp
!p.multi = [0,0,4]
!p.charsize = 2
Plot,Results[*,0],Results[*,2],xtitle='f, Hz', ytitle='Coherence_Ey_Ez',title=rbspx+time_rbsp,xrange=freqrange
Plot,Results[*,0],Results[*,1]*180./3.14,xtitle='f, Hz', ytitle='Phase_Ey_Ez',title=rbspx+time_rbsp,xrange=freqrange
Plot,Results[*,0],Results[*,3],xtitle='f, Hz', ytitle='Power_Ey,mV^2/Hz',title=rbspx+time_rbsp,xrange=freqrange
Plot,Results[*,0],Results[*,4],xtitle='f, Hz', ytitle='Phase_Ez,MV^2/Hz',title=rbspx+time_rbsp,xrange=freqrange
;Pclose


end
