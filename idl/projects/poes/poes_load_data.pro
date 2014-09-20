;+
; Procedure: poes_load_data
; 
; Keywords: 
;             trange:       time range of interest
;             datatype:     type of POES data to be loaded. Valid data types are:
;                             'ted': Total Energy Detector
;                             'meped': Medium Energy Proton and Electron Detector
;            
;             suffix:        String to append to the end of the loaded tplot variables
;             probes:        Name of the POES spacecraft, i.e., probes=['noaa18','noaa19','metop2']
;             varnames:      Name(s) of variables to load, defaults to all (*)
;             /downloadonly: Download the file but don't read it  
; 
; $LastChangedBy: egrimes $
; $LastChangedDate: 2014-09-18 13:58:25 -0700 (Thu, 18 Sep 2014) $
; $LastChangedRevision: 15823 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/poes/poes_load_data.pro $
;-

; the following routine takes a list of tplot names with the time 
; variables stored in milliseconds and converts the times to seconds
pro convert_poes_times, tplot_names
    for tplotname_idx = 0, n_elements(tplot_names)-1 do begin
        get_data, tplot_names[tplotname_idx], data=temp_data, dlimits=temp_dlimits
        store_data, tplot_names[tplotname_idx], dlimits=temp_dlimits, data={x: double(temp_data.X/1000.), y: temp_data.Y}
    endfor
end
pro poes_load_data, trange = trange, datatype = datatype, probes = probes, suffix = suffix, downloadonly = downloadonly
    compile_opt idl2

    poes_init
    if undefined(suffix) then suffix = ''
    if undefined(prefix) then prefix = ''
    
    ; handle possible server errors
    catch, errstats
    if errstats ne 0 then begin
        dprint, dlevel=1, 'Error: ', !ERROR_STATE.MSG
        catch, /cancel
        return
    endif

    if not keyword_set(datatype) then datatype = ''
    if not keyword_set(probes) then probes = ['noaa19'] 
    if not keyword_set(source) then source = !poes
    if (keyword_set(trange) && n_elements(trange) eq 2) $
      then tr = timerange(trange) $
      else tr = timerange()
      
    tn_list_before = tnames('*')
    
    pathformat = strarr(n_elements(probes))
    ; let's have the prefix include the probe name, so we can load
    ; data from multiple spacecraft without naming conflicts
    prefix_array = strarr(n_elements(probes))
    
    for probe_idx = 0, n_elements(probes)-1 do begin
        dprint, dlevel = 2, verbose=source.verbose, 'Loading ', strupcase(probes[probe_idx]), $
            ' ', strupcase(datatype), ' data'

        pathformat[probe_idx] = '/noaa/'+probes[probe_idx]+'/sem2_fluxes-2sec/YYYY/'+probes[probe_idx]+'_poes-sem2_fluxes-2sec_YYYYMMDD_v01.cdf'
        prefix_array[probe_idx] = prefix + probes[probe_idx]
    endfor
    
    
    for j = 0, n_elements(pathformat)-1 do begin
        relpathnames = file_dailynames(file_format=pathformat[j], trange=tr, /unique)

        files = file_retrieve(relpathnames, _extra=source, /last_version)
        
        if keyword_set(downloadonly) then continue
        cdf2tplot, files, prefix = prefix_array[j]+'_', suffix = suffix, /verbose, /get_support_data, /convert_int1_to_int2, /load_labels, tplotnames=tplotnames

    endfor
    ; make sure some tplot variables were loaded
    tn_list_after = tnames('*')
    new_tnames = ssl_set_complement([tn_list_before], [tn_list_after])

    ; the POES time data is in ms, for some reason; we need to
    ; convert it to seconds.
    convert_poes_times, new_tnames

    ; time clip the data
    if ~undefined(tr) && ~undefined(tplotnames) then begin
        if (n_elements(tr) eq 2) and (tplotnames[0] ne '') then begin
            time_clip, tplotnames, tr[0], tr[1], replace=1, error=error
        endif
    endif
    
end