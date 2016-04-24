;20160404 Ali
;SEP, SWIA, STATIC binning of fluxes

pro mvn_pui_binner,mamu=mamu,np=np

common mvn_pui_common

keflux1=replicate(0.,inn,srmd) ;sep1 flux binning
keflux2=replicate(0.,inn,srmd) ;sep2 flux binning
keflux=replicate(0.,inn,toteb) ;total flux binning
kefswi=replicate(0.,inn,swieb);swia flux binning
kefsta=replicate(0.,inn,staeb);static flux binning
onesinnnp=replicate(1.,inn,np)

ke[where(~finite(ke),/null)]=1. ;in case energy is NaN due to bad inputs (eV)
kestep=floor(ke/1e3); %linear energy step binning (keV)
lnkestep=126-floor(alog(ke)/totdee); %log energy step ln(eV) for all flux (edges: 328 keV to 14.9 eV with 10% resolution)
lnkeswia=69-floor(alog(ke)/swidee); %log energy step ln(eV) for SWIA (post Nov 2014)
lnkestat=63-floor(alog(ke)/stadee); %log energy step ln(eV) for STATIC (only pickup mode)

nfac=onesinnnp ;neutral density scale factor (scales according to radius)
nfac[where(rxyz lt 6000e3,/null)]=10. ;increase in electron impact ionization rate inside the bow shock due to increased electron flux
nfac[where(rxyz lt 3600e3,/null)]=0. ;for which there is no pickup source (zero neutral density)
rxyz[where(rxyz lt 3600e3,/null)]=3600e3 ;to ensure the radius doesn't go below the exobase

ke5=ke/1e3
ke5[where(ke5 lt 5.,/null)]=5.
rfov=1.+(ke5-5.)/5.; correction factor for SWIA and STATIC reduced FOV at E>5keV

cosfovsep=cos(!dtor*20.) ;sep opening angle (assuming conic) needs to be improved...
sinfovswi=sin(!dtor*45./rfov) ;swia and static +Z opening angle

for it=1,np-1 do begin ;loop over particles
  for in=0,inn-1 do begin ;loop over time
    
    ntotnt=ntot[in,it]
    nfacnt=nfac[in,it]
    rfovnt=rfov[in,it]
    kestepnt=kestep[in,it]
    lnkestepnt=lnkestep[in,it]
    lnkeswiant=lnkeswia[in,it]
    lnkestatnt=lnkestat[in,it]
    sinfovswint=sinfovswi[in,it]
    
    if (cosvsep1[in,it] gt cosfovsep) then keflux1[in,kestepnt]=keflux1[in,kestepnt]+ntotnt*nfacnt; bin pickup ion fluxes that are within the FOV
    if (cosvsep2[in,it] gt cosfovsep) then keflux2[in,kestepnt]=keflux2[in,kestepnt]+ntotnt*nfacnt
    if ((abs(cosvswiz[in,it]) lt sinfovswint) && (lnkeswiant ge 0) && (lnkeswiant le 47)) then kefswi[in,lnkeswiant]=kefswi[in,lnkeswiant]+ntotnt*nfacnt*rfovnt; %energy flux
    if ((abs(cosvstaz[in,it]) lt sinfovswint) && (lnkestatnt ge 0) && (lnkestatnt le 63)) then kefsta[in,lnkestatnt]=kefsta[in,lnkestatnt]+ntotnt*nfacnt*rfovnt; %energy flux
    if ((lnkestepnt ge 0) && (lnkestepnt le 99)) then keflux[in,lnkestepnt]=keflux[in,lnkestepnt]+ntotnt*nfacnt; %energy flux

  endfor
endfor

end