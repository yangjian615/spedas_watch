;Crib sheet to read in the RBSP ECTs official magnetic field model predicted quantities
;Save to tplot
;Only select quantities are grabbed at this time. 

;Written by Aaron B


;Data variable descriptions at http://www.rbsp-ect.lanl.gov/MagEphemDescription.php
;The data files need to be downloaded. You can get them by clicking on the 
;"RBSP [A,B] Data Files" link followed by the "pre" link. This crib loads the
;.h5 versions. 


rbsp_efw_init

;-----------------------------
;Define path to the ECT predict file (note that the H5 load routine won't work without
;	 full path explicitly spelled out...i.e. no ~)
path = '/Users/aaronbreneman/Desktop/code/Aaron/datafiles/rbsp/ectmag_pre/'


;----------------------------
;ECT predict file to load
;fn = 'rbspa_pre_MagEphem_T89Q_20120831_v1.0.0.h5' 
;fn = 'rbspa_pre_MagEphem_T89Q_20120907_v1.0.0.h5'
;fn = 'rbspa_pre_MagEphem_T89Q_20120831_v1.0.0.cdf'
;fn = 'rbspa_pre_MagEphem_OP77Q_20120919_v1.0.0.h5'
fn = 'rbspa_pre_MagEphem_OP77Q_20130108_v1.0.0.h5'

file = path + fn
R2 = FILE_INFO(file)
help,r2,/st

print,H5F_IS_HDF5(file)
result = h5_parse(file,/READ_DATA)


;Time variable
;Get to GPS time (starts at Jan 6th 1980 at 0:00:00)
offset = time_double('1980-01-06/00:00:00') - time_double('1970-01-01/00:00:00')
gpstime = result.gpstime._data
unixtime = gpstime + offset


;L*  (L-star parameter)
lstar = transpose(result.lstar._data)
;remove unrealistic values near perigee
goo = where((lstar ge 1d10) or (lstar le -1d10))
if goo[0] ne -1 then lstar[goo] = !values.f_nan
store_data,'lstar',data={x:unixtime,y:lstar}



;BGSM
bgsm = result.bsc_gsm._data
bmag = reform(bgsm[3,*])
bgsm = transpose(bgsm[0:2,*])
units = result.bsc_gsm.units._data
store_data,'bmag',data={x:unixtime,y:bmag}
store_data,'bgsm',data={x:unixtime,y:bgsm}
options,'bmag',ytitle='|B| nT'
options,'bgsm',ytitle='Bgsm nT'
tplot,['bmag','bgsm']

;Dipole tilt angle
dipoletiltangle = result.dipoletiltangle._data
store_data,'dipoletiltangle',data={x:unixtime,y:dipoletiltangle}
options,'dipoletiltangle',ytitle='Dipole tilt angle (deg)'
tplot,'dipoletiltangle'


;eccentric dipole stuff
ed_mlat = result.edmag_mlat._data
ed_mlon = result.edmag_mlon._data
ed_mlt = result.edmag_mlt._data
ed_r = result.edmag_r._data
store_data,'mlat_eccdipole',data={x:unixtime,y:ed_mlat}
store_data,'mlon_eccdipole',data={x:unixtime,y:ed_mlon}
store_data,'mlt_eccdipole',data={x:unixtime,y:ed_mlt}
store_data,'r_eccdipole',data={x:unixtime,y:ed_r}
options,'mlat_eccdipole',ytitle='MLAT (ecc dip) deg'
options,'mlon_eccdipole',ytitle='MLON (ecc dip) deg'
options,'mlt_eccdipole',ytitle='MLT (ecc dip) hours'
options,'r_eccdipole',ytitle='R (ecc dip) RE'
tplot,['mlat_eccdipole','mlon_eccdipole','mlt_eccdipole','r_eccdipole']

;centered dipole stuff
cd_mlat = result.cdmag_mlat._data
cd_mlon = result.cdmag_mlon._data
cd_mlt = result.cdmag_mlt._data
cd_r = result.cdmag_r._data
store_data,'mlat_centereddipole',data={x:unixtime,y:ed_mlat}
store_data,'mlon_centereddipole',data={x:unixtime,y:ed_mlon}
store_data,'mlt_centereddipole',data={x:unixtime,y:ed_mlt}
store_data,'r_centereddipole',data={x:unixtime,y:ed_r}
options,'mlat_centereddipole',ytitle='MLAT (cent dip) deg'
options,'mlon_centereddipole',ytitle='MLON (cent dip) deg'
options,'mlt_centereddipole',ytitle='MLT (cent dip) hours'
options,'r_centereddipole',ytitle='R (cent dip) RE'
tplot,['mlat_centereddipole','mlon_centereddipole','mlt_centereddipole','r_centereddipole']


