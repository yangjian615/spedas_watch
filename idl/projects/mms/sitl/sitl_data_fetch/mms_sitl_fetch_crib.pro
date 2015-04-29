; Crib sheet showing how to fetch mag data

cache_dir = '/Users/frederickwilder/'
start_date = '2015-04-10'
end_date = '2015-04-11'

;; Get mms2 data
;mms_sitl_get_dcb, start_date, end_date, cache_dir, afg_status, dfg_status, sc_id='mms2'
;
;;; Forget to include sc_id - will default to 'mms1,' but there is no data.
;mms_sitl_get_dcb, start_date, end_date, cache_dir, afg_status2, dfg_status2
;
;; Lets try e spectrum
;mms_sitl_get_espec, start_date, end_date, cache_dir, data_status, sc_id='mms2'
;
;; Now bspectrum
;mms_sitl_get_bspec, start_date, end_date, cache_dir, data_status, sc_id='mms2'

;mms_sitl_get_dce, start_date, end_date, cache_dir, data_status, sc_id='mms2'

; Lets try out this nasty level sorting stuff

;mms_get_single_data_file, local_filename, cache_dir, start_date, end_date, login_flag, 'afg', file_base, sc_id='mms2', $
;  mode='srvy', level='ql'

;mms_check_local_cache_level_sort, local_filename, cache_dir, start_date, end_date, login_flag, 'afg', file_base, sc_id='mms2', $
;    mode='srvy'

mms_check_local_cache_level_sort, local_filename, cache_dir, start_date, end_date, file_flag, file_base, $
  'afg', sc_id='mms2', mode='srvy'

end