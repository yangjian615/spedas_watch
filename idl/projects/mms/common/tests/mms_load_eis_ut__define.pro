;+
;
; Unit tests for mms_load_eis
;
; Requires both the SPEDAS QA folder (not distributed with SPEDAS) and mgunit
; in the local path
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-04-29 14:54:42 -0700 (Fri, 29 Apr 2016) $
; $LastChangedRevision: 20983 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_load_eis_ut__define.pro $
;-
function mms_load_eis_ut::test_load_pad_suffix
  mms_load_eis, datatype='phxtof', level='l2', probe=3, suffix='_p'
  mms_eis_pad, datatype='phxtof', suffix='_p', probe=3
  assert, spd_data_exists('mms3_epd_eis_phxtof_0-1000keV_proton_flux_omni_p_pad_spin mms3_epd_eis_phxtof_0-1000keV_proton_flux_omni_p_pad mms3_epd_eis_phxtof_0-1000keV_oxygen_flux_omni_p_pad_spin mms3_epd_eis_phxtof_0-1000keV_oxygen_flux_omni_p_pad', '2015-12-15', '2015-12-16'), $
    'Problem loading EIS PAD with suffix keyword'
  return, 1
end

function mms_load_eis_ut::test_load_with_suffix
  mms_load_eis, datatype='phxtof', level='l2', probe=4, suffix='_s'
  assert, spd_data_exists('mms4_epd_eis_phxtof_proton_flux_omni_s_spin mms4_epd_eis_phxtof_oxygen_flux_omni_s_spin mms4_epd_eis_phxtof_proton_flux_omni_s mms4_epd_eis_phxtof_oxygen_flux_omni_s mms4_epd_eis_phxtof_proton_P3_flux_t5_s_spin mms4_epd_eis_phxtof_pitch_angle_t0_s', '2015-12-15', '2015-12-16'), $
    'Problem loading EIS PHxTOF data with a suffix'
  return, 1
end

function mms_load_eis_ut::test_phxtof_omni_spec_load
  mms_load_eis, datatype='phxtof', level='l2', probe=1
  assert, spd_data_exists('mms1_epd_eis_phxtof_proton_flux_omni mms1_epd_eis_phxtof_oxygen_flux_omni', '2015-12-15', '2015-12-16'), $
    'Problem loading non-spin averaged omni-directional spectra (phxtof)'
  return, 1
end

function mms_load_eis_ut::test_electron_omni_spec_load
  mms_load_eis, datatype='electronenergy', level='l2', probe=1
  assert, spd_data_exists('mms1_epd_eis_electronenergy_electron_flux_omni', '2015-12-15', '2015-12-16'), $
    'Problem loading non-spin averaged omni-directional spectra (electronenergy)'
  return, 1
end

function mms_load_eis_ut::test_extof_omni_spec_load
  mms_load_eis, datatype='extof', level='l2', probe=1
  assert, spd_data_exists('mms1_epd_eis_extof_proton_flux_omni mms1_epd_eis_extof_alpha_flux_omni mms1_epd_eis_extof_oxygen_flux_omni', '2015-12-15', '2015-12-16'), $
    'Problem loading non-spin averaged omni-directional spectra (extof)'
  return, 1
end

function mms_load_eis_ut::test_load_wrong_en
  mms_load_eis, datatype='phxtof', level='l2'
  mms_eis_pad, energy=[200, 300], datatype='phxtof'
  assert, ~spd_data_exists('mms1_epd_eis_phxtof_200-300keV_proton_flux_omni_pad_spin', '2015-12-15', '2015-12-16'), $
    'Problem with EIS bad energy range test (PAD)'
  return, 1
end

function mms_load_eis_ut::test_load_phxtof_baden
  mms_load_eis, datatype='phxtof', level='l2'
  mms_eis_pad, energy=[50, 40]
  assert, ~spd_data_exists('mms1_epd_eis_phxtof_50-40keV_proton_flux_omni_pad_spin', '2015-12-15', '2015-12-16'), $
    'Problem with EIS bad energy range test (PAD)'
  return, 1
end

function mms_load_eis_ut::test_load_phxtof
  mms_load_eis, datatype='phxtof', level='l2'
  assert, spd_data_exists('mms1_epd_eis_phxtof_proton_flux_omni_spin', '2015-12-15', '2015-12-16'), $
    'Problem loading L2 EIS PHxTOF data'
  return, 1
