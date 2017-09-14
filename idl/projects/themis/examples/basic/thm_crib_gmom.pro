;+
;Procedure:
;  thm_crib_gmom
;
;Purpose:
;  Demonstrate basic examples of accessing ground particle moments data.
;  
;  
;
;See also:
;  thm_crib_mom
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-09-13 11:47:17 -0700 (Wed, 13 Sep 2017) $
;$LastChangedRevision: 23960 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/basic/thm_crib_gmom.pro $
;-

;------------------------------------------------------------------------------
; ESA+SST ions (ESA reduced + SST fast survey)
;------------------------------------------------------------------------------

thm_load_gmom, probe='e', trange=['2017-05-28', '2017-05-29'], datatype='ptirf'

tplot, ['the_ptirf_density', 'the_ptirf_avgtemp', 'the_ptirf_t3', 'the_ptirf_en_eflux']
stop

;------------------------------------------------------------------------------
; ESA+SST ions (ESA fast survey + SST fast survey)
;------------------------------------------------------------------------------

thm_load_gmom, probe='e', trange=['2017-05-28', '2017-05-29'], datatype='ptiff'

tplot, ['the_ptiff_density', 'the_ptiff_avgtemp', 'the_ptiff_t3', 'the_ptiff_en_eflux']
stop

;------------------------------------------------------------------------------
; ESA+SST ions (ESA burst + SST burst)
;------------------------------------------------------------------------------

thm_load_gmom, probe='e', trange=['2017-05-28', '2017-05-29'], datatype='ptibb'

tplot, ['the_ptibb_density', 'the_ptibb_avgtemp', 'the_ptibb_t3', 'the_ptibb_en_eflux']
stop

;------------------------------------------------------------------------------
; ESA+SST electrons (ESA reduced + SST fast survey)
;------------------------------------------------------------------------------

thm_load_gmom, probe='e', trange=['2017-05-28', '2017-05-29'], datatype='pterf'

tplot, ['the_pterf_density', 'the_pterf_avgtemp', 'the_pterf_t3', 'the_pterf_en_eflux']
stop

;------------------------------------------------------------------------------
; ESA+SST electrons (ESA fast survey + SST fast survey)
;------------------------------------------------------------------------------

thm_load_gmom, probe='e', trange=['2017-05-28', '2017-05-29'], datatype='pteff'

tplot, ['the_pteff_density', 'the_pteff_avgtemp', 'the_pteff_t3', 'the_pteff_en_eflux']
stop

;------------------------------------------------------------------------------
; ESA+SST electrons (ESA burst + SST burst)
;------------------------------------------------------------------------------

thm_load_gmom, probe='e', trange=['2017-05-28', '2017-05-29'], datatype='ptebb'

tplot, ['the_ptebb_density', 'the_ptebb_avgtemp', 'the_ptebb_t3', 'the_ptebb_en_eflux']
stop


end
