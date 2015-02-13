PRO eva_sitl_save, auto=auto
  compile_opt idl2
  
  stn = tnames('mms_stlm_fomstr',ct)
  if ct ne 1 then begin
    answer=dialog_message('FOMstr not found',/center,/error)
    return
  endif
  
  get_data,'mms_stlm_fomstr',data=D,lim=eva_lim,dl=eva_dl
  
  if keyword_set(auto) then begin 
    fname = getenv('HOME')+'/eva-fom-modified.sav'
  endif else begin
    fname_default = 'eva-fom-modified-'+time_string(systime(1,/utc),format=2)+'.sav'
    fname = dialog_pickfile(DEFAULT_EXTENSION='sav', /WRITE, $
      FILE=fname_default)
    if strlen(fname) eq 0 then begin
      answer = dialog_message('Cancelled',/center,/info)
      return
    endif
  endelse
  save, eva_lim, eva_dl, filename=fname
  found = file_test(fname)
  if found then begin
    if keyword_set(auto) then msg = 'Successfully saved!' $
      else msg = 'Successfully saved as '+fname 
    answer = dialog_message(msg,/center,/info)
  endif else begin
    answer = dialog_message('Not Saved!',/center,/error)
  endelse
END
