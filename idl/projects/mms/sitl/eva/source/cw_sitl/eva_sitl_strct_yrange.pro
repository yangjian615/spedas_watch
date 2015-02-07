PRO eva_sitl_strct_yrange, tpv, yrange=yrange
  compile_opt idl2
  
  get_data,tpv,data=S,lim=lim,dl=dl; S should be an array of strings
  Dyt = 0.
  imax = n_elements(S)
  for i=0,imax-1 do begin
    if (strpos(S[i],'zero') eq -1) then begin
      get_data,S[i],data=D
      Dyt = [Dyt, D.y]
    endif
  endfor
  ;////////////////////////////////////
  Dymax = max(Dyt,/nan)*1.1 < 255.
  ;////////////////////////////////////
  yrange = [0.,Dymax]
  ylim,tpv, yrange
END
