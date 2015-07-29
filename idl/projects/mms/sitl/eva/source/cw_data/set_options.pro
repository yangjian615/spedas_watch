PRO set_options, tpv, $
  ytitle=ytitle,ztitle=ztitle,yrange=yrange,$
  zrange=zrange,ylog=ylog,zlog=zlog,spec=spec,labels=labels,labflag=labflag,$
  colors=colors,ysubtitle=ysubtitle,constant=constant,cap=cap
  tn = tnames(tpv,n)
  if (strlen(tn[0]) gt 0) and (n eq 1) then begin
    options, tpv,'spec',keyword_set(spec)
    if keyword_set(spec) then options,tpv,'no_interp',1
    if n_elements(ylog) eq 1 then options, tpv,'ylog',ylog
    if n_elements(zlog) eq 1 then options, tpv,'zlog',1
    if n_elements(ytitle) eq 1 then options, tpv,'ytitle',ytitle
    if n_elements(ztitle) eq 1 then options, tpv,'ztitle',ztitle
    if n_elements(yrange) eq 2 then ylim, tpv, yrange[0],yrange[1]
    if n_elements(zrange) eq 2 then zlim, tpv, zrange[0],zrange[1]
    if n_elements(labels) gt 0 then options, tpv, labels=labels
    if n_elements(labflag) eq 1 then options,tpv,'labflag',labflag
    if n_elements(colors) gt 0 then options,tpv,'colors',colors
    if n_elements(ysubtitle) eq 1 then options, tpv,'ysubtitle',ysubtitle
    if n_elements(constant) eq 1 then options, tpv,'constant',0
    if keyword_set(cap) then eva_cap, tpv
  endif
END
