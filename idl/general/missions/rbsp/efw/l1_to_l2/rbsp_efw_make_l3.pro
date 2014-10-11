;+
; NAME: rbsp_efw_make_l3
; SYNTAX: 
; PURPOSE: Create the EFW L3 CDF file 
; INPUT: 
; OUTPUT: 
; KEYWORDS: type -> hidden - version for creating hidden file with EMFISIS data
;                -> survey - version for long-duration survey plots
;                -> if not set defaults to standard L3 version
;           script -> set if running from script. The date is read in
;           differently if so
; HISTORY: Created by Aaron W Breneman, May 2014
; VERSION: 
;   $LastChangedBy: aaronbreneman $
;   $LastChangedDate: 2014-10-09 14:48:00 -0700 (Thu, 09 Oct 2014) $
;   $LastChangedRevision: 15965 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/l1_to_l2/rbsp_efw_make_l3.pro $
;-



pro rbsp_efw_make_l3,sc,date,folder=folder,version=version,type=type,testing=testing

  print,date

  ;KEEP!!!!!! Necessary when running scripts
  date = time_string(double(date),prec=-3)

;;   print,'**SCRIPT****  ',keyword_set(script),'   ******'
;;   print,date
;;   print,'**************************************************'
;;   print,'**************************************************'
;;   print,'**************************************************'
;;   print,'**************************************************'
;;   print,'**************************************************'


;; stop


  rbsp_efw_init
  if ~keyword_set(type) then type = 'L3'  
  skip_plot = 1                 ;set to skip restoration of cdf file and test plotting at end of program


  starttime=systime(1)
  dprint,'BEGIN TIME IS ',systime()


  if n_elements(version) eq 0 then version = 1
  vstr = string(version, format='(I02)')
                                ;version = 'v'+vstr

;__________________________________________________
;Get skeleton file
;__________________________________________________
                                
  vskeleton='01'   ;skeleton version



  sc=strlowcase(sc)
  if sc ne 'a' and sc ne 'b' then begin
     dprint,'Invalid spacecraft: '+sc+', returning.'
     return
  endif
  rbspx = 'rbsp'+sc



  if ~keyword_set(folder) then folder = '~/Desktop/code/Aaron/RBSP/TDAS_trunk_svn/general/missions/rbsp/efw/l1_to_l2/'
                                ; make sure we have the trailing slash on folder
  if strmid(folder,strlen(folder)-1,1) ne path_sep() then folder=folder+path_sep()
  file_mkdir,folder

                                ; Grab the skeleton file.
  skeleton=rbspx+'_efw-l3_00000000_v'+vskeleton+'.cdf'



                                ; Use local skeleton
  source_file='/Volumes/UserA/user_homes/kersten/RBSP_l2/'+skeleton
  if keyword_set(testing) then begin
     source_file='~/Desktop/code/Aaron/RBSP/TDAS_trunk_svn/general/missions/rbsp/efw/l1_to_l2/' + skeleton
  endif


                                ; make sure we have the skeleton CDF
  source_file=file_search(source_file,count=found) ; looking for single file, so count will return 0 or 1
  if ~found then begin
     dprint,'Could not find l3 v'+vskeleton+' skeleton CDF, returning.'
     return
  endif
                                ; fix single element source file array
  source_file=source_file[0]

;__________________________________________________



                                ;Get the time structure for the flag values
  spinperiod = 11.8
  epoch_flag_times,date,spinperiod,epochvals,timevals

  store_data,tnames(),/delete

  timespan,date

  rbsp_load_spice_kernels

  ;Load ECT's magnetic ephemeris
  rbsp_read_ect_mag_ephem,sc

  ;Load both the spinfit data and also the E*B=0 version
  rbsp_efw_edotb_to_zero_crib,date,sc,/no_spice_load,/noplot,suffix='edotb'



