;+
;
;  This crib sheet shows how to create FPI angle-angle plots from the distribution functions
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-02-07 08:23:21 -0800 (Tue, 07 Feb 2017) $
;$LastChangedRevision: 22745 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_fpi_angle_angle_crib.pro $
;-

; Burst-mode electrons
mms_fpi_ang_ang, '2015-10-16/13:06:59.985', species='e', data_rate='brst'
stop

; Burst-mode ions
mms_fpi_ang_ang, '2015-10-16/13:06:59.985', species='i', data_rate='brst'
stop

; Limit the energy range for the ions
mms_fpi_ang_ang, '2015-10-16/13:06:59.985', energy_range=[662, 1802.2], species='i', data_rate='brst'
stop

; save the plots as postscript files
mms_fpi_ang_ang, '2015-10-16/13:06:59.985', /postscript, species='i', data_rate='brst'
stop

end