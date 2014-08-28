;;+
;PROCEDURE:   mvn_lpw_pkt_hsbm
;PURPOSE:
;  Takes the decumuted data (L0) from the HSBM and HTIME packets
;  and turn it the data into L1 and L2 tplot structures
;  E12_HF gain boost is manually set
;  
;USAGE:
;  mvn_lpw_pkt_hsbm,output,lpw_const,type,tplot_var
;
;INPUTS:
;       output:         L0 data 
;       lpw_const:      information of lpw calibration etc
;       type:           LF, MF or HF data
;
;KEYWORDS:
;       tplot_var = 'all' or 'sci'    => 'sci' produces tplot variables with physical units associated with them and is the default
;                                     => 'all' produces all tplot variables
;
;CREATED BY:   Laila Andersson 17 august 2011 
;FILE: mvn_lpw_pkt_hsbm.pro
;VERSION:   1.1
;LAST MODIFICATION:   2013, July 11th, Chris Fowler - added IF statement to check for data.
;                     2013, July 12th, Chris Fowler - added keyword tplot_var
;                     
;11/11/13 L. Andersson clean the routine up and change limit/dlimit to fit the CDF labels introduced dy and dv, might need to be disable...
;
;-

pro mvn_lpw_pkt_hsbm, output,lpw_const,type,tplot_var=tplot_var

If keyword_set(tplot_var) THEN tplot_var = tplot_var ELSE tplot_var = 'sci'  ;Default setting is science tplot variables only.

IF (output.p20 GT 0 AND type EQ 'lf') OR $  ;check for data, for keyword 'lf'
   (output.p21 GT 0 AND type EQ 'mf') OR $  ;check for data, for keyword 'mf'
   (output.p22 GT 0 AND type EQ 'hf') $     ;check for data, for keyword 'hf'
