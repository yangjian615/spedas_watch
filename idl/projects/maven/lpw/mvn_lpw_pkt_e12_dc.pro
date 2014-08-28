;;+
;PROCEDURE:   mvn_lpw_pkt_E12_DC
;PURPOSE:
;  Takes the decumuted data (L0) from either the ACT or PAS packet
;  and turn it the data into L1 and L2 data tplot structures
;  This packet contains the information of V1, V2 and E12_LF
;  
;
;USAGE:
;  mvn_lpw_pkt_act_pas,output,lpw_const,tplot_var,packet
;
;INPUTS:
;       output:         L0 data 
;       lpw_const:      information of lpw calibration etc
;       packet:         'act' => runs routine for the ACT packet
;                       'pas' => runs routine for the PAS packet 
;
;KEYWORDS:
;       tplot_var = 'all' or 'sci'  => 'sci' produces tplot variables with physical units and is the default
;                                   => 'all' produces all tplot variables
;
;CREATED BY:   Laila Andersson 17 august 2011 
;FILE: mvn_lpw_pkt_act_pas.pro
;VERSION:   1.1
; Changes:  Time in the header is now associated with the last measurement point
;LAST MODIFICATION:   2013, July 11th, Chris Fowler - added IF statement to check for data.
;                     2013, July 12th, Chris Fowler - added keyword tplot_var
;                     2013, July 15th, Chris Fowler - combined mvn_lpw_pck_act.pro and mvn_lpw_pas.pro into this one file.
;11/11/13 L. Andersson clean the routine up and change limit/dlimit to fit the CDF labels introduced dy and dv, might need to be disable...
;
;-

pro mvn_lpw_pkt_E12_DC, output,lpw_const,packet,tplot_var=tplot_var

If keyword_set(tplot_var) THEN tplot_var = tplot_var ELSE tplot_var = 'sci'  ;Default setting is science tplot variables only.

