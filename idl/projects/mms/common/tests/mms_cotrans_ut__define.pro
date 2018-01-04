;+
;
; Unit tests for mms_cotrans and mms_qcotrans
;
; To run:
;     IDL> mgunit, 'mms_cotrans_ut'
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2017-10-09 09:19:08 -0700 (Mon, 09 Oct 2017) $
; $LastChangedRevision: 24128 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_cotrans_ut__define.pro $
;-

function mms_cotrans_ut::test_state_radecl
  mms_load_state, trange=['2016-11-01', '2016-11-02'], probe=1
  mms_load_fgm, trange=['2016-11-01', '2016-11-02'], probe=1
  mms_cotrans, 'mms1_fgm_b_dmpa_srvy_l2_bvec', in_coord='dmpa', out_coord='gse', out_suffix='_gse'
  assert, spd_data_exists('mms1_fgm_b_dmpa_srvy_l2_bvec_gse', '2016-11-01', '2016-11-02'), 'Problem with state RADec variables'
  return, 1
end

function mms_cotrans_ut::test_fgm_radecl
  mms_load_fgm, level='ql', instrument='dfg', trange=['2016-11-01', '2016-11-02'], probe=1
  mms_cotrans, 'mms1_dfg_srvy_dmpa_bvec', in_coord='dmpa', out_coord='gse', out_suffix='_gse'
  assert, spd_data_exists('mms1_dfg_srvy_dmpa_bvec_gse', '2016-11-01', '2016-11-02'), 'Problem with FGM QL RADec variables'
  return, 1
end

function mms_cotrans_ut::test_cotrans_sm2gsm
  mms_qcotrans, 'mms1_mec_r_sm', out_coord='gsm', out_suffix='_gsm'
  get_data, 'mms1_mec_r_gsm', data=orig
  get_data, 'mms1_mec_r_sm_gsm', data=transformed
  diff = where(orig.Y[0, *]-transformed.Y[0, *] gt 1e-6, diffcount)
  assert, diffcount eq 0, 'Problem qcotransing from SM to GSM
  assert, spd_data_exists('mms1_mec_r_sm_gsm', '2015-12-1', '2015-12-2'), $
    'Problem qcotransing from SM to GSM'
  return, 1
end

function mms_cotrans_ut::test_cotrans_eci2gse2000
  mms_qcotrans, 'mms1_mec_r_eci', out_coord='gse2000', out_suffix='_eci2gse2000'
  assert, spd_data_exists('mms1_mec_r_eci_eci2gse2000', '2015-12-1', '2015-12-2'), $
    'Problem qcotrans''ing to GSE2000 from ECI'
  return, 1
end

function mms_cotrans_ut::test_cotrans_eci2sm
  mms_qcotrans, 'mms1_mec_r_eci', out_coord='sm', out_suffix='_eci2sm'
  assert, spd_data_exists('mms1_mec_r_eci_eci2sm', '2015-12-1', '2015-12-2'), $
    'Problem qcotrans''ing to SM from ECI'
  return, 1
end

function mms_cotrans_ut::test_cotrans_eci2gse
  mms_qcotrans, 'mms1_mec_r_eci', out_coord='gse', out_suffix='_eci2gse'
  assert, spd_data_exists('mms1_mec_r_eci_eci2gse', '2015-12-1', '2015-12-2'), $
    'Problem qcotrans''ing to GSE from ECI'
  return, 1
end

function mms_cotrans_ut::test_cotrans_eci2geo
  mms_qcotrans, 'mms1_mec_r_eci', out_coord='geo', out_suffix='_eci2geo'
  assert, spd_data_exists('mms1_mec_r_eci_eci2geo', '2015-12-1', '2015-12-2'), $
    'Problem qcotrans''ing to GEO from ECI'
  return, 1
end

function mms_cotrans_ut::test_cotrans_eci2gsm
  mms_qcotrans, 'mms1_mec_r_eci', out_coord='gsm', out_suffix='_eci2gsm'
  assert, spd_data_exists('mms1_mec_r_eci_eci2gsm', '2015-12-1', '2015-12-2'), $
    'Problem qcotrans''ing to GSM from ECI'
  return, 1
end

function mms_cotrans_ut::test_cotrans_gsm2geo
  mms_qcotrans, 'mms1_mec_r_gsm ', out_coord='geo', out_suffix='_gsm2geo'
  assert, spd_data_exists('mms1_mec_r_gsm_gsm2geo', '2015-12-1', '2015-12-2'), $
    'Problem qcotrans''ing to GSM from GEO'
  return, 1
end

function mms_cotrans_ut::test_cotrans_dmpa2gse
  mms_cotrans, 'mms1_fgm_b_dmpa_srvy_l2_bvec', out_coord='gse', out_suffix='_gse'
  assert, tnames('mms1_fgm_b_dmpa_srvy_l2_bvec_gse') ne '', 'Problem with mms_cotrans (dmpa2gse)'
  return, 1
end

