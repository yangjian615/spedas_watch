;20160404 Ali
;change the data resolution and load instrument pointings
;and puts them in an array of structures in common block "mvn_pui_com"
;to be called by mvn_pui_model

pro mvn_pui_data_res

@mvn_pui_commonblock.pro ;common mvn_pui_common
binsize=pui0.tbin
trange=pui0.trange

;get data from tplot variables (commented out, now getting data directly from instrument common blocks or spice)
;get_data,'mvn_swim_density',data=swian; %solar wind density (cm-3)
;get_data,'mvn_swim_velocity_mso',data=swiav; %solar wind velocity MSO (km/s)
;get_data,'mvn_swis_en_eflux',data=swiaefdata; %swia energy spectrum
;get_data,'mvn_B_1sec_MAVEN_MSO',data=mag; magnetic field vector, MSO (nT)
;get_data,'SepAnc_mvn_pos_mso',data=pos; maven position (km)
;get_data,'SepAnc_sep_1f_fov_mso',data=dld1; %sep1f fov
;get_data,'SepAnc_sep_2f_fov_mso',data=dld2; %sep2f fov
;get_data,'mvn_sta_c0_H_E',data=sta_c0_H_E_data ; STATIC m>12 energy spectra
;get_data,'mvn_sta_c0_L_E',data=sta_c0_L_E_data ; STATIC m<12 energy spectra

;----------MAG----------
get_data,'mvn_B_1sec',data=magdata; magnetic field vector, payload coordinates (nT)
if ~keyword_set(magdata) then begin
  dprint,'No MAG data available, using default B=[0,3,0] nT'
  pui.data.mag.mso=1e-9*[0,3,0] ;magnetic field (T)
  centertime=dgen(pui0.nt,range=timerange(trange))
  pui.centertime=centertime
endif else begin
  magpayload=1e-9*average_hist2(magdata.y,magdata.x,binsize=binsize,trange=trange,centertime=centertime); magnetic field vector payload (T)
  pui.data.mag.payload=transpose(magpayload)
  pui.centertime=centertime

  ;rotate MAG data into MSO coordinates (Tesla)
  pui.data.mag.mso=spice_vector_rotate(pui.data.mag.payload,centertime,'MAVEN_SPACECRAFT','MAVEN_MSO',check_objects='MAVEN_SPACECRAFT')
endelse

;----------SWIA----------
;nsw=average_hist2(swian.y,swian.x,binsize=binsize,trange=trange,centertime=centertime); solar wind density (cm-3)
if ~keyword_set(swim) then begin
  dprint,'No SWIA data available, using default values: Usw = 500 km/s, Nsw = 2 cm-3'
  pui.data.swi.swim.velocity_mso=[-500,0,0] ;solar wind velocity (km/s)
  pui.data.swi.swim.density=2. ;solar wind density (cm-3)
