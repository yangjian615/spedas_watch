;20160404 Ali
;SEP, SWIA, STATIC binning of fluxes

pro mvn_pui_binner2,mamu=mamu,np=np

common mvn_pui_common

keflux1=replicate(0.,inn,srmd) ;sep1 flux binning
keflux2=replicate(0.,inn,srmd) ;sep2 flux binning
kenflux=replicate(0.,inn,100) ;total flux binning
kefswi=replicate(0.,inn,swieb);swia flux binning
kefsta=replicate(0.,inn,staeb);static flux binning
onesinnnp=replicate(1.,inn,np)

ke[where(~finite(ke),/null)]=1 ;in case energy is NaN due to bad inputs
kestep=floor(ke/1e3); %linear energy step binning (keV)
lnkestep=70-floor(alog(ke)/swidee); %log energy step ln(eV) for SWIA (post Nov 2014)
lnkestat=63-floor(alog(ke)/stadee); %log energy step ln(eV) for STATIC (only pickup mode)

nfac=onesinnnp ;neutral density scale factor (scales according to radius)
nfac[where(rxyz lt 6000e3,/null)]=10. ;increase in electron impact ionization rate inside the bow shock due to increased electron flux
nfac[where(rxyz lt 3600e3,/null)]=0. ;for which there is no pickup source (zero neutral density)
rxyz[where(rxyz lt 3600e3,/null)]=3600e3 ;to ensure the radius doesn't go below the exobase

ke5=ke/1e3
ke5[where(ke5 lt 5,/null)]=5.
rfov=1.+(ke5-5.)/5.; correction factor for SWIA and STATIC reduced FOV at E>5keV

cosfovsep=cos(!dtor*20.) ;sep opening angle (assuming conic) needs to be improved...
sinfovswi=sin(!dtor*45./rfov) ;swia and static +Z opening angle

fsep1=onesinnnp-1 ;fov scale factor (1. if particles are within the fov, zero otherwise) 
fsep1[where(cosvsep1 gt cosfovsep)]=1.
fsep2=onesinnnp-1
fsep2[where(cosvsep2 gt cosfovsep)]=1.

keflx1=fsep1*ntot*nfac

for it=1,np-1 do begin ;loop over particles

    kestepnt=kestep[in,it]
    lnkestepnt=lnkestep[in,it]
    lnkestatnt=lnkestat[in,it]
    sinfovswint=sinfovswi[in,it]
    
    keflux1[*,kestepnt]=keflux1[*,kestepnt]+ntot[*,it]*nfac[*,it]*fsep1[*,it]; bin pickup ion fluxes that are within the FOV
    keflux2[*,kestepnt]=keflux2[*,kestepnt]+ntot[*,it]*nfac[*,it]*fsep2[*,it];
    if ((abs(cosvswiz[in,it]) lt sinfovswint) && (lnkestepnt ge 0) && (lnkestepnt le 47)) then kefswi[in,lnkestepnt]=kefswi[in,lnkestepnt]+ntot[*,it]*nfacnt*rfovnt; %energy flux
    if ((abs(cosvstaz[in,it]) lt sinfovswint) && (lnkestatnt ge 0) && (lnkestatnt le 63)) then kefsta[in,lnkestatnt]=kefsta[in,lnkestatnt]+ntot[*,it]*nfacnt*rfovnt; %energy flux

endfor
;stop
end