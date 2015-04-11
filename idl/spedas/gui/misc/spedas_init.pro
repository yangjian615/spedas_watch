;+
;PROCEDURE:  spedas_init
;
;PURPOSE:    Initializes system variables for spedas data.
;            Can be called from idl_startup to set custom locations.
;
;$LastChangedBy: crussell $
;$LastChangedDate: 2013-10-26 12:08:47 -0700 (Sat, 26 Oct 2013) $
;$LastChangedRevision: 13403 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/thmsoc/trunk/idl/spedas/spd_ui/api_examples/file_configuration_tab/spedas_init.pro $
;-

pro spedas_init, reset=reset, local_data_dir=local_data_dir, remote_data_dir=remote_data_dir, use_spdf = use_spdf, no_color_setup

  compile_opt idl2

  spedas_reset = 1

  defsysv,'!spedas',exists=exists
  if (not keyword_set(exists)) then begin ;if !spedas is not defined
    tmp_struct=file_retrieve(/structure_format)
    str_element,tmp_struct,'browser_exe','',/add
    str_element,tmp_struct,'temp_dir','',/add
    str_element,tmp_struct,'temp_cdf_dir','',/add
    str_element,tmp_struct,'linux_fix',0,/add
    defsysv,'!spedas',tmp_struct
  endif

  ftest = spedas_read_config()
  if (keyword_set(reset)) or not (size(ftest, /type) eq 8) then begin ;if it was not saved before or if it is reset
    tmp_struct=file_retrieve(/structure_format)
    str_element,tmp_struct,'browser_exe','',/add
    str_element,tmp_struct,'temp_dir','',/add
    str_element,tmp_struct,'temp_cdf_dir','',/add
    str_element,tmp_struct,'linux_fix',0,/add
    defsysv,'!spedas',tmp_struct
    data_dir =  spd_default_local_data_dir()
    data_dir = StrJoin( StrSplit(data_dir, '\\' , /Regex, /Extract, /Preserve_Null), path_sep())
    data_dir = StrJoin( StrSplit(data_dir, '/', /Regex, /Extract, /Preserve_Null), path_sep())    
    if STRMID(data_dir, 0, 1, /REVERSE_OFFSET) ne path_sep() then data_dir = data_dir + path_sep()
    !spedas.local_data_dir = data_dir
    !spedas.temp_dir =  data_dir + 'temp' + path_sep()
    !spedas.temp_cdf_dir =  data_dir + 'cdaweb' + path_sep()
    !spedas.browser_exe = ''
    !spedas.linux_fix = 0
    !spedas.init = 1
    print,'Resetting !spedas to default configuration.'
  endif else begin ;retrieved from saved values
    ctags = tag_names(ftest)
    nctags = n_elements(ctags)
    stags = tag_names(!spedas)
    sctags = n_elements(stags)

    For j = 0, nctags-1 Do Begin
      x0 = strtrim(ctags[j])
      x1 = ftest.(j)
      If (size(x1, /type) eq 11) then x1 = '' ;ignore objects
      If(is_string(x1)) Then x1 = strtrim(x1, 2) $
      Else Begin                  ;Odd thing can happen with byte arrays
        If(size(x1, /type) Eq 1) Then x1 = fix(x1)
        x1 = strcompress(/remove_all, string(x1))
      Endelse
      index = WHERE(stags eq x0, count)
      if count EQ 0 then begin
         dir = spedas_config_filedir()
         msg='The configuration file '+dir+'\spedas_config.txt contains invalid or obsolete fields. Would you like a new file automatically generated for you? If not, you will need to modify your existing file before proceeding. Configuration information can be found in the Users Guide.'
         answer = dialog_message(msg, /question)
         if answer EQ 'Yes' then begin
            cmd='del '+dir+'\spedas_config.txt'
            spawn, cmd, res, errres
            spedas_init
         endif
         return
      endif 
      if (count gt 0) and not (size(!spedas.(index), /type) eq 11) then !spedas.(index) = x1
    endfor
    spedas_reset = 0
    print,'Loaded !spedas from saved values.'
  endelse

  if spedas_reset then spedas_write_config ;if i twas just re-loaded from file, we do not re-write the values

  printdat,/values,!spedas,varname='!spedas'
  
end
