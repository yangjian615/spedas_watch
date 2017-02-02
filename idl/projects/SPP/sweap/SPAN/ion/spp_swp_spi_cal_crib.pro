PRO spp_swp_spi_parameters, vals

   ;; DAC to Voltage (DVM from HV Calibration Test)

   ;; Hemisphere 
   hemi_dacs = ['0000'x,'0040'x,'0080'x,'00C0'x,'0100'x,$
                '0280'x,'0500'x,'0800'x,'0C00'x,'1000'x]
   hemi_volt = [0.006,-3.903,-7.8,-11.7,-15.61,$
                -39.04,-78.1,-125,-187.5,-250]

   ;; Deflector 1
   def1_dacs = ['0000'x,'0080'x,'0100'x,'0180'x,'0300'x,$
                '0700'x,'0D00'x,'1300'x,'1C80'x,'2600'x]

   def1_volt = [0.0016,-3.15,-6.31,-9.48,-18.98,-44.3,$
                -82.3,-120.3,-180.5,-240.6]

   ;; Deflector 2
   def2_dacs = ['0000'x,'0080'x,'0100'x,'0180'x,'0300'x,$
                '0700'x,'0D00'x,'1300'x,'1C80'x,'2600'x]

   def2_volt = [0.0016,-3.15,-6.31,-9.48,-18.98,-44.3,$
                -82.3,-120.3,-180.5,-240.6]

   ;; Spoiler 
   splr_dacs = ['0000'x,'0100'x,'0200'x,'0400'x,'1000'x,'4000'x]
   splr_volt = [0.0003,-0.31,-0.62,-1.243,-4.974,-19.9]


   hemi_fitt = linfit(hemi_dacs,hemi_volt)
   def1_fitt = linfit(def1_dacs,def1_volt)
   def2_fitt = linfit(def2_dacs,def2_volt)
   splr_fitt = linfit(splr_dacs,splr_volt)


   vals = {$

          hemi_dacs:hemi_dacs,$
          def1_dacs:def1_dacs,$
          def2_dacs:def2_dacs,$
          splr_dacs:splr_dacs,$
          
          hemi_volt:hemi_volt,$
          def1_volt:def1_volt,$
          def2_volt:def2_volt,$
          splr_volt:splr_volt,$

          hemi_fitt:hemi_fitt,$
          def1_fitt:def1_fitt,$
          def2_fitt:def2_fitt,$
          splr_fitt:splr_fitt $
          
          }
   

END



pro spp_swp_spi_cal_DEF_YAW_scan,trange=trange


   if ~keyword_set(trange) then $
    ;; YAW DEFLector scan
    trange =  ['2016-10-26/23:30:30', '2016-10-27/01:06:30'] 

   hkp      = spp_apdat('3be'x)
   hkps     = hkp.array
   hkps_def = hkps.dac_defl
   
   rates  = (spp_apdat('3bb'x)).array
   manips = (spp_apdat('7c3'x)).array

   tr=time_double(trange)
   w = where(rates.time gt tr[0] and rates.time le tr[1])
   rates=rates[w]
   
   yaw  = interp(float(manips.yaw_pos),   manips.time,rates.time)
   def  = interp(float(hkps.dac_defl),    hkps.time,  rates.time)
   flag = interp(float(hkps.mram_addr_hi),hkps.time,  rates.time)
   
   counts = rates.valid_cnts[13]
   w =  where(flag ne 1,/null)
   counts[ w] = !values.f_nan
   plot, yaw, counts, xtitle='YAW',$
         ytitle='Counts in 1/4 NY Second',$
         title='Deflector Response for various Deflector DAC values',$
         xrange=[-1,1]*80.,/xstyle,charsize=1.4 ;,ylog=1,yrange=[1,5000]
   plots,yaw,counts,color = bytescale(def)
   defvals = [-50,-45,-40,-30,-20,-10,0,10,20,30,40,45,50]*1000L
   cols=bytescale(defvals)
   for i=0,n_elements(defvals)-1 do begin
      w = where( (def eq defvals[i]) and finite(counts) )
      y = yaw[w]
      c= counts[w]
      ;av=average_hist(y,c,std=std)
      cmax = max(c,bin)
      oplot,y,c,color=cols[i]
      xyouts,y[bin],cmax,strtrim(defvals[i],2),$
             align=.5,charsize=1.5 ;,color=cols[i]
      
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
  
  plot, def[w], counts[w], xtitle='DEF1-DEF2',$
        ytitle='Counts in 1/4 NY Second',$
        xrange=[-1,1]*2d^16,/xstyle,charsize=1.4
  makepng,'spani_cnts_vs_def',time=trange[0]

end










