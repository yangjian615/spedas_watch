;+
;
; Unit tests for mms_part_getspec
;
;
;
; Requires both the SPEDAS QA folder (not distributed with SPEDAS)
; and mgunit in the local path.
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2017-07-13 16:10:34 -0700 (Thu, 13 Jul 2017) $
; $LastChangedRevision: 23611 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_part_getspec_ut__define.pro $
;-

function mms_part_getspec_ut::test_theta_limits_fpi
  mms_part_getspec, probe=4, trange=['2015-12-15/10:50', '2015-12-15/11:00'], theta=[0, 90]
  get_data, 'mms4_des_dist_fast_theta', data=d
  assert, total(finite(d.Y[0, 8:*])) eq 0, 'Problem with theta limits for FPI'
  return, 1
end

function mms_part_getspec_ut::test_theta_limits_fpi_brst
  mms_part_getspec, probe=4, trange=['2015-10-16/13:06', '2015-10-16/13:07'], theta=[0, 90], data_rate='brst'
  get_data, 'mms4_des_dist_brst_theta', data=d
  assert, total(finite(d.Y[0, 8:*])) eq 0, 'Problem with theta limits for FPI (brst)'
  return, 1
end

function mms_part_getspec_ut::test_theta_limits_hpca
  mms_part_getspec, probe=4, trange=['2015-12-15/10:00', '2015-12-15/11:00'], instrument='hpca', theta=[0, 90]
  get_data, 'mms4_hpca_hplus_phase_space_density_theta', data=d
  assert, total(finite(d.Y[0, 8:*])) eq 0, 'Problem with theta limits for HPCA!'
  return, 1
end

function mms_part_getspec_ut::test_theta_limits_hpca_brst
  mms_part_getspec, probe=4, trange=['2015-10-16/13:06', '2015-10-16/13:07'], instrument='hpca', theta=[0, 90], data_rate='brst'
  get_data, 'mms4_hpca_hplus_phase_space_density_theta', data=d
  assert, total(finite(d.Y[0, 8:*])) eq 0, 'Problem with theta limits for HPCA! (brst)'
end

function mms_part_getspec_ut::test_phi_limits_fpi
  mms_part_getspec, probe=4, trange=['2015-12-15/10:50', '2015-12-15/11:00'], phi=[0, 175]
  get_data, 'mms4_des_dist_fast_phi', data=d
  assert, total(finite(d.Y[0, 16:-2])) eq 0, 'Problem with phi limits for FPI'
  return, 1
end

function mms_part_getspec_ut::test_phi_limits_fpi_brst
  mms_part_getspec, probe=4, trange=['2015-10-16/13:06', '2015-10-16/13:07'], phi=[0, 175], data_rate='brst'
  get_data, 'mms4_des_dist_brst_phi', data=d
  assert, total(finite(d.Y[0, 16:-2])) eq 0, 'Problem with phi limits for FPI (brst)'
  return, 1
end

function mms_part_getspec_ut::test_phi_limits_hpca
  mms_part_getspec, probe=1, trange=['2015-12-15/10:00', '2015-12-15/11:00'], phi=[0, 175], instrument='hpca'
  get_data, 'mms1_hpca_hplus_phase_space_density_phi', data=d
  assert, total(finite(d.Y[0, 8:-2])) eq 0, 'Problem with phi limits for HPCA'
  return, 1
end

function mms_part_getspec_ut::test_phi_limits_hpca_brst
  mms_part_getspec, probe=1, trange=['2015-10-16/13:06', '2015-10-16/13:07'], phi=[0, 175], instrument='hpca', data_rate='brst'
  get_data, 'mms1_hpca_hplus_phase_space_density_phi', data=d
  assert, total(finite(d.Y[0, 8:-2])) eq 0, 'Problem with phi limits for HPCA (brst)'
  return, 1
end

function mms_part_getspec_ut::test_energy_limits_fpi_brst
  mms_part_getspec, probe=4, trange=['2015-10-16/13:06', '2015-10-16/13:07'], energy=[0, 100], data_rate='brst'
  get_data, 'mms4_des_dist_brst_energy', data=d
  assert, total(finite(d.Y[0, 9:*])) eq 0, 'Problem with energy limits for FPI (brst)'
  return, 1
end

function mms_part_getspec_ut::test_energy_limits_fpi
  mms_part_getspec, probe=4, trange=['2015-12-15/10:00', '2015-12-15/11:00'], energy=[0, 100]
  get_data, 'mms4_des_dist_fast_energy', data=d
  assert, total(finite(d.Y[0, 9:*])) eq 0, 'Problem with energy limits for FPI'
  return, 1
end

function mms_part_getspec_ut::test_energy_limits_hpca_brst
  mms_part_getspec, probe=1, trange=['2015-12-15/10:00', '2015-12-15/11:00'], energy=[0, 100], instrument='hpca', data_rate='brst'
  get_data, 'mms1_hpca_hplus_phase_space_density_energy', data=d
  assert, total(finite(d.Y[0, 27:*])) eq 0, 'Problem with energy limits for HPCA (brst)'
  return, 1
end

function mms_part_getspec_ut::test_energy_limits_hpca
  mms_part_getspec, probe=1, trange=['2015-12-15/10:00', '2015-12-15/11:00'], energy=[0, 100], instrument='hpca'
  get_data, 'mms1_hpca_hplus_phase_space_density_energy', data=d
  assert, total(finite(d.Y[0, 27:*])) eq 0, 'Problem with energy limits for HPCA'
  return, 1
end

function mms_part_getspec_ut::test_all_outputs_hpca_srvy
  species = ['hplus', 'oplus', 'heplus', 'heplusplus']
  success = replicate(0,n_elements(species))
  for i = 0, n_elements(species)-1 do mms_part_getspec, probe=1, trange=['2015-12-15/15:00', '2015-12-15/16:00'], instrument='hpca', species=species[i],  /silent, data_rate='srvy', outputs='energy phi theta pa gyro moments'
  assert, spd_data_exists('mms1_hpca_heplusplus_phase_space_density_energy mms1_hpca_heplusplus_phase_space_density_theta mms1_hpca_heplusplus_phase_space_density_phi mms1_hpca_heplusplus_phase_space_density_pa mms1_hpca_heplusplus_phase_space_density_gyro', '2015-12-15/15:00', '2015-12-15/16:00'), 'Problem testing all outputs for HPCA'
  return, 1
end

function mms_part_getspec_ut::test_all_outputs_fpi_fast
  species = ['e','i']
  success = replicate(0,n_elements(species))
  for i = 0, n_elements(species)-1 do mms_part_getspec, probe=1, trange=['2015-12-15/10:00', '2015-12-15/11:00'], instrument='fpi', species=species[i],  /silent, data_rate='fast', outputs='energy phi theta pa gyro moments'
  
  return, 1
end

function mms_part_getspec_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  ; the following adds code coverage % to the output
  self->addTestingRoutine, ['mms_part_getspec', 'mms_part_products']
  return, 1
end

pro mms_part_getspec_ut__define
  define = {mms_part_getspec_ut, $
            inherits spd_tests_with_img_ut}
end
