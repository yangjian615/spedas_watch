;+
;
; Unit tests for mms_load_fpi
;
; Requires both the SPEDAS QA folder (not distributed with SPEDAS) and mgunit
; in the local path
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-03-16 12:16:42 -0700 (Wed, 16 Mar 2016) $
; $LastChangedRevision: 20477 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_load_fpi_ut__define.pro $
;-

; regression tests ---------->

; user requests a few seconds after file start time
function mms_load_fpi_ut::test_seconds_after_file_start
  mms_load_fpi, trange=['2015-10-15/6:45:21', '2015-10-15/6:51:21'], data_rate='brst', level='l1b'
  assert, spd_data_exists('mms3_dis_bulkSpeed','2015-10-15/06:47:23','2015-10-15/06:54:59'), $
    'Error! Not grabbing the correct data from the SDC???'
  return, 1
end

; user requests a few seconds after file end time
function mms_load_fpi_ut::test_seconds_after_file_end
  mms_load_fpi, trange=['2015-10-15/6:49:21', '2015-10-15/6:54:01'], data_rate='brst', level='l1b'
  assert, spd_data_exists('mms3_dis_bulkSpeed','2015-10-15/06:47:23','2015-10-15/06:54:59'), $
    'Error! Not grabbing the correct data from the SDC???'
  return, 1
end

; user requests a time interval without any CDF files inside
function mms_load_fpi_ut::test_empty_interval
  mms_load_fpi, trange=['2015-10-15/6:46:21', '2015-10-15/6:49:01'], data_rate='brst', level='l1b'
  assert, spd_data_exists('mms3_dis_bulkSpeed','2015-10-15/06:47:23','2015-10-15/06:49:59'), $
    'Error! Not grabbing the correct data from the SDC???'
  return, 1
end

; user requests a time interval just beyond start time (but inside the interval)
; of last burst-mode file for the day
function mms_load_fpi_ut::test_weird_fpi_case
  mms_load_fpi, trange=['2015-10-16/13:07', '2015-10-16/13:09'], data_rate='brst', level='l1b'
  assert, spd_data_exists('mms3_dis_bulkSpeed','2015-10-16/13:07','2015-10-16/13:09'), $
    'Error! Not grabbing the correct data from the SDC???'
  return, 1
end

; end of regression tests <------

function mms_load_fpi_ut::test_load
  mms_load_fpi, probe=4, level='l2', datatype='des-moms'
  assert, spd_data_exists('mms4_des_energyspectr_omni_avg mms4_des_pitchangdist_avg mms4_des_energyspectr_px_fast', '2015-12-15', '2015-12-16'), 'Problem loading fpi data'
  return, 1
end

function mms_load_fpi_ut::test_load_multi_probes
  mms_load_fpi, probe=['1', '4'], level='l2', datatype='des-moms'
  assert, spd_data_exists('mms1_des_energyspectr_omni_avg mms4_des_pitchangdist_avg mms1_des_energyspectr_pz_fast', '2015-12-15', '2015-12-16'), 'Problem loading multiple probe fpi data'
  return, 1
end

function mms_load_fpi_ut::test_load_mixed_probe_type
  mms_load_fpi, probes=['1', 4], level='l2', datatype='des-moms'
  assert, spd_data_exists('mms1_des_energyspectr_omni_avg mms4_des_pitchangdist_avg mms1_des_energyspectr_pz_fast', '2015-12-15', '2015-12-16'), 'Problem loading mixed probe type fpi data'
  return, 1
end

function mms_load_fpi_ut::test_load_level_ql
  mms_load_fpi, probe=1, level='ql'
  assert, spd_data_exists('mms1_des_EnergySpectr_omni_avg mms1_des_energySpectr_pY','2015-12-15', '2015-12-16'), 'Problem loading quicklook fpi data'
  assert, ~spd_data_exists('mms2_dis_TempYY_err','2015-12-15', '2015-12-16'), 'Problem loading quicklook fpi data'
  return, 1
end

function mms_load_fpi_ut::test_load_level_sitl
  mms_load_fpi, probes=[4], level='sitl'
  assert, spd_data_exists('mms4_fpi_ePitchAngDist_avg', '2015-12-15', '2015-12-16'), 'Problem loading fpi data of type sitl'
  return, 1
end

function mms_load_fpi_ut::test_load_data_rate
  mms_load_fpi, probes=1, data_rate='fast', datatype='des-moms'
  assert, spd_data_exists('mms1_des_energyspectr_mz_fast', '2015-12-15', '2015-12-16'), 'Problem loading fpi data with data rate'
  return, 1
end

function mms_load_fpi_ut::test_load_data_rate_caps
  mms_load_fpi, probes='1', data_rate='FAST', datatype='des-moms'
  assert, spd_data_exists('mms1_des_energyspectr_mz_fast', '2015-12-15', '2015-12-16'), 'Problem loading fpi data with data rate with CAPS'
  return, 1
end

