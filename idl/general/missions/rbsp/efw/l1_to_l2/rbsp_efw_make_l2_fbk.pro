;+
;
;rbsp_efw_make_l2_fbk
;
;Loads and plots RBSP (Van Allen probes) filterbank data
;used to create the L2 CDF file
;
;note: Source selects for the Filter Bank:
;		0=E12DC
;		1=E34DC
;		2=E56DC
;		3=E12AC
;		4=E34AC
;		5=E56AC
;		6=SCMU
;		7=SCMV
;		8=SCMW
;		9=(V1DC+V2DC+V3DC+V4DC)/4
;		(default is 0)
;
;
;KEY: fbk7 bin width (Hz):
;	0.8-1.5, 3-6, 12-25, 50-100, 200-400, 800-1.6k, 3.2-6.5k
;
;KEY: fbk13 bin width (Hz):
;	0.8-1.5, 1.5-3, 3-6, 6-12, 12-25, 25-50, 50-100, 100-200,
;	200-400, 400-800, 800-1.6k, 1.6k-3.2k, 3.2-6.5k
;
;
;
;
;Written by:
;	Aaron Breneman, UNN, Feb 2013
;		email: awbrenem@gmail.com
;
; History:
;	2013-04-25 - mostly written
;
;
; VERSION:
;	$LastChangedBy: kersten $
;	$LastChangedDate: 2013-09-18 13:41:10 -0700 (Wed, 18 Sep 2013) $
;	$LastChangedRevision: 13062 $
;	$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/l1_to_l2/rbsp_efw_make_l2_fbk.pro $
;
;-

pro rbsp_efw_make_l2_fbk,sc,date,folder=folder

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
	skeleton=rbspx+'/l2/fbk/0000/'+ $
		rbspx+'_efw-l2_fbk_00000000_v'+vstr+'.cdf'
	source_file=file_retrieve(skeleton,_extra=!rbsp_efw)

	; use skeleton from the staging dir until we go live in the main data tree
	;source_file='/Volumes/DataA/user_volumes/kersten/data/rbsp/'+skeleton

	; make sure we have the skeleton CDF
	source_file=file_search(source_file,count=found) ; looking for single file, so count will return 0 or 1
	if ~found then begin
		dprint,'Could not find fbk v'+vstr+' skeleton CDF, returning.'
		return
	endif
	; fix single element source file array
	source_file=source_file[0]

	;Load some data
	timespan,date

	;Load the filterbank data
	rbsp_load_efw_fbk,probe=sc,type='calibrated'
	get_data,rbspx+'_efw_fbk_13_fb1_pk',data=fbk13_pk_fb1,dlimits=dlim13_fb1
	get_data,rbspx+'_efw_fbk_13_fb2_pk',data=fbk13_pk_fb2,dlimits=dlim13_fb2
	get_data,rbspx+'_efw_fbk_7_fb1_pk',data=fbk7_pk_fb1,dlimits=dlim7_fb1
	get_data,rbspx+'_efw_fbk_7_fb2_pk',data=fbk7_pk_fb2,dlimits=dlim7_fb2

	get_data,rbspx+'_efw_fbk_13_fb1_av',data=fbk13_av_fb1
	get_data,rbspx+'_efw_fbk_13_fb2_av',data=fbk13_av_fb2
	get_data,rbspx+'_efw_fbk_7_fb1_av',data=fbk7_av_fb1
	get_data,rbspx+'_efw_fbk_7_fb2_av',data=fbk7_av_fb2





	;Determine the source of the data

	if is_struct(dlim13_fb1) then source13_fb1 = dlim13_fb1.data_att.channel else source13_fb1 = ''
	if is_struct(dlim13_fb2) then source13_fb2 = dlim13_fb2.data_att.channel else source13_fb2 = ''
	if is_struct(dlim7_fb1) then source7_fb1 = dlim7_fb1.data_att.channel else source7_fb1 = ''
	if is_struct(dlim7_fb2) then source7_fb2 = dlim7_fb2.data_att.channel else source7_fb2 = ''




	;Get the time structure for the flag values. These are not necessarily at the cadence
	;of physical data.
	epoch_flag_times,date,5,epoch_qual,timevals



	;Make the time string

	if is_struct(fbk13_pk_fb1) then times13 = fbk13_pk_fb1.x
	if is_struct(fbk7_pk_fb1) then times7 = fbk7_pk_fb1.x


	if is_struct(fbk13_pk_fb1) then epoch_fbk13 = tplot_time_to_epoch(times13,/epoch16)
	if is_struct(fbk7_pk_fb1) then epoch_fbk7 = tplot_time_to_epoch(times7,/epoch16)


	if is_struct(fbk13_pk_fb1) then datatimes = fbk13_pk_fb1.x
	if is_struct(fbk7_pk_fb1)  then datatimes = fbk7_pk_fb1.x


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
;		flag_arr[*,1] = -1    ;default to no eclipse
		flag_arr[*,2] = fill_val	;maneuver
		flag_arr[*,3] = fill_val	;efw_sweep
		flag_arr[*,4] = fill_val	;efw_deploy


		;Set the N/A values. These are not directly relevant to the quality
		;of the FBK product
		flag_arr[*,11] = na_val	;Espb_magnitude
		flag_arr[*,12] = na_val	;Eparallel_magnitude
		flag_arr[*,13] = na_val	;magnetic_wake
		flag_arr[*,14:19] = na_val  ;undefined values





