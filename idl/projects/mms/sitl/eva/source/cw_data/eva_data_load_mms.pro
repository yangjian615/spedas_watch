PRO eva_data_load_mms_options, tpv, ytitle=ytitle,ztitle=ztitle,yrange=yrange,$
  zrange=zrange,ylog=ylog,zlog=zlog,spec=spec,labels=labels,labflag=labflag,$
  colors=colors
  tplot_names,tpv,names=tn
  if n_elements(tn) eq 1 then begin
    options, tpv,'spec',keyword_set(spec)
    if keyword_set(spec) then options,tpv,'no_interp',1
    if n_elements(ylog) eq 1 then options, tpv,'ylog',ylog
    if n_elements(zlog) eq 1 then options, tpv,'zlog',1
    if n_elements(ytitle) eq 1 then options, tpv,'ytitle',ytitle
    if n_elements(ztitle) eq 1 then options, tpv,'ztitle',ztitle
    if n_elements(yrange) eq 2 then ylim, tpv, yrange[0],yrange[1]
    if n_elements(zrange) eq 2 then zlim, tpv, zrange[0],zrange[1]
    if n_elements(labels) gt 0 then options, tpv, labels=labels
    if n_elements(labflag) eq 1 then options,tpv,'labflag',labflag
    if n_elements(colors) gt 0 then options,tpv,'colors',colors
  endif
END

