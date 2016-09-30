pro spp_swp_spane_thresh_analysis,anode,sigma,trangefull=trangefull,data=data,plotname=plotname, instrument

;; WORK IN PROGRESS

; list conditions
; need to run tlimit outputting trangeFull as boundaries (first of anode, then of whole test as you get more sophisticated)
; 

  specAnode = tsample('spp_spane_b_ar_full_p1_16Ax8Dx32E_SPEC1', trangeFull, time = timeSpecAnode)
  threshAnode = tsample('spp_spane_b_hkp_MRAM_WR_ADDR', trangeFull, time = timeThreshAnode)
  mcpDACanode = tsample('spp_spane_b_hkp_MCP_DAC', trangeFull)
  anodeNumber = tsample('spp_spane_b_hkp_MRAM_WR_ADDR', trangefull)
  mcpVanode = tsample('spp_spane_b_hkp_ADC_VMON_MCP', trangefull)
  
  hkp = create_struct('time',timeThreshAnode, 'thresh', threshAnode, 'mcpdac', mcpDACanode, 'mcpv', mcpVanode, 'anode', anodeNumber)
  
  threshIntAnode = interpol(threshAnode, timeThreshAnode, timeSpecAnode)
  mcpDACintAnode = interpol(mcpDACanode, timeThreshAnode, timeSpecAnode)
  anodeNumberInt = interpol(anodeNumber, timeThreshAnode, timeSpecAnode)
  mcpVintAnode = interpol(mcpVanode, timeThreshAnode, timeSpecAnode)
  
  ; Select valid counts with boolean filter
  good = 1
  good = good and (threshIntAnode gt 70) ; cut out counts from when threshold is below noise.
  good = good and (specAnode[*,anode] lt 1000) ; average max real counts is ~ couple hundred
  ;good = good and (anodeNumber ne '1f'x) ; set anode equal to 0x1f when not active or when rotating.
  
  preFilter = create_struct('time', timeSpecAnode, 'thresh', threshIntAnode, 'mcpdac', mcpDACintAnode, 'mcpv', mcpVintAnode, $
                            'anode', anodeNumberInt, 'counts', specAnode)

  condition = where(good)
  filterDat = create_struct('time', preFilter.time[condition], 'thresh', preFilter.thresh[condition], 'mcpdac', preFilter.mcpdac[condition], $
                            'mcpv', preFilter.mcpv, 'anode', preFilter.anode[condition], 'counts', preFilter.counts[condition,*])
  
                            
  uniqueMCP = filterDat.mcpdac[uniq(filterDat.mcpdac)]
  ; define a better green.
  tvlct, 53, 156, 83, 100
  colorArray = [6, 100, 2, 1, 0] ; r, g, b, m, k
  ;colorArray = [250,300,350,400,450]
  ;indexArray = [4,3,2,1,0]        
                            
  for i = 0,4 do begin
    mcpCriteria = 1
    print, 'iteration # ' + strtrim(i)
    mcpCriteria = mcpCriteria and (filterDat.mcpdac eq uniqueMCP[i])
    mcpCondition = where(mcpCriteria)
    counts = filterDat.counts[mcpCondition, anode]
    threshDACs = filterDat.thresh[mcpCondition]
    mcpVs = filterDat.mcpv[mcpCondition]
    mcpVavg = mean(mcpVs)
    wi, (anode + 11), wsize = [600,600]
    !p.multi = [0,1,2]
    if i eq 0 then begin
      plot,threshDACs,counts,psym=4,xtitle='Threshold DAC level',ytitle='Counts', title = 'SPAN-B Flight Anode ' + strtrim(anode,2)
      p1 = !P & x1 = !X & y1 = !Y
    endif else begin
      !p = p1 & !x = x1 & !y = y1
    endelse
    oplot, threshDACs, counts, psym = 4, color = colorArray[i]
    sigmaCounts = stddev(counts)
    meanCounts = mean(counts)
    printdat, sigmaCounts
    ;--------------------------------------
    ;eliminate values more than 3sigma away
    sigmaCriteria = 1
    sigmaCriteria = sigmaCriteria and (counts lt (meanCounts + (sigma * sigmaCounts))) and (counts gt (meanCounts - (sigma * sigmaCounts)))
    sigmaCondition = where(sigmaCriteria)
    countsValid = counts[sigmaCondition]
    threshDACsValid = threshDACs[sigmaCondition]
    ;--------------------------------------
    ;calculate fit
    range = [min(threshDACs),max(threshDACs)]
    xp = dgen(6,range=range)
    yp = xp*0+500
    xv = dgen()
    yv = spline_fit3(xv,xp,yp,param=p,/ylog)
    fit,threshDACsValid,countsValid,param=p
    pf, p, color = colorArray[i], /over
    ;printdat, p
    ;pf,p,/over
    plt1 = get_plot_state()
    if i eq 0 then begin
      plot,xv,-deriv(xv,func(xv,param=p)),xtitle='Threshold DAC level',ytitle='PHD'
      p2 = !P & x2 = !X & y2 = !Y
    endif else begin
      !p = p2 & !x = x2 & !y = y2
    endelse
    oplot,xv,-deriv(xv,func(xv,param=p)), color = colorArray[i]
    plt2 = get_plot_state()
    !p.multi = 0
  endfor
end
  