;****TEMPORARY CODE******

;Set global flag if eclipse flag is thrown
	goo = where(flag_arr[*,1] eq 1)
	if goo[0] ne -1 then flag_arr[goo,0] = 1
;************************







	;Rename the skeleton file
	filename = 'rbsp'+sc+'_efw-l2_fbk_'+strjoin(strsplit(date,'-',/extract))+'_'+version+'.cdf'
	file_copy,source_file,folder+filename,/overwrite



	;Eliminate structures with zero data in them. This prevents the overwriting (below) of
	;good data with bad data

	if is_struct(fbk7_pk_fb1) then if total(fbk7_pk_fb1.y,/nan) eq 0. then fbk7_pk_fb1 = 0.
	if is_struct(fbk7_av_fb1) then if total(fbk7_av_fb1.y,/nan) eq 0. then fbk7_av_fb1 = 0.
	if is_struct(fbk7_pk_fb2) then if total(fbk7_pk_fb2.y,/nan) eq 0. then fbk7_pk_fb2 = 0.
	if is_struct(fbk7_av_fb2) then if total(fbk7_av_fb2.y,/nan) eq 0. then fbk7_av_fb2 = 0.

	if is_struct(fbk13_pk_fb1) then if total(fbk13_pk_fb1.y,/nan) eq 0. then fbk13_pk_fb1 = 0.
	if is_struct(fbk13_av_fb1) then if total(fbk13_av_fb1.y,/nan) eq 0. then fbk13_av_fb1 = 0.
	if is_struct(fbk13_pk_fb2) then if total(fbk13_pk_fb2.y,/nan) eq 0. then fbk13_pk_fb2 = 0.
	if is_struct(fbk13_av_fb2) then if total(fbk13_av_fb2.y,/nan) eq 0. then fbk13_av_fb2 = 0.





	cdfid = cdf_open(folder+filename)
	cdf_control, cdfid, get_var_info=info, variable='epoch'