THEN BEGIN
      
      ;--------------------- Constants ------------------------------------                        
               t_routine=SYSTIME(0) 
               t_epoch=lpw_const.t_epoch
               today_date=lpw_const.today_date
               cal_ver=lpw_const.version_calib_routine              
               filename_L0=output.filename  
               nn_fft_size=lpw_const.nn_fft_size   
      ;--------------------------------------------------------------------
       IF type EQ 'lf' and output.p20 GT 0 then begin
                  nn_pktnum=long(output.p20)          ; number of data packages           
                  data_hsbm=output.hsbm_lf
                  nn_index=output.hsbm_lf_i  
                  dt=  lpw_const.dt_hsbm_lf
                  nn_size=lpw_const.nn_hsbm_lf
                  f_bin=lpw_const.f_bin_lf
                  nn_bin=lpw_const.nn_bin_lf   
                  const_E12=lpw_const.E12_lf 
                  center_freq=lpw_const.center_freq_lf           
             endif
       IF type EQ 'mf' and output.p21 GT 0 then begin
                  nn_pktnum=long(output.p21)          ; number of data packages           
                  data_hsbm=output.hsbm_mf
                  nn_index=output.hsbm_mf_i  
                  dt= lpw_const.dt_hsbm_mf
                  nn_size=lpw_const.nn_hsbm_mf
                  f_bin=lpw_const.f_bin_mf
                  nn_bin=lpw_const.nn_bin_mf   
                   const_E12=lpw_const.E12_mf
                   center_freq=lpw_const.center_freq_mf            
             endif
       IF type EQ 'hf' and output.p22 GT 0 then begin
                  nn_pktnum=long(output.p22)          ; number of data packages           
                  data_hsbm=output.hsbm_hf
                  nn_index=output.hsbm_hf_i  
                  dt=  lpw_const.dt_hsbm_hf
                  nn_size=lpw_const.nn_hsbm_hf
                  f_bin=lpw_const.f_bin_hf            
                  nn_bin=lpw_const.nn_bin_hf                        
                  const_E12=lpw_const.E12_hf   
                                
                  print,'### HF HSBM  E12_HF gain boost ####',output.E12_HF_GB(nn_index)
                   
                  ;WARING the above means we do not expect this to change for flight we need to change this
                  center_freq=lpw_const.center_freq_hf                      
             endif
      ;--------------------------------------------------------------------       
      nn_length=long(nn_pktnum*nn_size) 
      time=double(output.SC_CLK1(nn_index)) + output.SC_CLK2(nn_index)/2l^16+t_epoch
      ; ## per Jan 4 2012 From D. Meyer ##
      ;   Just a reminder… Since the HSBM timestamp indicates the end of the buffer, 
      ; the following timestamp correction should be applied to the whole 48 bit timestamp 
      ; before converting to human readable format. 
      ;HSBM_HF: PKT_TS – 0x0000_0000_0040    (-1 msec)
      ;HSBM_MF: PKT_TS – 0x0000_0000_1000    (-62.5 msec)
      ;HSBM_LF: PKT_TS – 0x0000_0001_0000      (-1 second)
      if type EQ 'hf' THEN time=time-0.001 
      if type EQ 'mf' THEN time=time-0.0625 
      if type EQ 'lf' THEN time=time-1.0 
      time_sort=sort(time(0:nn_pktnum-1))
      ;--------------------------------------------------------------------       
      
      ;-------------  E as function of time E12_HSBM ---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_length) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_length) ,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   fltarr(nn_length) )     ;1-D 
                ;-------------- derive  time/variable ---------------- 
                FOR i=0,nn_pktnum-1 do BEGIN      
                      data.x(nn_size*i:nn_size*(i+1)-1) = time(time_sort(i)) -(nn_size-1-dindgen(nn_size))*dt                                                                                                                  
                      data.y(nn_size*i:nn_size*(i+1)-1) = data_hsbm(*,time_sort(i))*const_E12                                                                                                                                      
                      data.dy(nn_size*i:nn_size*(i+1)-1) = 0
                ENDFOR
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'generated_date'  ,     today_date+' # '+t_routine, $ 
                   't_epoch'         ,     t_epoch, $    
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver ,$     
                   'cal_y_const1'    ,     'PKT level:'+strcompress(const_E12,/remove_all)  ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'Information from PKT: HSBM'+type, $        
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[Volt]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$    
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'HSBM_'+type              ,$   
                  'yrange' ,        [min(data.y),max(data.y)] ,$   
                  'ystyle'  ,       1.                       ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------             
                 store_data,'mvn_lpw_hsbm_'+type,data=data,limit=limit,dlimit=dlimit
                ;--------------------------------------------------
   
      
                ;-------------  E matrix each burst versus time ---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum,nn_size) ,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   fltarr(nn_pktnum,nn_size) ,  $  
                                         'v',    fltarr(nn_pktnum,nn_size))     ;frequency - no significant error in this value 
                ;-------------- derive  time/variable ----------------  
                FOR i=0,nn_pktnum-1 do BEGIN                                                       
                    data.x(i)=time(time_sort(i))                                                                                                                               
                    data.y(i,*)=data_hsbm(*,time_sort(i))*const_E12      
                    data.v(i,*)=dindgen(nn_size)*dt
                    data.dy(i,*)=0
                ENDFOR                                      
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'generated_date'  ,     today_date+' # '+t_routine, $ 
                   't_epoch'         ,     t_epoch, $    
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver ,$     
                   'cal_y_const1'    ,     'PKT level:'+strcompress(const_E12 ,/remove_all)  ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'Information from PKT: HSBM'+type, $     
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[Volt]', $        
                   'cal_v_const1'    ,     'PKT level::' +strcompress(dt,/remove_all) ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   'zsubtitle'       ,     '[Time]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$    
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'HSBM_'+type             ,$   
                  'yrange' ,        [min(data.v),max(data.v)] ,$   
                  'ystyle'  ,       1.                       ,$ 
                  'ztitle' ,        'E-field E12'            ,$   
                  'zrange' ,        [min(data.y,/nan),max(data.y,/nan)],$   
                  'zlog'   ,        1.                       ,$  
                  'spec'   ,        1.                       ,$      
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------           
                store_data,'mvn_lpw_hsbm_matrix_'+type,data=data,limit=limit,dlimit=dlimit
                ;--------------------------------------------------
                
                     
      IF tplot_var EQ 'all' THEN BEGIN
                ;-------------  which order the packets arrive in  ---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum,3))     ;1-D 
                ;-------------- derive  time/variable ----------------                          
               
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'generated_date'  ,     today_date+' # '+t_routine, $ 
                   't_epoch'         ,     t_epoch, $    
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver ,$     
                   'cal_y_const1'    ,     'PKT level:'  ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
                   'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'Information from PKT: HSBM'+type, $     
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[Volt]', $        
                   'cal_v_const1'    ,     'PKT level::' ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   'cal_v_const2'    ,     'Used :'  ,$ ; Fixed convert information from measured binary values to physical units, variables from space testing
                   'zsubtitle'       ,     '[A]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$    
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'Y-axis'                 ,$   
                  'yrange' ,        [min(data.y),max(data.y)] ,$   
                  'ystyle'  ,       1.                       ,$  
                  'ylog'   ,        1.                       ,$
                  'spec'   ,        0.                       ,$  
                  'labels' ,        ['a']                    ,$  
                  'colors' ,        [6]                      ,$   
                  'labflag' ,       1                        ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,    [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------           
            datatype=create_struct('type', '{ raw}')
            data=create_struct(   $        
               'x'     ,  dblarr(nn_pktnum)  ,$
               'y'     ,  fltarr(nn_pktnum,3))  ;one for the order the other for the peak ampitude
            dlimit=create_struct(   $      
               'datafile'     ,  'Info of file used'  ,$
               'xsubtitle'    ,  '[sec]', $
               'ysubtitle'    ,  '[order]', $
               'data_att'     ,  datatype.type)   
            ;-------------- derive the time ---------------- 
            FOR i=0,nn_pktnum-1 do BEGIN                                                     
                   data.x(i)=time(time_sort(i))                                                                                                                  
                   data.y(i,0)=time_sort(i)                              ;how to sort the data
                   data.y(i,1)=i                                         ;which order the data was sent
                   data.y(i,2)=max(abs(data_hsbm(*,time_sort(i))*const_E12))  ;max amplitude within a package
            ENDFOR
            ;-------------- derive the time ---------------- 
            limit=create_struct(   $                           ;this one I set up the fields as I need, not directly after tplot options
               'ytitle',  'mvn_lpw_hsbm_'+type , $   
                'xtitle',  'Time'  ,$   
               'char_size' ,  2.  ,$                           ;this is not a tplot variable
               'xrange2'  , [min(data.x),max(data.x)], $       ;for plotting purpuses   
               'xstyle2'  ,   1  , $                           ;for plotting putpuses 
               'labels'   ,['order sent','clock order','max peak'], $
               'xlim2'    , [min(data.x),max(data.x)], $                ;this is the true range
               'ystyle'    , 1  ,$                                        ;for plotting purpuses 
               'yrange'  , [min(data.y),max(data.y)] ) 
            ;------------- 
            store_data,'mvn_lpw_hsbm_order_'+type,data=data,limit=limit,dlimit=dlimit
            ;--------------------------------------------------
      ENDIF
      
               ;-------------  HSBM FFT FULL---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum,nn_size/2+1) ,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   fltarr(nn_pktnum,nn_size/2+1) ,  $     ; same size as y
                                         'v',    fltarr(nn_pktnum,nn_size/2+1) ,  $     ; same size as y
                                         'dv',   fltarr(nn_pktnum,nn_size/2+1) )        ;same size as y
                ;-------------- derive  time/variable ----------------                          
                    FOR i=0,nn_pktnum-1 do BEGIN                                                       
                        data.x(i)=time(time_sort(i)) 
                        comp1=data_hsbm(*,time_sort(i))
                        uu=0 
                        nn_zero=0
                        comp1=comp1(nn_zero:nn_size-1)        
                        nn_length=nn_size-nn_zero         
                        ; Find the power spectrum with and without the Hanning filter.
                        han = HANNING(nn_length, /DOUBLE)
                        powerHan = ABS(FFT(han*comp1))^2
                        freq = FINDGEN(nn_length)/(nn_length*dt)
                        data.y(i,0:nn_length/2)=powerHan(0:nn_length/2)  ; note I magnify this value so it comes closer to the other spectras and one should do it the other way 
                        data.v(i,0:nn_length/2)= freq(0:nn_length/2)
                        data.dy(i,0:nn_length/2)=0
                        data.dv(i,0:nn_length/2)=0
                   ENDFOR
                   data.v(*,0)= 0.3*data.v(*,1)  ; so that it is not 0 Hz
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
                   'cal_source'      ,     'Information from PKT: HSBM'+type, $  
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[alog10(Hz)]', $        
                   'cal_v_const1'    ,     'PKT level::' ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   'zsubtitle'       ,     '[RAW]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$    
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'hsbm_full_burst_'+type,$   
                  'yrange' ,        [0.8*min(data.v(*,0)),1.1*max(data.v(*,nn_size/2))],$   
                  'ystyle'  ,       1.                       ,$  
                  'ylog'   ,        1.                       ,$
                  'ztitle' ,        'Wave power'             ,$   
                  'zrange' ,        [1.*lpw_const.power_scale_hf,1.e7],$   
                  'zlog'   ,        1.                       ,$  
                  'spec'   ,        1.                       ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------           
                store_data,'mvn_lpw_hsbm_spec_full_'+type,data=data,limit=limit,dlimit=dlimit
                ;--------------------------------------------------
      
      
                ;-------------  HSBM FFT ---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum,nn_fft_size/2+1) ,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   fltarr(nn_pktnum,nn_fft_size/2+1) ,  $    ; same size as y
                                         'v',    fltarr(nn_pktnum,nn_fft_size/2+1) ,  $     ; same size as y
                                         'dv',   fltarr(nn_pktnum,nn_fft_size/2+1) )       ; same size as y
                ;-------------- derive  time/variable ----------------                          
                      FOR i=0,nn_pktnum-1 do BEGIN                                                       
                           data.x(i)=time(time_sort(i)) 
                           comp1=data_hsbm(0:nn_fft_size-1,time_sort(i)) ;*const_E12     
                           han = HANNING(nn_fft_size, /DOUBLE)
                           powerHan = ABS(FFT(han*comp1))^2
                           freq = FINDGEN(nn_fft_size)/(nn_fft_size*dt)
                           data.y(i,*)=powerHan(0:nn_fft_size/2)   ; note I magnify this value so it comes closer to the other spectras and one should do it the other way 
                           data.v(i,*)= freq(0:nn_fft_size/2)
                           data.dy(i,*)=0
                           data.dv(i,*)=0
                    ENDFOR
                    data.v(*,0)=0.3*data.v(*,1)   ; to not have 0 hertz as the lowest freq               
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
                   'cal_source'      ,     'Information from PKT: HSBM'+type, $  
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[Hz]', $        
                   'cal_v_const1'    ,     'PKT level::' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   'zsubtitle'       ,     '[RAW]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$    
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'hsbm_full_burst_'+type ,$   
                  'yrange' ,        [0.9*min(center_freq),1.1*max(center_freq,/nan)],$   
                  'ystyle'  ,       1.                       ,$  
                  'ylog'   ,        1.                       ,$
                  'ztitle' ,        'Frequency'              ,$   
                  'zrange' ,        [1.*lpw_const.power_scale_hf,1.e7],$   
                  'zlog'   ,        1.                       ,$  
                  'spec'   ,        1.                       ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------           
                store_data,'mvn_lpw_hsbm_spec_'+type,data=data,limit=limit,dlimit=dlimit
               ;--------------------------------------------------
     
      
                ;-------------  HSBM FFT bin as spectras ---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum,nn_bin) ,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   fltarr(nn_pktnum,nn_bin) ,  $    ; same size as y
                                         'v',    fltarr(nn_pktnum,nn_bin) ,  $     ; same size as y
                                         'dv',   fltarr(nn_pktnum,nn_bin) )     ;1-D 
                ;-------------- derive  time/variable ----------------   
                     get_data,'mvn_lpw_hsbm_spec_'+type,data=data2,limit=limit,dlimit=dlimit                       
                     data.x=data2.x
                      ii1=0   ;first bin is the 0 hz
                      ii2=0
                      for i=0,nn_bin-1 do begin
                         ii2=ii1+f_bin(i)-1
                         if ii1 EQ ii2 then data.y(*,i)=data2.y(*,ii1)  ELSE data.y(*,i)= total(data2.y(*,ii1:ii2),2)/f_bin(i)
                         data.v(*,i)= data2.v(*,ii1+0.4*f_bin(i))
                         ii1=ii2+1
                         data.dy(*,i)=data2.dy(*,i)
                         data.dv(*,i)=0
                      endfor
                ;-------------------------------------------
                ;------------- What needs to be updated???? --------------------           
                limit.ztitle='Freq (bin)'                  
                ;------------- store --------------------          
                store_data,'mvn_lpw_hsbm_spec_bin_'+type,data=data,limit=limit,dlimit=dlimit
                ;--------------------------------------------------
      
      
                ;-------------  HSBM FFT power---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum,2) ,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   fltarr(nn_pktnum,2)  )    
                ;-------------- derive  time/variable ----------------                          
                  get_data,'mvn_lpw_hsbm_spec_bin_'+type,data=data2
                   data.x=data2.x
                   data.y(*,0)=alog10(total(data2.y,2))
                   for i=0,nn_pktnum-1 do begin
                         data.y(i,1)=alog10(total(   data2.y(i,2:n_elements(data2.y(0,*))-1)   ))
                   endfor
                   data.dy(*,0:1)=0
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
                   'cal_source'      ,     'Information from PKT: HSBM'+type, $  
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[log10 raw]')          
                ;-------------  limit ----------------
                qq=where(data.y GT 0,nq) ; only sum over points > 0 to get the lower yrange correct 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$    
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'mvn_lpw_hsbm_tot_power_'+type,$   
                  'yrange' ,         [min(data.y(qq,0),/nan),max(data.y,/nan)] ,$   
                  'ystyle'  ,       1.                       ,$ 
                  'labels' ,        [' ',' ']                    ,$  
                  'colors' ,        [4,6]                    ,$   
                  'labflag' ,       1                        ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------           
                  store_data,'mvn_lpw_hsbm_spec_total_'+type,data=data,limit=limit,dlimit=dlimit
                ;--------------------------------------------------
      
      
      IF tplot_var EQ 'all' THEN BEGIN
            ;------------- variable:  hsbm_mode --------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum)  )     ;1-D 
                ;-------------- derive  time/variable ---------------- 
                  data.x = time(time_sort)                                                      
                  data.y = output.orb_md(nn_index(time_sort))   
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
                   'cal_source'      ,     'Information from PKT: HSBM'+type, $  
                   'xsubtitle'       ,     '[sec]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$    
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'HSBM_'+type+'_mode'     ,$   
                  'yrange' ,        [-1,18]                  ,$   
                  'ystyle'  ,       1.                       ,$        
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------           
                     store_data,'mvn_lpw_hsbm_'+type+'_mode',data=data,limit=limit,dlimit=dlimit
               ;---------------------------------------------
      ENDIF
      
      
      IF nn_fft_size NE nn_size  THEN BEGIN   ;this is for MF which has longer burst
      nn_expand=nn_size/nn_fft_size
      ; I spread the time stamps out as much as possible, the time stamps is hterefore not accurate on the last three fft spectras
      ; print,' ###### ','mvn_lpw_hsbm_spec_long_'+type, ' is for the size ',nn_expand,nn_size,nn_fft_size,' warning with the time for this one'
              
                ;-------------  HSBM FFT LONG ---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum*nn_expand) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum*nn_expand,nn_fft_size/2+1) ,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   fltarr(nn_pktnum*nn_expand,nn_fft_size/2+1) ,  $    ; same size as y
                                         'v',    fltarr(nn_pktnum*nn_expand,nn_fft_size/2+1) ,  $     ; same size as y
                                         'dv',   fltarr(nn_pktnum*nn_expand,nn_fft_size/2+1) )     ;1-D 
                ;-------------- derive  time/variable ----------------                          
                FOR i=0,nn_pktnum-1 do BEGIN 
                    for ii=0,nn_expand-1 do begin 
                       if n_elements(time) GT 1  THEN $
                            if i LT nn_pktnum-1 then ddt=time(time_sort(i+1))-time(time_sort(i)) ELSE $
                                      ddt=time(time_sort(i))-time(time_sort(i-1)) ELSE ddt=0.01; maximimize to spred them out
                       data.x(i*nn_expand+ii)=time(time_sort(i))+ii*ddt*0.25 ;;nn_fft_size*dt*ii    ;here I work to increase the time       
                       comp1=data_hsbm(ii*nn_fft_size:(ii+1)*nn_fft_size-1,time_sort(i)) ;*const_E12     
                       han = HANNING(nn_fft_size, /DOUBLE)
                       powerHan = ABS(FFT(han*comp1))^2
                       freq = FINDGEN(nn_fft_size)/(nn_fft_size*dt)
                       data.y(i*nn_expand+ii,*)=powerHan(0:nn_fft_size/2)   ; note I magnify this value so it comes closer to the other spectras and one should do it the other way 
                       data.v(i*nn_expand+ii,*)= freq(0:nn_fft_size/2)
                       data.dy(i*nn_expand+ii,*)=0
                       data.dv(i*nn_expand+ii,*)=0
                   endfor ;ii    
                ENDFOR ;i
                data.v(*,0)=0.3*data.v(*,1)   ; to not have 0 hertz as the lowest freq
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
                   'cal_source'      ,     'Information from PKT: HSBM'+type, $  
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[alog10(Hz)]', $        
                   'cal_v_const1'    ,     'PKT level::', $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                ;   'cal_v_const2'    ,     'Used :'  , $ ; Fixed convert information from measured binary values to physical units, variables from space testing
                   'zsubtitle'       ,     '[raw]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$    
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'HSBM_spec_'+type,$   
                  'yrange' ,        [0.9*min(center_freq),1.1*max(center_freq,/nan)],$   
                  'ystyle'  ,       1.                       ,$  
                  'ylog'   ,        1.                       ,$
                  'ztitle' ,        'Frequency'                ,$   
                  'zrange' ,        [1.*lpw_const.power_scale_hf,1.e7],$   
                  'zlog'   ,        1.                       ,$  
                  'spec'   ,        1.                       ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------           
                 store_data,'mvn_lpw_hsbm_spec_long_'+type,data=data,limit=limit,dlimit=dlimit
                ;--------------------------------------------------
      
                ;-------------  HSBM FFT LONG BIN---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum*nn_expand) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum*nn_expand,nn_bin) ,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   fltarr(nn_pktnum*nn_expand,nn_bin) ,  $    ; same size as y
                                         'v',    fltarr(nn_pktnum*nn_expand,nn_bin) ,  $     ; same size as y
                                         'dv',   fltarr(nn_pktnum*nn_expand,nn_bin) )    
                ;-------------- derive  time/variable ----------------                          
                 get_data,'mvn_lpw_hsbm_spec_long_'+type,data=data2,limit=limit,dlimit=dlimit
                   data.x=data2.x
                   ii1=0   ;first bin is the 0 hz
                   ii2=0
                   for i=0,nn_bin-1 do begin
                     ii2=ii1+f_bin(i)-1
                      if ii1 EQ ii2 then data.y(*,i)=data2.y(*,ii1)  ELSE data.y(*,i)= total(data2.y(*,ii1:ii2),2)/f_bin(i)
                      data.v(*,i)= data2.v(*,ii1+0.4*f_bin(i))
                      ii1=ii2+1
                   endfor
