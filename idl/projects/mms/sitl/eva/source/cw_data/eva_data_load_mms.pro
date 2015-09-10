FUNCTION eva_data_load_mms, state
  compile_opt idl2

  ;-------------
  ; INITIALIZE
  ;-------------
  paramlist = strlowcase(state.paramlist_mms); list of parameters read from parameterSet file
  imax = n_elements(paramlist)
  sc_id = state.probelist_mms
  if (size(sc_id[0],/type) ne 7) then return, 'No'; STRING=7
  pmax = n_elements(sc_id)
  if pmax eq 1 then sc = sc_id[0] else sc = sc_id
  ts = str2time(state.start_time)
  te = str2time(state.end_time)
  timespan,state.start_time, te-ts, /seconds
  
  ;----------------------
  ; NUMBER OF PARAMETERS
  ;----------------------
  cparam = imax*pmax
  if cparam ge 17 then begin
    rst = dialog_message('Total of '+strtrim(string(cparam),2)+' MMS parameters. Still plot?',/question,/center)
  endif else rst = 'Yes'
  if rst eq 'No' then return, 'No'

  ;-------------
  ; CATCH ERROR
  ;-------------
  perror = -1
  catch, error_status; !ERROR_STATE is set
  if error_status ne 0 then begin
    catch, /cancel; Disable the catch system
    eva_error_message, error_status
    msg = [!Error_State.MSG,' ','...EVA will igonore this error.']
    ok = dialog_message(msg,/center,/error)
    progressbar -> Destroy
    message, /reset; Clear !ERROR_STATE
    perror = [perror,pcode]
    ;return, answer; 'answer' will be 'Yes', if at least some of the data were succesfully loaded.
  endif

  ;-------------
  ; LOAD
  ;-------------
  progressbar = Obj_New('progressbar', background='white', Text='Loading MMS data ..... 0 %')
  progressbar -> Start
  c = 0
  answer = 'No'
  for p=0,pmax-1 do begin; for each requested probe
    sc = sc_id[p]
    prb = strmid(sc,3,1)
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
      tn=strlowcase(tnames('*',jmax))
      param = strlowcase(sc+strmid(paramlist[i],4,1000))
      if jmax eq 0 then begin; if no pre-loaded variable
        ct = 0
      endif else begin; if pre-loaded variable exists...
        idx = where(strmatch(tn,param),ct); check if param is one of the preloaded variables.
      endelse
      if ct eq 0 then begin; if not loaded
        
        ;-----------
        ; EDP
        ;-----------
        pcode=1
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_edp_*') and (cp eq 0)) then begin
          mms_sitl_get_edp,sc=sc
          options,sc+'_edp_fast_dce_dsl', $
            labels=['X','Y','Z'],ytitle=sc+'!CEDP!Cfast',ysubtitle='[mV/m]',$
            colors=[2,4,6],labflag=-1,yrange=[-20,20],constant=0
          answer = 'Yes'
        endif
        
        ;-----------
        ; EIS
        ;-----------
        pcode=2
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_epd_eis_*') and (cp eq 0)) then begin
          mms_load_epd_eis, sc=sc
          tn=tnames(sc+'_epd_eis_electronenergy_electron_cps_t1',jmax)
          if (strlen(tn[0]) gt 0) and (jmax ge 1) then begin
            options,tn[0],ytitle='electrons',ylog=1,yrange=[0.8,1e+5]
            answer = 'Yes'
          endif
        endif
          
        ;-----------
        ; FEEPS
        ;-----------
        pcode=3
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_feeps_*') and (cp eq 0)) then begin
          mms_load_epd_feeps, sc=sc
          answer = 'Yes'
        endif
        
        ;-----------
        ; FPI
        ;-----------
        pcode=4
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_fpi_*') and (cp eq 0)) then begin
          mms_sitl_get_fpi_basic, sc_id=sc
          
          options, sc+'_fpi_eEnergySpectr_omni',spec=1,ylog=1,zlog=1,$
            ytitle=sc+'!CFPI!Cele',ysubtitle='[eV]'
          ylim, sc+'_fpi_eEnergySpectr_omni', 10,26000
          
          options,sc+'_fpi_iEnergySpectr_omni',spec=1,ylog=1,zlog=1,$
            ytitle=sc+'!CFPI!Cion',ysubtitle='[eV]'
          ylim, sc+'_fpi_iEnergySpectr_omni', 10,26000
          
          options,sc+'_fpi_ePitchAngDist_midEn',spec=1,zlog=1,$
            ytitle=sc+'!CFPI!Cele',ysubtitle='(PAD,mid-E)'
          ylim, sc+'_fpi_ePitchAngDist_midEn', 0,180
          
          options,sc+'_fpi_ePitchAngDist_highEn',spec=1,zlog=1,$
            ytitle=sc+'!CFPI!Cele',ysubtitle='(PAD,high-E)'
          ylim, sc+'_fpi_ePitchAngDist_highEn', 0, 180
          
          options,sc+'_fpi_DISnumberDensity',ylog=1,$
            ytitle=sc+'!CFPI!CNi',ysubtitle='[cm!U-3!N]'
          
          options,sc+'_fpi_iBulkV_DSC',$
            ytitle=sc+'!CFPI!CVi',ysubtitle='[km/s]',$
            labels=['V!DX!N', 'V!DY!N', 'V!DZ!N'],labflag=-1,colors=[2,4,6]

          answer = 'Yes'
        endif

        ;-----------
        ; HPCA
        ;-----------
        pcode=5
        ip=where(perror eq pcode,cp)
        level = 'sitl'
        if (strmatch(paramlist[i],'*_hpca_*rf_corrected') and (cp eq 0)) then begin
          sh='H!U+!N'
          sa='He!U++!N'
          sp='He!U+!N'
          so='O!U+!N'
          mms_sitl_get_hpca_basic, sc_id=sc, level=level
          
          options, sc+'_hpca_hplus_RF_corrected', ytitle=sc+'!CHPCA!C'+sh,ysubtitle='[eV]',ztitle='eflux',/spec,/ylog,/zlog
          ylim,    sc+'_hpca_hplus_RF_corrected', 1, 40000
          
          options, sc+'_hpca_heplusplus_RF_corrected', ytitle=sc+'!CHPCA!C'+sa,ysubtitle='[eV]',ztitle='eflux',/spec,/ylog,/zlog
          ylim,    sc+'_hpca_heplusplus_RF_corrected', 1, 40000
          
          options, sc+'_hpca_heplus_RF_corrected', ytitle=sc+'!CHPCA!C'+sp,ysubtitle='[eV]',ztitle='eflux',/spec,/ylog,/zlog
          ylim,    sc+'_hpca_heplus_RF_corrected', 1, 40000
          
          options, sc+'_hpca_oplus_RF_corrected', ytitle=sc+'!CHPCA!C'+so,ysubtitle='[eV]',ztitle='eflux',/spec,/ylog,/zlog
          ylim,    sc+'_hpca_oplus_RF_corrected', 1, 40000
          
          answer = 'Yes'
        endif
        
        pcode=6
        ip=where(perror eq pcode,cp)
        level = 'sitl'
        if( (cp eq 0) and $
          (strmatch(paramlist[i],'*_hpca_*number_density') or strmatch(paramlist[i],'*_hpca_*bulk_velocity'))) then begin
          mms_sitl_get_hpca_moments, sc_id=sc, level=level
          sh='(H!U+!N)'
          so='(O!U+!N)'
          options, sc+'_hpca_hplus_number_density',ytitle=sc+'!CHPCA!CN '+sh,ysubtitle='[cm!U-3!N]',/ylog,$
            colors=1,labels=['N '+sh]
          options, sc+'_hpca_oplus_number_density',ytitle=sc+'!CHPCA!CN '+so,ysubtitle='[cm!U-3!N]',/ylog,$
            colors=3,labels=['N '+so]
          options, sc+'_hpca_hplus_bulk_velocity',ytitle=sc+'!CHPCA!CV '+sh,ysubtitle='[km/s]',ylog=0,$
            colors=[2,4,6],labels=['V!DX!N '+sh, 'V!DY!N '+sh, 'V!DZ!N '+sh],labflag=-1
          options, sc+'_hpca_oplus_bulk_velocity',ytitle=sc+'!CHPCA!CV '+so,ysubtitle='[km/s]',ylog=0,$
            colors=[2,4,6],labels=['V!DX!N '+so, 'V!DY!N '+so, 'V!DZ!N '+so],labflag=-1
          options, sc+'_hpca_hplus_scalar_temperature',ytitle=sc+'!CHPCA!CT '+sh,ysubtitle='[eV]',/ylog,$
            colors=1,labels=['T '+sh]
          options, sc+'_hpca_oplus_scalar_temperature',ytitle=sc+'!CHPCA!CT '+so,ysubtitle='[eV]',/ylog,$
            colors=3,labels=['T '+so]

          options, sc+'_hpca_hplusoplus_number_densities',ytitle=sc+'!CHPCA!CDensity',ysubtitle='[cm!U-3!N]',/ylog,$
            colors=[1,3],labels=['N '+sh, 'N '+so],labflag=-1
          options, sc+'_hpca_hplusoplus_scalar_temperatures',ytitle=sc+'!CHPCA!CTemp',ysubtitle='[eV]',$
            colors=[1,3],labels=['T '+sh, 'T '+so],labflag=-1

          answer = 'Yes'
        endif

        ;-----------
        ; FIELDS/AFG
        ;-----------
        pcode=7
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_afg*') and (cp eq 0)) then begin
          mms_sitl_get_afg, sc_id=sc
          options,sc+'_afg_srvy_gsm_dmpa',$
            labels=['B!DX!N', 'B!DY!N', 'B!DZ!N','|B|'],ytitle=sc+'!CAFG!Csrvy',ysubtitle='[nT]',$
            colors=[2,4,6],labflag=-1,constant=0,cap=1
          answer = 'Yes'
        endif
  
        ;-----------
        ; FIELDS/DFG
        ;-----------
        pcode=8
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_dfg*') and (cp eq 0)) then begin
          mms_sitl_get_dfg, sc_id=sc
          options,sc+'_dfg_srvy_gsm_dmpa',$
            labels=['B!DX!N', 'B!DY!N', 'B!DZ!N','|B|'],ytitle=sc+'!CDFG!Csrvy',ysubtitle='[nT]',$
            colors=[2,4,6],labflag=-1,constant=0, cap=1
          answer = 'Yes'
        endif
        
        ;-----------
        ; FIELDS/DSP
        ;-----------
        pcode=9
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'*_dsp_*') and (cp eq 0)) then begin
          data_type = (strmatch(paramlist[i],'*b*')) ? 'bpsd' : 'epsd'
          mms_sitl_get_dsp, sc=sc, datatype=datatype
          tn=tnames(sc+'*dsp*',jmax)
          if (strlen(tn[0]) gt 0) and (jmax gt 0) then begin
            options,tn,ylog=1,zlog=1,yrange=[10,10000]
            idx = where(strmatch(tn,'*_mfe_*'),ct)
            if ct gt 0 then ylim,tn[idx],100,10000
          endif
          answer = 'Yes'
        endif
        
        ;-----------
        ; AE Index
        ;-----------
        pcode=10
        ip=where(perror eq pcode,cp)
        if (strmatch(paramlist[i],'thg_idx_ae') and (cp eq 0)) then begin
          thm_load_pseudoAE,datatype='ae'
          if tnames('thg_idx_ae') eq '' then begin
            store_data,'thg_idx_ae',data={x:[ts,te], y:replicate(!values.d_nan,2)}
          endif
          options,'thg_idx_ae',ytitle='THEMIS!CAE Index'
          answer = 'Yes'
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
    tn=tnames(sc+'_ql_pos_gsm',jmax)
    if (strlen(tn[0]) gt 0) and (jmax eq 1) then begin
      get_data,sc+'_ql_pos_gsm',data=D,lim=lim,dl=dl
      wtime = D.x
      wdist = D.y[*,3]/Re
      wposx = D.y[*,0]/Re
      wposy = D.y[*,1]/Re
      wposz = D.y[*,2]/Re
      matched=1
    endif
    
    if matched then begin
      store_data,sc+'_position_z',data={x:wtime,y:wposz}
      options,sc+'_position_z',ytitle=sc+' Zgsm (Re)'
      store_data,sc+'_position_y',data={x:wtime,y:wposy}
      options,sc+'_position_y',ytitle=sc+' Ygsm (Re)'
      store_data,sc+'_position_x',data={x:wtime,y:wposx}
      options,sc+'_position_x',ytitle=sc+' Xgsm (Re)'
    endif
    
    
  endfor; for each requested probe
  
  progressbar -> Destroy
  return, answer
END