PRO spp_swp_spi_thresh_scan, trange=trange


   ;; Setup
   loadct2, 34
   npoints = 200

   ;; --- Check keyword
   IF ~keyword_set(trange) THEN $
    stop, 'Error: Need trange.'

   ;; --- Get data
   rates  = (spp_apdat('3bb'x)).array
   manips = (spp_apdat('7c3'x)).array
   hkps   = (spp_apdat('3be'x)).array
   mons   = (spp_apdat('753'x)).array

   ;; --- Find time interval
   htime   = hkps.time
   rtime   = rates.time
   mtime   = mons.time
   rtt = where(rtime GE trange[0] AND $
               rtime LE trange[1],rcc)
   htt = where(htime GE trange[0] AND $
               htime LE trange[1],hcc)
   mtt = where(mtime GE trange[0] AND $
               mtime LE trange[1],mcc)
   IF rcc EQ 0  OR hcc EQ 0 OR mcc EQ 0 THEN $
    stop, 'Error: Time interval not loaded.'
   rates = temporary(rates[rtt])
   rtime = temporary(rtime[rtt])
   hkps  = temporary(hkps[htt])
   htime = temporary(htime[htt])
   mons  = temporary(mons[mtt])
   mtime = temporary(mtime[mtt])

   ;; --- Plot
   popen, '~/Desktop/ch10_thresh_scan',/landscape
   plot, [0,1],[0,1],$
         xr=[10,60],   xs=1,xlog=1,xtitle='Threshold',$
         yr=[1e1,1e4],ys=1,ylog=1,ytitle='Binned and Average Counts',$
         Title='Channel 10 Threshold Scan',/nodata,thick=2

   ;; --- Define variables and interpolate to rates
   addr_hi = hkps.MRAM_ADDR_HI  AND '1F'x
   addr_lo = hkps.MRAM_ADDR_LOW AND 'FFFF'x
   anode   = round(interp(addr_hi,htime,rtime))
   thresh  = round(interp(addr_lo,htime,rtime)) AND '1FF'x
   mcp_dac = round(interp(reform(hkps.DACS[0,*]),htime,rtime))
   mcp_vvv =       interp(hkps.MON_MCP_V,htime,rtime)
   mcp_ccc =       interp(hkps.MON_MCP_C,htime,rtime)
   fill    = round(interp(mons.P6I*100.,mtime,rtime))

   ;; --- Find autozero
   autozero = ishft(addr_lo,-9) and  '11'b
   autozero =  round(interp(autozero,htime,rtime))

   ;; --- Find unique values for MCP, Anode, and Autozero
   un_auz = autozero[uniq(autozero,sort(autozero))]
   un_ano = anode[uniq(anode,sort(anode))]
   un_mcp = mcp_dac[uniq(mcp_dac,sort(mcp_dac))]
   un_fil = fill[uniq(fill,sort(fill))]
   nn_auz = n_elements(un_auz)
   nn_ano = n_elements(un_ano)
   nn_mcp = n_elements(un_mcp)
   nn_fil = n_elements(un_fil)

   ;; --- Structure
   thresh_data  = ptrarr(nn_fil,nn_mcp,nn_auz,nn_ano,/alloc)

   ;; --- Loop through unique MCPs, Anodes, and Autozeros


   ;; Filament Current
   FOR fil=0, nn_fil-1 DO BEGIN
      fil_val = un_fil[fil]

      ;; MCPs
      FOR mcp=0, nn_mcp-1 DO BEGIN
         mcp_val = un_mcp[mcp]

         ;; Autozero
         FOR auz=1, 1 DO BEGIN  ;nn_auz-1 DO BEGIN
            auz_val = un_auz[auz]

            ;; Anode
            FOR ano=0, nn_ano-1 DO BEGIN 
               ano_val = un_ano[ano]

               ;; Find values that match all unique values
               good = (anode    EQ ano_val) AND $
                      (mcp_dac  EQ mcp_val) AND $
                      (autozero EQ auz_val) AND $
                      (fill     EQ fil_val) AND $
                      (thresh   NE 0)
               pp = where(good EQ 1,cc)
               IF cc GT npoints THEN BEGIN

                  IF ano_val LT '10'x THEN BEGIN
                     ;; ---------------- STARTS ------------------
                     ;; Setup counts
                     cnts = reform(rates[pp].STARTS_CNTS[ano_val])
                     ;; Bin according to threshold
                     cntsavg = average_hist(cnts,fix(thresh[pp]),$
                                            binsize=1,$
                                            xbins=cntsavg_bins)
                     ;; Derivative of threshold scan
                     dthavg = -deriv(cntsavg_bins,cntsavg)
                     ;; Exclude counts above 1e4
                     pp = where(cntsavg LT 1e4,cc)
                     IF cc NE 0 THEN BEGIN
                        cntsavg = temporary(cntsavg[pp])
                        cntsavg_bins = temporary(cntsavg_bins[pp])
                        dthavg  = temporary(dthavg[pp])
                     ENDIF
                  ENDIF ELSE BEGIN 
                     ;; ----------------- STOPS ------------------
                     ;; Setup counts
                     cnts = reform(rates[pp].STOPS_CNTS[ano_val-16])
                     ;; Bin according to threshold
                     cntsavg = average_hist(cnts,fix(thresh[pp]),$
                                            binsize=1,$
                                            xbins=cntsavg_bins)
                     ;; Derivative of threshold scan
                     dthavg = -deriv(cntsavg_bins,cntsavg)
                     ;; Exclude counts above 1e4
                     pp = where(cntsavg LT 1e4,cc)
                     IF cc NE 0 THEN BEGIN
                        cntsavg = temporary(cntsavg[pp])
                        cntsavg_bins = temporary(cntsavg_bins[pp])
                        dthavg  = temporary(dthavg[pp])
                     ENDIF
                  ENDELSE

                  ;; Save data in structure
                  *(thresh_data[fil,mcp,auz,ano]) = $                
                   {az:           auz_val,$
                    mcp:          mcp_val,$
                    anode:        ano_val,$
                    fillament:    fil_val,$
                    ;mcp_v:        mcp_v,$
                    cnts:         cnts,$
                    thresh:       thresh,$
                    dthavg:       dthavg,$
                    cntsavg:      cntsavg,$
                    cntsavg_bins: cntsavg_bins}                     
               ENDIF
            ENDFOR
         ENDFOR
      ENDFOR
   ENDFOR

   pp=0
   FOR i=0, nn_fil*nn_mcp*nn_auz*nn_ano-1 DO $
    IF *(thresh_data)[i] NE !NULL THEN BEGIN
      pp = [pp.i]
      cc++
   ENDIF
   pp=[1,cc-1]

   data = reform(thresh_data[pp],n_fil,nn_mcp,nn_auz,nn_ano)
   ;spp_swp_spi_thresh_scan_plot,thresh_data
   stop