;                   data.dy=data2.dy
                   data.dy=0;jmm, 2014-05-22
                   data.dv=0
                ;-------------------------------------------
                ;------------- What needs to be updated???? --------------------           
                limit.ztitle='Freq (bin)'                  
                ;------------- store --------------------          
                 store_data,'mvn_lpw_hsbm_spec_long_bin_'+type,data=data,limit=limit,dlimit=dlimit
                ;--------------------------------------------------
          
      
                ;-------------  HSBM FFT power2---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum*nn_expand) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum*nn_expand) ,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   fltarr(nn_pktnum*nn_expand) )
                ;-------------- derive  time/variable ---------------- 
                 get_data,'mvn_lpw_hsbm_spec_long_bin_'+type,data=data2
                 data.x=data2.x
                 data.y=alog10(total(data2.y,2))
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
                   'cal_source'      ,     'Information from PKT: HSBM'+type, $  
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[log10 raw]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$    
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'mvn_lpw_hsbm_tot_power2_'+type,$   
                  'yrange' ,        [min(data.y(qq),/nan),max(data.y,/nan)],$  
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------           
                 store_data,'mvn_lpw_hsbm_spec_total2_'+type,data=data,limit=limit,dlimit=dlimit
               ;--------------------------------------------------      
      ENDIF   ;IF nn_fft_size NE nn_size  THEN BEGIN   ;this is for MF which has longer burst
      
      
      
      
      ;----------- in case gst is active - not for flight data----------------------
      if n_elements(output.SC_CLK1) EQ n_elements(output.SC_CLK1_gst) THEN BEGIN
      
      nn_index2=where(output.APID2 EQ output.APID(nn_index(0)),nq)
      
      time1=double(output.SC_CLK1(nn_index)) + double(output.SC_CLK2(nn_index))/2l^16+t_epoch
      time2=double(output.SC_CLK1_gst(nn_index2)) + double(output.SC_CLK2_gst(nn_index2))/2l^16+t_epoch
      time3=double(output.SC_CLK3_gst(nn_index2)) + double(output.SC_CLK4_gst(nn_index2))/2l^16+t_epoch
      
      if type EQ 'hf' THEN time1=time1-0.001 
      if type EQ 'mf' THEN time1=time1-0.0625 
      if type EQ 'lf' THEN time1=time1-1.0 
      ;Correction is not needed for the gsm/gst time (i.e time2 and time3)
      ;from Corinnes read_htime
      htime_length = output.length(output.htime_i)
      htime_clk = output.SC_CLK1(output.htime_i)
      ii = 0
      for i = 0,n_elements(htime_length)-1 do begin ;loop over three
        for iii = 0,(((htime_length(i)-1)/2)-7)/2 do begin   ; the length derived in r_header such that -1 should not be used
          if ii eq 0 then abs_cap_time  = double(output.cap_time(ii)  + htime_clk(i)) else abs_cap_time  = [abs_cap_time,  double(output.cap_time(ii) + htime_clk(i)) ]
          if ii EQ 0 then abs_xfer_time = double(output.xfer_time(ii) + htime_clk(i)) else abs_xfer_time = [abs_xfer_time, double(output.xfer_time(ii) + htime_clk(i))]
          ii = ii+1
        endfor
      endfor
      column1 = string(output.htime_type)
      column2 = string(output.cap_time)
      column3 = string(output.xfer_time)
      column4 = string(abs_cap_time,format = '(Z08)')
      column5 = string(abs_xfer_time,format = '(Z08)')
      print,'############################ start type ',type,' #####################################'
      print,"       TYPE      REL_CAP_TIME      REL_XFER_TIME     index      ABS_CAP_TIME     ABS_XFER_TIME      index     packet_CAP_TIME   gse_XFER_TIME"
      iii=0
      for i=0, n_elements(output.htime_type)-1 do $
        if  (output.APID(nn_index(0)) EQ 95) and (output.htime_type(i) EQ 0) then begin
           print,column1[i]+string(9B)+column2[i]+string(9B)+column3[i]+string(9B)+string(i)+string(9B)+" 0x"+column4[i]+string(9B)+" 0x"+column5[i]+ $
                      string(9B)+string(iii)+string(9B)+" 0x"+string(output.SC_CLK1(nn_index2(iii)),format = '(Z08)')+string(9B)+" 0x"+string(output.SC_CLK1_gst(nn_index2(iii)),format = '(Z08)')
         iii=iii+1
          endif            
      ii=0
      for i=0,n_elements(output.htime_type)-1 do $
        if  (output.APID(nn_index(0)) EQ 96) and (output.htime_type(i) EQ 1) then begin
            print,column1[i]+string(9B)+column2[i]+string(9B)+column3[i]+string(9B)+string(i)+string(9B)+" 0x"+column4[i]+string(9B)+" 0x"+column5[i]+ $
                      string(9B)+string(iii)+string(9B)+" 0x"+string(output.SC_CLK1(nn_index2(iii)),format = '(Z08)')+string(9B)+" 0x"+string(output.SC_CLK1_gst(nn_index2(iii)),format = '(Z08)')
         iii=iii+1
         endif             
      ii=0
      for i=0,n_elements(output.htime_type)-1 do $
        if  (output.APID(nn_index(0)) EQ 97) and (output.htime_type(i) EQ 2) then begin
            print,column1[i]+string(9B)+column2[i]+string(9B)+column3[i]+string(9B)+string(i)+string(9B)+" 0x"+column4[i]+string(9B)+" 0x"+column5[i]+ $
                      string(9B)+string(iii)+string(9B)+" 0x"+string(output.SC_CLK1(nn_index2(iii)),format = '(Z08)')+string(9B)+" 0x"+string(output.SC_CLK1_gst(nn_index2(iii)),format = '(Z08)')
          iii=iii+1  
         endif 
      print,'############################ end type ',type,' #####################################'
      
      ENDIF   ;----------- in case gst is active ----------------------

ENDIF

IF output.p20 LE 0 AND type EQ 'lf' THEN print, "mvn_lpw_hsbm.pro skipped for keyword 'lf' as no packets found."
IF output.p21 LE 0 AND type EQ 'mf' THEN print, "mvn_lpw_hsbm.pro skipped for keyword 'mf' as no packets found."
IF output.p22 LE 0 AND type EQ 'hf' THEN print, "mvn_lpw_hsbm.pro skipped for keyword 'hf' as no packets found."

end
;*******************************************************************









