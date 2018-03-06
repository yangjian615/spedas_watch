pro spp_swp_ssrreadreq,times

n= n_elements(times)
if n and 1 then message ,'Must be odd'


n2 = n/2
tt = reform(times,2,n2)
for i=0,n2-1 do begin
    blocknums = data_cut('spp_swem_dhkp_SW_SSRWRADDR',tt[*,i])
    startblock = blocknums[0]
    deltablock = blocknums[1]-blocknums[0] > 1
    apmask  =  replicate('ffffffff'x,4)
    apmask1  = 'FFFFffff'x
    apmask2  = 'FFFFffff'x
    apmask3  = 'FFFFffff'x
;    print,startblock,deltablock,APMASK0,APMASK1,APMASK2,APMASK3,format='("cmd.sw_ssrreadreq(",i6,i5,Z4,Z4,Z4,Z4,")")'
    print,startblock,deltablock,APMASK,time_string(tt[*,i]),  $
      format='(%"cmd.SW_SSRREADREQ(%d,%d,0x%8X,0x%8X,0x%8X,0x%8x)  # from: %s  to: %s ")'
endfor


end




pro spp_swp_tplot,name,ADD=ADD,setlim=setlim

if keyword_set(setlim) then begin
  options,'spp_*AF*_SPEC' , spec=1
  options,'*MASK',tplot_routine='bitplot'
  options,'*_FLAGS',tplot_routine='bitplot'
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
  options,'*ACT_FLAG',colors='ddgrgrbb'
  options,'spp_spi_hkp_DAC_DEFL',ytitle='DEFL (dac)'

  tplot,var_label=tnames('manip*_POS *DAC_DEFL Igun_VOLTS Igun_CURRENT')
  !y.style=3
  dprint,setd=2
  store_data,'APID',data='APIDS_*'
  ylim,'APID',800,1000
  options,'APID',panel_size=2
  
  
endif


if keyword_set(name) then begin
  
  plot_name = strupcase(strtrim(name,2))
  case plot_name of
    'CMDCTR': tplot,'*swem_dhkp_SW_CMDCOUNTER *CMD_REC *CMDS_REC',add=add
    'SE':   tplot,'*sp?_AF0_ANODE_SPEC *sp?_AF1_*_SPEC spp_sp?_hkp_MRAM_*',ADD=ADD
    'SE_HV': tplot,'*sp?_hkp_ADC_VMON_* *sp?_hkp_ADC_IMON_*',ADD=ADD
    'SA_HV': tplot,'*CMDCOUNTER *spa_*CMD_REC *spa_hkp_HV_CONF_FLAG *spa_hkp_???_DAC *spa_hkp_ADC_VMON_* *spa_hkp_ADC_IMON_* *spa_*SF1_ANODE_SPEC',ADD=ADD
    'SB_HV': tplot,'*CMDCOUNTER *spb_*CMD_REC *spb_hkp_HV_CONF_FLAG *spb_hkp_???_DAC *spb_hkp_ADC_VMON_* *spb_hkp_ADC_IMON_* *spb_*SF1_ANODE_SPEC',ADD=ADD
    'SC_HV': tplot,'spp_spc_hkp_ADC*'
    'SE_LV': tplot,'*sp?_hkp_RIO*',ADD=ADD
    'SA_SPEC': tplot, '*spa_*ADC_VMON_HEM *spa_AF0_CNTS *spa_*AF1_ANODE_SPEC spp_spa_AF1_NRG_SPEC spp_spa_AT0_CNTS spp_spa_AT1_ANODE_SPEC spp_spa_AT1_NRG_SPEC spp_spa_AT1_PEAK_BIN', ADD=ADD
    'SB_SPEC': tplot, 'spp_spb_hkp_ADC_VMON_HEM spp_spb_AF0_CNTS spp_spb_AF1_ANODE_SPEC spp_spb_AF1_NRG_SPEC spp_spb_AT0_CNTS spp_spb_AT1_ANODE_SPEC spp_spb_AT1_NRG_SPEC spp_spb_AT1_PEAK_BIN', ADD=ADD
    'SI_RATE': tplot,'*rate*CNTS',ADD=ADD
    'SI_RATE1': tplot,'*rates_'+strsplit(/extract,'VALID_* MULTI_* STARTS_* STOPS_*'),add=add
    'SI_AF0?_1': tplot,'*spani_ar_full_p0_m?_*_SPEC1',add=add
    'SI_HV2': tplot,'*CMDCOUNTER *spi_hkp_HV_CONF_FLAG *spi_hkp_???_DAC *spi_hkp_ADC_VMON_* *spi_hkp_ADC_IMON_*',ADD=ADD
    'SI_MON' : tplot,'*spi_*hkp_MON*',add=add
    'SI_HV' : tplot,['*CMDCOUNTER','*spi_*CMDS_REC','*spi*DACS*','*spi_hkp_HV_MODE','*spi_*' + strsplit(/extract,'RAW_? MCP_? ACC_?')],add=add
    'MANIP':tplot,'manip*_POS',add=add
    'SI_GSE': tplot,add=add,'Igun_* APS3_*'
    'SI': tplot,add=add,'Igun_* manip_*POS *rates_VAL*CNTS *rates_*NO*CNTS '
    'SI_SCAN':tplot,add=add,'*MCP_V *MRAM* *spi_AF0?_NRG_SPEC'
    'SC':  tplot,'spp_*spc*',ADD=ADD
    'ACT': tplot,'spp*_ACT_FLAG spp_*SP?_22_C
    'SI_COVER': tplot, '*spi*CMD*REC spp_spi_*_ACT_FLAG spp_*SPI_22_C spp_spi_hkp*ANAL_TEMP', add = add
    'SA_COVER': tplot, '*spa*CMD*REC spp_spa_*_ACT_FLAG spp_*SPA_22_C spp_spa_hkp*ANAL_TEMP', add = add
    'SB_COVER': tplot, '*spb*CMD*REC spp_spb_*_ACT_FLAG spp_*SPB_22_C spp_spb_hkp*ANAL_TEMP', add = add
    'SB_COVER': tplot, '*spb_*ACT*CVR* *spb_*ACTSTAT*FLAG *spb*CMD*REC', add = add
 ;   'SA_COVER': tplot, '*spa_*ACT*CVR* *spa_*ACTSTAT*FLAG *spa*CMD*REC', add = add
    'SWEM': tplot,'APID spp_swem_dhkp_SW_CMDCOUNTER',add=add
    'TIMING': tplot,'spp_swem_timing_'+['DRIFT_DELTA','CLKS_PER_PPS_DELTA','SCSUBSECSATPPS']
    'TEMP': tplot,'*TEMP'
    'TEMPS': tplot,'*ALL_TEMPS
    'CRIT':tplot,'*SF1_ANODE_SPEC *ACC_? *22_C *HVOUT *RAIL*
    else:
  endcase
  wshow,i=0,0
endif
  
end
