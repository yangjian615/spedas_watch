;20160706 Ali
;models pickup ion fluxes using given constant upstream driver parameters

pro mvn_pui_flux_drivers,do3d=do3d

@mvn_pui_commonblock.pro ;common mvn_pui_common

nt=100 ;number of time steps
np=1000 ;number of simulated particles (1000 is enough for one gyro-period)

get_timespan,trange
mvn_pui_aos,nt=nt,np=np,binsize=1.,trange=trange,do3d=do3d ;initializes the array of structures for time series (pui) and defines intrument constants

pui0.msub=1 ;species subscript (0=H, 1=O)
pui0.mamu[pui0.msub]=16. ;mass of [H=1 C=12 N=14 O=16] (amu)
pui0.ngps[pui0.msub]=2.999 ;for SEP one full gyro-period is necessary, a few gyro-periods required for pickup hydrogen

pui.centertime=dgen(nt,range=timerange(trange))
pui.data.mag.mso=1e-9*[0,5,0] ;magnetic field (T)
pui.data.mag.mso[0]=1e-9*findgen(nt)
pui.data.swi.swim.velocity_mso=[-650,0,0] ;solar wind velocity (km/s)
pui.data.scp=[7000e3,0,0] ;s/c position (m)
pui.data.swi.swim.density=5. ;solar wind density (cm-3)
pui.data.sep[0].fov=[1,-1,0]/sqrt(2)
pui.data.sep[1].fov=[1,+1,0]/sqrt(2)

mvn_pui_data_analyze
pui.model[pui0.msub].ifreq.tot=5e-7*replicate(1.,nt) ;ionization frequency (s-1)

mvn_pui_solver ;solve pickup ion trajectories

;csspos=1e3*spice_body_pos('CSS','MARS',frame='MSO',utc='14-10-19/18:30') ;CSS position MSO (m)

;rcss=sqrt((r3x-csspos[0])^2+(r3y-csspos[1])^2+(r3z-csspos[2])^2) ;pickup ion distance from CSS (m)

nnh=mvn_pui_exoden(pui2.rtot,species='h') ;neutral exospheric density (cm-3)
nno=mvn_pui_exoden(pui2.rtot,species='o')
;nncss=mvn_pui_exoden(rcss,'css')

;nden=nncss
nden=nno
mvn_pui_flux_calculator,nden,dphi
mvn_pui_binner,dphi,do3d=do3d ;bin the results
if pui0.msub eq 1 then mvn_pui_sep_energy_response
mvn_pui_tplot,/store,/tplot

;times=dgen(np,range=timerange(trange))
;store_data,'n_(cm-3)',data={x:times,y:transpose([nnh,nno,nncss])},limits={labels:['H','O','CSS'],colors:'brg',labflag:1,ylog:1}
;store_data,'R_(km)',data={x:times,y:transpose([rxyz,rcss]/1e3)},limits={colors:'br',labels:['Mars','CSS'],labflag:1}
;store_data,'dR_(km)',times,transpose(drxyz/1e3)
;store_data,'E_(keV)',times,transpose(ke/1e3)
;store_data,'dE_(eV)',times,transpose(de)
;store_data,'dphi/dE_(cm-2.s-1.eV-1)',data={x:times,y:transpose(dphide)},limits={ylog:1}
;store_data,'dEphi/dE_(eV.cm-2.s-1.eV-1)',data={x:times,y:transpose(dephde)},limits={ylog:1}
;store_data,'dn/dE_(cm-3.eV-1)',data={x:times,y:transpose(dnnnde)},limits={ylog:1}
;stop



;p=plot([0],/xlog,/ylog,xrange=[100,100e3],yrange=[1000,1000e3],xtitle='Pickup Ion Energy (eV)',ytitle='Differential Energy Flux (eV/[cm2 s eV])')
;p=plot(ke,dephde,/o,c='b')
;p=plot(totet,keflux,/o,c='r')

;p=plot([0],/ylog,xrange=[0,200],yrange=[10,1e6],xtitle='Pickup Ion Energy (keV)',ytitle='Differential Flux (/[cm2 s keV])')
;p=plot(ke/1e3,1e3*dphide,/o,c='b')
;p=plot(kflux,/o,c='r')

;p=plot([0],/ylog,xtitle='Pickup Ion Energy (keV)',ytitle='Differential Density (/[cm3 keV])')
;p=plot(ke/1e3,1e3*dnnnde,/o,c='b')

;p=plot3d(reform(v3x)/1e3,reform(v3y)/1e3,reform(v3z)/1e3,/aspect_ratio,/aspect_z,xtitle='Vx (km/s)',ytitle='Vy (km/s)',ztitle='Vz (km/s)')
;rmars=3400e3 ;radius of mars (m)
;p=plot3d(reform(r3x)/rmars,reform(r3y)/rmars,reform(r3z)/rmars)
;p=scatterplot3d(/o,csspos[0]/rmars,csspos[1]/rmars,csspos[2]/rmars)
;mvn_pui_plot_mars_bow_shock,/rm,/p3d
end