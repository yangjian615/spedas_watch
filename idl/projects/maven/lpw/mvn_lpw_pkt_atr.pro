;;+
;PROCEDURE:   mvn_lpw_pkt_atr
;PURPOSE:
;  Takes the decumuted data (L0) from the ATR packet, Active Table Read back
;  and turn it the data into tplot structures
;  NOTE mvn_lpw_pkt_atr needs to be read before mvn_lpw_pkt_adr
; ATR packet will only be provided as raw values expect for the 
; sweep values that is derived into units of Volt
;
;USAGE:
;  mvn_lpw_pkt_atr,output,lpw_const,tplot_var
;
;INPUTS:
;       output:         L0 data 
;       lpw_const:      information of lpw calibration etc
;
;KEYWORDS:
;       tplot_var   'all' or 'sci'  'sci' produces tplot variables that have physical units associated with them.
;                                   'all' produces all tplot variables.
;
;CREATED BY:   Laila Andersson 17 august 2011 
;FILE: mvn_lpw_pkt_atr.pro
;VERSION:   1.1
;LAST MODIFICATION:   
;07/11/13 - Chris Fowler - added IF statement checking for data in output.p6, and keyword tplot_var.
;05/16/13
;11/11/13 L. Andersson clean the routine up and change limit/dlimit to fit the CDF labels, since this is a read back of tables no dv or dy information exist
;-

pro mvn_lpw_pkt_atr,output,lpw_const,tplot_var=tplot_var

If keyword_set(tplot_var) THEN tplot_var = tplot_var ELSE tplot_var = 'sci'  ;Default setting is science tplot variables only.

IF output.p6 GT 0 THEN BEGIN  ;Check we have data.
      
      ;--------------------- Constants Used In This Routine  ------------------------------------                            
               t_routine=SYSTIME(0) 
               t_epoch=lpw_const.t_epoch
               today_date=lpw_const.today_date
               cal_ver=lpw_const.version_calib_routine              
               filename_L0=output.filename
      ;---------         
      nn_swp=lpw_const.nn_swp 
      nn_dac=lpw_const.nn_dac
      const_sign = lpw_const.sign
      const_lp_bias1_DAC = lpw_const.lp_bias1_DAC 
      ;--------------------------------------------------------------------
      ;----------  variable: --------------------
      nn_pktnum=output.p6                               ; number of data packages 
      time = double(output.SC_CLK1(output.atr_i))+output.SC_CLK2(output.atr_i)/2l^16 +t_epoch
      ;-----------------------------------------
      
      ;------------- Checks ---------------------
      if output.p6 NE n_elements(output.atr_i) then stanna
      if n_elements(output.atr_i) EQ 0 then print,'(mvn_lpw_atr) No packages where found <---------------'
      ;-----------------------------------------
      
                
                 ;------------- variable:  atr_swp_table ---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum,nn_swp) ,  $     ; most of the time float and 1-D or 2-D
                                         'v',    fltarr(nn_pktnum,nn_swp)  )     ;1-D 
                ;-------------- derive  time/variable ----------------                          
                data.x = time
                for i=0,nn_pktnum-1 do begin  
                     data.y(i,*)=(output.ATR_SWP(i,*) - const_sign) * const_lp_bias1_DAC  ;output.ATR_SWP(i,flip_the_order)
                     data.v(i,*)=indgen(nn_swp) 
                endfor             
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'generated_date'  ,     today_date+' # '+t_routine, $ 
                   't_epoch'         ,     t_epoch, $    
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver ,$     
                   'cal_y_const1'    ,     'PKT level:'+strcompress(const_sign,/remove_all)+' # '+  $
                                                        strcompress(const_lp_bias1_DAC,/remove_all) ,$  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'Information from PKT: ATR', $     
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[bin number]', $        
                   'cal_v_const1'    ,     'PKT level:'  ,$; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   'zsubtitle'       ,     '[V]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     1.2                      ,$    
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'ATR_sweep'                 ,$   
                  'yrange' ,        [min(data.v,/nan),max(data.v,/nan)]+1 ,$   
                  'ystyle'  ,       1.                       ,$     
                  'ylog'   ,        1.                       ,$ 
                  'ztitle' ,        'Z-title'                ,$   
                  'zrange' ,        [min(data.y,/nan),max(data.y,/nan)] +1,$     
                  'zlog'   ,        1.                       ,$  
                  'spec'   ,        1.                       ,$ 
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------                        
                store_data,'mvn_lpw_atr_swp',data=data,limit=limit,dlimit=dlimit
               ;---------------------------------------------
     
      
      IF tplot_var EQ 'all' THEN BEGIN          
               ;------------- variable:  atr_swp_table_raw --------------------------- 
               data =  create_struct(     $         
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum,nn_swp) ,  $     ; most of the time float and 1-D or 2-D
                                         'v',    fltarr(nn_pktnum,nn_swp) )    
                ;-------------- derive  time/variable ----------------                          
                data.x = time
                for i=0,nn_pktnum-1 do begin  
                     data.y(i,*)=output.ATR_SWP(i,*)   ;raw data
                     data.v(i,*)=indgen(nn_swp) 
                endfor               
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'generated_date'  ,     today_date+' # '+t_routine, $ 
                   't_epoch'         ,     t_epoch, $    
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver ,$     
                   'cal_y_const1'    ,     'PKT level:' ,$  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