FUNCTION eva_data_load_mms, state
  compile_opt idl2

  catch, error_status; !ERROR_STATE is set 
  if error_status ne 0 then begin
    catch, /cancel; Disable the catch system
    eva_error_message, error_status
    msg = [!Error_State.MSG,' ','...EVA will try to igonore this error.'] 
    ok = dialog_message(msg,/center,/error)
    progressbar -> Destroy
    message, /reset; Clear !ERROR_STATE
    return, answer; 'answer' will be 'Yes', if at least some of the data were succesfully loaded.
  endif
  
  ;--- INITIALIZE ---
  paramlist = strlowcase(state.paramlist_mms); list of parameters read from parameterSet file
  imax = n_elements(paramlist)
  sc_id = state.probelist_mms
  if (size(sc_id[0],/type) ne 7) then return, 'No'; STRING=7
  pmax = n_elements(sc_id)
  if pmax eq 1 then sc = sc_id[0] else sc = sc_id
  ts = str2time(state.start_time)
  te = str2time(state.end_time)
  timespan,state.start_time, te-ts, /seconds
  
  ;--- Count Number of Parameters ---
  cparam = imax*pmax
  if cparam ge 17 then begin
    rst = dialog_message('Total of '+strtrim(string(cparam),2)+' MMS parameters. Still plot?',/question,/center)
  endif else rst = 'Yes'
  if rst eq 'No' then return, 'No'

  ;---- LOAD ----
  progressbar = Obj_New('progressbar', background='white', Text='Loading MMS data ..... 0 %')
  progressbar -> Start
  c = 0
  answer = 'No'
  for p=0,pmax-1 do begin; for each requested probe
    sc = sc_id[p]
    for i=0,imax-1 do begin; for each requested parameter
      
      if progressbar->CheckCancel() then begin
        ok = Dialog_Message('User cancelled operation.',/center) ; Other cleanup, etc. here.
        break
      endif
      
      prg = 100.0*float(c)/float(cparam)
      sprg = 'Loading MMS data ....... '+string(prg,format='(I2)')+' %'
      progressbar -> Update, prg, Text=sprg
      
      ; Check pre-loaded tplot variables. 
      ; Avoid reloading if already exists.
      tplot_names,names=tn
      jmax = n_elements(tn)
      param = sc+strmid(paramlist[i],4,1000)
      if jmax eq 0 then begin; if no pre-loaded variable
        ct = 0
      endif else begin; if pre-loaded variable exists...
        idx = where(strmatch(tn,param),ct); check if param is one of the preloaded variables.
      endelse
      
      if ct eq 0 then begin; if not loaded
        
        ;-----------
        ; FPI
        ;-----------
        if (strmatch(paramlist[i],'*_fpi_*')) then begin
          mms_sitl_get_fpi_basic, sc_id=sc
          tplot_names,'*fpi*',names=tn
          jmax= n_elements(tn)
          if (strlen(tn[0]) gt 0) and (jmax gt 0) then begin
            for j=0,jmax-1 do begin
              get_data,tn[j],data=D,dl=dl,lim=lim
              tn_main = strsplit(tn[j],'_',/extract)
              store_data,strjoin([sc,tn_main[1:*]],'_'),data=D,dl=dl,lim=lim
            endfor
            answer = 'Yes'
          endif
          

        endif
  
        ;-----------
        ; EPD/FEEPS
        ;-----------
        if (strmatch(paramlist[i],'*_feeps_*')) then begin
          mms_load_epd_feeps, sc=sc
          tplot_names,sc+'_epd_feeps_TOP_counts_per_accumulation_sensorID_4',names=tn
          print,'tn=',tn
          jmax = n_elements(tn)
          if jmax eq 1 then begin
            options, sc+'_epd_feeps_TOP_counts_per_accumulation_sensorID_4','ytitle','electrons'
            options, sc+'_epd_feeps_TOP_counts_per_accumulation_sensorID_4','ylog',1
            answer = 'Yes'
          endif
        endif
        
        ;-----------
        ; EPD/EIS
        ;-----------
        if (strmatch(paramlist[i],'*_feeps_*')) then begin
          mms_load_epd_eis, sc=sc
          tplot_names,sc+'_epd_eis_electronenergy_electron_cps_t1',names=tn
          jmax = n_elements(tn)
          if jmax eq 1 then begin
            options, sc+'_epd_eis_electronenergy_electron_cps_t1', 'ytitle', 'electrons'
            options, sc+'_epd_eis_electronenergy_electron_cps_t1', 'ylog', 1
            ylim, sc+'_epd_eis_electronenergy_electron_cps_t1', 0.8, 1e5
            answer = 'Yes'
          endif
        endif

        ;-----------
        ; HPCA
        ;-----------
        level = 'sitl';'l1b'
        if (strmatch(paramlist[i],'*_hpca_*rf_corrected')) then begin
          mms_sitl_get_hpca_basic, sc_id=sc, level=level
          eva_data_load_mms_options, sc+'_hpca_hplus_RF_corrected', ytitle='H+ (eV)',ztitle='eflux',yrange=[1,40000],zrange=[0.1,2000],/spec,/ylog,/zlog
          eva_data_load_mms_options, sc+'_hpca_heplusplus_RF_corrected', ytitle='He++ (eV)',ztitle='eflux',yrange=[1,40000],zrange=[0.1,2000],/spec,/ylog,/zlog
          eva_data_load_mms_options, sc+'_hpca_heplus_RF_corrected', ytitle='He+ (eV)',ztitle='eflux',yrange=[1,40000],zrange=[0.1,2000],/spec,/ylog,/zlog
          eva_data_load_mms_options, sc+'_hpca_oplus_RF_corrected', ytitle='O+ (eV)',ztitle='eflux',yrange=[1,40000],zrange=[0.1,2000],/spec,/ylog,/zlog
          answer = 'Yes'
        endif
        
        if(strmatch(paramlist[i],'*_hpca_*number_density')) or (strmatch(paramlist[i],'*_hpca_*bulk_velocity')) then begin
          mms_sitl_get_hpca_moments, sc_id=sc, level=level
          
          eva_data_load_mms_options, sc+'_hpca_hplus_number_density',ytitle='H!U+!N, cm!U-3!N',/ylog
          eva_data_load_mms_options, sc+'_hpca_aplus_number_density',ytitle='He!U+!U+!N, cm!U-3!N',/ylog
          eva_data_load_mms_options, sc+'_hpca_heplus_number_density',ytitle='He!U+!N, cm!U-3!N',/ylog
          eva_data_load_mms_options, sc+'_hpca_oplus_number_density',ytitle='O!U+!N, cm!U-3!N',/ylog
          
          eva_data_load_mms_options, sc+'_hpca_hplusoplus_number_densities',ytitle='cm!U-3!N',/ylog
          options, sc+'_hpca_hplusoplus_number_densities', colors = [2,4]
          options, sc+'_hpca_hplusoplus_number_densities', labels=['h!U+!N', 'o!U+!N']
          options, sc+'_hpca_hplusoplus_number_densities','labflag',-1
          
          eva_data_load_mms_options, sc+'_hpca_hplus_bulk_velocity',ytitle='H!U+!N km s!U-1!N',ylog=0
          options, sc+'_hpca_hplus_bulk_velocity', colors = [6,4,2]
          options, sc+'_hpca_hplus_bulk_velocity', labels=['V!DX!N', 'V!DY!N', 'V!DZ!N']
          options, sc+'_hpca_hplus_bulk_velocity','labflag',-1
          
          eva_data_load_mms_options, sc+'_hpca_oplus_bulk_velocity',ytitle='O!U+!N km s!U-1!N',ylog=0
          options, sc+'_hpca_oplus_bulk_velocity', colors = [6,4,2]
          options, sc+'_hpca_oplus_bulk_velocity', labels=['V!DX!N', 'V!DY!N', 'V!DZ!N']
          options, sc+'_hpca_oplus_bulk_velocity','labflag',-1
          answer = 'Yes'
        endif


        ;-----------
        ; AFG
        ;-----------
        if (strmatch(paramlist[i],'*_afg*')) then begin
          mms_sitl_get_afg, sc_id=sc;, no_update = no_update, reload = reload
          tplot_names,sc+'_afg_srvy_gsm_dmpa',names=tn
          jmax=n_elements(tn)
          if jmax eq 1 then begin
            eva_cap, sc+'_afg_srvy_gsm_dmpa'
            options, sc+'_afg_srvy_gsm_dmpa', labels=['B!DX!N', 'B!DY!N', 'B!DZ!N','|B|']
            options, sc+'_afg_srvy_gsm_dmpa', 'ytitle', sc+'!CAFG_srvy'
            options, sc+'_afg_srvy_gsm_dmpa', 'ysubtitle', '[nT]'
            options, sc+'_afg_srvy_gsm_dmpa', 'colors',[2,4,6]
            answer = 'Yes'
          endif 
        endif
  
        ;-----------
        ; DFG
        ;-----------
        if (strmatch(paramlist[i],'*_dfg*')) then begin
          mms_sitl_get_dfg, sc_id=sc;, no_update = no_update, reload = reload
          tplot_names,sc+'_dfg_srvy_gsm_dmpa',names=tn
          jmax=n_elements(tn)
          if jmax ge 1 then begin
            eva_cap, sc+'_dfg_srvy_gsm_dmpa'
            options, sc+'_dfg_srvy_gsm_dmpa', labels=['B!DX!N', 'B!DY!N', 'B!DZ!N','|B|']
            options, sc+'_dfg_srvy_gsm_dmpa', 'ytitle', sc+'!CDFG_srvy'
            options, sc+'_dfg_srvy_gsm_dmpa', 'ysubtitle', '[nT]'
            options, sc+'_dfg_srvy_gsm_dmpa', 'colors',[2,4,6]
            answer = 'Yes'
          endif
        endif
        
        ;-----------
        ; DSP
        ;-----------
        if (strmatch(paramlist[i],'*_dsp_*')) then begin
          data_type = (strmatch(paramlist[i],'*b*')) ? 'bpsd' : 'epsd'
          mms_load_dsp, sc = sc, data_type=data_type
          tplot_names,sc+'_dsp*',names=tn
          jmax=n_elements(tn)
          if (strlen(tn[0]) gt 0) and (jmax gt 0) then begin
            for j=0,jmax-1 do begin
              options,tn[j],'ylog',1
              options,tn[j],'zlog',1
              ylim,tn[j],10,10000
              if strpos(tn[j],'mfe') ge 0 then begin
                ylim,tn[j],100,100000
              endif
            endfor
          endif