END






PRO spp_swp_spi_thresh_scan_plot, data

   IF ~keyword_set(data) THEN stop, 'Must provide data.'

   ;; --- Plot
   popen, '~/Desktop/ch10_thresh_scan',/landscape
   plot, [0,1],[0,1],$
         xr=[10,60],   xs=1,xlog=1,xtitle='Threshold',$
         yr=[1e1,1e4],ys=1,ylog=1,ytitle='Binned and Average Counts',$
         Title='Channel 10 Threshold Scan',/nodata,thick=2

   ;; Color and Plot
   clr = round((ano_val-16)/16*250+70)
   oplot, cntsavg_bins, cntsavg, color=clr, thick=3,psym=-2

   ;; Color and Plot
   clr = round(ano_val/16.*250.)
   oplot, cntsavg_bins, cntsavg, color=clr, thick=3,psym=-1

   pclose


END






PRO spp_swp_spi_yaw_scan_response, trange=trange

   ;; --- Constants
   time_offset=2.6
   anode = 'a'x

   ;; --- Get data
   rates  = (spp_apdat('3bb'x)).array
   manips = (spp_apdat('7c3'x)).array

   ;; --- Find correct times
   w=where(rates.time gt trange[0] and $
           rates.time lt trange[1],/null)

   ;; --- Filter times
   rates = temporary(rates[w])

   ;; --- Setup coordiantes and fit
   yaws  = interp(manips.yaw_pos,manips.time,rates.time+time_offset)
   model = gaussfit(yaws, rates.valid_cnts[anode], aa,nterms=3)

   popen, 'spani_yaw_scan',/landscape
   plot,  yaws, rates.valid_cnts[anode],$
          thick=1.2, charthick=1.2, charsize=1.2,$
          xtitle='Yaw [degrees]',$
          ytitle='Counts per 0.218 s'
   oplot, yaws, model, color=50, thick=3
   oplot, [aa[1],aa[1]],[0.1,1e4],linestyle=2, thick=3
   pclose
   stop

END



pro spp_swp_spi_rot_linyaw_response,trange=trange, verbose=verbose

   ;; --- Constants
   time_offset=2.6
   anode = 'a'x

   ;; --- Get data
   rates  = (spp_apdat('3bb'x)).array
   hkps   = (spp_apdat('3be'x)).array
   manips = (spp_apdat('7c3'x)).array

   ;; --- Verbose
   IF keyword_set(verbose) THEN BEGIN
      hkp.print
      manip.print
      rate.print
   ENDIF

   ;; --- Get times if necessary
   if ~keyword_set(trange) then ctime,trange

   ;; --- Find correct times
   w=where(rates.time gt trange[0] and $
           rates.time lt trange[1],/null)

   ;; --- Filter times
   rates = temporary(rates[w])

   ;; --- Interpolate variables relative to rates time
   ;anodes = interp(float(hkps.mram_addr_low),hkps.time,rates.time)
   yaws   = round(interp(manips.yaw_pos,manips.time,rates.time+time_offset))
   lins   = interp(manips.lin_pos,manips.time,rates.time+time_offset)
   c      = bytescale(indgen(20))


   ;; --- Sum and fit
   hh  = histogram(lins,binsize=0.01,reverse_indices=ri,loc=arrloc)
   arr = fltarr(n_elements(hh)) 
   FOR j=0l, n_elements(hh)-1 DO IF ri[j+1] GT ri[j] THEN $
    arr[j] = total(rates[ri[ri[j]:ri[j+1]-1]].valid_cnts[anode])
   model = gaussfit(arrloc, arr, aa,nterms=3)


   ;; ------------ PLOTTING --------------------
   popen, '~/Desktop/spani_gun_map', /landscape
   plot,/nodata,yaws,total(rates.valid_cnts,1),$
        xtitle='Linear [cm]',$
        ytitle='Counts in 1/4 NYS (0.218 s)',$
        charsize=1.5
   ;anodes = replicate(10,n_elements(anodes))
   ;FOR i=0,15 DO BEGIN
   FOR j=-10, 10 DO BEGIN
      w = where(yaws EQ j,/null)
      if keyword_set(w) then BEGIN
         oplot,lins[w],rates[w].valid_cnts[anode],col = c[j]
         xyouts, -8, 1000*(j+10)/20+500, 'Yaw '+string(j),$
                 col=c[j],charsize=2,charthick=2
      ENDIF
   ENDFOR
   oplot, [aa[1],aa[1]], [0.1, 1e4], thick=2, linestyle= 2
   pclose

   stop


