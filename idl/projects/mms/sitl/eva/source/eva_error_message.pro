PRO eva_error_message, error_status, msg=msg
  @moka_logger_com
  
  help, /last_message, output=error_message; get error message
  vsn=float(strmid(!VERSION.RELEASE,0,3))
  if vsn ge 8.0 then begin
    r = terminal_size()
    r0 = r[0]
  endif else r0 = 5
  stra = strarr(r0) & stra[0:*] = '='
  strb = strarr(r0) & strb[0:*] = '-'
  format = '('+strtrim(string(r0),2)+'A)'
  
  ; IDL error message
  log.o,'===== IDL Error Message ====='
  for jjjj=0,n_elements(error_message)-1 do begin
    print,error_message[jjjj]
    log.o,error_message[jjjj]
  endfor
  
  ; EVA error message
  if n_elements(msg) ne 0 then begin
    log.o,'===== EVA Error Message ====='
    log.o, msg
  endif
  
  ; ENVIRONMENT
  log.o,'===== Environment ====='
  log.o, 'error index: '+string(error_status)
  log.o, 'OS name:   '+!VERSION.OS_NAME
  log.o, 'IDL version: '+!VERSION.RELEASE
  log.o, 'build date: '+ !VERSION.BUILD_DATE
  log.o, 'architecture: '+!VERSION.ARCH
  log.o, 'memory and file_offset bits: '+ $
    string(!VERSION.MEMORY_BITS, format=('(I3)')) + ' , ' + $
    string(!VERSION.FILE_OFFSET_BITS, format=('(I3)'))

  ; Message to user    
  print, format=format, stra
  print, "ERROR detected: Please find EVA's log file at"
  print, ""
  print, log.FILE
  print, ""
  print, 'and send this to Mitsuo Oka (moka@ssl.berkeley.edu)'
  print, format=format, stra
END
