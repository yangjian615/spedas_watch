;----------------------
;
;   pro mvn_lpw_pkt_hsk
;
;----------------------
;
; Start to the process to get the data into physical units
; WARNING this routine has hard coded numbers need to move to the instrument_constant file.
;
;----------------------
;  contains routines/procedures:
;  mvn_lpw_pkt_hsk    
;----------------------
;  KEYWORDS
;  tplot_var = 'all' or 'sci'  => 'sci' produces tplot variables with physical units associated with them and is the default
;                              => 'all' produces all tplot variables
;----------------------
;example
; to run
;     mvn_lpw_pkt_hsk,output, tplot_var
;----------------------
; history:
; original file atc_check made by Corinne Vannatta
; This is based on the existing file on 27 july  2011
; last change: 2013, July 11th, Chris Fowler - added IF statement to check for data; added keyword tplot_var.
;11/11/13 L. Andersson clean the routine up and change limit/dlimit to fit the CDF labels introduced dy and dv, might need to be disable...
;
;----------------------
;
;*******************************************************************

pro mvn_lpw_pkt_hsk, output,lpw_const,tplot_var=tplot_var

If keyword_set(tplot_var) THEN tplot_var = tplot_var ELSE tplot_var = 'sci'  ;Default setting is science tplot variables only.

