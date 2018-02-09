;+
;
; Unit tests for tplot_add_cdf_structure
;
; To run:
;     IDL> mgunit, 'spd_tplot_add_cdf_structure_ut'
;
; $LastChangedBy: adrozdov $
; $LastChangedDate: 2018-02-07 21:19:49 -0800 (Wed, 07 Feb 2018) $
; $LastChangedRevision: 24668 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/qa_tools/mgunit/spd_tplot_add_cdf_structure_ut__define.pro $
;-

function spd_tplot_add_cdf_structure_ut::test_cdf
  store_data, 'test_xy', data={x: double(1), y: indgen(1)}
  tplot_add_cdf_structure, 'test_xy'
  get_data, 'test_xy', limits=s
  assert, ~undefined(s.CDF), 'No CDF structure'
  assert, ~undefined(s.CDF.DEPEND_0) && ~undefined(s.CDF.VARS), 'No CDF fields' 
  return, 1
end

function spd_tplot_add_cdf_structure_ut::test_v
  store_data, 'test_xyv', data={x: double(indgen(2)), y: indgen(2,2)}
  tplot_add_cdf_structure, 'test_xyv'
  get_data, 'test_xyv', limits=s, data=d  
  assert, ~undefined(s.CDF.DEPEND_1), 'No DEPEND_1 CDF field'
  assert, ~undefined(d.v), 'No v created'
  return, 1
end

function spd_tplot_add_cdf_structure_ut::test_v12
  store_data, 'test_xyv12', data={x: double(indgen(2)), y: indgen(2,2,2)}
  tplot_add_cdf_structure, 'test_xyv12'
  get_data, 'test_xyv12', limits=s, data=d
  assert, ~undefined(s.CDF.DEPEND_1) && ~undefined(s.CDF.DEPEND_2), 'No DEPENDs CDF field'
  assert, ~undefined(d.v1) && ~undefined(d.v2), 'No v#'
  return, 1
end

function spd_tplot_add_cdf_structure_ut::test_v123
  store_data, 'test_xyv123', data={x: double(indgen(2)), y: indgen(2,2,2,2)}
  tplot_add_cdf_structure, 'test_xyv123'
  get_data, 'test_xyv123', limits=s, data=d
  assert, ~undefined(s.CDF.DEPEND_1) && ~undefined(s.CDF.DEPEND_2) && ~undefined(s.CDF.DEPEND_3), 'No DEPENDs CDF field'
  assert, ~undefined(d.v1) && ~undefined(d.v2) && ~undefined(d.v3), 'No v#'
  return, 1
end
function spd_tplot_add_cdf_structure_ut::test_v_epoch
  store_data, 'test_v_epoch', data={x: double(indgen(2)), y: indgen(2,2), v:indgen(2,2)}
  tplot_add_cdf_structure, 'test_v_epoch'
  get_data, 'test_v_epoch', limits=s, data=d
  assert, ~undefined((*(s.CDF.DEPEND_1.ATTRPTR)).DEPEND_0), 'No Epoch in v attribues'  
  return, 1
end

function spd_tplot_add_cdf_structure_ut::test_v123_epoch
  store_data, 'test_v123_epoch', data={x: double(indgen(2)), y: indgen(2,2,2,2,2), v1:indgen(2,2), v2:indgen(2,2), v3:indgen(2,2)}
  tplot_add_cdf_structure, 'test_v123_epoch'
  get_data, 'test_v123_epoch', limits=s, data=d
  assert, ~undefined((*(s.CDF.DEPEND_1.ATTRPTR)).DEPEND_0), 'No Epoch in v1 attribues'
  assert, ~undefined((*(s.CDF.DEPEND_2.ATTRPTR)).DEPEND_0), 'No Epoch in v2 attribues'
  assert, ~undefined((*(s.CDF.DEPEND_3.ATTRPTR)).DEPEND_0), 'No Epoch in v3 attribues'
  return, 1
end


pro spd_tplot_add_cdf_structure_ut::setup
  del_data, '*'
end

function spd_tplot_add_cdf_structure_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  ; the following adds code coverage % to the output
  self->addTestingRoutine, ['tplot_add_cdf_structure']
  return, 1
end

pro spd_tplot_add_cdf_structure_ut__define
  define = { spd_tplot_add_cdf_structure_ut, inherits MGutTestCase }
end