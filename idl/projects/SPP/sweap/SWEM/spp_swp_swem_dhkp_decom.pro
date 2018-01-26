

function spp_swp_swem_dhkp_decom,ccsds,ptp_header=ptp_header,apdat=apdat


if n_params() eq 0 then begin
  dprint,'Not working yet.'
  return,!null
endif

ccsds_data = spp_swp_ccsds_data(ccsds)

;if typename(ccsds) eq 'CCSDS_FORMAT' then data = *ccsds.pdata  else data=ccsds.data
;data = ccsds.data


if ccsds.pkt_size eq 30 then begin
  if debug(2) then begin
    dprint,'DHKP packet for boot mode ????',ccsds.pkt_size,dlevel=2,dwait = 10
;    hexprint,ccsds_data
    return,0
  endif
endif



;values = swap_endian(ulong(ccsds_data,10,11) )

if ccsds.pkt_size eq 86 then begin   ; This is old version of software????  not sure of what the packet size should have been for this version
  str2 = {time:   ccsds.time  ,$
    seqn: ccsds.seqn, $
    PWR_CONFIG_FLAG: spp_swp_data_select(ccsds_data, 80  ,  8), $   ;   SW_PWRSPARE, SW_ACTPWR ,  SW_SPANBHTR, SW_SPANAHTR  , SW_SPANBPWR ,   SW_SPANAEPWR  , SW_SPANAIPWR ,  SW_SPCPWR   87  UB  1
    MISC_CONFIG_FLAG: spp_swp_data_select(ccsds_data, 88  ,  8), $
    EVENT_CTR: spp_swp_data_select(ccsds_data,   88  ,  4), $       ;  SW_FLPLBPROG ,  SW_FIELDSCLK  ,SW_LINK_A_ACTIVE  ,SW_LINK_B_ACTIVE    95  UB  1
    SWEM_CONFIG_flag: spp_swp_data_select(ccsds_data,   96  ,  8), $
    LASTFSWEVENT: spp_swp_data_select(ccsds_data,   96  ,  4), $  ;  SW_FSWSPARE ,  SW_FSWCSCI  ,  SW_BOOTMODE ,  SW_WDRSTDET  ,  SW_SWEM3P3V 1 104 UB  8
    SPANAICONFIG: spp_swp_data_select(ccsds_data,  112 ,  8), $
    SW_SPANAIMODE: spp_swp_data_select(ccsds_data,   112 ,  4), $
    SW_PRVSPANAIERR: spp_swp_data_select(ccsds_data,   116 ,  4), $
    SW_SPANAE_CONFIG: spp_swp_data_select(ccsds_data,  120 ,  8), $
    SW_SPANAEMODE: spp_swp_data_select(ccsds_data,     120 ,  4), $
    SW_PRVSPANAEERR: spp_swp_data_select(ccsds_data,  124 ,  4), $
    SW_SPANBCONFIG: spp_swp_data_select(ccsds_data,   128 ,  8), $
    SW_SPANBMODE: spp_swp_data_select(ccsds_data,    128 ,  4), $
    SW_PRVSPANBERR: spp_swp_data_select(ccsds_data,    132 ,  4), $
    SW_SPCCONFIG: spp_swp_data_select(ccsds_data,   136 ,  8), $     ;()
    SW_SPCMODE: spp_swp_data_select(ccsds_data,    136 ,  4), $
    SW_PRVSPCERR: spp_swp_data_select(ccsds_data,    140 ,  4), $
    SW_FSWSTATE: spp_swp_data_select(ccsds_data,  144 ,  8), $
    SW_EVENTCTR: spp_swp_data_select(ccsds_data,  152 ,  32), $
    SW_LASTFSWEVENT: spp_swp_data_select(ccsds_data,  184 ,  16), $
    SW_CMDCOUNTER: spp_swp_data_select(ccsds_data,  200 ,  32), $
    SW_CMDSTATUS: spp_swp_data_select(ccsds_data,   232 ,  32), $
    SW_GLOBALSTATUS: spp_swp_data_select(ccsds_data, 264 ,  32), $    ;()
    SW_GLOBAL: spp_swp_data_select(ccsds_data,   264 ,  16), $
    SW_FPGAVER: spp_swp_data_select(ccsds_data,    280 ,  8), $
    SW_STATUS: spp_swp_data_select(ccsds_data,   288 ,  8), $
    SW_CDISTATUS: spp_swp_data_select(ccsds_data,   296 ,  32), $
    SW_SRVRDPTR: spp_swp_data_select(ccsds_data,  328 ,  32), $
    SW_SRVWRPTR: spp_swp_data_select(ccsds_data,  368 ,  32), $    ; line added on 2017- 12-10
    SW_ARCRDPTR: spp_swp_data_select(ccsds_data,  392 ,  32), $
    SW_SSRWRADDR: spp_swp_data_select(ccsds_data,   424 ,  32), $
    SW_SSRRDADDR: spp_swp_data_select(ccsds_data,   456 ,  32), $
    SW_SPANAECTL: spp_swp_data_select(ccsds_data,   488 ,  8), $
    SW_SPANBCTL: spp_swp_data_select(ccsds_data,  496 ,  8), $
    SW_SPANAICTL: spp_swp_data_select(ccsds_data,   504 ,  8), $
    SW_SPCCTL: spp_swp_data_select(ccsds_data,  512 ,  8), $
    SW_SPANAHTRCTL: spp_swp_data_select(ccsds_data,   520 ,  8), $
    SW_SPANBHTRCTL: spp_swp_data_select(ccsds_data,   528 ,  8), $
    SW_SPANAECVRCTL: spp_swp_data_select(ccsds_data,  536 ,  8), $
    SW_SPANBCVRCTL: spp_swp_data_select(ccsds_data,   544 ,  8), $
    SW_SPANAICVRCTL: spp_swp_data_select(ccsds_data,  552 ,  8), $
    SW_SPANAEATNCTL: spp_swp_data_select(ccsds_data,  560 ,  8), $
    SW_SPANBATNCTL: spp_swp_data_select(ccsds_data,   568 ,  8), $
    SW_SPANAIATNCTL: spp_swp_data_select(ccsds_data,  576 ,  8), $
    SW_DCBOVERCUR: spp_swp_data_select(ccsds_data,  584 ,  8), $
    SW_SEQSTATUSIDX: spp_swp_data_select(ccsds_data,  592 ,  8), $
    SW_SEQSTATUS: spp_swp_data_select(ccsds_data,  600 ,  16), $
    SW_MONSTATUS: spp_swp_data_select(ccsds_data,  616 ,  8), $
    SW_PWRDOWNWARN: spp_swp_data_select(ccsds_data,  624 ,  8), $
    SW_SSRBADBLKCNT:spp_swp_data_select(ccsds_data,  632 ,  8), $
    SW_FSWVERSION: spp_swp_data_select(ccsds_data, 640  ,  16),$
    SW_OSCPUUSAGE: spp_swp_data_select(ccsds_data,  656  ,  8), $
    SW_OSERRCOUNT: spp_swp_data_select(ccsds_data,  664  ,  16), $
    gap:0B}
  str2.gap=1
  return,str2
