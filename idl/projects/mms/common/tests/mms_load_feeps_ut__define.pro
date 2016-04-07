;+
;
; Unit tests for mms_load_feeps
;
; Requires both the SPEDAS QA folder (not distributed with SPEDAS) and mgunit
; in the local path
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-04-06 09:33:06 -0700 (Wed, 06 Apr 2016) $
; $LastChangedRevision: 20732 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_load_feeps_ut__define.pro $
;-

function mms_load_feeps_ut::test_load_multi_probe
  mms_load_feeps, probes=[1, 2, '3', 4], level='l2'
  assert, spd_data_exists('mms1_epd_feeps_electron_intensity_omni mms2_epd_feeps_electron_intensity_omni mms3_epd_feeps_electron_intensity_omni mms4_epd_feeps_electron_intensity_omni', '2015-12-15', '2015-12-16'), 'Problem with feeps multi probe'
  return, 1
end

function mms_load_feeps_ut::test_smooth
  mms_load_feeps, num_smooth=3.0, level='l2'
  assert, spd_data_exists('mms1_epd_feeps_electron_intensity_omni_smth', '2015-12-15', '2015-12-16'), 'Problem with creating smooted spectra'
  return, 1
end

function mms_load_feeps_ut::test_load_ion
  mms_load_feeps, datatype='ion', level='l2'
  assert, spd_data_exists('mms1_epd_feeps_ion_intensity_omni', '2015-12-15', '2015-12-16'), $
    'Problem with loading ion data'
  return, 1
end

function mms_load_feeps_ut::test_load_ion_brst
  mms_load_feeps, datatype='ion', data_rate='brst', level='l2'
  assert, spd_data_exists('mms1_epd_feeps_ion_intensity_omni', '2015-12-15', '2015-12-16'), $
    'Problem with loading ion burst data'
  return, 1
end

function mms_load_feeps_ut::test_suffix
  mms_load_feeps, level='l2', suffix='_test'
  assert, spd_data_exists('mms1_epd_feeps_electron_intensity_omni_test', '2015-12-15', '2015-12-16'), 'Problem with suffix'
  return, 1
end

function mms_load_feeps_ut::test_pad_limited_en
  mms_feeps_pad, probe=1, energy=[200, 400]
  assert, spd_data_exists('mms1_epd_feeps_200-400keV_pad_spin', '2015-12-15', '2015-12-16'), 'Problem with FEEPS limited energy range PAD'
  return, 1
end

function mms_load_feeps_ut::test_pad_bad_en
  mms_feeps_pad, probe=1, energy=[700, 800]
  assert, ~spd_data_exists('mms1_epd_feeps_700-800keV_pad_spin', '2015-12-15', '2015-12-16'), 'Problem with FEEPS bad energy range PAD'
  return, 1
end

function mms_load_feeps_ut::test_brst_caps_pad
  mms_load_feeps, data_rate='BRST', level='l2'
  mms_feeps_pad, probe=1, data_rate='BRST'
  assert, spd_data_exists('mms1_epd_feeps_0-1000keV_pad_spin', '2015-12-15', '2015-12-16'), 'Problem with FEEPS full energy range PAD (BRST)'
  return, 1
end

function mms_load_feeps_ut::test_brst_pad
  mms_load_feeps, data_rate='brst', level='l2'
  mms_feeps_pad, probe=1, data_rate='brst'
  assert, spd_data_exists('mms1_epd_feeps_0-1000keV_pad_spin', '2015-12-15', '2015-12-16'), 'Problem with FEEPS full energy range PAD (brst)'
  return, 1
end

function mms_load_feeps_ut::test_pad
  mms_feeps_pad, probe=1
  assert, spd_data_exists('mms1_epd_feeps_0-1000keV_pad_spin', '2015-12-15', '2015-12-16'), 'Problem with FEEPS full energy range PAD'
  return, 1
end

function mms_load_feeps_ut::test_load_spdf
  del_data,'*'
  mms_load_feeps, /spdf
  assert, spd_data_exists('mms1_epd_feeps_electron_intensity_omni_spin', '2015-12-15', '2015-12-16'), 'Problem loading L2 FEEPS data (SPDF)'
  return, 1
end

function mms_load_feeps_ut::test_load_l2
  assert, spd_data_exists('mms1_epd_feeps_electron_intensity_omni_spin', '2015-12-15', '2015-12-16'), 'Problem loading L2 FEEPS data'
  return, 1
end

pro mms_load_feeps_ut::setup
  del_data, '*'
  timespan, '2015-12-15/00:00', 1, /day
  mms_load_feeps, probe=1, level='L2'
end

function mms_load_feeps_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  ; the following adds code coverage % to the output
  self->addTestingRoutine, ['mms_load_feeps', 'mms_feeps_omni', $
                            'mms_feeps_pad_spinavg', 'mms_feeps_pad', $
                            'mms_feeps_remove_sun', 'mms_feeps_smooth', $
                            'mms_feeps_spin_avg', 'mms_feeps_split_integral_ch']
  self->addTestingRoutine, ['mms_feeps_sector_masks'], /is_function
  return, 1
end

pro mms_load_feeps_ut__define

  define = { mms_load_feeps_ut, inherits MGutTestCase }
end