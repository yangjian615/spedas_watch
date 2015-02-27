
FUNCTION eva_sitl_load_stlm, state
  compile_opt idl2
  @moka_logger_com
  
  
  clock = eva_tic('EVA_DATA_LOAD_STLM',/profiler) 
  
  str_tspan = [state.START_TIME, state.END_TIME]; string array
  
  stlm  = {$; SITL Manu
    input: 'soca', $ ; input type (default: 'soca'; or 'socs','stla')
    update: 1 } ; update input data everytime plotting STLM variables
  
  fomfile = state.PREF.CACHE_DATA_DIR+'FOMstr_'+stlm.input+'.sav'
  
  ; Should use "execute" to reduce number of codes?
  if stlm.update then begin
    case stlm.input of
      'soca': eva_sitl_load_soca,state, str_tspan; generates 'mms_soca_fom'(data=['mms_soca_fomstr','mms_soca_zero'])
      'socs': eva_sitl_load_socs,state          ; generates 'mms_socs_fom'(data=['mms_socs_fomstr','mms_socs_zero'])
      'stla': eva_sitl_load_stla,state          ; generates 'mms_stla_fom'(data=['mms_stla_fomstr','mms_stla_zero'])
      else: stop
    endcase
    r=tnames()
    
    ; 'mms_stlm_fomstr'
    idx=where(strmatch(r,'mms_'+stlm.input+'_fomstr',/fold_case),ct)
    codeFOM = (ct eq 1)
    if codeFOM then begin
      get_data,'mms_'+stlm.input+'_fomstr',data=D,lim=lim,dl=dl
      store_data,'mms_stlm_fomstr',data=D,lim=lim,dl=dl
      options,   'mms_stlm_fomstr','unix_FOMStr_mod',lim.unix_FOMStr_org; add unixFOMStr_mod
      options,   'mms_stlm_fomstr','unix_FOMStr_org'; remove unixFOMStr_org
      options,   'mms_stlm_fomstr','ytitle','FOM'
      options,   'mms_stlm_fomstr','ysubtitle','(SITL)'
      dgrand = ['mms_stlm_fomstr']
    endif else message, "This can't be happening!"
        
    ; 'mms_soca_bakstr'
    idx=where(strmatch(r,'mms_'+stlm.input+'_bakstr',/fold_case),ct)
    codeBAK = (ct eq 1)
    if codeBAK then begin
      get_data,'mms_'+stlm.input+'_bakstr',data=D,lim=lim,dl=dl
      store_data,'mms_stlm_bakstr',data=D, lim=lim, dl=dl
      options,   'mms_stlm_bakstr','unix_BAKStr_mod',lim.unix_BAKStr_org; add unix_BAKStr_mod
      options,   'mms_stlm_bakstr','unix_BAKStr_org'; remove unix_BAKStr_org
      options,   'mms_stlm_bakstr','ytitle','BAK'
      options,   'mms_stlm_bakstr','ysubtitle','(SITL)'
      dgrand = [dgrand,'mms_stlm_bakstr']
    endif
    

    ; 'mms_stlm_input_fom'
    get_data,'mms_'+stlm.input+'_fom',data=S,lim=lim,dl=dl
    store_data, 'mms_stlm_input_fom',data=S,lim=lim,dl=dl; Just make a copy
    options, 'mms_stlm_input_fom','ytitle','FOM'
    options, 'mms_stlm_input_fom','ysubtitle','(original)'
    
    ; 'mms_stlm_output_fom'
    dgrand = [dgrand,'mms_soca_zero']
    store_data, 'mms_stlm_output_fom',data=dgrand,lim=lim,dl=dl
    options, 'mms_stlm_output_fom','codeFOM',codeFOM
    options, 'mms_stlm_output_fom','codeBAK',codeBAK
    options,'mms_stlm_output_fom','ytitle','FOM'
    options,'mms_stlm_output_fom','ysubtitle','(SITL)'
    eva_sitl_strct_yrange,'mms_stlm_output_fom'
  endif

  eva_toc,clock,str=str,report=report
  
  log.o,str
  return, 'Yes'
END