;                   'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                 ;  'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'Information from PKT: ATR', $     
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[bin number]', $               
                   'cal_v_const1'    ,     'PKT level:' ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   'zsubtitle'       ,     '[raw value]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     1.2                      ,$    
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'ATR_sweep'                 ,$   
                  'yrange' ,        [min(data.v,/nan),max(data.v,/nan)]+1  ,$   
                  'ystyle'  ,       1.                       ,$  
                  'ztitle' ,        'Z-title'                ,$   
                  'zrange' ,        [min(data.y,/nan),max(data.y,/nan)]+1,$                       
                  'spec'            ,     1, $          
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------                        
                store_data,'mvn_lpw_atr_swp_raw',data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------           
      ENDIF
      
      
      IF tplot_var EQ 'all' THEN BEGIN
                ;------------- variable:  atr_dac_table ---------------------------
                data =  create_struct(     $         
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum,nn_dac) ,  $     ; most of the time float and 1-D or 2-D
                                         'v',    fltarr(nn_pktnum,nn_dac) )     ;1-D 
                ;-------------- derive  time/variable ----------------                          
                data.x = time    
                for i=0,nn_pktnum-1 do begin  
                  data.y(i,0)=output.ATR_W_BIAS1(i) 
                  data.y(i,1)=output.ATR_W_GUARD1(i)
                  data.y(i,2)=output.ATR_W_STUB1(i)
                  data.y(i,3)=output.ATR_LP_BIAS1(i) 
                  data.y(i,4)=output.ATR_LP_GUARD1(i)
                  data.y(i,5)=output.ATR_LP_STUB1(i) 
                  data.y(i,6)=output.ATR_W_BIAS2(i) 
                  data.y(i,7)=output.ATR_W_GUARD2(i) 
                  data.y(i,8)=output.ATR_W_STUB2(i) 
                  data.y(i,9)=output.ATR_LP_BIAS2(i) 
                  data.y(i,10)=output.ATR_LP_GUARD2(i) 
                  data.y(i,11)=output.ATR_LP_STUB2(i)
                  data.v(i,*)=indgen(nn_dac)     
                 endfor
                 str1= ['W_BIAS1','W_GUARD1','W_STUB1','LP_BIAS1','LP_GUARD1','LP_STUB1', $
                     'W_BIAS2','W_GUARD2','W_STUB2','LP_BIAS2','LP_GUARD2','LP_STUB2'] 
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'generated_date'  ,     today_date+' # '+t_routine, $ 
                   't_epoch'         ,     t_epoch, $    
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver ,$     
                   'cal_y_const1'    ,     'Used :' ,$  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'Information from PKT: ATR', $     
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[RAW]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     1.2                      ,$    
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'ATR_DAC_table'          ,$   
                  'yrange' ,        [0,12]                   ,$   
                  'ystyle'  ,       1.                       ,$  
                  'labels' ,        str1                     ,$   
                  'labflag' ,       1                        ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,    [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------                              
                store_data,'mvn_lpw_atr_dac',data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------
      ENDIF
      
      IF tplot_var EQ 'all' THEN BEGIN
                ;------------- variable:  rpt_rate ---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum))    ; same size as y
                ;-------------- derive  time/variable ----------------                          
                data.x=time                                                   
                data.y=2^(output.smp_avg(output.atr_i)+1)       ; from table 7.1.1 2^(rpt_rate_dummy+1) * MCU                
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'generated_date'  ,     today_date+' # '+t_routine, $ 
                   't_epoch'         ,     t_epoch, $    
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver ,$     
                   'cal_y_const1'    ,     'Used : MCU=1' ,$  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                  ; 'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                  ; 'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'Information from PKT: ATR', $     
                   'xsubtitle'       ,     '[sec]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     1.2                      ,$    
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'atr_rpt_rate * MCU'                 ,$   
                  'yrange' ,        [0,max(data.y)*1.2] ,$   
                  'ystyle'  ,       1.                       ,$        
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------                        
                store_data,'mvn_lpw_atr_rpt_rate',data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------
      ENDIF
      
      IF tplot_var EQ 'all' THEN BEGIN
                ;------------- variable:  atr_mode ---------------------------
                data =  create_struct(  $            
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum)  )    
                ;-------------- derive  time/variable ----------------                          
                 data.x = time                                                      
                 data.y = output.ORB_MD(output.atr_i)           
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'generated_date'  ,     today_date+' # '+t_routine, $ 
                   't_epoch'         ,     t_epoch, $    
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver ,$     
                   'cal_y_const1'    ,     'Used :'  ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                  ; 'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                  ; 'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'Information from PKT: ATR', $     
                   'xsubtitle'       ,     '[sec]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     1.2                      ,$    
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'ATR_mode'               ,$   
                  'yrange' ,        [-1,18]                  ,$   
                  'ystyle'  ,       1.                       ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,    [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------                        
                store_data,'mvn_lpw_atr_mode',data=data,limit=limit,dlimit=dlimit
               ;---------------------------------------------
      ENDIF
ENDIF

IF output.p6 LE 0 THEN print, "mvn_lpw_atr.pro skipped as no packets found."

end
;*******************************************************************






