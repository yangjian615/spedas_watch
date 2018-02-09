;+
;
; Unit tests for tplot2cdf
;
; To run:
;     IDL> mgunit, 'spd_tplot2cdf_ut'
;
; $LastChangedBy: adrozdov $
; $LastChangedDate: 2018-02-07 21:18:39 -0800 (Wed, 07 Feb 2018) $
; $LastChangedRevision: 24667 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/qa_tools/mgunit/spd_tplot2cdf_ut__define.pro $
;-


function spd_tplot2cdf_ut::test_save_times
  store_data, 'test_times', data={x: time_double('2018-01-01')+[1, 2, 3, 4], y: [5, 5, 5, 5]}
  tplot2cdf, tvars='test_times', filename='test_times.cdf', /default
  del_data, '*'
  cdf2tplot, 'test_times.cdf'
  get_data, 'test_times', data=d
  assert, array_equal(d.X, time_double('2018-01-01')+[1, 2, 3, 4]), 'Problem with times in CDF file saved by tplot2cdf'
  return, 1
end

function spd_tplot2cdf_ut::test_save_largenum
  store_data, 'test_largenum', data={x: time_double('2018-01-01')+[1, 2, 3, 4], y: [999999999999999999, 5, 5, 5]}
  tplot2cdf, tvars='test_largenum', filename='test_largenum.cdf', /default
  del_data, '*'
  cdf2tplot, 'test_largenum.cdf'
  get_data, 'test_largenum', data=d
  assert, array_equal(d.Y, [999999999999999999, 5, 5, 5]), 'Problem with large number in CDF file saved by tplot2cdf'
  return, 1
end

function spd_tplot2cdf_ut::test_save_float
  floatvals = indgen(4, /float)
  store_data, 'test_float', data={x: time_double('2018-01-01')+[1, 2, 3, 4], y: indgen(4, /float)}
  tplot2cdf, tvars='test_float', filename='test_float.cdf', /default
  del_data, '*'
  cdf2tplot, 'test_float.cdf'
  get_data, 'test_float', data=d
  assert, array_equal(d.Y, floatvals), 'Problem with floats in CDF file saved by tplot2cdf'
  return, 1
end

pro spd_tplot2cdf_ut::setup
  del_data, '*'
end

function spd_tplot2cdf_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  ; the following adds code coverage % to the output
  self->addTestingRoutine, ['tplot2cdf']
  return, 1
end

pro spd_tplot2cdf_ut__define
  define = { spd_tplot2cdf_ut, inherits MGutTestCase }
end