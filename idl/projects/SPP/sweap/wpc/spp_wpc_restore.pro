function spp_wpc_restore_file,file
   restore,/verbose,file
   strct={  $
      filename:  file,  $
      scetstart_ur8:    scetstart_ur8,  $
      dcb_cycles:       dcb_cycles,  $
      dcb_subcycles:    dcb_subcycles,  $
      times_ur8:  time_series_times_ur8,  $
      times:      time_series_times,  $
      raw:        time_series_raw  $
   }
      
   return, strct
end




function spp_wpc_restore_sample


  return, strct
end


ns = n_elements(s0.raw)
dt = 52e-5
time = dindgen(ns) * dt
!p.multi = [0,1,3]
signal = s1.raw /1.4e4
plot,time,signal,xstyle=3,xtitle='Time (ms)',ytitle='Signal Voltage (V)'
plot,time,s0.raw,xstyle=3,xtitle='Time (ms)',ytitle='Counts/bin'

nb = 256
raw =  total( reform(s0.raw,nb,ns/nb), 1) 
t   =  average( reform(time,nb,ns/nb), 1)
plot,t,raw,psym=10,xstyle=3,ystyle=3,xtitle='Time (ms)',ytitle='Counts/bin (rebinned)'


if 0 then begin
hist = histbins(s0.raw,tbins,binsize=16)
plot,hist
endif
end

