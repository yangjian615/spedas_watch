;+
;procedure: spd_init_tests
;
; purpose: Intialize testscript
;
;Mainly sets up the variable in which test output will be stored
;
;
; $LastChangedBy: aaflores $
; $LastChangedDate: 2015-07-27 10:09:18 -0700 (Mon, 27 Jul 2015) $
; $LastChangedRevision: 18281 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/test_support_routines/spd_init_tests.pro $
;-

pro spd_init_tests

outputs = csvector('')

DEFSYSV,'!output',csvector(outputs)

end