END














pro spp_swp_spi_rot_scan,trange=trange

   ;; Error Check 1
   IF size(trange,/type) EQ 7 THEN trange = time_double(temporary(trange))


   ;; Get Data
   rate   = (spp_apdat('3bb'x)).array
   hkp    = (spp_apdat('3be'x)).array
   manip  = (spp_apdat('7c3'x)).array
   events = (spp_apdat('3b9'x)).array

   ;; Error Check 2
   IF ~keyword_set(trange) THEN stop, 'Must set trange=trange as parameter.'

   ;; Find Times
   r_good = where(rate.time   GE trange[0] AND rate.time   LE trange[1],r_cc)
   h_good = where(hkp.time    GE trange[0] AND hkp.time    LE trange[1],h_cc)
   m_good = where(manip.time  GE trange[0] AND manip.time  LE trange[1],m_cc)
   e_good = where(events.time GE trange[0] AND events.time LE trange[1],e_cc)

   ;; Error Check 3
   IF r_cc EQ 0 OR h_cc EQ 0 OR m_cc EQ 0 OR e_cc EQ 0 THEN stop, 'No time sample.'

   ;; Interpolate to packets with highest rates (usually rates)
   starts       = rate[r_good].STARTS_CNTS
   start_nostop = rate[r_good].START_NOSTOP_CNTS
   stops        = rate[r_good].STOPS_CNTS
   stop_nostart = rate[r_good].STOP_NOSTART_CNTS
   valids       = rate[r_good].VALID_CNTS
   rtime        = rate[r_good].time

   rot    = interp(manip[m_good].rot_pos,manip[m_good].time, rtime)
   yaw    = interp(manip[m_good].yaw_pos,manip[m_good].time, rtime)
   lin    = interp(manip[m_good].lin_pos,manip[m_good].time, rtime)

   mcp_c = interp(hkp[h_good].MON_MCP_C,hkp[h_good].time,rtime)
   mcp_v = interp(hkp[h_good].MON_MCP_V,hkp[h_good].time,rtime)
   acc_c = interp(hkp[h_good].MON_ACC_C,hkp[h_good].time,rtime)
   acc_v = interp(hkp[h_good].MON_ACC_V,hkp[h_good].time,rtime)

   ;; Fit each distribution to 
   coeffs_str   = dblarr(3,16)
   coeffs_stp   = dblarr(3,16)
   coeffs_val   = dblarr(3,16)
   coeffs_tmp11   = dblarr(3,16)
   coeffs_tmp12   = dblarr(3,16)
   rot_str_cntr = dblarr(16)
   rot_stp_cntr = dblarr(16)
   rot_val_cntr = dblarr(16)

   FOR i=0,15 DO BEGIN
      tmp1 = gaussfit(rtime,reform(starts[i,*]),a1,nterms=3)
      tmp2 = gaussfit(rtime,reform(stops[i,*]), a2,nterms=3)
      tmp3 = gaussfit(rtime,reform(valids[i,*]),a3,nterms=3)

      coeffs_str[*,i] = a1
      coeffs_stp[*,i] = a2
      coeffs_val[*,i] = a3

      ;; Neighbouring Peaks
      ;mm   = where(tmp1 EQ (max(tmp1))[0])
      ;tmp11 = gaussfit(rtime[mm:*],((reform(starts[i,*])-tmp1)>0)[mm:*],coeffs_tmp11[*,i],nterms=3)
      ;tmp12 = gaussfit(rtime[0:mm],((reform(starts[i,*])-tmp1)>0)[0:mm],coeffs_tmp12[*,i],nterms=3)

      rot_str_cntr[i] = rot[where(tmp1 EQ (max(tmp1))[0])]
      rot_stp_cntr[i] = rot[where(tmp2 EQ (max(tmp2))[0])]
      rot_val_cntr[i] = rot[where(tmp3 EQ (max(tmp3))[0])]
   ENDFOR
   
   ;; Fit center values
   xx = [findgen(10)/2,indgen(6)+5]
   stp_fit = linfit(xx,rot_stp_cntr)
   str_fit = linfit(xx,rot_str_cntr)
   val_fit = linfit(xx,rot_val_cntr)


   ;; Sort events
   channel = events[e_good].channel 
   tof     = events[e_good].tof 
   etime   = events[e_good].time

   ;; Cycle through each anode
   thrsh=100
   indloc = fltarr(2,16)
   FOR i=0, 15 DO BEGIN

      pp = where(valids[i,*] GT 400,cc)
      tt = minmax(rtime[pp])
      ind = where(channel EQ i,cc)
      IF cc GT thrsh THEN BEGIN

         ;; Find peak counts
         ;; 80-120
         IF i EQ 0 THEN BEGIN
            pp      = where(etime[ind] GT tt[0] AND etime[ind] LT tt[1])
            tof_bin = histogram(tof[ind[pp]],loc=loc) 
            tof_bin = float(tof_bin)/max(tof_bin)
            xloc    = loc
            ;xind    = n_elements(loc)
            indloc[*,i] = [0,n_elements(loc)-1]
            pp      = where(loc GT 80 AND loc LT 110) ;; Hydrogen Peak
            param   = gaussfit(loc[pp],tof_bin[pp],a1,nterms=3)
            param   = a1
         ENDIF ELSE BEGIN 
            pp      = where(etime[ind] GT tt[0] AND etime[ind] LT tt[1])
            tmp = histogram(tof[ind[pp]],loc=loc)
            tmp = float(tmp) / max(tmp)
            tof_bin = [tof_bin, tmp]
            xloc = [xloc,loc]
            indloc[*,i] = [indloc[1,i-1]+1,n_elements(loc)+indloc[1,i-1]]
            ;xind = [xind,n_elements(loc)]
            pp      = where(loc GT 80 AND loc LT 110) ;; Hydrogen Peak
            par_tmp = gaussfit(loc[pp],tmp[pp],a1,nterms=3)
            param = [[param],[a1]]
         ENDELSE
      ENDIF

      ;; Number of corrective bins to be added to each tof channel.
      tof_corr = round(max(param[1,*]) - reform(param[1,*]))

   ENDFOR

   ;; PLOTTING
   ;!p.multi = [0,0,2]
   ns = 0.101725 ;* 1e-9
   popen, 'adjusted_normalized_tof',/landscape
   plot, [0,1],[0,1],$
         xr=[50,2048]*ns, /xlog, xs=1,$
         yr=[1e-4,1],     /ylog, ys=1,$
         /nodata,xtitle='[ns]',ytitle='Normalized Counts'
   FOR i=0, 15 DO BEGIN
      xx = xloc[indloc[0,i]:indloc[1,i]-1]; + tof_corr[i]
      yy = tof_bin[indloc[0,i]:indloc[1,i]-1]
      ;IF tof_corr[i] NE 0 THEN BEGIN
      ;   xx = xx+tof_corr[i]
      ;ENDIF
      oplot, xx*ns, yy, col=i/15.*250.
   ENDFOR
   pclose

   stop

