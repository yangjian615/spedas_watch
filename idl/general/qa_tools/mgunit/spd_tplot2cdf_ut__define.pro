;+
;
; Unit tests for tplot2cdf
;
; To run:
;     IDL> mgunit, 'spd_tplot2cdf_ut'
;
; $LastChangedBy: adrozdov $
; $LastChangedDate: 2018-02-09 16:47:26 -0800 (Fri, 09 Feb 2018) $
; $LastChangedRevision: 24685 $
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

function spd_tplot2cdf_ut::test_save_tt2000  
  store_data, 'test_tt2000', data={x: time_double('2018-01-01')+[1, 2, 3, 4], y: indgen(4)}
  tplot2cdf, tvars='test_tt2000', filename='test_tt2000.cdf', /default, /tt2000
  del_data, '*'
  id = CDF_OPEN('test_tt2000.cdf')
  CDF_VARGET, id, 'Epoch', Epoch
  CDF_CLOSE, id
  assert, size(Epoch, /type) eq 14, 'Saved TT2000 Epoch is not in LONG64 format'
  return, 1
end

function spd_tplot2cdf_ut::test_save_tt2000_long64
  EpochL = CDF_PARSE_TT2000('2005-12-04T20:19:18.176214648') + long64(indgen(4))
  Y = indgen(4)
  store_data, 'test_save_tt2000_long64', data={x: EpochL, y: Y}
  tplot2cdf, tvars='test_save_tt2000_long64', filename='test_save_tt2000_long64.cdf', /default, /tt2000
  del_data, '*'
  id = CDF_OPEN('test_save_tt2000_long64.cdf')
  CDF_VARGET, id, 'Epoch', Epoch_cdf, REC_COUNT=4
  CDF_VARGET, id, 'test_save_tt2000_long64', Y_cdf, REC_COUNT=4
  CDF_CLOSE, id
  assert, size(Epoch_cdf, /type) eq 14, 'Saved TT2000 Epoch is not in LONG64 format'
  assert, array_equal(EpochL, Epoch_cdf) and array_equal(Y, Y_cdf), 'Saved in CDF file data is different from tplot data'
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