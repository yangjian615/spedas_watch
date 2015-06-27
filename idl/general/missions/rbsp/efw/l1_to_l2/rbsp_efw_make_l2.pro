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
;           'vsvy_hires'   (official L2 product)          (working)
;           'spinfit' (default, official L2 product)      (working)
;           'combo_wygant' (no hires data)                (working)
;           'pfaff_esvy'                                  (working)
;           'combo_pfaff'                                 (working)
;
;
; HISTORY:
;   2014-12-02: Created by Aaron W Breneman, U. Minnesota
;				
;
; VERSION:
; $LastChangedBy: aaronbreneman $
; $LastChangedDate: 2015-06-25 16:50:00 -0700 (Thu, 25 Jun 2015) $
; $LastChangedRevision: 17975 $
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
                     hires=hires


  if ~keyword_set(type) then type = 'spinfit'



  compile_opt idl2

  rbsp_efw_init

  if n_elements(version) eq 0 then version = 1
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
     skeleton='/Volumes/UserA/user_homes/kersten/RBSP_l2/'+rbspx+'_efw-l2_00000000_v01.cdf'


     ;skeletonFile=file_retrieve(skeleton,_extra=!rbsp_efw)



                                ; use skeleton from the staging dir until we go live in the main data tree
                                ;skeletonFile='/Volumes/DataA/user_volumes/kersten/data/rbsp/'+skeleton

     found = 1
                                ; make sure we have the skeleton CDF
     if ~keyword_set(testing) then skeletonFile=file_search(skeleton,count=found) ; looking for single file, so count will return 0 or 1
     if keyword_set(testing) then skeletonfile = '~/Desktop/code/Aaron/RBSP/TDAS_trunk_svn/general/missions/rbsp/efw/l1_to_l2/rbsp'+sc+'_efw-l2_00000000_v01.cdf'


	if ~found then begin
		dprint,'Could not find skeleton CDF, returning.'
		return
	endif
                                ; fix single element source file array
     skeletonFile=skeletonFile[0]

  endif


  if keyword_set(testing) then folder = '~/Desktop/code/Aaron/RBSP/TDAS_trunk_svn/general/missions/rbsp/efw/l1_to_l2/'



;------------ Set up paths. END. ----------------------------




;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$


  skip = 'no'


  if skip eq 'no' then begin




     store_data,tnames(),/delete
     timespan,date
     rbsp_load_spice_kernels


                                ;--------------------------------------------------

     rbsp_load_efw_waveform,probe=sc,type='calibrated',datatype=['vsvy'],/noclean

     get_data,'rbsp'+sc+'_efw_vsvy',data=vsvy
     epoch_v = tplot_time_to_epoch(vsvy.x,/epoch16)
     times_v = vsvy.x

                                ;full resolution (V1+V2)/2
     vsvy_vavg = [[(vsvy.y[*,0] - vsvy.y[*,1])/2.],$
                  [(vsvy.y[*,2] - vsvy.y[*,3])/2.],$
                  [(vsvy.y[*,4] - vsvy.y[*,5])/2.]]
     




                                ;Interpolate data to times. This gives
                                ;nearly the same result as
                                ;downsampling to spinperiod
;     tinterpol_mxn,'rbsp'+sc+'_efw_vsvy',times_v,newname='rbsp'+sc+'_efw_vsvy'

     split_vec, 'rbsp'+sc+'_efw_vsvy', suffix='_V'+['1','2','3','4','5','6']
     get_data,'rbsp'+sc+'_efw_vsvy',data=vsvy

     
     if type eq 'combo' or type eq 'pfaff_esvy' or type eq 'esvy_despun' or type eq 'combo_pfaff' then begin
        rbsp_load_efw_waveform,probe=sc,type='calibrated',datatype=['esvy'],/noclean

        get_data,'rbsp'+sc+'_efw_esvy',data=esvy
        epoch_e = tplot_time_to_epoch(esvy.x,/epoch16)
        times_e = esvy.x

        if type eq 'combo' or type eq 'pfaff_esvy' then begin
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
     rbsp_efw_edotb_to_zero_crib,date,sc,/no_spice_load,/noplot,suffix='edotb'

;Get the official times to which all quantities are interpolated to
     get_data,'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_spinfit',data=tmp
     times = tmp.x
     epoch = tplot_time_to_epoch(times,/epoch16)