function mms_load_fpi_ut::test_load_data_rate_invalid
  mms_load_fpi, probes=['1'], datatype=1234
  assert, ~spd_data_exists('mms1_des_energyspectr_mz_fast', '2015-12-15', '2015-12-16'), 'Problem loading fpi data with invalid data rate'
  return, 1
end

function mms_load_fpi_ut::test_load_dtypes
  mms_load_fpi, probe=1, datatype=['des-moms']
  assert, spd_data_exists('mms1_des_energyspectr_anti_fast mms1_des_pitchangdist_lowen_fast mms1_des_presyz_dbcs_fast', '2015-12-15', '2015-12-16'), 'Problem loading fpi data using data type'
  return, 1
end

function mms_load_fpi_ut::test_load_dtypes_multi
  mms_load_fpi, probe=1, datatype=['des-moms', 'dis-dist']
  assert, spd_data_exists('mms1_des_energyspectr_mx_fast mms1_des_pitchangdist_miden_fast', '2015-12-15', '2015-12-16'), 'Problem loading fpi data type using multiple data types'
  return, 1
end

function mms_load_fpi_ut::test_load_dtypes_caps
  mms_load_fpi, probe=1, datatype='DIS', level='ql'
  assert, spd_data_exists('mms1_dis_startDelPhi_angle', '2015-12-15', '2015-12-16'), 'Problem loading fpi data with data types in CAPS (1)'
  assert, ~spd_data_exists('mms1_des_startDelPhi_angle', '2015-12-15', '2015-12-16'), 'Problem loading fpi data with data types in CAPS (2)'
  return, 1
end

function mms_load_fpi_ut::test_load_dtypes_star
  mms_load_fpi, probe=1, datatype='*'
  assert, spd_data_exists('mms1_des_pitchangdist_avg', '2015-12-15', '2015-12-16'), 'Problem loading fpi data with data types with star (1)'
  assert, ~spd_data_exists('mms3_des_pitchangdist_avg', '2015-12-15', '2015-12-16'), 'Problem loading fpi data with data types with star (2)'
  return, 1
end

function mms_load_fpi_ut::test_load_suffix
  mms_load_fpi, probe=4, level=['sitl'], suffix='_test'
  assert, spd_data_exists('mms4_fpi_startDelPhi_count_test mms4_fpi_eEnergySpectr_pY_test', '2015-12-15', '2015-12-16'), 'Problem loading fpi data using suffix keyword'
  assert, ~spd_data_exists('mms4_fpi_eEnergySpectr_pY', '2015-12-15', '2015-12-16'), 'Problem loading fpi data using suffix keyword'
  return, 1
end

function mms_load_fpi_ut::test_load_time_clip
  mms_load_fpi, probe=1, datatype='DIS', level='ql', time_clip=['2015-12-15 00:04:00', '2015-12-15 00:12:00']
  assert, spd_data_exists('mms1_dis_startDelPhi_angle', '2015-12-15', '2015-12-16'), 'Problem loading fpi data with time_clip'
  return, 1
end

function mms_load_fpi_ut::test_load_spdf
  mms_load_fpi, probe=1, datatype=['des-moms'], /spdf
  assert, spd_data_exists('mms1_des_energyspectr_mx_fast mms1_des_pitchangdist_miden_fast', '2015-12-15', '2015-12-16'), 'Problem loading fpi data type using spdf'
  assert, ~spd_data_exists('mms2_des_energyspectr_mx_fast mms3_des_pitchangdist_miden_fast', '2015-12-15', '2015-12-16'), 'Problem loading fpi data type using spdf'
  return, 1
end

function mms_load_fpi_ut::test_load_trange
  trange=timerange()
  mms_load_fpi, trange=trange, probe=1, datatype=['des-moms'], /spdf
  assert, spd_data_exists('mms1_des_energyspectr_mx_fast mms1_des_pitchangdist_miden_fast', '2015-12-15', '2015-12-16'), 'Problem loading fpi data type using trange'
  return, 1
end

function mms_load_fpi_ut::test_load_future_time
  start_date = systime(/seconds) + 86400.*10.
  stop_date = start_date + 86400.
  mms_load_fpi, trange=[start_date, stop_date], probe=1, datatype=['des-moms']
  assert, ~spd_data_exists('mms1_*', '2040-07-30', '2040-07-31'), 'Problem loading fpi data for date in future'
  return, 1
end

pro mms_load_fpi_ut::setup
  del_data, '*'
  timespan, '2015-12-15', 1, /day
end

function mms_load_fpi_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  ; the following adds code coverage % to the output
  self->addTestingRoutine, ['mms_load_fpi', 'mms_load_fpi_fix_spectra', 'mms_load_fpi_fix_dist', 'mms_load_fpi_fix_angles', $
      'mms_load_fpi_calc_omni', 'mms_load_fpi_calc_pad', 'mms_fpi_fix_metadata']
  return, 1
end

pro mms_load_fpi_ut__define
  define = { mms_load_fpi_ut, inherits MGutTestCase }
end