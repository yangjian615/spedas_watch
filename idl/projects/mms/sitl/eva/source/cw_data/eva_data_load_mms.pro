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
        endif
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
        data_type = (strmatch(paramlist[i],'*_lfb*')) ? 'bpsd' : 'epsd'
        mms_load_dsp, sc = sc, data_type=data_type
        case data_type of
          'bpsd':begin
            tpv = sc+'_dsp_lfb_'
            yrange = [10,10000]
            options, tpv+['x','y','z'], 'ylog',1
            options, tpv+['x','y','z'], 'zlog',1
            ylim, tpv+['x','y','z'], yrange[0], yrange[1]
            end
          'epsd':begin
            tpv = [sc+'_dsp_lfe_',sc+'_dsp_mfe_']
            yrange_min = [10, 100]
            yrange_max = [10000,100000]
            for m=0,1 do begin
              options, tpv[m]+['x','y','z'], 'ylog',1
              options, tpv[m]+['x','y','z'], 'zlog',1
              ylim, tpv[m]+['x','y','z'], yrange_min[m], yrange_max[m]
            endfor
            end
          else: stop
        endcase
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
      
      c+=1
    endfor
  endfor
  progressbar -> Destroy
  return, answer
END