endif else begin
  pui.data.swi.swim=average_hist(swim,swim.time_unix+2.,binsize=binsize,range=trange,xbins=centertime); swia moments
  pui.data.swi.swis=average_hist(swis,swis.time_unix+2.,binsize=binsize,range=trange,xbins=centertime); swia spectra
  ;vsw=1e3*average_hist2(swiav.y,swiav.x,binsize=binsize,trange=trange,centertime=centertime); solar wind velocity (m/s)
  ;swiaef=average_hist2(swiaefdata.y,swiaefdata.x,binsize=binsize,trange=trange,centertime=centertime); swia energy flux
  ;swiaet=average_hist2(swiaefdata.v,swiaefdata.x,binsize=binsize,trange=trange,centertime=centertime); swia energy table

  swisen=transpose(info_str[pui.data.swi.swis.info_index].energy_coarse)
  store_data,'mvn_redures_swia',data={x:centertime,y:transpose(pui.data.swi.swis.data),v:swisen},limits={ylog:1,zlog:1,spec:1,yrange:[25,25e3],ystyle:1,zrange:[1e3,1e8],ztitle:'Eflux',ytickunits:'scientific'}

  if keyword_set(swics) then begin ;swia survey data
    swiactime = swics.time_unix +4.0*swics.num_accum/2  ;center time of sample/sum
    pui.data.swi.swics=average_hist(swics,swiactime,binsize=binsize,range=trange,xbins=centertime); swia coarse survey
    swicsdt=swics[1:*].time_unix-swics[0:-1].time_unix
    store_data,'mvn_swics_dt_(s)',swics[1:*].time_unix,swicsdt
  endif

  if keyword_set(swica) then begin ;swia archive (burst) data
    swiactime = swica.time_unix +4.0*swica.num_accum/2  ;center time of sample/sum
    pui.data.swi.swica=average_hist(swica,swiactime,binsize=binsize,range=trange,xbins=centertime); swia coarse archive
    swicadt=swica[1:*].time_unix-swica[0:-1].time_unix
    store_data,'mvn_swica_dt_(s)',swica[1:*].time_unix,swicadt
  endif else pui.data.swi.swica=pui.data.swi.swics ;if no archive availabe at all, use survey instead
  badindex=where(~finite(pui.data.swi.swica.time_unix),/null) ;no archive availabe
  pui[badindex].data.swi.swica=pui[badindex].data.swi.swics ;use survey instead

  options,'mvn_swic?_dt_(s)','panel_size',.5
endelse

;----------SWEA----------
get_data,'swe_a4',data=sweaefdata; %swea energy spectrum
if keyword_set(sweaefdata) then begin
  sweaef=average_hist2(sweaefdata.y,sweaefdata.x,binsize=binsize,trange=trange,centertime=centertime); swea energy flux
  pui.data.swe.eflux=transpose(sweaef)
  
  sweadata=mvn_swe_engy
  swescpot=sweadata.sc_pot
  swescpot[where(~finite(swescpot),/null)]=0. ;when SWEA s/c potential is unknown, assume it's zero.
  
  mvn_swe_convert_units,sweadata,'df' ;convert SWEA units to phase-space density
  sweadata.energy-=replicate(1.,pui0.sweeb)#swescpot ;correct for s/c potential
  mvn_swe_convert_units,sweadata,'eflux' ;convert back to eflux
  
  store_data,'swe_a4_pot',data={x:sweadata.time,y:transpose(sweadata.data),v:transpose(sweadata.energy)},limits={spec:1,ylog:1,zlog:1,ystyle:1,yrange:[1.,5e3],zrange:[1e4,1e9],ztitle:'Eflux',ytickunits:'scientific'}
  sweaefpot=average_hist2(transpose(sweadata.data),sweadata.time,binsize=binsize,trange=trange,centertime=centertime); swea energy flux corrected for s/c potential
  sweaenpot=average_hist2(transpose(sweadata.energy),sweadata.time,binsize=binsize,trange=trange,centertime=centertime); swea energy bins corrected for s/c potential
  pui.data.swe.efpot=transpose(sweaefpot)
  pui.data.swe.enpot=transpose(sweaenpot)
  
  ;pui.data.swe=average_hist(mvn_swe_engy,mvn_swe_engy.time,binsize=binsize,range=trange,xbins=centertime,do_stdev=0); swea energy flux
  store_data,'mvn_redures_swea',data={x:centertime,y:sweaef,v:sweaefdata.v},limits={spec:1,ystyle:1,yrange:[3.,5e3],zrange:[1e4,1e9],ylog:1,zlog:1,ztitle:'Eflux',ytickunits:'scientific'}
  store_data,'mvn_redures_swea_pot',data={x:centertime,y:sweaefpot,v:sweaenpot},limits={spec:1,ystyle:1,yrange:[1.,5e3],zrange:[1e4,1e9],ylog:1,zlog:1,ztitle:'Eflux',ytickunits:'scientific'}
endif