;--------------------------------------------------
;save all spinfit resolution Efield quantities
;--------------------------------------------------

     get_data,'rbsp'+sc+'_efw_esvy_spinfit',data=tmp
     if type eq 'spinfit' then tmp.y[*,0] = -1.0E31
     spinfit = tmp.y

                                ;Spinfit with corotation field
     get_data,'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_spinfit',data=tmp
     if type eq 'spinfit' then tmp.y[*,0] = -1.0E31
     spinfit_vxb = tmp.y
                                ;Spinfit with corotation field and E*B=0
     get_data,'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_spinfit_edotb',data=tmp
     if type eq 'spinfit' then tmp.y[*,0] = -1.0E31
     spinfit_vxb_edotb = tmp.y
                                ;Spinfit without corotation field
     get_data,'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_coro_removed_spinfit',data=tmp
     if type eq 'spinfit' then tmp.y[*,0] = -1.0E31
     spinfit_vxb_coro = tmp.y
                                ;Spinfit without corotation field and E*B=0
     get_data,'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_coro_removed_spinfit_edotb',data=tmp
     if type eq 'spinfit' then tmp.y[*,0] = -1.0E31
     spinfit_vxb_coro_edotb = tmp.y


                                ;--------------------------------------------------
                                ;load eclipse times
                                ;--------------------------------------------------

     rbsp_load_eclipse_predict,sc,date,$
                               local_data_dir='~/data/rbsp/',$
                               remote_data_dir='http://themis.ssl.berkeley.edu/data/rbsp/'

     get_data,'rbsp'+sc + '_umbra',data=eu
     get_data,'rbsp'+sc + '_penumbra',data=ep


;--------------------------------------
;SUBTRACT OFF MODEL FIELD
;--------------------------------------

     model = 't89'
     rbsp_efw_DCfield_removal_crib,sc,/no_spice_load,/noplot,model=model
     

;--------------------------
;Density from (V1+V2)/2
;--------------------------

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


                                ;Interpolate single-ended measurements
                                ;to low cadence for combo file
     tinterpol_mxn,'rbsp'+sc+'_efw_vsvy',times,newname='rbsp'+sc+'_efw_vsvy_combo'
     get_data,'rbsp'+sc+'_efw_vsvy_combo',data=vsvy_combo
     


;--------------------------------------------------
;Calculate density and remove bad values
;--------------------------------------------------

     ;;Determine density from sc potential. Remove values when dens < 10 and dens > 3000 cm-3
     store_data,'sc_potential',data={x:times,y:sum12}
     rbsp_efw_density_fit_from_uh_line,'sc_potential',sc,$
                                       newname='rbsp'+sc+'_density',$
                                       dmin=10.,$
                                       dmax=3000.,$
                                       setval=-1.e31

;For density we have a special requirement
;.....Remove when (V1+V2)/2 > -1  AND
;.....Lshell > 4  (avoids hot plasma sheet)
;But, we'll also remove values +/- 10 minutes at start and
;finish of charging times (Scott indicates that this is a good thing
;to do)

     padch = 10.*60.   ;plus/minus time from actual times of charging for triggering the charging flag.
     
     charging_flag = replicate(0.,n_elements(times))
     tinterpol_mxn,'rbsp'+sc+'_state_lshell',times
     get_data,'rbsp'+sc+'_state_lshell_interp',data=lshell

     ;;Find charging times
     pot_tmp = replicate(0.,n_elements(times))
     goo = where((lshell.y gt 4) and (sum12 gt -1))
     if goo[0] ne -1 then pot_tmp[goo] = 1B

     pot_diff = pot_tmp - shift(pot_tmp,1)
     ;; store_data,'pot_diff',data={x:times,y:pot_diff}
     ;; store_data,'Vavg',data={x:times,y:sum12}
     ;; tplot,['pot_diff','rbsp'+sc+'_density','Vavg','rbsp'+sc+'_state_lshell']

     ;;Shift the times...
     boo = where(pot_diff eq 1.)  ;start of charging
     moo = where(pot_diff eq -1.) ;end of charging

     ;;equal number of elements in start and end of charging (usually the case)

     if boo[0] ne -1 and moo[0] ne -1 then begin
        if n_elements(boo) eq n_elements(moo) then begin
           for jj=0,n_elements(boo)-1 do begin
              l0 = times[boo[jj]] - padch
              l1 = times[moo[jj]] + padch
              bad = where((times ge l0) and (times le l1))
              if bad[0] ne -1 then charging_flag[bad] = 1
           endfor
        endif
     endif


     ;;when day ends with charging flag thrown
     if boo[0] ne -1 then begin
        if n_elements(boo) gt n_elements(moo) then begin
           for jj=0,n_elements(boo)-2 do begin
              l0 = times[boo[jj]] - padch
              l1 = times[moo[jj]] + padch
              bad = where((times ge l0) and (times le l1))
              if bad[0] ne -1 then charging_flag[bad] = 1
           endfor
           jj++
           l0 = times[boo[jj]] - padch
           l1 = times[n_elements(times)-1]
           bad = where((times ge l0) and (times le l1))
           if bad[0] ne -1 then charging_flag[bad] = 1
        endif
     endif

     ;; store_data,'charging_flag',data={x:times,y:charging_flag}
     ;; ylim,'charging_flag',-1,2
     ;; tplot,['charging_flag','Vavg']


     get_data,'rbsp'+sc+'_density',data=dens
     goo = where(charging_flag eq 1)
     if goo[0] ne -1 then dens.y[goo] = -1.e31
     


