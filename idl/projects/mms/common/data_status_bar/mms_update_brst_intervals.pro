;+
;
;  This routine will create a save file, mms_brst_intervals.sav in
;  the directory:
;
;        !mms.local_data_dir + '/'
;
; containing a structure with the tags "start_times" and "end_times".
; These are the start/end times of the brst  intervals as
; specified in the mms_burst_data_segment.csv file
;
; This is meant to be run by an automated script that rebuilds the
; mms_brst_intervals.sav file and uploads it to spedas.org:
;
;     http://spedas.org/mms/mms_brst_intervals.sav
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-06-29 15:34:45 -0700 (Wed, 29 Jun 2016) $
; $LastChangedRevision: 21402 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/data_status_bar/mms_update_brst_intervals.pro $
;-

pro mms_update_brst_intervals

  mms_init

  brst_file = spd_download(remote_file='https://lasp.colorado.edu/mms/sdc/public/service/latis/mms_burst_data_segment.csv', $
    local_file=!mms.local_data_dir+'mms_burst_data_segment.csv', $
    SSL_VERIFY_HOST=0, SSL_VERIFY_PEER=0) ; these keywords ignore certificate warnings

  brst_seg_temp = { VERSION: 1.0000000, $
    DATASTART: 1, $
    DELIMITER: 44b, $
    MISSINGVALUE: "", $
    COMMENTSYMBOL: "", $
    FIELDCOUNT: 13, $
    FIELDTYPES: [0, 3, 3, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0], $
    FIELDNAMES: [ "FIELD01", "TAISTARTTIME", $
    "TAIENDTIME", "FIELD04", "FIELD05", "FIELD06", $
    "FIELD07", "STATUS", "FIELD09", "FIELD10", $
    "FIELD11", "FIELD12", "FIELD13"], $
    FIELDLOCATIONS: [0, 4, 16, 28, 44, 50, 53, 56, 75, 78, 93, 114, 135], $
    FIELDGROUPS: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]  $
  }
  brst_data = read_ascii(brst_file, template=brst_seg_temp, count=num_items)

  complete_idxs = where(brst_data.status eq 'COMPLETE+FINISHED', c_count)
  if c_count ne 0 then begin
    tai_start = brst_data.TAISTARTTIME[complete_idxs]
    tai_end = brst_data.TAIENDTIME[complete_idxs]

    unix_start = mms_tai2unix(tai_start)
    unix_end = mms_tai2unix(tai_end)
  endif

  brst_intervals = {start_times: unix_start, end_times: unix_end}
  save, brst_intervals, filename=!mms.local_data_dir + '/mms_brst_intervals.sav'
  dprint, dlevel = 0, 'Brst intervals updated! Last interval in the file: ' + time_string(unix_start[n_elements(unix_start)-1]) + ' to ' + time_string(unix_end[n_elements(unix_end)-1])

end