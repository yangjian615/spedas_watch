;20160404 Ali
;binning of fluxes according to energy and angular response of SEP, SWIA, STATIC
;to be called by mvn_pui_model

pro mvn_pui_binner,mamu=mamu,np=np,do3d=do3d

common mvn_pui_common

onesnp=replicate(1.,np)

sep1ldx=sep1ld[*,0]#onesnp; sep look directions
sep1ldy=sep1ld[*,1]#onesnp
sep1ldz=sep1ld[*,2]#onesnp
sep2ldx=sep2ld[*,0]#onesnp
sep2ldy=sep2ld[*,1]#onesnp
sep2ldz=sep2ld[*,2]#onesnp

swiyldx=sep1ldy*sep2ldz-sep2ldy*sep1ldz ;swia look directions
swiyldy=sep1ldz*sep2ldx-sep2ldz*sep1ldx
swiyldz=sep1ldx*sep2ldy-sep2ldx*sep1ldy
swixld=(sep1ld+sep2ld)/sqrt(2.)
swizld=(sep1ld-sep2ld)/sqrt(2.)
swixldx=swixld[*,0]#onesnp
swixldy=swixld[*,1]#onesnp
swixldz=swixld[*,2]#onesnp
swizldx=swizld[*,0]#onesnp
swizldy=swizld[*,1]#onesnp
swizldz=swizld[*,2]#onesnp

staxldx=staxld[*,0]#onesnp; static look directions
staxldy=staxld[*,1]#onesnp
staxldz=staxld[*,2]#onesnp
stazldx=stazld[*,0]#onesnp
stazldy=stazld[*,1]#onesnp
stazldz=stazld[*,2]#onesnp
stayldx=stazldy*staxldz-staxldy*stazldz
stayldy=stazldz*staxldx-staxldz*stazldx
stayldz=stazldx*staxldy-staxldx*stazldy

cosvsep1=-(sep1ldx*v3x+sep1ldy*v3y+sep1ldz*v3z)/vxyz; cosine of angle between detector FOV and pickup ion -velocity vector
cosvsep2=-(sep2ldx*v3x+sep2ldy*v3y+sep2ldz*v3z)/vxyz;
cosvswix=-(swixldx*v3x+swixldy*v3y+swixldz*v3z)/vxyz;
cosvswiy=-(swiyldx*v3x+swiyldy*v3y+swiyldz*v3z)/vxyz;
cosvswiz=-(swizldx*v3x+swizldy*v3y+swizldz*v3z)/vxyz;
cosvstax=-(staxldx*v3x+staxldy*v3y+staxldz*v3z)/vxyz;
cosvstay=-(stayldx*v3x+stayldy*v3y+stayldz*v3z)/vxyz;
cosvstaz=-(stazldx*v3x+stazldy*v3y+stazldz*v3z)/vxyz;

cosvsep1xy=cosvsep1/sqrt(cosvsep1^2+cosvswiy^2); cosine of angle b/w projected -v on sep1 xy plane and sep1 fov 
cosvsep2xy=cosvsep2/sqrt(cosvsep2^2+cosvswiy^2); cosine of angle b/w projected -v on sep2 xy plane and sep2 fov
cosvsep1xz=cosvsep1/sqrt(cosvsep1^2+cosvsep2^2); cosine of angle b/w projected -v on sep1 xz plane and sep1 fov
cosvsep2xz=cosvsep2/sqrt(cosvsep1^2+cosvsep2^2); cosine of angle b/w projected -v on sep2 xz plane and sep2 fov

phiswipm=!dtor*(360+22.50) ;swia binning parameter
phistapm=!dtor*(360+11.25) ;static binning parameter
phiswixy=!pi+atan(-cosvswiy,-cosvswix); swia phi angles: between 0 and 2pi rad
phistaxy=!pi+atan(-cosvstay,-cosvstax); static phi angles: between 0 and 2pi rad
phiswixy=phiswipm-((phiswipm-phiswixy) mod (2*!pi)); swia phi angles: between 22.5 and 360+22.5 deg
phistaxy=phistapm-((phistapm-phistaxy) mod (2*!pi)); static phi angles: between 11.25 and 360+11.25 deg

keflux1=replicate(0.,inn,srmd) ;sep1 flux binning
keflux2=replicate(0.,inn,srmd) ;sep2 flux binning
keflux=replicate(0.,inn,toteb) ;total flux binning
kefswi=replicate(0.,inn,swieb);swia flux binning
kefsta=replicate(0.,inn,staeb);static flux binning
kefswi3d=replicate(0.,inn,swieb,swina,swine);swia 3d flux binning
kefsta3d=replicate(0.,inn,staeb,swina,swine);static 3d flux binning

ke[where(~finite(ke),/null)]=1. ;in case energy is NaN due to bad inputs (eV)
ke[where(ke ge 700e3,/null)]=1. ;in case energy is too high due to bad inputs (eV)
kestep=floor(ke/1e3); %linear energy step binning (keV)
lnkestep=126-floor(alog(ke)/totdee); %log energy step ln(eV) for all flux (edges: 328 keV to 14.9 eV with 10% resolution)
lnkeswia=69-floor(alog(ke)/swidee); %log energy step ln(eV) for SWIA (post Nov 2014)
lnkestat=63-floor(alog(ke)/stadee); %log energy step ln(eV) for STATIC (only pickup mode)