END












PRO spp_swp_spi_k_sweep, trange=trange


   ;; Get Sweep DACs
   spp_swp_spi_tables, tables,config='01'x

   ;; Get SPAN-Ai HV DAC to Volts
   spp_swp_spi_parameters, vals 

   ;; Setup
   loadct2, 34
   npoints = 200

   ;; --- Check keyword
   IF ~keyword_set(trange) THEN $
    stop, 'Error: Need trange.'

   ;; --- Get data
   rates  = (spp_apdat('3bb'x)).array
   ;manips = (spp_apdat('7c3'x)).array
   hkps   = (spp_apdat('3be'x)).array
   mons   = (spp_apdat('761'x)).array
   f_p0m0 = (spp_apdat('398'x)).array
   t_p0m0 = (spp_apdat('3a4'x)).array

   ;; --- Find time interval
   htime   = hkps.time
   rtime   = rates.time
   mtime   = mons.time
   ftime   = f_p0m0.time
   ttime   = t_p0m0.time

   rtt = where(rtime GE trange[0] AND $
               rtime LE trange[1],rcc)
   htt = where(htime GE trange[0] AND $
               htime LE trange[1],hcc)
   mtt = where(mtime GE trange[0] AND $
               mtime LE trange[1],mcc)
   ftt = where(ftime GE trange[0] AND $
               ftime LE trange[1],fcc)
   ttt = where(ttime GE trange[0] AND $
               ttime LE trange[1],tcc)


   IF rcc EQ 0  OR hcc EQ 0 OR mcc EQ 0 THEN $
    stop, 'Error: Time interval not loaded.'

   rates  = temporary(rates[rtt])
   rtime  = temporary(rtime[rtt])
   hkps   = temporary(hkps[htt])
   htime  = temporary(htime[htt])
   mons   = temporary(mons[mtt])
   mtime  = temporary(mtime[mtt])
   f_p0m0 = temporary(f_p0m0[ftt])
   t_p0m0 = temporary(t_p0m0[ttt])
   ftime  = temporary(ftime[ftt])
   ttime  = temporary(ttime[ttt])
   
   ;; --- Plot
   ;popen, '~/Desktop/ch10_thresh_scan',/landscape
   ;plot, [0,1],[0,1],$
   ;      xr=[10,60],   xs=1,xlog=1,xtitle='Threshold',$
   ;      yr=[1e1,1e4],ys=1,ylog=1,ytitle='Binned and Average Counts',$
   ;      Title='Channel 10 Threshold Scan',/nodata,thick=2

   ;; --- Define variables and interpolate to rates
   addr_hi   = hkps.MRAM_ADDR_HI  AND '1F'x
   igun_volt = mons.volts
   anode     = round(interp(addr_hi,htime,rtime))
   igun      = round(interp(igun_volt,mtime,rtime))
   ;mcp_dac = round(interp(reform(hkps.DACS[0,*]),htime,rtime))
   nrgs = intarr(32,rcc)
   FOR i=0,31 DO nrgs[i,*] = interpol(f_p0m0.NRG_SPEC[i],ftime,rtime)


   ;; Cycle through all 16 anodes
   center = fltarr(16,32)
   FOR i=0, 15 DO BEGIN
      
      pp = where(anode EQ i,cc)
      str = rates[pp].STARTS_CNTS[i]
      stp = rates[pp].STOPS_CNTS[i]
      val = rates[pp].VALID_CNTS[i]
      volts = igun[pp]
      nrg  = nrgs[*,pp]

      IF cc GT 100 THEN BEGIN
         maxx = max(nrg,loc,dim=1)
         locc = array_indices(nrg,loc)
         FOR j=0, 31 DO BEGIN
            ;; Only Energy bins with max counts
            pp=where(locc[0,*] EQ j)
            nrg2 = nrg[locc[0,pp],locc[1,pp]]
            IF max(nrg2) GT 10 THEN BEGIN
               ;plot, volts[pp],nrg2,title=string(total(nrg2))+' '+ string(j)+' '+string(i)
               tmp = gaussfit(volts[pp],nrg2,a1,nterms=3)
               center[i,j] = a1[1]
               ;oplot, volts[pp], tmp, color=50
            ENDIF
         ENDFOR
      ENDIF
   ENDFOR
   plot, indgen(32), reform(center[0,*]), psym=-1
   FOR i=1., 15 DO oplot, indgen(32),reform(center[i,*]),color=i/16*250.,psym=-1
   tmp = reform((transpose(reform(tables.sweepv_dac[tables.fsindex[indgen(256)*4]],8,32)))[*,0])
   ;; DAC to Hemisphere Volts
   hemi_voltage = vals.hemi_fitt[0]+vals.hemi_fitt[1]*tmp
   ;; Go through anode by anode and find k factor
   kval = fltarr(16)
   FOR i=0, 15 DO BEGIN
      cntr = reform(center[i,*])
      pp = where(cntr GT 0,cc)
      IF cc LT 3 THEN stop
      cntr1 = cntr[pp]
      hv = hemi_voltage[pp]
      tmp = total(sqrt((ABS(hv)*14-cntr1)^2))
      FOR j=15., 20., 0.001 DO BEGIN
         
         tmp2 = total(sqrt((ABS(hv)*j-cntr1)^2))
         IF tmp2 gt tmp THEN BEGIN
            kval[i] = j         
            plot, cntr1
            oplot, abs(hv)*j,color=50
            BREAK
         ENDIF
         tmp = tmp2
      ENDFOR
      kval[i] = j
      print, 'KVAL', j
   ENDFOR
   stop
