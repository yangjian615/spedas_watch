;+
;NAME: mms_init
;
;PURPOSE: Initializes system variables for MMS.
;
;REQUIRED INPUTS:
; none
;
;HISTORY:
; 2015-04-02 moka Created
; 
; $LastChangedBy: moka $
; $LastChangedDate: 2015-04-02 18:34:10 -0700 (Thu, 02 Apr 2015) $
; $LastChangedRevision: 17228 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/mms_init.pro $
;-

pro mms_init
  
  defsysv,'!mms',exists=exists
  if ~keyword_set(exists) then begin
    defsysv,'!mms', file_retrieve(/structure_format); default values
    
    cfg = mms_config_read()
    if (size(cfg,/type) eq 8)then begin
      !mms.LOCAL_DATA_DIR = cfg.local_data_dir
    endif else begin; if cfg not found
      dir = mms_config_filedir(); create config directory if not found
      !mms.LOCAL_DATA_DIR = root_data_dir()+'mms/'
      pref = {LOCAL_DATA_DIR: !mms.LOCAL_DATA_DIR}
      mms_config_write, pref
    endelse
    thm_graphics_config
  endif

  return
END