;----------------------------------------------------------------------------------------------------
;FIND AND SET ALL FLAG VALUES
;---------------------------------------------------------------------------------------------------- 

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
     ;;             'autobias',$
     ;;             'charging',$
     ;;             'undefined',$
     ;;             'undefined',$
     ;;             'undefined',$
     ;;             'undefined']


;Load the HSK data to flag the bias sweeps
     rbsp_load_efw_hsk,probe=sc,/get_support_data


                                ;Get flag values
     na_val = -2                ;not applicable value
     fill_val = -1              ;value in flag array that indicates "dunno"
     maxvolts = 195.            ;Max antenna voltage above which the saturation flag is thrown
     offset = 5                 ;position in flag_arr of "v1_saturation" 

     tmp = replicate(0,n_elements(times),6)
     flag_arr = replicate(fill_val,n_elements(times),20)


;Some values we an set right away
     flag_arr[*,9] = 1          ;V5 flag always set
     flag_arr[*,10] = 1         ;V6 flag always set
     flag_arr[*,11] = na_val    ;Espb_magnitude
     flag_arr[*,12] = na_val    ;Eparallel_magnitude
     flag_arr[*,13] = na_val    ;magnetic_wake
     flag_arr[*,16:19] = na_val ;undefined values


;Set flag if antenna potential exceeds max value
     for i=0,5 do begin
        vbad = where(abs(vsvy.y[*,i]) ge maxvolts)
        if vbad[0] ne -1 then tmp[vbad,i] = 1
        flag_arr[*,i+offset] = tmp[*,i]
     endfor

;set the eclipse flag in this program
     padec = 5.*60. ;plus/minus value (sec) outside of the eclipse start and stop times for throwing the eclipse flag

stop

;Umbra
     if is_struct(eu) then begin
        for bb=0,n_elements(eu.x)-1 do begin
           goo = where((vsvy.x ge (eu.x[bb]-padec)) and (vsvy.x le (eu.x[bb]+eu.y[bb]+padec)))
           if goo[0] ne -1 then flag_arr[goo,1] = 1
        endfor
     endif
;Penumbra
     if is_struct(ep) then begin
        for bb=0,n_elements(ep.x)-1 do begin
           goo = where((vsvy.x ge (ep.x[bb]-padec)) and (vsvy.x le (ep.x[bb]+ep.y[bb]+padec)))
           if goo[0] ne -1 then flag_arr[goo,1] = 1
        endfor
     endif





;--------------------------------------------------
;Determine times of antenna deployment
;--------------------------------------------------


     dep = rbsp_efw_boom_deploy_history(date,allvals=av)

     if sc eq 'a' then begin
        ds12 = strmid(av.deploystarta12,0,10)  
        ds34 = strmid(av.deploystarta34,0,10)  
        ds5 = strmid(av.deploystarta5,0,10)  
        ds6 = strmid(av.deploystarta6,0,10)  

        de12 = strmid(av.deployenda12,0,10)  
        de34 = strmid(av.deployenda34,0,10)  
        de5 = strmid(av.deployenda5,0,10)  
        de6 = strmid(av.deployenda6,0,10)  

        deps_alltimes = time_double([av.deploystarta12,av.deploystarta34,av.deploystarta5,av.deploystarta6])
        depe_alltimes = time_double([av.deployenda12,av.deployenda34,av.deployenda5,av.deployenda6])
     endif else begin
        ds12 = strmid(av.deploystartb12,0,10)  
        ds34 = strmid(av.deploystartb34,0,10)  
        ds5 = strmid(av.deploystartb5,0,10)  
        ds6 = strmid(av.deploystartb6,0,10)  

        de12 = strmid(av.deployendb12,0,10)  
        de34 = strmid(av.deployendb34,0,10)  
        de5 = strmid(av.deployendb5,0,10)  
        de6 = strmid(av.deployendb6,0,10)  

        deps_alltimes = time_double([av.deploystartb12,av.deploystartb34,av.deploystartb5,av.deploystartb6])
        depe_alltimes = time_double([av.deployendb12,av.deployendb34,av.deployendb5,av.deployendb6])
     endelse