function mms_cotrans_ut::test_qcotrans_dmpa2gse
  mms_qcotrans, 'mms1_fgm_b_dmpa_srvy_l2_bvec', out_coord='gse', out_suffix='_gse'
  assert, tnames('mms1_fgm_b_dmpa_srvy_l2_bvec_gse') ne '', 'Problem with mms_qcotrans (dmpa2gse)'
  return, 1
end

; compare the two methods to check for regressions
function mms_cotrans_ut::test_cotrans_qcotrans_dmpa2gse
  mms_cotrans, 'mms1_fgm_b_dmpa_srvy_l2_bvec', out_coord='gse', out_suffix='_cotrans_gse'
  mms_qcotrans, 'mms1_fgm_b_dmpa_srvy_l2_bvec', out_coord='gse', out_suffix='_qcotrans_gse'
  calc, '"qdiff"="mms1_fgm_b_dmpa_srvy_l2_bvec_qcotrans_gse"-"mms1_fgm_b_dmpa_srvy_l2_bvec_cotrans_gse"'
  get_data, 'qdiff', data=d
  zero_idxs = where(d.Y le 0.001, zerocount)
  if zerocount ne 0 then d.Y[zero_idxs] = !values.d_nan
  assert, abs((minmax(d.Y))[0]) lt 1. && abs((minmax(d.Y))[1]) lt 1., 'Problem with mms_cotrans vs. mms_qcotrans test (dmpa2gse)'
  return, 1
end

function mms_cotrans_ut::test_cotrans_qcotrans_dmpa2gsm
  mms_cotrans, 'mms1_fgm_b_dmpa_srvy_l2_bvec', out_coord='gsm', out_suffix='_cotrans_gsm'
  mms_qcotrans, 'mms1_fgm_b_dmpa_srvy_l2_bvec', out_coord='gsm', out_suffix='_qcotrans_gsm'
  calc, '"qdiff"="mms1_fgm_b_dmpa_srvy_l2_bvec_qcotrans_gsm"-"mms1_fgm_b_dmpa_srvy_l2_bvec_cotrans_gsm"'
  get_data, 'qdiff', data=d
  zero_idxs = where(d.Y le 0.001, zerocount)
  if zerocount ne 0 then d.Y[zero_idxs] = !values.d_nan
  assert, abs((minmax(d.Y))[0]) lt 1. && abs((minmax(d.Y))[1]) lt 1., 'Problem with mms_cotrans vs. mms_qcotrans test (dmpa2gsm)'
  return, 1
end

function mms_cotrans_ut::test_cotrans_qcotrans_dmpa2sm
  mms_cotrans, 'mms1_fgm_b_dmpa_srvy_l2_bvec', out_coord='sm', out_suffix='_cotrans_sm'
  mms_qcotrans, 'mms1_fgm_b_dmpa_srvy_l2_bvec', out_coord='sm', out_suffix='_qcotrans_sm'
  calc, '"qdiff"="mms1_fgm_b_dmpa_srvy_l2_bvec_qcotrans_sm"-"mms1_fgm_b_dmpa_srvy_l2_bvec_cotrans_sm"'
  get_data, 'qdiff', data=d
  zero_idxs = where(d.Y le 0.001, zerocount)
  if zerocount ne 0 then d.Y[zero_idxs] = !values.d_nan
  ; egrimes relaxed max difference to 2nT, 5/4/2016, max occurs near perigee where field is > 1000 nT
  assert, abs((minmax(d.Y))[0]) lt 1. && abs((minmax(d.Y))[1]) lt 2., 'Problem with mms_cotrans vs. mms_qcotrans test (dmpa2sm)'
  return, 1
end

function mms_cotrans_ut::test_cotrans_qcotrans_gse2sm
  mms_cotrans, 'mms1_fgm_b_gse_srvy_l2_bvec', out_coord='sm', out_suffix='_cotrans_sm'
  mms_qcotrans, 'mms1_fgm_b_gse_srvy_l2_bvec', out_coord='sm', out_suffix='_qcotrans_sm'
  calc, '"qdiff"="mms1_fgm_b_gse_srvy_l2_bvec_qcotrans_sm"-"mms1_fgm_b_gse_srvy_l2_bvec_cotrans_sm"'
  get_data, 'qdiff', data=d
  zero_idxs = where(d.Y le 0.001, zerocount)
  if zerocount ne 0 then d.Y[zero_idxs] = !values.d_nan
  assert, abs((minmax(d.Y))[0]) lt 1. && abs((minmax(d.Y))[1]) lt 1., 'Problem with mms_cotrans vs. mms_qcotrans test (gse2sm)'
  return, 1
end

pro mms_cotrans_ut::setup
  del_data, '*'
  timespan, '2015-12-1', 1, /day
  ; load FGM and MEC data
  mms_load_mec, probe=1, level='l2'
  mms_load_fgm, probe=1, level='l2'
  
  self.start_time = systime(/seconds)
end

function mms_cotrans_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  ; the following adds code coverage % to the output
  self->addTestingRoutine, ['mms_cotrans', 'mms_qcotrans', 'mms_cotrans_qtransformer', 'mms_cotrans_qrotate']
  return, 1
end

pro mms_cotrans_ut__define

  define = { mms_cotrans_ut, start_time: 0d, inherits MGutTestCase }
end