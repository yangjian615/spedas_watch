;----------------------
;
;   pro mvn_lpw_pkt_euv
;
;----------------------
;
; Start to the process to get the data into physical units
;
;----------------------
;  contains routines/procedures:
;  mvn_lpw_pkt_euv    
;----------------------
;  KEYWORDS
;  tplot_var =  'all' or 'sci'   => 'sci' produces tplot variables with physical units associated with them, sci is the default setting
;                                => 'all' produces all tplot variables
;----------------------
;example
; to run
;     mvn_lpw_pkt_euv,output,tplot_var
;----------------------
; history:
; original file euv_check made by Corinne Vannatta
; This is based on the existing file on 27 July  2011
; last change: 2013, July 11th, Chris Fowler - IF statement added to check for data; added keyword tplot_var
; 11/11/13 L. Andersson clean the routine up and change limit/dlimit to fit the CDF labels introduced dy and dv, might need to be disable...
; 
;----------------------
;
;*******************************************************************

pro mvn_lpw_pkt_euv, output,lpw_const,tplot_var=tplot_var

If keyword_set(tplot_var) THEN tplot_var = tplot_var ELSE tplot_var = 'sci'  ;Default setting is science tplot variables only.

IF output.p7 GT 0 THEN BEGIN  ;Check we have data 

      ;--------------------- Constants ------------------------------------                   
               t_routine=SYSTIME(0) 
               t_epoch=lpw_const.t_epoch
               today_date=lpw_const.today_date
               cal_ver=lpw_const.version_calib_routine              
               filename_L0=output.filename
      ;---------              
      nn_steps=lpw_const.nn_euv               ;number steps in one package
      nn_diodes=lpw_const.nn_euv_diodes       ;number of diodes
      dt=lpw_const.dt_euv                     ; time step 
      euv_diod_A=lpw_const.euv_diod_A    ;convert diode from raw to units
      euv_diod_B=lpw_const.euv_diod_B    ;convert diode from raw to units
      euv_diod_C=lpw_const.euv_diod_C    ;convert diode from raw to units
      euv_diod_D=lpw_const.euv_diod_D    ;convert diode from raw to units
      euv_temp=lpw_const.euv_temp        ;convert temp  from raw to units
      calib_file_euv=lpw_const.calib_file_euv
      ;--------------------------------------------------------------------
      nn_pktnum=output.p7                               ; number of data packages 
      nn_size=nn_pktnum*nn_steps                        ; number of data points
      time = double(output.SC_CLK1(output.EUV_i)+ output.SC_CLK2(output.EUV_i)/2l^16) + t_epoch
      dt=dt*2.^(output.smp_avg(output.euv_i)+6) / 2.^10  ; time step corrected for smp_avg
      ;--------------------------------------------------------------------
      
      ;------------- Checks ---------------------
      if output.p7 NE n_elements(output.euv_i) then stanna
      if n_elements(output.euv_i) EQ 0 then print,'(mvn_lpw_euv) No packages where found <---------------'
      ;-----------------------------------------
      
              ;------------- variable:  EUV 4-diodes ---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_size) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_size,nn_diodes) ,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   fltarr(nn_size,nn_diodes) )     ;1-D 
                ;-------------- derive  time/variable ----------------                          
                 for i=0L,nn_pktnum-1 do begin
                   data.x(nn_steps*i:nn_steps*(i+1)-1)  =time(i)+indgen(nn_steps)*dt(i) 
                   data.y(nn_steps*i:nn_steps*(i+1)-1,0) =output.DIODE_A(i,*)*euv_diod_A  ;'DIODE A'
                   data.y(nn_steps*i:nn_steps*(i+1)-1,1) =output.DIODE_B(i,*)*euv_diod_B  ;'DIODE B'
                   data.y(nn_steps*i:nn_steps*(i+1)-1,2) =output.DIODE_C(i,*)*euv_diod_C  ;'DIODE C'
                   data.y(nn_steps*i:nn_steps*(i+1)-1,3) =output.DIODE_D(i,*)*euv_diod_D  ;'DIODE D'
                   data.dy(nn_steps*i:nn_steps*(i+1)-1,0)=output.DIODE_A(i,*)*euv_diod_A *0.0
                   data.dy(nn_steps*i:nn_steps*(i+1)-1,1)=output.DIODE_B(i,*)*euv_diod_B *0.0 
                   data.dy(nn_steps*i:nn_steps*(i+1)-1,2)=output.DIODE_C(i,*)*euv_diod_C *0.0 
                   data.dy(nn_steps*i:nn_steps*(i+1)-1,3)=output.DIODE_D(i,*)*euv_diod_D *0.0                                    
                 endfor             
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'generated_date'  ,     today_date+' # '+t_routine, $ 
                   't_epoch'         ,     t_epoch, $    
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver ,$     
                   'cal_y_const1'    ,     'PKT level: '+strcompress(euv_diod_A,/remove_all)+' # ' + $
                                                         strcompress(euv_diod_B,/remove_all)+' # ' + $
                                                         strcompress(euv_diod_C,/remove_all)+' # ' + $
                                                         strcompress(euv_diod_D,/remove_all)+' # ' , $
                  ; 'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   'cal_datafile'    ,     calib_file_euv , $
                   'cal_source'      ,     'Information from PKT: EUV', $            
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[Raw * D]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     1.2                      ,$    
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'mvn_lpw_euv'                 ,$   
                  'yrange' ,        [min(data.y),max(data.y)] ,$   
                  'ystyle'  ,       1.                       ,$  
                  'labels' ,        ['diod!DA!N','diod!DB!N','diod!DC!N','diod!DD!N']  ,$  
                  'colors' ,        [0,2,4,6]                     ,$   
                  'labflag' ,       1                        ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------                        
                store_data,'mvn_lpw_euv',data=data,limit=limit,dlimit=dlimit
               ;---------------------------------------------
    
      
      IF tplot_var EQ 'all' THEN BEGIN
            ;------------- variable: EUV_temp RAW ---------------------------
                data =  create_struct(    $          
                                         'x',    dblarr(nn_size) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_size) ,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   fltarr(nn_size) )     ;1-D 
                ;-------------- derive  time/variable ----------------                          
                for i=0L,nn_pktnum-1 do begin                                                       
                   data.x(nn_steps*i:nn_steps*(i+1)-1) = time(i)+indgen(nn_steps)*dt(i)                                                                                                                              
                   data.y(nn_steps*i:nn_steps*(i+1)-1) = output.THERM(i,*)
                   data.dy(nn_steps*i:nn_steps*(i+1)-1)= 0
                endfor   
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'generated_date'  ,     today_date+' # '+t_routine, $ 
                   't_epoch'         ,     t_epoch, $    
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver , $     
                   'cal_y_const1'    ,     'PKT level:' , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   'cal_datafile'    ,     calib_file_euv , $
                   'cal_source'      ,     'Information from PKT: EUV', $          
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[Raw]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     1.2                      ,$    
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'EUV temp'                 ,$   
                  'yrange' ,        [min(data.y),max(data.y)] ,$   
                  'ystyle'  ,       1.                       ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------                        
                  store_data,'mvn_lpw_euv_temp',data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------
      ENDIF
      
      
      
                ;------------- variable: EUV_temp C deg---------------------------
                ;If you take the 20 bit temperature data and divide it by 16 to get 16 bit numbers, the numbers should follow the following conversion:
                ;Temp_in_DN(16 bit) = 41.412 x Temp_in_deg_C - 8160.7
                 ;    (measured *  euv_temp(0) +   euv_temp(1)) /euv_temp(2)  = Temp_in_deg_C
                data =  create_struct(  $            
                                         'x',    dblarr(nn_size) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_size) ,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   fltarr(nn_size) )     ;1-D 
                ;-------------- derive  time/variable ----------------                                         
                for i=0L,nn_pktnum-1 do begin                                                       
                    data.x(nn_steps*i:nn_steps*(i+1)-1) = time(i)+indgen(nn_steps)*dt(i)   
                    data.y(nn_steps*i:nn_steps*(i+1)-1) = (output.THERM(i,*) *  euv_temp(0) +   euv_temp(1)) /euv_temp(2) 
                    data.dy(nn_steps*i:nn_steps*(i+1)-1)= 0
                endfor    
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'generated_date'  ,     today_date+' # '+t_routine, $ 
                   't_epoch'         ,     t_epoch, $    
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver ,$     
                   'cal_y_const1'    ,     'PKT level:' + strcompress(euv_temp(0),/remove_all) +' # ' + $
                                                          strcompress(euv_temp(1),/remove_all) +' # ' + $
                                                          strcompress(euv_temp(2),/remove_all) , $
                  ; 'cal_y_const2'    ,     'Used :' 
                   'cal_datafile'    ,     calib_file_euv, $
                   'cal_source'      ,     'Information from PKT: EUV', $          
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[Deg C]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     1.2                      ,$    
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'EUV Temp'                 ,$   
                  'yrange' ,        [min(data.y),max(data.y)] ,$   
                  'ystyle'  ,       1.                       ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------                        
                 store_data,'mvn_lpw_euv_temp_C',data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------
      
      
      IF tplot_var EQ 'all' THEN BEGIN
                ;---------variable: info of the start of each packet -----------------
                data =  create_struct(     $         
                                         'x',    dblarr(nn_size) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_size) )     ;1-D 
                ;-------------- derive  time/variable ----------------                          
                  data.x= time
                  data.y=1.0                
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'generated_date'  ,     today_date+' # '+t_routine, $ 
                   't_epoch'         ,     t_epoch, $    
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver ,$     
                   'cal_source'      ,     'Information from PKT: EUV', $  ; only information of when each packet starts       
                   'xsubtitle'       ,     '[sec]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     1.2                      ,$    
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'None'                 )              ;for plotting lpw pkt lab data
                ;------------- store --------------------                        
                store_data,'mvn_lpw_euv_packet_start',data=data
                ;---------------------------------------------
            
            
            
               ;------------- variable:  smp_avg ---------------------------
                data =  create_struct(  $            
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum))     ;1-D 
                ;-------------- derive  time/variable ---------------- 
                 data.x=time                                                 
                 data.y=2.^(output.smp_avg(output.euv_i)+6)       ; from ICD section 7.6                                     
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
                   'cal_source'      ,     'Information from PKT: EUV', $  
                   'xsubtitle'       ,     '[sec]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     1.2                      ,$    
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'EUV_smp_avg'                 ,$   
                  'yrange' ,        [2^6,max(data.y)],$   
                  'ystyle'  ,       1.                       ,$        
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store -------------------- 
                store_data,'mvn_lpw_euv_smp_avg',data=data,limit=limit,dlimit=dlimit
               ;---------------------------------------------
      ENDIF
      
ENDIF

IF output.p7 LE 0 THEN print, "mvn_lpw_euv.pro skipped as no packets found."

end
;*******************************************************************