;all the dates of deployment times (note: all deployments start and
;end on same date)
     dep_alldates = [ds12,ds34,ds5,ds6]

     goo = where(date eq dep_alldates)
     if goo[0] ne -1 then begin
        ;;for each deployment find timerange and flag
        for y=0,n_elements(goo)-1 do begin
           boo = where((times ge deps_alltimes[goo[y]]) and (times le depe_alltimes[goo[y]]))
           if boo[0] ne -1 then flag_arr[boo,4] = 1
        endfor
     endif

;--------------------------------------------------
;Determine maneuver times
;--------------------------------------------------

     m = rbsp_load_maneuver_file(sc,date)
     if is_struct(m) then begin
        for bb=0,n_elements(m.m0)-1 do begin
           goo = where((times ge m.m0[bb]) and (times le m.m1[bb]))
           if goo[0] ne -1 then flag_arr[goo,2] = 1
        endfor
     endif


;--------------------------------------------------
;Determine times of bias sweeps
;--------------------------------------------------


     get_data, 'rbsp'+sc+'_efw_hsk_beb_analog_CONFIG0', data = BEB_config
     if is_struct(BEB_config) then begin
        bias_sweep = intarr(n_elements(BEB_config.x))
        boo = where(BEB_config.y eq 64)
        if boo[0] ne -1 then bias_sweep[boo] = 1
        store_data,'bias_sweep',data={x:BEB_config.x,y:bias_sweep}
        tinterpol_mxn,'bias_sweep',times
        ;; ylim,['bias_sweep','bias_sweep_interp'],0,1.5
        ;; tplot,['bias_sweep','bias_sweep_interp']
        get_data,'bias_sweep_interp',data=bias_sweep
        bias_sweep_flag = bias_sweep.y
     endif else begin
        bias_sweep_flag = replicate(fill_val,n_elements(times))
     endelse


;------------------------------------------------
;ADD AUTO BIAS TO FLAG VALUES
;------------------------------------------------
     
;; AutoBias starts actively controlling the bias currents at V12 = -1.0 V,
;; ramping down the magnitude of the bias current so that when V12 = 0.0 V,
;; the bias current is very near to zero after starting out around -20
;; nA/sensor.

;; For V12 > 0.0 V, the bias current continues to increase (become more
;; positive), although at a slower rate, 0.2 nA/V or something like that.


;Auto Bias flag values. From 'rbsp?_efw_hsk_idpu_fast_TBD'
;Bit	Value	Meaning
;3	8	Toggles off and on every other cycle when AutoBias is;
;		active.
;2	4	One when AutoBias is controlling the bias, Zero when
;		AutoBias is not controlling the bias.
;1	2	One when BIAS3 and BIAS4 can be controlled by AUtoBias,
;		zero otherwise.
;0	1	One when BIAS1 and BIAS2 can be controlled by AUtoBias,
;		zero otherwise.



                                ;Find times when auto biasing is active
     get_data,'rbsp'+sc+'_efw_hsk_idpu_fast_TBD',data=tbd
     tbd.y = floor(tbd.y)
     ab_flag = intarr(n_elements(tbd.x))

                                ;Possible flag values for on and off
     ab_off = [1,2,3,8,10,11]
     ab_on = [4,5,6,7,12,13,14,15]

     goo = where((tbd.y eq 4) or (tbd.y eq 5) or (tbd.y eq 6) or (tbd.y eq 7) or (tbd.y eq 12) or (tbd.y eq 13) or (tbd.y eq 14) or (tbd.y eq 15))
     if goo[0] ne -1 then ab_flag[goo] = 1
     
     store_data,'ab_flag',data={x:tbd.x,y:ab_flag}
     ;; options,['rbsp'+sc+'_efw_hsk_idpu_fast_TBD','ab_flag'],'psym',4
     ;; tplot,['rbsp'+sc+'_efw_hsk_idpu_fast_TBD','ab_flag','rbsp'+sc+'_state_lshell']
     ;; timebar,eu.x
     ;; timebar,eu.x+eu.y


     tinterpol_mxn,'ab_flag',times
     ;; tplot,['ab_flag','ab_flag_interp']

     get_data,'ab_flag_interp',data=ab_flag
     ab_flag = ab_flag.y



;--------------------------------------------------
;ADD IN ACTUAL BIAS CURRENTS
;--------------------------------------------------

     tinterpol_mxn,'rbsp'+sc+'_efw_hsk_beb_analog_IEFI_IBIAS1',times
     tinterpol_mxn,'rbsp'+sc+'_efw_hsk_beb_analog_IEFI_IBIAS2',times
     tinterpol_mxn,'rbsp'+sc+'_efw_hsk_beb_analog_IEFI_IBIAS3',times
     tinterpol_mxn,'rbsp'+sc+'_efw_hsk_beb_analog_IEFI_IBIAS4',times
     tinterpol_mxn,'rbsp'+sc+'_efw_hsk_beb_analog_IEFI_IBIAS5',times
     tinterpol_mxn,'rbsp'+sc+'_efw_hsk_beb_analog_IEFI_IBIAS6',times
