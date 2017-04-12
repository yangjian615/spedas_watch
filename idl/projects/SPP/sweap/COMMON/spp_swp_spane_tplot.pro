pro spp_swp_spane_tplot,name,ADD=ADD,setlim=setlim

  if keyword_set(setlim) then begin
    options,'spp_*AF*_SPEC' , spec=1
    options,'*MASK',tplot_routine='bitplot'
    options,'*_FLAG',tplot_routine='bitplot'
    tplot_options,'no_interp',1
    ;  options,'*SPEC23',panel_size=3
    options,'*rates*CNTS',spec=1,zrange=[1,1],/zlog,yrange=[0,0],ylog=0
    options,'*rates*CNTS',spec=0,yrange=[1,1],ylog=1
    options,'*hkp_HV_MODE',tplot_routine= 'bitplot'
    options,'*TEMPS',/ynozero
    options,'*events*',psym=3
    options,'manip_YAW_POS',ytitle='YAW (deg)'
    options,'manip_ROT_POS',ytitle='ROT (deg)'
    options,'manip_LIN_POS',ytitle='LIN (cm)'
    options,'Igun_VOLTS',ytitle='Energy (eV)'
    options,'Igun_CURRENT',ytitle ='Ie- (uA)'
    options,'spp_spi_hkp_DAC_DEFL',ytitle='DEFL (dac)'

    tplot,var_label=tnames('manip*_POS *DAC_DEFL Egun_VOLTS Egun_CURRENT')
    !y.style=3
    dprint,setd=3


  endif


  if keyword_set(name) then begin

    plot_name = strupcase(strtrim(name,2))
    case plot_name of
      'SE':   tplot,'*sp?_AF0_ANODE_SPEC *sp?_AF1_*_SPEC spp_sp?_hkp_MRAM_*',ADD=ADD
      'SE_HV': tplot,'*sp?_hkp_ADC_VMON_* *sp?_hkp_ADC_IMON_*',ADD=ADD
      'SE_LV': tplot,'*sp?_hkp_RIO*',ADD=ADD
      'SA_SPEC': tplot, '*spa_*ADC_VMON_HEM *spa_AF0_CNTS *spa_*AF1_ANODE_SPEC spp_spa_AF1_NRG_SPEC spp_spa_AT0_CNTS spp_spa_AT1_ANODE_SPEC spp_spa_AT1_NRG_SPEC spp_spa_AT1_PEAK_BIN', ADD=ADD
      'SB_SPEC': tplot, 'spp_spb_hkp_ADC_VMON_HEM spp_spb_AF0_CNTS spp_spb_AF1_ANODE_SPEC spp_spb_AF1_NRG_SPEC spp_spb_AT0_CNTS spp_spb_AT1_ANODE_SPEC spp_spb_AT1_NRG_SPEC spp_spb_AT1_PEAK_BIN', ADD=ADD
      'MANIP':tplot,'manip*_POS',add=add
      'SA_COVER': tplot, '*spa_*ACT*CVR* *spa_*ACTSTAT*FLAG* *spa_*ANAL*TEMP* *spa*ATO* *spa*ATI*', add = add
      'SB_COVER': tplot, '*spb_*ACT*CVR* *spb_*ACTSTAT*FLAG* *spb_*ANAL*TEMP* *spb*ATO* *spb*ATI*', add = add
      'SB_COVER_Greg': tplot, '*spb_*hkp*CMD*REC TEMP *spb*hkp*ACT*CVR*T *spb*hkp*ACTSTAT*FLAG', add = add
      'SA_COVER_Greg': tplot, '*spa_*hkp*CMD*REC TEMP *spa_*hkp*ACT*CVR*T *spa_*hkp*ACTSTAT*FLAG', add = add

      else:
    endcase
  endif

end
