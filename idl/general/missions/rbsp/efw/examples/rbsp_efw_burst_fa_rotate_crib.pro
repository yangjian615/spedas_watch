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
;   $LastChangedDate: 2014-10-17 13:38:53 -0700 (Fri, 17 Oct 2014) $
;   $LastChangedRevision: 16006 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/examples/rbsp_efw_burst_fa_rotate_crib.pro $
;-
; cindy tried to make work on B1. It d`oesn't get past making the search coil in mgse; nothing in the e_b1 tplot quantities


rbsp_efw_init

;------------------------------------------------------------------------
;VARIABLES TO SET
;------------------------------------------------------------------------


load_data = 1
;If loading data, set these to the path and file to load.
;Otherwise set them to the path and file to be saved. 
;; fn = 'burst_crib_b2_a_20140827'
fn = 'burst_crib_b2_a_20140123'
fileroot = '~/Desktop/code/Aaron/datafiles/'



rotate_to_fa = 1   ;rotate to FA coord? If so, this will be used when calling Chasten crib. 

if load_data then begin


;Loads the burst data that has been rotated to MGSE coord
;; ;**************************************************
   tplot_restore,filename=fileroot+fn + '.tplot'
   restore,fileroot+fn+'.idl'
;; ;**************************************************



endif else begin



	;burst type ('1' or '2')
	bt = '2'   

	;Select to bandpass data or not (note that bandpassed data also used for Pflux calculation)
	bandpass_data = 'y'
	fmin = 40. ;Hz
	fmax = 4000. 

	;date and time
	date = '2014-01-23'
	timespan,date

	;Define timerange for loading of burst waveform
	;(CURRENTLY NEED AT LEAST 1 SEC OF BURST FOR MGSE TRANSFORMATION TO WORK!!!)
	t0 = date + '/03:00'
	t1 = date + '/07:00'

	probe='a'

	minduration = 1.  ;minimum duration of each burst (sec). This is used to eliminate
					  ;spuriously short bursts that occur when there are short data gaps.
					  ;Spuriously short bursts can screw up twavpol.
	;; date = '2014-01-06'   ;Wave at 4 Hz
	;; t0 = time_double(date + '/20:00')
	;; t1 = time_double(date + '/22:00')
	;; probe='a'	


;-----------------------------------------------------------------------


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
;	rbsp_load_spice_kernels

	rbsp_efw_position_velocity_crib,/noplot
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


	rbsp_load_efw_waveform_partial,probe=probe,type='calibrated',datatype=['mscb'+bt]
	rbsp_load_efw_waveform_partial,probe=probe,type='calibrated',datatype=['vb'+bt]
	rbsp_load_efw_waveform_partial,probe=probe,type='calibrated',datatype=['eb'+bt]
		

	copy_data,rbspx+'_efw_mscb'+bt,rbspx+'_efw_mscb'+bt+'_uvw'
	store_data,rbspx+'_efw_mscb'+bt,/delete
	


        ;--------------------------------------------------
                                ;Check to see if there is Eburst
                                ;data. Otherwise, create it from
                                ;Vburst data

        get_data,rbspx+'_efw_eb'+bt,data=eburst
        if ~is_struct(eburst) then begin

                                ;Create E-field variables (mV/m)
           trange = timerange()
           print,time_string(trange)
           cp0 = rbsp_efw_get_cal_params(trange[0])

           if probe eq 'a' then cp = cp0.a else cp = cp0.b


           boom_length = cp.boom_length
           boom_shorting_factor = cp.boom_shorting_factor

           get_data,rbspx+'_efw_vb'+bt,data=dd
           e12 = 1000.*(dd.y[*,0]-dd.y[*,1])/boom_length[0]
           e34 = 1000.*(dd.y[*,2]-dd.y[*,3])/boom_length[1]
           e56 = 1000.*(dd.y[*,4]-dd.y[*,5])/boom_length[2]


 ;          stop
           
                                ;SET 56 COMPONENT TO ZERO
;	e56[*] = 0.
           
           
           eb1= [[e12],[e34],[e56]]
           store_data,rbspx+'_efw_eb'+bt+'_uvw',data={x:dd.x,y:eb1}


        endif else copy_data,rbspx+'_efw_eb'+bt,rbspx+'_efw_eb'+bt+'_uvw'

	
	tplot,[rbspx+'_efw_eb'+bt+'_uvw',rbspx+'_efw_mscb'+bt+'_uvw']
	
	;Convert from UVW (spinning sc) to MGSE coord
	rbsp_uvw_to_mgse,probe,rbspx+'_efw_mscb'+bt+'_uvw',/no_spice_load,/nointerp,/no_offset	
	rbsp_uvw_to_mgse,probe,rbspx+'_efw_eb'+bt+'_uvw',/no_spice_load,/nointerp,/no_offset	
	
	copy_data,rbspx+'_efw_eb'+bt+'_uvw_mgse',rbspx+'_efw_eb'+bt+'_mgse'
	copy_data,rbspx+'_efw_mscb'+bt+'_uvw_mgse',rbspx+'_efw_mscb'+bt+'_mgse'

	tplot,[rbspx+'_efw_eb'+bt+'_mgse',rbspx+'_efw_mscb'+bt+'_mgse']

	split_vec,rbspx+'_efw_eb'+bt+'_mgse'
	split_vec,rbspx+'_efw_mscb'+bt+'_mgse'

	;Check to see how things look (MGSEx is spin axis)
	tplot,[rbspx+'_efw_eb'+bt+'_mgse_x',rbspx+'_efw_eb'+bt+'_mgse_y',rbspx+'_efw_eb'+bt+'_mgse_z']
;stop
	tplot,[rbspx+'_efw_mscb'+bt+'_mgse_x',rbspx+'_efw_mscb'+bt+'_mgse_y',rbspx+'_efw_mscb'+bt+'_mgse_z']
;stop


	;--------
	;These are the variables we will be working with
	varM = rbspx+'_efw_mscb'+bt+'_mgse'
	varE = rbspx+'_efw_eb'+bt+'_mgse'



;Delete unnecessary tplot variables to save space
        store_data,tnames(rbspx+'_efw_vb'+bt),/delete
        store_data,tnames('*uvw*'),/delete
        store_data,tnames('*mgse_?'),/delete
        store_data,tnames(rbspx+'_efw_eb2'),/delete
        store_data,tnames(rbspx+'_efw_mscb2'),/delete


;Save what we've done so far so we can pick up here next time by restoring
        tplot_save,'*',filename=fileroot+fn
        save,filename=fileroot+fn+'.idl'


     endelse


stop


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




	get_data,varE,data=varr


	;Separate the bursts by comparing the delta-time b/t each
	;data point to 1/samplerate

	dt = varr.x - shift(varr.x,1)
	dt = dt[1:n_elements(dt)-1]



	sr = rbsp_sample_rate(varr.x,out_med_av=medavg)
	store_data,varE+'_samplerate',data={x:varr.x,y:sr}
	store_data,varE+'_samplerate_diff',data={x:varr.x,y:abs(sr-medavg[0])}
	

	threshold = 1/medavg
	goo = where(abs(dt) ge 2*threshold[1])

	b = 0L
	q = 0L
	
	;left and right location of each burst chunk
	chunkL = [0,goo+1]
	chunkR = [goo-1,n_elements(sr)-1]

	;Get rid of abnormally small chunks. These sometimes occur if there is a small
	;gap in the data. 

	chunkduration = (chunkR - chunkL)/medavg[1]
	
	goo = where(chunkduration ge minduration)
	chunkL = chunkL[goo]
	chunkR = chunkR[goo]
	nchunks = n_elements(goo)

	print,'Duration (sec) of each chunk: ',(chunkR - chunkL)/medavg[1]


stop





;-----------------------------------------------------------------------------------
;Calculate Poynting flux for each chunk
;-----------------------------------------------------------------------------------


;			 Poynting flux coord system
;   		 	P1mgse = Bmgse x xhat_mgse  (xhat_mgse is spin axis component)
;				P2mgse = Bmgse x P1mgse
;  		   		P3mgse = Bmgse
;
;			 The output tplot variables are:
;
;			 	These three output variables contain a mix of spin axis and spin plane components:
;			 		pflux_p1  -> Poynting flux in perp1 direction
;			 		pflux_p2  -> Poynting flux in perp2 direction
; 			 		pflux_Bo  -> Poynting flux along Bo
;
;			 	These partial Poynting flux calculations contain only spin plane Ew.
;			 		pflux_nospinaxis_perp 
;			 		pflux_nospinaxis_para
;

Tlong = 1/fmin
Tshort = 1/fmax

;Ew and Bw in Pflux coord
	BurstE = [[0.],[0.],[0.]]
	BurstB = [[0.],[0.],[0.]]
	Bursttimes = 0d
        pflux_nospinaxis_para = 0d
        pflux_para = 0d
        pflux_nospinaxis_perp = 0d
        pflux_perp1 = 0d
        pflux_perp2 = 0d

	for i=0,nchunks-1 do begin

           t0z = varr.x[chunkL[i]]
           t1z = varr.x[chunkR[i]]


           ve = tsample(varE,[t0z,t1z],times=te)
           vb = tsample(varM,[t0z,t1z],times=tb)
           vm = tsample(rbspx+'_Mag_mgse',[t0z,t1z],times=tm)

           store_data,varE+'_tmp',data={x:te,y:ve}
           store_data,varM+'_tmp',data={x:tb,y:vb}
           store_data,rbspx+'_Mag_mgse_tmp',data={x:tm,y:vm}
           

           tplot,[varE+'_tmp',varM+'_tmp',rbspx+'_Mag_mgse_tmp']
           tlimit,t0z,t1z



           rbsp_poynting_flux,$
              varM+'_tmp',$
              varE+'_tmp',$
              Tshort,Tlong,$
              Bo=rbspx+'_Mag_mgse_tmp'

           get_data,'pflux_Ew',data=dtmp
           BurstE = [BurstE,dtmp.y]
           get_data,'pflux_Bw',data=dtmp
           BurstB = [BurstB,dtmp.y]
           Bursttimes = [Bursttimes,dtmp.x]

           get_data,'pflux_nospinaxis_para',data=dtmp
           pflux_nospinaxis_para = [pflux_nospinaxis_para,dtmp.y]
           get_data,'pflux_para',data=dtmp
           pflux_para = [pflux_para,dtmp.y]
           get_data,'pflux_nospinaxis_perp',data=dtmp
           pflux_nospinaxis_perp = [pflux_nospinaxis_perp,dtmp.y]
           get_data,'pflux_perp1',data=dtmp
           pflux_perp1 = [pflux_perp1,dtmp.y]
           get_data,'pflux_perp2',data=dtmp
           pflux_perp2 = [pflux_perp2,dtmp.y]
	
	endfor


	;Store the field-aligned burst data
	nn = n_elements(bursttimes)-1
	store_data,rbspx+'_efw_eb'+bt+'_pflux_coord',data={x:Bursttimes[1:nn],y:BurstE[1:nn,*]}
	store_data,rbspx+'_efw_mscb'+bt+'_pflux_coord',data={x:Bursttimes[1:nn],y:BurstB[1:nn,*]}
        store_data,rbspx+'_pflux_nospinaxis_para',data={x:Bursttimes[1:nn],y:pflux_nospinaxis_para[1:nn]}
        store_data,rbspx+'_pflux_nospinaxis_perp',data={x:Bursttimes[1:nn],y:pflux_nospinaxis_perp[1:nn]}
        store_data,rbspx+'_pflux_para',data={x:Bursttimes[1:nn],y:pflux_para[1:nn]}
        store_data,rbspx+'_pflux_perp1',data={x:Bursttimes[1:nn],y:pflux_perp1[1:nn]}
        store_data,rbspx+'_pflux_perp2',data={x:Bursttimes[1:nn],y:pflux_perp2[1:nn]}


ylim,['rbsp'+probe+'_pflux_nospinaxis_para','rbsp'+probe+'_pflux_nospinaxis_perp'],-1d-5,1d-5


                                ;Plot uncontaminated parallel and perp components


;interpolate mlat to high cadence so its data points show up on
;zoomed-in plot of short burst duration
tinterpol_mxn,rbspx+'_state_mlat',rbspx+'_efw_eb'+bt+'_pflux_coord'

ylim,'*pflux*',0,0
tplot,[rbspx+'_efw_eb'+bt+'_pflux_coord',$
       rbspx+'_efw_mscb'+bt+'_pflux_coord',$
       rbspx+'_pflux_nospinaxis_para',$
       rbspx+'_pflux_nospinaxis_perp',$
      rbspx+'_state_mlat_interp']


stop


;--------------------------------------------------
;Rotate each chunk to FA coord
;--------------------------------------------------



if rotate_to_fa then begin

   BurstE = [[0.],[0.],[0.]]
   BurstB = [[0.],[0.],[0.]]
   BursttimesE = 0d
   BursttimesB = 0d

   theta_kbE = 0.
   thetatimesE = 0d
   dtheta_kbE = 0.
   eigsE = [[0.],[0.],[0.]]
   emax2eintE = 0.
   eint2eminE = 0.
   emax_vecE = [[0.],[0.],[0.]]
   eint_vecE = [[0.],[0.],[0.]]
   emin_vecE = [[0.],[0.],[0.]]

   theta_kbB = 0.
   thetatimesB = 0d
   dtheta_kbB = 0.
   eigsB = [[0.],[0.],[0.]]
   emax2eintB = 0.
   eint2eminB = 0.
   emax_vecB = [[0.],[0.],[0.]]
   eint_vecB = [[0.],[0.],[0.]]
   emin_vecB = [[0.],[0.],[0.]]


   for i=0,nchunks-1 do begin

      t0z = varr.x[chunkL[i]]
      t1z = varr.x[chunkR[i]]

      ve = tsample(varE,[t0z,t1z],times=te)
      vb = tsample(varM,[t0z,t1z],times=tb)
      vm = tsample(rbspx+'_Mag_mgse',[t0z,t1z],times=tm)

      store_data,varE+'_tmp',data={x:te,y:ve}
      store_data,varM+'_tmp',data={x:tb,y:vb}
      store_data,rbspx+'_Mag_mgse_tmp',data={x:tm,y:vm}
      

      tplot,[varE+'_tmp',varM+'_tmp',rbspx+'_Mag_mgse_tmp']
      tlimit,t0z,t1z

                                ;Efield: Rotate each chunk to FA/minvar coord
      fa = rbsp_rotate_field_2_vec(varE+'_tmp',rbspx+'_Mag_mgse_tmp')
      get_data,varE+'_tmp_FA_minvar',data=dtmp
      BurstE = [BurstE,dtmp.y]
      BursttimesE = [BursttimesE,dtmp.x]

      get_data,'theta_kb',data=dtmp
      theta_kbE = [theta_kbE,dtmp.y]
      thetatimesE = [thetatimesE,dtmp.x]
      get_data,'dtheta_kb',data=dtmp
      dtheta_kbE = [dtheta_kbE,dtmp.y]
      get_data,'emax2eint',data=dtmp
      emax2eintE = [emax2eintE,dtmp.y]
      get_data,'eint2emin',data=dtmp
      eint2eminE = [eint2eminE,dtmp.y]
      get_data,'minvar_eigenvalues',data=dtmp
      eigsE = [eigsE,dtmp.y]
      get_data,'emax_vec_minvar',data=dtmp
      emax_vecE = [emax_vecE,dtmp.y]
      get_data,'eint_vec_minvar',data=dtmp
      eint_vecE = [eint_vecE,dtmp.y]
      get_data,'emin_vec_minvar',data=dtmp
      emin_vecE = [emin_vecE,dtmp.y]


                                ;Bfield: Rotate each chunk to FA/minvar coord
      fa = rbsp_rotate_field_2_vec(varM+'_tmp',rbspx+'_Mag_mgse_tmp')
      get_data,varM+'_tmp_FA_minvar',data=dtmp
      BurstB = [BurstB,dtmp.y]
      BursttimesB = [BursttimesB,dtmp.x]

      get_data,'theta_kb',data=dtmp
      theta_kbB = [theta_kbB,dtmp.y]
      thetatimesB = [thetatimesB,dtmp.x]
      get_data,'dtheta_kb',data=dtmp
      dtheta_kbB = [dtheta_kbB,dtmp.y]
      get_data,'emax2eint',data=dtmp
      emax2eintB = [emax2eintB,dtmp.y]
      get_data,'eint2emin',data=dtmp
      eint2eminB = [eint2eminB,dtmp.y]
      get_data,'minvar_eigenvalues',data=dtmp
      eigsB = [eigsB,dtmp.y]
      get_data,'emax_vec_minvar',data=dtmp
      emax_vecB = [emax_vecB,dtmp.y]
      get_data,'eint_vec_minvar',data=dtmp
      eint_vecB = [eint_vecB,dtmp.y]
      get_data,'emin_vec_minvar',data=dtmp
      emin_vecB = [emin_vecB,dtmp.y]

      tplot,[varE+'_tmp_FA_minvar',varM+'_tmp_FA_minvar',rbspx+'_Mag_mgse_tmp']


   endfor

   varE = varE + '_FA_minvar'
   varM = varM + '_FA_minvar'

                                ;Store the field-aligned burst data
   nn = n_elements(BursttimesE)-1
   store_data,varE,data={x:BursttimesE[1:nn],y:BurstE[1:nn,*]}
   nn = n_elements(BursttimesB)-1
   store_data,varM,data={x:BursttimesB[1:nn],y:BurstB[1:nn,*]}

   tplot,[varE,varM]

   ;; ;Store the minvar analysis variables
   nn = n_elements(thetatimesB)-1
   store_data,varM+'_theta_kb',data={x:thetatimesB[1:nn],y:theta_kbB[1:nn]}
   store_data,varM+'_dtheta_kb',data={x:thetatimesB[1:nn],y:dtheta_kbB[1:nn]}
   store_data,varM+'_emax2eint',data={x:thetatimesB[1:nn],y:emax2eintB[1:nn]}
   store_data,varM+'_eint2emin',data={x:thetatimesB[1:nn],y:eint2eminB[1:nn]}
   store_data,varM+'_minvar_eigenvalues',data={x:thetatimesB[1:nn],y:eigsB[1:nn]}
   store_data,varM+'_emax_vec',data={x:thetatimesB[1:nn],y:emax_vecB[1:nn]}
   store_data,varM+'_eint_vec',data={x:thetatimesB[1:nn],y:eint_vecB[1:nn]}
   store_data,varM+'_emin_vec',data={x:thetatimesB[1:nn],y:emin_vecB[1:nn]}

   nn = n_elements(thetatimesE)-1
   store_data,varE+'_theta_kb',data={x:thetatimesE[1:nn],y:theta_kbE[1:nn]}
   store_data,varE+'_dtheta_kb',data={x:thetatimesE[1:nn],y:dtheta_kbE[1:nn]}
   store_data,varE+'_emax2eint',data={x:thetatimesE[1:nn],y:emax2eintE[1:nn]}
   store_data,varE+'_eint2emin',data={x:thetatimesE[1:nn],y:eint2eminE[1:nn]}
   store_data,varE+'_minvar_eigenvalues',data={x:thetatimesE[1:nn],y:eigsE[1:nn]}
   store_data,varE+'_emax_vec',data={x:thetatimesE[1:nn],y:emax_vecE[1:nn]}
   store_data,varE+'_eint_vec',data={x:thetatimesE[1:nn],y:eint_vecE[1:nn]}
   store_data,varE+'_emin_vec',data={x:thetatimesE[1:nn],y:emin_vecE[1:nn]}

   options,varM+'_theta_kb','ytitle',rbspx+ '!CWave normal!Cangle'
   options,varM+'_dtheta_kb','ytitle',rbspx+'!CWave normal!Cangle!Cuncertainty'
   options,varE+'_theta_kb','ytitle',rbspx+ '!CWave normal!Cangle'
   options,varE+'_dtheta_kb','ytitle',rbspx+'!CWave normal!Cangle!Cuncertainty'
   
   tplot,[varE,varE+'_theta_kb',varE+'_emax2eint',varE+'_eint2emin']
   tplot,[varM,varM+'_theta_kb',varM+'_emax2eint',varM+'_eint2emin']

   stop

endif


;------------------------------------------------------------------
;Run Chasten's routine for both E and B
;------------------------------------------------------------------

	get_data,varE,data=varr


	;Separate the bursts by comparing the delta-time b/t each
	;data point to 1/samplerate

	dt = varr.x - shift(varr.x,1)
	dt = dt[1:n_elements(dt)-1]

	sr = rbsp_sample_rate(varr.x,out_med_av=medavg)
;	store_data,varE+'_samplerate',data={x:varr.x,y:sr}
;	store_data,varE+'_samplerate_diff',data={x:varr.x,y:abs(sr-medavg[0])}
	;tplot,[varE,varE+'_samplerate',varE+'_samplerate_diff']
	

	threshold = 1/medavg
	goo = where(abs(dt) ge 2*threshold[1])

	b = 0L
	q = 0L
	
	;left and right location of each burst chunk
	chunkL = [0,goo+1]
	chunkR = [goo-1,n_elements(sr)-1]

	;Get rid of abnormally small chunks. These sometimes occur if there is a small
	;gap in the data. 

	chunkduration = (chunkR - chunkL)/medavg[1]
	
	goo = where(chunkduration ge minduration)
	chunkL = chunkL[goo]
	chunkR = chunkR[goo]
	nchunks = n_elements(goo)

	print,'Duration (sec) of each chunk: ',(chunkR - chunkL)/medavg[1]

	BurstE = [[0.],[0.],[0.]]
	BurstB = [[0.],[0.],[0.]]
	Bursttimes = 0d

	for i=0,nchunks-1 do begin

		t0z = varr.x[chunkL[i]]
		t1z = varr.x[chunkR[i]]

		ve = tsample(varE,[t0z,t1z],times=te)
		vb = tsample(varM,[t0z,t1z],times=tb)
		vm = tsample(rbspx+'_Mag_mgse',[t0z,t1z],times=tm)

		store_data,varE+'_tmp',data={x:te,y:ve}
		store_data,varM+'_tmp',data={x:tb,y:vb}
		store_data,rbspx+'_Mag_mgse_tmp',data={x:tm,y:vm}

		get_data,varM+'_tmp',data=dtmp
		BurstE = [BurstE,dtmp.y]
		BurstB = [BurstB,dtmp.y]
		Bursttimes = [Bursttimes,dtmp.x]


		;-------
	
		;Bfield: Run Chaston crib on each chunk	
		twavpol,varM+'_tmp',prefix='tmp'
		;twavpol,varM+'_tmp',prefix='tmp',nopfft=16448,steplength=4112
		;twavpol,varM+'_tmp',prefix='tmp',nopfft=16448,steplength=4096


		;Find the size of returned data
		get_data,'tmp'+'_waveangle',data=dtmp
		sz = n_elements(dtmp.v)

		if i eq 0 then begin
			waveangleB = replicate(0.,[1,sz])
			powspecB = replicate(0.,[1,sz]) 
			degpolB = replicate(0.,[1,sz])
			elliptictB = replicate(0.,[1,sz])
			helicitB = replicate(0.,[1,sz])
			pspec3B = replicate(0.,[1,sz,3])
			chastontimesB = 0d
		endif

		;change wave normal angle to degrees
		get_data,'tmp'+'_waveangle',data=dtmp
		dtmp.y = dtmp.y/!dtor	
		waveangleB = [waveangleB,dtmp.y]
		chastontimesB = [chastontimesB,dtmp.x]		
		
		get_data,'tmp'+'_powspec',data=dtmp
		powspecB = [powspecB,dtmp.y]
		get_data,'tmp'+'_degpol',data=dtmp
		degpolB = [degpolB,dtmp.y]
		get_data,'tmp'+'_elliptict',data=dtmp
		elliptictB = [elliptictB,dtmp.y]
		get_data,'tmp'+'_helict',data=dtmp
		helicitB = [helicitB,dtmp.y]
		get_data,'tmp'+'_pspec3',data=dtmp
		pspec3B = [pspec3B,dtmp.y]
                if i eq 0 then freqvalsB = dtmp.v
	


		;Efield: Run Chaston crib on each chunk	
		twavpol,varE+'_tmp',prefix='tmp'
		;twavpol,varE+'_tmp_FA',prefix='tmp',nopfft=16448,steplength=4112
		;twavpol,varE+'_tmp_FA',prefix='tmp',nopfft=16448,steplength=4096



		if i eq 0 then begin
			waveangleE = replicate(0.,[1,sz])
			powspecE = replicate(0.,[1,sz]) 
			degpolE = replicate(0.,[1,sz])
			elliptictE = replicate(0.,[1,sz])
			helicitE = replicate(0.,[1,sz])
			pspec3E = replicate(0.,[1,sz,3])
			chastontimesE = 0d
		endif

		;change wave normal angle to degrees
		get_data,'tmp'+'_waveangle',data=dtmp
		dtmp.y = dtmp.y/!dtor	
		waveangleE = [waveangleE,dtmp.y]
		chastontimesE = [chastontimesE,dtmp.x]		
	
	
		get_data,'tmp'+'_powspec',data=dtmp
		powspecE = [powspecE,dtmp.y]
		get_data,'tmp'+'_degpol',data=dtmp
		degpolE = [degpolE,dtmp.y]
		get_data,'tmp'+'_elliptict',data=dtmp
		elliptictE = [elliptictE,dtmp.y]
		get_data,'tmp'+'_helict',data=dtmp
		helicitE = [helicitE,dtmp.y]
		get_data,'tmp'+'_pspec3',data=dtmp
		pspec3E = [pspec3E,dtmp.y]
                if i eq 0 then freqvalsE = dtmp.v

	endfor



	;Store the field-aligned burst data
	nn = n_elements(bursttimes)-1
	store_data,varM,data={x:Bursttimes[1:nn],y:BurstB[1:nn,*]}
	store_data,varE,data={x:Bursttimes[1:nn],y:BurstE[1:nn,*]}


	;Store the Chaston crib variables
	nn = n_elements(chastontimesB)-1
	store_data,varM+'_waveangle',data={x:chastontimesB[1:nn],y:waveangleB[1:nn,*],v:freqvalsB}
	store_data,varM+'_powspec',data={x:chastontimesB[1:nn],y:powspecB[1:nn,*],v:freqvalsB}
	store_data,varM+'_degpol',data={x:chastontimesB[1:nn],y:degpolB[1:nn,*],v:freqvalsB}
	store_data,varM+'_elliptict',data={x:chastontimesB[1:nn],y:elliptictB[1:nn,*],v:freqvalsB}
	store_data,varM+'_helicit',data={x:chastontimesB[1:nn],y:helicitB[1:nn,*],v:freqvalsB}
	store_data,varM+'_pspec3',data={x:chastontimesB[1:nn],y:pspec3B[1:nn,*,*],v:freqvalsB}


	nn = n_elements(chastontimesE)-1
	store_data,varE+'_waveangle',data={x:chastontimesE[1:nn],y:waveangleE[1:nn,*],v:freqvalsE}
	store_data,varE+'_powspec',data={x:chastontimesE[1:nn],y:powspecE[1:nn,*],v:freqvalsE}
	store_data,varE+'_degpol',data={x:chastontimesE[1:nn],y:degpolE[1:nn,*],v:freqvalsE}
	store_data,varE+'_elliptict',data={x:chastontimesE[1:nn],y:elliptictE[1:nn,*],v:freqvalsE}
	store_data,varE+'_helicit',data={x:chastontimesE[1:nn],y:helicitE[1:nn,*],v:freqvalsE}
	store_data,varE+'_pspec3',data={x:chastontimesE[1:nn],y:pspec3E[1:nn,*,*],v:freqvalsE}



	ylim,[varM+'_powspec',$
			varM+'_degpol',$
			varM+'_waveangle',$
			varM+'_elliptict',$
			varM+'_helicit',$
			varM+'_pspec3'],100,8000,1

	zlim,varM+'_waveangle',0,90,0
	zlim,varM+'_powspec',1d-9,1d-4,1
	zlim,varM+'_pspec3',1d-9,1d-4,1

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




	options,[varM+'_powspec',$
			varM+'_degpol',$
			varM+'_waveangle',$
			varM+'_elliptict',$
			varM+'_helict',$
			varM+'_pspec3'],'spec',1

	options,[varE+'_powspec',$
			varE+'_degpol',$
			varE+'_waveangle',$
			varE+'_elliptict',$
			varE+'_helict',$
			varE+'_pspec3'],'spec',1



	tplot,[varM,$
			varM+'_powspec',$
			varM+'_degpol',$
			varM+'_waveangle',$
			varM+'_elliptict',$
			varM+'_helict',$
			varM+'_pspec3']


	tplot,[varE,$
			varE+'_powspec',$
			varE+'_degpol',$
			varE+'_waveangle',$
			varE+'_elliptict',$
			varE+'_helict',$
			varE+'_pspec3']



	;remove unnecessary variables
	store_data,['theta_kb','dtheta_kb','minvar_eigenvalues','emax2eint','eint2emin','emax_vec_minvar','eint_vec_minvar','emin_vec_minvar'],/delete




























;; ;********************************************************************************
;; ;Spectral Poynting flux

;; get_data,'rbsp'+probe+'_pflux_nospinaxis_para',data=pf
;; minv = min(pf.y,/nan)
;; maxv = max(pf.y,/nan)

;; minvalpara = minv

;; !p.charsize = 1.5
;; !x.margin = [5,5]


;; muo = 4d0*!DPI*1d-7     ; -Permeability of free space (N/A^2 or H/m)


;; ;pro rbsp_spec, tplot_var, $
;; ;	tplot_var_spec=tplot_var_spec, $
;; ;	npts=npts, n_ave=n_ave, $
;; ;	tspec=tspec, spec=spec, freq=freq, df=df, $
;; ;	nan_fill_gaps=nan_fill_gaps, $
;; ;	median_subtract=median_subtract, median_width=median_width, median_val=median_val, $
;; ;	mingap=mingap, $
;; ;	verbose=verbose

;; rbsp_spec,'rbsp'+probe+'_pflux_nospinaxis_para',$
;;           npts=64,freq=freq_bins,df=df,tspec=time_index

;; print,'time resolution (msec) = ',1000.*(tspec[1]-tspec[0])
;; print,'freq resolution (Hz) = ',df
;; print,'freqs (Hz) = ',ff

;; get_data,'rbsp'+probe+'_pflux_nospinaxis_para_SPEC',data=dd
;; maxs = max(dd.y,/nan)
;; mins = min(dd.y,/nan)


;; ylim,'rbsp'+probe+'_pflux_nospinaxis_para',0,0
;; ylim,['rbsp'+probe+'_pflux_nospinaxis_para_SPEC'],10.,4000.,0
;; zlim,['rbsp'+probe+'_pflux_nospinaxis_para_SPEC'],maxs/10d^5,maxs/10.,1
;; options,'rbsp'+probe+'_pflux_nospinaxis_para_SPEC','spec',1
;; tplot,['rbsp'+probe+'_pflux_nospinaxis_para',$
;;        'rbsp'+probe+'_pflux_nospinaxis_para_SPEC',$
;;        'rbsp'+probe+'_efw_mscb'+bt+'_mgse',$
;;        'rbsp'+probe+'_efw_eb'+bt+'_mgse']



;; ;**************************************************
;; ;Find where Poynting flux is + and - along Bo
;; ;**************************************************

;; get_data,'rbsp'+probe+'_pflux_nospinaxis_para',data=ppara

;; ;Separate positive and negative values
;; goop = where(ppara.y ge 0.)
;; goon = where(ppara.y lt 0.)
;; ppara_p = ppara.y
;; ppara_p[goon] = 0.
;; ppara_n = ppara.y	
;; ppara_n[goop] = 0.	

;; store_data,'ppara_p',data={x:ppara.x,y:ppara_p}
;; store_data,'ppara_n',data={x:ppara.x,y:ppara_n}

;; rbsp_spec,'ppara_p',npts=64,freq=freq_bins2,df=df2,tspec=time_index2
;; rbsp_spec,'ppara_n',npts=64

;; ylim,['ppara_p_SPEC','ppara_n_SPEC'],10.,10000.,0.
;; zlim,['ppara_p_SPEC','ppara_n_SPEC'],maxs/10d^5,maxs,1
;; tplot,['ppara_p','ppara_p_SPEC','ppara_n','ppara_n_SPEC']

;; get_data,'ppara_p_SPEC',data=ppara_specp
;; get_data,'ppara_n_SPEC',data=ppara_specn


;; ;--------------------------------------------
;; ;create red, blue and puke-yellow colors for plots
;; ;--------------------------------------------

;; loadct,39
;; tvlct,r,g,b,/get  
;; r[3] = 218
;; g[3] = 165
;; b[3] = 32
;; r[1] = 178
;; g[1] = 34
;; b[1] = 34
;; r[2] = 72
;; g[2] = 61
;; b[2] = 139
;; r[0] = 0
;; g[0] = 0
;; b[0] = 0

;; modifyct,20,'mycolors',r,g,b
;; loadct,20

;; ;-------------------
;; ;remove small values
;; ;-------------------

;; minv = max(ppara_specp.y,/nan)/1d4

;; ;Positive parallel values
;; tmpy = where(abs(ppara_specp.y) lt minv)
;; if tmpy[0] ne -1 then ppara_specp.y[tmpy] = 0


;; ;Negative parallel values
;; tmpy = where(abs(ppara_specn.y) lt minv)
;; if tmpy[0] ne -1 then ppara_specn.y[tmpy] = 0


;; ;---------------------------
;; ;red - upwards Poynting flux
;; ;---------------------------

;; tmpy = where(ppara_specp.y gt minv)
;; if tmpy[0] ne -1 then ppara_specp.y[tmpy] = 2

;; ;------------------------------
;; ;blue - downwards Poynting flux
;; ;------------------------------

;; tmpy = where(ppara_specn.y gt minv)
;; if tmpy[0] ne -1 then ppara_specn.y[tmpy] = 1



;; ;Combine the upwards and downwards parallel spectra
;; ;pparab = ppara_specp.y > ppara_specn.y
;; pparab = ppara_specp.y + ppara_specn.y


;; store_data,'pparab',data={x:time_index2,y:pparab,v:freq_bins2}
;; options,'pparab','spec',1
;; ylim,'pparab',10.,4000.,0
;; ylim,'rbsp'+probe+'_pflux_nospinaxis_para',0,0
;; ylim,['rbsp'+probe+'_pflux_nospinaxis_para_SPEC'],10.,4000.,0
;; zlim,['rbsp'+probe+'_pflux_nospinaxis_para_SPEC'],maxs/10d^5,maxs,1
;; zlim,'pparab',0,3
;; options,'rbsp'+probe+'_pflux_nospinaxis_para_SPEC','spec',1


;; ;Red = upwards Pflux
;; ;Blue = downwards
;; ;Green = could be either upwards or downwards
;; tplot,['pparab',$
;;        'rbsp'+probe+'_pflux_nospinaxis_para',$
;;        'rbsp'+probe+'_pflux_nospinaxis_para_SPEC',$
;;        'rbsp'+probe+'_efw_mscb'+bt+'_mgse',$
;;        'rbsp'+probe+'_efw_eb'+bt+'_mgse']
















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
