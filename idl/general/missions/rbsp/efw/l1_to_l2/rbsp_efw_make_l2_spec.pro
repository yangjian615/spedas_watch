;+
;rbsp_efw_spec_L2_crib
;
;Loads and plots RBSP (Van Allen probes) spectral data
;used for the L2 CDF files
;
; SPEC returns 7 channels, with nominal data selection:
;		SPEC0: E12AC
;		SPEC1: E56AC
;		SPEC2: SCMpar
;		SPEC3: SCMperp
;		SPEC4: SCMW
;		SPEC5: V1AC
;		SPEC6: V2AC
;
;			Select 7 of: E12dc,E34dc,E56dc
;						 E12ac,E34ac,E56ac
;						 Edcpar,Edcprp
;						 Eacpar,Eacprp
;						 V1ac,V2ac,V3ac,V4ac,V5ac,V6ac
;						 SCMU,SCMV,SCMW
;						 SCMpar,SCMprp,
;						 (V1dc+V2dc+V3dc+V4dc)/4,
;						 Edcprp2, Eacprp2, SCMprp2
;
;	notes: 
;
;
;	Aaron Breneman, UMN, Feb 2013
;	email: awbrenem@gmail.com
;
; VERSION:
;	$LastChangedBy: kersten $
;	$LastChangedDate: 2013-09-18 13:41:10 -0700 (Wed, 18 Sep 2013) $
;	$LastChangedRevision: 13062 $
;	$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/l1_to_l2/rbsp_efw_make_l2_spec.pro $
;
;-



pro rbsp_efw_make_l2_spec,sc,date,folder=folder

	skip_plot = 1   ;set to skip restoration of cdf file and test plotting at end of program

	dprint,'BEGIN TIME IS ',systime()

	if n_elements(version) eq 0 then version = 1
	vstr = string(version, format='(I02)')
	version = 'v'+vstr

	sc=strlowcase(sc)
	if sc ne 'a' and sc ne 'b' then begin
		dprint,'Invalid spacecraft: '+sc+', returning.'
		return
	endif
	rbspx = 'rbsp'+sc

	if ~keyword_set(folder) then folder ='~/Desktop/code/Aaron/RBSP/l2_processing_cribs/'
	; make sure we have the trailing slash on folder
	if strmid(folder,strlen(folder)-1,1) ne path_sep() then folder=folder+path_sep()
	file_mkdir,folder

	; Grab the skeleton file.
	skeleton=rbspx+'/l2/spec/0000/'+ $
		rbspx+'_efw-l2_spec_00000000_v'+vstr+'.cdf'


;########################
;testing skeleton
;skeleton = 'rbspa_efw-l2_spec_00000000_v01.cdf'
;source_file='~/Desktop/code/Aaron/RBSP/TDAS_trunk_svn/ssl_general/missions/rbsp/efw/l1_to_l2/' + skeleton
;stop
;########################



	source_file=file_retrieve(skeleton,_extra=!rbsp_efw)

	; use skeleton from the staging dir until we go live in the main data tree
	;source_file='/Volumes/DataA/user_volumes/kersten/data/rbsp/'+skeleton
	
	; make sure we have the skeleton CDF
	source_file=file_search(source_file,count=found) ; looking for single file, so count will return 0 or 1
	if ~found then begin
		dprint,'Could not find spec v'+vstr+' skeleton CDF, returning.'
		return
	endif
	; fix single element source file array
	source_file=source_file[0]

	; fix single element source file array
	source_file=source_file[0]


	timespan, date

;Load the spectrogram data
	rbsp_load_efw_spec,probe=sc,type='calibrated'


	;Determine number of bins
	tn = tnames('*spec0')
	get_data,tn[0],data=dd
	bins = strtrim(n_elements(dd.v),2)

	get_data,rbspx+'_efw_'+bins+'_spec0',data=spec0,dlimits=dlim0
	get_data,rbspx+'_efw_'+bins+'_spec1',data=spec1,dlimits=dlim1
	get_data,rbspx+'_efw_'+bins+'_spec2',data=spec2,dlimits=dlim2
	get_data,rbspx+'_efw_'+bins+'_spec3',data=spec3,dlimits=dlim3
	get_data,rbspx+'_efw_'+bins+'_spec4',data=spec4,dlimits=dlim4
	get_data,rbspx+'_efw_'+bins+'_spec5',data=spec5,dlimits=dlim5
	get_data,rbspx+'_efw_'+bins+'_spec6',data=spec6,dlimits=dlim6

	chn0 = strlowcase(dlim0.data_att.channel)
	chn1 = strlowcase(dlim1.data_att.channel)
	chn2 = strlowcase(dlim2.data_att.channel)
	chn3 = strlowcase(dlim3.data_att.channel)
	chn4 = strlowcase(dlim4.data_att.channel)
	chn5 = strlowcase(dlim5.data_att.channel)
	chn6 = strlowcase(dlim6.data_att.channel)

	ep0 = tplot_time_to_epoch(spec0.x,/epoch16)
	ep1 = tplot_time_to_epoch(spec1.x,/epoch16)
	ep2 = tplot_time_to_epoch(spec2.x,/epoch16)
	ep3 = tplot_time_to_epoch(spec3.x,/epoch16)
	ep4 = tplot_time_to_epoch(spec4.x,/epoch16)
	ep5 = tplot_time_to_epoch(spec5.x,/epoch16)
	ep6 = tplot_time_to_epoch(spec6.x,/epoch16)

	datatimes = spec0.x


	;Get the time structure for the flag values. These are not necessarily at the cadence
	;of physical data.
	epoch_flag_times,date,5,epoch_qual,timevals


