;20160404 Ali
;This code uses analytical solutions to the equations of motion
;of pickup ions in the upstream undistrubed solar wind uniform fields
;and finds pickup ion fluxes near Mars at the location of MAVEN.
;For more info, refer to Ali's PhD thesis, also see Rahmati et al. (2014, 2015)
;This code assumes that the user has access to the pfp data

pro mvn_pui_model,binsize=binsize,trange=trange,np=np,nodataload=nodataload

common mvn_pui_common,mag,vsw,usw,nsw,scp,kemax, $
  rxyz,vxyz,drxyz,ntot,ke, $
  sep1ld,sep2ld,stazld,cosvsep1,cosvsep2,cosvswiz,cosvstaz, $
  inn,centertime,sep1att,sep1data,sep2att,sep2data,sweaef, $
  fismir,ifreq_o,ifreq_h, $
  keflux,keflux1,keflux2,kefswi,kefsta,totdee,swidee,stadee,swedee,swiatsa, $
  srmd,swieb,staeb,sweeb,toteb
  
srmd=700; %sep response matrix dimentions
sopeb=30 ;sep open # of energy bins
swieb=48 ;swia # of energy bins
staeb=64 ;static # of energy bins
sweeb=64 ;swea # of energy bins
toteb=100;total flux # of energy bins

swiatsa=!pi*2.8 ; SWIA and STATIC total solid angle (2.8pi sr)

swidee=.14464; %SWIA dE/E
stadee=.1633; %STATIC dE/E
swedee=.1165; %SWEA dE/E
totdee=.1

if ~keyword_set(binsize) then binsize=30 ;simulation resolution/cadence (seconds)
if ~keyword_set(np) then np=1000; %number of simulated particles (1000 is enough for one gyro-period)
if ~keyword_set(trange) then get_timespan,trange else timespan,trange ;time range
if ~keyword_set(nodataload) then mvn_pui_data_load ;load tplot variables
mvn_pui_data_res,trange=trange,binsize=binsize ;change data resolution and load instrument pointings
mvn_pui_data_analyze ;analyze data

dprint,dlevel=2,'All data loaded successfully, the pickup ion model is now calculating...'
dprint,dlevel=2,'The simulation should take ~'+strtrim(ceil(10.*np*inn/1000/2880),2)+' seconds on a modern machine.'
simtime=systime(1) ;simulation start time, let's do this!

;modeling pickup oxygen
mamu=16; %mass of [H=1 C=12 N=14 O=16] (amu)
mvn_pui_solver,mamu=mamu,np=np,ntg=0.999 ;solve pickup ion trajectories
ntot=drxyz/((rxyz-2400e3)^2.1); %for Mars oxygen exosphere (m-1.1) fit to Rahmati et al., 2014
mvn_pui_binner,mamu=mamu,np=np ;bin the results

