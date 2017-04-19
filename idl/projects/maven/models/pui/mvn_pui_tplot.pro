;20160504 Ali
;creates tplot variables from data and pickup ion model results
;keywords:
;   store: stores model-data comparisons in tplot variables (use with one of the following keywords)
;   tplot: plots the main results (model-data comparison)
;   swia3d: plots SWIA pickup hydrogen and oxygen 3d spectra
;   stah3d: plots STATIC 3d spectra, pickup hydrogen, D1 data product, mass channel=0 or sum of 0,1,2
;   stao3d: plots STATIC 3d spectra  pickup oxygen,   D1 data product, mass channel=4 or sum of 3,4,5
;   datimage: plots 3d data images instead of tplots (use instead of 'store' with one of the above 3d keywords)
;   modimage: plots 3d model images instead of tplots
;   d2mimage: plots 3d images of data to model ratios
;   tohban: plots Tohban-related data

pro mvn_pui_tplot,store=store,tplot=tplot,swia3d=swia3d,stah3d=stah3d,stao3d=stao3d,datimage=datimage,modimage=modimage,d2mimage=d2mimage,tohban=tohban

@mvn_pui_commonblock.pro ;common mvn_pui_common

if ~keyword_set(pui) then begin
  dprint,'Please run mvn_pui_model first. returning...'
  return
endif

if keyword_set(swia3d) || keyword_set(stah3d) || keyword_set(stao3d) then switch3d=1 else switch3d=0
tplot_options,'no_interp',1
centertime=pui.centertime

;*************STORE 1D DATA*************
if keyword_set(store) and (keyword_set(tplot) or keyword_set(tohban)) then begin
  store_data,'MAVEN_pos_(km)',data={x:centertime,y:transpose(pui.data.scp)/1e3},limits={colors:'bgr',labels:['x','y','z'],labflag:1}
  store_data,'mvn_sep1_fov',centertime,transpose(pui.data.sep[0].fov)
  store_data,'mvn_sep2_fov',centertime,transpose(pui.data.sep[1].fov)
  store_data,'mvn_stax_fov',centertime,transpose(pui.data.sta.fov.x)
  store_data,'mvn_staz_fov',centertime,transpose(pui.data.sta.fov.z)
  options,'mvn_*_fov','colors','bgr'
  ylim,'mvn_*_fov',-1,1
  options,'mvn_*_fov','panel_size',.5

