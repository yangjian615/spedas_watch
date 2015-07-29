;+
; PROCEDURE:
;         mms_load_scm
;         
; PURPOSE:
;         Load data from the MMS Search Coil Magnetometer (SCM)
; 
; KEYWORDS:
;         trange: time range of interest
;         probes: list of probes - values for MMS SC #
;         local_data_dir: local directory to store the CDF files
; 
; OUTPUT:
; 
; 
; EXAMPLE:
;     See the crib sheet mms_load_data_crib.pro for usage examples
; 
; NOTES:
;     Please see the notes in mms_load_data for more information 
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-07-27 11:15:11 -0700 (Mon, 27 Jul 2015) $
;$LastChangedRevision: 18290 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/mms_load_scm.pro $
;-

pro mms_load_scm, trange = trange, probes = probes, datatype = datatype, $
                  level = level, data_rate = data_rate, $
                  local_data_dir = local_data_dir, source = source, $
                  get_support_data = get_support_data
    if undefined(trange) then trange = ['2015-06-22', '2015-06-23']
    if undefined(probes) then probes = ['1'] ; default to MMS 1
    if undefined(datatype) then datatype = 'sc256' 
    if undefined(level) then level = 'l1b' 
    if undefined(data_rate) then data_rate = 'comm'
      
    mms_load_data, trange = trange, probes = probes, level = level, instrument = 'scm', $
        data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
        datatype = datatype, get_support_data = get_support_data
end