;----------------------
;
;   pro mvn_lpw_pkt_adr
;
;----------------------
;
; Start to the process to get the data into physical units
; note mvn_lpw_atr needs to be read before this one (ATR should always be created before ADR on start up)
; first varibles from only ADR is derived 
; at the end variables using ADR and ATR is derived
; 
; the some of  the ADR parameters is provided as raw and unit_converted (per discussion with David Meyer)
;
;----------------------
;  contains routines/procedures:
;  mvn_lpw_pkt_adr    
;----------------------
;  KEYWORDS
;  tplot_var = 'all' or 'sci'  => 'sci' produces tplot variables with physical units associated with them and is the default
;                              => 'all' produces all tplot variables
;----------------------
;example
; to run
;     mvn_lpw_pkt_adr,output,lpw_const,tplot_var
;----------------------
; history:
; original file atc_check made by Corinne Vannatta
; This is based on the existing file on 17 August 2011
; last change: 2013 July 11th, Chris Fowler - IF statement added to check for data.
; 11/11/13 L. Andersson clean the routine up and change limit/dlimit to fit the CDF labels introduced dy and dv, might need to be disable...
;
;----------------------
;
;*******************************************************************

pro mvn_lpw_pkt_adr, output,lpw_const,tplot_var=tplot_var

If keyword_set(tplot_var) THEN tplot_var = tplot_var ELSE tplot_var = 'sci'  ;Default setting is science tplot variables only.

