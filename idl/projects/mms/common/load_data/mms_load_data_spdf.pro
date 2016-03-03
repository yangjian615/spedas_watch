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
;       *** IMPORTANT NOTE ON BURST DATA *** 
;       Burst data files downloaded with this routine will not be in the same 
;       directory structure as the burst files downloaded with mms_load_data using
;       the SDC. This is because the SDC puts burst files in daily folders, while
;       SPDF doesn't. 
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-03-02 08:39:40 -0800 (Wed, 02 Mar 2016) $
;$LastChangedRevision: 20285 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/load_data/mms_load_data_spdf.pro $
;-

pro mms_load_data_spdf, probes = probes, datatype = datatype, instrument = instrument, $
                   trange = trange, source = source, level = level, $
                   remote_data_dir = remote_data_dir, local_data_dir = local_data_dir, $
                   attitude_data = attitude_data, no_download = no_download, $
                   no_server = no_server, data_rate = data_rate, tplotnames = tplotnames

    if not keyword_set(datatype) then datatype = '*'
    if not keyword_set(level) then level = 'l2'
    if not keyword_set(probes) then probes = ['1']
    if not keyword_set(data_rate) then data_rate = 'srvy'
    
    ; make sure important strings are lower case
    instrument = strlowcase(instrument)
    level = strlowcase(level)
    
    if not keyword_set(remote_data_dir) then remote_data_dir = 'http://spdf.sci.gsfc.nasa.gov/pub/data/mms/'

    if (keyword_set(trange) && n_elements(trange) eq 2) $
      then tr = timerange(trange) $
      else tr = timerange()
      
    mms_init, remote_data_dir = remote_data_dir, local_data_dir = local_data_dir
    ;if not keyword_set(source) then source = !mms
    
    pathformat = strarr(n_elements(probes)*n_elements(datatype))
    path_count = 0 

    for probe_idx = 0, n_elements(probes)-1 do begin
        if data_rate eq 'brst' then time_format = 'YYYYMMDDhhmmss' else time_format = 'YYYYMMDD'
        case strlowcase(instrument) of
            'fgm': begin
                ; FGM
                ; mms1/fgm/srvy/l2/2016/01/
                pathformat[path_count] = 'PROBE' + strcompress(string(probes[probe_idx]), /rem) + '/' + $
                    instrument + '/'+data_rate+'/'+level+'/YYYY/MM/PROBE' + strcompress(string(probes[probe_idx]), /rem) + $
                    '_' + instrument + '_'+data_rate+'_'+level+'_'+time_format+'_v*.cdf'
                path_count += 1
              end
             'aspoc': begin
                ; ASPOC
                ; mms1/aspoc/srvy/l2/2016/02/
                pathformat[path_count] = 'PROBE' + strcompress(string(probes[probe_idx]), /rem) + '/' + $
                    instrument + '/'+data_rate+'/'+level+'/YYYY/MM/PROBE' + strcompress(string(probes[probe_idx]), /rem) + $
                    '_' + instrument + '_'+data_rate+'_'+level+'_'+time_format+'_v*.cdf'
                path_count += 1
              end
             'edi': begin
                ; EDI
                ; mms1/edi/srvy/l2/efield/2016/01/
                for datatype_idx = 0, n_elements(datatype)-1 do begin
                    pathformat[path_count] = 'PROBE' + strcompress(string(probes[probe_idx]), /rem) + '/' + $
                        instrument + '/'+data_rate+'/'+level+'/'+datatype[datatype_idx]+'/YYYY/MM/PROBE' + strcompress(string(probes[probe_idx]), /rem) + $
                        '_' + instrument + '_'+data_rate+'_'+level+'_'+datatype[datatype_idx]+'_'+time_format+'_v*.cdf'
                    path_count += 1
                endfor
              end
             'fpi': begin
                ; FPI
                ; mms1/fpi/fast/l2/des-dist/2016/01/
                ; special case for FPI
                if data_rate eq 'brst' then time_format = 'YYYYMMDDhhmmss' else time_format = 'YYYYMMDDhh0000'
                for datatype_idx = 0, n_elements(datatype)-1 do begin
                    pathformat[path_count] = 'PROBE' + strcompress(string(probes[probe_idx]), /rem) + '/' + $
                        instrument + '/'+data_rate+'/'+level+'/'+datatype[datatype_idx]+'/YYYY/MM/PROBE' + strcompress(string(probes[probe_idx]), /rem) + $
                        '_' + instrument + '_'+data_rate+'_'+level+'_'+datatype[datatype_idx]+'_'+time_format+'_v*.cdf'
                    path_count += 1
                endfor
              end
             'eis': begin
                ; EIS
                ; mms1/epd-eis/srvy/l2/extof/2016/01/
                instru = 'epd-eis' ; different instrument name for EIS data in the directory structure
                for datatype_idx = 0, n_elements(datatype)-1 do begin
                    pathformat[path_count] = 'PROBE' + strcompress(string(probes[probe_idx]), /rem) + '/' + $
                        instru + '/'+data_rate+'/'+level+'/'+datatype[datatype_idx]+'/YYYY/MM/PROBE' + strcompress(string(probes[probe_idx]), /rem) + $
                        '_' + instru + '_'+data_rate+'_'+level+'_'+datatype[datatype_idx]+'_'+time_format+'_v*.cdf'
                    path_count += 1
                endfor
              end
             'feeps': begin
                ; FEEPS
                ; mms1/feeps/srvy/l2/electron/2016/01/
                if data_rate eq 'brst' then time_format = 'YYYYMMDDhhmmss' else time_format = 'YYYYMMDD000000'
                for datatype_idx = 0, n_elements(datatype)-1 do begin
                    pathformat[path_count] = 'PROBE' + strcompress(string(probes[probe_idx]), /rem) + '/' + $
                        instrument + '/'+data_rate+'/'+level+'/'+datatype[datatype_idx]+'/YYYY/MM/PROBE' + strcompress(string(probes[probe_idx]), /rem) + $
                        '_' + instrument + '_'+data_rate+'_'+level+'_'+datatype[datatype_idx]+'_'+time_format+'_v*.cdf'
                    path_count += 1
                endfor
              end
             'hpca': begin
                ; HPCA
                ; mms1/hpca/srvy/l2/ion/2016/01/   (???)
                ; no L2 data at the SPDF yet (3/2/2016)
              end
             'mec': begin
                ; MEC
                ; mms1/mec/srvy/l2/ephts04d/2016/01/
                for datatype_idx = 0, n_elements(datatype)-1 do begin
                    pathformat[path_count] = 'PROBE' + strcompress(string(probes[probe_idx]), /rem) + '/' + $
                        instrument + '/'+data_rate+'/'+level+'/'+datatype[datatype_idx]+'/YYYY/MM/PROBE' + strcompress(string(probes[probe_idx]), /rem) + $
                        '_' + instrument + '_'+data_rate+'_'+level+'_'+datatype[datatype_idx]+'_'+time_format+'_v*.cdf'
                    path_count += 1
                endfor
              end
             'scm': begin
                ; SCM
                ; mms1/scm/srvy/l2/scsrvy/2016/01/
                for datatype_idx = 0, n_elements(datatype)-1 do begin
                    pathformat[path_count] = 'PROBE' + strcompress(string(probes[probe_idx]), /rem) + '/' + $
                        instrument + '/'+data_rate+'/'+level+'/'+datatype[datatype_idx]+'/YYYY/MM/PROBE' + strcompress(string(probes[probe_idx]), /rem) + $
                        '_' + instrument + '_'+data_rate+'_'+level+'_'+datatype[datatype_idx]+'_'+time_format+'_v*.cdf'
                    path_count += 1
                endfor
              end
        endcase
    endfor

    data_count = 0 
    for probe_idx = 0, n_elements(probes)-1 do begin
      for datatype_idx = 0, n_elements(datatype)-1 do begin
        if instrument eq 'fpi' then resolution = 7200 ; 2-hour resolution on FS files
        if data_rate eq 'brst' then resolution = 1 ; 1 second resolution for burst files
        
        relpathnames = file_dailynames(file_format=pathformat[data_count], trange=tr, /unique, resolution=resolution)

        ; the following is a kludge to deal with the fact that "mm" in "mms" 
        ; is interpreted by file_dailynames as 00 (minute?)
        for path_idx = 0, n_elements(relpathnames)-1 do begin
            real_path = relpathnames[path_idx]
            str_replace, real_path, 'PROBE', 'mms'
            str_replace, real_path, 'PROBE', 'mms' ; str_replace only replaces the first it finds
            relpathnames[path_idx] = real_path
        endfor

        ;files = file_retrieve(relpathnames, /last_version, REMOTE_DATA_DIR=!mms.remote_data_dir)
        files = spd_download(remote_file=relpathnames, remote_path=remote_data_dir, $
          local_path = local_data_dir, $
          SSL_VERIFY_HOST=0, SSL_VERIFY_PEER=0) ; these keywords ignore certificate warnings

        mms_cdf2tplot, files, tplotnames = tplotnames
        
        data_count += 1
      endfor
    endfor
    
    ; time clip the data
    if ~undefined(tr) && ~undefined(tplotnames) then begin
        if (n_elements(tr) eq 2) and (tplotnames[0] ne '') then begin
            time_clip, tplotnames, tr[0], tr[1], replace=1, error=error
        endif
    endif
end