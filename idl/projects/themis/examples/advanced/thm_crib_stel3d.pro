;+
;Purpose:
;  Crib demonstrating usage of stel3d tool with themis particle data
;
;
;Notes:
;  -Currently only compatible with modified tool at:
;    /spedas_gui/stel_3d/stel_3d_pro_20150811/pro
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-02-24 11:09:47 -0800 (Wed, 24 Feb 2016) $
;$LastChangedRevision: 20156 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_stel3d.pro $
;-


;IMPORTANT NOTES =======================================================
;
;  -Data must have at least 3 distributions within the time range.
;
;======================================================================



probe = 'b'
datatype = 'peib'
trange = '2008-02-26/' + ['04:54','04:55'] + ':00'


;load data into standard structures
dist = thm_part_dist_array(probe=probe, datatype=datatype, trange=trange)


;apply standard processing
thm_part_process, dist, dist_counts, units='counts'
thm_part_process, dist, dist_df, units='df'


;convert to stel3d data model
data = spd_dist_to_hash(dist_df, counts=dist_counts)


stel3d, data=data, trange=trange 



end