;differences b/t centered dipole and eccentric dipole
mlat_diff = cd_mlat - ed_mlat
mlon_diff = cd_mlon - ed_mlon
mlt_diff = cd_mlt - ed_mlt
r_diff = cd_r - ed_r
store_data,'mlat_diff',data={x:unixtime,y:mlat_diff}
store_data,'mlon_diff',data={x:unixtime,y:mlon_diff}
store_data,'mlt_diff',data={x:unixtime,y:mlt_diff}
store_data,'r_diff',data={x:unixtime,y:r_diff}
options,'mlat_diff',ytitle='mlat centdip-mlat eccdip'
options,'mlon_diff',ytitle='mlon centdip-mlon eccdip'
options,'mlt_diff',ytitle='mlt centdip-mlt eccdip'
options,'r_diff',ytitle='R centdip-R eccdip'
tplot,['mlat_diff','mlon_diff','mlt_diff','r_diff']



;Field Line Type
;Description of the type of field line the S/C is on., 
;Can be one of 4 types: 

;1 = LGM_CLOSED - FL hits Earth at both ends. 
;2 = LGM_OPEN_N_LOBE - FL is an OPEN field line rooted in the Northern polar cap. 
;3 = LGM_OPEN_S_LOBE - FL is an OPEN field line rooted in the Southern polar cap. 
;4 = LGM_OPEN_IMF - FL does not hit Earth at eitrher end.
fieldlinetype = result.fieldlinetype._data
fieldlinetype_int = replicate(1,n_elements(fieldlinetype))
goo = where(fieldlinetype eq 'LGM_OPEN_N_LOBE')
if goo[0] ne -1 then fieldlinetype_int[goo] = 2
goo = where(fieldlinetype eq 'LGM_OPEN_S_LOBE')
if goo[0] ne -1 then fieldlinetype_int[goo] = 3
goo = where(fieldlinetype eq 'LGM_OPEN_IMF')
if goo[0] ne -1 then fieldlinetype_int[goo] = 4
store_data,'fieldlinetype',data={x:unixtime,y:fieldlinetype_int}
options,'fieldlinetype',ytitle='fieldlinetype:!C1=connected!C2=connected in N!C3=connected in S!C4=open both ends'
ylim,'fieldlinetype',0,5,0
tplot,'fieldlinetype'

;Lshell
lshell = result.lsimple._data
invlat = result.invlat._data
invlat_eq = result.invlat_eq._data
store_data,'lshell',data={x:unixtime,y:lshell}
store_data,'invlat',data={x:unixtime,y:invlat}
store_data,'invlat_eq',data={x:unixtime,y:invlat_eq}
options,'lshell',ytitle='L shell'
options,'invlat',ytitle='Inv lat (deg)'
options,'invlat_eq',ytitle='Inv lat at eq (deg)'

;Kp index
kp = result.kp._data
store_data,'Kp',data={x:unixtime,y:Kp}
options,'Kp',ytitle='Kp index'
ylim,'Kp',0,10,0
tplot,['lshell','invlat','invlat_eq','Kp']


;Field line footpoint coordinates and field strengths at the footpoints
bfn_geo = transpose(result.Bfn_geo._data)
bfn_gsm = transpose(result.Bfn_gsm._data)
bfs_geo = transpose(result.Bfs_geo._data)
bfs_gsm = transpose(result.Bfs_gsm._data)
bmag_mirror = transpose(result.Bm._data)

store_data,'bfn_geo',data={x:unixtime,y:bfn_geo}
store_data,'bfn_gsm',data={x:unixtime,y:bfn_gsm}
store_data,'bfs_geo',data={x:unixtime,y:bfs_geo}
store_data,'bfs_gsm',data={x:unixtime,y:bfs_gsm}

options,'bfn_geo','ytitle','|B| at!CNorth footpoint!CGEO coord'
options,'bfn_gsm','ytitle','|B| at!CNorth footpoint!CGSM coord'
options,'bfs_geo','ytitle','|B| at!CSouth footpoint!CGEO coord'
options,'bfs_gsm','ytitle','|B| at!CSouth footpoint!CGSM coord'


tplot,['bfn_geo','bfn_gsm','bfs_geo','bfs_gsm']


pfn_cd_mlat = result.Pfn_CD_MLAT._data
pfn_cd_mlon = result.Pfn_CD_MLON._data
pfn_cd_mlt = result.Pfn_CD_MLT._data
pfn_ed_mlat = result.Pfn_ED_MLAT._data
pfn_ed_mlon = result.Pfn_ED_MLON._data
pfn_ed_mlt = result.Pfn_ED_MLT._data
pfn_geo = transpose(result.Pfn_geo._data)
pfn_geod_height = result.Pfn_geod_Height._data
pfn_geod_latlon = transpose(result.Pfn_geod_LatLon._data)
pfn_gsm = transpose(result.Pfn_gsm._data)

store_data,'pfn_cd_mlat',data={x:unixtime,y:pfn_cd_mlat}
store_data,'pfn_cd_mlon',data={x:unixtime,y:pfn_cd_mlon}
store_data,'pfn_cd_mlt',data={x:unixtime,y:pfn_cd_mlt}
store_data,'pfn_ed_mlat',data={x:unixtime,y:pfn_ed_mlat}
store_data,'pfn_ed_mlon',data={x:unixtime,y:pfn_ed_mlon}
store_data,'pfn_ed_mlt',data={x:unixtime,y:pfn_ed_mlt}
store_data,'pfn_geo',data={x:unixtime,y:pfn_geo}
store_data,'pfn_geod_height',data={x:unixtime,y:pfn_geod_height}
store_data,'pfn_geod_latlon',data={x:unixtime,y:pfn_geod_latlon}
store_data,'pfn_gsm',data={x:unixtime,y:pfn_gsm}