;NEED TO AS BONNELL ABOUT THE OFFICIAL NAMES FOR THESE SOURCES THAT WILL SHOW UP
;FROM THE LOAD_FBK ROUTINE


	if is_struct(fbk7_pk_fb1) then begin
	
		cdf_varput,cdfid,'epoch',epoch_fbk7
		cdf_varput,cdfid,'epoch_qual',epoch_qual
		cdf_varput,cdfid,'efw_qual',transpose(flag_arr)
		if source7_fb1 eq 'E12DC' then cdf_varput,cdfid,'fbk7_e12dc_pk',transpose(fbk7_pk_fb1.y)
		if source7_fb1 eq 'E12AC' then cdf_varput,cdfid,'fbk7_e12ac_pk',transpose(fbk7_pk_fb1.y)
		if source7_fb1 eq 'E34DC' then cdf_varput,cdfid,'fbk7_e34dc_pk',transpose(fbk7_pk_fb1.y)
		if source7_fb1 eq 'E34AC' then cdf_varput,cdfid,'fbk7_e34ac_pk',transpose(fbk7_pk_fb1.y)
		if source7_fb1 eq 'E56DC' then cdf_varput,cdfid,'fbk7_e56dc_pk',transpose(fbk7_pk_fb1.y)
		if source7_fb1 eq 'E56AC' then cdf_varput,cdfid,'fbk7_e56ac_pk',transpose(fbk7_pk_fb1.y)
		if source7_fb1 eq 'SCMU' then cdf_varput,cdfid,'fbk7_scmu_pk',transpose(fbk7_pk_fb1.y)
		if source7_fb1 eq 'SCMV' then cdf_varput,cdfid,'fbk7_scmv_pk',transpose(fbk7_pk_fb1.y)
		if source7_fb1 eq 'SCMW' then cdf_varput,cdfid,'fbk7_scmw_pk',transpose(fbk7_pk_fb1.y)
		if source7_fb1 eq 'V1V2V3V4_AVG_AC' then cdf_varput,cdfid,'fbk7_v1v1v3v4_avg_ac_pk',transpose(fbk7_pk_fb1.y)

	endif



	if is_struct(fbk7_av_fb1) then begin
	
		cdf_varput,cdfid,'epoch',epoch_fbk7
		cdf_varput,cdfid,'epoch_qual',epoch_qual
		cdf_varput,cdfid,'efw_qual',transpose(flag_arr)
		if source7_fb1 eq 'E12DC' then cdf_varput,cdfid,'fbk7_e12dc_av',transpose(fbk7_av_fb1.y)
		if source7_fb1 eq 'E12AC' then cdf_varput,cdfid,'fbk7_e12ac_av',transpose(fbk7_av_fb1.y)
		if source7_fb1 eq 'E34DC' then cdf_varput,cdfid,'fbk7_e34dc_av',transpose(fbk7_av_fb1.y)
		if source7_fb1 eq 'E34AC' then cdf_varput,cdfid,'fbk7_e34ac_av',transpose(fbk7_av_fb1.y)
		if source7_fb1 eq 'E56DC' then cdf_varput,cdfid,'fbk7_e56dc_av',transpose(fbk7_av_fb1.y)
		if source7_fb1 eq 'E56AC' then cdf_varput,cdfid,'fbk7_e56ac_av',transpose(fbk7_av_fb1.y)
		if source7_fb1 eq 'SCMU' then cdf_varput,cdfid,'fbk7_scmu_av',transpose(fbk7_av_fb1.y)
		if source7_fb1 eq 'SCMV' then cdf_varput,cdfid,'fbk7_scmv_av',transpose(fbk7_av_fb1.y)
		if source7_fb1 eq 'SCMW' then cdf_varput,cdfid,'fbk7_scmw_av',transpose(fbk7_av_fb1.y)
		if source7_fb1 eq 'V1V2V3V4_AVG_AC' then cdf_varput,cdfid,'fbk7_v1v1v3v4_avg_ac_av',transpose(fbk7_av_fb1.y)

	endif





	if is_struct(fbk7_pk_fb2) then begin
	
		cdf_varput,cdfid,'epoch',epoch_fbk7
		cdf_varput,cdfid,'epoch_qual',epoch_qual
		cdf_varput,cdfid,'efw_qual',transpose(flag_arr)
		if source7_fb2 eq 'E12DC' then cdf_varput,cdfid,'fbk7_e12dc_pk',transpose(fbk7_pk_fb2.y)
		if source7_fb2 eq 'E12AC' then cdf_varput,cdfid,'fbk7_e12ac_pk',transpose(fbk7_pk_fb2.y)
		if source7_fb2 eq 'E34DC' then cdf_varput,cdfid,'fbk7_e34dc_pk',transpose(fbk7_pk_fb2.y)
		if source7_fb2 eq 'E34AC' then cdf_varput,cdfid,'fbk7_e34ac_pk',transpose(fbk7_pk_fb2.y)
		if source7_fb2 eq 'E56DC' then cdf_varput,cdfid,'fbk7_e56dc_pk',transpose(fbk7_pk_fb2.y)
		if source7_fb2 eq 'E56AC' then cdf_varput,cdfid,'fbk7_e56ac_pk',transpose(fbk7_pk_fb2.y)
		if source7_fb2 eq 'SCMU' then cdf_varput,cdfid,'fbk7_scmu_pk',transpose(fbk7_pk_fb2.y)
		if source7_fb2 eq 'SCMV' then cdf_varput,cdfid,'fbk7_scmv_pk',transpose(fbk7_pk_fb2.y)
		if source7_fb2 eq 'SCMW' then cdf_varput,cdfid,'fbk7_scmw_pk',transpose(fbk7_pk_fb2.y)
		if source7_fb2 eq 'V1V2V3V4_AVG_AC' then cdf_varput,cdfid,'fbk7_v1v1v3v4_avg_ac_pk',transpose(fbk7_pk_fb2.y)

	endif


	if is_struct(fbk7_av_fb2) then begin
	
		cdf_varput,cdfid,'epoch',epoch_fbk7
		cdf_varput,cdfid,'epoch_qual',epoch_qual
		cdf_varput,cdfid,'efw_qual',transpose(flag_arr)
		if source7_fb2 eq 'E12DC' then cdf_varput,cdfid,'fbk7_e12dc_av',transpose(fbk7_av_fb2.y)
		if source7_fb2 eq 'E12AC' then cdf_varput,cdfid,'fbk7_e12ac_av',transpose(fbk7_av_fb2.y)
		if source7_fb2 eq 'E34DC' then cdf_varput,cdfid,'fbk7_e34dc_av',transpose(fbk7_av_fb2.y)
		if source7_fb2 eq 'E34AC' then cdf_varput,cdfid,'fbk7_e34ac_av',transpose(fbk7_av_fb2.y)
		if source7_fb2 eq 'E56DC' then cdf_varput,cdfid,'fbk7_e56dc_av',transpose(fbk7_av_fb2.y)
		if source7_fb2 eq 'E56AC' then cdf_varput,cdfid,'fbk7_e56ac_av',transpose(fbk7_av_fb2.y)
		if source7_fb2 eq 'SCMU' then cdf_varput,cdfid,'fbk7_scmu_av',transpose(fbk7_av_fb2.y)
		if source7_fb2 eq 'SCMV' then cdf_varput,cdfid,'fbk7_scmv_av',transpose(fbk7_av_fb2.y)
		if source7_fb2 eq 'SCMW' then cdf_varput,cdfid,'fbk7_scmw_av',transpose(fbk7_av_fb2.y)
		if source7_fb2 eq 'V1V2V3V4_AVG_AC' then cdf_varput,cdfid,'fbk7_v1v1v3v4_avg_ac_av',transpose(fbk7_av_fb2.y)

	endif




	if is_struct(fbk13_pk_fb1) then begin
	
		cdf_varput,cdfid,'epoch',epoch_fbk13
		cdf_varput,cdfid,'epoch_qual',epoch_qual
		cdf_varput,cdfid,'efw_qual',transpose(flag_arr)
		if source13_fb1 eq 'E12DC' then cdf_varput,cdfid,'fbk13_e12dc_pk',transpose(fbk13_pk_fb1.y)
		if source13_fb1 eq 'E12AC' then cdf_varput,cdfid,'fbk13_e12ac_pk',transpose(fbk13_pk_fb1.y)
		if source13_fb1 eq 'E34DC' then cdf_varput,cdfid,'fbk13_e34dc_pk',transpose(fbk13_pk_fb1.y)
		if source13_fb1 eq 'E34AC' then cdf_varput,cdfid,'fbk13_e34ac_pk',transpose(fbk13_pk_fb1.y)
		if source13_fb1 eq 'E56DC' then cdf_varput,cdfid,'fbk13_e56dc_pk',transpose(fbk13_pk_fb1.y)
		if source13_fb1 eq 'E56AC' then cdf_varput,cdfid,'fbk13_e56ac_pk',transpose(fbk13_pk_fb1.y)
		if source13_fb1 eq 'EparDC' then cdf_varput,cdfid,'fbk13_epardc_pk',transpose(fbk13_pk_fb1.y)
		if source13_fb1 eq 'Eperp1DC' then cdf_varput,cdfid,'fbk13_eperp1dc_pk',transpose(fbk13_pk_fb1.y)
		if source13_fb1 eq 'EparAC' then cdf_varput,cdfid,'fbk13_eparac_pk',transpose(fbk13_pk_fb1.y)
		if source13_fb1 eq 'Eperp1AC' then cdf_varput,cdfid,'fbk13_eperp1ac_pk',transpose(fbk13_pk_fb1.y)
		if source13_fb1 eq 'V1AC' then cdf_varput,cdfid,'fbk13_v1ac_pk',transpose(fbk13_pk_fb1.y)
		if source13_fb1 eq 'V2AC' then cdf_varput,cdfid,'fbk13_v2ac_pk',transpose(fbk13_pk_fb1.y)
		if source13_fb1 eq 'V3AC' then cdf_varput,cdfid,'fbk13_v3ac_pk',transpose(fbk13_pk_fb1.y)
		if source13_fb1 eq 'V4AC' then cdf_varput,cdfid,'fbk13_v4ac_pk',transpose(fbk13_pk_fb1.y)
		if source13_fb1 eq 'V5AC' then cdf_varput,cdfid,'fbk13_v5ac_pk',transpose(fbk13_pk_fb1.y)
		if source13_fb1 eq 'V6AC' then cdf_varput,cdfid,'fbk13_v6ac_pk',transpose(fbk13_pk_fb1.y)
		if source13_fb1 eq 'SCMU' then cdf_varput,cdfid,'fbk13_scmu_pk',transpose(fbk13_pk_fb1.y)
		if source13_fb1 eq 'SCMV' then cdf_varput,cdfid,'fbk13_scmv_pk',transpose(fbk13_pk_fb1.y)
		if source13_fb1 eq 'SCMW' then cdf_varput,cdfid,'fbk13_scmw_pk',transpose(fbk13_pk_fb1.y)
		if source13_fb1 eq 'SCMpar' then cdf_varput,cdfid,'fbk13_scmpar_pk',transpose(fbk13_pk_fb1.y)
		if source13_fb1 eq 'SCMperp1' then cdf_varput,cdfid,'fbk13_scmperp1_pk',transpose(fbk13_pk_fb1.y)
		if source13_fb1 eq 'V1V2V3V4_AVG_AC' then cdf_varput,cdfid,'fbk13_v1v1v3v4_avg_ac_pk',transpose(fbk13_pk_fb1.y)
		if source13_fb1 eq 'Eperp2DC' then cdf_varput,cdfid,'fbk13_eperp2dc_pk',transpose(fbk13_pk_fb1.y)
		if source13_fb1 eq 'Eperp2AC' then cdf_varput,cdfid,'fbk13_eperp2ac_pk',transpose(fbk13_pk_fb1.y)
		if source13_fb1 eq 'SCMperp2' then cdf_varput,cdfid,'fbk13_scmperp2_pk',transpose(fbk13_pk_fb1.y)

	endif


	if is_struct(fbk13_av_fb1) then begin
	
		cdf_varput,cdfid,'epoch',epoch_fbk13
		cdf_varput,cdfid,'epoch_qual',epoch_qual
		cdf_varput,cdfid,'efw_qual',transpose(flag_arr)
		if source13_fb1 eq 'E12DC' then cdf_varput,cdfid,'fbk13_e12dc_av',transpose(fbk13_av_fb1.y)
		if source13_fb1 eq 'E12AC' then cdf_varput,cdfid,'fbk13_e12ac_av',transpose(fbk13_av_fb1.y)
		if source13_fb1 eq 'E34DC' then cdf_varput,cdfid,'fbk13_e34dc_av',transpose(fbk13_av_fb1.y)
		if source13_fb1 eq 'E34AC' then cdf_varput,cdfid,'fbk13_e34ac_av',transpose(fbk13_av_fb1.y)
		if source13_fb1 eq 'E56DC' then cdf_varput,cdfid,'fbk13_e56dc_av',transpose(fbk13_av_fb1.y)
		if source13_fb1 eq 'E56AC' then cdf_varput,cdfid,'fbk13_e56ac_av',transpose(fbk13_av_fb1.y)
		if source13_fb1 eq 'EparDC' then cdf_varput,cdfid,'fbk13_epardc_av',transpose(fbk13_av_fb1.y)
		if source13_fb1 eq 'Eperp1DC' then cdf_varput,cdfid,'fbk13_eperp1dc_av',transpose(fbk13_av_fb1.y)
		if source13_fb1 eq 'EparAC' then cdf_varput,cdfid,'fbk13_eparac_av',transpose(fbk13_av_fb1.y)
		if source13_fb1 eq 'Eperp1AC' then cdf_varput,cdfid,'fbk13_eperp1ac_av',transpose(fbk13_av_fb1.y)
		if source13_fb1 eq 'V1AC' then cdf_varput,cdfid,'fbk13_v1ac_av',transpose(fbk13_av_fb1.y)
		if source13_fb1 eq 'V2AC' then cdf_varput,cdfid,'fbk13_v2ac_av',transpose(fbk13_av_fb1.y)
		if source13_fb1 eq 'V3AC' then cdf_varput,cdfid,'fbk13_v3ac_av',transpose(fbk13_av_fb1.y)
		if source13_fb1 eq 'V4AC' then cdf_varput,cdfid,'fbk13_v4ac_av',transpose(fbk13_av_fb1.y)
		if source13_fb1 eq 'V5AC' then cdf_varput,cdfid,'fbk13_v5ac_av',transpose(fbk13_av_fb1.y)
		if source13_fb1 eq 'V6AC' then cdf_varput,cdfid,'fbk13_v6ac_av',transpose(fbk13_av_fb1.y)
		if source13_fb1 eq 'SCMU' then cdf_varput,cdfid,'fbk13_scmu_av',transpose(fbk13_av_fb1.y)
		if source13_fb1 eq 'SCMV' then cdf_varput,cdfid,'fbk13_scmv_av',transpose(fbk13_av_fb1.y)
		if source13_fb1 eq 'SCMW' then cdf_varput,cdfid,'fbk13_scmw_av',transpose(fbk13_av_fb1.y)
		if source13_fb1 eq 'SCMpar' then cdf_varput,cdfid,'fbk13_scmpar_av',transpose(fbk13_av_fb1.y)
		if source13_fb1 eq 'SCMperp1' then cdf_varput,cdfid,'fbk13_scmperp1_av',transpose(fbk13_av_fb1.y)
		if source13_fb1 eq 'V1V2V3V4_AVG_AC' then cdf_varput,cdfid,'fbk13_v1v1v3v4_avg_ac_av',transpose(fbk13_av_fb1.y)
		if source13_fb1 eq 'Eperp2DC' then cdf_varput,cdfid,'fbk13_eperp2dc_av',transpose(fbk13_av_fb1.y)
		if source13_fb1 eq 'Eperp2AC' then cdf_varput,cdfid,'fbk13_eperp2ac_av',transpose(fbk13_av_fb1.y)
		if source13_fb1 eq 'SCMperp2' then cdf_varput,cdfid,'fbk13_scmperp2_av',transpose(fbk13_av_fb1.y)

	endif




	if is_struct(fbk13_pk_fb2) then begin
	
		cdf_varput,cdfid,'epoch',epoch_fbk13
		cdf_varput,cdfid,'epoch_qual',epoch_qual
		cdf_varput,cdfid,'efw_qual',transpose(flag_arr)
		if source13_fb2 eq 'E12DC' then cdf_varput,cdfid,'fbk13_e12dc_pk',transpose(fbk13_pk_fb2.y)
		if source13_fb2 eq 'E12AC' then cdf_varput,cdfid,'fbk13_e12ac_pk',transpose(fbk13_pk_fb2.y)
		if source13_fb2 eq 'E34DC' then cdf_varput,cdfid,'fbk13_e34dc_pk',transpose(fbk13_pk_fb2.y)
		if source13_fb2 eq 'E34AC' then cdf_varput,cdfid,'fbk13_e34ac_pk',transpose(fbk13_pk_fb2.y)
		if source13_fb2 eq 'E56DC' then cdf_varput,cdfid,'fbk13_e56dc_pk',transpose(fbk13_pk_fb2.y)
		if source13_fb2 eq 'E56AC' then cdf_varput,cdfid,'fbk13_e56ac_pk',transpose(fbk13_pk_fb2.y)
		if source13_fb2 eq 'EparDC' then cdf_varput,cdfid,'fbk13_epardc_pk',transpose(fbk13_pk_fb2.y)
		if source13_fb2 eq 'Eperp1DC' then cdf_varput,cdfid,'fbk13_eperp1dc_pk',transpose(fbk13_pk_fb2.y)
		if source13_fb2 eq 'EparAC' then cdf_varput,cdfid,'fbk13_eparac_pk',transpose(fbk13_pk_fb2.y)
		if source13_fb2 eq 'Eperp1AC' then cdf_varput,cdfid,'fbk13_eperp1ac_pk',transpose(fbk13_pk_fb2.y)
		if source13_fb2 eq 'V1AC' then cdf_varput,cdfid,'fbk13_v1ac_pk',transpose(fbk13_pk_fb2.y)
		if source13_fb2 eq 'V2AC' then cdf_varput,cdfid,'fbk13_v2ac_pk',transpose(fbk13_pk_fb2.y)
		if source13_fb2 eq 'V3AC' then cdf_varput,cdfid,'fbk13_v3ac_pk',transpose(fbk13_pk_fb2.y)
		if source13_fb2 eq 'V4AC' then cdf_varput,cdfid,'fbk13_v4ac_pk',transpose(fbk13_pk_fb2.y)
		if source13_fb2 eq 'V5AC' then cdf_varput,cdfid,'fbk13_v5ac_pk',transpose(fbk13_pk_fb2.y)
		if source13_fb2 eq 'V6AC' then cdf_varput,cdfid,'fbk13_v6ac_pk',transpose(fbk13_pk_fb2.y)
		if source13_fb2 eq 'SCMU' then cdf_varput,cdfid,'fbk13_scmu_pk',transpose(fbk13_pk_fb2.y)
		if source13_fb2 eq 'SCMV' then cdf_varput,cdfid,'fbk13_scmv_pk',transpose(fbk13_pk_fb2.y)
		if source13_fb2 eq 'SCMW' then cdf_varput,cdfid,'fbk13_scmw_pk',transpose(fbk13_pk_fb2.y)
		if source13_fb2 eq 'SCMpar' then cdf_varput,cdfid,'fbk13_scmpar_pk',transpose(fbk13_pk_fb2.y)
		if source13_fb2 eq 'SCMperp1' then cdf_varput,cdfid,'fbk13_scmperp1_pk',transpose(fbk13_pk_fb2.y)
		if source13_fb2 eq 'V1V2V3V4_AVG_AC' then cdf_varput,cdfid,'fbk13_v1v1v3v4_avg_ac_pk',transpose(fbk13_pk_fb2.y)
		if source13_fb2 eq 'Eperp2DC' then cdf_varput,cdfid,'fbk13_eperp2dc_pk',transpose(fbk13_pk_fb2.y)
		if source13_fb2 eq 'Eperp2AC' then cdf_varput,cdfid,'fbk13_eperp2ac_pk',transpose(fbk13_pk_fb2.y)
		if source13_fb2 eq 'SCMperp2' then cdf_varput,cdfid,'fbk13_scmperp2_pk',transpose(fbk13_pk_fb2.y)

	endif




	if is_struct(fbk13_av_fb2) then begin
	
		cdf_varput,cdfid,'epoch',epoch_fbk13
		cdf_varput,cdfid,'epoch_qual',epoch_qual
		cdf_varput,cdfid,'efw_qual',transpose(flag_arr)
		if source13_fb2 eq 'E12DC' then cdf_varput,cdfid,'fbk13_e12dc_av',transpose(fbk13_av_fb2.y)
		if source13_fb2 eq 'E12AC' then cdf_varput,cdfid,'fbk13_e12ac_av',transpose(fbk13_av_fb2.y)
		if source13_fb2 eq 'E34DC' then cdf_varput,cdfid,'fbk13_e34dc_av',transpose(fbk13_av_fb2.y)
		if source13_fb2 eq 'E34AC' then cdf_varput,cdfid,'fbk13_e34ac_av',transpose(fbk13_av_fb2.y)
		if source13_fb2 eq 'E56DC' then cdf_varput,cdfid,'fbk13_e56dc_av',transpose(fbk13_av_fb2.y)
		if source13_fb2 eq 'E56AC' then cdf_varput,cdfid,'fbk13_e56ac_av',transpose(fbk13_av_fb2.y)
		if source13_fb2 eq 'EparDC' then cdf_varput,cdfid,'fbk13_epardc_av',transpose(fbk13_av_fb2.y)
		if source13_fb2 eq 'Eperp1DC' then cdf_varput,cdfid,'fbk13_eperp1dc_av',transpose(fbk13_av_fb2.y)
		if source13_fb2 eq 'EparAC' then cdf_varput,cdfid,'fbk13_eparac_av',transpose(fbk13_av_fb2.y)
		if source13_fb2 eq 'Eperp1AC' then cdf_varput,cdfid,'fbk13_eperp1ac_av',transpose(fbk13_av_fb2.y)
		if source13_fb2 eq 'V1AC' then cdf_varput,cdfid,'fbk13_v1ac_av',transpose(fbk13_av_fb2.y)
		if source13_fb2 eq 'V2AC' then cdf_varput,cdfid,'fbk13_v2ac_av',transpose(fbk13_av_fb2.y)
		if source13_fb2 eq 'V3AC' then cdf_varput,cdfid,'fbk13_v3ac_av',transpose(fbk13_av_fb2.y)
		if source13_fb2 eq 'V4AC' then cdf_varput,cdfid,'fbk13_v4ac_av',transpose(fbk13_av_fb2.y)
		if source13_fb2 eq 'V5AC' then cdf_varput,cdfid,'fbk13_v5ac_av',transpose(fbk13_av_fb2.y)
		if source13_fb2 eq 'V6AC' then cdf_varput,cdfid,'fbk13_v6ac_av',transpose(fbk13_av_fb2.y)
		if source13_fb2 eq 'SCMU' then cdf_varput,cdfid,'fbk13_scmu_av',transpose(fbk13_av_fb2.y)
		if source13_fb2 eq 'SCMV' then cdf_varput,cdfid,'fbk13_scmv_av',transpose(fbk13_av_fb2.y)
		if source13_fb2 eq 'SCMW' then cdf_varput,cdfid,'fbk13_scmw_av',transpose(fbk13_av_fb2.y)
		if source13_fb2 eq 'SCMpar' then cdf_varput,cdfid,'fbk13_scmpar_av',transpose(fbk13_av_fb2.y)
		if source13_fb2 eq 'SCMperp1' then cdf_varput,cdfid,'fbk13_scmperp1_av',transpose(fbk13_av_fb2.y)
		if source13_fb2 eq 'V1V2V3V4_AVG_AC' then cdf_varput,cdfid,'fbk13_v1v1v3v4_avg_ac_av',transpose(fbk13_av_fb2.y)
		if source13_fb2 eq 'Eperp2DC' then cdf_varput,cdfid,'fbk13_eperp2dc_av',transpose(fbk13_av_fb2.y)
		if source13_fb2 eq 'Eperp2AC' then cdf_varput,cdfid,'fbk13_eperp2ac_av',transpose(fbk13_av_fb2.y)
		if source13_fb2 eq 'SCMperp2' then cdf_varput,cdfid,'fbk13_scmperp2_av',transpose(fbk13_av_fb2.y)

	endif



	cdf_close, cdfid

	dprint,'END TIME IS: ',systime()

	store_data,tnames(),/delete



	;Load the newly filled CDF structure to see if it works
	if ~skip_plot then begin
		cdf_leap_second_init
		cdf2tplot,files=folder + filename


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





