;+
; PROCEDURE:
;     mms_run_all_tests
;     
; PURPOSE
;     Run all the unit tests for the MMS load routines
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-03-15 15:49:48 -0700 (Tue, 15 Mar 2016) $
; $LastChangedRevision: 20470 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_run_all_tests.pro $
;-

pro mms_run_all_tests
    test_suites = ['mms_cdf2tplot_ut', 'mms_load_data_ut', 'mms_load_fgm_ut']
    mgunit, test_suites, filename='mms_tests_output_'+time_string(systime(/sec), tformat='YYYYMMDD_hhmm')+'.txt', nfail=nfail
    if nfail ne 0 then begin
        dprint, dlevel = 0, 'Error! Problems found while running the testsuite!'
    endif
end