nfac=replicate(1.,inn,np) ;neutral density scale factor (scales according to radius)
nfac[where(rxyz lt 6000e3,/null)]=10. ;increase in electron impact ionization rate inside the bow shock due to increased electron flux
nfac[where(rxyz lt 3600e3,/null)]=0. ;for which there is no pickup source (zero neutral density)
rxyz[where(rxyz lt 3600e3,/null)]=3600e3 ;to ensure the radius doesn't go below the exobase

ke5=ke/1e3
ke5[where(ke5 lt 5.,/null)]=5.
rfov=1.+(ke5-5.)/5.; correction factor for SWIA and STATIC reduced FOV at E>5keV

ntotfac=ntot*nfac
nrfovac=ntotfac*rfov

cosfovsep=cos(!dtor*30.) ;sep opening angle (assuming conic) needs to be improved...
sinfovswi=sin(!dtor*45./rfov) ;swia and static +Z opening angle
phifovswi=!dtor*dindgen(swina+1,increment=22.5,start=22.50) ;swia anode phi angle bins (azimuth):between 22.5 and 360+22.5 deg
phifovsta=!dtor*dindgen(swina+1,increment=22.5,start=11.25) ;static anode phi angle bins (azimuth):between 11.25 and 360+11.25 deg
thefovswi=!dtor*dindgen(swine+1,increment=22.5,start=-45.0) ;swia and static deflection theta angles (elevation):between -45 and 45 deg

cosfovsepxy=cos(!dtor*21.0) ;sep opening angle (full angular extent) in sep xy plane
cosfovsepxz=cos(!dtor*15.5) ;sep opening angle (full angular extent) in sep xz plane

sdea1xy=(cosvsep1xy-cosfovsepxy)/(1-cosfovsepxy) ;sep projected detector effective area on sep1 xy plane
sdea2xy=(cosvsep2xy-cosfovsepxy)/(1-cosfovsepxy)
sdea1xz=(cosvsep1xz-cosfovsepxz)/(1-cosfovsepxz)
sdea2xz=(cosvsep2xz-cosfovsepxz)/(1-cosfovsepxz)

sdea1=sdea1xy*sdea1xz ;sep detector effective area factor (cm2)
sdea2=sdea2xy*sdea2xz

sdea1[where(cosvsep1xy lt cosfovsepxy)]=1e-3 ;very small sep detector area within cosfovsep (cm2)
sdea2[where(cosvsep2xy lt cosfovsepxy)]=1e-3
sdea1[where(cosvsep1xz lt cosfovsepxz)]=1e-3
sdea2[where(cosvsep2xz lt cosfovsepxz)]=1e-3

for it=1,np-1 do begin ;loop over particles
  for in=0,inn-1 do begin ;loop over time
    
    ntotfacnt=ntotfac[in,it]
    nrfovacnt=nrfovac[in,it]
    kestepnt=kestep[in,it]
    lnkestepnt=lnkestep[in,it]
    lnkeswiant=lnkeswia[in,it]
    lnkestatnt=lnkestat[in,it]
    sinfovswint=sinfovswi[in,it]
    cosvswiznt=cosvswiz[in,it]
    cosvstaznt=cosvstaz[in,it]
    
    if (cosvsep1[in,it] gt cosfovsep) then keflux1[in,kestepnt]+=ntotfacnt*sdea1[in,it]; bin pickup ion fluxes that are within the FOV
    if (cosvsep2[in,it] gt cosfovsep) then keflux2[in,kestepnt]+=ntotfacnt*sdea2[in,it]
    if ((lnkestepnt ge 0) && (lnkestepnt le toteb-1)) then keflux[in,lnkestepnt]+=ntotfacnt; %total energy flux
    if ((abs(cosvswiznt) lt sinfovswint) && (lnkeswiant ge 0) && (lnkeswiant le swieb-1)) then kefswi[in,lnkeswiant]+=nrfovacnt; %energy flux
    if ((abs(cosvstaznt) lt sinfovswint) && (lnkestatnt ge 0) && (lnkestatnt le staeb-1)) then kefsta[in,lnkestatnt]+=nrfovacnt; %energy flux
    
    if keyword_set(do3d) then begin
      rfovnt=rfov[in,it]
      phiswixynt=phiswixy[in,it]
      phistaxynt=phistaxy[in,it]
      for j=0,swina-1 do begin
        for k=0,swine-1 do begin
    if ((phiswixynt gt phifovswi[j]) && (phiswixynt lt phifovswi[j+1]) && (cosvswiznt gt sin(thefovswi[k]/rfovnt)) && (cosvswiznt lt sin(thefovswi[k+1]/rfovnt)) && (lnkeswiant ge 0) && (lnkeswiant le swieb-1)) then kefswi3d[in,lnkeswiant,j,k]+=nrfovacnt; %energy flux
    if ((phistaxynt gt phifovsta[j]) && (phistaxynt lt phifovsta[j+1]) && (cosvstaznt gt sin(thefovswi[k]/rfovnt)) && (cosvstaznt lt sin(thefovswi[k+1]/rfovnt)) && (lnkestatnt ge 0) && (lnkestatnt le staeb-1)) then kefsta3d[in,lnkestatnt,j,k]+=nrfovacnt; %energy flux
        endfor
      endfor
    endif

  endfor
endfor

end