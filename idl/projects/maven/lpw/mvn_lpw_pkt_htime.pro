;;+
;PROCEDURE:   mvn_lpw_pkt_htime
;PURPOSE:
;  Takes the decumuted data (L0) from the HTIME packet
;  and turn it the data into tplot structures
;  This packet contains the information of when HSBM packets are created
;  The capture time and when they where sent to the archive
;  Noraml operation: HTIME paket is transimtted in the survey pipeline while HSBM is via archive
;
;USAGE:
;  mvn_lpw_pkt_pas,output,lpw_const,tplot_var
;
;INPUTS:
;       output:         L0 data 
;       lpw_const:      information of lpw calibration etc
;
;KEYWORDS:
;       tplot_var = 'all' or 'sci'     => 'sci' produces tplot variables with physical units associated with them and is the default
;                                      => 'all' produces all tplot variables
;
;CREATED BY:   Laila Andersson 13 august 2012 
;FILE: mvn_lpw_pkt_pas.pro
;VERSION:   1.1
; Changes:  Time in the header is now associated with the last measurement point
;LAST MODIFICATION:   05/16/13
;                     2013, July 11th, Chris Fowler - added IF statement to check for data
;                     2013, July 12th, Chris Fowler - add keyword tplot_var
;11/11/13 L. Andersson clean the routine up and change limit/dlimit to fit the CDF labels, no dy or dv is needed in this routine
;
;-

pro mvn_lpw_pkt_htime, output,lpw_const,tplot_var=tplot_var

If keyword_set(tplot_var) THEN tplot_var = tplot_var ELSE tplot_var = 'sci'  ;Default setting is science tplot variables only.

IF output.p23 GT 0 THEN BEGIN  ;check for data
      
      ;--------------------- Constants ------------------------------------               
               t_routine=SYSTIME(0) 
               t_epoch=lpw_const.t_epoch
               today_date=lpw_const.today_date
               cal_ver=lpw_const.version_calib_routine              
               filename_L0=output.filename
      ;--------------------------------------------------------------------
      
      ;--------------------------------------------------------------------       
      ; time stamp of the packet it self
      time=double(output.SC_CLK1(output.HTIME_i)) + output.SC_CLK2(output.HTIME_i)/2l^16+t_epoch  ;number of packets
      
      length=(((long(output.length[output.HTIME_i])-1)/2)-7)/2+1
      lenght_cum0=total(length,/CUMULATIVE)
      time_long=dblarr(n_elements(output.htime_type))  ;make time so it matches htime_type
      
      for i=0,n_elements(time)-1 do $ 
        if length(i) GT 0 then $ 
              time_long(lenght_cum0(i)-length(i):lenght_cum0(i)-1)=time(i)
      type_3=['lf','mf','hf','unused']  ; 00, 01, 10, 11 see ICD section 9.11 
      ;--------------------------------------------------------------------
  
      IF tplot_var EQ 'all' THEN BEGIN      
            ;--------------------------------------------------------------------    
            for iu=0,2  do begin ; loop over the HSBM types lf mf hf
                type=type_3(iu)
                qq=where(output.htime_type EQ iu,nq)  
                
               ;-------------  compare time with time as function of time  capture time and trensfere time---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nq) ,  $     ; double 1-D arr
                                         'y',    fltarr(nq) )    ;1-D 
                ;-------------- derive  time/variable ----------------                                               
                   data.x=double(time_long(qq) + output.cap_time(qq))                                                                                                               
                   data.y=output.htime_type(qq)+0.8     ; for the plotting routine the yvalue in cap and xfer needs to be different                                        
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'generated_date'  ,     today_date+' # '+t_routine, $ 
                   't_epoch'         ,     t_epoch, $    
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver ,$     
                   'cal_y_const1'    ,     'PKT level:'  ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                  ; 'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
                  ; 'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'Information from PKT: HTIME', $     
                   'xsubtitle'       ,     '[sec]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     1.2                      ,$    
                  'xtitle' ,        'Time (not sorted)'      ,$   
                  'ytitle' ,        'Capture time '+type     ,$   
                  'yrange' ,        [0,3] ,$   
                  'ystyle'  ,       1.                       ,$  
                  'ylog'   ,        1.                       ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------                              
                  store_data,'mvn_lpw_htime_cap_'+type,data=data,limit=limit,dlimit=dlimit
                ;--------------------------------------------------       
                    data.x=double(time_long(qq) + output.xfer_time(qq))
                    data.y=output.htime_type(qq) +0.1     ; for the plotting routine the yvalue in cap and xfer needs to be different      
                    limit.ytitle='Xfer '+type 
                  store_data,'mvn_lpw_htime_xfer_'+type,data=data,limit=limit,dlimit=dlimit
                 ;--------------------------------------------------       
            
            endfor  ;end loop over the HSBM types lf mf hf
      ENDIF
      
      IF tplot_var EQ 'all' THEN BEGIN
                 ;------------- variable:  HTIME report rate ---------------------------
            
                   data =  create_struct(   $           
                                         'x',    dblarr(n_elements(time)) ,  $     ; double 1-D arr
                                         'y',    fltarr(n_elements(time)))     ;1-D 
                ;-------------- derive  time/variable ----------------   
                 data.x = time                                                      
                 data.y = 2^output.smp_avg(output.HTIME_i)        ; smp_avg is used for htime to get the HTIME_rate, Equation see table 7.8 ICD  
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'generated_date'  ,     today_date+' # '+t_routine, $ 
                   't_epoch'         ,     t_epoch, $    
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver ,$     
                   'cal_y_const1'    ,     'PKT level:'  ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                  ; 'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'Information from PKT: HTIME', $     
                   'xsubtitle'       ,     '[sec]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     1.2                      ,$    
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'HTIME rate (sec)'       ,$   
                  'yrange' ,        [-1,max(data.y)*1.2]     ,$   
                  'ystyle'  ,       1.                       ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,    [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------                              
                    store_data,'mvn_lpw_htime_rate',data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------
      ENDIF
ENDIF

IF output.p23 LE 0 THEN print, "mvn_lpw_htime.pro skipped as no packets found."

end
;*******************************************************************









