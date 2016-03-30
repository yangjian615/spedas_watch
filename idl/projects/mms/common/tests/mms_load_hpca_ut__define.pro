;+
;
; Unit tests for mms_load_hpca
;
; Requires both the SPEDAS QA folder (not distributed with SPEDAS) and mgunit
; in the local path
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-03-29 08:29:38 -0700 (Tue, 29 Mar 2016) $
; $LastChangedRevision: 20618 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_load_hpca_ut__define.pro $
;-

; regression test for bug reported by Karlheinz Trattner, 3/23/2016
function mms_load_hpca_ut::test_load_startaz
    ; load the data
    mms_load_hpca, probes=probes, datatype='flux', level='l1b', data_rate='srvy',/get_support_data
    mms_hpca_calc_anodes, fov=[0, 360], probe=probes
    mms_hpca_spin_sum, probe=probes, species='hplus',fov=[0,360],datatype='flux'
    assert, spd_data_exists('mms1_hpca_start_azimuth mms1_hpca_hplus_flux_elev_0-360 mms1_hpca_hplus_flux_elev_0-360_spin', '2015-10-22/06:00', '2015-10-22/06:10'), 'Problem loading HPCA data (startaz regression?)'
    return, 1
end

function mms_load_hpca_ut::test_load_startaz_nosupp
  ; load the data
  mms_load_hpca, probes=probes, datatype='flux', level='l1b', data_rate='srvy'
  mms_hpca_calc_anodes, fov=[0, 360], probe=probes
  mms_hpca_spin_sum, probe=probes, species='hplus',fov=[0,360],datatype='flux'
  assert, spd_data_exists('mms1_hpca_start_azimuth mms1_hpca_hplus_flux_elev_0-360 mms1_hpca_hplus_flux_elev_0-360_spin', '2015-10-22/06:00', '2015-10-22/06:10'), 'Problem loading HPCA data (startaz regression?)'
  return, 1
end

function mms_load_hpca_ut::test_load_startaz_nosupp_l2
  ; load the data
  mms_load_hpca, probes=probes, datatype='flux', level='l2', data_rate='srvy'
  mms_hpca_calc_anodes, fov=[0, 360], probe=probes
  mms_hpca_spin_sum, probe=probes, species='hplus',fov=[0,360],datatype='flux'
  assert, spd_data_exists('mms1_hpca_start_azimuth mms1_hpca_hplus_flux_elev_0-360 mms1_hpca_hplus_flux_elev_0-360_spin', '2015-10-22/06:00', '2015-10-22/06:10'), 'Problem loading HPCA data (startaz regression?)'
  return, 1
end

pro mms_load_hpca_ut::setup
    del_data, '*'
    timespan, '2015-10-22/06:00', 10., /minutes 
end

function mms_load_hpca_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  ; the following adds code coverage % to the output
  self->addTestingRoutine, ['mms_load_hpca', 'mms_hpca_calc_anodes', 'mms_hpca_set_metadata']
  self->addTestingRoutine, ['mms_hpca_sum_fov', 'mms_hpca_avg_fov', 'mms_hpca_anodes', 'mms_hpca_energies', 'mms_hpca_elevations'], /is_function
  return, 1
end

pro mms_load_hpca_ut__define

    define = { mms_load_hpca_ut, inherits MGutTestCase }
end