;*****TEMPORARY CODE***********
;APPLY THE ECLIPSE FLAG WITHIN THIS ROUTINE. LATER, THIS WILL BE DONE BY THE MASTER ROUTINE
	;load eclipse times
	; for Keith's stack
	rbsp_load_eclipse_predict,sc,date,$
		local_data_dir='~/data/rbsp/',$
		remote_data_dir='http://themis.ssl.berkeley.edu/data/rbsp/'

	get_data,'rbsp'+sc+'_umbra',data=eu
	get_data,'rbsp'+sc+'_penumbra',data=ep

	eclipset = replicate(0B,n_elements(datatimes))

;*****************************





	;Get flag values
	na_val = -2    ;not applicable value
	fill_val = -1  ;value in flag array that indicates "dunno"
	good_val = 0   ;value for good data
	bad_val = 1    ;value for bad data
	maxvolts = 195. ;Max antenna voltage above which the saturation flag is thrown

	offset = 5   ;position in flag_arr of "v1_saturation" 

	;All the flag values for the entire EFW data set
	flag_arr = replicate(fill_val,n_elements(timevals),20)


;*****TEMPORARY CODE*****
;set the eclipse flag in this program

flag_arr[*,1] = 0.    ;default to no eclipse

;Umbra
if is_struct(eu) then begin
	for bb=0,n_elements(eu.x)-1 do begin
		goo = where((datatimes ge eu.x[bb]) and (datatimes le (eu.x[bb]+eu.y[bb])))
		if goo[0] ne -1 then eclipset[goo] = 1
	endfor
endif
;Penumbra
if is_struct(ep) then begin
	for bb=0,n_elements(ep.x)-1 do begin
		goo = where((datatimes ge ep.x[bb]) and (datatimes le (ep.x[bb]+ep.y[bb])))
		if goo[0] ne -1 then eclipset[goo] = 1
	endfor
endif


flag_arr[*,1] = ceil(interpol(eclipset,datatimes,timevals))
;***********************
	



		flag_arr[*,0] = 0			;global_flag
		flag_arr[*,2] = fill_val	;maneuver
		flag_arr[*,3] = fill_val	;efw_sweep
		flag_arr[*,4] = fill_val	;efw_deploy


		;Set the N/A values. These are not directly relevant to the quality
		;of the spec product
		flag_arr[*,11] = na_val		;Espb_magnitude
		flag_arr[*,12] = na_val		;Eparallel_magnitude
		flag_arr[*,13] = na_val		;magnetic_wake
		flag_arr[*,14:19] = na_val  ;undefined values





;****TEMPORARY CODE******

;Set global flag if eclipse flag is thrown
	goo = where(flag_arr[*,1] eq 1)
	if goo[0] ne -1 then flag_arr[goo,0] = 1
;************************



	
	;Rename the skeleton file
	filename = 'rbsp'+sc+'_efw-l2_spec_'+strjoin(strsplit(date,'-',/extract))+'_'+version+'.cdf'
	file_copy,source_file,folder+filename,/overwrite

	;Open the new skeleton file
	cdfid = cdf_open(folder+filename)
	cdf_control, cdfid, get_var_info=info, variable='epoch'



	cdf_varput,cdfid,'epoch',ep0
	cdf_varput,cdfid,'epoch_qual',epoch_qual			
	cdf_varput,cdfid,'efw_qual',transpose(flag_arr)

	if is_struct(spec0) then cdf_varput,cdfid,'spec'+bins+'_'+chn0,transpose(spec0.y)
	if is_struct(spec1) then cdf_varput,cdfid,'spec'+bins+'_'+chn1,transpose(spec1.y)
	if is_struct(spec2) then cdf_varput,cdfid,'spec'+bins+'_'+chn2,transpose(spec2.y)
	if is_struct(spec3) then cdf_varput,cdfid,'spec'+bins+'_'+chn3,transpose(spec3.y)
	if is_struct(spec4) then cdf_varput,cdfid,'spec'+bins+'_'+chn4,transpose(spec4.y)
	if is_struct(spec5) then cdf_varput,cdfid,'spec'+bins+'_'+chn5,transpose(spec5.y)
	if is_struct(spec6) then cdf_varput,cdfid,'spec'+bins+'_'+chn6,transpose(spec6.y)



	cdf_close, cdfid

	dprint,'END TIME IS: ',systime()


	store_data,tnames(),/delete

;Load the newly filled CDF structure to see if it works
if ~skip_plot then begin
	cdf_leap_second_init
	cdf2tplot,files=folder + filename

	zlim,1,1d-3^2,1d-1^2,1						
	ylim,[1,2,3,4,5,6,7],1,10000,1

	zlim,[1,2,3,4,5,6,7],1d-3^2,1d-1^2,1						


	names = ['global_flag',$
		'eclipse',$
		'maneuver',$
		'efw_sweep',$
		'efw_deploy',$
		'v1_saturation',$
		'v2_saturation',$
		'v3_saturation',$
		'v4_saturation',$
		'v5_saturation',$
		'v6_saturation',$
		'Espb_magnitude',$
		'Eparallel_magnitude',$
		'magnetic_wake',$
		'undefined',$
		'undefined',$
		'undefined',$
		'undefined',$
		'undefined',$
		'undefined']

	split_vec,'efw_qual',suffix='_'+names

	ylim,1,1,10000,1
	zlim,1,0.001,10,1

	tplot,[1,4,5]

endif


end




