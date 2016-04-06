;+
; FUNCTION:
;     mms_gui_datarates
;
; PURPOSE:
;     Returns list of valid data rates for a given instrument
;      (for populating the data rate listbox in the GUI)
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-04-01 09:06:46 -0700 (Fri, 01 Apr 2016) $
; $LastChangedRevision: 20678 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/gui/mms_gui_datarates.pro $
;-

function mms_gui_datarates, instrument
  instrument = strlowcase(instrument)
  valid_rates = hash(/fold_case)

  valid_rates['fgm'] = ['srvy', 'brst']
  valid_rates['hpca'] = ['srvy', 'brst']
  valid_rates['eis'] = ['srvy', 'brst']
  valid_rates['feeps'] = ['srvy', 'brst']
  valid_rates['fpi'] = ['fast', 'brst']
  valid_rates['scm'] = ['srvy', 'brst', 'slow', 'fast']
  valid_rates['edi'] = ['srvy', 'brst']
  valid_rates['edp'] = ['fast', 'brst', 'slow']
  valid_rates['dsp'] = ['fast', 'slow']
  valid_rates['aspoc'] = ['srvy']
  valid_rates['mec'] = ['srvy', 'brst']

  if valid_rates.haskey(instrument) then begin
    return, valid_rates[instrument]
  endif else begin
    return, -1 ; not found
  endelse
end