END






PRO spp_swp_spi_plot_tof, trange=trange, $
                          anode=anode,   $
                          normalized=normalized


   ;; Setup
   loadct2, 34

   ;; --- Check keyword
   IF ~keyword_set(trange) THEN BEGIN
      print, 'Error: Need trange.'
      ctime, trange
   ENDIF

   
   IF ~keyword_set(anode) THEN $
    anode = indgen(16)
   nn_anode = n_elements(anode)

   ;; --- Get data
   events  = (spp_apdat('3b9'x)).array
   ;rates  = (spp_apdat('3bb'x)).array
   ;manips = (spp_apdat('7c3'x)).array
   ;hkps   = (spp_apdat('3be'x)).array
   ;mons   = (spp_apdat('761'x)).array
   ;f_p0m0 = (spp_apdat('398'x)).array
   ;t_p0m0 = (spp_apdat('3a4'x)).array


   ;; --- Find time interval
   etime   = events.time
   ;htime   = hkps.time
   ;rtime   = rates.time
   ;mtime   = mons.time
   ;ftime   = f_p0m0.time
   ;ttime   = t_p0m0.time

   e_good = where(events.time GE trange[0] AND $
                  events.time LE trange[1],e_cc)

   ;rtt = where(rtime GE trange[0] AND $
   ;            rtime LE trange[1],rcc)
   ;htt = where(htime GE trange[0] AND $
   ;            htime LE trange[1],hcc)
   ;mtt = where(mtime GE trange[0] AND $
   ;            mtime LE trange[1],mcc)
   ;ftt = where(ftime GE trange[0] AND $
   ;            ftime LE trange[1],fcc)
   ;ttt = where(ttime GE trange[0] AND $
   ;            ttime LE trange[1],tcc)
   
   ;; Histograms
   hh = fltarr(nn_anode,2048)
   FOR i=0, nn_anode-1 DO BEGIN
      hh[i,*] = histogram(events[e_good].tof,min=0,max=2047,binsize=1)
      IF keyword_set(normalized) THEN hh[i,*] = hh[i,*]/max(hh[i,*])
   ENDFOR

   ;; Plot
   title = time_string(trange[0])+' '+$
           time_string(trange[1])
   title = title+' Anodes: '
   FOR i=0, nn_anode-1 DO $
    title = title + ' ' + string(anode[i], format='(I2)') 
   IF keyword_set(normzlied) THEN BEGIN
      ytitle = 'Normalized Counts'
      yrange = [1e-4,1]
   ENDIF ELSE BEGIN 
      ytitle = 'Counts per 1/4 NYS'
      yrange = [1,max(hh)*1.1]
   ENDELSE
   
   xx = indgen(2048)*0.101725
   xtitle = 'ns'
   xrange = [5,max(xx)]
   xlog = 1
   ylog = 1

   plot, [1,1],[1,1],/nodata,$
         ystyle=1,ytitle=ytitle,yrange=yrange,ylog=ylog,$
         xstyle=1,xtitle=xtitle,xrange=xrange,xlog=xlog,$
         title = title
   
   FOR i=0, nn_anode-1 DO $
    oplot, xx, hh[i,*], color=i/16.*250. 

END








