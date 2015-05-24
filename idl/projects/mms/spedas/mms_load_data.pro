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
;$LastChangedDate: 2015-05-22 15:37:18 -0700 (Fri, 22 May 2015) $
;$LastChangedRevision: 17679 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/mms_load_data.pro $
;-

pro mms_load_data, probes = probes, datatype = datatype, instrument = instrument, $
                   trange = trange, source = source, level = level, $
                   remote_data_dir = remote_data_dir, local_data_dir = local_data_dir

    if not keyword_set(datatype) then datatype = '*'
    if not keyword_set(level) then level = 'ql'
    if not keyword_set(instrument) then instrument = 'dfg' ; default to DFG
    instrument = strlowcase(instrument)
    if not keyword_set(probes) then probes = ['1']
    if probes[0] eq '*' then probes = [1, 2, 3, 4]
    
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
        pathformat[probe_idx] = 'PROBE' + strcompress(string(probes[probe_idx]), /rem) + '/' + instrument + '/srvy/'+level+'/YYYY/MM/PROBE' + strcompress(string(probes[probe_idx]), /rem) + '_' + instrument + '_srvy_'+level+'_YYYYMMDD_v0.0.0.cdf'
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