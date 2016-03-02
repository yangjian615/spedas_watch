;+
; PROCEDURE:
;         mms_load_data_spdf
;         
; PURPOSE:
;         Load MMS data from NASA/SPDF (backup to loading from SDC)
; 
; KEYWORDS:
; 
; OUTPUT:
; 
; 
; EXAMPLE:
;    mms_load_data_spdf, probe=1, instrument='fgm', level='l2', trange=['2016-01-10', '2016-01-11']
; 
; NOTES:
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-03-01 09:07:16 -0800 (Tue, 01 Mar 2016) $
;$LastChangedRevision: 20277 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/load_data/mms_load_data_spdf.pro $
;-

pro mms_load_data_spdf, probes = probes, datatype = datatype, instrument = instrument, $
                   trange = trange, source = source, level = level, $
                   remote_data_dir = remote_data_dir, local_data_dir = local_data_dir, $
                   attitude_data = attitude_data, no_download = no_download, $
                   no_server = no_server

    if not keyword_set(datatype) then datatype = '*'
    if not keyword_set(level) then level = 'l2'
    if not keyword_set(probes) then probes = ['1']
    
    ; make sure important strings are lower case
    instrument = strlowcase(instrument)
    level = strlowcase(level)
    
    if not keyword_set(remote_data_dir) then remote_data_dir = 'http://cdaweb.gsfc.nasa.gov/istp_public/data/mms/'

    if (keyword_set(trange) && n_elements(trange) eq 2) $
      then tr = timerange(trange) $
      else tr = timerange()
      
    mms_init, remote_data_dir = remote_data_dir
    ;if not keyword_set(source) then source = !mms
    
    pathformat = strarr(n_elements(probes))
    
    for probe_idx = 0, n_elements(probes)-1 do begin
        pathformat[probe_idx] = 'PROBE' + strcompress(string(probes[probe_idx]), /rem) + '/' + $
            instrument + '/srvy/'+level+'/YYYY/MM/PROBE' + strcompress(string(probes[probe_idx]), /rem) + $
            '_' + instrument + '_srvy_'+level+'_YYYYMMDD_v*.cdf'
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

        files = spd_download(remote_file=relpathnames, remote_path=!mms.remote_data_dir, $
          SSL_VERIFY_HOST=0, SSL_VERIFY_PEER=0) ; these keywords ignore certificate warnings

        mms_cdf2tplot, files, tplotnames = tplotnames
        
    endfor
    
    ; time clip the data
    if ~undefined(tr) && ~undefined(tplotnames) then begin
        if (n_elements(tr) eq 2) and (tplotnames[0] ne '') then begin
            time_clip, tplotnames, tr[0], tr[1], replace=1, error=error
        endif
    endif
end