IF output.p8 GT 0 THEN BEGIN  ;check we have data

      ;--------------------- Constants Used In This Routine ------------------------------------
               t_routine=SYSTIME(0) 
               t_epoch=lpw_const.t_epoch
               today_date=lpw_const.today_date
               cal_ver=lpw_const.version_calib_routine              
               filename_L0=output.filename
      ;---------         
      const_active_steps=lpw_const.nn_active_steps                             ; the last point is omitted, do not contain importnat information 
      nn_steps=lpw_const.nn_swp_steps                                          ; nn_steps  number of input in the table note the wvalues is 128-1 because 1 point the instrument wait for everything to setle
      nn_steps2=lpw_const.nn_swp                                               ;true number of steps
      nn_pktnum=lpw_const.nn_modes
      const_sign = lpw_const.sign
      const_lp_bias1_DAC=lpw_const.lp_bias1_DAC 
      const_w_bias1_DAC=lpw_const.w_bias1_DAC 
      const_lp_guard1_DAC=lpw_const.lp_guard1_DAC 
      const_w_guard1_DAC=lpw_const.w_guard1_DAC
      const_lp_stub1_DAC=lpw_const.lp_stub1_DAC 
      const_w_stub1_DAC=lpw_const.w_stub1_DAC
      const_lp_bias2_DAC=lpw_const.lp_bias2_DAC 
      const_w_bias2_DAC=lpw_const.w_bias2_DAC 
      const_lp_guard2_DAC=lpw_const.lp_guard2_DAC 
      const_w_guard2_DAC=lpw_const.w_guard2_DAC
      const_lp_stub2_DAC=lpw_const.lp_stub2_DAC 
      const_w_stub2_DAC=lpw_const.w_stub2_DAC
      const_bias1_readback=lpw_const.bias1_readback
      const_guard1_readback=lpw_const.guard1_readback
      const_stub1_readback=lpw_const.stub1_readback
      const_V1_readback =lpw_const.V1_readback
      const_bias2_readback=lpw_const.bias2_readback
      const_guard2_readback=lpw_const.guard2_readback
      const_stub2_readback=lpw_const.stub2_readback
      const_V2_readback =lpw_const.V2_readback
      ;--------------------------------------------------------------------
      nn_pktnum = output.p8                                 ; number of data packages 
      time      = double(output.SC_CLK1(output.adr_i))+output.SC_CLK2(output.adr_i)/2l^16 +t_epoch
      ;---------------------------------------------
      
      ;------------- Checks ---------------------
      if output.p8 NE n_elements(output.adr_DYN_OFFSET1) then stanna
      ;-----------------------------------------
      
              ;----------  variable: LP_BIAS1 RAW + Converted    --------------------------- 
                data =  create_struct(  $             
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum,nn_steps) ,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   fltarr(nn_pktnum,nn_steps) ,  $    ; same size as y
                                         'v',    fltarr(nn_pktnum,nn_steps) ,  $     ; same size as y
                                         'dv',   fltarr(nn_pktnum,nn_steps) )     ;1-D 
                ;-------------- derive  time/variable ----------------                          
                 data.x = time                                                                                                              
                 data.y = output.adr_lp_bias1
                 for i=0,nn_pktnum-1 do data.v(i,*)=indgen(nn_steps)   
                 data.dy=1
                 data.dv=1             
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'generated_date'  ,     today_date+' # '+t_routine, $ 
                   't_epoch'         ,     t_epoch, $    
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver ,$     
                   'cal_y_const1'    ,     'PKT level:' , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'Information from PKT: ADR', $     
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[bins]', $                     
                   'cal_v_const1'    ,     'PKT level::' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   'zsubtitle'       ,     '[RAW]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     1.2                      ,$    
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'Adr_lp_bias1'                 ,$   
                  'yrange' ,        [min(data.v),max(data.v)] ,$   
                  'ystyle'  ,       1.                       ,$  
                  'ztitle' ,        'Z-title'                ,$   
                  'zrange' ,        [min(data.y),max(data.y)],$                        
                  'spec'            ,     1, $           
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------                        
                ;-------------   RAW    ----------
                IF tplot_var EQ 'all' THEN store_data,'mvn_lpw_adr_lp_bias1_raw',data=data,limit=limit,dlimit=dlimit
                ;------------------ Converted ---------------------------
                dlimit.zsubtitle='[readback]'
                data.y = data.y*const_bias1_readback
                limit.zrange=[min(data.y),max(data.y)]
                store_data,'mvn_lpw_adr_lp_bias1',data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------
   
      
                ;----------  variable: LP_BIAS2   RAW + Converted    --------------------------- 
                data =  create_struct(      $        
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum,nn_steps) ,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   fltarr(nn_pktnum,nn_steps) ,  $    ; same size as y
                                         'v',    fltarr(nn_pktnum,nn_steps) ,  $     ; same size as y
                                         'dv',   fltarr(nn_pktnum,nn_steps) )     ;1-D 
                ;-------------- derive  time/variable ----------------   
                data.x = time                                                                                                              
                data.y = output.adr_lp_bias2
                for i=0,nn_pktnum-1 do data.v(i,*)=indgen(nn_steps)
                data.dy=1
                data.dv=1                                     
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'generated_date'  ,     today_date+' # '+t_routine, $ 
                   't_epoch'         ,     t_epoch, $    
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver ,$     
                   'cal_y_const1'    ,     'PKT level:' , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'Information from PKT: ADR', $    
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[Bin]', $        
                   'cal_v_const1'    ,     'PKT level::', $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   'zsubtitle'       ,     '[RAW]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     1.2                      ,$    
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'ADR_lp_bias2'           ,$   
                  'yrange' ,        [min(data.v),max(data.v)],$   
                  'ystyle'  ,       1.                       ,$  
                  'zrange' ,        [min(data.y),max(data.y)],$  
                  'spec'   ,        1.                       ,$      
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------                        
                ;-------------   RAW    ----------                     
                 IF tplot_var EQ 'all' THEN store_data,'mvn_lpw_adr_lp_bias2_raw',data=data,limit=limit,dlimit=dlimit
                 ;---------------- Converted --------------------
                 dlimit.zsubtitle='[readback]'
                 dlimit.cal_y_const1='PKT level:' + strcompress(const_bias2_readback,/remove_all)
                 data.y = data.y*const_bias2_readback
                 limit.zrange=[min(data.y),max(data.y)]
                 store_data,'mvn_lpw_adr_lp_bias2',data=data,limit=limit,dlimit=dlimit
                 ;---------------------------------------------
      
      
                 ;----------  variable: offset1   RAW + Converted    --------------------------- 
                 data =  create_struct(      $        
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum) ,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   fltarr(nn_pktnum) )     ;1-D 
                ;-------------- derive  time/variable ----------------                          
                 data.x = time                                                                                                               
                 data.y = output.adr_dyn_offset1    
                 data.dy=1         
                ;-------------------------------------------
                  ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'generated_date'  ,     today_date+' # '+t_routine, $ 
                   't_epoch'         ,     t_epoch, $    
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver ,$     
                   'cal_y_const1'    ,     'PKT level:'  , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'Information from PKT: ADR', $    
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[Raw]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     1.2                      ,$    
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'ADR_dyn_offset1'                 ,$   
                  'yrange' ,        [min(data.y),max(data.y)] ,$   
                  'ystyle'  ,       1.                       ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------                       
                ;-------------   RAW    ----------
                IF tplot_var EQ 'all' THEN store_data,'mvn_lpw_adr_dyn_offset1_raw',data=data,limit=limit,dlimit=dlimit
                ;---------------- Converted --------------------
                 dlimit.ysubtitle='DAC [V]'
                 dlimit.cal_y_const1='PKT level:' + strcompress(const_lp_bias1_DAC,/remove_all)
                 data.y = (data.y-const_sign)*const_lp_bias1_DAC
                 limit.yrange=[min(data.y),max(data.y)]
                 store_data,'mvn_lpw_adr_dyn_offset1',data=data,limit=limit,dlimit=dlimit
                 ;---------------------------------------------
      
      
                ;----------  variable: offset2    RAW + Converted   --------------------------- 
                data =  create_struct(    $           
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum) ,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   fltarr(nn_pktnum)  )     ;1-D 
                ;-------------- derive  time/variable ----------------                          
                data.x = time                                                                                                              
                data.y = output.adr_dyn_offset2
                data.dy=1
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'generated_date'  ,     today_date+' # '+t_routine, $ 
                   't_epoch'         ,     t_epoch, $    
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver ,$     
                   'cal_y_const1'    ,     'PKT level:'  , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                  ; 'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                  ; 'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'Information from PKT: ADR', $    
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[RAW]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     1.2                      ,$    
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'ADR_dyn_offset2'                 ,$   
                  'yrange' ,        [min(data.y),max(data.y)] ,$   
                  'ystyle'  ,       1.                       ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------                        
                ;-------------   RAW    ----------
                 IF tplot_var EQ 'all' THEN store_data,'mvn_lpw_adr_dyn_offset2_raw',data=data,limit=limit,dlimit=dlimit
                 ;---------------- Converted --------------------
                 dlimit.ysubtitle='DAC [V]'
                 dlimit.cal_y_const1='PKT level:' + strcompress(const_lp_bias2_DAC,/remove_all)
                 data.y = (data.y-const_sign)*const_lp_bias2_DAC
                 limit.yrange=[min(data.y),max(data.y)]
                 store_data,'mvn_lpw_adr_dyn_offset2',data=data,limit=limit,dlimit=dlimit
                 ;---------------------------------------------
      
      
      
                 ;------------- variable:  surface_pot1  RAW + Converted  ---------------------------
                 data =  create_struct(   $            
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum,6) ,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   fltarr(nn_pktnum,6) )     ;1-D 
                ;-------------- derive  time/variable ----------------                          
                     data.x = time     
                     data.y(*,0)=output.adr_w_bias1
                     data.y(*,1)=output.adr_w_guard1
                     data.y(*,2)=output.adr_w_stub1
                     data.y(*,3)=output.adr_w_v1
                     data.y(*,4)=output.adr_lp_guard1
                     data.y(*,5)=output.adr_lp_stub1          
                     str1=['ADR_W_BIAS1','ADR_W_GUARD1','ADR_W_STUB1','ADR_W_V1' ,'ADR_LP_GUARD1','ADR_LP_STUB1']
                     data.dy(*,0:5)=0
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'generated_date'  ,     today_date+' # '+t_routine, $ 
                   't_epoch'         ,     t_epoch, $    
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver ,$     
                   'cal_y_const1'    ,     'PKT level:' , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
                   'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'Information from PKT: ADR', $    
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[Raw]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     1.2                      ,$    
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'Different potentials 1' ,$   
                  'yrange' ,        [min(data.y),max(data.y)],$   
                  'ystyle'  ,       1.                       ,$  
                  'labels' ,        str1                      ,$  
                  'colors' ,        [1,2,3,4,5,6]            ,$   
                  'labflag' ,       1                        ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------                           
                ;-------------   RAW    ----------                  
                IF tplot_var EQ 'all' THEN store_data,'mvn_lpw_adr_surface_pot1_raw',data=data,limit=limit,dlimit=dlimit
                ;---------------- Converted --------------------
                dlimit.ysubtitle='readback [V]'
                dlimit.cal_y_const1='PKT level:' + strcompress(const_bias1_readback,/remove_all) + ' # ' + $
                                                   strcompress(const_guard1_readback,/remove_all) + ' # ' + $
                                                   strcompress(const_stub1_readback,/remove_all) + ' # ' + $
                                                   strcompress(const_V1_readback,/remove_all) + ' # ' + $
                                                   strcompress(const_guard1_readback,/remove_all) + ' # ' + $
                                                   strcompress(const_stub1_readback,/remove_all) 
                data.y(*,0)=data.y(*,0)*const_bias1_readback     ;output.adr_w_bias1*c
                data.y(*,1)=data.y(*,1)*const_guard1_readback     ;output.adr_w_guard1*C
                data.y(*,2)=data.y(*,2)*const_stub1_readback     ;output.adr_w_stub1*C
                data.y(*,3)=data.y(*,3)*const_V1_readback        ;output.adr_w_v1*const_V1_readback
                data.y(*,4)=data.y(*,4)*const_guard1_readback     ;output.adr_lp_guard1*c
                data.y(*,5)=data.y(*,5)*const_stub1_readback     ;output.adr_lp_stub1*c   
                limit.yrange=[min(data.y),max(data.y)]
                store_data,'mvn_lpw_adr_surface_pot1',data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------
      
      
                ;------------- variable:  surface_pot2   RAW + Converted  ---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum,6) ,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   fltarr(nn_pktnum,6) )     ;1-D 
                ;-------------- derive  time/variable ----------------                          
                    data.x = time    
                    data.y(*,0)=output.adr_w_bias2
                    data.y(*,1)=output.adr_w_guard2
                    data.y(*,2)=output.adr_w_stub2
                    data.y(*,3)=output.adr_w_v2
                    data.y(*,4)=output.adr_lp_guard2
                    data.y(*,5)=output.adr_lp_stub2          
                    str1=['ADR_W_BIAS2','ADR_W_GUARD2','ADR_W_STUB2','ADR_W_V2' ,'ADR_LP_GUARD2','ADR_LP_STUB2']
                    data.dy(*,0:5)=0
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'generated_date'  ,     today_date+' # '+t_routine, $ 
                   't_epoch'         ,     t_epoch, $    
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver ,$     
                   'cal_y_const1'    ,     'PKT level:'  , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                  ; 'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                  ; 'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'Information from PKT: ADR', $    
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[Raw]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     1.2                      ,$    
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'Different potentials 2'   ,$   
                  'yrange' ,        [min(data.y),max(data.y)] ,$   
                  'ystyle'  ,       1.                       ,$ 
                  'labels' ,        str1                     ,$  
                  'colors' ,        [1,2,3,4,5,6]            ,$   
                  'labflag' ,       1                        ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------                      
                ;-------------   RAW    ----------                       
                IF tplot_var EQ 'all' THEN store_data,'mvn_lpw_adr_surface_pot2_raw',data=data,limit=limit,dlimit=dlimit
                ;---------------- Converted --------------------
                dlimit.ysubtitle='readback [V]'
                dlimit.cal_y_const1='PKT level:' + strcompress(const_bias2_readback,/remove_all) + ' # ' + $
                                                   strcompress(const_guard2_readback,/remove_all) + ' # ' + $
                                                   strcompress(const_stub2_readback,/remove_all) + ' # ' + $
                                                   strcompress(const_V2_readback,/remove_all) + ' # ' + $
                                                   strcompress(const_guard2_readback,/remove_all) + ' # ' + $
                                                   strcompress(const_stub2_readback,/remove_all)
                data.y(*,0)=data.y(*,0)*const_bias2_readback     ;output.adr_w_bias2*c
                data.y(*,1)=data.y(*,1)*const_guard2_readback     ;output.adr_w_guard2*C
                data.y(*,2)=data.y(*,2)*const_stub2_readback     ;output.adr_w_stub2*C
                data.y(*,3)=data.y(*,3)*const_V2_readback        ;output.adr_w_v2*constV21_readback
                data.y(*,4)=data.y(*,4)*const_guard2_readback     ;output.adr_lp_guard2*c
                data.y(*,5)=data.y(*,5)*const_stub2_readback     ;output.adr_lp_stub2*c   
                limit.yrange=[min(data.y),max(data.y)]
                store_data,'mvn_lpw_adr_surface_pot2',data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------
      
      
      IF tplot_var EQ 'all' THEN BEGIN
            ;------------- variable:  smp_avg ---------------------------
                 data =  create_struct(  $            
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum) )     ;1-D 
                ;-------------- derive  time/variable ----------------                          
                 data.x = time                                                  
                 data.y = 2^(output.smp_avg(output.adr_i)+1)       ;from table 7.6  2^(smp_avg+1)
                ;-------------------------------------------
                     ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'generated_date'  ,     today_date+' # '+t_routine, $ 
                   't_epoch'         ,     t_epoch, $    
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver ,$     
                   'cal_y_const1'    ,     'PKT level:'  , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'Information from PKT: ADR', $    
                   'xsubtitle'       ,     '[sec]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     1.2                      ,$    
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'ADR_smp_avg'                 ,$   
                  'yrange' ,        [0,max(data.y)*1.2] ,$   
                  'ystyle'  ,       1.                       ,$  
                  'ylog'   ,        1.                       ,$      
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------                        
                store_data,'mvn_lpw_adr_smp_avg',data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------
      ENDIF
      
      IF tplot_var EQ 'all' THEN BEGIN
            ;------------- variable:  adr_mode ---------------------------
                data =  create_struct( $             
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum) )     ;1-D 
                ;-------------- derive  time/variable ----------------                          
                  data.x = time                                                      
                  data.y = output.ORB_MD(output.adr_i)
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'generated_date'  ,     today_date+' # '+t_routine, $ 
                   't_epoch'         ,     t_epoch, $    
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver ,$     
                   'cal_y_const1'    ,     'PKT level:' , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'Information from PKT: ADR', $    
                   'xsubtitle'       ,     '[sec]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     1.2                      ,$    
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'ADR_mode'                 ,$   
                  'yrange' ,        [-1,18] ,$   
                  'ystyle'  ,       1.                       ,$        
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------                        
                store_data,'mvn_lpw_adr_mode',data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------
      ENDIF
      
      
      
      ;*******************************************************************************************
      ;***************     Second half where ADR is compared with ATR    *************************
      ;*******************************************************************************************
      ;adr is always after atr, hence match to a atr before this time stamp 
      
      IF tplot_var EQ 'all' THEN BEGIN
            ;-------------- Set up the fundamental so  Expected ATR can be derived (12 different values is created below)----------------
            ;------------------------------ This is will then be compared to ADR_raw*const ----------------------------------------------
            ;----------------------------------   The time is based on the ATR time stamp ----------------------------------------------
            ;---- To get the ADR time-stamp I expect the  ATR(data0) packet first for the matching ADR(data1) packet  ------------
            get_data,'mvn_lpw_atr_dac',data=data0    ; this is what we based it on
            get_data,'mvn_lpw_adr_surface_pot1_raw',data=data1  ;data1.y(*,3)=output.adr_w_v1  
            ;-------------
                  data =  create_struct(  $             
                                         'x',    dblarr(n_elements(data0.x)) ,  $     ; double 1-D arr
                                         'y',    fltarr(n_elements(data0.x)) ,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   fltarr(n_elements(data0.x)) )     ;1-D 
                ;-------------- derive  time/variable ----------------                          
                data.x = data0.x                                                                                                              
                ;data.y =   ; will be different for all 12 variables  ;this will change below
                data.dy=-1
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'generated_date'  ,     today_date+' # '+t_routine, $ 
                   't_epoch'         ,     t_epoch, $    
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver ,$     
                   'cal_y_const1'    ,     'PKT level:' , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'Information from PKT: ADR and ATR', $    
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[DAC [V?]]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     1.2                      ,$    
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'expect_ATR_X'                 ,$   
                  'yrange' ,        [min(data.y),max(data.y)] ,$   
                  'ystyle'  ,       1.                       ,$        
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------                        
            ;-------------  
            ;---------------- Create 10 of the 12 variables ----------------------
            ;---------------- mvn_lpw_expect_ATR_bias1_wave --------------------
                                              ;mvn_lpw_atr_dac:  data0.y(*,0)=output.ATR_W_BIAS1(i)
            get_data,'mvn_lpw_atr_dac',data=data0    ; this is what we based it on
            get_data,'mvn_lpw_adr_surface_pot1_raw',data=data1  ;data1.y(*,3)=output.adr_w_v1                                   
            sort_data1=fltarr(n_elements(data0.x))     ;DO I HAVE TO DO THIS ON ALL VARIABLES BELOW?
            for i=0,n_elements(data0.x)-1 do BEGIN
                 qq=min(abs( (data0.x(i)-data1.x) +1e9*(data0.x(i)-data1.x LT 0)),nq)  ;find the right ADR(data1) match to the ATR(data0) time
                 sort_data1(i)=nq
              ;   print,i,nq,data0.x(i)-data1.x(nq),' EE ',(data0.x(i)-data1.x)
            endfor  
            dlimit.cal_y_const1='PKT level:' + strcompress(const_w_bias1_DAC,/remove_all) +' # '+ $
                                               strcompress(const_V1_readback,/remove_all)
            data.y = (data0.y(*,0)-const_sign)*const_w_bias1_DAC +(data1.y(sort_data1,3)*const_V1_readback)
            limit.yrange=[min(data.y),max(data.y)]
            limit.ytitle='expected_ATR_bias1_wave'
            store_data,'mvn_lpw_exp_ATR_bias1_wave',data=data,limit=limit,dlimit=dlimit
            ;---------------------------------------------
            ;---------------- mvn_lpw_expect_ATR_guard1_wave --------------------
                                              ;mvn_lpw_atr_dac:  data0.y(i,1)=output.ATR_W_GUARD1(i)
            get_data,'mvn_lpw_adr_surface_pot1_raw',data=data1  ;data1.y(*,3)=output.adr_w_v1              
            dlimit.cal_y_const1='PKT level:' + strcompress(const_w_guard1_DAC,/remove_all) +' # '+ $
                                               strcompress(const_V1_readback,/remove_all)                         
            data.y = (data0.y(*,1)-const_sign)*const_w_guard1_DAC +(data1.y(sort_data1,3)*const_V1_readback)
            limit.yrange=[min(data.y),max(data.y)]
            limit.ytitle='expected_ATR_guard1_wave'
            store_data,'mvn_lpw_exp_ATR_guard1_wave',data=data,limit=limit,dlimit=dlimit
            ;---------------------------------------------
            ;---------------- mvn_lpw_expect_ATR_stub1_wave --------------------
                                              ;mvn_lpw_atr_dac:  data0.y(i,2)=output.ATR_W_STUB1(i)
            get_data,'mvn_lpw_adr_surface_pot1_raw',data=data1  ;data1.y(*,3)=output.adr_w_v1                           
            data.y = (data0.y(*,2)-const_sign)*const_w_stub1_DAC +(data1.y(sort_data1,3)*const_V1_readback)
            limit.yrange=[-5,5] ;[min(data.y),max(data.y)]
            limit.ytitle='expected_ATR_stub1_wave'
            store_data,'mvn_lpw_exp_ATR_stub1_wave',data=data,limit=limit,dlimit=dlimit
            ;---------------------------------------------
            ;---------------- mvn_lpw_expect_ATR_bias2_wave --------------------
                                              ;mvn_lpw_atr_dac:  data0.y(*,6)=output.ATR_W_BIAS2(i)
            get_data,'mvn_lpw_adr_surface_pot2_raw',data=data1  ;data1.y(*,3)=output.adr_w_v2             
            dlimit.cal_y_const1='PKT level:' + strcompress(const_w_bias2_DAC,/remove_all) +' # '+ $
                                               strcompress(const_V2_readback,/remove_all)                               
            data.y = (data0.y(*,6)-const_sign)*const_w_bias2_DAC +(data1.y(sort_data1,3)*const_V2_readback)
            limit.yrange=[min(data.y),max(data.y)]
            limit.ytitle='expected_ATR_bias2_wave'
            store_data,'mvn_lpw_exp_ATR_bias2_wave',data=data,limit=limit,dlimit=dlimit
            ;---------------------------------------------
            ;---------------- mvn_lpw_expect_ATR_guard2_wave --------------------
                                              ;mvn_lpw_atr_dac:  data0.y(i,7)=output.ATR_W_GUARD2(i)
            get_data,'mvn_lpw_adr_surface_pot2_raw',data=data1  ;data1.y(*,3)=output.adr_w_v2            
            dlimit.cal_y_const1='PKT level:' + strcompress(const_w_guard2_DAC,/remove_all) +' # '+ $
                                               strcompress(const_V2_readback,/remove_all)                                
            data.y = (data0.y(*,7)-const_sign)*const_w_guard2_DAC +(data1.y(sort_data1,3)*const_V2_readback)
            limit.yrange=[min(data.y),max(data.y)]
            limit.ytitle='expected_ATR_guard2_wave'
            store_data,'mvn_lpw_exp_ATR_guard2_wave',data=data,limit=limit,dlimit=dlimit
            ;---------------------------------------------
            ;---------------- mvn_lpw_expect_ATR_stub2_wave --------------------
                                              ;mvn_lpw_atr_dac:  data0.y(i,8)=output.ATR_W_STUB2(i)
            get_data,'mvn_lpw_adr_surface_pot2_raw',data=data1  ;data1.y(*,3)=output.adr_w_v2            
            dlimit.cal_y_const1='PKT level:' + strcompress(const_w_stub2_DAC,/remove_all) +' # '+ $
                                               strcompress(const_V2_readback,/remove_all)                                
            data.y = (data0.y(*,8)-const_sign)*const_w_stub2_DAC +(data1.y(sort_data1,3)*const_V2_readback)
            limit.yrange=[-5,5] ;[min(data.y),max(data.y)]
            limit.ytitle='expected_ATR_stub2_wave'
            store_data,'mvn_lpw_exp_ATR_stub2_wave',data=data,limit=limit,dlimit=dlimit
            ;---------------------------------------------
            ;---------------- mvn_lpw_expect_ATR_bias1_LP   moved down since this will be 128 of them --------------------
            ;---------------------------------------------
            ;---------------- mvn_lpw_expect_ATR_guard1_LP --------------------
                                              ;mvn_lpw_atr_dac:  data0.y(i,4)=output.ATR_LP_GUARD1(i)
            get_data,'mvn_lpw_adr_lp_bias1_raw',data=data1           ;data1.y(*,127)=output.adr_lp_bias1(*,127)           
            dlimit.cal_y_const1='PKT level:' + strcompress(const_lp_guard1_DAC,/remove_all) +' # '+ $
                                               strcompress(const_bias1_readback,/remove_all)                             
            data.y = (data0.y(*,4)-const_sign)*const_lp_guard1_DAC +(data1.y(sort_data1,126)*const_bias1_readback)
            limit.yrange=[min(data.y),max(data.y)]
            limit.ytitle='expected_ATR_guard1_LP'
            store_data,'mvn_lpw_exp_ATR_guard1_LP',data=data,limit=limit,dlimit=dlimit
            ;---------------------------------------------
            ;---------------- mvn_lpw_expect_ATR_stub1_LP --------------------
                                              ;mvn_lpw_atr_dac:  data0.y(i,5)=output.ATR_LP_STUB1(i)
            get_data,'mvn_lpw_adr_lp_bias1_raw',data=data1           ;data1.y(*,127)=output.adr_lp_bias1(*,127)           
            dlimit.cal_y_const1='PKT level:' + strcompress(const_lp_stub1_DAC,/remove_all) +' # '+ $
                                               strcompress(const_bias1_readback,/remove_all)                               
            data.y = (data0.y(*,5)-const_sign)*const_lp_stub1_DAC +(data1.y(sort_data1,126)*const_bias1_readback)
            limit.yrange=[min(data.y),max(data.y)]
            limit.ytitle='expected_ATR_stub1_LP'
            store_data,'mvn_lpw_exp_ATR_stub1_LP',data=data,limit=limit,dlimit=dlimit
            ;---------------------------------------------
            ;---------------- mvn_lpw_expect_ATR_bias2_LP   moved down since this will be 128 of them --------------------
            ;---------------------------------------------
            ;---------------- mvn_lpw_expect_ATR_guard12_LP --------------------
                                              ;mvn_lpw_atr_dac:  data0.y(i,10)=output.ATR_LP_GUARD2(i)
            get_data,'mvn_lpw_adr_lp_bias2_raw',data=data1           ;data1.y(*,127)=output.adr_lp_bias2(*,127)           
            dlimit.cal_y_const1='PKT level:' + strcompress(const_lp_guard2_DAC,/remove_all) +' # '+ $
                                               strcompress(const_bias2_readback,/remove_all)                               
            data.y = (data0.y(*,10)-const_sign)*const_lp_guard2_DAC +(data1.y(sort_data1,126)*const_bias2_readback)
            limit.yrange=[min(data.y),max(data.y)]
            limit.ytitle='expected_ATR_guard2_LP'
            store_data,'mvn_lpw_exp_ATR_guard2_LP',data=data,limit=limit,dlimit=dlimit
            ;---------------------------------------------
            ;---------------- mvn_lpw_expect_ATR_stub2_LP --------------------
                                              ;mvn_lpw_atr_dac:  data0.y(i,11)=output.ATR_LP_STUB2(i)
            get_data,'mvn_lpw_adr_lp_bias2_raw',data=data1           ;data1.y(*,127)=output.adr_lp_bias2(*,127)           
            dlimit.cal_y_const1='PKT level:' + strcompress(const_lp_stub2_DAC,/remove_all) +' # '+ $
                                               strcompress(const_bias2_readback,/remove_all)                               
            data.y = (data0.y(*,11)-const_sign)*const_lp_stub2_DAC +(data1.y(sort_data1,126)*const_bias2_readback)
            limit.yrange=[min(data.y),max(data.y)]
            limit.ytitle='expected_ATR_stub2_LP'
            store_data,'mvn_lpw_exp_ATR_stub2_LP',data=data,limit=limit,dlimit=dlimit
            ;---------------------------------------------    
            ;---------------- Create the last 2 of the 12 variables ----------------------
            ;;LP
                ;---------------- mvn_lpw_expect_ATR_bias1_LP     128 of them --------------------
                data =  create_struct(   $           
                                         'x',    dblarr(n_elements(data0.x)) ,  $     ; double 1-D arr
                                         'y',    fltarr(n_elements(data0.x),nn_steps2) ,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   fltarr(n_elements(data0.x),nn_steps2) ,  $    ; same size as y
                                         'v',    fltarr(n_elements(data0.x),nn_steps2) ,  $     ; same size as y
                                         'dv',   fltarr(n_elements(data0.x),nn_steps2) )     ;1-D 
                ;-------------- derive  time/variable ----------------                          
                                                   ;mvn_lpw_atr_dac:  data0.y(*,3)=output.ATR_LP_BIAS1(i)
                 get_data,'mvn_lpw_atr_swp',data=data1  ;data1.y(i,*)=(output.ATR_SWP(i,*) - const_sign) *const_DAC_volt   ;  not unique to boom 1 or boom 2 
                 data.x=data0.x  ;(sort_data0)
                 print,'#################'
                 sort_data1=fltarr(n_elements(data0.x))
                 for i=0,n_elements(data0.x)-1 do BEGIN
                      qq=min(abs( (data0.x(i)-data1.x) +1e9*(data0.x(i)-data1.x LT 0)),nq)  ;find the right ADR(data1) match to the ATR(data0) time
                      sort_data1(i)=nq
                     ; print,i,nq,data0.x(i)-data1.x(nq),' EE ',(data0.x(i)-data1.x)
                 endfor                            
                 for i=0,n_elements(data0.x)-1 do begin  
                 ;change to 
                  ;where Func(TBD) is first ATR packet that has the applicable orbital mode in the tertiary header                     
                    data.y(i,*) =(data0.y(i,3)-const_sign)*const_lp_bias1_DAC+data1.y(sort_data1(i),*) + 0.  ;the '0' is because this is grounded
                    data.v(i,*)=data1.v(sort_data1(i),*)
                    data.dy(i,*)=-1
                    data.dv(i,*)=-1
                 endfor
                ;-------------------------------------------
                ;          
                dlimit.cal_y_const1='PKT level:' + strcompress(const_lp_bias1_DAC,/remove_all)                    
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     1.2                      ,$    
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'expected_ATR_bias1_LP'                 ,$   
                  'yrange' ,        [min(data.v),max(data.v)] ,$   
                  'ystyle'  ,       1.                       ,$ 
                  'ztitle' ,        'Points'                ,$   
                  'zrange' ,        [min(data.y),max(data.y)],$  
                  'spec'   ,        1.                       ,$        
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------   
                 store_data,'mvn_lpw_exp_ATR_bias1_LP',data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------
                ;---------------- mvn_lpw_expect_ATR_bias2_LP     128 of them --------------------
                                              ;mvn_lpw_atr_dac:  data0.y(*,9)=output.ATR_LP_BIAS2(i)  
                        
                 dlimit.cal_y_const1='PKT level:' + strcompress(const_lp_bias2_DAC,/remove_all)                               ;                     
                 for i=0,n_elements(data0.x)-1 do begin                       
                    data.y(i,*) =(data0.y(i,9)-const_sign)*const_lp_bias2_DAC+data1.y(sort_data1(i),*) + 0.  ;the '0' is because this is grounded
                    data.dy(i,*)=-1
                 endfor   
                 limit.zrange=[min(data.y),max(data.y)]
                 limit.ytitle='expected_ATR_bias2_LP'
                 store_data,'mvn_lpw_exp_ATR_bias2_LP',data=data,limit=limit,dlimit=dlimit
            ;---------------------------------------------
      ENDIF
ENDIF

IF output.p8 LE 0 THEN print, "mvn_lpw_adr.pro skipped as no packets found."

end
;*******************************************************************