PRO spp_swp_spi_times

   message,'not to be run!'



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; SPAN-Ai 0th Calibration   ;;;
;;;       2016-XX-XX          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ;;; ASK DAVIN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; SPAN-Ai 1st Calibration   ;;;
;;;       2016-10-24          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ;; First Rotation Scan
   trange = ['2016-10-24/05:31:00', '2016-10-24/06:38:00']  
   
   ;; First  Ion Beam Characterization LIN-YAW
   trange = ['2016-10-24/08:01:00', '2016-10-24/10:13:00']  
   
   ;; Second Ion Beam Characterization YAW-LIN
   trange = ['2016-10-24/15:03:00', '2016-10-24/17:22:00']  
   
   ;; Third  Ion Beam Characterization YAW-LIN
   trange = ['2016-10-25/04:00:00', '2016-10-25/06:20:00']  
   
   ;; Deflector-YAW scan
   trange = ['2016-10-26/04:00:00', '2016-10-26/06:00:00']    
   
   ;; YAW-Deflector scan
   trange = ['2016-10-26/23:21:30', '2016-10-27/01:06:30']  
   


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; SPAN-Ai 2nd Calibration    ;;;
;;;         SNOUT2             ;;;
;;;       2016-12-03           ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ;; THRESHOLD SCANS

   ;; START 0- STOP 0  - MCP 0xd400, 0xd800, 0xdC00, 0xe000
   trange=['2016-12-04/01:58:00','2016-12-04/02:30:00']
   ;; Channel 0- MCP 0xd000
   trange=['2016-12-04/02:30:00','2016-12-04/02:40:00']
   ;; STOP 1 - MCP 0xd400, 0xd800, 0xdC00, 0xe000- 
   trange=['2016-12-04/02:44:00','2016-12-04/03:04:00']
   ;; Channel 1- MCP 0xd000 
   trange=['2016-12-04/03:04:00','2016-12-04/03:15:00']
   ;; START 2- STOP 2  - MCP 0xd400, 0xd800, 0xdC00, 0xe000
   trange=['2016-12-04/03:15:00','2016-12-04/03:52:00']
   ;; Channel 2 - MCP 0xd000
   ;; NEED MORE INTEGRATION TIME
   ;; STOP 3 - MCP 0xd400, 0xd800, 0xdC00, 0xe000- 
   trange=['2016-12-04/03:52:00','2016-12-04/04:10:00']
   ;; Channel 3- MCP 0xd000
   ;; NEED MORE INTEGRATION TIME
   ;; START 4- STOP 4  - MCP 0xd400, 0xd800, 0xdC00, 0xe000
   trange=['2016-12-04/05:01:00','2016-12-05/05:38:00']
   ;; Channel 4- MCP 0xd000
   ;; NEED MORE INTEGRATION TIME
   ;; STOP 5  - MCP 0xd400, 0xd800, 0xdC00, 0xe000 - 
   trange=['2016-12-04/05:38:00','2016-12-04/05:58:00']
   ;; Channel 5- MCP 0xd000
   trange=['2016-12-04/05:58:00','2016-12-04/06:06:00']
   ;; START 6  - STOP 6  - MCP 0xd400, 0xd800, 0xdC00, 0xe000
   trange=['2016-12-04/06:12:00','2016-12-04/06:46:00']
   ;; Channel 6- MCP 0xd000
   trange=['2016-12-04/06:46:00','2016-12-04/06:50:00']
   ;; STOP 7   - MCP 0xd400, 0xd800, 0xdC00, 0xe000
   trange=['2016-12-04/06:53:00','2016-12-04/07:10:00']
   ;; Channel 7- MCP 0xd000
   trange=['2016-12-04/07:10:00','2016-12-04/07:14:00']
   ;; START 8  - STOP 8  - MCP 0xd400, 0xd800, 0xdC00, 0xe000
   trange=['2016-12-04/07:25:00','2016-12-04/08:16:00']
   ;; Channel 8- MCP 0xd000
   trange=['2016-12-04/08:16:00','2016-12-04/18:00:00']
   ;; STOP 9  -  MCP 0xd400, 0xd800, 0xdC00, 0xe000
   trange=['2016-12-04/18:13:00','2016-12-04/18:40:00']
   ;; Channel 9- MCP 0xd000
   trange=['2016-12-04/18:40:00','2016-12-04/18:41:00']
   ;; START 10 - STOP 10  - MCP 0xd400, 0xd800, 0xdC00, 0xe000
   trange=['2016-12-04/18:41:00','2016-12-04/19:34:00']
   ;; Channel 10- MCP 0xd000
   trange=['2016-12-04/19:34:00','2016-12-04/22:20:00']
   ;; START 11 - STOP 11  - MCP 0xd400, 0xd800, 0xdC00, 0xe000
   trange=['2016-12-04/22:20:00','2016-12-04/23:15:00']
   ;; Channel 11- MCP 0xd000
   trange=['2016-12-04/23:15:00 - 2016-12-04/23:35:00']
   ;; START 12 - STOP 12  - MCP 0xd400, 0xd800, 0xdC00, 0xe000
   trange=['2016-12-04/23:37:00','2016-12-05/00:28:00']
   ;; Channel 12- MCP 0xd000
   trange=['2016-12-04/00:28:00','2016-12-05/01:00:00']
   ;; START 13 - STOP 13  - MCP 0xd400, 0xd800, 0xdC00, 0xe000
   trange=['2016-12-05/01:00:00','2016-12-05/01:51:00']
   ;; Channel 13- MCP 0xd000
   trange=['2016-12-05/01:51:00','2016-12-05/02:10:00']
   ;; START 14 - STOP 14  - MCP 0xd400, 0xd800, 0xdC00, 0xe000
   trange=['2016-12-05/02:12:00','2016-12-05/03:02:00']
   ;; Channel 14- MCP 0xd000 
   trange=['2016-12-05/03:02:00','2016-12-05/03:35:00']
   
   ;;... add the rest


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; SPAN-Ai 3rd Calibration   ;;;
;;;      CAL Facility         ;;;
;;;       2016-12-12          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ;; First Rotation Scan
   trange=['2016-12-13/04:56:00','2016-12-13/06:25:00']




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; SPAN-Ai 4th Calibration ;;;
;;;      CAL Facility       ;;;
;;;       2017-01-02        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   
   ;; Limited Performance Test
   trange = ['2017-01-02/18:10:00','2017-01-02/18:40:00']

   ;; Ramp MCP 0x0 - 0xD000, RAW 0xD000, ACC 0x0
   trange = ['2017-01-02/18:50:00', '2017-01-02/19:31:00']

   ;; RAW 0xD000, MCP 0xD000, ACC 0x0
   trange = ['2017-01-02/19:31:00', '2017-01-02/23:24:00']

   ;; Ramp ACC 0x0 - 0xFF00, RAW 0xD000, MCP 0x0
   trange = ['2017-01-02/23:34:00', '2017-01-03/01:36:00']

   ;; RAW 0xD000, MCP 0x0, ACC 0xFF00
   trange = ['2017-01-03/01:36:00', '2017-01-03/17:56:00']

   ;; Ramp MCP 0x0 - 0xD000
   ;; RAMP ACC 0x0 - 0xFF00
   ;; RAW 0xD000
   trange = ['2017-01-03/18:00:00', '2017-01-03/19:35:00']

   ;; Rotation Scan
   trange = ['2017-01-03/19:30:00' - '2017-01-03/22:00:00']
   
   ;; Threshold Scan of all STARTS and STOPS
   ;; RAW 0xD000, ACC 0xFF00, MCP-0xD000 - gun-0.75mA-480V
   ;; Thresh 60-5, AZ 0-3
   trange = ['2017-01-04/06:00:00' - '2017-01-04/16:00:00']

   ;; Long exposure on channel 15
   ;; RAW 0xD000, ACC 0xFF00, MCP-0xD000 - gun-0.75mA-480V
   trange=['2017-01-04/14:45:00','2017-01-04/19:50:00']

   
   ;; Threshold Scan of channel 12 (yellow)
   ;; RAW 0xD000, ACC 0xFF00 - gun 480V
   ;; MCP - 0xD000,0xD800,0xE000
   ;; Gun - 0.70A, 0.75A, 0.80A
   trange = ['2017-01-04/22:36:00', '2017-01-05/03:41:00']


   ;; Long exposure on channe; 12
   ;; RAW 0xD000, ACC 0xFF00, MCP-0xD000 - gun-0.75mA-480V
   trange = ['2017-01-05/03:41:00', '2017-01-05/06:20:00']


   ;; Gun Map (overnight 4th-5th)
   trange = []

   ;; Rotation Scan
   trange = ['2017-01-06/05:30:00', '2017-01-06/09:40:00']