;	;This data will stay as despun 32 S/s 
;	if keyword_set(hires) then begin
;	
;		;Load the vxb subtracted data. If there isn't any vxb subtracted data
;		;then grab the regular Esvy MGSE data
;		rbsp_efw_vxb_subtract_crib,sc,/no_spice_load,/noplot;,/ql
;
;
;		get_data,rbspx+'_efw_esvy_mgse_vxb_removed',data=esvy_mgse
;		if is_struct(esvy_mgse) then esvy_mgse.y[*,0] = !values.f_nan
;
;		if ~is_struct(esvy_mgse) then begin
;			get_data,rbspx+'_efw_esvy_mgse',data=esvy_mgse
;		endif	
;	
;		epoch_esvy = tplot_time_to_epoch(esvy_mgse.x,/epoch16)
;
;	endif





  ;--------------------------------------------------
  ;Load other crap

  rbsp_load_efw_waveform,probe=sc,type='calibrated',datatype='vsvy',/noclean
  rbsp_downsample,'rbsp'+sc+'_efw_vsvy',1/spinperiod,/nochange	

  split_vec, 'rbsp?_efw_vsvy', suffix='_V'+['1','2','3','4','5','6']
  get_data,'rbsp'+sc+'_efw_vsvy',data=vsvy

  


;**************************************************
;get the master times
;**************************************************

  get_data,'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_spinfit',data=goo
  times = goo.x
  epoch = tplot_time_to_epoch(times,/epoch16)

;**************************************************
;save all spinfit resolution Efield quantities
;**************************************************

                                ;Spinfit with corotation field
  if type eq 'L3' then goo.y[*,0] = -1.0E31
  spinfit_vxb = goo.y
                                ;Spinfit with corotation field and E*B=0
  get_data,'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_spinfit_edotb',data=tmp
  if type eq 'L3' then tmp.y[*,0] = -1.0E31
  spinfit_vxb_edotb = tmp.y
                                ;Spinfit without corotation field
  get_data,'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_coro_removed_spinfit',data=tmp
  if type eq 'L3' then tmp.y[*,0] = -1.0E31
  spinfit_vxb_coro = tmp.y
                                ;Spinfit without corotation field and E*B=0
  get_data,'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_coro_removed_spinfit_edotb',data=tmp
  if type eq 'L3' then tmp.y[*,0] = -1.0E31
  spinfit_vxb_coro_edotb = tmp.y





;  tinterpol_mxn,'angles',times
  get_data,'angles',data=angles





;Interpolate the flag value times to the data times
  epochvals = interpol(epochvals,timevals,times)
  timevals = interpol(timevals,timevals,times)





;--------------------------------------
;SUBTRACT OFF MODEL FIELD
;--------------------------------------

  model = 't89'
  
;******************************
;CHANGE THIS TO USE EMFISIS L3
;******************************
  rbsp_efw_DCfield_removal_crib,sc,/no_spice_load,/noplot,model=model ;,/ql
  


;--------------------------
;Density proxy
;--------------------------

  get_data,rbspx +'_efw_vsvy_V1',data=d1
  get_data,rbspx +'_efw_vsvy_V2',data=d2
  get_data,rbspx +'_efw_vsvy_V3',data=d3
  get_data,rbspx +'_efw_vsvy_V4',data=d4
  get_data,rbspx +'_efw_vsvy_V5',data=d5
  get_data,rbspx +'_efw_vsvy_V6',data=d6


;interpolate to "times"

  v1 = interpol(d1.y,d1.x,times)
  v2 = interpol(d2.y,d2.x,times)
  v3 = interpol(d3.y,d3.x,times)
  v4 = interpol(d4.y,d4.x,times)
  v5 = interpol(d5.y,d5.x,times)
  v6 = interpol(d6.y,d6.x,times)

  
  datt = d1
  sum12 = (v1 + v2)/2.	
  sum34 = (v3 + v4)/2.	
  sum56 = (v5 + v6)/2.	

  sum56[*] = -1.0E31


  