;tplot,['*IBIAS*','rbsp'+sc+'_efw_hsk_idpu_fast_TBD']

     get_data,'rbsp'+sc+'_efw_hsk_beb_analog_IEFI_IBIAS1_interp',data=ib1
     get_data,'rbsp'+sc+'_efw_hsk_beb_analog_IEFI_IBIAS2_interp',data=ib2
     get_data,'rbsp'+sc+'_efw_hsk_beb_analog_IEFI_IBIAS3_interp',data=ib3
     get_data,'rbsp'+sc+'_efw_hsk_beb_analog_IEFI_IBIAS4_interp',data=ib4
     get_data,'rbsp'+sc+'_efw_hsk_beb_analog_IEFI_IBIAS5_interp',data=ib5
     get_data,'rbsp'+sc+'_efw_hsk_beb_analog_IEFI_IBIAS6_interp',data=ib6


     ibias = [[ib1.y],[ib2.y],[ib3.y],[ib4.y],[ib5.y],[ib6.y]]




;--------------------------------------------------
;Set individual flags based on above calculated values
;--------------------------------------------------

     flag_arr[*,3] = bias_sweep_flag
     flag_arr[*,14] = ab_flag       ;autobias
     flag_arr[*,15] = charging_flag ;charging
     

;--------------------------------------------------
;Change values of certain arrays that are "fill_val" to 0
;--------------------------------------------------

     goo = where(flag_arr[*,3] eq fill_val) ;bias sweep
     if goo[0] ne -1 then flag_arr[goo,3] = 0

     goo = where(flag_arr[*,4] eq fill_val) ;antenna deploy
     if goo[0] ne -1 then flag_arr[goo,4] = 0

     goo = where(flag_arr[*,14] eq fill_val) ;autobias
     if goo[0] ne -1 then flag_arr[goo,14] = 0

     goo = where(flag_arr[*,15] eq fill_val) ;charging
     if goo[0] ne -1 then flag_arr[goo,15] = 0

     goo = where(flag_arr[*,1] eq fill_val) ;eclipse
     if goo[0] ne -1 then flag_arr[goo,1] = 0

     goo = where(flag_arr[*,2] eq fill_val) ;maneuver
     if goo[0] ne -1 then flag_arr[goo,2] = 0



;--------------------------------------------------
;SET GLOBAL FLAG
;--------------------------------------------------
;Conditions for throwing global flag
;..........any of the v1-v4 saturation flags are thrown
;..........the eclipse flag is thrown
;..........maneuver
;..........charging flag thrown
;..........antenna deploy
;..........bias sweep

     flag_arr[*,0] = 0

     goo = where((flag_arr[*,5] eq 1) or (flag_arr[*,6] eq 1) or (flag_arr[*,7] eq 1) or (flag_arr[*,8] eq 1))
     if goo[0] ne -1 then flag_arr[goo,0] = 1 ;v1-v4 saturation

     goo = where(flag_arr[*,1] eq 1) ;eclipse
     if goo[0] ne -1 then flag_arr[goo,0] = 1

     goo = where(flag_arr[*,15] eq 1) ;charging
     if goo[0] ne -1 then flag_arr[goo,0] = 1

     goo = where(flag_arr[*,3] eq 1) ;bias sweep
     if goo[0] ne -1 then flag_arr[goo,0] = 1
     
     goo = where(flag_arr[*,4] eq 1) ;antenna deploy
     if goo[0] ne -1 then flag_arr[goo,0] = 1

     goo = where(flag_arr[*,2] eq 1) ;maneuver
     if goo[0] ne -1 then flag_arr[goo,0] = 1


;--------------------------------------------------
;Nan out various values when global flag is thrown
;--------------------------------------------------

     ;;density
     goo = where(flag_arr[*,0] eq 1)


stop

     if goo[0] ne -1 then dens.y[goo] = -1.e31


;--------------------------------------------------
;Set a 3D flag variable for the survey plots
;--------------------------------------------------

                                ;charging, autobias and eclipse flags all in one variable for convenience