;----------STATIC----------
;if keyword_set(sta_c0_L_E_data) then begin
;  sta_c0H=average_hist2(sta_c0_H_E_data.y,sta_c0_H_E_data.x,binsize=binsize,trange=trange,centertime=centertime); static c0
;  sta_c0L=average_hist2(sta_c0_L_E_data.y,sta_c0_L_E_data.x,binsize=binsize,trange=trange,centertime=centertime); static c0
;  staetc0=average_hist2(sta_c0_L_E_data.v,sta_c0_L_E_data.x,binsize=binsize,trange=trange,centertime=centertime); static energy table
;  store_data,'redures_H_sta_c0',centertime,sta_c0H,staetc0
;  store_data,'redures_L_sta_c0',centertime,sta_c0L,staetc0
;end

if keyword_set(mvn_c0_dat) then begin
  time = (mvn_c0_dat.time + mvn_c0_dat.end_time)/2.
  c0eflux=average_hist2(mvn_c0_dat.eflux,time,binsize=binsize,trange=trange,centertime=centertime); static c0 energy flux
  c0energy=average_hist2(mvn_c0_dat.energy[mvn_c0_dat.swp_ind,*,0],time,binsize=binsize,trange=trange,centertime=centertime); static c0 energy table
  pui.data.sta.c0.eflux=transpose(c0eflux,[1,2,0])
  pui.data.sta.c0.energy=transpose(c0energy)
  store_data,'mvn_redures_H_sta_c0',centertime,c0eflux[*,*,1],c0energy
  store_data,'mvn_redures_L_sta_c0',centertime,c0eflux[*,*,0],c0energy
endif

if keyword_set(mvn_d1_dat) and pui0.do3d then begin
  time = (mvn_d1_dat.time + mvn_d1_dat.end_time)/2.
  d1eflux=average_hist2(mvn_d1_dat.eflux,time,binsize=binsize,trange=trange,centertime=centertime); static d1 energy flux
  d1energy=average_hist2(mvn_d1_dat.energy[mvn_d1_dat.swp_ind,*,0,0],time,binsize=binsize,trange=trange,centertime=centertime); static d1 energy table
  pui.data.sta.d1.eflux=transpose(reform(d1eflux,[pui0.nt,pui0.sd1eb,pui0.swine,pui0.swina,8]),[1,3,2,4,0])
  pui.data.sta.d1.energy=transpose(d1energy)
  store_data,'mvn_sta_d1_dt_(s)',mvn_d1_dat.time,mvn_d1_dat.delta_t
  store_data,'mvn_sta_d1_sweep_index',mvn_d1_dat.time,mvn_d1_dat.swp_ind
  store_data,'mvn_sta_d1_mass_(amu)',mvn_d1_dat.time,reform(mvn_d1_dat.mass_arr[mvn_d1_dat.swp_ind,0,0,*])
  ylim,'mvn_sta_d1_mass_(amu)',1,1,1
  options,'mvn_sta_d1_dt_(s)','panel_size',.5
  options,'mvn_sta_d1_sweep_index','panel_size',.5
endif

