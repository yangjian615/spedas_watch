;rbsp_efw_spinfit_vxb_subtract_crib.pro
;
;Create the vxb subtracted spinfit data (now from E12 data only)
;
;keywords:
;			ql -> select to load EMFISIS quicklook data. Defaults to hires L3 data but
;				  quicklook data are available sooner.
;			qa -> select to load QA waveform data. Don't want to use this route for normal
;				  data processing. 
;			hiresl3 -> loads the EMFISIS high resolution 64 S/s L3 GSE data
;
;
;By Aaron W Breneman
;University of Minnesota
;2013-04-16



pro rbsp_efw_spinfit_vxb_subtract_crib,probe,no_spice_load=no_spice_load,noplot=noplot,ql=ql,qa=qa,hiresl3=hiresl3


;Get the time range if it hasn't already been set
	x = timerange()
	date = strmid(time_string(x[0]),0,10)

	rbspx = 'rbsp'+probe


;Load spice stuff

	if ~keyword_set(no_spice_load) then rbsp_load_spice_kernels

	;Get antenna pointing direction and stuff
	rbsp_load_state,probe=probe,/no_spice_load,datatype=['spinper','spinphase','mat_dsc','Lvec'] 

	rbsp_efw_position_velocity_crib,/no_spice_load,/noplot
	get_data,rbspx+'_spinaxis_direction_gse',data=wsc_GSE	


;Load eclipse times 

	if ~keyword_set(noplot) then begin
		rbsp_load_eclipse_predict,probe,date
		get_data,'rbsp'+probe+'_umbra',data=eu
		get_data,'rbsp'+probe+'_penumbra',data=ep
	endif

;Load waveform data
	if ~keyword_set(qa) then rbsp_load_efw_waveform, probe=probe, datatype = 'esvy', coord = 'uvw',/noclean
	if keyword_set(qa) 	then rbsp_load_efw_waveform, probe=probe, datatype = 'esvy', coord = 'uvw',/noclean,/qa
	
		
;Load the mag data	
	if keyword_set(ql) then begin
		rbsp_load_emfisis,probe=probe,/quicklook

		get_data,rbspx+'_emfisis_quicklook_Mag',data=dd2
		if ~is_struct(dd2) then begin
			print,'******NO QL MAG DATA TO LOAD.....rbsp_efw_DCfield_removal_crib.pro*******'
			return
		endif		

	endif else begin

		if keyword_set(hiresl3) then type = 'hires' else type = '1sec'

		rbsp_load_emfisis,probe=probe,coord='gse',cadence=type,level='l3'

		get_data,rbspx+'_emfisis_l3_'+type+'_gse_Mag',data=dd2
		if ~is_struct(dd2) then begin
			print,'******NO L3 MAG DATA TO LOAD.....rbsp_efw_DCfield_removal_crib.pro*******'
			return
		endif		

	endelse

		
;Spinfit data and transform to MGSE coordinates
	rbsp_spinfit, rbspx + '_efw_esvy', plane_dim = 0 ; V12
	
	get_data,rbspx + '_efw_esvy_spinfit',data=dx

	if ~is_struct(dx) then begin
		print,"CAN'T SPINFIT THE DATA....RETURNING"
		return
	endif


	
	rbsp_cotrans, rbspx + '_efw_esvy_spinfit', rbspx + '_sfit12_mgse', /dsc2mgse



;Find the co-rotation Efield
	rbsp_corotation_efield,probe,date,/no_spice_load


message,"Rotating emfisis data...",/continue

	if keyword_set(ql) then begin
		;Some of the EMFISIS quicklook data extend beyond the day loaded. This messes things up
		;later. Remove these data points now. 

		t0 = time_double(date)
		t1 = t0 + 86400.

		ttst = tnames(rbspx+'_emfisis_quicklook_Mag',cnt)
		if cnt eq 1 then time_clip,rbspx+'_emfisis_quicklook_Mag',t0,t1,replace=1,error=error,newname=rbspx+'_emfisis_quicklook_Mag'
		ttst = tnames(rbspx+'_emfisis_quicklook_Magnitude',cnt)
		if cnt eq 1 then time_clip,rbspx+'_emfisis_quicklook_Magnitude',t0,t1,replace=1,error=error,newname=rbspx+'_emfisis_quicklook_Magnitude'


		;Create the dlimits structure for the EMFISIS quantity. Jianbao's spinfit program needs
		;to see that the coords are 'uvw'
		get_data,rbspx +'_emfisis_quicklook_Mag',data=datt
		data_att = {coord_sys:'uvw'}
		dlim = {data_att:data_att}
		store_data,rbspx +'_emfisis_quicklook_Mag',data=datt,dlimits=dlim


		;spinfit the mag data and transform to MGSE
		
		get_data,rbspx +'_emfisis_quicklook_Mag',data=dmag
		
		if is_struct(dmag) then begin		
			rbsp_decimate,rbspx +'_emfisis_quicklook_Mag', upper = 2
			rbsp_spinfit,rbspx +'_emfisis_quicklook_Mag', plane_dim = 0
			rbsp_cotrans,rbspx +'_emfisis_quicklook_Mag_spinfit', rbspx + '_mag_mgse', /dsc2mgse
		endif

	endif else begin
		;Transform the EMFISIS gse mag data to mgse
	
		get_data,rbspx+'_emfisis_l3_'+type+'_gse_Mag',data=tmpp

		if is_struct(tmpp) then begin
			wsc_GSE_tmp = [[interpol(wsc_GSE.y[*,0],wsc_GSE.x,tmpp.x)],$
						   [interpol(wsc_GSE.y[*,1],wsc_GSE.x,tmpp.x)],$
						   [interpol(wsc_GSE.y[*,2],wsc_GSE.x,tmpp.x)]]
		
		
			message,"Rotating emfisis l3_hires, npoints:"+string(n_elements(tmpp.x)),/continue

			rbsp_gse2mgse,rbspx+'_emfisis_l3_'+type+'_gse_Mag',wsc_GSE_tmp,newname=rbspx+'_mag_mgse'
		endif


	endelse