IF output.p9 GT 0 THEN BEGIN  ;check for data.
      
      ;--------------------- Constants ------------------------------------                      
               t_routine=SYSTIME(0) 
               t_epoch=lpw_const.t_epoch
               today_date=lpw_const.today_date
               cal_ver=lpw_const.version_calib_routine              
               filename_L0=output.filename
      ;------------------------------------------------------------
      nn_pktnum=output.p9                              ; number of data packages
      nn_size=nn_pktnum                                 ; number of data points 
      ;--------------------------------------------------------------------
      
      ;------------- Checks ---------------------
      if output.p9 NE n_elements(output.hsk_i) then stanna
      if n_elements(output.hsk_i) EQ 0 then print,'(mvn_lpw_hsk) No packages where found <---------------'
      ;-----------------------------------------
      
      time=double(output.SC_CLK1(output.hsk_i)+output.SC_CLK2(output.hsk_i)/2l^16)+t_epoch    
      
      IF tplot_var EQ 'all' THEN BEGIN
            ;------------- variable:  hsk ---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_size) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_size,17) ,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   fltarr(nn_size,17) )     ;1-D 
                ;-------------- derive  time/variable ----------------                          
                  data.x=time                                                                                                                 
                  for i=0,nn_pktnum-1 do begin
                      data.y(i,0)= output.Preamp_Temp1(i)  * 0.02648 + 172.9     ;* 0.0331 + 262.9  ;  ((0.003152-7.78491e-5*output.Preamp_Temp1(i))-5.815e-1)/(-2.351e-3)  ;  * 0.0331 + 262.9  ;Boom1    -0.00315212  7.78491e-05
                      data.y(i,1)= output.Preamp_Temp2(i)  * 0.024825 + 165.9    ;  * 0.0331 + 262.9  ;Boom2     -0.0153951  7.62035e-05
                 
                      data.y(i,0)= output.Preamp_Temp1(i)  * 0.02648*1.05 + 182.9     ;* 0.0331 + 262.9  ;  ((0.003152-7.78491e-5*output.Preamp_Temp1(i))-5.815e-1)/(-2.351e-3)  ;  * 0.0331 + 262.9  ;Boom1    -0.00315212  7.78491e-05
                      data.y(i,1)= output.Preamp_Temp2(i)  * 0.024825*1.05 + 175.9    ;  * 0.0331 + 262.9  ;Boom2     -0.0153951  7.62035e-05
                
                 
                        ;;     data.y(i,0) =0.78*(output.Preamp_Temp1(i)* 0.033113 + 248.68) -20 ;  
                      ;     data.y(i,1) =0.78*( output.Preamp_Temp2(i)  * 0.033113 + 248.68 ) -20 ;
                      data.y(i,0) =(output.Preamp_Temp1(i)* 0.033113 + 262.68) -6. ;  
                      data.y(i,1) =( output.Preamp_Temp2(i)  * 0.033113 + 262.68 ) -8. ;
            
            
                      ;   data.y(i,2)=output.Beb_Temp(i)          * 0.0325 + 256.29
               
                     ;  0.913043     0.931035     0.901961     0.886364
                     ;248.682
                     ;    data.y(i,0) =228.7 + (output.Preamp_Temp1(i) - 1.* (data.y(i,2)-20))  * 0.0331     ; corr the value when BEB is NE 20 C then we need to correct the preamp value  ;0.886  248.682 + 0.0331132 
                     ;    data.y(i,1) =218.2 + (output.Preamp_Temp2(i) - 9.* (data.y(i,2)-20))  * 0.0331   ;   DN * 0.0331 + 262.9 
                   
                   data.y(i,2)=output.Beb_Temp(i)          * 0.0325 + 256.29
                   data.y(i,3)=output.plus12va(i)          * 0.0004581
                   data.y(i,4)=output.minus12va(i)         * 0.0004699
                   data.y(i,5)=output.plus5va(i)           * 0.0001913
                   data.y(i,6)=output.minus5va(i)          * 0.0001923
                   data.y(i,7)=output.plus90va(i)          * 0.0077058
                   data.y(i,8)=output.minus90va(i)         * 0.0077058
                   data.y(i,9)=output.CMD_ACCEPT(i)
                   data.y(i,10)=output.CMD_REJECT(i)
                   data.y(i,11)=output.MEM_SEU_COUNTER(i)
                   data.y(i,12)=output.INT_STAT(i)
                   data.y(i,13)=output.CHKSUM(i)
                   data.y(i,14)=output.EXT_STAT(i)
                   data.y(i,15)=output.DPLY1_CNT(i)
                   data.y(i,16)=output.DPLY2_CNT(i)  
                   data.dy(i,*)=0    
                endfor
               str1=['Preamp_Temp1','Preamp_Temp2','Beb_Temp','plus12va','minus12va','plus5va','minus5va','plus90va','minus90va','CMD_ACCEPT','CMD_REJECT', $
                      'MEM_SEU_COUNTER','INT_STAT','CHKSUM','EXT_STAT','DPLY1_CNT','DPLY2_CNT']                 
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'generated_date'  ,     today_date+' # '+t_routine, $ 
                   't_epoch'         ,     t_epoch, $    
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver ,$     
                   'cal_y_const1'    ,     'PKT level: WARNING VOLTAGE CALIB hardcoded!!!!!'  ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                  ; 'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
                  ; 'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'Information from PKT: HSK', $     
                   'xsubtitle'       ,     '[sec]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     1.2                      ,$    
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'HSK'                 ,$ 
                  'labels' ,        str1                    ,$  
                  'labflag' ,       1                        ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,    [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------           
                 store_data,'mvn_lpw_hsk',data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------
            
            
                ;------------- variable:  hsk_temp ---------------------------
                data1 =  create_struct(   $           
                                         'x',    dblarr(nn_size) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_size,3) )     ;1-D 
                ;-------------- derive  time/variable ----------------                                                                                             
                 data1.x=data.x
                 data1.y(*,0:2)=data.y(*,0:2)     
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
                   'cal_source'      ,     'Information from PKT: HSK', $   
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[C]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     1.2                      ,$    
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'HSK Temp'                 ,$   
                  'yrange' ,        [min(data.y),max(data.y)] ,$   
                  'ystyle'  ,       1.                       ,$  
                  'labels' ,        str1(0:2)                ,$  
                  'colors' ,        [2,4,6]                  ,$   
                  'labflag' ,       1                        ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------  
                store_data,'mvn_lpw_hsk_temp',data=data1,limit=limit,dlimit=dlimit
                ;---------------------------------------------
 
 
            
                ;------------- variable:  hsk_12v ---------------------------   
                data1 =  create_struct(   $           
                                         'x',    dblarr(nn_size) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_size,2)  )     ;1-D 
                ;-------------- derive  time/variable ----------------                                                                                             
                data1.x=data.x
                data1.y(*,0:1)=abs(data.y(*,3:4))                 
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
                   'cal_source'      ,     'Information from PKT: HSK', $   
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[Volt]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     1.2                      ,$    
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'HSK - abs(12V)'         ,$   
                  'yrange' ,        [min(data.y),max(data.y)] ,$   
                  'ystyle'  ,       1.                       ,$  
                  'labels' ,        str1(3:4)                 ,$  
                  'colors' ,        [4,6]                      ,$   
                  'labflag' ,       1                        ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,    [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------    
                store_data,'mvn_lpw_hsk_12v',data=data1,limit=limit,dlimit=dlimit
                ;---------------------------------------------
            
                ;------------- variable:  hsk_5v ---------------------------
                 data1 =  create_struct(   $           
                                         'x',    dblarr(nn_size) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_size,2)  )     ;1-D 
                ;-------------- derive  time/variable ----------------                                                                                             
                data1.x=data.x
                data1.y(*,0:1)=abs(data.y(*,5:6))                 
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
                   'cal_source'      ,     'Information from PKT: HSK', $   
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[Volt]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     1.2                      ,$    
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'HSK - abs(5V)'         ,$   
                  'yrange' ,        [min(data.y),max(data.y)] ,$   
                  'ystyle'  ,       1.                       ,$  
                  'labels' ,        str1(5:6)                 ,$  
                  'colors' ,        [4,6]                      ,$   
                  'labflag' ,       1                        ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,    [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------    
                store_data,'mvn_lpw_hsk_5v',data=data1,limit=limit,dlimit=dlimit
                ;---------------------------------------------
            
            
             ;------------- variable:  hsk_90v ---------------------------
                 data1 =  create_struct(   $           
                                         'x',    dblarr(nn_size) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_size,2)  )     ;1-D 
                ;-------------- derive  time/variable ----------------                                                                                             
                data1.x=data.x
                data1.y(*,0:1)=abs(data.y(*,7:8))                 
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
                   'cal_source'      ,     'Information from PKT: HSK', $   
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[Volt]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     1.2                      ,$    
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'HSK - abs(90V)'         ,$   
                  'yrange' ,        [min(data.y),max(data.y)] ,$   
                  'ystyle'  ,       1.                       ,$  
                  'labels' ,        str1(7:8)                 ,$  
                  'colors' ,        [4,6]                      ,$   
                  'labflag' ,       1                        ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,    [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------       
                store_data,'mvn_lpw_hsk_90v',data=data1,limit=limit,dlimit=dlimit
                ;---------------------------------------------
            
            
                ;------------- variable:  smp_avg ---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum))     ;1-D 
                ;-------------- derive  time/variable ----------------                                            
                  data.x=time                                                   
                  data.y=2^(output.smp_avg(output.hsk_i)+1)       ; from ICD section 7.6
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
                   'cal_source'      ,     'Information from PKT: HSK', $   
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[No]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     1.2                      ,$    
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'HSK smp_avg'                 ,$     
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------                       
                store_data,'mvn_lpw_hsk_smp_avg',data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------
      ENDIF
ENDIF

IF output.p9 LE 0 THEN print, "mvn_lpw_hsk.pro skipped as no data packet found."

end
;*******************************************************************







