pro spp_swp_tplot,name,ADD=ADD,setlim=setlim

if keyword_set(setlim) then begin
  options,'*SPEC*' , spec=1
  options,'*MASK',tplot_routine='bitplot'
  options,'*_FLAG',tplot_routine='bitplot'
  tplot_options,'no_interp',1
  options,'*SPEC23',panel_size=3
  options,'*rates*CNTS',spec=1,zrange=[1,1],/zlog,yrange=[0,0],ylog=0
  options,'*rates*CNTS',spec=0,yrange=[1,1],ylog=1
  options,'*hkp_HV_MODE',tplot_routine= 'bitplot'
  options,'*TEMPS',/ynozero
  
  
endif


if keyword_set(name) then begin
  
  plot_name = strupcase(strtrim(name,2))
  case plot_name of
    'SA':   tplot,'*PPULSE_MASK *ar_full_p1_*_SPEC1 *ar_full_p1_*_SPEC23 *ar_full_p0_*_SPEC spp_*ar_full_p1_MODE?',ADD=ADD
    'SA_HV': tplot,'*_a_*_IMON_* *a_*_VMON_*',ADD=ADD
    'SA_LV': tplot,'*spane*hkp*RIO*',ADD=ADD
    'SA_SPEC': tplot,'*_a_ar_targ_p1_*CNTS_TOTAL *_a_ar_targ_p1_*_SPEC? *_a_ar_targ_p0_*_SPEC*',add=add
    'SB': tplot,'APID',ADD=ADD
    'SB_SPEC': tplot,'*_b_ar_targ_p1_*CNTS_TOTAL *_b_ar_targ_p1_*_SPEC? *_b_ar_targ_p0_*_SPEC*',add=add
    'SI_RATE': tplot,'*rate*CNTS',ADD=ADD
    'SI_RATE1': tplot,'*rates_'+strsplit(/extract,'VALID_* MULTI_* STARTS_* STOPS_*'),add=add
    'SI_AF0?_1': tplot,'*spani_ar_full_p0_m?_*_SPEC1',add=add
    'SI_MON' : tplot,'*spani_*hkp_MON*',add=add
    'SI_HV' : tplot,'*spani_*' + strsplit(/extract,'RAW_? MCP_? ACC_?'),add=add
    'MANIP':tplot,'*_M???POS *MRAM_LOW',add=add
    'SI_GSE': tplot,add=add,'Igun_* APS3_*'
    'SC':  tplot,'spp_*spc*',ADD=ADD
    else:
  endcase
endif
  
end