options,'pfn_cd_mlat','ytitle','Mlat!CNorth!Cfootpoint!Ccentered!Cdipole!Cdeg'
options,'pfn_cd_mlon','ytitle','Mlong!CNorth!Cfootpoint!Ccentered!Cdipole!Cdeg'
options,'pfn_cd_mlt','ytitle','MLT!CNorth!Cfootpoint!Ccentered!Cdipole!CHours'
options,'pfn_ed_mlat','ytitle','Mlat!CNorth!Cfootpoint!Cecc!Cdipole!Cdeg'
options,'pfn_ed_mlon','ytitle','Mlong!CNorth!Cfootpoint!Cecc!Cdipole!Cdeg'
options,'pfn_ed_mlt','ytitle','MLT!CNorth!Cfootpoint!Cecc!Cdipole!CHours'
options,'pfn_geo','ytitle','Location of!CNorth!Cfootpoint!CGEO!CRE'
options,'pfn_geod_height','ytitle','Geodetic!CHeight!CNorth!Cfootpoint!Ckm'
options,'pfn_geod_latlon','ytitle','Geodetic!Clat and lon!CNorth!Cfootpoint!Cdeg'
options,'pfn_gsm','ytitle','Location of!CNorth!Cfootpoint!CGSM!CRE'

tplot,['pfn_cd_mlat','pfn_cd_mlon','pfn_cd_mlt']
tplot,['pfn_ed_mlat','pfn_ed_mlon','pfn_ed_mlt']
tplot,['pfn_geo','pfn_geod_height','pfn_geod_latlon','pfn_gsm']


pfs_cd_mlat = result.Pfs_CD_MLAT._data
pfs_cd_mlon = result.Pfs_CD_MLON._data
pfs_cd_mlt = result.Pfs_CD_MLT._data
pfs_ed_mlat = result.Pfs_ED_MLAT._data
pfs_ed_mlon = result.Pfs_ED_MLON._data
pfs_ed_mlt = result.Pfs_ED_MLT._data
pfs_geo = transpose(result.Pfs_geo._data)
pfs_geod_height = result.Pfs_geod_Height._data
pfs_geod_latlon = transpose(result.Pfs_geod_LatLon._data)
pfs_gsm = transpose(result.Pfs_gsm._data)

store_data,'pfs_cd_mlat',data={x:unixtime,y:pfs_cd_mlat}
store_data,'pfs_cd_mlon',data={x:unixtime,y:pfs_cd_mlon}
store_data,'pfs_cd_mlt',data={x:unixtime,y:pfs_cd_mlt}
store_data,'pfs_ed_mlat',data={x:unixtime,y:pfs_ed_mlat}
store_data,'pfs_ed_mlon',data={x:unixtime,y:pfs_ed_mlon}
store_data,'pfs_ed_mlt',data={x:unixtime,y:pfs_ed_mlt}
store_data,'pfs_geo',data={x:unixtime,y:pfs_geo}
store_data,'pfs_geod_height',data={x:unixtime,y:pfs_geod_height}
store_data,'pfs_geod_latlon',data={x:unixtime,y:pfs_geod_latlon}
store_data,'pfs_gsm',data={x:unixtime,y:pfs_gsm}


options,'pfs_cd_mlat','ytitle','Mlat!CSouth!Cfootpoint!Ccentered!Cdipole!Cdeg'
options,'pfs_cd_mlon','ytitle','Mlong!CSouth!Cfootpoint!Ccentered!Cdipole!Cdeg'
options,'pfs_cd_mlt','ytitle','MLT!CSouth!Cfootpoint!Ccentered!Cdipole!CHours'
options,'pfs_ed_mlat','ytitle','Mlat!CSouth!Cfootpoint!Cecc!Cdipole!Cdeg'
options,'pfs_ed_mlon','ytitle','Mlong!CSouth!Cfootpoint!Cecc!Cdipole!Cdeg'
options,'pfs_ed_mlt','ytitle','MLT!CSouth!Cfootpoint!Cecc!Cdipole!CHours'
options,'pfs_geo','ytitle','Location of!CSouth!Cfootpoint!CGEO!CRE'
options,'pfs_geod_height','ytitle','Geodetic!CHeight!CSouth!Cfootpoint!Ckm'
options,'pfs_geod_latlon','ytitle','Geodetic!Clat and lon!CSouth!Cfootpoint!Cdeg'
options,'pfs_gsm','ytitle','Location of!CSouth!Cfootpoint!CGSM!CRE'

tplot,['pfs_cd_mlat','pfs_cd_mlon','pfs_cd_mlt']
tplot,['pfs_ed_mlat','pfs_ed_mlon','pfs_ed_mlt']
tplot,['pfs_geo','pfs_geod_height','pfs_geod_latlon','pfs_gsm']




