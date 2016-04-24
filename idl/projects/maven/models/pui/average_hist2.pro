;20160404 Ali
;this is a revised version of Davin's average_hist function
;FUNCTION average_hist2(a,x)
;returns the average of "a", binned according to "x"
;can handle 2D "a"

function average_hist2,a,x,binsize=binsize,trange=trange,centertime=centertime
  tdrange=time_double(trange)
  h=histogram(x,binsize=binsize,min=tdrange[0],max=tdrange[1]-binsize,locations=centertime,reverse=ri,/nan)
  centertime=centertime+binsize/2
  sizea=size(a,/dimen)
  if (n_elements(sizea) ne 1) then avg=replicate(1.,size(h,/dimen),sizea[1]) else avg=replicate(1.,size(h,/dimen))
  whn0 = where(h ne 0,count)
  for j=0l,count-1 do begin
    i = whn0[j]
    ind = ri[ri[i]:ri[i+1]-1]
    avg[i,*] = average(a[ind,*],1)
  endfor
  return,avg
end
