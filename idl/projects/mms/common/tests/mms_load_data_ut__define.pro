;+
;
; Unit tests for mms_load_data
;
; REQUIRED (in working directory): 
;     test_auth_info_team.sav - sav file containing username and password
;     test_auth_info_pub.sav - sav file containing an empty username and password
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-03-10 15:31:00 -0800 (Thu, 10 Mar 2016) $
; $LastChangedRevision: 20399 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_load_data_ut__define.pro $
;-

; test that we can handle both the new L2pre variable names and the old ones
function mms_load_data_ut::test_fgm_l2pre_vars
  del_data, '*'
  ;; placeholder to remind me to add this test when the data are at the SDC
  ;; fails for now
end

; test MMS team member access 
function mms_load_data_ut::test_team_access
  del_data, '*'
  mms_load_data, login_info='test_auth_info_team.sav', trange=['2016-01-21', '2016-01-22'], $
      instrument='dfg', level='l2pre', data_rate='srvy', probe=1
  get_data, 'mms1_dfg_srvy_l2pre_dmpa', data=d
  assert, is_struct(d), 'Problem accessing the SDC with an MMS username/password'
  return, 1
end

; test MMS team member access with multiple calls
function mms_load_data_ut::test_team_access_multi
  del_data, '*'
  mms_load_data, login_info='test_auth_info_team.sav', trange=['2016-01-21', '2016-01-22'], $
    instrument='dfg', level='l2pre', data_rate='srvy', probe=1
  mms_load_data, login_info='test_auth_info_team.sav', trange=['2016-01-21', '2016-01-22'], $
    instrument='fpi', level='sitl', data_rate='fast', probe=1
  mms_load_data, login_info='test_auth_info_team.sav', trange=['2016-01-21', '2016-01-22'], $
    instrument='hpca', level='l1b', data_rate='srvy', probe=1
  assert, tnames('mms1_dfg_srvy_l2pre_dmpa') ne '', 'Problem loading L2pre DFG data (team, multi-call test)'
  assert, tnames('mms1_hpca_hplus_number_density') ne '', 'Problem loading L1b HPCA data (team, multi-call test)'
  assert, tnames('mms1_fpi_eEnergySpectr_pX') ne '', 'Problem loading SITL FPI data (team, multi-call test)'
  return, 1
end

; test public access to the SDC
function mms_load_data_ut::test_public_access_sdc
  del_data, '*'
  mms_load_data, login_info='test_auth_info_pub.sav', trange=['2016-01-21', '2016-01-22'], $
    instrument='fgm', level='l2', data_rate='srvy', probe=1
  return, 1
end

; test public access to the SDC with multiple calls
function mms_load_data_ut::test_public_access_sdc_multi
  del_data, '*'
  mms_load_data, login_info='test_auth_info_pub.sav', trange=['2016-01-21', '2016-01-22'], $
    instrument='fgm', level='l2', data_rate='srvy', probe=1
  mms_load_data, login_info='test_auth_info_pub.sav', trange=['2016-01-21', '2016-01-22'], $
    instrument='fpi', level='l2', data_rate='fast', probe=1, datatype='des-moms'
  mms_load_data, login_info='test_auth_info_pub.sav', trange=['2016-01-21', '2016-01-22'], $
    instrument='edi', level='l2', data_rate='srvy', probe=1, datatype='efield'
  
  assert, tnames('mms1_fgm_b_gsm_srvy_l2') ne '', 'Problem loading L2 FGM data (public, multi-call test)'
  assert, tnames('mms1_des_numberdensity_dbcs_fast') ne '', 'Problem loading L2 FPI data (public, multi-call test)'
  assert, tnames('mms1_edi_e_gsm_srvy_l2') ne '', 'Problem loading L2 EDI data (public, multi-call test)'
  return, 1
end

pro mms_load_data_ut::setup
  ; do some setup for the tests
end

pro mms_load_data_ut__define
  define = { mms_load_data_ut, inherits MGutTestCase }
end