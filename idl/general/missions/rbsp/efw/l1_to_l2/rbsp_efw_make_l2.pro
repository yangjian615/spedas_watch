;+
; NAME:
;   rbsp_efw_make_l2
;
; PURPOSE:
;   Generate level-2 EFW CDF files 
;
;
; CALLING SEQUENCE:
;   rbsp_efw_make_l2_spinfit, sc, date
;
; ARGUMENTS:
;   sc: IN, REQUIRED
;         'a' or 'b'
;   date: IN, REQUIRED
;         A date string in format like '2013-02-13'
;
; KEYWORDS:
;   folder: IN, OPTIONAL
;         Default is something like
;           !rbsp_efw.local_data_dir/rbspa/l2/spinfit/2012/
;
;   type: Set to choose which type of L2 file you want to
;   create. Options are
;           'combo'   (hidden combo files)                (working)
;           'esvy_despun'  (official L2 product)          (working)
;           'spinfit_both_boompairs' (hidden L2 product that
;                calculates spinfit quantities with both V1V2 and V3V4
;           'vsvy_hires'   (official L2 product)          (working)
;           'spinfit' (default, official L2 product)      (working)
;           'combo_wygant' (no hires data)                (working)
;           'pfaff_esvy'                                  (working)
;           'combo_pfaff'                                 (working)
;
;   boom_pair -> specify for the spinfit routine. Defaults to '12' but
;   can be set to '34'
;
; OLD CDF files that are now obsolete are:
;      rbspa_efw-l2_e-spinfit-mgse_20130103_v01.cdf
;      rbspa_efw-l2_esvy_despun_20130105_v01.cdf
;      rbspa_efw-l2_vsvy-hires_20130105_v01.cdf
;      rbspa_efw-l2_combo_20130101_v03_hr.cdf
;      rbspa_efw-l2_combo_20130101_v03.cdf
;      rbspa_efw-l2_combo_pfaff_00000000_v01.cdf
;      rbspa_efw-l2_combo_wygant_00000000_v01.cdf
;
;
; HISTORY:
;   2014-12-02: Created by Aaron W Breneman, U. Minnesota
;				
;
; VERSION:
; $LastChangedBy: aaronbreneman $
; $LastChangedDate: 2016-01-27 14:29:37 -0800 (Wed, 27 Jan 2016) $
; $LastChangedRevision: 19824 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/l1_to_l2/rbsp_efw_make_l2.pro $
;
;-

pro rbsp_efw_make_l2,sc,date,$
                     folder=folder,$
                     type=type,$
                     magExtra = magExtra,$
                     version = version,$
                     save_flags = save_flags,$
                     no_spice_load = no_spice_load,$
                     no_cdf = no_cdf,$
                     testing=testing,$
                     hires=hires,$
                     boom_pair=bp,$
                     ql=ql


  if ~keyword_set(type) then type = 'spinfit'
  if ~keyword_set(bp) then bp = '12'
  if ~keyword_set(ql) then ql = 0


  if ~keyword_set(testing) then begin
     openw,lun,'output.txt',/get_lun
     printf,lun,'date = ',date
     printf,lun,'date type: ',typename(date)
     printf,lun,'probe = ',sc
     printf,lun,'probe type: ',typename(sc)
     printf,lun,'bp = ',bp
     printf,lun,'bp type: ',typename(bp)
;  printf,lun,'hires = ',hires
;  printf,lun,'hires type: ',typename(hires)
     close,lun
     free_lun,lun
  endif

  compile_opt idl2

  rbsp_efw_init

  if n_elements(version) eq 0 then version = 2
  vstr = string(version, format='(I02)')


  rbspx='rbsp' + strlowcase(sc[0])
  rbx = rbspx + '_'

;------------ Set up paths. BEGIN. ----------------------------

  if ~keyword_set(no_cdf) then begin

     year = strmid(date, 0, 4)

     if ~keyword_set(folder) then folder = !rbsp_efw.local_data_dir + $
                                           'rbsp' + strlowcase(sc[0]) + path_sep() + $
                                           'l2' + path_sep() + $
                                           'spinfit' + path_sep() + $
                                           year + path_sep()

                                ; make sure we have the trailing slash on folder
     if strmid(folder,strlen(folder)-1,1) ne path_sep() then folder=folder+path_sep()
     if ~keyword_set(no_cdf) then file_mkdir, folder



                                ; Grab the skeleton file.
     ;; skeleton=rbspx+'/l2/e-spinfit-mgse/0000/'+ $
     ;;          rbspx+'_efw-l2_00000000_v'+vstr+'.cdf'
     skeleton='/Volumes/UserA/user_homes/kersten/RBSP_l2/'+rbspx+'_efw-l2_00000000_v02.cdf'


                                ; use skeleton from the staging dir until we go live in the main data tree
                                ;skeletonFile='/Volumes/DataA/user_volumes/kersten/data/rbsp/'+skeleton

     found = 1
                                ; make sure we have the skeleton CDF
     if ~keyword_set(testing) then skeletonFile=file_search(skeleton,count=found)
     if keyword_set(testing) then $
        skeletonfile = '~/Desktop/code/Aaron/RBSP/TDAS_trunk_svn/general/missions/rbsp/efw/l1_to_l2/rbsp'+$
                       sc+'_efw-l2_00000000_v02.cdf'


     if ~found then begin
        dprint,'Could not find skeleton CDF, returning.'
        return
     endif
                                ; fix single element source file array
     skeletonFile=skeletonFile[0]

  endif

  if keyword_set(testing) then folder = '~/Desktop/code/Aaron/RBSP/TDAS_trunk_svn/general/missions/rbsp/efw/l1_to_l2/'



;------------ Set up paths. END. ----------------------------


  skip = 'no'

  if skip eq 'no' then begin

     store_data,tnames(),/delete
     timespan,date
     rbsp_load_spice_kernels

                                ;--------------------------------------------------

     rbsp_load_efw_waveform,probe=sc,type='calibrated',datatype='vsvy',/noclean

     get_data,'rbsp'+sc+'_efw_vsvy',data=vsvy
     epoch_v = tplot_time_to_epoch(vsvy.x,/epoch16)
     times_v = vsvy.x

     ;; full resolution (V1+V2)/2
     vsvy_vavg = [[(vsvy.y[*,0] - vsvy.y[*,1])/2.],$
                  [(vsvy.y[*,2] - vsvy.y[*,3])/2.],$
                  [(vsvy.y[*,4] - vsvy.y[*,5])/2.]]
     
     split_vec, 'rbsp'+sc+'_efw_vsvy', suffix='_V'+['1','2','3','4','5','6']
     get_data,'rbsp'+sc+'_efw_vsvy',data=vsvy

     
     if type eq 'combo' or type eq 'pfaff_esvy' or type eq 'esvy_despun' or type eq 'combo_pfaff' then begin
        rbsp_load_efw_waveform,probe=sc,type='calibrated',datatype='esvy',/noclean

        get_data,'rbsp'+sc+'_efw_esvy',data=esvy
        epoch_e = tplot_time_to_epoch(esvy.x,/epoch16)
        times_e = esvy.x

        if type eq 'combo' or type eq 'pfaff_esvy' or type eq 'combo_pfaff' then begin
           tinterpol_mxn,'rbsp'+sc+'_efw_esvy','rbsp'+sc+'_efw_vsvy',newname='rbsp'+sc+'_efw_esvy'
           get_data,'rbsp'+sc+'_efw_esvy',data=esvy_v
        endif
        
     endif




;despin the Efield data and put in MGSE
;Load the vxb subtracted data. If there isn't any vxb subtracted data
;then grab the regular Esvy MGSE data

     if type eq 'combo' or type eq 'esvy_despun' or type eq 'combo_pfaff' then begin
        if ~keyword_set(qa) then rbsp_efw_vxb_subtract_crib,sc,/no_spice_load,/noplot
        if keyword_set(qa)  then rbsp_efw_vxb_subtract_crib,sc,/no_spice_load,/noplot,/qa

        get_data,'rbsp'+sc+'_efw_esvy_mgse_vxb_removed',data=esvy_vxb_mgse
        esvy_vxb_mgse.y[*,0] = -1.e31

        epoch_e = tplot_time_to_epoch(esvy_vxb_mgse.x,/epoch16)
        times_e = esvy_vxb_mgse.x

        get_data,'rbsp'+sc+'_efw_esvy_mgse',data=esvy_mgse

     endif

     
                                ;Load ECT's magnetic ephemeris
     rbsp_read_ect_mag_ephem,sc

                                ;Load both the spinfit data and also the E*B=0 version
     if type ne 'spinfit_both_boompairs' then rbsp_efw_edotb_to_zero_crib,$
        date,sc,/no_spice_load,/noplot,suffix='edotb',boom_pair=bp,ql=ql

     if type eq 'spinfit_both_boompairs' then begin

        rbsp_efw_edotb_to_zero_crib,$
           date,sc,/no_spice_load,/noplot,suffix='edotb',boom_pair='12',ql=ql

        copy_data,'rbsp'+sc+'_efw_esvy_spinfit',$
                  'tmp_sf_12'
        copy_data,'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_spinfit',$
                  'tmp_sf_vxb_12'
        copy_data,'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_coro_removed_spinfit',$
                  'tmp_sf_vxb_coro_12'
        copy_data,'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_spinfit_edotb',$
                  'tmp_sf_vxb_edotb_12'
        copy_data,'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_coro_removed_spinfit_edotb',$
                  'tmp_sf_vxb_coro_edotb_12'


        rbsp_efw_edotb_to_zero_crib,$
           date,sc,/no_spice_load,/noplot,suffix='edotb',boom_pair='34',ql=ql


        ;;Temporarily rename these b/c the edotb routine deletes
        ;;"spinfit" tplot variables
        copy_data,'rbsp'+sc+'_efw_esvy_spinfit',$
                  'tmp_sf_34'
        copy_data,'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_spinfit',$
                  'tmp_sf_vxb_34'
        copy_data,'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_coro_removed_spinfit',$
                  'tmp_sf_vxb_coro_34'
        copy_data,'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_spinfit_edotb',$
                  'tmp_sf_vxb_edotb_34'
        copy_data,'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_coro_removed_spinfit_edotb',$
                  'tmp_sf_vxb_coro_edotb_34'
        



        ;;Now copy to final names
        copy_data,'tmp_sf_12',$
                  'rbsp'+sc+'_efw_esvy_spinfit_12'
        copy_data,'tmp_sf_34',$
                  'rbsp'+sc+'_efw_esvy_spinfit_34'

        copy_data,'tmp_sf_vxb_12',$
                  'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_spinfit_12'
        copy_data,'tmp_sf_vxb_34',$
                  'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_spinfit_34'

        copy_data,'tmp_sf_vxb_coro_12',$
                  'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_coro_removed_spinfit_12'
        copy_data,'tmp_sf_vxb_coro_34',$
                  'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_coro_removed_spinfit_34'

        copy_data,'tmp_sf_vxb_edotb_12',$
                  'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_spinfit_edotb_12'
        copy_data,'tmp_sf_vxb_edotb_34',$
                  'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_spinfit_edotb_34'

        copy_data,'tmp_sf_vxb_coro_edotb_12',$
                  'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_coro_removed_spinfit_edotb_12'
        copy_data,'tmp_sf_vxb_coro_edotb_34',$
                  'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_coro_removed_spinfit_edotb_34'
        

        store_data,['*tmp_sf*'],/delete
     endif




;Get the official times to which all quantities are interpolated to
     if type ne 'spinfit_both_boompairs' then get_data,'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_spinfit',data=tmp
     if type eq 'spinfit_both_boompairs' then get_data,'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_spinfit_12',data=tmp
     times = tmp.x
     epoch = tplot_time_to_epoch(times,/epoch16)



;--------------------------------------------------
;Get flag values (also gets density values from v12 and v34)
;--------------------------------------------------

     flag_str = rbsp_efw_get_flag_values(sc,times)

     flag_arr = flag_str.flag_arr
     bias_sweep_flag = flag_str.bias_sweep_flag
     ab_flag = flag_str.ab_flag
     charging_flag = flag_str.charging_flag
     ibias = flag_str.ibias


     

;--------------------------------------------------
;save all spinfit resolution Efield quantities
;--------------------------------------------------

     if type ne 'spinfit_both_boompairs' then begin

        tmp = 0.
        get_data,'rbsp'+sc+'_efw_esvy_spinfit',data=tmp
        if is_struct(tmp) then begin
           if type eq 'spinfit' then tmp.y[*,0] = -1.0E31
           spinfit_esvy = tmp.y
           tmp = 0.
        endif

                                ;Spinfit with corotation field
        get_data,'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_spinfit',data=tmp
        if is_struct(tmp) then begin
           if type eq 'spinfit' then tmp.y[*,0] = -1.0E31
           spinfit_vxb = tmp.y
           tmp = 0.
        endif

        ;;                         ;Spinfit with corotation field and E*B=0
        ;; get_data,'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_spinfit_edotb',data=tmp
        ;; if type eq 'spinfit' then tmp.y[*,0] = -1.0E31
        ;; spinfit_vxb_edotb = tmp.y
                                ;Spinfit without corotation field
        get_data,'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_coro_removed_spinfit',data=tmp
        if is_struct(tmp) then begin
           if type eq 'spinfit' then tmp.y[*,0] = -1.0E31
           spinfit_vxb_coro = tmp.y
           tmp = 0.
        endif

                  ;Spinfit without corotation field and E*B=0
        get_data,'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_coro_removed_spinfit_edotb',data=tmp
        if is_struct(tmp) then begin
           spinfit_vxb_coro_edotb = tmp.y
        endif

     endif

     ;----------
     if type eq 'spinfit_both_boompairs' then begin

        tmp = 0.
        tinterpol_mxn,'rbsp'+sc+'_efw_esvy_spinfit_12',times,$
              newname='rbsp'+sc+'_efw_esvy_spinfit_12'
        get_data,     'rbsp'+sc+'_efw_esvy_spinfit_12',data=tmp
        if is_struct(tmp) then begin
           tmp.y[*,0] = -1.0E31
           spinfit_esvy_12 = tmp.y
           tmp = 0.
        endif

                                ;Spinfit with corotation field
        tinterpol_mxn,'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_spinfit_12',times,$
              newname='rbsp'+sc+'_efw_esvy_mgse_vxb_removed_spinfit_12'
        get_data,     'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_spinfit_12',data=tmp
        if is_struct(tmp) then begin
           tmp.y[*,0] = -1.0E31
           spinfit_vxb_12 = tmp.y
           tmp = 0.
        endif
                                ;Spinfit with corotation field and E*B=0
        tinterpol_mxn,'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_spinfit_edotb_12',times,$
              newname='rbsp'+sc+'_efw_esvy_mgse_vxb_removed_spinfit_edotb_12'
        get_data,     'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_spinfit_edotb_12',data=tmp
        if is_struct(tmp) then begin
           spinfit_vxb_edotb_12 = tmp.y
        endif

                                ;Spinfit without corotation field
        tinterpol_mxn,'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_coro_removed_spinfit_12',times,$
              newname='rbsp'+sc+'_efw_esvy_mgse_vxb_removed_coro_removed_spinfit_12'
        get_data,     'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_coro_removed_spinfit_12',data=tmp
        if is_struct(tmp) then begin
           tmp.y[*,0] = -1.0E31
           spinfit_vxb_coro_12 = tmp.y
           tmp = 0.
        endif
                                ;Spinfit without corotation field and E*B=0
        tinterpol_mxn,'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_coro_removed_spinfit_edotb_12',times,$
              newname='rbsp'+sc+'_efw_esvy_mgse_vxb_removed_coro_removed_spinfit_edotb_12'
        get_data,     'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_coro_removed_spinfit_edotb_12',data=tmp
        if is_struct(tmp) then begin
           spinfit_vxb_coro_edotb_12 = tmp.y
        endif
                                ;----

        tmp = 0.
        tinterpol_mxn,'rbsp'+sc+'_efw_esvy_spinfit_34',times,$
              newname='rbsp'+sc+'_efw_esvy_spinfit_34'
        get_data,     'rbsp'+sc+'_efw_esvy_spinfit_34',data=tmp
        if is_struct(tmp) then begin
           tmp.y[*,0] = -1.0E31
           spinfit_esvy_34 = tmp.y
           tmp = 0.
        endif
                   ;Spinfit with corotation field
        tinterpol_mxn,'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_spinfit_34',times,$
              newname='rbsp'+sc+'_efw_esvy_mgse_vxb_removed_spinfit_34'
        get_data,     'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_spinfit_34',data=tmp
        if is_struct(tmp) then begin
           tmp.y[*,0] = -1.0E31
           spinfit_vxb_34 = tmp.y
           tmp = 0.
        endif
                   ;Spinfit with corotation field and E*B=0
        tinterpol_mxn,'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_spinfit_edotb_34',times,$
              newname='rbsp'+sc+'_efw_esvy_mgse_vxb_removed_spinfit_edotb_34'
        get_data,     'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_spinfit_edotb_34',data=tmp
        if is_struct(tmp) then begin
           spinfit_vxb_edotb_34 = tmp.y
        endif
                   ;Spinfit without corotation field
        tinterpol_mxn,'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_coro_removed_spinfit_34',times,$
              newname='rbsp'+sc+'_efw_esvy_mgse_vxb_removed_coro_removed_spinfit_34'
        get_data,     'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_coro_removed_spinfit_34',data=tmp
        if is_struct(tmp) then begin
           tmp.y[*,0] = -1.0E31
           spinfit_vxb_coro_34 = tmp.y
           tmp = 0.
        endif
                   ;Spinfit without corotation field and E*B=0
        tinterpol_mxn,'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_coro_removed_spinfit_edotb_34',times,$
              newname='rbsp'+sc+'_efw_esvy_mgse_vxb_removed_coro_removed_spinfit_edotb_34'
        get_data,     'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_coro_removed_spinfit_edotb_34',data=tmp
        if is_struct(tmp) then begin
           spinfit_vxb_coro_edotb_34 = tmp.y
        endif
     endif


;--------------------------------------
;SUBTRACT OFF MODEL FIELD
;--------------------------------------

     model = 't89'
     rbsp_efw_DCfield_removal_crib,sc,/no_spice_load,/noplot,model=model
     

;--------------------------------------
; SC potentials (V1+V2)/2 and (V3+V4)/2
;--------------------------------------

     get_data,'rbsp'+sc +'_efw_vsvy_V1',data=v1
     get_data,'rbsp'+sc +'_efw_vsvy_V2',data=v2
     get_data,'rbsp'+sc +'_efw_vsvy_V3',data=v3
     get_data,'rbsp'+sc +'_efw_vsvy_V4',data=v4
     get_data,'rbsp'+sc +'_efw_vsvy_V5',data=v5
     get_data,'rbsp'+sc +'_efw_vsvy_V6',data=v6

     sum12 = (v1.y + v2.y)/2.	
     sum34 = (v3.y + v4.y)/2.	
     sum56 = (v5.y + v6.y)/2.	

     sum56[*] = -1.0E31
     
     store_data,'sum12',data={x:v1.x,y:sum12}
     tinterpol_mxn,'sum12',times,newname='sum12'
     get_data,'sum12',data=sum12
     sum12=sum12.y

     store_data,'sum34',data={x:v3.x,y:sum34}
     tinterpol_mxn,'sum34',times,newname='sum34'
     get_data,'sum34',data=sum34
     sum34=sum34.y



                                ;Interpolate single-ended measurements
                                ;to low cadence for combo file
     tinterpol_mxn,'rbsp'+sc+'_efw_vsvy',times,newname='rbsp'+sc+'_efw_vsvy_combo'
     get_data,'rbsp'+sc+'_efw_vsvy_combo',data=vsvy_spinres
     

;--------------------------------------------------
;Nan out various values when global flag is thrown
;--------------------------------------------------

     ;;density
     tinterpol_mxn,'rbsp'+sc+'_density12',times,newname='rbsp'+sc+'_density12'
     get_data,'rbsp'+sc+'_density12',data=dens12
     goo = where(flag_arr[*,0] eq 1)
     if goo[0] ne -1 and is_struct(dens12) then dens12.y[goo] = -1.e31

     tinterpol_mxn,'rbsp'+sc+'_density34',times,newname='rbsp'+sc+'_density34'
     get_data,'rbsp'+sc+'_density34',data=dens34
     goo = where(flag_arr[*,0] eq 1)
     if goo[0] ne -1 and is_struct(dens34) then dens34.y[goo] = -1.e31



;--------------------------------------------------
;Set a 3D flag variable for the survey plots
;--------------------------------------------------

     ;;charging, autobias and eclipse flags all in one variable for convenience
     flags = [[flag_arr[*,15]],[flag_arr[*,14]],[flag_arr[*,1]]]





     
;the times for the mag spinfit can be slightly different than the times for the
;Esvy spinfit. 
     tinterpol_mxn,'rbsp'+sc+'_mag_mgse',times,newname='rbsp'+sc+'_mag_mgse'
     get_data,'rbsp'+sc+'_mag_mgse',data=mag_mgse


;Downsample the GSE position and velocity variables to cadence of spinfit data
     tinterpol_mxn,'rbsp'+sc+'_E_coro_mgse',times,newname='rbsp'+sc+'_E_coro_mgse'
     tinterpol_mxn,'rbsp'+sc+'_vscxb',times,newname='vxb'
     tinterpol_mxn,'rbsp'+sc+'_state_vel_coro_mgse',times,newname='rbsp'+sc+'_state_vel_coro_mgse'
     tinterpol_mxn,'rbsp'+sc+'_state_pos_gse',times,newname='rbsp'+sc+'_state_pos_gse'
     tinterpol_mxn,'rbsp'+sc+'_state_vel_gse',times,newname='rbsp'+sc+'_state_vel_gse'
     get_data,'vxb',data=vxb
     get_data,'rbsp'+sc+'_state_pos_gse',data=pos_gse
     get_data,'rbsp'+sc+'_state_vel_gse',data=vel_gse
     get_data,'rbsp'+sc+'_E_coro_mgse',data=ecoro_mgse
     get_data,'rbsp'+sc+'_state_vel_coro_mgse',data=vcoro_mgse
     
     tinterpol_mxn,'rbsp'+sc+'_mag_mgse_'+model,times,newname='rbsp'+sc+'_mag_mgse_'+model
     tinterpol_mxn,'rbsp'+sc+'_mag_mgse_t89_dif',times,newname='rbsp'+sc+'_mag_mgse_t89_dif'
     get_data,'rbsp'+sc+'_mag_mgse_'+model,data=mag_model
     get_data,'rbsp'+sc+'_mag_mgse_t89_dif',data=mag_diff

     mag_model_magnitude = sqrt(mag_model.y[*,0]^2 + mag_model.y[*,1]^2 + mag_model.y[*,2]^2)
     mag_data_magnitude = sqrt(mag_mgse.y[*,0]^2 + mag_mgse.y[*,1]^2 + mag_mgse.y[*,2]^2)
     mag_diff_magnitude = mag_data_magnitude - mag_model_magnitude

     tinterpol_mxn,'rbsp'+sc+'_state_mlt',times,newname='rbsp'+sc+'_state_mlt'
     tinterpol_mxn,'rbsp'+sc+'_state_mlat',times,newname='rbsp'+sc+'_state_mlat'
     tinterpol_mxn,'rbsp'+sc+'_state_lshell',times,newname='rbsp'+sc+'_state_lshell'
     tinterpol_mxn,'rbsp'+sc+'_ME_lstar',times,newname='rbsp'+sc+'_ME_lstar'
     tinterpol_mxn,'rbsp'+sc+'_ME_orbitnumber',times,newname='rbsp'+sc+'_ME_orbitnumber'

     get_data,'rbsp'+sc+'_state_mlt',data=mlt
     get_data,'rbsp'+sc+'_state_mlat',data=mlat
     get_data,'rbsp'+sc+'_state_lshell',data=lshell
     get_data,'rbsp'+sc+'_ME_orbitnumber',data=orbit_num
     get_data,'rbsp'+sc+'_ME_lstar',data=lstar
     if is_struct(lstar) then lstar = lstar.y[*,0]

     tinterpol_mxn,'rbsp'+sc+'_spinaxis_direction_gse',times,newname='rbsp'+sc+'_spinaxis_direction_gse'
     get_data,'rbsp'+sc+'_spinaxis_direction_gse',data=sa

     tinterpol_mxn,'angles',times,newname='angles'
     get_data,'angles',data=angles

     

  endif                         ;for skipping processing


  year = strmid(date, 0, 4)
  mm   = strmid(date, 5, 2)
  dd   = strmid(date, 8, 2)

  if type eq 'spinfit' then type2 = 'e-spinfit-mgse'
  if type eq 'spinfit_both_boompairs' then type2 = 'e-spinfit-mgse_both_booms'
  if type eq 'esvy_despun' then type2 = 'esvy_despun'
  if type eq 'vsvy_hires' then type2 = 'vsvy-hires'
  if type eq 'combo' then type2 = 'combo'
  if type eq 'combo_pfaff' then type2 = 'combo_pfaff'
  if type eq 'combo_wygant' then type2 = 'combo_wygant'
  if type eq 'pfaff_esvy' then type2 = 'pfaff_esvy'

  if keyword_set(hires) then $
     datafile = folder + rbx + 'efw-l2_' + type2 + '_' + year + mm + dd + '_v' + vstr + '_hr.cdf' else $
        datafile = folder + rbx + 'efw-l2_' + type2 + '_' + year + mm + dd+ '_v' + vstr + '.cdf'

  file_copy, skeletonFile, datafile, /overwrite ; Force to replace old file.
  cdfid = cdf_open(datafile)



  ;;--------------------------------------------------
  ;;Rename certain CDF variables depending on whether we're
  ;;using the E12 or E34 boom pair
  ;;--------------------------------------------------

  if type ne 'spinfit_both_boompairs' then begin

     if bp eq '12' then begin

        cdf_varrename,cdfid,'efield_spinfit_mgse_e12','efield_spinfit_mgse'
        cdf_varrename,cdfid,'density_v12','density'
        cdf_varrename,cdfid,'efield_spinfit_vxb_edotb_mgse_e12','efield_spinfit_vxb_edotb_mgse'
        cdf_varrename,cdfid,'efield_spinfit_vxb_mgse_e12','efield_spinfit_vxb_mgse'

        cdf_vardelete,cdfid,'efield_spinfit_mgse_e34'
        cdf_vardelete,cdfid,'density_v34'
        cdf_vardelete,cdfid,'efield_spinfit_vxb_edotb_mgse_e34'
        cdf_vardelete,cdfid,'efield_spinfit_vxb_mgse_e34'

     endif else begin

        cdf_varrename,cdfid,'efield_spinfit_mgse_e34','efield_spinfit_mgse'
        cdf_varrename,cdfid,'density_v34','density'
        cdf_varrename,cdfid,'efield_spinfit_vxb_edotb_mgse_e34','efield_spinfit_vxb_edotb_mgse'
        cdf_varrename,cdfid,'efield_spinfit_vxb_mgse_e34','efield_spinfit_vxb_mgse'

        cdf_vardelete,cdfid,'efield_spinfit_mgse_e12'
        cdf_vardelete,cdfid,'density_v12'
        cdf_vardelete,cdfid,'efield_spinfit_vxb_edotb_mgse_e12'
        cdf_vardelete,cdfid,'efield_spinfit_vxb_mgse_e12'

     endelse

  endif


;;--------------------------------------------------
;;spinfit_both_boompairs
;;--------------------------------------------------


  if type eq 'spinfit_both_boompairs' then begin

     cdf_varput,cdfid,'epoch',epoch

     cdf_varrename,cdfid,'efw_qual','flags_all'
     cdf_varrename,cdfid,'e12_vxb_coro_spinfit_mgse','efield_spinfit_vxb_coro_e12'
     cdf_varrename,cdfid,'e34_vxb_coro_spinfit_mgse','efield_spinfit_vxb_coro_e34'
     
     ;;Remove the highcadence version and rename the lowcadence one to vsvy_vavg
     cdf_vardelete,cdfid,'vsvy_vavg'
     cdf_varrename,cdfid,'vsvy_vavg_lowcadence','vsvy_vavg'

     cdf_varput,cdfid,'flags_charging_bias_eclipse',transpose(flags)
     cdf_varput,cdfid,'flags_all',transpose(flag_arr)

     cdf_varput,cdfid,'efield_spinfit_vxb_edotb_mgse_e12',transpose(spinfit_vxb_edotb_12)
     cdf_varput,cdfid,'efield_spinfit_vxb_edotb_mgse_e34',transpose(spinfit_vxb_edotb_34)
     if is_struct(dens12) then cdf_varput,cdfid,'density_v12',dens12.y
     if is_struct(dens34) then cdf_varput,cdfid,'density_v34',dens34.y

     cdf_varput,cdfid,'vsvy_vavg',transpose([[sum12],[sum34],[sum56]])
     cdf_varput,cdfid,'VxB_mgse',transpose(vxb.y)

     cdf_varput,cdfid,'efield_coro_mgse',transpose(ecoro_mgse.y)
     cdf_varput,cdfid,'mlt',reform(mlt.y)
     cdf_varput,cdfid,'mlat',reform(mlat.y)
     cdf_varput,cdfid,'lshell',reform(lshell.y)
     cdf_varput,cdfid,'pos_gse',transpose(pos_gse.y)
     cdf_varput,cdfid,'vel_gse',transpose(vel_gse.y)
     cdf_varput,cdfid,'spinaxis_gse',transpose(sa.y)
     cdf_varput,cdfid,'orbit_num',orbit_num.y
     cdf_varput,cdfid,'angle_Ey_Ez_Bo',transpose(angles.y)
     cdf_varput,cdfid,'bias_current',transpose(ibias)





;variables to delete
     cdf_vardelete,cdfid,'e_spinfit_mgse_efw_qual'
     ;; cdf_vardelete,cdfid,'efw_qual'
     cdf_vardelete,cdfid,'Lstar'
     cdf_vardelete,cdfid,'efield_spinfit_mgse_e12'
     cdf_vardelete,cdfid,'efield_spinfit_mgse_e34'
     cdf_vardelete,cdfid,'efield_spinfit_vxb_mgse_e12'
     cdf_vardelete,cdfid,'efield_spinfit_vxb_mgse_e34'
     cdf_vardelete,cdfid,'efield_spinfit_vxb_coro_e12'
     cdf_vardelete,cdfid,'efield_spinfit_vxb_coro_e34'

     cdf_vardelete,cdfid,'e_spinfit_mgse_BEB_config'
     cdf_vardelete,cdfid,'e_spinfit_mgse_DFB_config'
     cdf_vardelete,cdfid,'sigma12_spinfit_mgse'
     cdf_vardelete,cdfid,'sigma34_spinfit_mgse'
     cdf_vardelete,cdfid,'npoints12_spinfit_mgse'
     cdf_vardelete,cdfid,'npoints34_spinfit_mgse'
     cdf_vardelete,cdfid,'efield_uvw'
     cdf_vardelete,cdfid,'efield_raw_uvw'
;     cdf_vardelete,cdfid,'density'
     cdf_vardelete,cdfid,'bfield_mgse'
     cdf_vardelete,cdfid,'bfield_model_mgse'
     cdf_vardelete,cdfid,'bfield_minus_model_mgse'
     cdf_vardelete,cdfid,'bfield_magnitude_minus_modelmagnitude'
 ;    cdf_vardelete,cdfid,'efield_spinfit_vxb_edotb_mgse'
     cdf_vardelete,cdfid,'bfield_magnitude'
     cdf_vardelete,cdfid,'magnitude_minus_modelmagnitude'
     cdf_vardelete,cdfid,'vsvy'
     cdf_vardelete,cdfid,'esvy'

     cdf_vardelete,cdfid,'vsvy_vavg_combo'
     cdf_vardelete,cdfid,'mag_model_mgse'
     cdf_vardelete,cdfid,'mag_minus_model_mgse'
     cdf_vardelete,cdfid,'mag_spinfit_mgse'
;     cdf_vardelete,cdfid,'efield_spinfit_vxb_mgse'
     cdf_vardelete,cdfid,'vel_coro_mgse'
     cdf_vardelete,cdfid,'esvy_vxb_mgse'
     cdf_vardelete,cdfid,'efield_mgse'
     cdf_vardelete,cdfid,'vsvy_combo'

     cdf_vardelete,cdfid,'e12_spinfit_mgse'
     cdf_vardelete,cdfid,'e34_spinfit_mgse'
     cdf_vardelete,cdfid,'e12_vxb_spinfit_mgse'
     cdf_vardelete,cdfid,'e34_vxb_spinfit_mgse'
  ;   cdf_vardelete,cdfid,'e12_vxb_coro_spinfit_mgse'
  ;   cdf_vardelete,cdfid,'e34_vxb_coro_spinfit_mgse'

  endif



;--------------------------------------------------
;spinfit E12 files
;--------------------------------------------------


  if type eq 'spinfit' then begin

     cdf_varput,cdfid,'epoch',epoch

                                ;spinfit resolution
     cdf_varput,cdfid,'flags_charging_bias_eclipse',transpose(flags)
     cdf_varput,cdfid,'efield_spinfit_mgse',transpose(spinfit_vxb)
     cdf_varput,cdfid,'VxB_mgse',transpose(vxb.y)
     cdf_varput,cdfid,'e_spinfit_mgse_efw_qual',transpose(flag_arr)
     cdf_varput,cdfid,'efield_coro_mgse',transpose(ecoro_mgse.y)
     cdf_varput,cdfid,'mlt',transpose(mlt.y)
     cdf_varput,cdfid,'mlat',transpose(mlat.y)
     cdf_varput,cdfid,'lshell',transpose(lshell.y)
     cdf_varput,cdfid,'pos_gse',transpose(pos_gse.y)
     cdf_varput,cdfid,'vel_gse',transpose(vel_gse.y)
     cdf_varput,cdfid,'spinaxis_gse',transpose(sa.y)
     cdf_varput,cdfid,'orbit_num',orbit_num.y
     cdf_varput,cdfid,'Lstar',lstar
     cdf_varput,cdfid,'angle_Ey_Ez_Bo',transpose(angles.y)
     cdf_varput,cdfid,'bias_current',transpose(ibias)



;variables to delete
     cdf_vardelete,cdfid,'e_spinfit_mgse_BEB_config'
     cdf_vardelete,cdfid,'e_spinfit_mgse_DFB_config'
     cdf_vardelete,cdfid,'sigma12_spinfit_mgse'
     cdf_vardelete,cdfid,'sigma34_spinfit_mgse'
     cdf_vardelete,cdfid,'npoints12_spinfit_mgse'
     cdf_vardelete,cdfid,'npoints34_spinfit_mgse'
     cdf_vardelete,cdfid,'efield_uvw'
     cdf_vardelete,cdfid,'efield_raw_uvw'
     cdf_vardelete,cdfid,'density'
     cdf_vardelete,cdfid,'bfield_mgse'
     cdf_vardelete,cdfid,'bfield_model_mgse'
     cdf_vardelete,cdfid,'bfield_minus_model_mgse'
     cdf_vardelete,cdfid,'bfield_magnitude_minus_modelmagnitude'
     cdf_vardelete,cdfid,'efield_spinfit_vxb_edotb_mgse'
     cdf_vardelete,cdfid,'bfield_magnitude'
     cdf_vardelete,cdfid,'magnitude_minus_modelmagnitude'
     cdf_vardelete,cdfid,'vsvy'
     cdf_vardelete,cdfid,'esvy'
     cdf_vardelete,cdfid,'vsvy_vavg'
     cdf_vardelete,cdfid,'vsvy_vavg_combo'
     cdf_vardelete,cdfid,'efw_qual'
     cdf_vardelete,cdfid,'e12_spinfit_mgse'
     cdf_vardelete,cdfid,'e34_spinfit_mgse'
     cdf_vardelete,cdfid,'mag_model_mgse'
     cdf_vardelete,cdfid,'mag_minus_model_mgse'
     cdf_vardelete,cdfid,'mag_spinfit_mgse'
     cdf_vardelete,cdfid,'efield_spinfit_vxb_mgse'
     cdf_vardelete,cdfid,'e12_vxb_spinfit_mgse'
     cdf_vardelete,cdfid,'e34_vxb_spinfit_mgse'
     cdf_vardelete,cdfid,'vel_coro_mgse'
     cdf_vardelete,cdfid,'esvy_vxb_mgse'
     cdf_vardelete,cdfid,'efield_mgse'
     cdf_vardelete,cdfid,'e12_vxb_coro_spinfit_mgse'
     cdf_vardelete,cdfid,'e34_vxb_coro_spinfit_mgse'
     cdf_vardelete,cdfid,'vsvy_combo'


  endif


;--------------------------------------------------
;Combo files
;--------------------------------------------------


  if type eq 'combo' then begin


     cdf_varput,cdfid,'epoch',epoch
     cdf_varput,cdfid,'epoch_e',epoch_e


;spinfit cadence
     cdf_varput,cdfid,'flags_charging_bias_eclipse',transpose(flags)
     cdf_varput,cdfid,'vsvy_combo',transpose(vsvy_spinres.y)
     cdf_varput,cdfid,'vsvy_vavg_combo',sum12
     cdf_varput,cdfid,'efw_qual',transpose(flag_arr)
     cdf_varput,cdfid,'mag_model_mgse',transpose(mag_model.y)    
     cdf_varput,cdfid,'mag_minus_model_mgse',transpose(mag_diff.y) 
     cdf_varput,cdfid,'magnitude_minus_modelmagnitude',mag_diff_magnitude
     cdf_varput,cdfid,'mag_spinfit_mgse',transpose(mag_mgse.y)
     if bp eq '12' then cdf_varput,cdfid,'e12_vxb_spinfit_mgse',transpose(spinfit_vxb) 
     if bp eq '34' then cdf_varput,cdfid,'e34_vxb_spinfit_mgse',transpose(spinfit_vxb) 
     if bp eq '12' then cdf_varput,cdfid,'density',dens12.y
     if bp eq '34' then cdf_varput,cdfid,'density',dens34.y
     cdf_varput,cdfid,'mlt',transpose(mlt.y)
     cdf_varput,cdfid,'mlat',transpose(mlat.y)
     cdf_varput,cdfid,'lshell',transpose(lshell.y)
     cdf_varput,cdfid,'pos_gse',transpose(pos_gse.y)
     cdf_varput,cdfid,'vel_gse',transpose(vel_gse.y)
     cdf_varput,cdfid,'spinaxis_gse',transpose(sa.y)
     cdf_varput,cdfid,'orbit_num',orbit_num.y
     cdf_varput,cdfid,'Lstar',lstar
     cdf_varput,cdfid,'angle_Ey_Ez_Bo',transpose(angles.y)
     cdf_varput,cdfid,'bias_current',transpose(ibias)



;full cadence (only for hires version)
     if keyword_set(hires) then cdf_varput,cdfid,'esvy_vxb_mgse',transpose(esvy_vxb_mgse.y)
;     if keyword_set(hires) then cdf_varput,cdfid,'esvy',transpose(esvy_vxb_mgse.y)


;variables to delete
     if bp eq '12' then cdf_vardelete,cdfid,'e34_vxb_spinfit_mgse'
     if bp eq '34' then cdf_vardelete,cdfid,'e12_vxb_spinfit_mgse'
     cdf_vardelete,cdfid,'e12_spinfit_mgse'
     cdf_vardelete,cdfid,'e34_spinfit_mgse'
     cdf_vardelete,cdfid,'efield_spinfit_mgse'
     cdf_vardelete,cdfid,'VxB_mgse'
     cdf_vardelete,cdfid,'e_spinfit_mgse_BEB_config'
     cdf_vardelete,cdfid,'e_spinfit_mgse_DFB_config'
     cdf_vardelete,cdfid,'e_spinfit_mgse_efw_qual'
     cdf_vardelete,cdfid,'sigma12_spinfit_mgse'
     cdf_vardelete,cdfid,'sigma34_spinfit_mgse'
     cdf_vardelete,cdfid,'npoints12_spinfit_mgse'
     cdf_vardelete,cdfid,'npoints34_spinfit_mgse'
     cdf_vardelete,cdfid,'efield_coro_mgse'
     cdf_vardelete,cdfid,'efield_uvw'
     cdf_vardelete,cdfid,'efield_raw_uvw'
     cdf_vardelete,cdfid,'bfield_mgse'
     cdf_vardelete,cdfid,'bfield_model_mgse'
     cdf_vardelete,cdfid,'bfield_minus_model_mgse'
     cdf_vardelete,cdfid,'bfield_magnitude_minus_modelmagnitude'
     cdf_vardelete,cdfid,'efield_spinfit_vxb_edotb_mgse'
     cdf_vardelete,cdfid,'bfield_magnitude'
     cdf_vardelete,cdfid,'efield_spinfit_vxb_mgse'
     cdf_vardelete,cdfid,'vel_coro_mgse'
     cdf_vardelete,cdfid,'efield_mgse'
     cdf_vardelete,cdfid,'vsvy_vavg'
     cdf_vardelete,cdfid,'vsvy'
     cdf_vardelete,cdfid,'esvy'
     cdf_vardelete,cdfid,'e12_vxb_coro_spinfit_mgse'
     cdf_vardelete,cdfid,'e34_vxb_coro_spinfit_mgse'
     if ~keyword_set(hires) then cdf_vardelete,cdfid,'esvy_vxb_mgse'

  endif

;--------------------------------------------------
;esvy despun files
;--------------------------------------------------

  if type eq 'esvy_despun' then begin

     cdf_varput,cdfid,'epoch',epoch
     cdf_varput,cdfid,'epoch_e',epoch_e


;spinfit resolution
     cdf_varput,cdfid,'flags_charging_bias_eclipse',transpose(flags)
     cdf_varput,cdfid,'efw_qual',transpose(flag_arr)
     cdf_varput,cdfid,'mlt',transpose(mlt.y)
     cdf_varput,cdfid,'mlat',transpose(mlat.y)
     cdf_varput,cdfid,'lshell',transpose(lshell.y)
     cdf_varput,cdfid,'pos_gse',transpose(pos_gse.y)
     cdf_varput,cdfid,'vel_gse',transpose(vel_gse.y)
     cdf_varput,cdfid,'spinaxis_gse',transpose(sa.y)
     cdf_varput,cdfid,'orbit_num',orbit_num.y
     cdf_varput,cdfid,'Lstar',lstar
     cdf_varput,cdfid,'angle_Ey_Ez_Bo',transpose(angles.y)
     cdf_varput,cdfid,'bias_current',transpose(ibias)



;full resolution
     cdf_varput,cdfid,'efield_mgse',transpose(esvy_mgse.y)



;variables to delete
     cdf_vardelete,cdfid,'efield_spinfit_mgse'
     cdf_vardelete,cdfid,'VxB_mgse'
     cdf_vardelete,cdfid,'e_spinfit_mgse_BEB_config'
     cdf_vardelete,cdfid,'e_spinfit_mgse_DFB_config'
     cdf_vardelete,cdfid,'e_spinfit_mgse_efw_qual'
     cdf_vardelete,cdfid,'sigma12_spinfit_mgse'
     cdf_vardelete,cdfid,'sigma34_spinfit_mgse'
     cdf_vardelete,cdfid,'npoints12_spinfit_mgse'
     cdf_vardelete,cdfid,'npoints34_spinfit_mgse'
     cdf_vardelete,cdfid,'efield_coro_mgse'
     cdf_vardelete,cdfid,'efield_uvw'
     cdf_vardelete,cdfid,'efield_raw_uvw'
     cdf_vardelete,cdfid,'density'
     cdf_vardelete,cdfid,'bfield_mgse'
     cdf_vardelete,cdfid,'bfield_model_mgse'
     cdf_vardelete,cdfid,'bfield_minus_model_mgse'
     cdf_vardelete,cdfid,'bfield_magnitude_minus_modelmagnitude'
     cdf_vardelete,cdfid,'efield_spinfit_vxb_edotb_mgse'
     cdf_vardelete,cdfid,'bfield_magnitude'
     cdf_vardelete,cdfid,'vsvy'
     cdf_vardelete,cdfid,'esvy'
     cdf_vardelete,cdfid,'vsvy_combo'
     cdf_vardelete,cdfid,'vsvy_vavg'
     cdf_vardelete,cdfid,'vsvy_vavg_combo'
     cdf_vardelete,cdfid,'e12_spinfit_mgse'
     cdf_vardelete,cdfid,'e34_spinfit_mgse'
     cdf_vardelete,cdfid,'mag_model_mgse'
     cdf_vardelete,cdfid,'mag_minus_model_mgse'
     cdf_vardelete,cdfid,'efield_spinfit_vxb_mgse'
     cdf_vardelete,cdfid,'e12_vxb_spinfit_mgse'
     cdf_vardelete,cdfid,'e34_vxb_spinfit_mgse'
     cdf_vardelete,cdfid,'vel_coro_mgse'
     cdf_vardelete,cdfid,'esvy_vxb_mgse'
     cdf_vardelete,cdfid,'magnitude_minus_modelmagnitude'
     cdf_vardelete,cdfid,'mag_spinfit_mgse'
     cdf_vardelete,cdfid,'e12_vxb_coro_spinfit_mgse'
     cdf_vardelete,cdfid,'e34_vxb_coro_spinfit_mgse'
     
  endif



;--------------------------------------------------
;vsvy-hires files
;--------------------------------------------------

  if type eq 'vsvy_hires' then begin

     cdf_varput,cdfid,'epoch',epoch
     cdf_varput,cdfid,'epoch_v',epoch_v

;spinfit resolution
     cdf_varput,cdfid,'flags_charging_bias_eclipse',transpose(flags)
     cdf_varput,cdfid,'efw_qual',transpose(flag_arr)
     cdf_varput,cdfid,'mlt',transpose(mlt.y)
     cdf_varput,cdfid,'mlat',transpose(mlat.y)
     cdf_varput,cdfid,'lshell',transpose(lshell.y)
     cdf_varput,cdfid,'pos_gse',transpose(pos_gse.y)
     cdf_varput,cdfid,'vel_gse',transpose(vel_gse.y)
     cdf_varput,cdfid,'spinaxis_gse',transpose(sa.y)
     cdf_varput,cdfid,'orbit_num',orbit_num.y
     cdf_varput,cdfid,'Lstar',lstar
     cdf_varput,cdfid,'angle_Ey_Ez_Bo',transpose(angles.y)
     cdf_varput,cdfid,'bias_current',transpose(ibias)



;full resolution
     cdf_varput,cdfid,'vsvy',transpose(vsvy.y)
     cdf_varput,cdfid,'vsvy_vavg',transpose(vsvy_vavg)


;variables to delete
     cdf_vardelete,cdfid,'efield_spinfit_mgse'
     cdf_vardelete,cdfid,'VxB_mgse'
     cdf_vardelete,cdfid,'e_spinfit_mgse_BEB_config'
     cdf_vardelete,cdfid,'e_spinfit_mgse_DFB_config'
     cdf_vardelete,cdfid,'e_spinfit_mgse_efw_qual'
     cdf_vardelete,cdfid,'sigma12_spinfit_mgse'
     cdf_vardelete,cdfid,'sigma34_spinfit_mgse'
     cdf_vardelete,cdfid,'npoints12_spinfit_mgse'
     cdf_vardelete,cdfid,'npoints34_spinfit_mgse'
     cdf_vardelete,cdfid,'efield_coro_mgse'
     cdf_vardelete,cdfid,'efield_uvw'
     cdf_vardelete,cdfid,'efield_raw_uvw'
     cdf_vardelete,cdfid,'density'
     cdf_vardelete,cdfid,'bfield_mgse'
     cdf_vardelete,cdfid,'bfield_model_mgse'
     cdf_vardelete,cdfid,'bfield_minus_model_mgse'
     cdf_vardelete,cdfid,'bfield_magnitude_minus_modelmagnitude'
     cdf_vardelete,cdfid,'efield_spinfit_vxb_edotb_mgse'
     cdf_vardelete,cdfid,'bfield_magnitude'
     cdf_vardelete,cdfid,'e12_spinfit_mgse'
     cdf_vardelete,cdfid,'e34_spinfit_mgse'
     cdf_vardelete,cdfid,'vsvy_vavg_combo'
     cdf_vardelete,cdfid,'vsvy_combo'
     cdf_vardelete,cdfid,'mag_model_mgse'
     cdf_vardelete,cdfid,'mag_minus_model_mgse'
     cdf_vardelete,cdfid,'efield_spinfit_vxb_mgse'
     cdf_vardelete,cdfid,'e12_vxb_spinfit_mgse'
     cdf_vardelete,cdfid,'e34_vxb_spinfit_mgse'
     cdf_vardelete,cdfid,'vel_coro_mgse'
     cdf_vardelete,cdfid,'esvy_vxb_mgse'
     cdf_vardelete,cdfid,'magnitude_minus_modelmagnitude'
     cdf_vardelete,cdfid,'mag_spinfit_mgse'
     cdf_vardelete,cdfid,'efield_mgse'
     cdf_vardelete,cdfid,'e12_vxb_coro_spinfit_mgse'
     cdf_vardelete,cdfid,'e34_vxb_coro_spinfit_mgse'
     cdf_vardelete,cdfid,'esvy'

  endif


;--------------------------------------------------
;Wygant combo files
;--------------------------------------------------

  if type eq 'combo_wygant' then begin

     cdf_varput,cdfid,'epoch',epoch


;spinfit resolution
     cdf_varput,cdfid,'efw_qual',transpose(flag_arr)
     cdf_varput,cdfid,'flags_charging_bias_eclipse',transpose(flags)
     if bp eq '12' then cdf_varput,cdfid,'e12_vxb_spinfit_mgse',transpose(spinfit_vxb)   
     if bp eq '34' then cdf_varput,cdfid,'e34_vxb_spinfit_mgse',transpose(spinfit_vxb)   
     if bp eq '12' then cdf_varput,cdfid,'e12_vxb_coro_spinfit_mgse',transpose(spinfit_vxb_coro) 
     if bp eq '34' then cdf_varput,cdfid,'e34_vxb_coro_spinfit_mgse',transpose(spinfit_vxb_coro) 
     if bp eq '12' then cdf_varput,cdfid,'density',dens12.y
     if bp eq '34' then cdf_varput,cdfid,'density',dens34.y
     cdf_varput,cdfid,'efield_coro_mgse',transpose(ecoro_mgse.y)
     cdf_varput,cdfid,'vel_coro_mgse',transpose(vcoro_mgse.y)
     cdf_varput,cdfid,'spinaxis_gse',transpose(sa.y)
     cdf_varput,cdfid,'mlt',transpose(mlt.y)
     cdf_varput,cdfid,'mlat',transpose(mlat.y)
     cdf_varput,cdfid,'lshell',transpose(lshell.y)
     cdf_varput,cdfid,'pos_gse',transpose(pos_gse.y)
     cdf_varput,cdfid,'vel_gse',transpose(vel_gse.y)
     cdf_varput,cdfid,'spinaxis_gse',transpose(sa.y)
     cdf_varput,cdfid,'orbit_num',orbit_num.y
     cdf_varput,cdfid,'Lstar',lstar
     cdf_varput,cdfid,'angle_Ey_Ez_Bo',transpose(angles.y)
     cdf_varput,cdfid,'bias_current',transpose(ibias)


;variables to delete
     if bp eq '12' then cdf_vardelete,cdfid,'e34_vxb_spinfit_mgse'
     if bp eq '34' then cdf_vardelete,cdfid,'e12_vxb_spinfit_mgse'
     if bp eq '12' then cdf_vardelete,cdfid,'e34_vxb_coro_spinfit_mgse'
     if bp eq '34' then cdf_vardelete,cdfid,'e12_vxb_coro_spinfit_mgse'
     cdf_vardelete,cdfid,'e12_spinfit_mgse'
     cdf_vardelete,cdfid,'e34_spinfit_mgse'
     cdf_vardelete,cdfid,'efield_spinfit_mgse'
     cdf_vardelete,cdfid,'VxB_mgse'
     cdf_vardelete,cdfid,'e_spinfit_mgse_BEB_config'
     cdf_vardelete,cdfid,'e_spinfit_mgse_DFB_config'
     cdf_vardelete,cdfid,'e_spinfit_mgse_efw_qual'
     cdf_vardelete,cdfid,'sigma12_spinfit_mgse'
     cdf_vardelete,cdfid,'sigma34_spinfit_mgse'
     cdf_vardelete,cdfid,'npoints12_spinfit_mgse'
     cdf_vardelete,cdfid,'npoints34_spinfit_mgse'
     cdf_vardelete,cdfid,'efield_uvw'
     cdf_vardelete,cdfid,'efield_raw_uvw'
     cdf_vardelete,cdfid,'bfield_mgse'
     cdf_vardelete,cdfid,'bfield_model_mgse'
     cdf_vardelete,cdfid,'bfield_minus_model_mgse'
     cdf_vardelete,cdfid,'bfield_magnitude_minus_modelmagnitude'
     cdf_vardelete,cdfid,'efield_spinfit_vxb_edotb_mgse'
     cdf_vardelete,cdfid,'bfield_magnitude'
     cdf_vardelete,cdfid,'vsvy'
     cdf_vardelete,cdfid,'esvy'
     cdf_vardelete,cdfid,'vsvy_vavg'
     cdf_vardelete,cdfid,'vsvy_vavg_combo'
     cdf_vardelete,cdfid,'vsvy_combo'
     cdf_vardelete,cdfid,'mag_model_mgse'
     cdf_vardelete,cdfid,'mag_minus_model_mgse'
     cdf_vardelete,cdfid,'efield_spinfit_vxb_mgse'
     cdf_vardelete,cdfid,'esvy_vxb_mgse'
     cdf_vardelete,cdfid,'magnitude_minus_modelmagnitude'
     cdf_vardelete,cdfid,'mag_spinfit_mgse'
     cdf_vardelete,cdfid,'efield_mgse'

  endif

;--------------------------------------------------
;Pfaff esvy files
;--------------------------------------------------

  if type eq 'pfaff_esvy' then begin

     cdf_varput,cdfid,'epoch',epoch
     cdf_varput,cdfid,'epoch_v',epoch_v

;spinfit cadence
     cdf_varput,cdfid,'efw_qual',transpose(flag_arr)
     cdf_varput,cdfid,'flags_charging_bias_eclipse',transpose(flags)
     cdf_varput,cdfid,'spinaxis_gse',transpose(sa.y)
     cdf_varput,cdfid,'mlt',transpose(mlt.y)
     cdf_varput,cdfid,'mlat',transpose(mlat.y)
     cdf_varput,cdfid,'lshell',transpose(lshell.y)
     cdf_varput,cdfid,'pos_gse',transpose(pos_gse.y)
     cdf_varput,cdfid,'vel_gse',transpose(vel_gse.y)
     cdf_varput,cdfid,'spinaxis_gse',transpose(sa.y)
     cdf_varput,cdfid,'orbit_num',orbit_num.y
     cdf_varput,cdfid,'Lstar',lstar
     cdf_varput,cdfid,'angle_Ey_Ez_Bo',transpose(angles.y)
     cdf_varput,cdfid,'bias_current',transpose(ibias)


;full cadence
     cdf_varput,cdfid,'esvy',transpose(esvy_v.y) ;on vsvy cadence
     cdf_varput,cdfid,'vsvy',transpose(vsvy.y)


;variables to delete
     cdf_vardelete,cdfid,'efield_spinfit_mgse'
     cdf_vardelete,cdfid,'VxB_mgse'
     cdf_vardelete,cdfid,'e_spinfit_mgse_BEB_config'
     cdf_vardelete,cdfid,'e_spinfit_mgse_DFB_config'
     cdf_vardelete,cdfid,'e_spinfit_mgse_efw_qual'
     cdf_vardelete,cdfid,'sigma12_spinfit_mgse'
     cdf_vardelete,cdfid,'sigma34_spinfit_mgse'
     cdf_vardelete,cdfid,'npoints12_spinfit_mgse'
     cdf_vardelete,cdfid,'npoints34_spinfit_mgse'
     cdf_vardelete,cdfid,'efield_coro_mgse'
     cdf_vardelete,cdfid,'efield_uvw'
     cdf_vardelete,cdfid,'efield_raw_uvw'
     cdf_vardelete,cdfid,'density'
     cdf_vardelete,cdfid,'bfield_mgse'
     cdf_vardelete,cdfid,'bfield_model_mgse'
     cdf_vardelete,cdfid,'bfield_minus_model_mgse'
     cdf_vardelete,cdfid,'bfield_magnitude_minus_modelmagnitude'
     cdf_vardelete,cdfid,'efield_spinfit_vxb_edotb_mgse'
     cdf_vardelete,cdfid,'bfield_magnitude'
     cdf_vardelete,cdfid,'esvy'
     cdf_vardelete,cdfid,'vsvy_combo'
     cdf_vardelete,cdfid,'vsvy_vavg'
     cdf_vardelete,cdfid,'vsvy_vavg_combo'
     cdf_vardelete,cdfid,'e12_spinfit_mgse'
     cdf_vardelete,cdfid,'e34_spinfit_mgse'
     cdf_vardelete,cdfid,'mag_model_mgse'
     cdf_vardelete,cdfid,'mag_minus_model_mgse'
     cdf_vardelete,cdfid,'efield_spinfit_vxb_mgse'
     cdf_vardelete,cdfid,'e12_vxb_spinfit_mgse'
     cdf_vardelete,cdfid,'e34_vxb_spinfit_mgse'
     cdf_vardelete,cdfid,'vel_coro_mgse'
     cdf_vardelete,cdfid,'esvy_vxb_mgse'
     cdf_vardelete,cdfid,'magnitude_minus_modelmagnitude'
     cdf_vardelete,cdfid,'mag_spinfit_mgse'
     cdf_vardelete,cdfid,'efield_mgse'
     cdf_vardelete,cdfid,'e12_vxb_coro_spinfit_mgse'
     cdf_vardelete,cdfid,'e34_vxb_coro_spinfit_mgse'

  endif

;--------------------------------------------------
;Pfaff combo files
;--------------------------------------------------

  if type eq 'combo_pfaff' then begin

     cdf_varput,cdfid,'epoch',epoch
     if keyword_set(hires) then cdf_varput,cdfid,'epoch_e',epoch_e
     if keyword_set(hires) then cdf_varput,cdfid,'epoch_v',epoch_v

;spinfit cadence
     cdf_varput,cdfid,'efw_qual',transpose(flag_arr)
     cdf_varput,cdfid,'flags_charging_bias_eclipse',transpose(flags)
     if bp eq '12' then cdf_varput,cdfid,'e12_vxb_spinfit_mgse',transpose(spinfit_vxb) 
     if bp eq '34' then cdf_varput,cdfid,'e34_vxb_spinfit_mgse',transpose(spinfit_vxb) 
     if bp eq '12' then cdf_varput,cdfid,'density',dens12.y
     if bp eq '34' then cdf_varput,cdfid,'density',dens34.y
     cdf_varput,cdfid,'efield_coro_mgse',transpose(ecoro_mgse.y)
     cdf_varput,cdfid,'vel_coro_mgse',transpose(vcoro_mgse.y)
     cdf_varput,cdfid,'bfield_mgse',transpose(mag_mgse.y)
     cdf_varput,cdfid,'bfield_model_mgse',transpose(mag_model.y)
     cdf_varput,cdfid,'bfield_minus_model_mgse',transpose(mag_diff.y)
     cdf_varput,cdfid,'bfield_magnitude_minus_modelmagnitude',mag_diff_magnitude
     cdf_varput,cdfid,'mlt',transpose(mlt.y)
     cdf_varput,cdfid,'mlat',transpose(mlat.y)
     cdf_varput,cdfid,'lshell',transpose(lshell.y)
     cdf_varput,cdfid,'pos_gse',transpose(pos_gse.y)
     cdf_varput,cdfid,'vel_gse',transpose(vel_gse.y)
     cdf_varput,cdfid,'spinaxis_gse',transpose(sa.y)
     cdf_varput,cdfid,'orbit_num',orbit_num.y
     cdf_varput,cdfid,'Lstar',lstar
     cdf_varput,cdfid,'angle_Ey_Ez_Bo',transpose(angles.y)
     cdf_varput,cdfid,'bias_current',transpose(ibias)
     if ~keyword_set(hires) then cdf_varput,cdfid,'vsvy_combo',transpose(vsvy_spinres.y)
     if ~keyword_set(hires) then cdf_varput,cdfid,'vsvy_vavg_combo',transpose(sum12)

;full cadence
     if keyword_set(hires) then cdf_varput,cdfid,'esvy_vxb_mgse',transpose(esvy_vxb_mgse.y)
     if keyword_set(hires) then cdf_varput,cdfid,'vsvy',transpose(vsvy.y)
     if keyword_set(hires) then cdf_varput,cdfid,'esvy',transpose(esvy_v.y)
     if keyword_set(hires) then cdf_varput,cdfid,'vsvy_vavg',transpose(vsvy_vavg)


;variables to delete
     if bp eq '12' then cdf_vardelete,cdfid,'e34_vxb_spinfit_mgse'
     if bp eq '34' then cdf_vardelete,cdfid,'e12_vxb_spinfit_mgse'
     cdf_vardelete,cdfid,'e12_spinfit_mgse'
     cdf_vardelete,cdfid,'e34_spinfit_mgse'
     cdf_vardelete,cdfid,'efield_spinfit_mgse'
     cdf_vardelete,cdfid,'VxB_mgse'
     cdf_vardelete,cdfid,'e_spinfit_mgse_BEB_config'
     cdf_vardelete,cdfid,'e_spinfit_mgse_DFB_config'
     cdf_vardelete,cdfid,'e_spinfit_mgse_efw_qual'
     cdf_vardelete,cdfid,'sigma12_spinfit_mgse'
     cdf_vardelete,cdfid,'sigma34_spinfit_mgse'
     cdf_vardelete,cdfid,'npoints12_spinfit_mgse'
     cdf_vardelete,cdfid,'npoints34_spinfit_mgse'
     cdf_vardelete,cdfid,'efield_uvw'
     cdf_vardelete,cdfid,'efield_raw_uvw'
     cdf_vardelete,cdfid,'efield_spinfit_vxb_edotb_mgse'
     cdf_vardelete,cdfid,'bfield_magnitude'
     if ~keyword_set(hires) then cdf_vardelete,cdfid,'vsvy'
     if ~keyword_set(hires) then cdf_vardelete,cdfid,'esvy_vxb_mgse'
     if keyword_set(hires) then cdf_vardelete,cdfid,'vsvy_combo'
     if ~keyword_set(hires) then cdf_vardelete,cdfid,'vsvy_vavg'
     if keyword_set(hires) then cdf_vardelete,cdfid,'vsvy_vavg_combo'
     cdf_vardelete,cdfid,'mag_model_mgse'
     cdf_vardelete,cdfid,'mag_minus_model_mgse'
     cdf_vardelete,cdfid,'efield_spinfit_vxb_mgse'
     cdf_vardelete,cdfid,'magnitude_minus_modelmagnitude'
     cdf_vardelete,cdfid,'mag_spinfit_mgse'
     cdf_vardelete,cdfid,'efield_mgse'
     cdf_vardelete,cdfid,'esvy'
     cdf_vardelete,cdfid,'e12_vxb_coro_spinfit_mgse'
     cdf_vardelete,cdfid,'e34_vxb_coro_spinfit_mgse'
     if ~keyword_set(hires) then cdf_vardelete,cdfid,'esvy'
     if ~keyword_set(hires) then cdf_vardelete,cdfid,'esvy_vxb_mgse'
     

  endif

  cdf_close, cdfid


end