end

function mms_load_eis_ut::test_load_electron_pad
  del_data, '*'
  mms_load_eis, datatype='electronenergy', level='l2'
  mms_eis_pad, datatype='electronenergy'
  assert, spd_data_exists('mms1_epd_eis_electronenergy_0-1000keV_electron_flux_omni_pad_spin', '2015-12-15', '2015-12-16'), $
    'Problem loading EIS electron PAD'
  return, 1
end

function mms_load_eis_ut::test_load_electron
  del_data, '*'
  mms_load_eis, datatype='electronenergy', level='l2'
  assert, spd_data_exists('mms1_epd_eis_electronenergy_electron_flux_omni_spin', '2015-12-15', '2015-12-16'), $
    'Problem loading EIS electron data'
  return, 1
end

function mms_load_eis_ut::test_pad_limited_en
  mms_eis_pad, energy=[300, 400]
  assert, spd_data_exists('mms1_epd_eis_extof_300-400keV_proton_flux_omni_pad_spin mms1_epd_eis_extof_300-400keV_oxygen_flux_omni_pad_spin', '2015-12-15', '2015-12-16'), $
    'Problem with EIS PAD (limited energy range)'
  return, 1
end

function mms_load_eis_ut::test_brst_caps_pad
  del_data, '*'
  mms_load_eis, data_rate='BRST', level='l2'
  mms_eis_pad, data_rate='BRST'
  assert, spd_data_exists('mms1_epd_eis_brst_extof_0-1000keV_proton_flux_omni_pad_spin mms1_epd_eis_brst_extof_0-1000keV_oxygen_flux_omni_pad_spin', '2015-12-15', '2015-12-16'), $
    'Problem with EIS burst mode PAD (caps)'
  return, 1
end

function mms_load_eis_ut::test_brst_pad
  del_data, '*'
  mms_load_eis, data_rate='brst', level='l2'
  mms_eis_pad, data_rate='brst'
  assert, spd_data_exists('mms1_epd_eis_brst_extof_0-1000keV_proton_flux_omni_pad_spin mms1_epd_eis_brst_extof_0-1000keV_oxygen_flux_omni_pad_spin', '2015-12-15', '2015-12-16'), $
    'Problem with EIS burst mode PAD'
  return, 1
end

function mms_load_eis_ut::test_pad
  mms_eis_pad
  assert, spd_data_exists('mms1_epd_eis_extof_0-1000keV_proton_flux_omni_pad_spin mms1_epd_eis_extof_0-1000keV_oxygen_flux_omni_pad_spin', '2015-12-15', '2015-12-16'), $
    'Problem with EIS PAD'
  return, 1
end

function mms_load_eis_ut::test_load_l2_spdf
  del_data, '*'
  mms_load_eis, probe=1, level='L2', /spdf
  assert, spd_data_exists('mms1_epd_eis_extof_proton_flux_omni_spin mms1_epd_eis_extof_alpha_flux_omni_spin mms1_epd_eis_extof_oxygen_flux_omni_spin', '2015-12-15', '2015-12-16'), $
    'Problem loading L2 EIS data (SPDF)'
  return, 1
end

function mms_load_eis_ut::test_load_l2
  assert, spd_data_exists('mms1_epd_eis_extof_proton_flux_omni_spin mms1_epd_eis_extof_alpha_flux_omni_spin mms1_epd_eis_extof_oxygen_flux_omni_spin', '2015-12-15', '2015-12-16'), $
    'Problem loading L2 EIS data'
  return, 1
end

pro mms_load_eis_ut::setup
  del_data, '*'
  timespan, '2015-12-15/00:00', 1, /day
  mms_load_eis, probe=1, level='L2'
end

function mms_load_eis_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  ; the following adds code coverage % to the output
  self->addTestingRoutine, ['mms_load_eis', 'mms_eis_omni', $
    'mms_eis_pad_spinavg', 'mms_eis_pad', $
    'mms_eis_spin_avg']
  return, 1
end

pro mms_load_eis_ut__define

  define = { mms_load_eis_ut, inherits MGutTestCase }
end