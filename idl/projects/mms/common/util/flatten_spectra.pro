;+
; PROCEDURE:
;         flatten_spectra
;
; PURPOSE:
;         Create quick plots of spectra at a certain time (i.e., energy vs. eflux, PA vs. eflux, etc)
; KEYWORDS:
;       [XY]LOG:   [XY] axis in log format
;       [XY]RANGE: 2 element vector that sets [XY] axis range
;       NOLEGEND:  Disable legend display
;       COLORS:    n element vector that sets the colors of the line in order that they are in tplot_vars.options.varnames
;                  n is number of tplot variables in tplot_vars.options.varnames
;             
;       PNG:         save png from the displayed windows (cannot be used with /POSTRSCRIPT keyword)
;       POSTRSCRIPT: create postscript files instead of displaying the plot
;       PREFIX:      filename prefix
;       FILENAME:    custorm filename, including folder. By default the folder is !mms.local_data_dir      
;
; EXAMPLE:
;     To create line plots of FPI electron energy spectra for all MMS spacecraft:
;     
;       MMS> mms_load_fpi, datatype='des-moms', trange=['2015-12-15', '2015-12-16'], probes=[1, 2, 3, 4]
;       MMS> tplot, 'mms?_des_energyspectr_omni_fast'
;       MMS> flatten_spectra, /xlog, /ylog
;       
;       --> then click the tplot window at the time you want to create the line plots at
;
; NOTES:
;     work in progress; suggestions, comments, complaints, etc: egrimes@igpp.ucla.edu
;     
;$LastChangedBy: adrozdov $
;$LastChangedDate: 2017-11-20 15:59:20 -0800 (Mon, 20 Nov 2017) $
;$LastChangedRevision: 24325 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/util/flatten_spectra.pro $
;-

pro warning, str
  ; print warning message 
  dprint, dlevel=0, '########################### WARNING #############################'  
  dprint, dlevel=0,  str
  dprint, dlevel=0, '#################################################################'
end

function get_unit_string, unit_array
  ; prepare string of units from the given array. If there is more that one unit in the array, print the warning 
  if ~undefined(unit_array) then begin
    if N_ELEMENTS(unit_array) gt 1 then begin
      warning, 'Units of the tplot variables are different!'
      return, STRJOIN(unit_array, ', ')             
    endif else RETURN, unit_array[0]
  endif else return, ''
end

pro get_unit_array, metadata, field, arr=arr
  ; extract unique units from metadata 
  str_element, metadata,field, SUCCESS=S, VALUE=V
  V = S ? V : '[]' ; Test if we sucsesfully return the value
  if undefined(arr) then begin
    append_array, arr, V      
  endif else begin
    if total(strcmp(arr, V)) lt 1 then append_array, arr, V       
  endelse
end

pro flatten_spectra, xlog=xlog, ylog=ylog, xrange=xrange, yrange=yrange, nolegend=nolegend, colors=colors,$
   png=png, postscript=postscript, prefix=prefix, filename=filename
  @tplot_com.pro
  
  ctime,t,npoints=1,prompt="Use cursor to select a time to plot the spectra",$
    hours=hours,minutes=minutes,seconds=seconds,days=days,/silent
  
  if t eq 0 then return ; exit on the right click
  
  print, 'time selected: ' + time_string(t, tformat='YYYY-MM-DD/hh:mm:ss.fff')
  vars_to_plot = tplot_vars.options.varnames
   
  fname = '' ; filename for if we save png of postscript  
  if UNDEFINED(prefix) THEN prefix = ''  
  
  ; loop to get supporting information
  for v_idx=0, n_elements(vars_to_plot)-1 do begin  
    get_data, vars_to_plot[v_idx], data=vardata, alimits=metadata

    ; determine units: get fields for metadata and add the the array if any 
    get_unit_array, metadata, 'ysubtitle', arr=xunits
    get_unit_array, metadata, 'ztitle', arr=yunits
    
    ; determine max and min  
    if N_ELEMENTS(xrange) ne 2 or N_ELEMENTS(yrange) ne 2 then begin 
      tmp = min(vardata.X - t, /ABSOLUTE, idx_to_plot) ; get the time index
      append_array,yr,reform(vardata.Y[idx_to_plot, *])
      if dimen2(vardata.v) eq 1 then  append_array,xr,reform(vardata.v) else append_array,xr,reform(vardata.v[idx_to_plot, *])     
    endif      
    
    ; filename if we need to save file
    fname += vars_to_plot[v_idx] + '_'      
  endfor
  
  ; select [xy] range
  if N_ELEMENTS(xrange) ne 2 then xrange = KEYWORD_SET(xlog) ? [min(xr(where(xr>0))), max(xr(where(xr>0)))] : [min(xr), max(xr)]
  if N_ELEMENTS(yrange) ne 2 then yrange = KEYWORD_SET(ylog) ? [min(yr(where(yr>0))), max(yr(where(yr>0)))] : [min(yr), max(yr)]
  
  ; user defined colors indexes
  if ~KEYWORD_SET(colors) or (N_ELEMENTS(colors) lt n_elements(vars_to_plot)) then begin
    colors = indgen(n_elements(vars_to_plot),start=0,increment=2)
  endif 
  
  ; units string
  xunit_str = get_unit_string(xunits)
  yunit_str = get_unit_string(yunits)
   
  ; position for the legend
  leg_x = 0.04
  leg_y = 0.04
  leg_dy = 0.04

  ; finalizing filename
  fname += time_string(t, tformat='YYYYMMDD_hhmmss')
  fname = !mms.local_data_dir + prefix + fname  
  if ~UNDEFINED(filename) THEN fname = filename

  ; Device = postscript or window
  if KEYWORD_SET(postscript) then popen, fname, /landscape else window, 1
  
  ; loop plot
  for v_idx=0, n_elements(vars_to_plot)-1 do begin

      get_data, vars_to_plot[v_idx], data=vardata, limits=tplot_lims      
      time_to_plot = find_nearest_neighbor(vardata.X, t)
      idx_to_plot = where(vardata.X eq time_to_plot)
      
      data_to_plot = vardata.Y[idx_to_plot, *]
      if dimen2(vardata.v) eq 1 then x_data = vardata.v else x_data = vardata.v[idx_to_plot, *]

      if v_idx eq 0 then begin
        plot, x_data, data_to_plot[0, *], $
          xlog=xlog, ylog=ylog, xrange=xrange, yrange=yrange, $
          xtitle=xunit_str, ytitle=yunit_str, $
          charsize=2.0, title=time_string(t, tformat='YYYY-MM-DD/hh:mm:ss.fff'), color=colors[v_idx]
          
          if ~keyword_set(nolegend) then begin
            leg_x += !x.WINDOW[0]
            leg_y = !y.WINDOW[1] - leg_y
          endif            
      endif else begin
        oplot, x_data, data_to_plot[0, *], color=colors[v_idx]
      endelse      
      
      if ~keyword_set(nolegend) then begin
        leg_y -= leg_dy
        XYOUTS, leg_x, leg_y, vars_to_plot[v_idx], /normal, color=colors[v_idx], charsize=1.5
      endif      
  endfor
  
  ; save to file
  if KEYWORD_SET(png) and ~KEYWORD_SET(postscript) then makepng, fname
  if KEYWORD_SET(postscript) then pclose
end