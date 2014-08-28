;+
;NAME:
; thm_sample_rate_bar
;PURPOSE:
; creates the sample rate bar for overview plots
;CALLING SEQUENCE:
; p = thm_sample_rate_bar(date,duration,probe)
;INPUT:
; date =  the date for the start of the timespan, 
; duration = the duration of your bar in days
; probe = THEMIS probe Id
;
;KEYWORDS:
; outline: set this to 1 to generate a sample rate panel with
;          a black outline rather than no outline
;OUTPUT:
; p = the variable name of the sample_rate_bar, set to '' if not
;     sccessful
;HISTORY:
; 20-nov-2007, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: pcruce $
; $LastChangedDate: 2009-08-03 17:09:36 -0700 (Mon, 03 Aug 2009) $
; $LastChangedRevision: 6522 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/common/thm_sample_rate_bar.pro $
;-
Function thm_sample_rate_bar, date, duration, probe,outline=outline, _extra = _extra

  p = ''
  timespan, date, duration
  sc = strlowcase(strcompress(probe[0], /remove_all))

; make tplot variable tracking the sample rate (0=SS,1=FS,2=PB,3=WB)
;------------------------------------------------------------------
  thm_load_hsk, probe = sc, varformat = 'th'+sc+'*issr_mode*'
  if tnames('th'+sc+'*issr_mode*') eq '' then $
    store_data, strjoin('th'+sc+'_hsk_issr_mode_raw'), $
    data = {x:[time_double(date)], y:float('NaN')}
  get_data, strjoin('th'+sc+'_hsk_issr_mode_raw'), data = d,dlimit=dl
  ss_data = float(d.y)
  index_ss_fill = where(d.y ne 0)
  index_ss = where(d.y eq 0)
  if (index_ss_fill[0] ne -1) then ss_data[index_ss_fill] = float('NaN')
  if (index_ss[0] ne -1) then ss_data[index_ss] = 0.

  fs_data = float(d.y)
  index_fs_fill = where(d.y ne 0 and d.y ne 1 and d.y ne 2 and d.y ne 3)
  index_fs = where(d.y eq 0 or d.y eq 1 or d.y eq 2 Or d.y eq 3)
  if (index_fs_fill[0] ne -1) then fs_data[index_fs_fill] = float('NaN')
  if (index_fs[0] ne -1) then fs_data[index_fs] = 0.

  str_element,dl,'ysubtitle',/delete
  str_element,dl,'colors',/delete
  store_data, 'slow_survey_bar_'+sc, data = {x:d.x, y:ss_data},dlimit=dl
  store_data, 'fast_survey_bar_'+sc, data = {x:d.x, y:fs_data},dlimit=dl
  store_data, 'aesthetic_bar_'+sc, data = {x:d.x, y:ss_data},dlimit=dl
;get particle burst data from fgh level 2 data, jmm, 27-aug-2007
  thm_load_fgm, probe = sc[0], level = 'l2', datatype = 'fgh'
;if L2 data is not there, look for L1 data, jmm, 24-apr-2008
  tn = tnames('th'+sc+'*fgh*')
  If(tn[0] eq '') then begin
    tns = tnames('th'+sc+'*state_spin*')
    If(tns[0] eq '') then thm_load_state, probe = sc[0], /get_support_data
    thm_load_fgm, probe = sc[0], level = 'l1', datatype = 'fgh'
  Endif
  tn = tnames('th'+sc+'*fgh*')
  if tn[0] eq '' then begin     ;no data
    store_data, 'particle_burst_bar_'+sc, data = {x:time_double(date), y:float('NaN')}
    store_data, 'particle_burst_sym_'+sc, data = {x:time_double(date), y:float('NaN')}
  endif else begin
    tn = tn[0]       ;assuming that all fgh's have the same time range
    get_data, tn, data = d,dlimit=dl
    If(size(d, /type) Eq 8) Then Begin ;on the off chance
      test_y = d.x
      pb_data = float(test_y)
      index_pb_fill = where(finite(test_y) Eq 0)
      index_pb = where(finite(test_y))
      if (index_pb_fill[0] ne -1) then pb_data[index_pb_fill] = float('NaN')
      if (index_pb[0] ne -1) then pb_data[index_pb] = 0.0
      pb_data2 = pb_data        ; pb_data2 is for symbols below bar
      if (index_pb[0] ne -1) then pb_data2[index_pb] = -1.0
      str_element,dl,'labels',/delete
      str_element,dl,'ysubtitle',/delete
      str_element,dl,'colors',/delete   
      str_element,dl,'labflag',/delete
      str_element,dl,'ytitle',/delete
      store_data, 'particle_burst_bar_'+sc, data = {x:d.x, y:pb_data},dlimit=dl
      store_data, 'particle_burst_sym_'+sc, data = {x:d.x, y:pb_data2},dlimit=dl
    Endif Else Begin
      store_data, 'particle_burst_bar_'+sc, data = {x:time_double(date), y:float('NaN')}
      store_data, 'particle_burst_sym_'+sc, data = {x:time_double(date), y:float('NaN')}
    Endelse
  endelse