;     flags = [[flag_arr[*,15]],[flag_arr[*,14]],[flag_arr[*,1]]]





     


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

     get_data,'angles',data=angles

     
     if type eq 'L3' then filename = 'rbsp'+sc+'_efw-l3_'+strjoin(strsplit(date,'-',/extract))+'_v'+vstr+'.cdf'
     if type eq 'hidden' then filename = 'rbsp'+sc+'_efw-l3_'+strjoin(strsplit(date,'-',/extract))+'_v'+vstr+'_hidden.cdf'
     if type eq 'survey' then filename = 'rbsp'+sc+'_efw-l3_'+strjoin(strsplit(date,'-',/extract))+'_v'+vstr+'_survey.cdf'




;Set all globally-flagged data to the ISTP fill_value

     badvs = where(flag_arr[*,0] eq 1)
     if badvs[0] ne -1 then begin

        get_data,rbx+'efw_esvy_mgse_vxb_removed_spinfit',data=dtmp
        newflags = ceil(interpol(flag_arr[*,0],times,dtmp.x))
        goo = where(newflags eq 1)
        if goo[0] ne -1 then dtmp.y[goo,*] = -1.0E31
        store_data,rbx+'efw_esvy_mgse_vxb_removed_spinfit',data=dtmp

     endif


;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

     tplot_save,'*',filename='~/Desktop/l2_test'
     save,filename='~/Desktop/l2_test.idl'


;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$


  endif                         ;for skipping processing






  tplot_restore,filename='~/Desktop/l2_test.tplot'
  restore,'~/Desktop/l2_test.idl'



  year = strmid(date, 0, 4)
  mm   = strmid(date, 5, 2)
  dd   = strmid(date, 8, 2)

  if type eq 'spinfit' then type2 = 'e-spinfit-mgse'
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

;; rbspa_efw-l2_e-spinfit-mgse_20130103_v01.cdf
;; rbspa_efw-l2_esvy_despun_20130105_v01.cdf
;; rbspa_efw-l2_vsvy-hires_20130105_v01.cdf
;; rbspa_efw-l2_combo_20130101_v03_hr.cdf
;; rbspa_efw-l2_combo_20130101_v03.cdf

;; rbspa_efw-l2_combo_pfaff_00000000_v01.cdf
;; rbspa_efw-l2_combo_wygant_00000000_v01.cdf


;  stop

;--------------------------------------------------
;spinfit E12 files
;--------------------------------------------------


  if type eq 'spinfit' then begin

     cdf_varput,cdfid,'epoch',epoch

                                ;spinfit resolution
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
     cdf_vardelete,cdfid,'npoints12_spinfit_mgse'
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
     cdf_vardelete,cdfid,'vsvy_vavg'
     cdf_vardelete,cdfid,'vsvy_vavg_combo'
     cdf_vardelete,cdfid,'efw_qual'
     cdf_vardelete,cdfid,'e12_spinfit_mgse'
     cdf_vardelete,cdfid,'mag_model_mgse'
     cdf_vardelete,cdfid,'mag_minus_model_mgse'
     cdf_vardelete,cdfid,'mag_spinfit_mgse'
     cdf_vardelete,cdfid,'efield_spinfit_vxb_mgse'
     cdf_vardelete,cdfid,'e12_vxb_spinfit_mgse'
     cdf_vardelete,cdfid,'vel_coro_mgse'
     cdf_vardelete,cdfid,'esvy_vxb_mgse'
     cdf_vardelete,cdfid,'efield_mgse'
     cdf_vardelete,cdfid,'e12_vxb_coro_spinfit_mgse'
     cdf_vardelete,cdfid,'vsvy_combo'

  endif


;--------------------------------------------------
;Combo files
;--------------------------------------------------


  if type eq 'combo' then begin


     cdf_varput,cdfid,'epoch',epoch
     cdf_varput,cdfid,'epoch_e',epoch_e


;spinfit cadence
     cdf_varput,cdfid,'vsvy_combo',transpose(vsvy_combo.y)
     cdf_varput,cdfid,'vsvy_vavg_combo',sum12
     cdf_varput,cdfid,'efw_qual',transpose(flag_arr)
     cdf_varput,cdfid,'e12_spinfit_mgse',transpose(spinfit)   
     cdf_varput,cdfid,'mag_model_mgse',transpose(mag_model.y)    
     cdf_varput,cdfid,'mag_minus_model_mgse',transpose(mag_diff.y) 
     cdf_varput,cdfid,'magnitude_minus_modelmagnitude',mag_diff_magnitude
     cdf_varput,cdfid,'mag_spinfit_mgse',transpose(mag_mgse.y)
     cdf_varput,cdfid,'e12_vxb_spinfit_mgse',transpose(spinfit_vxb) 
     cdf_varput,cdfid,'density',dens.y
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
     cdf_vardelete,cdfid,'efield_spinfit_mgse'
     cdf_vardelete,cdfid,'VxB_mgse'
     cdf_vardelete,cdfid,'e_spinfit_mgse_BEB_config'
     cdf_vardelete,cdfid,'e_spinfit_mgse_DFB_config'
     cdf_vardelete,cdfid,'e_spinfit_mgse_efw_qual'
     cdf_vardelete,cdfid,'sigma12_spinfit_mgse'
     cdf_vardelete,cdfid,'npoints12_spinfit_mgse'
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
     if ~keyword_set(hires) then cdf_vardelete,cdfid,'esvy_vxb_mgse'

  endif