qqo=5e22; %for mars oxygen exosphere (m-0.9) fit to Rahmati et al., 2014
;ifreq=4.5e-7; ionization frequency (s-1) per Rahmati et al., 2014
keflux1=1e-4*qqo*keflux1*(ifreq_o#replicate(1.,srmd)); %sep1 differential flux (/[cm2 s keV])
keflux2=1e-4*qqo*keflux2*(ifreq_o#replicate(1.,srmd)); %sep2 differential flux (/[cm2 s keV])
kefluxo=1e-4*qqo*keflux*(ifreq_o#replicate(1.,toteb))/totdee; %pickup oxygen differential energy flux (eV/[cm2 s eV])
kefswio=1e-4*qqo*kefswi*(ifreq_o#replicate(1.,swieb))/swidee/swiatsa; %differential energy flux (eV/[cm2 s sr eV])
kefstao=1e-4*qqo*kefsta*(ifreq_o#replicate(1.,staeb))/stadee/swiatsa; %differential energy flux (eV/[cm2 s sr eV])

seprm=replicate(0.,srmd,srmd); %sep response matrix, very crude!
for j=0,srmd-1 do for i=0,srmd-1 do seprm[j,i]=.05*j^.022*exp(-1./100.*(i-(j-55.))^2)
;seprm(1:10,:)=0; %sep electronic noise threshold = 11 keV
sepde=total(seprm,1); %sep pickup oxygen detection efficiency
sepflux1=seprm##keflux1; %sep1 flux
sepflux2=seprm##keflux2; %sep2 flux
sepet=[1,8,10,11,13,15,17,20,24,30,37,47,60,77,100,130,169,220,300,400,500,650]; %sep energy table (keV)
sepeb1=replicate(0.,inn,sopeb); sep energy binning
sepeb2=replicate(0.,inn,sopeb)
for i=0,20 do begin ;very crude way of binning, needs to be changed!
sepeb1[*,i]=total(sepflux1[*,sepet[i]-1:sepet[i+1]-1],2);
sepeb2[*,i]=total(sepflux2[*,sepet[i]-1:sepet[i+1]-1],2);
endfor

;reducing the count rates by a factor of 100 when the SEP attenuator is closed
sepeb1att=sepeb1/(99.*(sep1att#replicate(1,sopeb))-98)
sepeb2att=sepeb2/(99.*(sep2att#replicate(1,sopeb))-98)

store_data,'O+_Max_Energy_(keV)',centertime,kemax/1e3 ;pickup oxygen max energy (keV)
dprint,dlevel=2,'Pickup O+ done, now simulating pickup H+'

;Now let's model pickup hydrogen
mamu=1; %mass of [H=1 C=12 N=14 O=16] (amu)
mvn_pui_solver,mamu=mamu,np=np,ntg=2.999 ;solve pickup ion trajectories
ntot=drxyz/((rxyz-2700e3)^2.7); %for Mars hydrogen exosphere (m-1.7) fit to Feldman et al., 2011
mvn_pui_binner,mamu=mamu,np=np ;bin the results

qqh=4e27; %for mars hydrogen exosphere (m-0.3) fit to Feldman et al., 2011
kefluxh=1e-4*qqh*keflux*(ifreq_h#replicate(1.,toteb))/totdee; %pickup hydrogen differential energy flux (eV/[cm2 s eV])
kefswih=1e-4*qqh*kefswi*(ifreq_h#replicate(1.,swieb))/swidee/swiatsa; %differential energy flux (eV/[cm2 s sr eV])
kefstah=1e-4*qqh*kefsta*(ifreq_h#replicate(1.,staeb))/stadee/swiatsa; %differential energy flux (eV/[cm2 s sr eV])

totet=exp(totdee*dindgen(toteb,start=126.5,increment=-1)); total flux energy bin midpoints (312 keV to 15.6 keV)
swiet=exp(swidee*dindgen(swieb,start=69.5,increment=-1)); SWIA (post Nov 2014) energy bin midpoints (23 keV to 26 eV)
staet=exp(stadee*dindgen(staeb,start=63.4,increment=-1)); STATIC (mode 4) energy bin midpoints (31 keV to 1.0 eV)
sweet=exp(swedee*dindgen(sweeb,start=72.5,increment=-1)); SWEA energy bin midpoints (4627 eV to 3.0 eV)

;create tplot variables from the results
store_data,'model_puh_tot',data={x:centertime,y:kefluxh,v:totet}, $
  dlimits={ylog:1,zlog:1,spec:1,yrange:[10.,300e3],ytitle:'Model PUH',zrange:[1e2,1e6],ztitle:'Eflux'}
store_data,'model_puo_tot',data={x:centertime,y:kefluxo,v:totet}, $
  dlimits={ylog:1,zlog:1,spec:1,yrange:[10.,300e3],ytitle:'Model PUO',zrange:[1e2,1e6],ztitle:'Eflux'}
store_data,'model_sep1',centertime,sepeb1att,sep1data.v
store_data,'model_sep2',centertime,sepeb2att,sep2data.v
options,'model_sep*','spec',1
ylim,'model_sep*',10,1e3,1
zlim,'model_sep*',.1,1e4,1
store_data,'model_swia',centertime,kefswih+kefswio,swiet
;store_data,'model_o_swia',centertime,kefswio,swiaet
;store_data,'model_h_swia',centertime,kefswih,swiaet
options,'*_swia','spec',1
ylim,'*_swia',25,25e3,1
zlim,'*_swia',1e3,1e8,1
store_data,'model_H_sta_c0',centertime,kefstao,staet
store_data,'model_L_sta_c0',centertime,kefstah,staet
options,'*_sta_c0','spec',1
ylim,'*_sta_c0',1,35e3,1
zlim,'*_sta_c0',1e3,1e8,1

;tplot_names
;printdat
tplot,'MAVEN_pos_(km) alt2 swe_a4 redures_swea mvn_swim_density n_sw_(cm-3) mvn_swim_velocity_mso Vsw_MSO_(km/s) mvn_swim_atten_state mvn_swim_swi_mode mvn_swis_en_eflux *_swia mvn_B_1sec MAG_MSO_(nT) O+_Max_Energy_(keV) mvn_sep?_B-O_Rate_Energy model_sep? mvn_SEPS_svy_ATT mvn_euv_l3 Ionization_Frequencies_(s-1) *_sta_c0 mvn_sta_c0_att mvn_sta_c0_mode'
dprint,dlevel=2,'Simulation time: '+strtrim(systime(1)-simtime,2)+' seconds'

end
