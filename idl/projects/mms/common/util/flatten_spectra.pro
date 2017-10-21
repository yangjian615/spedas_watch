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
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-10-20 13:02:00 -0700 (Fri, 20 Oct 2017) $
;$LastChangedRevision: 24201 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/util/flatten_spectra.pro $
;-


pro flatten_spectra, xlog=xlog, ylog=ylog
  @tplot_com.pro
  
  ctime,t,npoints=1,prompt="Use cursor to select a time to plot the spectra",$
    hours=hours,minutes=minutes,seconds=seconds,days=days,/silent
  
  print, 'time selected: ' + time_string(t, tformat='YYYY-MM-DD/hh:mm:ss.fff')
  vars_to_plot = tplot_vars.options.varnames
  window, 1
  !P.MULTI = [0, 1, 1]
  
  for v_idx=0, n_elements(vars_to_plot)-1 do begin

      get_data, vars_to_plot[v_idx], data=vardata

      time_to_plot = find_nearest_neighbor(vardata.X, t)
      idx_to_plot = where(vardata.X eq time_to_plot)
      
      data_to_plot = vardata.Y[idx_to_plot, *]
      if dimen2(vardata.v) eq 1 then x_data = vardata.v else x_data = vardata.v[idx_to_plot, *]

      if v_idx eq 0 then begin
        plot, x_data, xlog=xlog, ylog=ylog, data_to_plot[0, *], charsize=2.0, title=time_string(t, tformat='YYYY-MM-DD/hh:mm:ss.fff')
      endif else begin
        oplot, x_data, data_to_plot[0, *], color=v_idx*2
      endelse
  endfor

end