;--------------------------------------------------
;esvy despun files
;--------------------------------------------------

  if type eq 'esvy_despun' then begin

     cdf_varput,cdfid,'epoch',epoch
     cdf_varput,cdfid,'epoch_e',epoch_e


;spinfit resolution
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
     cdf_vardelete,cdfid,'npoints12_spinfit_mgse'
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
     cdf_vardelete,cdfid,'vsvy_combo'
     cdf_vardelete,cdfid,'vsvy_vavg'
     cdf_vardelete,cdfid,'vsvy_vavg_combo'
     cdf_vardelete,cdfid,'e12_spinfit_mgse'
     cdf_vardelete,cdfid,'mag_model_mgse'
     cdf_vardelete,cdfid,'mag_minus_model_mgse'
     cdf_vardelete,cdfid,'efield_spinfit_vxb_mgse'
     cdf_vardelete,cdfid,'e12_vxb_spinfit_mgse'
     cdf_vardelete,cdfid,'vel_coro_mgse'
     cdf_vardelete,cdfid,'esvy_vxb_mgse'
     cdf_vardelete,cdfid,'magnitude_minus_modelmagnitude'
     cdf_vardelete,cdfid,'mag_spinfit_mgse'
     cdf_vardelete,cdfid,'e12_vxb_coro_spinfit_mgse'
     

  endif



;--------------------------------------------------
;vsvy-hires files
;--------------------------------------------------

  if type eq 'vsvy_hires' then begin

     cdf_varput,cdfid,'epoch',epoch
     cdf_varput,cdfid,'epoch_v',epoch_v

;spinfit resolution
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
     cdf_vardelete,cdfid,'npoints12_spinfit_mgse'
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
     cdf_vardelete,cdfid,'vsvy_vavg_combo'
     cdf_vardelete,cdfid,'vsvy_combo'
     cdf_vardelete,cdfid,'mag_model_mgse'
     cdf_vardelete,cdfid,'mag_minus_model_mgse'
     cdf_vardelete,cdfid,'efield_spinfit_vxb_mgse'
     cdf_vardelete,cdfid,'e12_vxb_spinfit_mgse'
     cdf_vardelete,cdfid,'vel_coro_mgse'
     cdf_vardelete,cdfid,'esvy_vxb_mgse'
     cdf_vardelete,cdfid,'magnitude_minus_modelmagnitude'
     cdf_vardelete,cdfid,'mag_spinfit_mgse'
     cdf_vardelete,cdfid,'efield_mgse'
     cdf_vardelete,cdfid,'e12_vxb_coro_spinfit_mgse'

  endif


;--------------------------------------------------
;Wygant combo files
;--------------------------------------------------

  if type eq 'combo_wygant' then begin

     cdf_varput,cdfid,'epoch',epoch


