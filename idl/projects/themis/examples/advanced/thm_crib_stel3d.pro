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
;$LastChangedDate: 2016-02-09 16:37:17 -0800 (Tue, 09 Feb 2016) $
;$LastChangedRevision: 19922 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_stel3d.pro $
;-




;date (must be full length)
trange = '2008-02-26/' + ['04:54','04:55'] + ':00'


;load data into standard structures
dist = thm_part_dist_array(probe='b',type='peib', trange=trange)


;write to ascii file compatible with stel3d
file = 'thm_part_test_file.txt'
thm_part_write_ascii, dist, filename=file


stel3d, file, trange=trange


;compare with first sample's original (non-interpolated) data
;spd_part_vis, dist


end