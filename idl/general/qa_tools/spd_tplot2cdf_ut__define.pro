;+
;
; Unit tests for tplot2cdf2
;
; To run:
;     IDL> mgunit, 'spd_tplot2cdf_ut'
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2018-01-25 12:51:41 -0800 (Thu, 25 Jan 2018) $
; $LastChangedRevision: 24592 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/qa_tools/spd_tplot2cdf_ut__define.pro $
;-


function spd_tplot2cdf_ut::test_save_times
  store_data, 'test_times', data={x: time_double('2018-01-01')+[1, 2, 3, 4], y: [5, 5, 5, 5]}
  tplot2cdf2, tvars='test_times', filename='test_times.cdf', /default
  del_data, '*'
  cdf2tplot, 'test_times.cdf'
  get_data, 'test_times', data=d
  assert, array_equal(d.X, time_double('2018-01-01')+[1, 2, 3, 4]), 'Problem with times in CDF file saved by tplot2cdf'
  return, 1
end

function spd_tplot2cdf_ut::test_save_largenum
  store_data, 'test_largenum', data={x: time_double('2018-01-01')+[1, 2, 3, 4], y: [999999999999999999, 5, 5, 5]}
  tplot2cdf2, tvars='test_largenum', filename='test_largenum.cdf', /default
  del_data, '*'
  cdf2tplot, 'test_largenum.cdf'
  get_data, 'test_largenum', data=d
  assert, array_equal(d.Y, [999999999999999999, 5, 5, 5]), 'Problem with large number in CDF file saved by tplot2cdf'
  return, 1
end

function spd_tplot2cdf_ut::test_save_float
  floatvals = indgen(4, /float)
  store_data, 'test_float', data={x: time_double('2018-01-01')+[1, 2, 3, 4], y: indgen(4, /float)}
  tplot2cdf2, tvars='test_float', filename='test_float.cdf', /default
  del_data, '*'
  cdf2tplot, 'test_float.cdf'
  get_data, 'test_float', data=d
  assert, array_equal(d.Y, floatvals), 'Problem with floats in CDF file saved by tplot2cdf'
  return, 1
end

function spd_tplot2cdf_ut::test_fpi_multidimensional_data
  mms_load_fpi, trange=['2015-12-15', '2015-12-16'], datatype='des-dist', probe=3
  get_data, 'mms3_des_dist_fast', data=original
  tplot2cdf2, tvars='mms3_des_dist_fast', filename='test_fpi_dist.cdf'
  del_data, '*'
  mms_cdf2tplot, 'test_fpi_dist.cdf', /all
  get_data, 'mms3_des_dist_fast', data=d
  assert, array_equal(original.Y, d.Y) && array_equal(original.x, d.x) && array_equal(original.v1, d.v1) && array_equal(original.v2, d.v2) && array_equal(original.v3, d.v3), 'Problem with multi-dimensional FPI data'
  return, 1
end

function spd_tplot2cdf_ut::test_hpca_multidimensional_data
  mms_load_hpca, trange=['2015-12-15', '2015-12-16'], datatype='ion', probe=3
  get_data, 'mms3_hpca_hplus_phase_space_density', data=original
  tplot2cdf2, tvars='mms3_hpca_hplus_phase_space_density', filename='test_hpca_dist.cdf'
  del_data, '*'
  mms_cdf2tplot, 'test_hpca_dist.cdf'
  get_data, 'mms3_hpca_hplus_phase_space_density', data=d
  assert, array_equal(original.Y, d.Y) && array_equal(original.x, d.x) && array_equal(original.v1, d.v1) && array_equal(original.v2, d.v2), 'Problem with saving HPCA dist to file'
  return, 1
end

function spd_tplot2cdf_ut::test_rbsp_spec
  rbsp_load_rbspice, probe='a', trange=['2015-10-16', '2015-10-17'], datatype='TOFxEH', level='l3'
  get_data, 'rbspa_rbspice_l3_TOFxEH_proton_omni_spin', data=original
  tplot2cdf2, tvars='rbspa_rbspice_l3_TOFxEH_proton_omni_spin', filename='rbsp_data.cdf'
  del_data, '*'
  mms_cdf2tplot, 'rbsp_data.cdf', /all
  get_data, 'rbspa_rbspice_l3_TOFxEH_proton_omni_spin', data=d
  assert, array_equal(original.X, d.X) && array_equal(original.Y, d.Y) && array_equal(original.v, d.v), 'Problem with saving RBSP data to a CDF file'
  return, 1
end

pro spd_tplot2cdf_ut::setup
  del_data, '*'
end

function spd_tplot2cdf_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  ; the following adds code coverage % to the output
  self->addTestingRoutine, ['tplot2cdf2']
  return, 1
end

pro spd_tplot2cdf_ut__define
  define = { spd_tplot2cdf_ut, inherits MGutTestCase }
end