;wave bursts from level 1 ffw data
  thm_load_fft, probe = sc[0], level = 'l1', varformat = 'th'+sc+'*ffw*'
  tn = tnames('th'+sc+'*ffw*')
  if tn[0] eq '' then begin
    store_data, 'wave_burst_bar_'+sc, data = {x:time_double(date), y:float('NaN')}
    store_data, 'wave_burst_sym_'+sc, data = {x:time_double(date), y:float('NaN')}
  endif else begin
    tn = tn[0] ;making the assumption that all ffws will have the same time range?
    get_data, tn, data = d,dlimit=dl
    test_y = d.x                ;use the times here
    If(size(d, /type) Eq 8) Then Begin ;on the off chance
      wb_data = float(test_y)
      index_wb_fill = where(finite(test_y) Eq 0)
      index_wb = where(finite(test_y))
      if (index_wb_fill[0] ne -1) then wb_data[index_wb_fill] = float('NaN')
      if (index_wb[0] ne -1) then wb_data[index_wb] = 0.0
      wb_data2 = wb_data        ; wb_data2 is for symbols above bar
      if (index_wb[0] ne -1) then wb_data2[index_wb] = 1.0
      str_element,dl,'spec',/delete
      str_element,dl,'ysubtitle',/delete
      str_element,dl,'log',/delete
      store_data, 'wave_burst_bar_'+sc, data = {x:d.x, y:wb_data},dlimit=dl
      store_data, 'wave_burst_sym_'+sc, data = {x:d.x, y:wb_data2},dlimit=dl
    Endif Else Begin
      store_data, 'wave_burst_bar_'+sc, data = {x:time_double(date), y:float('NaN')}
      store_data, 'wave_burst_sym_'+sc, data = {x:time_double(date), y:float('NaN')}
    Endelse
  endelse

  options, 'aesthetic_bar_'+sc, 'color', 255
  options, 'slow_survey_bar_'+sc, 'color', 5
  options, 'fast_survey_bar_'+sc, 'color', 6
  options, 'particle_burst_bar_'+sc, 'color', 3
  options, 'particle_burst_sym_'+sc, 'color', 0
  options, 'wave_burst_bar_'+sc, 'color', 0
  options, 'wave_burst_sym_'+sc, 'color', 0
  
  options, 'slow_survey_bar_'+sc, 'thick', 5
  options, 'fast_survey_bar_'+sc, 'thick', 5
  options, 'particle_burst_bar_'+sc, 'psym', 6
  options, 'particle_burst_bar_'+sc, 'symsize', 0.1
  options, 'particle_burst_sym_'+sc, 'psym', 6
  options, 'particle_burst_sym_'+sc, 'symsize', 0.2
  options, 'wave_burst_bar_'+sc, 'psym', 6
  options, 'wave_burst_bar_'+sc, 'symsize', 0.1
  options, 'wave_burst_sym_'+sc, 'psym', 6
  options, 'wave_burst_sym_'+sc, 'symsize', 0.2
  
  if keyword_set(outline) then begin

     options,'aesthetic_bar_'+sc,color=0,ticklen=0,$
             yticks=1,ytickname=[' ',' ']

  endif

  store_data, 'sample_rate_'+sc, data = ['aesthetic_bar_'+sc, 'fast_survey_bar_'+sc, 'slow_survey_bar_'+sc, 'particle_burst_sym_'+sc, 'wave_burst_sym_'+sc]

  ylim, 'sample_rate_'+sc, -1.1, 1.1, 0
  options, 'sample_rate_'+sc, 'panel_size', 0.2
  options,'sample_rate_'+sc,ytitle=''
  

;end mode bar code block
;--------------->
  p = 'sample_rate_'+sc
  Return, p
End