;*****TEMPORARY CODE***********
;APPLY THE ECLIPSE FLAG WITHIN THIS ROUTINE. LATER, THIS WILL BE DONE BY THE MASTER ROUTINE
                                ;load eclipse times
                                ; for Keith's stack
  rbsp_load_eclipse_predict,sc,date,$
                            local_data_dir='~/data/rbsp/',$
                            remote_data_dir='http://themis.ssl.berkeley.edu/data/rbsp/'


  get_data,rbspx + '_umbra',data=eu
  get_data,rbspx + '_penumbra',data=ep

  eclipset = replicate(0B,n_elements(vsvy.x))

;*****************************


  store_data,'sc_potential',data={x:times,y:sum12}
  rbsp_efw_density_fit_from_uh_line,'sc_potential',newname='rbsp'+sc+'_density'
;  tinterpol_mxn,'rbsp'+sc+'_density',times

  get_data,'rbsp'+sc+'_density',data=density
  density = density.y  
  goo = where(density ge 1d4)
  if goo[0] ne -1 then density[goo] = -1.e31



;------------------------------------------------
;ADD BIAS SWEEPS TO FLAG VALUES
;------------------------------------------------
  
;Load the HSK data to flag the bias sweeps
  rbsp_load_efw_hsk,probe=sc,/get_support_data
  get_data, 'rbsp'+sc+'_efw_hsk_beb_analog_CONFIG0',data=BEB_config
  tinterpol_mxn,'rbsp'+sc+'_efw_hsk_idpu_fast_TBD',times
  get_data,'rbsp'+sc+'_efw_hsk_idpu_fast_TBD_interp',data=tbd
  
  
;copy_data,'rbsp'+sc+'_efw_hsk_idpu_fast_TBD','rbsp'+sc+'_efw_hsk_idpu_fast_TBD2'
;rbsp_decimate,'rbsp'+sc+'_efw_hsk_idpu_fast_TBD2'
;tinterpol_mxn,'rbsp'+sc+'_efw_hsk_idpu_fast_TBD','rbsp'+sc+'_efw_hsk_idpu_fast_TBD2'
;tplot,['rbsp'+sc+'_efw_hsk_idpu_fast_TBD','rbsp'+sc+'_efw_hsk_idpu_fast_TBD_interp']

  
;***********************
;NEED TO TEST THESE B/C THEY'VE BEEN DOWNSAMPLED
  autobias_flag = tbd.y
;************************




;Then looking for where BEB_config.y = 64
;This seemed to flag nearly all of the bias sweep event

