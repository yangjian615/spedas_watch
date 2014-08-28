;WARNING!!! THIS CALCULATION IS VERY PRELIMINARY. DO NOT PUBLISH OR PRESENT
;RESULTS WITHOUT FIRST CONSULTING THE EFW PI JOHN WYGANT wygan001@umn.edu

;Crib sheet for calling rbsp_poynting_flux.pro

;Procedure: load EMFISIS data in GSE. 
;			Transform EMFISIS GSE -> MGSE
;			Load EFW despun waveform data in MGSE
;			Call Poynting flux program

;Created by Aaron W Breneman, UMN awbrenem@gmail.com
;


	rbsp_efw_init
	!rbsp_efw.user_agent = ''   ;for faster data downloads

	date = '2012-10-14'   ;Wave at 4 Hz
	t0 = time_double(date + '/05:00')
	t1 = time_double(date + '/07:00')

	;date = '2013-03-01'   
	;date = '2013-02-26'   
	timespan,date


	probe='a'
	rbspx = 'rbsp'+probe



;--------------------------------------------------------------------------------
;Find the GSE coordinates of the sc spin axis. This will be used to transform the 
;Mag data from GSE -> MGSE coordinates
;--------------------------------------------------------------------------------


;Load spice stuff

	if ~keyword_set(no_spice_load) then rbsp_load_spice_kernels

	;Get antenna pointing direction and stuff
	rbsp_load_state,probe=probe,/no_spice_load,datatype=['spinper','spinphase','mat_dsc','Lvec'] 

	rbsp_efw_position_velocity_crib,/no_spice_load,/noplot

	get_data,rbspx+'_spinaxis_direction_gse',data=wsc_GSE	


 
;------------------------------------------------------
;Get EMFISIS mag data in GSE
;------------------------------------------------------

;Load EMFISIS data

	rbsp_load_emfisis,probe=probe,coord='gse',cadence='hires',level='l3'
	;rbsp_load_emfisis,probe=probe,coord='gse',cadence='4sec',level='l3'


;Transform the Mag data to MGSE coordinates

	get_data,rbspx+'_emfisis_l3_hires_gse_Mag',data=tmpp
	;get_data,rbspx+'_emfisis_l3_4sec_gse_Mag',data=tmpp

	wsc_GSE_tmp = [[interpol(wsc_GSE.y[*,0],wsc_GSE.x,tmpp.x)],$
				   [interpol(wsc_GSE.y[*,1],wsc_GSE.x,tmpp.x)],$
				   [interpol(wsc_GSE.y[*,2],wsc_GSE.x,tmpp.x)]]

	;wsc_GSE_tmp = [[wsc_GSE.y[0,0]],[wsc_GSE.y[0,1]],[wsc_GSE.y[0,2]]]

	rbsp_gse2mgse,rbspx+'_emfisis_l3_hires_gse_Mag',reform(wsc_GSE_tmp),newname=rbspx+'_Mag_mgse'
	;rbsp_gse2mgse,rbspx+'_emfisis_l3_4sec_gse_Mag',reform(wsc_GSE_tmp),newname=rbspx+'_Mag_mgse'




;----------------------------------------------------------
;Get Esvy data in MGSE 
;----------------------------------------------------------


	;Load Esvy data in MGSE 
	rbsp_load_efw_esvy_mgse,probe=probe,/no_spice_load

	


;---------------------------------------------------------
;Reduce the data to reasonable times
;---------------------------------------------------------

	m1 = tsample(rbspx+'_Mag_mgse',[t0,t1],times=tm)
 	store_data,rbspx+'_Mag_mgse_r',data={x:tm,y:m1}
	m1 = tsample(rbspx+'_efw_esvy_mgse',[t0,t1],times=tm)
 	store_data,rbspx+'_efw_esvy_mgse_r',data={x:tm,y:m1}


;----------------------------------------------------------
;Get Poynting flux
;----------------------------------------------------------

	;Tlong = 40.  ;seconds
	;Tshort = 1. 

	;EMIC waves
	Tlong = 1.  	   ;0.1 Hz
	Tshort = 0.125       ;8 Hz

	;EMIC waves
;	Tlong = 2.  ;seconds
;	Tshort = 0.2 


	rbsp_poynting_flux,rbspx+'_Mag_mgse_r',rbspx+'_efw_esvy_mgse_r',Tshort,Tlong

	copy_data,'pftst_nospinaxis_perp',rbspx+'_pftst_nospinaxis_perp'
	copy_data,'pftst_nospinaxis_para',rbspx+'_pftst_nospinaxis_para'
	copy_data,'pftst_p1',rbspx+'_pftst_p1'
	copy_data,'pftst_p2',rbspx+'_pftst_p2'
	copy_data,'pftst_Bo',rbspx+'_pftst_Bo'
	copy_data,'Bw_pftst_p3',rbspx+'_Bw_pftst_p3'
	copy_data,'Bw_pftst_p2',rbspx+'_Bw_pftst_p2'
	copy_data,'Mag_mgse_DC_interp',rbspx+'_Mag_mgse_DC_interp'

	store_data,['pftst_nospinaxis_perp','pftst_nospinaxis_para','pftst_p1','pftst_p2','pftst_Bo','Bw_pftst_p3','Bw_pftst_p2','Mag_mgse_DC_interp'],/delete

;----------------------------------------------------------
;Plot various quantities
;----------------------------------------------------------


	;compare pure to mixed pflux
	tplot,rbspx+'_'+['pftst_nospinaxis_perp','pftst_nospinaxis_para','pftst_p1','pftst_p2','pftst_Bo']


	;compare E and B to pftst

	;Perp to field component
	
	ylim,rbspx+'_pftst_nospinaxis_perp',-0.005,0.005
	ylim,rbspx+'_pftst_nospinaxis_para',-0.005,0.005
	ylim,[rbspx+'_Ew_pftst_p1',rbspx+'_Bw_pftst_p3',rbspx+'_Mag_mgse_DC_interp'],0,0
	tplot,[rbspx+'_pftst_nospinaxis_perp',rbspx+'_Ew_pftst_p1',rbspx+'_Bw_pftst_p3',rbspx+'_Mag_mgse_DC_interp']

	;Field aligned component
	tplot,[rbspx+'_pftst_nospinaxis_para',rbspx+'_Ew_pftst_p1',rbspx+'_Bw_pftst_p2',rbspx+'_Mag_mgse_DC_interp']


	tplot,[rbspx+'_pftst_nospinaxis_para',rbspx+'_pftst_nospinaxis_perp']

