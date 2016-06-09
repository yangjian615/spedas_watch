;20160525 Ali
;manipulating pickup ion model results
;to be called by mvn_pui_model or by user
;can be used to extract exospheric neutral O densities by a reverse method

pro mvn_pui_results

common mvn_pui_common

ebinlim=14 ;energy bin limit

ctime,trange,/silent
timespan,trange
mvn_pui_model,/do3d,/nodataload,/exoden,binsize=32

nr=swiaef3d/kefswio3d/(~kefswih3d)/1e6 ;exospheric neutral density (cm-3)
rr=(sqrt(krxswio3d^2+kryswio3d^2+krzswio3d^2))/knnswio3d/1e3 ;radial distance (km)

nre=nr[*,0:ebinlim,*,*] ;limited in high energies
rre=rr[*,0:ebinlim,*,*]
nref=nre(where(finite(nre) and nre)) ;only finite densities
rref=rre(where(finite(nre) and nre))

nrcounter=replicate(0.,100) ;binning counter
nrlogbin1=replicate(0.,100) ;ln densities binned
nrlogbin2=replicate(0.,100) ;ln square densities binned

sizenref=size(nref)
for i=0,sizenref[-1]-1 do begin
  rrstep=floor(rref[i]/2e3) ;radial distance step (2000 km)
  nrcounter[rrstep]+=1
  nrlogbin1[rrstep]+=alog(nref[i])
  nrlogbin2[rrstep]+=(alog(nref[i]))^2
endfor

rravg=(.5+dindgen(100))*2000 ;radial distance steps (2000 km)
nravg=nrlogbin1/nrcounter
nrstd=sqrt((nrlogbin2*nrcounter-nrlogbin1^2)/(nrcounter-1))/nrcounter ;standard error
nrasb=nravg-2*nrstd ;two standard errors below average
nrasa=nravg+2*nrstd ;two standard errors above average

w=getwindows(/current)
if keyword_set(w) then w.erase
p1=plot(nref,rref,/xlog,xtitle='Neutral Density (cm-3)',ytitle='Radial Distance (km)',symbol='.',linestyle='',/current)
p2=plot(exp(nravg),rravg,symbol='o',/overplot)
p3=plot(exp(nrasb),rravg,color='blue',/overplot)
p4=plot(exp(nrasa),rravg,color='red',/overplot)

end