message,"Done rotating emfisis data...",/continue





;Find residual Efield (i.e. no Vsc x B and no Vcoro x B field)	
	dif_data,rbspx+'_state_vel_mgse',rbspx+'_state_vel_coro_mgse',newname='vel_total'
	
	get_data,'vel_total',data=vt
	get_data,rbspx + '_mag_mgse',data=mmgse
	get_data,rbspx+'_sfit12_mgse',data=sfmgse
	
	if is_struct(vt) and is_struct(mmgse) and is_struct(sfmgse) then $
		rbsp_vxb_subtract,'vel_total',rbspx + '_mag_mgse',rbspx+'_sfit12_mgse'


	copy_data,'Esvy_mgse_vxb_removed',rbspx+'_efw_esvy_mgse_vxb_removed_spinfit'







;Apply crude antenna effective length correction to minimize residual field
	get_data,rbspx+'_efw_esvy_mgse_vxb_removed_spinfit', data = d

	if is_struct(d) then begin
		d.y[*, 1] *= 0.947d   ;found by S. Thaller
		d.y[*, 2] *= 0.947d
		;; d.y[*, 1] *= 1d
		;; d.y[*, 2] *= 1d
		store_data,rbspx+'_efw_esvy_mgse_vxb_removed_spinfit', data = d
	endif



;add back in the corotation field
	add_data,rbspx+'_efw_esvy_mgse_vxb_removed_spinfit',rbspx+'_E_coro_mgse',newname=rbspx+'_efw_esvy_mgse_vxb_removed_spinfit'



	split_vec,rbspx+'_efw_esvy_mgse_vxb_removed_spinfit'
	ylim,[rbspx+'_efw_esvy_mgse_vxb_removed_spinfit_y',rbspx+'_efw_esvy_mgse_vxb_removed_spinfit_z'],-5,5

	options,rbspx+'_efw_esvy_mgse_vxb_removed_spinfit_?','ysubtitle',''

	options,rbspx+'_efw_esvy_mgse_vxb_removed_spinfit_x','ytitle','Ex MGSE!CInertial Frame!C(E-V!Dsc!NxB)!Cspinfit!C[mV/m]'
	options,rbspx+'_efw_esvy_mgse_vxb_removed_spinfit_y','ytitle','Ey MGSE!CInertial Frame!C(E-V!Dsc!NxB)!Cspinfit!C[mV/m]'
	options,rbspx+'_efw_esvy_mgse_vxb_removed_spinfit_z','ytitle','Ez MGSE!CInertial Frame!C(E-V!Dsc!NxB)!Cspinfit!C[mV/m]'

;	options,rbspx + '_mag_mgse_spinfit','ytitle','Bfield MGSE!C[nT]'
;	options,rbspx + '_mag_mgse_spinfit','ysubtitle',''
	options,rbspx + '_mag_mgse','ytitle','Bfield MGSE!C[nT]'
	options,rbspx + '_mag_mgse','ysubtitle',''

	options,rbspx+'_efw_esvy_mgse_vxb_removed_spinfit_x','colors',4
	options,rbspx+'_efw_esvy_mgse_vxb_removed_spinfit_y','colors',1
	options,rbspx+'_efw_esvy_mgse_vxb_removed_spinfit_z','colors',2



	if ~keyword_set(noplot) then begin
		tplot,[rbspx+'_efw_esvy_mgse_vxb_removed_spinfit_y',rbspx+'_efw_esvy_mgse_vxb_removed_spinfit_z']

		if is_struct(eu) then timebar,eu.x,color=50
		if is_struct(eu) then timebar,eu.x + eu.y,color=50
		if is_struct(ep) then timebar,ep.x,color=80
		if is_struct(ep) then timebar,ep.x + ep.y,color=80
	endif

	message,"Done with rbsp_efw_spinfit_vxb_crib...",/continue

end