mag=transpose(pui.data.mag.mso)
emot=pui.model.params.kemax/pui.model.params.rg/2. ;motional electric field magnitude (V/m)
nsw=pui.data.swi.swim.density ;solar wind density (cm-3)
fsw=pui.data.swi.swim2.fsw ;solar wind number flux (cm-2 s-1)
esw=1e-3*pui.data.swi.swim2.esw ;solar wind proton energy (keV)
mfsw=pui.data.swi.swim2.mfsw ;solar wind proton momentum flux (g cm-1 s-2)
efsw=pui.data.swi.swim2.efsw ;solar wind proton energy flux (eV cm-2 s-1)
sintub=sqrt(pui.model.params.kemax/(4*1e3*[1,16]#esw))
eden=pui.data.swe.eden ;swea electron density (cm-3)
edenpot=pui.data.swe.edenpot ;swea electron density (cm-3)

store_data,'mvn_mag_MSO_(nT)',data={x:centertime,y:1e9*[[mag],[sqrt(total(mag^2,2))]]},limits={yrange:[-10,10],labels:['Bx','By','Bz','Btot'],colors:'bgrk',labflag:1}
store_data,'mvn_mag_Btot_(nT)',data={x:centertime,y:1e9*sqrt(total(mag^2,2))},limits={yrange:[.1,1000],ylog:1}
store_data,'mvn_Nsw_(cm-3)',data={x:centertime,y:pui.data.swi.swim.density},limits={yrange:[.01,100],ylog:1}
store_data,'mvn_Vsw_MSO_(km/s)',data={x:centertime,y:[[transpose(pui.data.swi.swim.velocity_mso)],[-pui.data.swi.swim2.usw]]},limits={labels:['Vx','Vy','Vz','-Vtot'],colors:'bgrk',labflag:1}
store_data,'Sin(thetaUB)',data={x:centertime,y:transpose(sintub)},limits={yrange:[0,1]}
store_data,'E_Motional_(V/km)',data={x:centertime,y:1e3*transpose(emot)},limits={yrange:[.01,10],ylog:1}
store_data,'Pickup_Gyro_Period_(sec)',data={x:centertime,y:transpose(pui.model[0:1].params.tg)},limits={yrange:[1,1e3],ylog:1,labels:['H+','O+'],colors:'br',labflag:1}
store_data,'Pickup_Gyro_Radius_(1000km)',data={x:centertime,y:transpose(pui.model[0:1].params.rg/1e6)},limits={yrange:[.1,100],ylog:1,labels:['H+','O+'],colors:'br',labflag:1}
store_data,'Pickup_Max_Energy_(keV)',data={x:centertime,y:[[transpose(pui.model[0:1].params.kemax/1e3)],[esw],[4*esw],[4*16*esw]]},limits={yrange:[.1,300],ylog:1,labels:['H+','O+','SWIA','4xSWIA','64xSWIA'],colors:'brgcm',labflag:1}
store_data,'Pickup_Number_Density_(cm-3)',data={x:centertime,y:[[transpose(pui.model[0:1].params.totnnn)],[nsw],[eden],[edenpot]]},limits={yrange:[.001,100],ylog:1,labels:['H+','O+','SWIA','SWEA','SWEApot'],colors:'brgcm',labflag:1}
store_data,'Pickup_Number_Flux_(cm-2.s-1)',data={x:centertime,y:[[transpose(pui.model[0:1].params.totphi)],[fsw]]},limits={yrange:[1e4,1e9],ylog:1,labels:['H+','O+','SWIA'],colors:'brg',labflag:1}
store_data,'Pickup_Momentum_Flux_(g.cm-1.s-2)',data={x:centertime,y:[[transpose(pui.model[0:1].params.totmph)],[mfsw]]},limits={yrange:[1e-11,1e-7],ylog:1,labels:['H+','O+','SWIA'],colors:'brg',labflag:1}
store_data,'Pickup_Energy_Flux_(eV.cm-2.s-1)',data={x:centertime,y:[[transpose(pui.model[0:1].params.toteph)],[efsw]]},limits={yrange:[1e8,1e12],ylog:1,labels:['H+','O+','SWIA'],colors:'brg',labflag:1}
store_data,'O+_Max_Energy_(keV)',centertime,pui.model[1].params.kemax/1e3 ;pickup oxygen max energy (keV)

store_data,'mvn_model_puh_tot',data={x:centertime,y:transpose(pui.model[0].fluxes.toteflux),v:pui1.totet},limits={ylog:1,zlog:1,spec:1,yrange:[10.,30e3],zrange:[1e2,1e6],ztitle:'Eflux'}
store_data,'mvn_model_puo_tot',data={x:centertime,y:transpose(pui.model[1].fluxes.toteflux),v:pui1.totet},limits={ylog:1,zlog:1,spec:1,yrange:[100.,300e3],zrange:[1e2,1e6],ztitle:'Eflux'}
;store_data,'mvn_model_pux_tot',data={x:centertime,y:transpose(pui.model[2].fluxes.toteflux),v:pui1.totet},limits={ylog:1,zlog:1,spec:1,yrange:[10.,300e3],zrange:[1e2,1e6],ztitle:'Eflux'}

rmars=3400e3 ;mars radius (m)
for i=0,1 do begin ;loop over 2 seps
  sepx=pui.model[1].fluxes.sep[i].rv[0:2]
  sepv=pui.model[1].fluxes.sep[i].rv[3:5]
store_data,'mvn_model_puo_sep'+strtrim(i+1,2),data={x:centertime,y:transpose(pui.model[1].fluxes.sep[i].model_rate),v:pui1.sepet[i].sepbo},limits={spec:1,ylog:1,zlog:1,yrange:[10,1e3],zrange:[.1,1e4],ztitle:'counts/s',ztickunits:'scientific',ytickunits:'scientific'}
store_data,'mvn_model_puo_sep'+strtrim(i+1,2)+'_source_MSO_(Rm)',data={x:centertime,y:[[transpose(sepx)],[sqrt(total(sepx^2,1))]]/rmars},limits={labels:['x','y','z','r'],colors:'bgrk',labflag:1}
store_data,'mvn_model_puo_sep'+strtrim(i+1,2)+'_MSO_(km/s)',data={x:centertime,y:[[transpose(sepv)],[sqrt(total(sepv^2,1))]]/1e3},limits={labels:['x','y','z','v'],colors:'bgrk',labflag:1}
store_data,'mvn_model_puh_raw_sep'+strtrim(i+1,2),data={x:centertime,y:transpose(pui.model[0].fluxes.sep[i].incident_rate)},limits={spec:1,zlog:1,yrange:[0,10],zrange:[1,1e4]}
store_data,'mvn_model_puo_raw_sep'+strtrim(i+1,2),data={x:centertime,y:transpose(pui.model[1].fluxes.sep[i].incident_rate)},limits={spec:1,zlog:1,yrange:[0,200],zrange:[1,1e4]}
;store_data,'mvn_model_pux_raw_sep'+strtrim(i+1,2),centertime,transpose(pui.model[2].fluxes.sep[i].incident_rate)
endfor

kefswih=transpose(pui.model[0].fluxes.swi1d.eflux)
kefswio=transpose(pui.model[1].fluxes.swi1d.eflux)
store_data,'mvn_model_swia',centertime,kefswih+kefswio,pui1.swiet
;store_data,'mvn_model_swia_O',centertime,kefswio,pui1.swiet
;store_data,'mvn_model_swia_H',centertime,kefswih,pui1.swiet
options,'mvn_model_swia','spec',1
options,'mvn_model_swia','ztitle','Eflux'
options,'mvn_model_swia','ytickunits','scientific'
ylim,'mvn_model_swia',25,25e3,1
zlim,'mvn_model_swia',1e3,1e8,1

kefstah=transpose(pui.model[0].fluxes.sta1d.eflux)
kefstao=transpose(pui.model[1].fluxes.sta1d.eflux)
store_data,'mvn_model_H_sta_c0',centertime,kefstao,pui1.staet
store_data,'mvn_model_L_sta_c0',centertime,kefstah,pui1.staet
endif
;*********END STORE 1D DATA*************

if keyword_set(mvn_d1_dat) then begin
;  d1eflux=transpose(pui.data.sta.d1.eflux,[3,0,1,2])
;  d1energy=transpose(pui.data.sta.d1.energy)
;  store_data,'redures_d1H_sta_c0',centertime,mean(total(d1eflux[*,*,*,3:5],4),dim=3),d1energy,verbose=verbose
;  store_data,'redures_d1L_sta_c0',centertime,mean(total(d1eflux[*,*,*,6:7],4),dim=3),d1energy,verbose=verbose
endif
options,'*_sta_c0','spec',1
options,'*_sta_c0','ztitle','Eflux'
options,'*_sta_c0','ytickunits','scientific'
ylim,'*_sta_c0',1,35e3,1
zlim,'*_sta_c0',1e3,1e8,1

;*************STORE 3D DATA*************
if keyword_set (datimage) or keyword_set (modimage) or keyword_set (d2mimage) then img=1
if switch3d and (keyword_set(store) or keyword_set(img)) then begin
  store_data,'mvn_s*_model*_A*D*',/delete
  store_data,'mvn_s*_data*_A*D*',/delete
  dprint,dlevel=2,'Creating 3D tplots. This will take a few seconds to complete...'

  kefswih3d=transpose(pui.model[0].fluxes.swi3d.eflux,[3,0,1,2])
  kefswio3d=transpose(pui.model[1].fluxes.swi3d.eflux,[3,0,1,2])
  kefstah3d=transpose(pui.model[0].fluxes.sta3d.eflux,[3,0,1,2])
  kefstao3d=transpose(pui.model[1].fluxes.sta3d.eflux,[3,0,1,2])

  if keyword_set(swica) and keyword_set(swia3d) then begin
    ;swap swia dimentions to match the model (time-energy-az-el)
    ;also, reverse the order of elevation (deflection) angles to start from positive theta (like static)
    swiaef3d=reverse(transpose(pui.data.swi.swica.data,[3,0,2,1]),4)
    swicaen=transpose(info_str[pui.data.swi.swica.info_index].energy_coarse)
  endif
  d1eflux=transpose(pui.data.sta.d1.eflux,[4,0,1,2,3])
  d1energy=transpose(pui.data.sta.d1.energy)

  verbose=0
  for j=0,pui0.swina-1 do begin ;loop over azimuth bins (phi)
    for k=0,pui0.swine-1 do begin ;loop over elevation bins (theta): + to - theta goes left to right on the screen
      jj=15-((j+9) mod 16) ;to sort vertical placement of tplot panels: center is sunward for swia

      if keyword_set(swia3d) then begin
        kefswi3d=kefswih3d[*,*,jj,k]+kefswio3d[*,*,jj,k]
        if keyword_set(img) then begin
          if j eq 0 and k eq 0 then p=window(background_color='k')
          if keyword_set(modimage) then p=image(alog10(kefswi3d),layout=[4,16,1+k+j*4],/current,margin=0.1,rgb_table=33,aspect=0,min=4,max=7,axis_style=0,background_color='b',/order)
          if keyword_set(datimage) then p=image(alog10(swiaef3d[*,*,jj,k]),layout=[4,16,1+k+j*4],/current,margin=0.1,rgb_table=33,aspect=0,min=4,max=7,axis_style=0,background_color='b',/order)
          if keyword_set(d2mimage) then p=image(alog10(swiaef3d[*,*,jj,k]/kefswi3d),layout=[4,16,1+k+j*4],/current,margin=0.1,rgb_table=33,aspect=0,min=-1,max=1,axis_style=0,background_color='w',/order)
        endif else begin
          store_data,'mvn_swia_model_A'+strtrim(jj,2)+'D'+strtrim(k,2),centertime,kefswi3d,pui1.swiet,verbose=verbose
          if keyword_set(swica) then store_data,'mvn_swia_data_A'+strtrim(jj,2)+'D'+strtrim(k,2),centertime,swiaef3d[*,*,jj,k],swicaen,verbose=verbose
          options,'mvn_swia*_A*D*','spec',1
          options,'mvn_swia*_A*D*','ytickunits','scientific'
          ylim,'mvn_swia*_A*D*',25,25e3,1
          zlim,'mvn_swia*_A*D*',1e4,1e7,1
        endelse
      endif

      if keyword_set(stao3d) then begin
        if keyword_set(img) then begin
          if j eq 0 and k eq 0 then p=window(background_color='k')
          if keyword_set(modimage) then p=image(alog10(kefstao3d[*,*,jj,k]),layout=[4,16,1+k+j*4],/current,margin=0.1,rgb_table=33,aspect=0,min=4,max=7,axis_style=0,background_color='b',/order)
          if keyword_set(datimage) then p=image(alog10(d1eflux[*,*,jj,k,4]),layout=[4,16,1+k+j*4],/current,margin=0.1,rgb_table=33,aspect=0,min=4,max=7,axis_style=0,background_color='b',/order)
          if keyword_set(d2mimage) then p=image(alog10(d1eflux[*,*,jj,k,4]/kefstao3d[*,*,jj,k]),layout=[4,16,1+k+j*4],/current,margin=0.1,rgb_table=33,aspect=0,min=-1,max=1,axis_style=0,background_color='w',/order)
        endif else begin
          store_data,'mvn_stat_model_puo_A'+strtrim(jj,2)+'D'+strtrim(k,2),centertime,kefstao3d[*,*,jj,k],d1energy,verbose=verbose
          ;        if keyword_set(mvn_d1_dat) then store_data,'mvn_stat_data_HImass_A'+strtrim(jj,2)+'D'+strtrim(k,2),centertime,total(d1eflux[*,*,jj,k,3:5],5),d1energy,verbose=verbose
          if keyword_set(mvn_d1_dat) then store_data,'mvn_stat_data_HImass_A'+strtrim(jj,2)+'D'+strtrim(k,2),centertime,d1eflux[*,*,jj,k,4],d1energy,verbose=verbose
        endelse
      endif
        
      if keyword_set(stah3d) then begin
        if keyword_set(img) then begin
          if j eq 0 and k eq 0 then p=window(background_color='k')
          if keyword_set(modimage) then p=image(alog10(kefstah3d[*,*,jj,k]),layout=[4,16,1+k+j*4],/current,margin=0.1,rgb_table=33,aspect=0,min=4,max=7,axis_style=0,background_color='b',/order)
          if keyword_set(datimage) then p=image(alog10(d1eflux[*,*,jj,k,0]),layout=[4,16,1+k+j*4],/current,margin=0.1,rgb_table=33,aspect=0,min=4,max=7,axis_style=0,background_color='b',/order)
          if keyword_set(d2mimage) then p=image(alog10(d1eflux[*,*,jj,k,0]/kefstah3d[*,*,jj,k]),layout=[4,16,1+k+j*4],/current,margin=0.1,rgb_table=33,aspect=0,min=-1,max=1,axis_style=0,background_color='w',/order)
        endif else begin
          store_data,'mvn_stat_model_puh_A'+strtrim(jj,2)+'D'+strtrim(k,2),centertime,kefstah3d[*,*,jj,k],d1energy,verbose=verbose
          ;        if keyword_set(mvn_d1_dat) then store_data,'mvn_stat_data_LOmass_A'+strtrim(jj,2)+'D'+strtrim(k,2),centertime,total(d1eflux[*,*,jj,k,0:2],5),d1energy,verbose=verbose
          if keyword_set(mvn_d1_dat) then store_data,'mvn_stat_data_LOmass_A'+strtrim(jj,2)+'D'+strtrim(k,2),centertime,d1eflux[*,*,jj,k,0],d1energy,verbose=verbose
        endelse
      endif
      ;      store_data,'mvn_stat_data_3d_A'+strtrim(jj,2)+'_D'+strtrim(k,2),mvn_ca_dat.time,mvn_ca_dat.eflux[*,*,k+4*jj],mvn_ca_dat.energy[mvn_ca_dat.swp_ind,*,0]
    endfor
  endfor

  options,'mvn_stat*_A*D*','spec',1
  options,'mvn_stat*_A*D*','ytickunits','scientific'
  ylim,'mvn_stat*_A*D*',10,35e3,1
  zlim,'mvn_stat*_A*D*',1e4,1e7,1
endif
;*********END STORE 3D DATA*************

if keyword_set(swia3d) then begin
  swiastat='swia'
  modelmass=''
  datamass=''
endif

if keyword_set(stah3d) then begin
  swiastat='stat'
  modelmass='_puh'
  datamass='_LOmass'
endif

if keyword_set(stao3d) then begin
  swiastat='stat'
  modelmass='_puo'
  datamass='_HImass'
endif

if switch3d and ~keyword_set(img) then begin
  !p.background=2
  !p.color=-1
  wi,1,wsize=[480,1000],wposition=[0*480,0]
  wi,5,wsize=[480,1000],wposition=[0*480,0]
  wi,2,wsize=[480,1000],wposition=[1*480,0]
  wi,6,wsize=[480,1000],wposition=[1*480,0]
  wi,3,wsize=[480,1000],wposition=[2*480,0]
  wi,7,wsize=[480,1000],wposition=[2*480,0]
  wi,4,wsize=[480,1000],wposition=[3*480,0]
  wi,8,wsize=[480,1000],wposition=[3*480,0]
  tplot,'mvn_'+swiastat+'_data'+datamass+'_A*D0',window=1
  tplot,'mvn_'+swiastat+'_data'+datamass+'_A*D1',window=2
  tplot,'mvn_'+swiastat+'_data'+datamass+'_A*D2',window=3
  tplot,'mvn_'+swiastat+'_data'+datamass+'_A*D3',window=4
  tplot,'mvn_'+swiastat+'_model'+modelmass+'_A*D0',window=5
  tplot,'mvn_'+swiastat+'_model'+modelmass+'_A*D1',window=6
  tplot,'mvn_'+swiastat+'_model'+modelmass+'_A*D2',window=7
  tplot,'mvn_'+swiastat+'_model'+modelmass+'_A*D3',window=8
  !p.background=-1
  !p.color=0
endif

if keyword_set(tplot) then begin
wi,10 ;tplot raw data
tplot,window=10,'MAVEN_pos_(km) swea_a4_pot mvn_swim_density mvn_swim_velocity_mso mvn_swim_atten_state mvn_swim_swi_mode mvn_swis_en_eflux mvn_swics_dt_(s) mvn_swica_dt_(s) mvn_B_1sec mvn_sep?_svy_DURATION mvn_sep?_fov mvn_sep?_B-O_Rate_Energy mvn_euv_l3 mvn_euv_data mvn_staz_fov mvn_sta_c0_att mvn_sta_c0_mode mvn_sta_d1_sweep_index mvn_sta_d1_mass_(amu) mvn_sta_d1_dt_(s)'
wi,20 ;tplot useful pickup ion variables. for diagnostic purposes, best shown on a vertical screen
tplot,window=20,'mvn_mag_Btot_(nT) Sin(thetaUB) E_Motional_(V/km) Pickup_* Ionization_Frequencies_(s-1)'
wi,30 ;tplot other stuff
tplot,window=30,'mvn_model_pu?_tot mvn_model_pu*_raw_sep1 mvn_model_puo_sep1_source_MSO_(Rm) mvn_model_puo_sep1_MSO_(km/s) mvn_model_pu*_raw_sep2 mvn_model_puo_sep2_source_MSO_(Rm) mvn_model_puo_sep2_MSO_(km/s) redures_d1H_sta_c0 redures_d1L_sta_c0'
wi,0 ;tplot main results (model-data comparison)
tplot,window=0,'alt2 mvn_redures_swea_pot mvn_Nsw_(cm-3) mvn_Vsw_MSO_(km/s) mvn_redures_swia mvn_model_swia mvn_mag_MSO_(nT) mvn_data_redures_sep1 mvn_model_puo_sep1 mvn_SEPS_svy_ATT mvn_data_redures_sep2 mvn_model_puo_sep2 O+_Max_Energy_(keV) mvn_redures_H_sta_c0 mvn_model_H_sta_c0 mvn_redures_L_sta_c0 mvn_model_L_sta_c0'
endif

if keyword_set(tohban) then tplot,'alt2 swea_a4_pot mvn_swis_en_eflux mvn_Nsw_(cm-3) mvn_Vsw_MSO_(km/s) mvn_sep1_A-F_Rate_Energy mvn_sep1_B-O_Rate_Energy mvn_mag_MSO_(nT) mvn_mag_Btot_(nT) mvn_redures_L_sta_c0 mvn_redures_H_sta_c0'

end