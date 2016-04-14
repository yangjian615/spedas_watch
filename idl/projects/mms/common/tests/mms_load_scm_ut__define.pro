;+
;
; Unit tests for mms_load_scm
;
; Requires both the SPEDAS QA folder (not distributed with SPEDAS) and mgunit
; in the local path
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-03-16 12:16:42 -0700 (Wed, 16 Mar 2016) $
; $LastChangedRevision: 20477 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_load_scm_ut__define.pro $
;-

function mms_load_scm_ut::test_load
  mms_load_scm, probe=4
  assert, spd_data_exists('mms4_scm_acb_gse_scsrvy_srvy_l2', '2015-12-15', '2015-12-16'), 'Problem loading scm data'
  return, 1
end

function mms_load_scm_ut::test_load_multi_probes
  mms_load_scm, probe=['1', '4'], level='l2'
  assert, spd_data_exists('mms1_scm_acb_gse_scsrvy_srvy_l2 mms4_scm_acb_gse_scsrvy_srvy_l2', '2015-12-15', '2015-12-16'), 'Problem loading multiple probe scm data'
  return, 1
end

function mms_load_scm_ut::test_load_mixed_probe_type
  mms_load_scm, probes=['1', 3], level='l2'
  assert, spd_data_exists('mms1_scm_acb_gse_scsrvy_srvy_l2 mms3_scm_acb_gse_scsrvy_srvy_l2', '2015-12-15', '2015-12-16'), 'Problem loading using mixed probe types'
  assert, ~spd_data_exists('mms2_scm_acb_gse_scsrvy_srvy_l2', '2015-12-15', '2015-12-16'), 'Problem loading using mixed probe types'
  return, 1
end

function mms_load_scm_ut::test_load_level_1a
  mms_load_scm, probe=1, level='l1a'
  assert, spd_data_exists('mms1_scm_acb_scm123_scsrvy_srvy_l1a', '2015-12-15', '2015-12-16'), 'Problem loading l1a scm data'
  return, 1
end

function mms_load_scm_ut::test_load_level_1b
  mms_load_scm, probes=[4], level='l1b'
  assert, spd_data_exists('mms4_scm_acb_scm123_scsrvy_srvy_l1b', '2015-12-15', '2015-12-16'), 'Problem loading scm data for l1b'
  return, 1
end

function mms_load_scm_ut::test_load_brst
  mms_load_scm, probes=1, data_rate='brst'
  assert, spd_data_exists('mms1_scm_acb_gse_scb_brst_l2', '2015-12-15', '2015-12-16'), 'Problem loading scm brst data'
  return, 1
end

function mms_load_scm_ut::test_load_slow_data_caps
  mms_load_scm, probes='1', data_rate='SLOW', trange=['2015-8-15', '2015-8-16']
  assert, spd_data_exists('mms1_scm_scs_gse', '2015-8-15', '2015-8-16'), 'Problem loading scm SLOW data rate with CAPS'
  return, 1
end

function mms_load_scm_ut::test_load_multiple_data_rates 
  mms_load_scm, probes='1', data_rate=['srvy', 'fast']
  assert, spd_data_exists('mms1_scm_acb_gse_scsrvy_srvy_l2 mms1_scm_acb_gse_scsrvy_srvy_l2', '2015-12-15', '2015-12-16'), 'Problem loading scm with multiple data rates'
  return, 1
end

function mms_load_scm_ut::test_load_data_rate_invalid
  mms_load_scm, probes=['1'], data_rate=1234
  assert, ~spd_data_exists('mms1_scm_acb_gse_scsrvy_srvy_l2', '2015-12-15', '2015-12-16'), 'Problem loading scm data with invalid data rate'
  return, 1
end

function mms_load_scm_ut::test_load_dtypes
  mms_load_scm, probe=1, datatype=['cal']
  assert, spd_data_exists('mms1_scm_acb_gse_scsrvy_srvy_l2', '2015-12-15', '2015-12-16'), 'Problem loading scm data using data type'
  return, 1
