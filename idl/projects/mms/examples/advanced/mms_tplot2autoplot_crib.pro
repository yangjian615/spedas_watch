;+
; PROCEDURE:
;         mms_tplot2autoplot_crib
;
; PURPOSE:
;         Crib sheet showing how to send MMS data to Autoplot
;
; NOTES:
;         For this to work, you'll need to open Autoplot and enable the 'Server' feature via
;         the 'Options' menu with the default port (12345)
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2018-01-22 12:57:57 -0800 (Mon, 22 Jan 2018) $
; $LastChangedRevision: 24563 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/advanced/mms_tplot2autoplot_crib.pro $
;-

mms_load_fgm, trange=['2015-10-16', '2015-10-17']
mms_load_feeps, trange=['2015-10-16', '2015-10-17']

tplot2ap, ['mms1_fgm_b_gse_srvy_l2_bvec', 'mms1_epd_feeps_srvy_l2_electron_intensity_omni_spin']
tplot2ap, ['mms1_fgm_b_gse_srvy_l2_bvec']

stop
end