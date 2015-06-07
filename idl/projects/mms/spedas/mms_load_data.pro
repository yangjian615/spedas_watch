;+
; PROCEDURE:
;         mms_load_data
;         
; PURPOSE:
;         Load MMS data for the AFG/DFG magnetometers into tplot variables
; 
; KEYWORDS:
;         trange: time range of interest
;         probes: list of probes - values for MMS SC #
;         instrument: currently accepts AFG or DFG
;         datatype: not implemented yet
;         local_data_dir: local directory to store the CDF files; should be set if 
;             you're on *nix or OSX, the default currently assumes Windows (c:\data\mms\)
; 
; OUTPUT:
; 
; 
; EXAMPLE:
;     See the crib sheet mms_load_data_crib.pro for usage examples
; 
; NOTES:
;     1) With no remote_data_dir specified, this routine grabs the data in CDFs from:
;         http://lasp.colorado.edu/mms/sdc/about/browse/mms#/?fg/srvy/[level]/YYYY/MM/
;         
;     2) I expect this routine to change significantly as the MMS data products are 
;         released to the public and feedback comes in from scientists - egrimes@igpp
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-06-05 09:54:04 -0700 (Fri, 05 Jun 2015) $
;$LastChangedRevision: 17810 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/mms_load_data.pro $
;-

function mms_load_defatt_file, filename
    ; from ascii_template on a definitive attitude file
    defatt_template = { VERSION: 1.00000, $
        DATASTART: 49, $
        DELIMITER: 32b, $
        MISSINGVALUE: !values.D_NAN, $
        COMMENTSYMBOL: 'COMMENT', $
        FIELDCOUNT: 21, $
        FIELDTYPES: [7, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 7], $
        FIELDNAMES: ['Time', 'Elapsed', 'q1', 'q2', 'q3', 'qc', 'wX', 'wY', 'wZ', 'wPhase', 'zRA', 'zDec', 'ZPhase', 'LRA', 'LDec', 'LPhase', 'PRA', 'PDec', 'PPhase', 'Nut', 'QF'], $
        FIELDLOCATIONS: [0, 22, 38, 47, 55, 65, 73, 80, 87, 94, 102, 111, 118, 126, 135, 142, 150, 159, 166, 176, 183], $
        FIELDGROUPS: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]}
    
    def_att = read_ascii(filename, template=defatt_template, count=num_items)
    
    ; note on time format in this file:
    ; date/time values are stored in the format: YYYY-DOYThh:mm:ss.fff
    ; so to convert the first time value to a time_double, time = time_double(def_att.time[0], tformat='YYYY-DOYThh:mm:ss.fff')

    return, def_att
end

pro mms_load_defatt_tplot, filename
    ; load the data from the ASCII file
    def_att_data = mms_load_defatt_file(filename)
    
    ; the last datapoint in the file is 'DATA_STOP', so
    ; we use n_elements-1 here to not copy the last element
    time_vals = dblarr(n_elements(def_att_data.time)-1)

    ; n_elements-2 here to avoid copying the last element, as above
    for time_idx = 0l, n_elements(def_att_data.time)-2 do begin
        if def_att_data.time[time_idx] ne 'DATA_STOP' then $
            time_vals[time_idx] = time_double(def_att_data.time[time_idx], tformat='YYYY-DOYThh:mm:ss.fff')
    endfor
    store_data, 'mms_defatt_spinras', data={x: time_vals, y: def_att_data.LRA[0:n_elements(def_att_data.LRA)-2]}
    store_data, 'mms_defatt_spindec', data={x: time_vals, y: def_att_data.LDEC[0:n_elements(def_att_data.LDEC)-2]}

end

pro mms_load_data, probes = probes, datatype = datatype, instrument = instrument, $
                   trange = trange, source = source, level = level, $
                   remote_data_dir = remote_data_dir, local_data_dir = local_data_dir

    if not keyword_set(datatype) then datatype = '*'
    ; currently, datatype = level
    if datatype ne '*' && undefined(level) then level = datatype
    if not keyword_set(level) then level = 'ql'
    if not keyword_set(instrument) then instrument = 'dfg' ; default to DFG
    if not keyword_set(probes) then probes = ['1']
    if probes[0] eq '*' then probes = [1, 2, 3, 4]
    
    ; make sure important strings are lower case
    instrument = strlowcase(instrument)
    level = strlowcase(level)
    
    if not keyword_set(remote_data_dir) then remote_data_dir = 'http://lasp.colorado.edu/mms/sdc/about/browse/'
    if not keyword_set(local_data_dir) then local_data_dir = 'c:\data\mms\'
    if (keyword_set(trange) && n_elements(trange) eq 2) $
      then tr = timerange(trange) $
      else tr = timerange()
      
    mms_init, remote_data_dir = remote_data_dir, local_data_dir = local_data_dir
    if not keyword_set(source) then source = !mms
      
    tn_list_before = tnames('*')
    
    pathformat = strarr(n_elements(probes))
    
    for probe_idx = 0, n_elements(probes)-1 do begin
        ; currently defaulting to V0.0.0 of the CDFs 
        ; TODO: this needs to be updated to grab the latest version of the CDF file.
        pathformat[probe_idx] = 'PROBE' + strcompress(string(probes[probe_idx]), /rem) + '/' + $
            instrument + '/srvy/'+level+'/YYYY/MM/PROBE' + strcompress(string(probes[probe_idx]), /rem) + $
            '_' + instrument + '_srvy_'+level+'_YYYYMMDD_v0.0.0.cdf'
    endfor

    for probe_idx = 0, n_elements(probes)-1 do begin
        relpathnames = file_dailynames(file_format=pathformat[probe_idx], trange=tr, /unique)
        
        ; the following is a kludge to deal with the fact that "mm" in "mms" 
        ; is interpreted by file_dailynames as 00 (minute?)
        for path_idx = 0, n_elements(relpathnames)-1 do begin
            real_path = relpathnames[path_idx]
            str_replace, real_path, 'PROBE', 'mms'
            str_replace, real_path, 'PROBE', 'mms' ; str_replace only replaces the first it finds
            relpathnames[path_idx] = real_path
        endfor
        files = file_retrieve(relpathnames, _extra=source, /last_version)
        cdf2tplot, files, tplotnames = tplotnames
    endfor
    
    ; time clip the data
    if ~undefined(tr) && ~undefined(tplotnames) then begin
        if (n_elements(tr) eq 2) and (tplotnames[0] ne '') then begin
            time_clip, tplotnames, tr[0], tr[1], replace=1, error=error
        endif
    endif
end