IF (output.p12 GT 0 AND packet EQ 'act') OR $
   (output.p13 GT 0 AND packet EQ 'pas') THEN BEGIN  ;check for data

      ;--------------------- Constants ------------------------------------          
               t_routine=SYSTIME(0) 
               t_epoch=lpw_const.t_epoch
               today_date=lpw_const.today_date
               cal_ver=lpw_const.version_calib_routine              
               filename_L0=output.filename
      ;---------   
      subcycle_length=lpw_const.sc_lngth
      nn_steps=long(lpw_const.nn_pa)                                   ;number of samples in one subcycle
      const_V2_readback=lpw_const.V2_readback
      const_V1_readback=lpw_const.V1_readback
      const_E12_LF =    lpw_const.E12_lf
      ;--------------------------------------------------------------------
      IF packet EQ 'act' THEN BEGIN
            output_state_i = output.act_i
            nn_pktnum = long(output.p12)
            output_state_V1 = output.act_V1
            output_state_V2 = output.act_V2
            output_state_E12_LF = output.act_E12_LF
      ENDIF
      
      IF packet EQ 'pas' THEN BEGIN
            output_state_i = output.pas_i
            nn_pktnum = long(output.p13)
            output_state_V1 = output.pas_V1
            output_state_V2 = output.pas_V2
            output_state_E12_LF = output.pas_E12_LF
      ENDIF
      ;--------------------------------------------------------------------    
      nn_pktnum=nn_pktnum                                      ; number of data packages 
      nn_size=nn_pktnum*nn_steps                                     ; number of data points
      dt=subcycle_length(output.mc_len(output_state_i))/nn_steps
      t_s=subcycle_length(output.mc_len(output_state_i))*3./64         ;this is how long time each measurement point took
                                                                     ;the time in the header is associated with the last point in the measurement
                                                                     ;therefore is the time corrected by the thength of the subcycle_length
      time      = double(output.SC_CLK1(output_state_i)) + output.SC_CLK2(output_state_i)/2l^16+t_epoch-t_s  -subcycle_length(output.mc_len(output_state_i))
      ;--------------------------------------------------------------------
      
      ;------------- Checks ---------------------
      if nn_pktnum NE n_elements(output_state_i) then stop
      ;if output.p12 NE n_elements(output_state_i) then stop
      if n_elements(output_state_i) EQ 0 then print,'(mvn_lpw_act) No packages where found <---------------'
      ;-----------------------------------------
      
      ;----------  variable:   V1 ---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_size) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_size) ,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   fltarr(nn_size))     ;1-D 
                ;-------------- derive  time/variable ----------------                          
                 for i=0L,nn_pktnum-1 do begin
                         data.x(nn_steps*i:nn_steps*(i+1)-1) = time(i) + dindgen(nn_steps) * dt(i)  
                         data.y(nn_steps*i:nn_steps*(i+1)-1) = output_state_V1(i,*) * const_V1_readback
                         data.dy(nn_steps*i:nn_steps*(i+1)-1) = 0
                 endfor        
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'generated_date'  ,     today_date+' # '+t_routine, $ 
                   't_epoch'         ,     t_epoch, $    
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver ,$     
                   'cal_y_const1'    ,     'PKT level:'+strcompress(const_V1_readback,/remove_all)  ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                  ; 'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'Information from PKT: '+strtrim(packet,2), $     
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[Volt]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$    
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'mvn_lpw_'+strtrim(packet,2)+'_V1',$   
                  'yrange' ,        [min(data.y),max(data.y)] ,$   
                  'ystyle'  ,       1.                       ,$      
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,    [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------                        
                 store_data,'mvn_lpw_'+strtrim(packet,2)+'_V1',data=data,limit=limit,dlimit=dlimit
                ;--------------------------------------------------
 
      
                ;----------  variable: V2 ---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_size) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_size) ,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   fltarr(nn_size) )     ;1-D 
                ;-------------- derive  time/variable ----------------                          
                 for i=0L,nn_pktnum-1 do begin                                                        
                      data.x(nn_steps*i:nn_steps*(i+1)-1) = time(i) + dindgen(nn_steps)*dt(i)  
                      data.y(nn_steps*i:nn_steps*(i+1)-1) = output_state_V2(i,*)*const_V2_readback
                      data.dy(nn_steps*i:nn_steps*(i+1)-1) = 0
                 endfor
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'generated_date'  ,     today_date+' # '+t_routine, $ 
                   't_epoch'         ,     t_epoch, $    
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver ,$     
                   'cal_y_const1'    ,     'PKT level:'+strcompress(const_V2_readback ,/remove_all)  ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'Information from PKT: '+strtrim(packet,2), $   
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[Volt]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$     
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'mvn_lpw_'+strtrim(packet,2)+'_V2',$   
                  'yrange' ,        [min(data.y),max(data.y)] ,$   
                  'ystyle'  ,       1.                       ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------                              
                store_data,'mvn_lpw_'+strtrim(packet,2)+'_V2',data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------------
 
      
                ;----------  variable: E12 ---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_size) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_size) ,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   fltarr(nn_size)  )   ;1-D 
                ;-------------- derive  time/variable ----------------   
                 for i=0L,nn_pktnum-1 do begin
                          data.x(nn_steps*i:nn_steps*(i+1)-1) = time(i) + dindgen(nn_steps) * dt(i)                                                                                                                                                                                                   
                          data.y(nn_steps*i:nn_steps*(i+1)-1) = output_state_E12_LF(i,*) *const_E12_LF
                          data.dy(nn_steps*i:nn_steps*(i+1)-1) = 0
                 endfor         
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'generated_date'  ,     today_date+' # '+t_routine, $ 
                   't_epoch'         ,     t_epoch, $    
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver ,$     
                   'cal_y_const1'    ,     'PKT level:' +strcompress(const_E12_LF,/remove_all) ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'Information from PKT: '+strtrim(packet,2), $   
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[Volt]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$     
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'mvn_lpw_'+strtrim(packet,2)+'_E12',$   
                  'yrange' ,        [min(data.y),max(data.y)] ,$   
                  'ystyle'  ,       1.                       ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------                        
                store_data,'mvn_lpw_'+strtrim(packet,2)+'_E12',data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------
 
 
     
                 ;------------- variable:  mc_len ---------------------------  needed for the spectra
                data =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum))     ;1-D 
                ;-------------- derive  time/variable ---------------- 
                 data.x = time                                                      
                 data.y = subcycle_length(output.mc_len(output_state_i) )*4.                                      
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
                   'cal_source'      ,     'Information from PKT: '+strtrim(packet,2), $   
                   'xsubtitle'       ,     '[sec]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$     
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        strtrim(packet,2)+'_mc_len',$   
                  'yrange' ,        [0,65]                   ,$   
                  'ystyle'  ,       1.                       ,$   
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,    [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------                        
                 store_data,'mvn_lpw_'+strtrim(packet,2)+'_mc_len',data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------
      
     IF tplot_var EQ 'all' THEN BEGIN 
                ;------------- variable:  mode ---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum) )     ;1-D 
                ;-------------- derive  time/variable ---------------- 
                 data.x = time                                                    
                 data.y = output.orb_md(output_state_i)  
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
                   'cal_source'      ,     'Information from PKT: '+strtrim(packet,2), $   
                   'xsubtitle'       ,     '[sec]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$     
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        strtrim(packet,2)+'_mode',$   
                  'yrange' ,        [-1,18]                  ,$   
                  'ystyle'  ,       1.                       ,$        
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------                        
                     store_data,'mvn_lpw_'+strtrim(packet,2)+'_mode',data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------
      ENDIF
      
ENDIF

IF output.p12 LE 0 AND packet EQ 'act' THEN print, "mvn_lpw_act_pas.pro(act) skipped as no packets found."
IF output.p13 LE 0 AND packet EQ 'pas' THEN print, "mvn_lpw_act_pas.pro(pas) skipped as no packets found."

end
;*******************************************************************





