;20161230 Ali
;plots Mars and its bow shock over the current plot
;keywords:
;rm: plots in units of Rm instead of km
;p3d: plots in 3d

pro mvn_pui_plot_mars_bow_shock,rm=rm,p3d=p3d

  rmars=3400. ;radius of mars (km)
  theta=!dtor*findgen(361) ;theta in radians
  xmars=cos(theta)
  ymars=sin(theta)
  ybow=-3+findgen(61)/10.
  xbow=1.7-.24*ybow^2 ;fit to nominal mars bow shock
  xtitle='$X (R_M)$'
;  ytitle='$(Y^2+Z^2)^{1/2} (R_M)$'
  ytitle='$Y (R_M)$'
  ztitle='$Z (R_M)$'
  
  if ~keyword_set(rm) then begin
    xmars*=rmars
    ymars*=rmars
    xbow*=rmars
    ybow*=rmars
    xtitle='X (km)'
    ytitle='Y (km)'
    ztitle='Z (km)'
  end


  p=plot(/o,[0],/nodata,xtitle=xtitle,ytitle=ytitle,ztitle=ztitle,/aspect_ratio,/aspect_z) ;bow shock
  p=plot(/o,xmars,ymars,'r') ;Mars
  p=plot(/o,xbow,ybow,'b') ;bow shock
  ;  p=plot(/o,2.9*xmars,2.9*ymars,'--') ;MAVEN coverage
  if keyword_set(p3d) then begin
    p=plot3d(/o,0.*xmars,xmars,ymars,'r')
    p=plot3d(/o,xmars,0.*xmars,ymars,'r')
    p=plot3d(/o,xbow,0.*xbow,ybow,'b')
  endif
    

end