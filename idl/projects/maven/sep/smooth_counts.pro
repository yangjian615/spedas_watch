function smooth_counts,data,norm,smpar=smpar,nsmooth=nsmooth,delta_t=delta_t
if not keyword_set(smpar) then smpar=50.
if size(/type,data) eq 7 then begin
  names = tnames(data,n)
  printdat,names
  for i=0,n-1 do begin
     dprint,dlevel=2,'Smooth counts in: ',names[i],' length:',smpar
     get_data,names[i],data=d,dlim=dlim
     d.y = smooth_counts(d.y,d.znorm,smpar=smpar)
     store_data,names[i]+'_sm',data=d,dlim=dlim
  endfor
  return,names+'_sm'
endif


dim = size(/dimension,data)
n = dim[0]
nd = n_elements(dim)
d2 = n_elements(dim) eq 2 ? dim[1] : 1
sm_data = replicate(!values.f_nan,dim)
nsmooth = replicate(!values.f_nan,dim)
lval = data[0] > .01
nsm = 1d

for j=0l,d2-1 do begin
for i=0L , n-1 do begin
    val = data[i,j]
    if finite(val) eq 1 then begin        ;lval = data[i,j] 
       if keyword_set(norm) then lcnts= lval * norm[i,j] else lcnts = lval
       nsm = 1.d + smpar/ (lcnts > .0001)  
       lval =  (lval*(nsm-1) + val )/nsm
      sm_data[i,j] = lval
      nsmooth[i,j] = nsm
    endif ;else dprint
endfor
endfor

return,sm_data
end


;pro test_smooth_counts,seed
nsamp = 10000
rate = replicate(.01d,nsamp)
rate[3000:4000] = 10.
rate[6000:7000] = 400.
rate[7000:8000] = 4000
rate[7400:7600]= 1
rate[500:1000] = 1
rate[1500:5500]=.001
;rate[*]=.01
delt = replicate(1,nsamp)
avg  = rate * delt
cnts = randomp(avg,seed)
;cnts = float(cnts)
;cnts[6900:7100] = !values.f_nan
plot,cnts,/ylog,yrange=[.0001,10000],psym=3
oplot,avg,color=5

scnts = smooth_counts(cnts,nsmooth)
oplot,scnts,color=6
;oplot,scnts,color=5
oplot,nsmooth,color=1
oplot,avg,color=5
mm_scnts = minmax(scnts)
mm_nsmooth = minmax(nsmooth)
;printdat
printdat,average(scnts)
printdat,average(avg)
printdat,average(cnts)
print,average(scnts)/average(cnts)
end
