;+
;
; Unit tests for mms_cotrans and mms_qcotrans
;
; Requires both the SPEDAS QA folder (not distributed with SPEDAS) and mgunit
; in the local path
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-05-04 09:20:59 -0700 (Wed, 04 May 2016) $
; $LastChangedRevision: 21018 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_cotrans_ut__define.pro $
;-

function mms_cotrans_ut::test_cotrans_dmpa2gse
  mms_cotrans, 'mms1_fgm_b_dmpa_srvy_l2_bvec', in_coord='dmpa', out_coord='gse', out_suffix='_gse'
  assert, tnames('mms1_fgm_b_dmpa_srvy_l2_bvec_gse') ne '', 'Problem with mms_cotrans (dmpa2gse)'
  return, 1
end

function mms_cotrans_ut::test_qcotrans_dmpa2gse
  mms_qcotrans, 'mms1_fgm_b_dmpa_srvy_l2_bvec', in_coord='dmpa', out_coord='gse', out_suffix='_gse'
  assert, tnames('mms1_fgm_b_dmpa_srvy_l2_bvec_gse') ne '', 'Problem with mms_qcotrans (dmpa2gse)'
  return, 1
end

; compare the two methods to check for regressions
function mms_cotrans_ut::test_cotrans_qcotrans_dmpa2gse
  mms_cotrans, 'mms1_fgm_b_dmpa_srvy_l2_bvec', in_coord='dmpa', out_coord='gse', out_suffix='_cotrans_gse'
  mms_qcotrans, 'mms1_fgm_b_dmpa_srvy_l2_bvec', in_coord='dmpa', out_coord='gse', out_suffix='_qcotrans_gse'
  calc, '"qdiff"="mms1_fgm_b_dmpa_srvy_l2_bvec_qcotrans_gse"-"mms1_fgm_b_dmpa_srvy_l2_bvec_cotrans_gse"'
  get_data, 'qdiff', data=d
  zero_idxs = where(d.Y le 0.001, zerocount)
  if zerocount ne 0 then d.Y[zero_idxs] = !values.d_nan
  assert, abs((minmax(d.Y))[0]) lt 1. && abs((minmax(d.Y))[1]) lt 1., 'Problem with mms_cotrans vs. mms_qcotrans test (dmpa2gse)'
  return, 1
end

function mms_cotrans_ut::test_cotrans_qcotrans_dmpa2gsm
  mms_cotrans, 'mms1_fgm_b_dmpa_srvy_l2_bvec', in_coord='dmpa', out_coord='gsm', out_suffix='_cotrans_gsm'
  mms_qcotrans, 'mms1_fgm_b_dmpa_srvy_l2_bvec', in_coord='dmpa', out_coord='gsm', out_suffix='_qcotrans_gsm'
  calc, '"qdiff"="mms1_fgm_b_dmpa_srvy_l2_bvec_qcotrans_gsm"-"mms1_fgm_b_dmpa_srvy_l2_bvec_cotrans_gsm"'
  get_data, 'qdiff', data=d
  zero_idxs = where(d.Y le 0.001, zerocount)
  if zerocount ne 0 then d.Y[zero_idxs] = !values.d_nan
  assert, abs((minmax(d.Y))[0]) lt 1. && abs((minmax(d.Y))[1]) lt 1., 'Problem with mms_cotrans vs. mms_qcotrans test (dmpa2gsm)'
  return, 1
end

function mms_cotrans_ut::test_cotrans_qcotrans_dmpa2sm
  mms_cotrans, 'mms1_fgm_b_dmpa_srvy_l2_bvec', in_coord='dmpa', out_coord='sm', out_suffix='_cotrans_sm'
  mms_qcotrans, 'mms1_fgm_b_dmpa_srvy_l2_bvec', in_coord='dmpa', out_coord='sm', out_suffix='_qcotrans_sm'
  calc, '"qdiff"="mms1_fgm_b_dmpa_srvy_l2_bvec_qcotrans_sm"-"mms1_fgm_b_dmpa_srvy_l2_bvec_cotrans_sm"'
  get_data, 'qdiff', data=d
  zero_idxs = where(d.Y le 0.001, zerocount)
  if zerocount ne 0 then d.Y[zero_idxs] = !values.d_nan
  ; egrimes relaxed max difference to 2nT, 5/4/2016, max occurs near perigee where field is > 1000 nT
  assert, abs((minmax(d.Y))[0]) lt 1. && abs((minmax(d.Y))[1]) lt 2., 'Problem with mms_cotrans vs. mms_qcotrans test (dmpa2sm)'
  return, 1
end

function mms_cotrans_ut::test_cotrans_qcotrans_gse2sm
  mms_cotrans, 'mms1_fgm_b_gse_srvy_l2_bvec', in_coord='gse', out_coord='sm', out_suffix='_cotrans_sm'
  mms_qcotrans, 'mms1_fgm_b_gse_srvy_l2_bvec', in_coord='gse', out_coord='sm', out_suffix='_qcotrans_sm'
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
  self->addTestingRoutine, ['mms_cotrans', 'mms_qcotrans']
  return, 1
end

pro mms_cotrans_ut__define

  define = { mms_cotrans_ut, start_time: 0d, inherits MGutTestCase }
end