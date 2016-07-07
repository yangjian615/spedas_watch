;+
;PROCEDURE:
;         mms_tplot_quicklook
;
; PURPOSE:
;         Wrapper around tplot specifically for MMS quicklook figures; this
;         routine will include all panels in the QL figure even when there is no 
;         data (panels without data are labeled 'NO DATA')
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-07-06 15:42:54 -0700 (Wed, 06 Jul 2016) $
; $LastChangedRevision: 21432 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/quicklook/mms_tplot_quicklook.pro $
;-

pro mms_tplot_quicklook, tplotnames, _extra=ex
@tplot_com.pro
    ; grab the trange from the common block
    if is_struct(tplot_vars.options) then begin
      start_time = time_string(tplot_vars.options.trange[0])
      end_time = time_string(tplot_vars.options.trange[1])
    endif
    
    ; check that the tvars exist and have data over the trange
    for tvar_idx = 0, n_elements(tplotnames)-1 do begin
      if tdexists(tplotnames[tvar_idx], start_time, end_time) ne 0 then begin
        append_array, tplotnames_with_data, tplotnames[tvar_idx]
      endif else begin
        store_data, 'no_data', data={x: [time_double(start_time), time_double(end_time)], y: [0, 0]}
        append_array, tplotnames_with_data, 'no_data'
      endelse
    endfor

    ; plot them
    tplot, tplotnames_with_data, get_plot_pos=positions, _extra=ex
    
    ; add NO DATA labels to plots on the figure without any data
    where_no_data = where(tplotnames_with_data eq 'no_data', nodatacount)
    if nodatacount ne 0 then begin
      no_data_msg = 'NO DATA'
      no_data_panel_pos = positions[*, where_no_data]
      for no_data_panel=0, nodatacount-1 do begin
        xyouts, /normal, 0.47, (no_data_panel_pos[*,no_data_panel])[1]+((no_data_panel_pos[*,no_data_panel])[3]-(no_data_panel_pos[*,no_data_panel])[1])/2.0, no_data_msg
      endfor
    endif
end