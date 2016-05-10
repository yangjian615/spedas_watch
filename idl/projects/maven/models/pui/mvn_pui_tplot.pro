;20160504 Ali
;create tplot variables from the pickup ion model results

pro mvn_pui_tplot,do3d=do3d,notplot=notplot

common mvn_pui_common
common mvn_swia_data

totet=exp(totdee*dindgen(toteb,start=126.5,increment=-1)); total flux energy bin midpoints (312 keV to 15.6 keV)
swiet=exp(swidee*dindgen(swieb,start=69.5,increment=-1)); SWIA (post Nov 2014) energy bin midpoints (23 keV to 26 eV)
staet=exp(stadee*dindgen(staeb,start=63.4,increment=-1)); STATIC (mode 4) energy bin midpoints (31 keV to 1.0 eV)
sweet=exp(swedee*dindgen(sweeb,start=72.5,increment=-1)); SWEA energy bin midpoints (4627 eV to 3.0 eV)

store_data,'mvn_model_puh_tot',data={x:centertime,y:kefluxh,v:totet}, $
  dlimits={ylog:1,zlog:1,spec:1,yrange:[10.,300e3],ytitle:'Model PUH',zrange:[1e2,1e6],ztitle:'Eflux'}
store_data,'mvn_model_puo_tot',data={x:centertime,y:kefluxo,v:totet}, $
  dlimits={ylog:1,zlog:1,spec:1,yrange:[10.,300e3],ytitle:'Model PUO',zrange:[1e2,1e6],ztitle:'Eflux'}
store_data,'mvn_model_puo_sep1',centertime,sepeb1att,sep1data.v
store_data,'mvn_model_puo_sep2',centertime,sepeb2att,sep2data.v
options,'mvn_model_puo_sep?','spec',1
ylim,'mvn_model_puo_sep?',10,1e3,1
zlim,'mvn_model_puo_sep?',.1,1e4,1
store_data,'mvn_swia_model',centertime,kefswih+kefswio,swiet
;store_data,'model_o_swia',centertime,kefswio,swiaet
;store_data,'model_h_swia',centertime,kefswih,swiaet
store_data,'mvn_model_H_sta_c0',centertime,kefstao,staet
store_data,'mvn_model_L_sta_c0',centertime,kefstah,staet
options,'*_sta_c0','spec',1
ylim,'*_sta_c0',1,35e3,1
zlim,'*_sta_c0',1e3,1e8,1

if keyword_set(do3d) then begin
  for j=0,swina-1 do begin ;loop over azimuth bins
    for k=0,swine-1 do begin ;loop over elevation bins
      jj=15-((j+9) mod 16)
      store_data,'mvn_swia_model_3d_A'+strtrim(jj,2)+'_D'+strtrim(k,2),centertime,kefswih3d[*,*,jj,k]+kefswio3d[*,*,jj,k],swiet
      store_data,'mvn_swia_data_3d_A'+strtrim(jj,2)+'_D'+strtrim(k,2),swica.time_unix,transpose(swica[*].data[*,k,jj]),swiet
      ;     store_data,'mvn_model_H_sta_c0',centertime,kefstao3d,staet
      ;     store_data,'mvn_model_L_sta_c0',centertime,kefstah3d,staet
    endfor
  endfor
endif
options,'mvn_swia*','spec',1
ylim,'mvn_swia*',25,25e3,1
zlim,'mvn_swia*',1e3,1e8,1

if ~keyword_set(notplot) then begin
  if keyword_set(do3d) then begin
wi,1,wsize=[480,1000],wposition=[3*480,0]
wi,2,wsize=[480,1000],wposition=[2*480,0]
wi,3,wsize=[480,1000],wposition=[1*480,0]
wi,4,wsize=[480,1000],wposition=[0*480,0]
wi,5,wsize=[480,1000],wposition=[3*480,0]
wi,6,wsize=[480,1000],wposition=[2*480,0]
wi,7,wsize=[480,1000],wposition=[1*480,0]
wi,8,wsize=[480,1000],wposition=[0*480,0]
tplot,'mvn_swia_data_3d_A*_D0',window=1
tplot,'mvn_swia_data_3d_A*_D1',window=2
tplot,'mvn_swia_data_3d_A*_D2',window=3
tplot,'mvn_swia_data_3d_A*_D3',window=4
tplot,'mvn_swia_model_3d_A*_D0',window=5
tplot,'mvn_swia_model_3d_A*_D1',window=6
tplot,'mvn_swia_model_3d_A*_D2',window=7
tplot,'mvn_swia_model_3d_A*_D3',window=8
  endif

wi,0,wsize=[1200,1800]
tplot,'MAVEN_pos_(km) alt2 swe_a4 redures_swea mvn_swim_density n_sw_(cm-3) mvn_swim_velocity_mso Vsw_MSO_(km/s) mvn_swim_atten_state mvn_swim_swi_mode mvn_swis_en_eflux mvn_swia_data_redures mvn_swia_model mvn_B_1sec MAG_MSO_(nT) O+_Max_Energy_(keV) mvn_sep?_B-O_Rate_Energy mvn_model_puo_sep? mvn_SEPS_svy_ATT mvn_euv_l3 Ionization_Frequencies_(s-1) *_sta_c0 mvn_sta_c0_att mvn_sta_c0_mode',window=0
endif

;tplot_names
;printdat
end