;+
;
;  Name: SPD_UI_DIALOG_PICKFILE_SAVE_WRAPPER
;  
;  Purpose: Wrapper for the IDL routine dialog_pickfile. Checks for invalid characters in the filename.
;  
;  Inputs: Any keywords that need to be passed on to dialog_pickfile (see note 1 below for special cases)
;
;  Output: Filename ('' if dialog is cancelled)
;  
;  NOTE: 
;  1. This routine should not be used if the multiple_files keyword is being passed to dialog_pickfile
;        as ';' will be flagged as invalid if used to separate file names.
;  2. This routine doesn't check for all characters that can cause problems on windows. A large number of cases
;    are already screened by dialog_pickfile on windows (cases that cause no problems on linux).
;  
;  
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas/gui/utilities/spd_ui_dialog_pickfile_save_wrapper.pro $
;-

function spd_ui_dialog_pickfile_save_wrapper,get_path=newpath,_extra=ex

  validfile = 0
  while ~validfile do begin
    filename = dialog_pickfile(get_path=newpath,_extra=ex)
    if stregex(filename,'\*|\{|;|\?', /boolean) then begin
      messageString = 'Invalid characters in filename. Please enter a new name.'
      response=dialog_message(messageString,/CENTER)
    endif else validfile = 1
  endwhile
  return, filename
end
