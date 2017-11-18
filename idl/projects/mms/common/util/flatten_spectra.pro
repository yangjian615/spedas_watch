;+
; PROCEDURE:
;         flatten_spectra
;
; PURPOSE:
;         Create quick plots of spectra at a certain time (i.e., energy vs. eflux, PA vs. eflux, etc)
;         
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
;$LastChangedDate: 2017-11-16 20:45:18 -0800 (Thu, 16 Nov 2017) $
;$LastChangedRevision: 24294 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/util/flatten_spectra.pro $
;-


pro flatten_spectra, xlog=xlog, ylog=ylog, xrange=xrange, yrange=yrange
  @tplot_com.pro
  
  ctime,t,npoints=1,prompt="Use cursor to select a time to plot the spectra",$
    hours=hours,minutes=minutes,seconds=seconds,days=days,/silent
  
  print, 'time selected: ' + time_string(t, tformat='YYYY-MM-DD/hh:mm:ss.fff')
  vars_to_plot = tplot_vars.options.varnames
  window, 1
  !P.MULTI = [0, 1, 1]
  
  ; determine max and min
  if N_ELEMENTS(xrange) ne 2 or N_ELEMENTS(yrange) ne 2 then begin
    for v_idx=0, n_elements(vars_to_plot)-1 do begin
      get_data, vars_to_plot[v_idx], data=vardata
      tmp = min(vardata.X - t, /ABSOLUTE, idx_to_plot) ; get the time index
      append_array,yr,reform(vardata.Y[idx_to_plot, *])
      if dimen2(vardata.v) eq 1 then  append_array,xr,reform(vardata.v) else append_array,xr,reform(vardata.v[idx_to_plot, *])     
    endfor
  endif
  if N_ELEMENTS(xrange) ne 2 then xrange = KEYWORD_SET(xlog) ? [min(xr(where(xr>0))), max(xr(where(xr>0)))] : [min(xr), max(xr)]
  if N_ELEMENTS(yrange) ne 2 then yrange = KEYWORD_SET(ylog) ? [min(yr(where(yr>0))), max(yr(where(yr>0)))] : [min(yr), max(yr)]
  
  for v_idx=0, n_elements(vars_to_plot)-1 do begin

      get_data, vars_to_plot[v_idx], data=vardata, limits=tplot_lims
      ; append_array,lims,tplot_lims

      time_to_plot = find_nearest_neighbor(vardata.X, t)
      idx_to_plot = where(vardata.X eq time_to_plot)
      
      data_to_plot = vardata.Y[idx_to_plot, *]
      if dimen2(vardata.v) eq 1 then x_data = vardata.v else x_data = vardata.v[idx_to_plot, *]

      if v_idx eq 0 then begin
        plot, x_data, data_to_plot[0, *], $
          xlog=xlog, ylog=ylog, xrange=xrange, yrange=yrange, $
          charsize=2.0, title=time_string(t, tformat='YYYY-MM-DD/hh:mm:ss.fff')
      endif else begin
        oplot, x_data, data_to_plot[0, *], color=v_idx*2
      endelse
  endfor

end