end

function mms_load_scm_ut::test_load_dtypes_multi
  mms_load_scm, probe=1, datatype=['scb', 'scf', 'schb']
  assert, spd_data_exists('mms1_scm_acb_gse_scsrvy_srvy_l2', '2015-12-15', '2015-12-16'), 'Problem loading scm data type using multiple data types'
  return, 1
end

function mms_load_scm_ut::test_load_dtypes_caps
  mms_load_scm, probe=1, datatype='SCS'
  assert, spd_data_exists('mms1_scm_acb_gse_scsrvy_srvy_l2', '2015-12-15', '2015-12-16'), 'Problem loading scm data with data types in CAPS'
  return, 1
end

function mms_load_scm_ut::test_load_dtypes_asterick
  mms_load_scm, probe=1, datatype='*', data_rate=['srvy', 'brst']
  assert, spd_data_exists('mms1_scm_acb_gse_scb_brst_l2 mms1_scm_acb_gse_scsrvy_srvy_l2', '2015-12-15', '2015-12-16'), 'Problem loading scm data with datatype=*'
  return, 1
end

function mms_load_scm_ut::test_load_suffix
  mms_load_scm, probe=4, suffix='_test'
  assert, spd_data_exists('mms4_scm_acb_gse_scsrvy_srvy_l2_test', '2015-12-15', '2015-12-16'), 'Problem loading scm data using suffix keyword'
  assert, ~spd_data_exists('mms4_scm_acb_gse_scsrvy_srvy_l2', '2015-12-15', '2015-12-16'), 'Problem loading scm data using suffix keyword'
  return, 1
end

function mms_load_scm_ut::test_load_time_clip
  mms_load_scm, probe=1, time_clip=['2015-12-15/04:00:00', '2015-12-15/08:00:00']
  assert, spd_data_exists('mms1_scm_acb_gse_scsrvy_srvy_l2', '2015-12-15/04:00:00', '2015-12-15/08:00:00'), 'Problem loading scm data with time_clip'
  return, 1
end

function mms_load_scm_ut::test_load_spdf
  mms_load_scm, probe=1, /spdf
  assert, spd_data_exists('mms1_scm_acb_gse_scsrvy_srvy_l2', '2015-12-15', '2015-12-16'), 'Problem loading scm data type using spdf'
  return, 1
end

function mms_load_scm_ut::test_load_get_support_data
  mms_load_scm, probe=1, /get_support_data
  assert, spd_data_exists('mms1_scm_acb_gse_scsrvy_srvy_l2', '2015-12-15', '2015-12-16'), 'Problem loading scm data with get_support_data keyword set'
  return, 1
end

function mms_load_scm_ut::test_load_trange
  trange=timerange()-86400.
  mms_load_scm, trange=trange, probe=1
  assert, spd_data_exists('mms1_scm_acb_gse_scsrvy_srvy_l2', '2015-12-14', '2015-12-15'), 'Problem loading scm data using trange'
  return, 1
end

function mms_load_scm_ut::test_load_future_time
  start_date = systime(/seconds) + 86400.*10.
  stop_date = start_date + 86400.
  mms_load_scm, trange=[start_date, stop_date], probe=1 
  assert, ~spd_data_exists('mms1_scm_acb_gse_scsrvy_srvy_l2', '2040-07-30', '2040-07-31'), 'Problem loading scm data for date in future'
  return, 1
end

pro mms_load_scm_ut::setup
  del_data, '*'
  timespan, '2015-12-15', 1, /day
end

function mms_load_scm_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  ; the following adds code coverage % to the output
  self->addTestingRoutine, ['mms_load_scm', 'mms_set_scm_options']
  return, 1
end

pro mms_load_scm_ut__define

  define = { mms_load_scm_ut, inherits MGutTestCase }
end