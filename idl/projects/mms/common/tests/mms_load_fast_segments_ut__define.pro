;+
;
; Unit tests for mms_load_fast_segments
;
; Requires both the SPEDAS QA folder (not distributed with SPEDAS) and mgunit
; in the local path
;
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-07-13 14:31:03 -0700 (Wed, 13 Jul 2016) $
; $LastChangedRevision: 21457 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_load_fast_segments_ut__define.pro $
;-
function mms_load_fast_segments_ut::test_overlap_start
  mms_load_fast_segments, trange=['2015-10-16/5:02:00', '2015-10-16/13:02:25']
  assert, spd_data_exists('mms_bss_fast', '2015-10-16/5:02:00', '2015-10-16/13:02:25'), $
    'Problem loading fast segment bar when the user requests a time that overlaps the start time'
  return, 1
end

function mms_load_fast_segments_ut::test_suffix_keyword
  mms_load_fast_segments, trange=['2015-12-15', '2015-12-16'], suffix='_testsuffix'
  assert, spd_data_exists('mms_bss_fast_testsuffix', '2015-12-15', '2015-12-16'), $
    'Problem with suffix keyword in mms_load_fast_segments'
  return, 1
end

function mms_load_fast_segments_ut::test_exact_range
  mms_load_fast_segments, trange=['2015-10-16/05:02:34', '2015-10-16/16:33:54']
  assert, spd_data_exists('mms_bss_fast', '2015-10-16/05:02:34', '2015-10-16/16:33:54'), $
    'Problem loading fast bar when using the exact trange'
  return, 1
end

function mms_load_fast_segments_ut::test_multi_days
  mms_load_fast_segments, trange=['2015-12-1', '2015-12-16']
  assert, spd_data_exists('mms_bss_fast', '2015-12-1', '2015-12-16'), $
    'Problem loading fast bar for multiple days'
  return, 1
end

pro mms_load_fast_segments_ut::setup
  del_data, '*'
end

function mms_load_fast_segments_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  ; the following adds code coverage % to the output
  self->addTestingRoutine, ['mms_load_fast_segments']
  return, 1
end

pro mms_load_fast_segments_ut__define
  define = { mms_load_fast_segments_ut, inherits MGutTestCase }
end