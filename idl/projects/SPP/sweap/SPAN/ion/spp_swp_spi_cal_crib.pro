pro spp_swp_spi_cal_DEF_YAW_scan,trange=trange
if ~keyword_set(trange) then trange =  ['2016-10-26/23:30:30', '2016-10-27/01:06:30']  ; YAW DEFLector scan
hkp =spp_apdat('3be'x)
hkps = hkp.array
hkps_def = hkps.dac_defl

rates = (spp_apdat('3bb'x)).array
manips = (spp_apdat('7c3'x)).array
tr=time_double(trange)
w = where(rates.time gt tr[0] and rates.time le tr[1])
rates=rates[w]

yaw = interp(float(manips.yaw_pos),manips.time,rates.time)
def = interp(float(hkps.dac_defl),hkps.time,rates.time)
flag = interp(float(hkps.mram_addr_hi),hkps.time,rates.time)

counts = rates.valid_cnts[13]
w =  where(flag ne 1,/null)
counts[ w] = !values.f_nan


plot, yaw, counts, xtitle='YAW',ytitle='Counts in 1/4 NY Second',title='Deflector Response for various Deflector DAC values',xrange=[-1,1]*80.,/xstyle,charsize=1.4;,ylog=1,yrange=[1,5000]
plots,yaw,counts,color = bytescale(def)

defvals = [-50,-45,-40,-30,-20,-10,0,10,20,30,40,45,50]*1000L
cols=bytescale(defvals)
for i=0,n_elements(defvals)-1 do begin
  w = where( (def eq defvals[i]) and finite(counts) )
  y = yaw[w]
  c= counts[w]
;  av=average_hist(y,c,std=std)
  cmax = max(c,bin)
  oplot,y,c,color=cols[i]
  xyouts,y[bin],cmax,strtrim(defvals[i],2),align=.5,charsize=1.5;,color=cols[i]
  
endfor

makepng,'spani_cnts_vs_yaw',time=trange[0]



end

pro spp_swp_spi_cal_YAW_DEF_scan,trange=trange

  if n_elements(trange) ne 2 then ctime,trange
  hkp =spp_apdat('3be'x)
  hkps = hkp.array
  hkps_def = long(hkps.DACS[5])-long(hkps.DACS[6])
  store_data,hkp.tname+'DEF', hkps.time,  hkps_def
  
  rates = (spp_apdat('3bb'x)).array
  manips = (spp_apdat('7c3'x)).array
  w = where(rates.time gt trange[0] and rates.time le trange[1])
  rates=rates[w]
  def = interp(float(hkps_def),hkps.time,rates.time)
  yaw = interp(float(hkps_def),hkps.time,rates.time)
  
  counts = rates.valid_cnts[15]
  w = where(def ne 0)
  
  plot, def[w], counts[w], xtitle='DEF1-DEF2',ytitle='Counts in 1/4 NY Second',xrange=[-1,1]*2d^16,/xstyle,charsize=1.4
  makepng,'spani_cnts_vs_def',time=trange[0]

end

pro spp_swp_spi_rot_yaw_response,trange=trange

rate =spp_apdat('3bb'x)
hkp =spp_apdat('3be'x)
manip = spp_apdat('7c3'x)

hkp.print
manip.print
rate.print
if ~keyword_set(trange) then ctime,trange

; trange = [1.4773680e+09,systime(1)+3600]

rates = rate.array
w=where(rates.time gt trange[0] and rates.time lt trange[1],/null)
rates = rates[w]

hkps = hkp.array
manips = manip.array

time_offset=2.6

anodes = interp(float(hkps.mram_addr_low),hkps.time,rates.time)
yaws = interp(manips.yaw_pos, manips.time, rates.time+time_offset)

c = bytescale(indgen(16))

plot,/nodata,yaws,total(rates.valid_cnts,1),xtitle='YAW angle (degrees)',ytitle='Counts in 1/4 NYS',charsize=1.5
for i=0,15 do  begin
  w = where(anodes eq i,/null)
  if keyword_set( w) then  oplot,yaws[w],rates[w].valid_cnts[i],col = c[i]
endfor
  
end



pro spp_swp_spi_times

message,'not to be run!'

; SpanI first cal.
trange = ['2016-10-24/05:31:00', '2016-10-24/06:38:00']  ; first rotation scan
trange = ['2016-10-24/08:01:00', '2016-10-24/10:13:00']  ; first Ion beam characterization  lin yaw
trange =  ['2016-10-24/15:03:00', '2016-10-24/17:22:00']  ; second ion beam characterization  yaw lin
trange =  ['2016-10-25/04', '2016-10-25/06:20:00']  ; third ion beam characterization  yaw lin
trange =  ['2016-10-26/4', '2016-10-26/6']    ;  DEFlector YAW scan
trange =  ['2016-10-26/23:21:30', '2016-10-27/01:06:30']  ; YAW DEFLector scan

files=spp_file_retrieve(/cal,/spani,trange=trange)

files=spp_file_retrieve(/cal,/spani,trange=systime(1))

files =spp_file_retrieve(/cal,/spani,recent=2/24.)

spp_ptp_file_read, files


spp_init_realtime,/cal,/spani,/exec,recent=.01

spp_swp_tplot,/setlim
spp_swp_tplot,'si'

spp_swp_gse_pressure_file_read  ; load chamber pressure

end