;+
;
; Unit tests for mms_load_brst_segments
;
; Requires both the SPEDAS QA folder (not distributed with SPEDAS) and mgunit
; in the local path
;
;
; brst segments used in these tests:
;                 start      -    stop
;   2015-10-16: 13:02:24.000 - 13:03:04.000
;   2015-10-16: 13:03:34.000 - 13:04:54.000
; 
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-07-13 14:31:03 -0700 (Wed, 13 Jul 2016) $
; $LastChangedRevision: 21457 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_load_brst_segments_ut__define.pro $
;-
function mms_load_brst_segments_ut::test_load_suffix
  mms_load_brst_segments, trange=['2015-12-15', '2015-12-16'], suffix='_testsuffix'
  assert, spd_data_exists('mms_bss_burst_testsuffix', '2015-12-15', '2015-12-16'), $
    'Problem with the suffix keyword when loading burst segment bar'
  return, 1
end

function mms_load_brst_segments_ut::test_load_singletime
  mms_load_brst_segments, trange=['2015-10-16/13:02:25', '2015-10-16/13:02:25']
  assert, spd_data_exists('mms_bss_burst', '2015-10-16/13:02:24', '2015-10-16/13:02:26'), $
    'Problem loading burst bar with start time = end time in a burst interval'
  return, 1
end

function mms_load_brst_segments_ut::test_load_overlap_two_segs
  mms_load_brst_segments, trange=['2015-10-16/13:03', '2015-10-16/13:04:05']
  assert, spd_data_exists('mms_bss_burst', '2015-10-16/13:03', '2015-10-16/13:04:05'), $
    'Problem loading burst bar with start time after start of an interval and end time before the end of the next interval'
  return, 1
end

function mms_load_brst_segments_ut::test_load_full_day
  mms_load_brst_segments, trange=['2015-10-16', '2015-10-17']
  assert, spd_data_exists('mms_bss_burst', '2015-10-16', '2015-10-17'), $
    'Problem loading burst segments for the full day'
  return, 1
end

function mms_load_brst_segments_ut::test_load_one_interval
  mms_load_brst_segments, trange=['2015-10-16/13:02', '2015-10-16/13:04']
  assert, spd_data_exists('mms_bss_burst', '2015-10-16/13:02', '2015-10-16/13:04'), $
    'Problem loading burst bar for a single interval'
  return, 1
end

function mms_load_brst_segments_ut::test_load_inside_one_interval
  mms_load_brst_segments, trange=['2015-10-16/13:02:30', '2015-10-16/13:03']
  assert, spd_data_exists('mms_bss_burst','2015-10-16/13:02:24', '2015-10-16/13:03:04'), $
    'Problem loading burst bar when requested trange is inside the burst interval'
  return, 1
end

function mms_load_brst_segments_ut::test_load_overlap_starttime
  mms_load_brst_segments, trange=['2015-10-16/13:02:00', '2015-10-16/13:03']
  assert, spd_data_exists('mms_bss_burst', '2015-10-16/13:02:00', '2015-10-16/13:03'), $
    'Problem loading burst bar when we only overlap the start time of an interval'
  return, 1
end

function mms_load_brst_segments_ut::test_load_overlap_endtime
  mms_load_brst_segments, trange=['2015-10-16/13:02:40', '2015-10-16/13:03:06']
  assert, spd_data_exists('mms_bss_burst', '2015-10-16/13:02:40', '2015-10-16/13:03:06'), $
    'Problem loading burst bar when we only overlap the end time of an interval'
  return, 1
end

function mms_load_brst_segments_ut::test_exact_range
  mms_load_brst_segments, trange=['2015-10-16/13:02:24', '2015-10-16/13:03:04']
  assert, spd_data_exists('mms_bss_burst', '2015-10-16/13:02:24', '2015-10-16/13:03:04'), $
    'Problem loading burst bar when using the exact trange of the burst interval'
  return, 1
end

pro mms_load_brst_segments_ut::setup
  del_data, '*'
end

function mms_load_brst_segments_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  ; the following adds code coverage % to the output
  self->addTestingRoutine, ['mms_load_brst_segments']
  return, 1
end

pro mms_load_brst_segments_ut__define

  define = { mms_load_brst_segments_ut, inherits MGutTestCase }
end