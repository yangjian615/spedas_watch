;;+
;PROCEDURE:   mvn_lpw_pkt_swp
;PURPOSE:
;  Takes the decumuted data (L0) from the SWP1 or SWP2 packet
;  and turn it into L1 and L2 data in tplot structures
;
;USAGE:
;  mvn_lpw_pkt_swp,output,lpw_const, swpn, tplot_var
;
;INPUTS:
;       output:         L0 data 
;       lpw_const:      information of lpw calibration etc
;       swpn:           sweep number; = 1 or 2
;
;KEYWORDS:
;       tplot_var = 'all' or 'sci'     => 'sci' produces tplot variables which have physical units associated with them and is the default
;                                      => 'all' produces all tplot variables
;
;CREATED BY:   Laila Andersson 17 august 2011 
;FILE: mvn_lpw_pkt_swp.pro
;VERSION:   1.1
;LAST MODIFICATION:   05/16/13
;                     2013, July 12th, Chris Fowler - combined mvn_lpw_swp1.pro and mvn_lpw_swp2.pro into this one file; added
;                           keyword tplot_var                           
;11/11/13 L. Andersson clean the routine up and change limit/dlimit to fit the CDF labels introduced dy and dv, might need to be disable...
;
;-

pro mvn_lpw_pkt_swp, output,lpw_const,swpn,tplot_var=tplot_var

If keyword_set(tplot_var) THEN tplot_var = tplot_var ELSE tplot_var = 'sci'  ;Default setting is science tplot variables only.