;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; SPAN-Ai 5th Calibration ;;;
;;;      CAL Facility       ;;;
;;;       2017-01-10        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ;; First Rotation Scan
   ;; Gun at 0.728mA 480V
   trange = ['2017-01-13/18:20:00','2017-01-13/23:00:00']
   
   ;; Second Rotation Scan (After adjusting TOF offsets)
   ;; Gun at 0.800mA 480V with adjustments
   trange = ['2017-01-17/17:43:00','2017-01-17/23:45:00']

   ;; Gun Map (YAWLIN Scan)
   trange = ['2017-01-18/18:20:00','2017-01-18/20:30:00']

   ;; YAW Scan
   ;; WHEN???

   ;; Threshold Scan
   trange = ['2017-01-19/07:45:00','2017-01-19/16:00:00']

   ;; Threshold Scan channel 10 with varying mcps and gun filament
   trange = ['2017-01-20/06:32:00','2017-01-20/11:15:00']

   ;; K Sweep
   ;trange = ['2017-01-23/05:30:30','2017-01-23/12:36:30']
   trange = ['2017-01-23/04:30:30','2017-01-23/12:36:30']
   trange = time_double(trange)
   files = spp_file_retrieve(/cal,/spani,trange=trange)
   spp_ptp_file_read, files

   ;; Deflector Scan
   trange = ['2017-01-24/07:25:00','2017-01-24/19:00:00']
   trange = time_double(trange)
   files = spp_file_retrieve(/cal,/spani,trange=trange)
   spp_ptp_file_read, files


   ;; Energy-Yaw Scan
   

   ;; Spoiler-Yaw Scan
   
   

   


   ;; Load Selected Time Range
   files = spp_file_retrieve(/cal,/spani,trange=trange)
   files = spp_file_retrieve(/cal,/spani,trange=systime(1))
   files = spp_file_retrieve(/cal,/spani,recent=2/24.)
   spp_ptp_file_read, files
   spp_init_realtime,/cal,/spani,/exec,recent=.01
   spp_swp_tplot,/setlim
   spp_swp_tplot,'si'
   spp_swp_gse_pressure_file_read ; load chamber pressure
   

end
