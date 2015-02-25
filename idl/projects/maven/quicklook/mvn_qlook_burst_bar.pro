;+
;NAME:
; mvn_qlook_burst_bar
;PURPOSE:
; creates burst data bar for overview plots
;CALLING SEQUENCE:
; p = mvn_qlook_burst_bar(date,duration)
;INPUT:
; date =  the date for the start of the timespan, 
; duration = the duration of your bar in days
;KEYWORDS:
; outline: set this to 1 to generate a sample rate panel with
;          a black outline rather than no outline
;OUTPUT:
; p = the variable name of the qlook_burst_bar, set to '' if not
;     sccessful
;HISTORY:
; 20-nov-2007, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2015-02-23 16:20:00 -0800 (Mon, 23 Feb 2015) $
; $LastChangedRevision: 17028 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/quicklook/mvn_qlook_burst_bar.pro $
;-
Function mvn_qlook_burst_bar, date, duration, outline=outline, _extra = _extra

  p = ''
  timespan, date, duration

; make tplot variable tracking the presence of archive data
;------------------------------------------------------------------
  
;To test archive data, look for 'a3' app_id packets,
;'swe_3d_arc' data in SWE common block and 'mvn_swi?a_en_counts'
;variables
  @mvn_swe_com
  If(is_struct(swe_3d_arc)) Then Begin
     store_data, 'mvn_swe_arctemp', data = {x:swe_3d_arc.time, y:0.5+fltarr(n_elements(swe_3d_arc.time))}
     yes_swe_arc = 1b
  Endif Else yes_swe_arc = 0b
  get_data, 'mvn_swica_ph_counts', data = ddd
  If(is_struct(ddd)) Then Begin
     store_data, 'mvn_swi_arctemp', data = {x:ddd.x, y:0.5+fltarr(n_elements(ddd.x))}
     yes_swi_arc = 1b
  Endif Else yes_swi_arc = 0b

;Use SWE if you have it, swi as a backup
  If(yes_swe_arc) Then Begin
     copy_data, 'mvn_swe_arctemp', 'mvn_arcflag'
     tdegap, 'mvn_arcflag', /overwrite, dt = 600.0
  Endif Else If(yes_swi_arc) Then Begin
     copy_data, 'mvn_swi_arctemp', 'mvn_arcflag'
     tdegap, 'mvn_arcflag', /overwrite, dt = 600.0
  Endif Else Begin
     store_data, 'mvn_arcflag', {x:timerange(), y:[!values.f_nan, !values.f_nan]}
  Endelse

  options, 'mvn_arcflag', 'color', 6 ;red
  options, 'mvn_arcflag', 'thick', 5

  if keyword_set(outline) then begin
     options,'mvn_arcflag',color=0,ticklen=0,yticks=1,ytickname=[' ',' ']
  endif

  ylim, 'mvn_arcflag', 0.0, 1.0, 0
  options, 'mvn_arcflag', 'panel_size', 0.2
  options,'mvn_arcflag', ytitle=''
  

;end mode bar code block
;--------------->
  p = 'mvn_arcflag'
  Return, p
End