;---------------------------------------------------
;AUTO BIAS VALUES (BONNELL EMAIL ON 4/30/2014
;--------------------------------------------------
; PRH repurposed some spare bits in one of the HSK quantities to indicate
;the configuration and activity state of the AutoBias (SCVB) program.

; These config and status bits can be accessed through the following
;quantity (using the SPEDAS/IDL designation since I don't know how the
;quantity would be specified in Science Data Tool but the interpretation
;of the bits should be the same regardless of the name):

;	rbsp{a,b}_efw_hsk_idpu_fast_TBD

; Yes, the HSK quantity's name is "TBD", not to be determined; that's what
;happens when one utilizes spares!

; This quantity can be considered to be diveded into four one-bit flags
;occupying the bit locations shown below:

;Bit	Value	Meaning
;3	8	Toggles off and on every other cycle when AutoBias is;
;		active.
;2	4	One when AutoBias is controlling the bias, Zero when
;		AutoBias is not controlling the bias.
;1	2	One when BIAS3 and BIAS4 can be controlled by AUtoBias,
;		zero otherwise.
;0	1	One when BIAS1 and BIAS2 can be controlled by AUtoBias,
;		zero otherwise.
;
                                ;If one just plots the value of the IDPU_FAST_TBD quantity, then one gets
;an integer that is the sum of the values of the bits that are set to one
;(naturally).

; For example - for all the tests so far, control of both BIAS1+BIAS2 and
;BIAS3+BIAS4 have been enabled, and b/c of issues with the parameter
;settings, AutoBias has almost always been actively controlling the biases
;when the program was running, and so bits 2, 1, and 0 were on (1), giving
;TBD the value of 7.
;
;NOTES:
;
;(1)  When AutoBias is not running, the value of TBD is all zeros.
;
;(2)  It's not clear given the default rate at which the IDPU Fast Digital
;HSK packet is generated that the toggling of TBD bit 3 will be seen at all
;possible cadences (8, 16, 32, ..., 2048 s).  On the ETU, it was easy
;enough to see, but the cadence of the IDPU Fast Digital HSK packet there
;was 1 s, but the toggling may not be seen in the on-orbit config.
;
;(3)  To clarify - if the AutoBias update cadence is set to 8 seconds, then
;what one should see is TBD bit 3 on for 8 seconds, then off for 8 seconds.



                                ;Get flag values
  na_val = -2                   ;not applicable value
  fill_val = -1                 ;value in flag array that indicates "dunno"
  maxvolts = 195.               ;Max antenna voltage above which the saturation flag is thrown
  offset = 5                    ;position in flag_arr of "v1_saturation" 

  tmp = replicate(0,n_elements(times),6)
  flag_arr = replicate(fill_val,n_elements(times),20)


  for i=0,5 do begin

                                ;Change bad values to "1"
     vbad = where(abs(vsvy.y[*,i]) ge maxvolts)
     if vbad[0] ne -1 then tmp[vbad,i] = 1

                                ;Change good values to "0"
     vgood = where(abs(vsvy.y[*,i]) lt maxvolts)
     if vgood[0] ne -1 then tmp[vgood,i] = 0

                                ;Interpolate the bad data values onto the pre-defined flag value times
     flag_arr[*,i+offset] = ceil(tmp[*,i])


;****TEMPORARY CODE******
;Set the actual bad vsvy values to NaN
     if vbad[0] ne -1 then vsvy.y[vbad,i] = -1.e31
;************************


  endfor


;****TEMPORARY CODE******
;Throw the global flag if any of the single-ended flags are thrown.
  flag_arr[*,0] = 0
  goo = where((flag_arr[*,5] eq 1) or (flag_arr[*,6] eq 1) or (flag_arr[*,7] eq 1) or (flag_arr[*,8] eq 1))
  if goo[0] ne -1 then flag_arr[goo,0] = 1
;************************


                                ;set V5 and V6 flags to bad
  flag_arr[*,9] = 1
  flag_arr[*,10] = 1



;*****TEMPORARY CODE*****
;set the eclipse flag in this program

;Umbra
  if is_struct(eu) then begin
     for bb=0,n_elements(eu.x)-1 do begin
        goo = where((vsvy.x ge eu.x[bb]) and (vsvy.x le (eu.x[bb]+eu.y[bb])))
        if goo[0] ne -1 then eclipset[goo] = 1
     endfor
  endif
;Penumbra
  if is_struct(ep) then begin
     for bb=0,n_elements(ep.x)-1 do begin
        goo = where((vsvy.x ge ep.x[bb]) and (vsvy.x le (ep.x[bb]+ep.y[bb])))
        if goo[0] ne -1 then eclipset[goo] = 1
     endfor
  endif
  
  
  flag_arr[*,1] = ceil(interpol(eclipset,vsvy.x,timevals))
  
  
                                ;Also set global flag if eclipse flag is thrown
  goo = where(flag_arr[*,1] eq 1)
  if goo[0] ne -1 then flag_arr[goo,0] = 1
  
  
;***********************
  
  flag_arr[*,2] = fill_val       ;maneuver
  flag_arr[*,3] = fill_val       ;efw_sweep
  flag_arr[*,4] = fill_val       ;efw_deploy
  
  
                                ;Set the N/A values. These are not directly relevant to the quality
                                ;of the Vsvy product
  flag_arr[*,11] = na_val       ;Espb_magnitude
  flag_arr[*,12] = na_val       ;Eparallel_magnitude
  flag_arr[*,13] = na_val       ;magnetic_wake
  flag_arr[*,14:19] = na_val    ;undefined values
  
  


                                ;*****TEMPORARY********
                                ;NaN out bad values
  goo = where((finite(vsvy.y[*,0]) eq 0) or (finite(vsvy.y[*,1]) eq 0))
;	if goo[0] ne -1 then sum12[goo] = -1.e31
  if goo[0] ne -1 then density[goo] = -1.e31
  goo = where((finite(vsvy.y[*,2]) eq 0) or (finite(vsvy.y[*,3]) eq 0))
  if goo[0] ne -1 then sum34[goo] = -1.e31
                                ;**********************
                                ;Nan out all spinfit values when global flag or eclipse flag is thrown 

  goo = where(flag_arr[*,0] eq 1)
  if goo[0] ne -1 then begin
     spinfit_vxb[goo,*] = -1.e31
;		spinfit[goo,*] = -1.e31
;		sum12[goo] = -1.e31
;		sum34[goo] = -1.e31
     density[goo] = -1.e31
  endif
  goo = where(flag_arr[*,1] eq 1)
  if goo[0] ne -1 then begin
     spinfit_vxb[goo,*] = -1.e31
;		spinfit[goo,*] = -1.e31
     ;; sum12[goo] = -1.e31
     ;; sum34[goo] = -1.e31
     density[goo] = -1.e31
  endif


  eclipse_flag = flag_arr[*,1]

  charging_flag = fltarr(n_elements(eclipse_flag))
  goo = where((flag_arr[*,5] eq 1) or (flag_arr[*,6] eq 1) or (flag_arr[*,7] eq 1) or (flag_arr[*,8] eq 1))
  if goo[0] ne -1 then charging_flag[goo] = 1


  goo = where(charging_flag eq 1)
  if goo[0] ne -1 then density[goo] = -1.e31


  ;Get the Vsc x B data
  get_data,'vxb_x',data=vxbx
  get_data,'vxb_y',data=vxby
  get_data,'vxb_z',data=vxbz
  store_data,'vxb',data={x:vxbx.x,y:[[vxbx.y],[vxby.y],[vxbz.y]]}


                                ;the times for the mag spinfit can be slightly different than the times for the
                                ;Esvy spinfit. 
  tinterpol_mxn,rbspx+'_mag_mgse',times,newname=rbspx+'_mag_mgse'
  get_data,rbspx+'_mag_mgse',data=mag_mgse


                                ;Downsample the GSE position and velocity variables to cadence of spinfit data
  tinterpol_mxn,rbspx+'_E_coro_mgse',times,newname=rbspx+'_E_coro_mgse'
  tinterpol_mxn,'vxb',times,newname='vxb'
  tinterpol_mxn,rbspx+'_state_vel_coro_mgse',times,newname=rbspx+'_state_vel_coro_mgse'
  tinterpol_mxn,rbspx+'_state_pos_gse',times,newname=rbspx+'_state_pos_gse'
  tinterpol_mxn,rbspx+'_state_vel_gse',times,newname=rbspx+'_state_vel_gse'
  get_data,'vxb',data=vxb
  get_data,rbspx+'_state_pos_gse',data=pos_gse
  get_data,rbspx+'_state_vel_gse',data=vel_gse
  get_data,rbspx+'_E_coro_mgse',data=ecoro_mgse
  get_data,rbspx+'_state_vel_coro_mgse',data=vcoro_mgse
  
  tinterpol_mxn,rbspx+'_mag_mgse_'+model,times,newname=rbspx+'_mag_mgse_'+model
  tinterpol_mxn,rbspx+'_mag_mgse_t89_dif',times,newname=rbspx+'_mag_mgse_t89_dif'
  get_data,rbspx+'_mag_mgse_'+model,data=mag_model
  get_data,rbspx+'_mag_mgse_t89_dif',data=mag_diff

  mag_model_magnitude = sqrt(mag_model.y[*,0]^2 + mag_model.y[*,1]^2 + mag_model.y[*,2]^2)
  mag_data_magnitude = sqrt(mag_mgse.y[*,0]^2 + mag_mgse.y[*,1]^2 + mag_mgse.y[*,2]^2)
  mag_diff_magnitude = mag_data_magnitude - mag_model_magnitude


  tinterpol_mxn,rbspx+'_state_mlt',times,newname=rbspx+'_state_mlt'
  tinterpol_mxn,rbspx+'_state_mlat',times,newname=rbspx+'_state_mlat'
  tinterpol_mxn,rbspx+'_state_lshell',times,newname=rbspx+'_state_lshell'
  tinterpol_mxn,rbspx+'_ME_lstar',times,newname=rbspx+'_ME_lstar'
  tinterpol_mxn,rbspx+'_ME_orbitnumber',times,newname=rbspx+'_ME_orbitnumber'

  get_data,rbspx+'_state_mlt',data=mlt
  get_data,rbspx+'_state_mlat',data=mlat
  get_data,rbspx+'_state_lshell',data=lshell
  get_data,rbspx+'_ME_orbitnumber',data=orbit_num
  get_data,rbspx+'_ME_lstar',data=lstar
  if is_struct(lstar) then lstar = lstar.y[*,0]


  tinterpol_mxn,rbspx+'_spinaxis_direction_gse',times,newname=rbspx+'_spinaxis_direction_gse'
  get_data,rbspx+'_spinaxis_direction_gse',data=sa

                                ;If the hires keyword is selected then create an additional CDF file for hires + lowres data

  mlt_lshell_mlat = [[mlt.y],[lshell.y],[mlat.y]]
  location = [[mlt.y],[lshell.y],[mlat.y],$
              [pos_gse.y[*,0]],[pos_gse.y[*,1]],[pos_gse.y[*,2]],$
              [vel_gse.y[*,0]],[vel_gse.y[*,1]],[vel_gse.y[*,2]],$
              [sa.y[*,0]],[sa.y[*,1]],[sa.y[*,2]],[orbit_num.y],[lstar]]
  flags = [[charging_flag],[autobias_flag],[eclipse_flag]]
  bfield_data = [[mag_mgse.y[*,0]],[mag_mgse.y[*,0]],[mag_mgse.y[*,0]],$
                 [mag_model.y[*,0]],[mag_model.y[*,0]],[mag_model.y[*,0]],$
                 [mag_diff.y[*,0]],[mag_diff.y[*,0]],[mag_diff.y[*,0]],$
                 [mag_data_magnitude],[mag_diff_magnitude]]
  density_potential = [[density],[sum12],[v1],[v2],[v3],[v4],[v5],[v6]]


  if ~keyword_set(type) then filename = 'rbsp'+sc+'_efw-l3_'+strjoin(strsplit(date,'-',/extract))+'_v'+vstr+'.cdf'
  if type eq 'hidden' then filename = 'rbsp'+sc+'_efw-l3_'+strjoin(strsplit(date,'-',/extract))+'_v'+vstr+'_hidden.cdf'
  if type eq 'survey' then filename = 'rbsp'+sc+'_efw-l3_'+strjoin(strsplit(date,'-',/extract))+'_v'+vstr+'_survey.cdf'


  
  file_copy,source_file,folder+filename,/overwrite

  cdfid = cdf_open(folder+filename)

  cdf_varput,cdfid,'epoch',epoch
  cdf_varput,cdfid,'epoch_qual',epochvals
  cdf_varput,cdfid,'flags_all',transpose(flag_arr)
  cdf_varput,cdfid,'flags_charging_bias_eclipse',transpose(flags)

 
;**************************************************
;Populate CDF file for L3 version
;**************************************************

  if type eq 'L3' then begin
     
     cdf_varput,cdfid,'efield_inertial_frame_mgse',transpose(spinfit_vxb)
     cdf_varput,cdfid,'efield_corotation_frame_mgse',transpose(spinfit_vxb_coro)
     cdf_varput,cdfid,'VcoroxB_mgse',transpose(ecoro_mgse.y)
     cdf_varput,cdfid,'VscxB_mgse',transpose(vxb.y)
     cdf_varput,cdfid,'density',density
     cdf_varput,cdfid,'v1_plus_v2_div2',sum12
     cdf_varput,cdfid,'mlt_lshell_mlat',transpose(mlt_lshell_mlat)
     cdf_varput,cdfid,'pos_gse',transpose(pos_gse.y)
     cdf_varput,cdfid,'vel_gse',transpose(vel_gse.y)
     cdf_varput,cdfid,'spinaxis_gse',transpose(sa.y)
     
     cdf_vardelete,cdfid,'efield_inertial_frame_mgse_edotb_zero'
     cdf_vardelete,cdfid,'efield_corotation_frame_mgse_edotb_zero'
     cdf_vardelete,cdfid,'bfield_mgse'
     cdf_vardelete,cdfid,'bfield_model_mgse'
     cdf_vardelete,cdfid,'bfield_minus_model_mgse'
     cdf_vardelete,cdfid,'bfield_magnitude'
     cdf_vardelete,cdfid,'bfield_magnitude_minus_modelmagnitude'
     cdf_vardelete,cdfid,'Bfield'
     cdf_vardelete,cdfid,'density_potential'
     cdf_vardelete,cdfid,'ephemeris'
     cdf_vardelete,cdfid,'orbit_num'
     cdf_vardelete,cdfid,'Lstar'
     cdf_vardelete,cdfid,'angle_Ey_Ez_Bo'

  endif



;**************************************************
;Populate CDF file for survey version
;**************************************************


  if type eq 'survey' then begin

     cdf_varput,cdfid,'efield_inertial_frame_mgse',transpose(spinfit_vxb)
     cdf_varput,cdfid,'efield_corotation_frame_mgse',transpose(spinfit_vxb_coro)
     cdf_varput,cdfid,'efield_inertial_frame_mgse_edotb_zero',transpose(spinfit_vxb_edotb)
     cdf_varput,cdfid,'efield_corotation_frame_mgse_edotb_zero',transpose(spinfit_vxb_coro_edotb)
     cdf_varput,cdfid,'VcoroxB_mgse',transpose(ecoro_mgse.y)
     cdf_varput,cdfid,'VscxB_mgse',transpose(vxb.y)
     cdf_varput,cdfid,'Bfield',transpose(bfield_data)
     cdf_varput,cdfid,'density_potential',transpose(density_potential)
     cdf_varput,cdfid,'ephemeris',transpose(location)
     cdf_varput,cdfid,'angle_Ey_Ez_Bo',transpose(angles.y)
     
     cdf_vardelete,cdfid,'orbit_num'
     cdf_vardelete,cdfid,'Lstar'
     cdf_vardelete,cdfid,'density'   
     cdf_vardelete,cdfid,'v1_plus_v2_div2'
     cdf_vardelete,cdfid,'pos_gse'
     cdf_vardelete,cdfid,'vel_gse'
     cdf_vardelete,cdfid,'spinaxis_gse'
     cdf_vardelete,cdfid,'mlt_lshell_mlat'
     cdf_vardelete,cdfid,'bfield_mgse'
     cdf_vardelete,cdfid,'bfield_model_mgse'
     cdf_vardelete,cdfid,'bfield_minus_model_mgse'
     cdf_vardelete,cdfid,'bfield_magnitude_minus_modelmagnitude'
     cdf_vardelete,cdfid,'bfield_magnitude'


  endif


;**************************************************
;Populate CDF file for hidden version
;**************************************************

  if type eq 'hidden' then begin

     cdf_varput,cdfid,'efield_inertial_frame_mgse',transpose(spinfit_vxb)
     cdf_varput,cdfid,'efield_corotation_frame_mgse',transpose(spinfit_vxb_coro)
     cdf_varput,cdfid,'efield_inertial_frame_mgse_edotb_zero',transpose(spinfit_vxb_edotb)
     cdf_varput,cdfid,'efield_corotation_frame_mgse_edotb_zero',transpose(spinfit_vxb_coro_edotb)
     cdf_varput,cdfid,'VcoroxB_mgse',transpose(ecoro_mgse.y)
     cdf_varput,cdfid,'VscxB_mgse',transpose(vxb.y)
     cdf_varput,cdfid,'bfield_magnitude',mag_data_magnitude
     cdf_varput,cdfid,'bfield_mgse',transpose(mag_mgse.y)
     cdf_varput,cdfid,'bfield_model_mgse',transpose(mag_model.y)
     cdf_varput,cdfid,'bfield_minus_model_mgse',transpose(mag_diff.y)
     cdf_varput,cdfid,'bfield_magnitude_minus_modelmagnitude',mag_diff_magnitude
     cdf_varput,cdfid,'density',density
     cdf_varput,cdfid,'v1_plus_v2_div2',sum12
     cdf_varput,cdfid,'mlt_lshell_mlat',transpose(mlt_lshell_mlat)
     cdf_varput,cdfid,'pos_gse',transpose(pos_gse.y)
     cdf_varput,cdfid,'vel_gse',transpose(vel_gse.y)
     cdf_varput,cdfid,'spinaxis_gse',transpose(sa.y)
     cdf_varput,cdfid,'orbit_num',orbit_num.y
     cdf_varput,cdfid,'Lstar',lstar
     cdf_varput,cdfid,'angle_Ey_Ez_Bo',transpose(angles.y)
     
     cdf_vardelete,cdfid,'Bfield'
     cdf_vardelete,cdfid,'ephemeris'
     cdf_vardelete,cdfid,'density_potential'


  endif



  cdf_close, cdfid
  store_data,tnames(),/delete



  ;;                               ;Load the newly filled CDF structure to see if it works
  ;; if ~skip_plot then begin

  ;;    cdf_leap_second_init
  ;;    cdf2tplot,files=folder + filename

  ;;    ylim,'vsvy_vavg',-200,200
  ;;    ylim,'efw_qual',-2,2
  ;;    ylim,'e12_spinfit_mgse',-20,20
  ;;    ylim,'vxb_spinfit_mgse',-20,20

  ;;    tplot,tnames()

  ;;    names = ['global_flag',$
  ;;             'eclipse',$
  ;;             'maneuver',$
  ;;             'efw_sweep',$
  ;;             'efw_deploy',$
  ;;             'v1_saturation',$
  ;;             'v2_saturation',$
  ;;             'v3_saturation',$
  ;;             'v4_saturation',$
  ;;             'v5_saturation',$
  ;;             'v6_saturation',$
  ;;             'Espb_magnitude',$
  ;;             'Eparallel_magnitude',$
  ;;             'magnetic_wake',$
  ;;             'undefined	',$
  ;;             'undefined	',$
  ;;             'undefined	',$
  ;;             'undefined	',$
  ;;             'undefined',$
  ;;             'undefined']

  ;;    split_vec,'efw_qual',suffix='_'+names

  ;;    ylim,'e12_vxb_spinfit_mgse',-30,30
  ;;    tplot,['efw_qual_global_flag','vsvy_vavg','e12_spinfit_mgse','e12_vxb_spinfit_mgse','mag_spinfit_mgse','density']
     
  ;; endif

  ;; dprint,'END TIME IS ',systime()
  ;; dprint,'TOTAL RUNTIME (s) IS ',systime(1)-starttime
  
  

end
