

PRO eva_sitl_load_soca, state, str_tspan, mdq=mdq
  compile_opt idl2
  @moka_logger_com
  tspan = time_double(str_tspan)
  log.o,'tspan:'+str_tspan[0]+' - '+str_tspan[1]


  ; 'mms_soca_fomstr' (latest ABS selection or SITL target)
  unix_FOMstr = eva_sitl_load_soca_getfom(state.PREF.CACHE_DATA_DIR, state.PARENT); Whatever tspan is, we retrieve unix_FOMStr to get 'tfom'.
  tfom = eva_sitl_tfom(unix_FOMstr)
  log.o,'tfom:'+time_string(tfom[0],prec=7)+' - '+time_string(tfom[1],prec=7)
  dgrand = ['mms_soca_fomstr']
  store_data,'mms_soca_fomstr',data=eva_sitl_strct_read(unix_FOMStr,tfom[0])
  options,'mms_soca_fomstr','ytitle','FOM'
  options,'mms_soca_fomstr','ysubtitle','(ABS)'
  options,'mms_soca_fomstr','unix_FOMStr_org',unix_FOMStr


  ; 'mms_soca_mdq'
  wavex = unix_FOMstr.TIMESTAMPS+5.d0; shift 5 seconds so that the bars (histograms) will be properly placed.
  D = {x:wavex, y:unix_FOMstr.MDQ} 
  store_data,'mms_soca_mdq',data=D
  options,'mms_soca_mdq','psym',10
  options,'mms_soca_mdq','ytitle','MDQ'
  
  ; 'mms_soca_zero'
  zerox = [tspan[0],tfom[0],tfom[0],tfom[0],tfom[1],tfom[1],tfom[1],tspan[1]]
  zeroy = [      0.,     0.,   255.,     0.,     0.,   255.,     0.,      0.]
  store_data,'mms_soca_zero',data={x:zerox, y:zeroy}
  options,'mms_soca_zero','linestyle',1


  ; 'mms_soca_backstr' (burst segment status)
  ; latest SITL target time is stored in "tfom"
  EPS = 0.001d
  if tspan[0]+EPS lt tfom[0] then begin

    mms_get_back_structure, tspan[0], tspan[1], BAKStr, pw_flag, pw_message; START,STOP are ULONG
    ;//////////////////////////////////////////////

    ;BAKStr = test_fake_backstructure()

    ;//////////////////////////////////////////////
    if pw_flag then begin
      rst=dialog_message(pw_message,/info,/center)
    endif else begin

      unix_BAKStr_org = BAKStr
      str_element,/add,unix_BAKStr_org,'START', mms_tai2unix(BAKStr.START); START,STOP are LONG
      str_element,/add,unix_BAKStr_org,'STOP',  mms_tai2unix(BAKStr.STOP)
      D = eva_sitl_strct_read(unix_BAKStr_org,tspan[0])
      store_data,'mms_soca_bakstr',data=D
      options,'mms_soca_bakstr','ytitle','FOM'
      options,'mms_soca_bakstr','ysubtitle','(burst segment status)'
      options,'mms_soca_bakstr','colors',85; 179
      options,'mms_soca_bakstr','unix_BAKStr_org',unix_BAKStr_org
      dgrand = [dgrand,'mms_soca_bakstr']
    endelse
  endif
  
  ; 'mms_soca_fom'
  dgrand = [dgrand,'mms_soca_zero']
  store_data, 'mms_soca_fom',data=dgrand
  options,    'mms_soca_fom','ytitle', 'FOM'
;  if keyword_set(mdq) then begin
;    ; ABSstr
;    ;unix_ABSstr = eva_data_load_soca_getabs(str_tspan)
;  endif

END