;Check if we have data packets before continuing:
IF (swpn EQ 1 AND output.p10 GT 0) OR $
   (swpn EQ 2 AND output.p11 GT 0) THEN BEGIN
               
               ;--------------------- Constants ------------------------------------
               t_routine=SYSTIME(0) 
               t_epoch=lpw_const.t_epoch
               today_date=lpw_const.today_date
               cal_ver=lpw_const.version_calib_routine              
               filename_L0=output.filename
                ;---------         
                subcycle_length=lpw_const.sc_lngth
                sample_aver=lpw_const.sample_aver
                nn_steps=long(lpw_const.nn_swp) 
                ;--------------------------------------------------------------------     
      
      CASE swpn OF 
         1: BEGIN
            ;--------------------- Constants SWP 1 specific ------------------------------------
            const_I_readback= lpw_const.I1_readback
            const_V_readback= lpw_const.V2_readback
            const_lp_bias_DAC = lpw_const.lp_bias1_DAC 
            ;--------------------------------------------------------------------
            output_swp_i = output.swp1_i
            output_swp_ii = output.swp1_I1
            output_swp_V = output.swp1_V2
            output_I_ZERO = output.I_ZERO1
            output_swp_dyn_offset = output.swp1_dyn_offset1  
            nn_pktnum = output.p10
            vnum = 2  ;voltage number (2 for swp1; 1 for swp2)   
         END
         2: BEGIN
            ;--------------------- Constants SWP 2 specific------------------------------------
            const_I_readback= lpw_const.I2_readback
            const_V_readback= lpw_const.V1_readback
            const_lp_bias_DAC = lpw_const.lp_bias2_DAC 
            ;--------------------------------------------------------------------
            output_swp_i = output.swp2_i
            output_swp_ii = output.swp2_I2
            output_swp_V = output.swp2_V1
            output_I_ZERO = output.I_ZERO2
            output_swp_dyn_offset = output.swp2_dyn_offset2  
            nn_pktnum = output.p11
            vnum = 1  ;voltage number (2 for swp1; 1 for swp2)   
         END
      ENDCASE
      ;--------------------------------------------------------------------      
      nn_pktnum = nn_pktnum                                         ; number of data packages 
      nn_size   = long(nn_pktnum)*long(nn_steps)                     ; number of data points
      dt=subcycle_length(output.mc_len(output_swp_i))/nn_steps
      t_s=subcycle_length(output.mc_len(output_swp_i))*3./128       ;this is how long time each measurement point took
                                                                     ;the time in the header is associated with the last point in the measurement
                                                                     ;therefore is the time corrected by the thength of the subcycle_length
      time      = double(output.SC_CLK1(output_swp_i)) + output.SC_CLK2(output_swp_i)/2l^16+t_epoch-t_s-subcycle_length(output.mc_len(output_swp_i))
      t_routine=SYSTIME(0)                                           ; date and hour of when the paket was decompressed as a string
      ;---------------------------------------------
      
      ;------------- Checks ---------------------
      if output.p10 NE n_elements(output_swp_i) AND swpn EQ 1 then stanna
      if n_elements(output_swp_i) EQ 0 AND swpn EQ 1 then print,'(mvn_lpw_swp1) No packages where found <---------------'
      if output.p11 NE n_elements(output_swp_i) AND swpn EQ 2 then stanna
      if n_elements(output_swp_i) EQ 0 AND swpn EQ 2 then print,'(mvn_lpw_swp2) No packages where found <---------------'
      ;-----------------------------------------
      
    
            ;--------------- variable: V   ------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_size) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_size) ,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   fltarr(nn_size) )     ;1-D 
                ;-------------- derive  time/variable ----------------                          
                for i=0L,nn_pktnum-1 do begin
                      data.x(nn_steps*i:nn_steps*(i+1)-1) = time(i) + dindgen(nn_steps) * dt(i)                                                                                                                  
                      data.y(nn_steps*i:nn_steps*(i+1)-1) = output_swp_V(i, *) * const_V_readback 
                      data.dy(nn_steps*i:nn_steps*(i+1)-1) = 0
                endfor                      
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'generated_date'  ,     today_date+' # '+t_routine, $ 
                   't_epoch'         ,     t_epoch, $    
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver ,$     
                   'cal_y_const1'    ,     'PKT level:' + strcompress(const_V_readback ,/remove_all) ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'Information from PKT: SWP'+strtrim(swpn,2), $     
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[Volt]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$    
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'mvn_lpw_swp'+strtrim(swpn,2)+'_V'+strtrim(vnum,2),$   
                  'yrange' ,        [min(data.y),max(data.y)] ,$   
                  'ystyle'  ,       1.                       ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,    [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------                               
                   store_data,'mvn_lpw_swp'+strtrim(swpn,2)+'_V'+strtrim(vnum,2),data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------
 
      
      IF tplot_var EQ 'all' THEN BEGIN
                ;--------------- variable:  I ---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_size) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_size,2) ,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   fltarr(nn_size,2)  )     ;1-D 
                ;-------------- derive  time/variable ----------------                                                                                                                     
                 for i=0L,nn_pktnum-1 do begin
                   data.x(nn_steps*i:nn_steps*(i+1)-1)= time(i) + dindgen(nn_steps)*dt(i) 
                   data.y(nn_steps*i:nn_steps*(i+1)-1,0) = (output_swp_ii(i,*)-output_I_ZERO(i)*16)*const_I_readback   ;with zero correction
                   data.y(nn_steps*i:nn_steps*(i+1)-1,1) = (output_swp_ii(i,*))*const_I_readback                        ;without zero correction
                   data.dy(nn_steps*i:nn_steps*(i+1)-1,0) = 0
                   data.dy(nn_steps*i:nn_steps*(i+1)-1,1) = 0
                endfor
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'generated_date'  ,     today_date+' # '+t_routine, $ 
                   't_epoch'         ,     t_epoch, $    
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver ,$     
                   'cal_y_const1'    ,     'PKT level:' +strcompress(const_I_readback,/remove_all) ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'Information from PKT: SWP'+strtrim(swpn,2), $     
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[I]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$    
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,         'mvn_lpw_swp'+strtrim(swpn,2)+'_I'+strtrim(swpn,2),$   
                  'yrange' ,        [min(data.y),max(data.y)] ,$   
                  'ystyle'  ,       1.                       ,$  
                  'labels' ,        ['i!Dcorr!N','no i!Dzero!N'],$  
                  'colors' ,        [0,6]                      ,$   
                  'labflag' ,       1                        ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store -------------------- 
                store_data,'mvn_lpw_swp'+strtrim(swpn,2)+'_I'+strtrim(swpn,2),data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------
      ENDIF
      
      ; IF tplot_var EQ 'all' THEN BEGIN   ;< ---- always produce this variable    
            ;--------------- variable:  offsets ---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum ,2) ,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   fltarr(nn_pktnum ,2) )     ;1-D 
                ;-------------- derive  time/variable ----------------                          
                data.x = time                                                                                                                
                for i=0,nn_pktnum-1 do begin
                  data.y(i,0) = output_I_ZERO(i)     ; RAW ADC value
                  data.y(i,1) = output_swp_dyn_offset(i)  * const_lp_bias_DAC      ; Volt 
                  data.dy(i,0) = 0
                  data.dy(i,1) = 0
                endfor  
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'generated_date'  ,     today_date+' # '+t_routine, $ 
                   't_epoch'         ,     t_epoch, $    
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver ,$     
                   'cal_y_const1'    ,     'PKT level:'+strcompress(const_lp_bias_DAC,/remove_all)  ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'Information from PKT: SWP'+strtrim(swpn,2), $     
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[Raw/Volt]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$     
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'I_zero and Dyn_offset',$   
                  'yrange' ,        [min(data.y),max(data.y)] ,$   
                  'ystyle'  ,       1.                       ,$  
                  'labels' ,        ['i!Dzero!N','Dyn!Doffset!N'],$  
                  'colors' ,        [0,6]                      ,$   
                  'labflag' ,       1                        ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------                               
                store_data,'mvn_lpw_swp'+strtrim(swpn,2)+'_offset',data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------
    ;    ENDIF   
      
      
      IF tplot_var EQ 'all' THEN BEGIN
                ;--------------- variable:  IV-bin-spectra ---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum,nn_steps) ,  $     ; most of the time float and 1-D or 2-D
                                         'v',    fltarr(nn_pktnum,nn_steps) ,  $     ; same size as y
                                         'dy',   fltarr(nn_pktnum,nn_steps) ,  $    ; same size as y
                                         'dv',   fltarr(nn_pktnum,nn_steps) )     ;1-D 
                ;-------------- derive  time/variable ----------------                                                                                                                                                            
                  data.x = time
                  print,'(mvn_lpw_swp'+strtrim(swpn,2)+') This is using bin to each current, not sorted in any manner'
                  for i=0,nn_pktnum-1 do  begin
                      data.y(i,*)=(output_swp_ii(i,*)-output_I_ZERO(i)*16)*const_I_readback   ;should be the same as for I1
                      data.v(i,*)=indgen(nn_steps)                                 ;the potential-sweep based on the atr, do not use output information!!!
                  endfor
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'generated_date'  ,     today_date+' # '+t_routine, $ 
                   't_epoch'         ,     t_epoch, $    
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver ,$     
                   'cal_y_const1'    ,     'PKT level:'+strcompress(const_I_readback,/remove_all)  ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'Information from PKT: SWP'+strtrim(swpn,2), $     
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[Bin number]', $        
                   'cal_v_const1'    ,     'PKT level::' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   'zsubtitle'       ,     '[I-zero raw units]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$     
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'Bin'                 ,$   
                  'yrange' ,        [min(data.v),max(data.v)] ,$   
                  'ystyle'  ,       1.                       ,$
                  'ztitle' ,        'Current (corr i_zero)'         ,$   
                  'zrange' ,        [min(data.y),max(data.y)],$  
                  'spec'   ,        1.                       ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------                        
                 store_data,'mvn_lpw_swp'+strtrim(swpn,2)+'_IV_bin',data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------
      ENDIF
      
   
    ; IF tplot_var EQ 'all' THEN BEGIN   ;< ---- always produce this variable          
            get_data,'mvn_lpw_atr_swp',data=data2 
            tmp=size(data2)
            if tmp(0) EQ 1 then begin           ;<---------- double check that atr information exists 
              ;--------------- variable:  IV-spectra ---------------------------
                            data =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum,nn_steps) ,  $     ; most of the time float and 1-D or 2-D
                                         'v',    fltarr(nn_pktnum,nn_steps) ,  $     ; same size as y
                                         'dy',   fltarr(nn_pktnum,nn_steps) ,  $    ; same size as y
                                         'dv',   fltarr(nn_pktnum,nn_steps) )     ;1-D 
                ;-------------- derive  time/variable ----------------                                                                                                                                                            
                  data.x = time
                  print,'(mvn_lpw_swp'+strtrim(swpn,2)+') Warning need to verify that the use of the sweep table is correct!!!!' 
                  get_data,'mvn_lpw_atr_swp',data=data2,dlimit=dlimit2                        ;this is what is stored as the sweep, to make sure I do not twist the orded in two different places  
                  get_data,'mvn_lpw_swp'+strtrim(swpn,2)+'_offset',data=data3,dlimit=dlimit3
                  time_max=0    
                  for i=0,nn_pktnum-1 do  begin
                      tmp=min(data.x(i)-data2.x +1e9*(data.x(i)-data2.x LT -0.2),ii)
                      tmp=sort(data2.y(ii,*)) 
                      data.y(i,*) = (output_swp_ii(i,tmp)-output_I_ZERO(i)*16)*const_I_readback  ;should be the same as for I1
                      data.v(i,*) = data2.y(ii,tmp) + data3.y(i,1)   ;*const_lp_bias_DAC 
                      ;error analysis just based on the information of the packet
                      data.dy(i,*)=0                               ;     <----------just fejk some non zero points
                      data.dv(i,*)=0                              ;     <----------just fejk some non zero points
                  endfor  
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'generated_date'  ,     today_date+' # '+t_routine, $ 
                   't_epoch'         ,     t_epoch, $    
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver ,$     
                   'cal_y_const1'    ,     'PKT level:'+strcompress(const_I_readback,/remove_all)  ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'Information from PKT: SWP'+strtrim(swpn,2)+' and ATR', $     
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[A?]', $        
                   'cal_v_const1'    ,     'PKT level::'+strcompress(dlimit3.cal_y_const1,/remove_all) +' # '  $  
                                                        +strcompress(dlimit2.cal_y_const1,/remove_all), $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   'zsubtitle'       ,     '[I-zero raw units]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$     
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'Sweep from ATR-file'     ,$   
                  'yrange' ,        [min(data.v),max(data.v)] ,$   
                  'ystyle'  ,       1.                       ,$
                  'ztitle' ,        'Current (corr i_zero)'   ,$   
                  'zrange' ,        [min(data.y),max(data.y)],$  
                  'spec'   ,        1.                       ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------    
                 store_data,'mvn_lpw_swp'+strtrim(swpn,2)+'_IV',data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------
            endif
    ;  ENDIF
      
      IF tplot_var EQ 'all' THEN BEGIN
            ;------------- variable:  swp_mc_len ---------------------------    
                data =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum) )    ;1-D 
                ;-------------- derive  time/variable ---------------- 
                 data.x = time                                                     
                 data.y = subcycle_length(output.mc_len(output_swp_i))*4.   ;ORB_MD 
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'generated_date'  ,     today_date+' # '+t_routine, $ 
                   't_epoch'         ,     t_epoch, $    
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver ,$     
                   'cal_y_const1'    ,     'PKT level:'  ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'Information from PKT: SWP'+strtrim(swpn,2), $     
                   'xsubtitle'       ,     '[sec]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$     
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'swp'+strtrim(swpn,2)+'_mc_len',$   
                  'yrange' ,        [0,300]                 ,$   
                  'ystyle'  ,       1.                       ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------    
                  store_data,'mvn_lpw_swp'+strtrim(swpn,2)+'_mc_len',data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------
      ENDIF
      
      IF tplot_var EQ 'all' THEN BEGIN
           ;------------- variable:  smp_avg ---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum) )    ;1-D 
                ;-------------- derive  time/variable ----------------  
                data.x = time                                                  
                data.y = sample_aver(output.smp_avg(output_swp_i))       ; from ICD table  
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'generated_date'  ,     today_date+' # '+t_routine, $ 
                   't_epoch'         ,     t_epoch, $    
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver ,$     
                   'cal_y_const1'    ,     'PKT level:'  ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'Information from PKT: SWP'+strtrim(swpn,2), $     
                   'xsubtitle'       ,     '[sec]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$     
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'swp'+strtrim(swpn,2)+'_smp_avg',$   
                  'yrange' ,        [0,2050]                 ,$   
                  'ystyle'  ,       1.                       ,$      
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------                        
                  store_data,'mvn_lpw_swp'+strtrim(swpn,2)+'_smp_avg',data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------
      ENDIF
      
      IF tplot_var EQ 'all' THEN BEGIN
                ;------------- variable:  swp_mode ---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum))     ;1-D 
                ;-------------- derive  time/variable ----------------   
                  data.x = time                                                     
                  data.y = output.orb_md(output_swp_i)   ;ORB_MD   
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'generated_date'  ,     today_date+' # '+t_routine, $ 
                   't_epoch'         ,     t_epoch, $    
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver ,$     
                   'cal_y_const1'    ,     'PKT level:'  ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'Information from PKT: SWP'+strtrim(swpn,2), $     
                   'xsubtitle'       ,     '[sec]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$     
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'swp'+strtrim(swpn,2)+'_mode',$   
                  'yrange' ,        [-1,18]                  ,$   
                  'ystyle'  ,       1.                       ,$        
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store -------------------- 
                store_data,'mvn_lpw_swp'+strtrim(swpn,2)+'_mode',data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------
      ENDIF
ENDIF

IF swpn EQ 1 AND output.p10 LE 0 THEN print, "mvn_lpw_pkt_swp(1) skipped as no packets found."
IF swpn EQ 2 AND output.p11 LE 0 THEN print, "mvn_lpw_pkt_swp(2) skipped as no packets found."

end
;*******************************************************************