endif



if ccsds.pkt_size eq 0 then begin   ; This is old version of software????  not sure of what the packet size should have been for this version
  nsq = 32
  sequence_cntr = uintarr(nsq)
  sequence_ena  = 0ull
  sequence_exec = 0ull
  startbit = 584
 for i =0,nsq-1 do begin
    sequence_cntr[i] = spp_swp_data_select(ccsds_data,startbit,14)
    sequence_exec = ishft(sequence_exec,1) or spp_swp_data_select(ccsds_data,startbit+1,1)
    sequence_ena  = ishft(sequence_exec,1) or spp_swp_data_select(ccsds_data,startbit+2,1)
    startbit += 16  
  endfor
  str2 = {time:   ccsds.time  ,$
    seqn: ccsds.seqn, $
    PWR_CONFIG_FLAG: spp_swp_data_select(ccsds_data, 80  ,  8), $   ;   SW_PWRSPARE, SW_ACTPWR ,  SW_SPANBHTR, SW_SPANAHTR  , SW_SPANBPWR ,   SW_SPANAEPWR  , SW_SPANAIPWR ,  SW_SPCPWR   87  UB  1
    MISC_CONFIG_FLAG: spp_swp_data_select(ccsds_data, 88  ,  8), $
    EVENT_CTR: spp_swp_data_select(ccsds_data,   88  ,  4), $       ;  SW_FLPLBPROG ,  SW_FIELDSCLK  ,SW_LINK_A_ACTIVE  ,SW_LINK_B_ACTIVE    95  UB  1
    SWEM_CONFIG_flag: spp_swp_data_select(ccsds_data,   96  ,  8), $
    LASTFSWEVENT: spp_swp_data_select(ccsds_data,   96  ,  4), $  ;  SW_FSWSPARE ,  SW_FSWCSCI  ,  SW_BOOTMODE ,  SW_WDRSTDET  ,  SW_SWEM3P3V 1 104 UB  8
    SPANAICONFIG: spp_swp_data_select(ccsds_data,  112 ,  8), $
    SW_SPANAIMODE: spp_swp_data_select(ccsds_data,   112 ,  4), $
    SW_PRVSPANAIERR: spp_swp_data_select(ccsds_data,   116 ,  4), $
    SW_SPANAE_CONFIG: spp_swp_data_select(ccsds_data,  120 ,  8), $
    SW_SPANAEMODE: spp_swp_data_select(ccsds_data,     120 ,  4), $
    SW_PRVSPANAEERR: spp_swp_data_select(ccsds_data,  124 ,  4), $
    SW_SPANBCONFIG: spp_swp_data_select(ccsds_data,   128 ,  8), $
    SW_SPANBMODE: spp_swp_data_select(ccsds_data,    128 ,  4), $
    SW_PRVSPANBERR: spp_swp_data_select(ccsds_data,    132 ,  4), $
    SW_SPCCONFIG: spp_swp_data_select(ccsds_data,   136 ,  8), $     ;()
    SW_SPCMODE: spp_swp_data_select(ccsds_data,    136 ,  4), $
    SW_PRVSPCERR: spp_swp_data_select(ccsds_data,    140 ,  4), $
    SW_FSWSTATE: spp_swp_data_select(ccsds_data,  144 ,  16), $
    SW_EVENTCTR: spp_swp_data_select(ccsds_data,  160 ,  32), $
    SW_LASTFSWEVENT: spp_swp_data_select(ccsds_data,  192 ,  32), $
    SW_CMDCOUNTER: spp_swp_data_select(ccsds_data,  224 ,  32), $
    SW_CMDSTATUS: spp_swp_data_select(ccsds_data,   256 ,  32), $
    SW_GLOBALSTATUS: spp_swp_data_select(ccsds_data, 288 ,  32), $    ;()
    SW_GLOBAL: spp_swp_data_select(ccsds_data,   288 ,  16), $
    SW_FPGAVER: spp_swp_data_select(ccsds_data,    304 ,  8), $
    SW_STATUS: spp_swp_data_select(ccsds_data,   312 ,  8), $
    SW_CDISTATUS: spp_swp_data_select(ccsds_data,   320 ,  32), $
    SW_SRVRDPTR: spp_swp_data_select(ccsds_data,  352 ,  32), $
    SW_ARCRDPTR: spp_swp_data_select(ccsds_data,  384 ,  32), $
    SW_SSRWRADDR: spp_swp_data_select(ccsds_data,   416 ,  32), $
    SW_SSRRDADDR: spp_swp_data_select(ccsds_data,   448 ,  32), $
    SW_SPANAECTL: spp_swp_data_select(ccsds_data,   480 ,  8), $
    SW_SPANBCTL: spp_swp_data_select(ccsds_data,  488 ,  8), $
    SW_SPANAICTL: spp_swp_data_select(ccsds_data,   496 ,  8), $
    SW_SPCCTL: spp_swp_data_select(ccsds_data,  504 ,  8), $
    SW_SPANAHTRCTL: spp_swp_data_select(ccsds_data,   512 ,  8), $
    SW_SPANBHTRCTL: spp_swp_data_select(ccsds_data,   520 ,  8), $
    SW_SPANAECVRCTL: spp_swp_data_select(ccsds_data,  528 ,  8), $
    SW_SPANBCVRCTL: spp_swp_data_select(ccsds_data,   536 ,  8), $
    SW_SPANAICVRCTL: spp_swp_data_select(ccsds_data,  544 ,  8), $
    SW_SPANAEATNCTL: spp_swp_data_select(ccsds_data,  552 ,  8), $
    SW_SPANBATNCTL: spp_swp_data_select(ccsds_data,   560 ,  8), $
    SW_SPANAIATNCTL: spp_swp_data_select(ccsds_data,  568 ,  8), $
    SW_DCBOVERCUR: spp_swp_data_select(ccsds_data,  576 ,  8), $
    SEQUENCE_CNTR: sequence_cntr , $
    SEQUENCE_EXEC: sequence_EXEC,  $
    SEQUENCE_ENA:  sequence_ENA,  $
    SW_FSWVERSION: spp_swp_data_select(ccsds_data, 1096  ,  16),$
    SW_OSCPUUSAGE: spp_swp_data_select(ccsds_data,  1112  ,  8), $
    gap:0B}
  str2.gap=1
  return,str2
endif


if ccsds.pkt_size lt 42 then begin
  if debug(2) then begin
    dprint,'error',ccsds.pkt_size,dlevel=2
    hexprint,ccsds_data
    return,0
  endif
endif


 
end





