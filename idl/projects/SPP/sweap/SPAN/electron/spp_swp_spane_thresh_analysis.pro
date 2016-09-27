
pro spp_swp_spane_thresh_analysis,anode,trangefull=trangefull,data=data,plotname=plotname, instrument

  ;channel = anode and 'f'x
  ;stp  = (anode and '10'x) ne 0
  ;if not keyword_set(trangefull) then ctime,trangefull

  ;timebar,trangefull

  ;spp_apid_data,'360'x,apdata=foo ; change this to look for Ae or B. find out what B packets are
  ;foobar = foo.data_array.array
  ;w = where((foobar.time ge trangefull[0]) and (foobar.time le trangefull[1]) )
  ;rates_w = rates[w]

  ;--------------------------
  ;run tlimit and ctime exact for each mcp value
  print, 'mcpv = 0xa000'
  tlimit
  ctime, /exact, endTimea000, va000
  tlimit, /last
  tlimit
  ctime, /exact, endTimea800, va800
  tlimit, /last
  tlimit
  ctime, /exact, endTimeb000, vb000
  tlimit, /last  
  tlimit
  ctime, /exact, endTimeb800, vb800
  tlimit, /last
  tlimit
  ctime, /exact, endTimebb00, vbb00
  tlimit, /last
  
  thresha000 = tsample('spp_spane_b_hkp_MRAM_WR_ADDR', endTimea000, time = timeThresha000)
  thresha800 = tsample('spp_spane_b_hkp_MRAM_WR_ADDR', endTimea800, time = timeThresha800)
  threshb000 = tsample('spp_spane_b_hkp_MRAM_WR_ADDR', endTimeb000, time = timeThreshb000)
  threshb800 = tsample('spp_spane_b_hkp_MRAM_WR_ADDR', endTimeb800, time = timeThreshb800)
  threshbb00 = tsample('spp_spane_b_hkp_MRAM_WR_ADDR', endTimebb00, time = timeThreshbb00)
  cntsa000 = tsample('spp_spane_b_ar_full_p1_16Ax8Dx32E_SPEC1', endTimea000, time = timeCntsa000)
  cntsa800 = tsample('spp_spane_b_ar_full_p1_16Ax8Dx32E_SPEC1', endTimea800, time = timeCntsa800)
  cntsb000 = tsample('spp_spane_b_ar_full_p1_16Ax8Dx32E_SPEC1', endTimeb000, time = timeCntsb000)
  cntsb800 = tsample('spp_spane_b_ar_full_p1_16Ax8Dx32E_SPEC1', endTimeb800, time = timeCntsb800)
  cntsbb00 = tsample('spp_spane_b_ar_full_p1_16Ax8Dx32E_SPEC1', endTimebb00, time = timeCntsbb00)
  threshInterpa000 = interpol(thresha000, timeThresha000, timeCntsa000)
  threshInterpa800 = interpol(thresha800, timeThresha800, timeCntsa800)
  threshInterpb000 = interpol(threshb000, timeThreshb000, timeCntsb000)
  threshInterpb800 = interpol(threshb800, timeThreshb800, timeCntsb800)
  threshInterpbb00 = interpol(threshbb00, timeThreshbb00, timeCntsbb00)
  
  wi, 1, wsize = [600,400]
  yrange = [0.1,300.]
  ; define a better green.
  tvlct, 53, 156, 83, 100
  plot, yrange = yrange, threshInterpa000, cntsa000[*,anode], /ylog, xtitle = 'Threshold', ytitle = 'Counts', title = 'Anode ' + strtrim(anode,2)+ ' SPAN-B'
  oplot, threshInterpa000, cntsa000[*,anode], color = 6
  oplot, threshInterpa800, cntsa800[*,anode], color = 100
  oplot, threshInterpb000, cntsb000[*,anode], color = 2
  oplot, threshInterpb800, cntsb800[*,anode], color = 1
  oplot, threshInterpbb00, cntsbb00[*,anode], color = 0
  
  cntAvga000 = average_hist(cntsa000[*,anode], fix(threshInterpa000), binsize = 1, xbins = tbinsa000)
  cntAvga800 = average_hist(cntsa800[*,anode], fix(threshInterpa800), binsize = 1, xbins = tbinsa800)
  cntAvgb000 = average_hist(cntsb000[*,anode], fix(threshInterpb000), binsize = 1, xbins = tbinsb000)
  cntAvgb800 = average_hist(cntsb800[*,anode], fix(threshInterpb800), binsize = 1, xbins = tbinsb800)
  cntAvgbb00 = average_hist(cntsbb00[*,anode], fix(threshInterpbb00), binsize = 1, xbins = tbinsbb00) 
   
  wi, 2, wsize = [600,400]
  ;yrangeBins = [0.001, 20.]
  plot, tbinsbb00, cntsbb00[*,anode], psym = -1, color = 0, xtitle = 'Threshold', title = 'Average_Hist, SPANB Anode ' + strtrim(anode,2), ytitle = 'Counts'
  oplot, tbinsa000, cntsa000[*,anode], psym = -1, color = 6
  oplot, tbinsa800, cntsa800[*,anode], psym = -1, color = 100
  oplot, tbinsb000, cntsb000[*,anode], psym = -1, color = 2
  oplot, tbinsb800, cntsb800[*,anode], psym = -1, color = 1
  oplot, tbinsbb00, cntsbb00[*,anode], psym = -1, color = 0
  
  wi, 3, wsize = [600,400]
  dthAvga000 = -deriv(tbinsa000, cntAvga000)
  dthAvga800 = -deriv(tbinsa800, cntAvga800)
  dthAvgb000 = -deriv(tbinsb000, cntAvgb000)
  dthAvgb800 = -deriv(tbinsb800, cntAvgb800)
  dthAvgbb00 = -deriv(tbinsbb00, cntAvgbb00)
  
  plot, tbinsa000, dthavga000, psym=-4, xtitle='Threshold', /ylog, yrange = [0.1,100.], title = 'Deriv Anode ' + strtrim(anode,2)
  oplot, tbinsa000, dthavga000, psym = -4, color = 6
  oplot, tbinsa800, dthavga800, psym = -4, color = 100
  oplot, tbinsb000, dthavgb000, psym = -4, color = 2
  oplot, tbinsb800, dthavgb800, psym = -4, color = 1
  oplot, tbinsbb00, dthavgbb00, psym = -4, color = 0

  ;data = {anode:anode,  cntavg:cntavg,  tbins:tbins } what's this do?

end
