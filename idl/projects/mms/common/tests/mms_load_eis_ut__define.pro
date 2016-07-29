;+
;
; Unit tests for mms_load_eis
;
; Requires both the SPEDAS QA folder (not distributed with SPEDAS) and mgunit
; in the local path
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-07-28 13:00:42 -0700 (Thu, 28 Jul 2016) $
; $LastChangedRevision: 21557 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_load_eis_ut__define.pro $
;-

function mms_load_eis_ut::test_yrange_of_spectra
  mms_load_eis, datatype='phxtof', level='l2', probe=1
  get_data, 'mms1_epd_eis_phxtof_proton_flux_omni_spin', limits=l
  assert, array_equal(l.yrange, [14, 45]), 'Problem with yrange of L2 PHxTOF proton variable'
  
  mms_load_eis, datatype='extof', level='l2', probe=1
  get_data, 'mms1_epd_eis_extof_proton_flux_omni_spin', limits=proton_l
  get_data, 'mms1_epd_eis_extof_alpha_flux_omni_spin', limits=alpha_l
  get_data, 'mms1_epd_eis_extof_oxygen_flux_omni_spin', limits=oxygen_l
  assert, array_equal(proton_l.yrange, [55, 1000]), 'Problem with yrange of L2 ExTOF proton variable'
  assert, array_equal(alpha_l.yrange, [80, 650]), 'Problem with yrange of L2 ExTOF alpha variable'
  assert, array_equal(oxygen_l.yrange, [145, 950]), 'Problem with yrange of L2 ExTOF oxygen variable'
  
  mms_load_eis, datatype='electronenergy', level='l2', probe=1
  get_data, 'mms1_epd_eis_electronenergy_electron_flux_omni_spin', limits=electrons_l
  assert, array_equal(electrons_l.yrange, [40, 660]), 'Problem with yrange of L2 electronenergy variable'
  
  del_data, '*'
  
  ; the following will break when the L1b files are updated to v3
  mms_load_eis, datatype='phxtof', level='l1b', probe=1
  get_data, 'mms1_epd_eis_phxtof_proton_flux_omni_spin', limits=l1b_l
  assert, array_equal(l1b_l.yrange, [10, 28]), 'Problem with yrange of L1b PHxTOF proton variable'
  
  return, 1
end

function mms_load_eis_ut::test_yrange_of_spectra_brst
  mms_load_eis, datatype='phxtof', level='l2', probe=1, data_rate='brst'
  get_data, 'mms1_epd_eis_brst_phxtof_proton_flux_omni_spin', limits=l
  assert, array_equal(l.yrange, [14, 45]), 'Problem with yrange of L2 PHxTOF proton variable (brst)'

  mms_load_eis, datatype='extof', level='l2', probe=1, data_rate='brst'
  get_data, 'mms1_epd_eis_brst_extof_proton_flux_omni_spin', limits=proton_l
  get_data, 'mms1_epd_eis_brst_extof_alpha_flux_omni_spin', limits=alpha_l
  get_data, 'mms1_epd_eis_brst_extof_oxygen_flux_omni_spin', limits=oxygen_l
  assert, array_equal(proton_l.yrange, [55, 1000]), 'Problem with yrange of L2 ExTOF proton variable (brst)'
  assert, array_equal(alpha_l.yrange, [80, 650]), 'Problem with yrange of L2 ExTOF alpha variable (brst)'
  assert, array_equal(oxygen_l.yrange, [145, 950]), 'Problem with yrange of L2 ExTOF oxygen variable (brst)'

  del_data, '*'

  ; the following will break when the L1b files are updated to v3
  mms_load_eis, datatype='phxtof', level='l1b', probe=1, data_rate='brst'
  get_data, 'mms1_epd_eis_brst_phxtof_proton_flux_omni_spin', limits=l1b_l
  assert, array_equal(l1b_l.yrange, [10, 28]), 'Problem with yrange of L1b PHxTOF proton variable (brst)'

  return, 1
end
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

function mms_load_eis_ut::test_load_timeclip
  del_data, '*'
  mms_load_eis, trange=['2015-12-15/11:00', '2015-12-15/12:00'], /time_clip
  assert, spd_data_exists('mms1_epd_eis_extof_proton_flux_omni_spin mms1_epd_eis_extof_alpha_flux_omni_spin mms1_epd_eis_extof_oxygen_flux_omni_spin', '2015-12-15/11:00', '2015-12-15/12:00'), $
    'Problem loading L2 EIS data with time clipping'
  assert, ~spd_data_exists('mms1_epd_eis_extof_proton_flux_omni_spin mms1_epd_eis_extof_alpha_flux_omni_spin mms1_epd_eis_extof_oxygen_flux_omni_spin', '2015-12-15/10:00', '2015-12-15/11:00'), $
    'Problem loading L2 EIS data with time clipping'
  assert, ~spd_data_exists('mms1_epd_eis_extof_proton_flux_omni_spin mms1_epd_eis_extof_alpha_flux_omni_spin mms1_epd_eis_extof_oxygen_flux_omni_spin', '2015-12-15/12:00', '2015-12-15/13:00'), $
    'Problem loading L2 EIS data with time clipping'
  return, 1
end

function mms_load_eis_ut::test_pad_binsize
  mms_eis_pad, bin_size=3
  get_data, 'mms1_epd_eis_extof_0-1000keV_proton_flux_omni_pad_spin', data=d
  assert, n_elements(d.V) eq 61, 'Problem with bin_size keyword in mms_eis_pad'
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
    'mms_eis_pad_spinavg', 'mms_eis_pad', 'mms_eis_set_metadata', $
    'mms_eis_spin_avg']
  return, 1
end

pro mms_load_eis_ut__define

  define = { mms_load_eis_ut, inherits MGutTestCase }
end