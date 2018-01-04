;+
;NAME:
;
; spedas
;
;PURPOSE:
; Starts spd_gui, the GUI for SPEDAS data analysis
;
;CALLING SEQUENCE:
; spedas
;
;INPUT:
; none
;
; Keywords:
;   Reset - If set will reset all internal settings.
;           Otherwise, it will try to load the state of the previous call.
;   template_filename - The file name of a previously saved spedas template document,
;                   can be used to store user preferences and defaults.
;
;OUTPUT:
; none
;
;HISTORY:
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2017-12-04 14:50:01 -0800 (Mon, 04 Dec 2017) $
;$LastChangedRevision: 24393 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/spedas.pro $
;-----------------------------------------------------------------------------------

pro spedas, reset=reset,template_filename=template_filename

  spd_gui,reset=reset,template_filename=template_filename

end