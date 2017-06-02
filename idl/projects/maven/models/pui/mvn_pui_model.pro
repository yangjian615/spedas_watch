;20160404 Ali
;This code uses analytical solutions to the equations of motion
;of pickup ions in the upstream undistrubed solar wind uniform fields
;and finds pickup ion fluxes near Mars at the location of MAVEN.
;For more info, refer to Ali's PhD thesis (2016), also see Rahmati et al. (2014, 2015)
;Note that the results are only valid when MAVEN is outside the bow shock
;and in the upstream undisturbed solar wind, when upstream drivers are available.
;This code assumes that the user has access to the MAVEN PFP data.
;mvn_pui_tplot can be used to store and plot 3d pickup ion model-data comparisons.
;please send bugs/comments to rahmati@ssl.berkeley.edu
;
;Keywords:
;   binsize: specifies the time cadense (time bin size) for simulation in seconds. if not set, default is used (32 sec)
;   trange: time range for simulation. if not set, timespan will be called
;   np: number of simulated particles in each time bin. if not set, default is used (1000 particles)
;   ns: number of simulated species. default is 2 (H and O)
;   do3d: models pickup oxygen and hydrogen 3D spectra for SWIA and STATIC, a bit slower than 1D spectra and requires more memory
;   savetplot: saves the model-data comparison tplots as png files
;   exoden: sets exospheric neutral densities to n(r)=1 cm-3 for exospheric density retrieval by a reverse method
;   nodataload: skips loading any data. use if you want to re-run the simulation with all the required data already loaded
;   nomag: skips loading mag data. if not already loaded, uses default IMF
;   noswia: skips loading swia data. if not already loaded, uses default solar wind parameters
;   noswea: skips loading swea data. if not already loaded, uses default electron impact ionizattion frequencies
;   nostatic: skips loading static data
;   nosep: skips loading sep data
;   noeuv: skips loading euv data. if not already loaded, uses default photoionization frequencies
;   nospice: skips loading spice kernels (use in case spice is already loaded, otherwise the code will fail)

pro mvn_pui_model,binsize=binsize,trange=trange,np=np,ns=ns,do3d=do3d,exoden=exoden,savetplot=savetplot,nodataload=nodataload, $
                  nomag=nomag,noswia=noswia,noswea=noswea,nostatic=nostatic,nosep=nosep,noeuv=noeuv,nospice=nospice

@mvn_pui_commonblock.pro ;common mvn_pui_common

if ~keyword_set(binsize) then binsize=32. ;simulation resolution or cadense (seconds)
if ~keyword_set(trange) then get_timespan,trange else timespan,trange
if ~keyword_set(np) then np=1111; number of simulated particles (1000 is enough for one gyro-period)
if ~keyword_set(ns) then ns=2;  number of simulated species. default is 2 (H and O)
if ~keyword_set(nodataload) then mvn_pui_data_load,do3d=do3d,nomag=nomag,noswia=noswia,noswea=noswea,nostatic=nostatic,nosep=nosep,noeuv=noeuv,nospice=nospice
if np lt 2 then begin
  dprint,'number of simulated particles in each time bin must be greater than 1'
  return
endif

trange=time_double(trange)
nt=1+floor((trange[1]-binsize/2.-trange[0])/binsize) ;number of time steps
mvn_pui_aos,nt=nt,np=np,ns=ns,binsize=binsize,trange=trange,do3d=do3d ;initializes the array of structures for time series (pui) and defines intrument constants
mvn_pui_data_res ;change data resolution and load instrument pointings and put them in arrays of structures
mvn_pui_data_analyze ;analyze data: calculate ionization frequencies

ttdtsf=1. ;time to do the simulation factor
if keyword_set(do3d) then ttdtsf=2.4 ;2.4 times slower if you do3d!
simpred=ceil(10.*np*nt/1000./2880.*ttdtsf) ;simulation predicted time (s)
dprint,dlevel=2,'All data loaded successfully, the pickup ion model is now calculating...'
dprint,dlevel=2,'The simulation should take ~'+strtrim(simpred,2)+' seconds on a modern machine.'
simtime=systime(1) ;simulation start time, let's do this!
;----------------------------------------
;modeling pickup hydrogen
pui0.msub=0 ;species subscript (0=H, 1=O)
pui0.mamu[pui0.msub]=1. ; mass of [H=1 C=12 N=14 O=16] (amu)
pui0.ngps[pui0.msub]=5. ;a few gyro-periods required for pickup hydrogen
if keyword_set(exoden) then pui0.ngps[pui0.msub]=0.999 ;for exoden
mvn_pui_solver ;solve pickup ion trajectories
rtot=pui2.rtot
dprint,dlevel=2,'Pickup H+ trajectories solved, now binning...'
nfac=1. ;neutral density scale factor (scales according to seasonal change in hydrogen density)
rtot[where(rtot lt 3600e3,/null)]=3600e3 ;to ensure the radius doesn't go below the exobase
nden=mvn_pui_exoden(rtot,species='h') ;hydrogen density (cm-3)
nden*=nfac
if keyword_set(exoden) then nden=1. ;assuming n(r)=1 cm-3
dphi=mvn_pui_flux_calculator(nden)
mvn_pui_binner,dphi ;bin the results
dprint,dlevel=2,'Pickup H+ binning done.'
;-----------------------------------------
;modeling pickup oxygen
pui0.msub=1 ;species subscript (0=H, 1=O)
pui0.mamu[pui0.msub]=16.; mass of [H=1 C=12 N=14 O=16] (amu)
pui0.ngps[pui0.msub]=1. ;for SEP one full gyro-period is necessary
if keyword_set(exoden) then pui0.ngps[pui0.msub]=0.499 ;half a gyro-period is enough for SWIA/STATIC reverse model
mvn_pui_solver ;solve pickup ion trajectories
rtot=pui2.rtot
dprint,dlevel=2,'Pickup O+ trajectories solved, now binning...'
nfac=replicate(1.,np,nt) ;neutral density scale factor (scales according to radius)
nfac[where(rtot lt 6000e3,/null)]=1. ;increase in electron impact ionization rate inside the bow shock due to increased electron flux
nfac[where(rtot lt 3600e3,/null)]=0. ;no pickup source below the exobase (zero neutral density)
rtot[where(rtot lt 3600e3,/null)]=3600e3 ;to ensure the radius doesn't go below the exobase
nden=mvn_pui_exoden(rtot,species='o') ;oxygen density (cm-3)
nden*=nfac
if keyword_set(exoden) then nden=1. ;assuming n(r)=1 cm-3
dphi=mvn_pui_flux_calculator(nden)
mvn_pui_binner,dphi ;bin the results
dprint,dlevel=2,'Pickup O+ binning done.'
mvn_pui_sep_energy_response
;------------------------------------------
if ~keyword_set(exoden) then mvn_pui_tplot,/store,/tplot,savetplot=savetplot ;store the results in tplot variables and plot them
dprint,dlevel=2,'Simulation time: '+strtrim(systime(1)-simtime,2)+' seconds'

end