;          if strmatch(data_type,'bpsd') then begin
;            get_data,sc+'_dsp_lfb_x',data=Dx,dl=dl,lim=lim
;            get_data,sc+'_dsp_lfb_y',data=Dy
;            get_data,sc+'_dsp_lfb_z',data=Dz
;            Dt = Dx.y + Dy.y + Dz.y
;            store_data,sc+'_dsp_lfb_omni',data={x:Dx.x,y:Dt,v:Dx.v};,dl=dl,lim=lim
;            options,tpv,'ylog',1
;            options,tpv,'zlog',1
;            options,tpv,'spec',1
;          endif else begin
;            get_data,sc+'_dsp_lfe_x',data=Dx,dl=dl,lim=lim
;            get_data,sc+'_dsp_lfe_y',data=Dy
;            get_data,sc+'_dsp_lfe_z',data=Dz
;            Dt = Dx.y + Dy.y + Dz.y
;            tpv=sc+'_dsp_lfe_omni'
;            store_data,tpv,data={x:Dx.x,y:Dt,v:Dx.v};,dl=dl,lim=lim
;            options,tpv,'ylog',1
;            options,tpv,'zlog',1
;            options,tpv,'spec',1
;          endelse
          
          answer = 'Yes'
        endif
        
        ;-----------
        ; EDP
        ;-----------
        if (strmatch(paramlist[i],'*_edp_*')) then begin
          mms_load_edp, sc = sc, level='l1b', mode='comm', data_type='dcecomm';, /no_sweeps
          tplot_names,sc+'_edp_*',names=tn
          jmax=n_elements(tn)
          if (strlen(tn[0]) gt 0) and (jmax gt 0) then begin
            for j=0,jmax-1 do begin
              eva_data_load_mms_options, tn[j], ytitle='E, mV/m',labels=['X','Y','Z'],$
                labflag=-1,colors=[2,4,6],yrange=[-20,20]
            endfor
          endif
          answer = 'Yes'
        endif
        
        ;-----------
        ; AE Index
        ;-----------
        if strmatch(paramlist[i],'thg_idx_ae') then begin
          thm_load_pseudoAE,datatype='ae'
          if tnames('thg_idx_ae') eq '' then begin
            store_data,'thg_idx_ae',data={x:[ts,te], y:replicate(!values.d_nan,2)}
          endif
          options,'thg_idx_ae',ytitle='THEMIS!CAE Index'
        endif
      endif;if ct eq 0 then begin; if not loaded
      c+=1
    endfor; for each requested parameter
    
    ;-------------
    ; ORBIT INFO
    ;-------------
    matched=0
    Re = 6371.2
    ; predicted orbit from AFG
    tplot_names,sc+'_ql_pos_gsm',names=tn
    if (n_elements(tn) eq 1) then begin
      if (strlen(tn) gt 0) then begin
        get_data,sc+'_ql_pos_gsm',data=D,lim=lim,dl=dl
        wtime = D.x
        wdist = D.y[*,3]/Re
        wposx = D.y[*,0]/Re
        wposy = D.y[*,1]/Re
        wposz = D.y[*,2]/Re
        matched=1
      endif
    endif
    
    if matched then begin
      store_data,sc+'_position_z',data={x:wtime,y:wposz}
      options,sc+'_position_z',ytitle=sc+' Z (Re)'
      store_data,sc+'_position_y',data={x:wtime,y:wposy}
      options,sc+'_position_y',ytitle=sc+' Y (Re)'
      store_data,sc+'_position_x',data={x:wtime,y:wposx}
      options,sc+'_position_x',ytitle=sc+' X (Re)'
    endif
    
    
  endfor; for each requested probe
  
  progressbar -> Destroy
  return, answer
END
