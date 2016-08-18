pro spp_swp_tplot,name,ADD=ADD,setlim=setlim

if keyword_set(setlim) then begin
  options,'*SPEC*' , spec=1
  options,'*MASK',tplot_routine='bitplot'
  options,'*_FLAG',tplot_routine='bitplot'
  tplot_options,'no_interp',1
  options,'*SPEC23',panel_size=3
  
  
endif



  plot_name = strupcase(strtrim(name,2))
  case plot_name of
    'SA':   tplot,'*PPULSE_MASK *ar_full_p1_*_SPEC1 *ar_full_p1_*_SPEC23 *ar_full_p0_*_SPEC spp_*ar_full_p1_MODE?',ADD=ADD
    'SA_HV': tplot,'*_a_*_IMON_* *a_*_VMON_*',ADD=ADD
    'SA_LV': tplot,'*spane*hkp*RIO*',ADD=ADD
    'SA_SPEC': tplot,'*_a_ar_targ_p1_*CNTS_TOTAL *_a_ar_targ_p1_*_SPEC? *_a_ar_targ_p0_*_SPEC*',add=add
    'SB': tplot,'APID',ADD=ADD
    'SI':tplot,'APID',ADD=ADD
    'SC':  tplot,'spp_*spc*',ADD=ADD
    else:
  endcase
  
end
