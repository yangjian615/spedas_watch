;+
;COMMON BLOCK:   mvn_swe_com
;PURPOSE:
;  Stores the SWEA static memory.
;
;     swe_hsk:  slow housekeeping
;     a0:       3D survey
;     a1:       3D archive
;     a2:       PAD survey
;     a3:       PAD archive
;     a4:       ENGY survey
;     a5:       ENGY archive
;     a6:       fast housekeeping
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2014-07-10 18:08:08 -0700 (Thu, 10 Jul 2014) $
; $LastChangedRevision: 15555 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_com.pro $
;
;CREATED BY:	David L. Mitchell  2013-03-18
;FILE:  mvn_swe_com.pro
;-
common swe_raw, a0, a1, a2, a3, a4, a5, a6, swe_hsk, swe_3d, swe_3d_arc, $
                swe_chksum, swe_active_chksum

common swe_dat, swe_3d_struct, swe_pad_struct, swe_engy_struct, swe_mag_struct, $
                mvn_swe_engy, mvn_swe_engy_arc, swe_mag1, swe_mag2

common swe_cal, decom, swe_v, swe_t, swe_ne, swe_dt, swe_duty, swe_gf, swe_swp, $
                swe_de, swe_el, swe_del, swe_az, swe_daz, swe_Ka, swe_dead, $
                swe_integ_t, swe_padlut, swe_mcp_eff, swe_rgf, swe_dgf

common swe_cfg, t_swp1, t_mtx1, t_mtx2, t_mtx3, t_swp2, t_cfg