;----------SEP----------
get_data,'mvn_sep1_B-O_Rate_Energy',data=sep1data ; SEP1 count rates
get_data,'mvn_sep2_B-O_Rate_Energy',data=sep2data ; SEP2 count rates
get_data,'mvn_sep1_svy_ATT',data=sep1at ; SEP1 attenuator state
get_data,'mvn_sep2_svy_ATT',data=sep2at ; SEP2 attenuator state
if keyword_set(sep1data) then begin
;  sep1att=interp(sep1at.y,sep1at.x,centertime)
;  sep2att=interp(sep2at.y,sep2at.x,centertime)
  sep1att=average_hist(sep1at.y,sep1at.x,binsize=binsize,range=trange,xbins=centertime)
  sep2att=average_hist(sep2at.y,sep2at.x,binsize=binsize,range=trange,xbins=centertime)
  sep1cps=average_hist2(sep1data.y,sep1data.x,binsize=binsize,trange=trange,centertime=centertime); sep1 counts/sec
  sep2cps=average_hist2(sep2data.y,sep2data.x,binsize=binsize,trange=trange,centertime=centertime); sep1 counts/sec
  pui.data.sep[0].rate_bo=transpose(sep1cps)
  pui.data.sep[1].rate_bo=transpose(sep2cps)
  pui.data.sep[0].att=sep1att
  pui.data.sep[1].att=sep2att
  pui1.sepet[0].sepbo=sep1data.v
  pui1.sepet[1].sepbo=sep2data.v

  store_data,'mvn_data_redures_sep1',centertime,sep1cps,sep1data.v
  store_data,'mvn_data_redures_sep2',centertime,sep2cps,sep2data.v
  options,'mvn_data_redures_sep?','spec',1
  options,'mvn_data_redures_sep?','ztitle','counts/s'
  options,'mvn_data_redures_sep?','ytickunits','scientific'
  options,'mvn_data_redures_sep?','ztickunits','scientific'
  ylim,'mvn_data_redures_sep?',10,1e3,1
  zlim,'mvn_data_redures_sep?',.1,1e4,1
endif

;----------EUV----------
;EUV 3 channels
get_data,'mvn_euv_data',data=euvdata ;EUV level 2 data (1 second cadence)
if keyword_set(euvdata) then pui.data.euv.l2=transpose(average_hist2(euvdata.y,euvdata.x,binsize=binsize,trange=trange,centertime=centertime))
;FISM irradiances (W/cm2/nm)
get_data,'mvn_euv_l3',data=fismdata ;FISM minute data
if keyword_set(fismdata) then pui.data.euv.l3=transpose(interp(fismdata.y,fismdata.x,centertime))

;----------Boundaries----------
;get_data,'wind',data=wind ;s/c altitude when in the solar wind (km)
;pui.model.swalt=average_hist2(wind.y,wind.x,binsize=binsize,trange=trange,centertime=centertime)
mvn_pui_sw_orbit_coverage,times=centertime,alt_sw=alt_sw
pui.data.swalt=alt_sw ;s/c altitude when in the solar wind (km)
;----------Positions----------
pui.data.scp=1e3*spice_body_pos('MAVEN','MARS',frame='MSO',utc=centertime,check_objects=['MARS','MAVEN_SPACECRAFT']) ;MAVEN position MSO (m)

mvn_pui_au_ls,times=centertime,mars_au=mars_au,mars_ls=mars_ls
pui.data.mars_au=mars_au ;Mars heliocentric distance (AU)
pui.data.mars_ls=mars_ls ;Mars Solar Longitude (Ls)

;----------FOV----------
xdir=[1.,0,0]#replicate(1.,pui0.nt) ;X-direction (SEP front FOV)
ydir=[0,1.,0]#replicate(1.,pui0.nt) ;Y-direction
zdir=[0,0,1.]#replicate(1.,pui0.nt) ;Z-direction (symmetry axis of SWIA and STATIC)
pui.data.sep[0].fov=spice_vector_rotate(xdir,centertime,'MAVEN_SEP1','MSO',check_objects='MAVEN_SPACECRAFT'); sep1 look direction MSO
pui.data.sep[1].fov=spice_vector_rotate(xdir,centertime,'MAVEN_SEP2','MSO',check_objects='MAVEN_SPACECRAFT'); sep2 look direction MSO
;swizld=transpose(spice_vector_rotate(zdir,centertime,'MAVEN_SWIA','MSO',check_objects='MAVEN_SPACECRAFT')); SWIA-Z look direction
pui.data.sta.fov.x=spice_vector_rotate(xdir,centertime,'MAVEN_STATIC','MSO',check_objects=['MAVEN_APP_OG','MAVEN_SPACECRAFT']); STATIC-X look direction
pui.data.sta.fov.z=spice_vector_rotate(zdir,centertime,'MAVEN_STATIC','MSO',check_objects=['MAVEN_APP_OG','MAVEN_SPACECRAFT']); STATIC-Z look direction

tplot_options,'no_interp',1

end