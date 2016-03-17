;+
;
; Unit tests for unh_mms_file_filter
;
; Requires mgunit in the local path
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-03-16 14:09:36 -0700 (Wed, 16 Mar 2016) $
; $LastChangedRevision: 20479 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_file_filter_ut__define.pro $
;-

function mms_file_filter_ut::test_min_version
    min_v = ['C:\Users\admin\data\mms/mms1/dfg/srvy/ql/2016/01/mms1_dfg_srvy_ql_20160117_v2.13.3.cdf',$
             'C:\Users\admin\data\mms/mms1/dfg/srvy/ql/2016/01/mms1_dfg_srvy_ql_20160119_v2.14.1.cdf', $
             'C:\Users\admin\data\mms/mms1/dfg/srvy/ql/2016/01/mms1_dfg_srvy_ql_20160120_v2.14.1.cdf']
    min_versions = unh_mms_file_filter(self.testdata, trange=time_double(['2016-01-15', '2016-01-20']), min_version='2.13.3')
    assert, array_equal(min_v, min_versions), 'Problem with min_version keyword'
    return, 1
end

function mms_file_filter_ut::test_latest_version
    latest_version = ['C:\Users\admin\data\mms/mms1/dfg/srvy/ql/2016/01/mms1_dfg_srvy_ql_20160119_v2.14.1.cdf',$
                      'C:\Users\admin\data\mms/mms1/dfg/srvy/ql/2016/01/mms1_dfg_srvy_ql_20160120_v2.14.1.cdf']
    latest_files = unh_mms_file_filter(self.testdata, trange=time_double(['2016-01-15', '2016-01-20']), /latest_version)
    assert, array_equal(latest_version, latest_files), 'Problem with the latest_version keyword'
    return, 1
end

function mms_file_filter_ut::test_version_eq
    version_eqs =  ['C:\Users\admin\data\mms/mms1/dfg/srvy/ql/2016/01/mms1_dfg_srvy_ql_20160115_v2.13.2.cdf',$
      'C:\Users\admin\data\mms/mms1/dfg/srvy/ql/2016/01/mms1_dfg_srvy_ql_20160116_v2.13.2.cdf',$
      'C:\Users\admin\data\mms/mms1/dfg/srvy/ql/2016/01/mms1_dfg_srvy_ql_20160118_v2.13.2.cdf']
    version_eq_files = unh_mms_file_filter(self.testdata, trange=time_double(['2016-01-15', '2016-01-20']), version='2.13.2')
    assert, array_equal(version_eqs, version_eq_files), 'Problem with the version keyword'
    return, 1
end

pro mms_file_filter_ut::setup
    self.testdata = ['C:\Users\admin\data\mms/mms1/dfg/srvy/ql/2016/01/mms1_dfg_srvy_ql_20160115_v2.13.2.cdf',$
    'C:\Users\admin\data\mms/mms1/dfg/srvy/ql/2016/01/mms1_dfg_srvy_ql_20160116_v2.13.2.cdf',$
    'C:\Users\admin\data\mms/mms1/dfg/srvy/ql/2016/01/mms1_dfg_srvy_ql_20160117_v2.13.3.cdf',$
    'C:\Users\admin\data\mms/mms1/dfg/srvy/ql/2016/01/mms1_dfg_srvy_ql_20160118_v2.13.2.cdf',$
    'C:\Users\admin\data\mms/mms1/dfg/srvy/ql/2016/01/mms1_dfg_srvy_ql_20160119_v2.14.1.cdf',$
    'C:\Users\admin\data\mms/mms1/dfg/srvy/ql/2016/01/mms1_dfg_srvy_ql_20160120_v2.14.1.cdf']
end

pro mms_file_filter_ut__define

    define = { mms_file_filter_ut, testdata: strarr(6), inherits MGutTestCase }
end