;spinfit resolution
     cdf_varput,cdfid,'efw_qual',transpose(flag_arr)
     cdf_varput,cdfid,'e12_spinfit_mgse',transpose(spinfit)           
     cdf_varput,cdfid,'e12_vxb_spinfit_mgse',transpose(spinfit_vxb)   
     cdf_varput,cdfid,'e12_vxb_coro_spinfit_mgse',transpose(spinfit_vxb_coro) 
     cdf_varput,cdfid,'efield_coro_mgse',transpose(ecoro_mgse.y)
     cdf_varput,cdfid,'vel_coro_mgse',transpose(vcoro_mgse.y)
     cdf_varput,cdfid,'density',dens.y
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
     cdf_vardelete,cdfid,'efield_spinfit_mgse'
     cdf_vardelete,cdfid,'VxB_mgse'
     cdf_vardelete,cdfid,'e_spinfit_mgse_BEB_config'
     cdf_vardelete,cdfid,'e_spinfit_mgse_DFB_config'
     cdf_vardelete,cdfid,'e_spinfit_mgse_efw_qual'
     cdf_vardelete,cdfid,'sigma12_spinfit_mgse'
     cdf_vardelete,cdfid,'npoints12_spinfit_mgse'
     cdf_vardelete,cdfid,'efield_uvw'
     cdf_vardelete,cdfid,'efield_raw_uvw'
     cdf_vardelete,cdfid,'bfield_mgse'
     cdf_vardelete,cdfid,'bfield_model_mgse'
     cdf_vardelete,cdfid,'bfield_minus_model_mgse'
     cdf_vardelete,cdfid,'bfield_magnitude_minus_modelmagnitude'
     cdf_vardelete,cdfid,'efield_spinfit_vxb_edotb_mgse'
     cdf_vardelete,cdfid,'bfield_magnitude'
     cdf_vardelete,cdfid,'vsvy'
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
     cdf_vardelete,cdfid,'npoints12_spinfit_mgse'
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
     cdf_vardelete,cdfid,'vsvy_combo'
     cdf_vardelete,cdfid,'vsvy_vavg'
     cdf_vardelete,cdfid,'vsvy_vavg_combo'
     cdf_vardelete,cdfid,'e12_spinfit_mgse'
     cdf_vardelete,cdfid,'mag_model_mgse'
     cdf_vardelete,cdfid,'mag_minus_model_mgse'
     cdf_vardelete,cdfid,'efield_spinfit_vxb_mgse'
     cdf_vardelete,cdfid,'e12_vxb_spinfit_mgse'
     cdf_vardelete,cdfid,'vel_coro_mgse'
     cdf_vardelete,cdfid,'esvy_vxb_mgse'
     cdf_vardelete,cdfid,'magnitude_minus_modelmagnitude'
     cdf_vardelete,cdfid,'mag_spinfit_mgse'
     cdf_vardelete,cdfid,'efield_mgse'
     cdf_vardelete,cdfid,'e12_vxb_coro_spinfit_mgse'

  endif

;--------------------------------------------------
;Pfaff combo files
;--------------------------------------------------

  if type eq 'combo_pfaff' then begin

     cdf_varput,cdfid,'epoch',epoch
     cdf_varput,cdfid,'epoch_e',epoch_e

;spinfit cadence
     cdf_varput,cdfid,'efw_qual',transpose(flag_arr)
     cdf_varput,cdfid,'e12_vxb_spinfit_mgse',transpose(spinfit_vxb) 
     cdf_varput,cdfid,'e12_spinfit_mgse',transpose(spinfit)         
     cdf_varput,cdfid,'efield_coro_mgse',transpose(ecoro_mgse.y)
     cdf_varput,cdfid,'vel_coro_mgse',transpose(vcoro_mgse.y)
     cdf_varput,cdfid,'bfield_mgse',transpose(mag_mgse.y)
     cdf_varput,cdfid,'bfield_model_mgse',transpose(mag_model.y)
     cdf_varput,cdfid,'bfield_minus_model_mgse',transpose(mag_diff.y)
     cdf_varput,cdfid,'bfield_magnitude_minus_modelmagnitude',mag_diff_magnitude
     cdf_varput,cdfid,'density',dens.y
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
     if keyword_set(hires) then cdf_varput,cdfid,'esvy_vxb_mgse',transpose(esvy_vxb_mgse.y)


;variables to delete
     cdf_vardelete,cdfid,'efield_spinfit_mgse'
     cdf_vardelete,cdfid,'VxB_mgse'
     cdf_vardelete,cdfid,'e_spinfit_mgse_BEB_config'
     cdf_vardelete,cdfid,'e_spinfit_mgse_DFB_config'
     cdf_vardelete,cdfid,'e_spinfit_mgse_efw_qual'
     cdf_vardelete,cdfid,'sigma12_spinfit_mgse'
     cdf_vardelete,cdfid,'npoints12_spinfit_mgse'
     cdf_vardelete,cdfid,'efield_uvw'
     cdf_vardelete,cdfid,'efield_raw_uvw'
     cdf_vardelete,cdfid,'efield_spinfit_vxb_edotb_mgse'
     cdf_vardelete,cdfid,'bfield_magnitude'
     cdf_vardelete,cdfid,'vsvy'
     cdf_vardelete,cdfid,'vsvy_combo'
     cdf_vardelete,cdfid,'vsvy_vavg'
     cdf_vardelete,cdfid,'vsvy_vavg_combo'
     cdf_vardelete,cdfid,'mag_model_mgse'
     cdf_vardelete,cdfid,'mag_minus_model_mgse'
     cdf_vardelete,cdfid,'efield_spinfit_vxb_mgse'
     cdf_vardelete,cdfid,'magnitude_minus_modelmagnitude'
     cdf_vardelete,cdfid,'mag_spinfit_mgse'
     cdf_vardelete,cdfid,'efield_mgse'
     cdf_vardelete,cdfid,'e12_vxb_coro_spinfit_mgse'
     if ~keyword_set(hires) then cdf_vardelete,cdfid,'esvy_vxb_mgse'

  endif


;  stop



  cdf_close, cdfid

end
