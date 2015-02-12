;;+
;PROCEDURE:   mvn_lpw_pkt_E12_DC
;PURPOSE:
;  Takes the decumuted data (L0) from either the ACT or PAS packet
;  and turn it the data into L1 and L2 data tplot structures
;  This packet contains the information of V1, V2 and E12_LF
;  
;
;USAGE:
;  mvn_lpw_pkt_E12_DC,output,lpw_const,cdf_istp_lpw,tplot_var,packet
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
;  spice = '/directory/of/spice/=> 1 if SPICE is installed. SPICE is then used to get correct clock times.
;                 => 0 is SPICE is not installed. S/C time is used.                                  
;
;CREATED BY:   Laila Andersson 17 august 2011 
;FILE: mvn_lpw_pkt_E12_DC.pro
;VERSION:   2.0  <------------------------------- update 'pkt_ver' variable
; Changes:  Time in the header is now associated with the last measurement point
;LAST MODIFICATION:   2013, July 11th, Chris Fowler - added IF statement to check for data.
;                     2013, July 12th, Chris Fowler - added keyword tplot_var
;                     2013, July 15th, Chris Fowler - combined mvn_lpw_pck_act.pro and mvn_lpw_pas.pro into this one file.
;                     2014, March 20, Chris Fowler - added SPICE time
;11/11/13 L. Andersson clean the routine up and change limit/dlimit to fit the CDF labels introduced dy and dv, might need to be disable...
;04/15/14 L. Andersson included L1
;04/22/14 L. Andersson major changes to meet the CDF requirement and allow time to come from spice, added verson number in dlimit, changed version number
;140718 clean up for check out L. Andersson
;2014-10-03: CF: modified dlimit fields for ISTP compliance.
;-

pro mvn_lpw_pkt_E12_DC, output,lpw_const,packet,tplot_var=tplot_var,spice=spice

IF (output.p12 GT 0 AND packet EQ 'act') OR $
   (output.p13 GT 0 AND packet EQ 'pas') THEN BEGIN  ;check for data


If keyword_set(tplot_var) THEN tplot_var = tplot_var ELSE tplot_var = 'SCI'  ;Default setting is science tplot variables only.


      ;--------------------- Constants ------------------------------------          
               t_routine            = SYSTIME(0) 
               t_epoch              = lpw_const.t_epoch
               today_date           = lpw_const.today_date
               cal_ver              = lpw_const.version_calib_routine 
               pkt_ver              = 'pkt_e12_ver  2.0' 
               cdf_istp             = lpw_const.cdf_istp_lpw                                      
               filename_L0          = output.filename
      ;----------------------------------------------------------------         
               inst_phys            = lpw_const.inst_phys
               sensor_distance      = lpw_const.sensor_distance
               boom_shorting_factor = lpw_const.boom_shortening              
               subcycle_length      = lpw_const.sc_lngth
              nn_steps              = long(lpw_const.nn_pa)                                   ;number of samples in one subcycle
              const_V2_readback     = lpw_const.V2_readback
              const_V1_readback     = lpw_const.V1_readback
              const_E12_LF          = lpw_const.E12_lf
              boom1_corr            = lpw_const.boom1_corr
              boom2_corr            = lpw_const.boom2_corr
              e12_corr              = lpw_const.e12_corr
      ;--------------------------------------------------------------------
      IF packet EQ 'act' THEN BEGIN
            output_state_i      = output.act_i
            nn_pktnum           = long(output.p12)
            output_state_V1     = output.act_V1
            output_state_V2     = output.act_V2
            output_state_E12_LF = output.act_E12_LF                   
      ENDIF
      
      IF packet EQ 'pas' THEN BEGIN
            output_state_i      = output.pas_i
            nn_pktnum           = long(output.p13)
            output_state_V1     = output.pas_V1
            output_state_V2     = output.pas_V2
            output_state_E12_LF = output.pas_E12_LF
      ENDIF
        ;--------------------------------------------------------------------    
      nn_pktnum       = nn_pktnum                                                    ; number of data packages 
      nn_size         = nn_pktnum*nn_steps                                           ; number of data points
      dt              = subcycle_length(output.mc_len[output_state_i])/nn_steps
      t_s             = subcycle_length(output.mc_len[output_state_i])*3./64         ;this is how long time each measurement point took
                                                                                    ;the time in the header is associated with the last point in the measurement
                                                                                    ;therefore is the time corrected by the thength of the subcycle_length
      ;--------------------------------------------------------------------
      
      ;------------- Checks ---------------------
      if nn_pktnum NE n_elements(output_state_i) then stop
      ;if output.p12 NE n_elements(output_state_i) then stop
      if n_elements(output_state_i) EQ 0 then print,'(mvn_lpw_act) No packages where found <---------------'
      ;-----------------------------------------
 
  
   
        ;the way we do the clock (fix sc_dt and then spice) gives us a unsertainty of 1e-6/16/64?? SEC in time TBR
 
  
      ;-------------------- Get correct clock time ------------------------------
      dt              =subcycle_length(output.mc_len[output_state_i])/nn_steps
      t_s             =subcycle_length(output.mc_len[output_state_i])*3./64         ;this is how long time each measurement point took
                                                                     ;the time in the header is associated with the last point in the measurement
                                                                     ;therefore is the time corrected by the thength of the subcycle_length
    
    
      ;-------------------- Get correct clock time ------------------------------
     
      time_sc         = double(output.SC_CLK1[output_state_i]) + output.SC_CLK2[output_state_i]/2l^16+t_epoch -t_s 
      time_dt         = dblarr(nn_pktnum*nn_steps)                                                                                  ;will hold times for subcycles within each packet            
      for i=0L,nn_pktnum-1 do time_dt[nn_steps*i:nn_steps*(i+1)-1]  =time_sc[i]+dt[i]*indgen(nn_steps)     
      IF keyword_set(spice)  THEN BEGIN                                                                                                ;if this computer has SPICE installed:
         aa = output.SC_CLK1[output_state_i]
         bb = output.SC_CLK2[output_state_i]
         mvn_lpw_anc_clocks_spice, aa, bb,clock_field_str,clock_start_t,clock_end_t,spice,spice_used,str_xtitle,kernel_version,time  ;correct times using SPICE    
         aa=floor(time_dt-t_epoch)
         bb=floor(((time_dt-t_epoch) MOD 1) *2l^16)                                                                                    ;if this computer has SPICE installed:
         mvn_lpw_anc_clocks_spice, aa, bb,clock_field_str,clock_start_t_dt,clock_end_t_dt,spice,spice_used,str_xtitle,kernel_version,time_dt  ;correct times using SPICE    
        ENDIF ELSE BEGIN
          clock_field_str  = ['Spacecraft Clock ', 's/c time seconds from 1970-01-01/00:00']
          time             = time_sc                                                                                            ;data points in s/c time
          clock_start_t    = [time_sc(0)-t_epoch,          time_sc(0)]                         ;corresponding start times to above string array, s/c time
          clock_end_t      = [time_sc(nn_pktnum-1)-t_epoch,time_sc(nn_pktnum-1)]               ;corresponding end times, s/c time
          spice_used       = 'SPICE not used'
          str_xtitle       = 'Time (s/c)'  
          kernel_version    = 'N/A'
          clock_start_t_dt = [time_dt(0)-t_epoch,          time_dt(0)]                                        
          clock_end_t_dt   = [time_dt(nn_pktnum-1)-t_epoch,time_dt(nn_pktnum-1)]
      ENDELSE           
      ;--------------------------------------------------------------------
 
 
   
      ;----------  variable:   V1 ---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_size) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_size) ,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   fltarr(nn_size))     ;1-D 
                ;-------------- derive  time/variable ----------------                          
                 data.x = time_dt
                  
                 
                 for i=0L,nn_pktnum-1 do begin
                         ;data.x[nn_steps*i:nn_steps*(i+1)-1] = time[i] + dindgen(nn_steps) * dt[i]  
                        ; data.y[nn_steps*i:nn_steps*(i+1)-1] = output_state_V1[i,*] * const_V1_readback
                         data.y[nn_steps*i:nn_steps*(i+1)-1] = ((output_state_V1[i,*] * const_V1_readback)-boom1_corr(0))/boom1_corr(1)
                         data.dy[nn_steps*i:nn_steps*(i+1)-1] = 0
                 endfor        
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'Product_name',                  'Calibrated PKT V1 data, mode: '+strtrim(packet,2), $
                   'Project',                       cdf_istp[12], $
                   'Source_name',                   cdf_istp[0], $     ;Required for cdf production...
                   'Discipline',                    cdf_istp[1], $
                   'Instrument_type',               cdf_istp[2], $
                   'Data_type',                     cdf_istp[3] ,  $
                   'Data_version',                  cdf_istp[4], $  ;Keep this text string, need to add v## when we make the CDF file (done later)
                   'Descriptor',                    cdf_istp[5], $
                   'PI_name',                       cdf_istp[6], $
                   'PI_affiliation',                cdf_istp[7], $     
                   'TEXT',                          cdf_istp[8], $
                   'Mission_group',                 cdf_istp[9], $     
                   'Generated_by',                  cdf_istp[10],  $
                   'Generation_date',                today_date+' # '+t_routine, $
                   'Rules_of_use',                  cdf_istp[11], $
                   'Acknowledgement',               cdf_istp[13],   $                                                                            
                   'Var_type',  'Data', $    ;can be data, support data, metadata or ignore data
                   'MONOTON', 'INCREASE', $
                   'SCALEMIN', min(data.y), $
                   'SCALEMAX', max(data.y), $        ;..end of required for cdf production.
                   't_epoch'         ,     t_epoch, $    
                   'Time_start'      ,     clock_start_t_dt, $
                   'Time_end'        ,     clock_end_t_dt, $
                   'Time_field'      ,     clock_field_str, $
                   'SPICE_kernel_version', kernel_version, $
                   'SPICE_kernel_flag'      ,     spice_used, $                   
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver+' # '+pkt_ver ,$     
                   'cal_y_const1'    ,     'Uses: '+strcompress(const_V1_readback,/remove_all)  ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                  ; 'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'Information from PKT: '+strtrim(packet,2), $     
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[uncorr Volt]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$    
                  'xtitle' ,        str_xtitle                   ,$   
                  'ytitle' ,        'mvn_lpw_'+strtrim(packet,2)+'_V1',$   
                  'yrange' ,        [min(data.y),max(data.y)] ,$   
                  'ystyle'  ,       1.                       ,$      
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,    [min(data.x),max(data.x)], $              ;for plotting lpw pkt lab data
                  'noerrorbars', 1)
                ;------------- store --------------------                        
                 store_data,'mvn_lpw_'+strtrim(packet,2)+'_V1',data=data,limit=limit,dlimit=dlimit
                ;--------------------------------------------------
 
      
                ;----------  variable: V2 ---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_size) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_size) ,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   fltarr(nn_size) )     ;1-D 
                ;-------------- derive  time/variable ----------------                          
                 data.x = time_dt
                 for i=0L,nn_pktnum-1 do begin                                                        
                      ;data.x[nn_steps*i:nn_steps*(i+1)-1] = time[i] + dindgen(nn_steps)*dt[i]  
                      ;data.y[nn_steps*i:nn_steps*(i+1)-1] = output_state_V2[i,*]*const_V2_readback
                      data.y[nn_steps*i:nn_steps*(i+1)-1] = ((output_state_V2[i,*] * const_V2_readback)-boom2_corr(0))/boom2_corr(1)
                      data.dy[nn_steps*i:nn_steps*(i+1)-1] = 0
                 endfor
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'Product_name',                  'Calibrated PKT V2 data, mode: '+strtrim(packet,2), $
                   'Project',                       cdf_istp[12], $
                   'Source_name',                   cdf_istp[0], $     ;Required for cdf production...
                   'Discipline',                    cdf_istp[1], $
                   'Instrument_type',               cdf_istp[2], $
                   'Data_type',                     cdf_istp[3] ,  $
                   'Data_version',                  cdf_istp[4], $  ;Keep this text string, need to add v## when we make the CDF file (done later)
                   'Descriptor',                    cdf_istp[5], $
                   'PI_name',                       cdf_istp[6], $
                   'PI_affiliation',                cdf_istp[7], $     
                   'TEXT',                          cdf_istp[8], $
                   'Mission_group',                 cdf_istp[9], $     
                   'Generated_by',                  cdf_istp[10],  $
                   'Generation_date',                today_date+' # '+t_routine, $
                   'Rules_of_use',                  cdf_istp[11], $
                   'Acknowledgement',               cdf_istp[13],   $                                                                            
                   'Var_type',  'Data', $    ;can be data, support data, metadata or ignore data
                   'MONOTON', 'INCREASE', $
                   'SCALEMIN', min(data.y), $
                   'SCALEMAX', max(data.y), $        ;..end of required for cdf production.
                   't_epoch'         ,     t_epoch, $    
                   'Time_start'      ,     clock_start_t_dt, $
                   'Time_end'        ,     clock_end_t_dt, $
                   'Time_field'      ,     clock_field_str, $
                   'SPICE_kernel_version', kernel_version, $
                   'SPICE_kernel_flag'      ,     spice_used, $                   
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver+' # '+pkt_ver ,$     
                   'cal_y_const1'    ,     'Uses: '+strcompress(const_V2_readback ,/remove_all)  ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'Information from PKT: '+strtrim(packet,2), $   
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[uncorr Volt]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$     
                  'xtitle' ,        str_xtitle                   ,$   
                  'ytitle' ,        'mvn_lpw_'+strtrim(packet,2)+'_V2',$   
                  'yrange' ,        [min(data.y),max(data.y)] ,$   
                  'ystyle'  ,       1.                       ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)], $              ;for plotting lpw pkt lab data
                  'noerrorbars', 1)
                ;------------- store --------------------                              
                store_data,'mvn_lpw_'+strtrim(packet,2)+'_V2',data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------------
 
      
                ;----------  variable: E12 ---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_size) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_size) ,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   fltarr(nn_size)  )   ;1-D 
                ;-------------- derive  time/variable ----------------   
                 data.x = time_dt
                 for i=0L,nn_pktnum-1 do begin
                          ;data.x[nn_steps*i:nn_steps*(i+1)-1] = time[i] + dindgen(nn_steps) * dt[i]                                                                                                                                                                                                   
                         ; data.y[nn_steps*i:nn_steps*(i+1)-1] = output_state_E12_LF[i,*] *const_E12_LF                                                                                                                                                                                                  
                          data.y[nn_steps*i:nn_steps*(i+1)-1] = ((output_state_E12_LF[i,*] *const_E12_LF)-e12_corr(0))/e12_corr(1)
                          data.dy[nn_steps*i:nn_steps*(i+1)-1] = SQRT(abs(output_state_E12_LF[i,*] *const_E12_LF))
                 endfor         
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                          dlimit=create_struct(   $
                             'Product_name',                  'Calibrated PKT Electric field data, mode: '+strtrim(packet,2), $
                             'Project',                       cdf_istp[12], $
                             'Source_name',                   cdf_istp[0], $     ;Required for cdf production...
                             'Discipline',                    cdf_istp[1], $
                             'Instrument_type',               cdf_istp[2], $
                             'Data_type',                     cdf_istp[3] ,  $
                             'Data_version',                  cdf_istp[4], $  ;Keep this text string, need to add v## when we make the CDF file (done later)
                             'Descriptor',                    cdf_istp[5], $
                             'PI_name',                       cdf_istp[6], $
                             'PI_affiliation',                cdf_istp[7], $     
                             'TEXT',                          cdf_istp[8], $
                             'Mission_group',                 cdf_istp[9], $     
                             'Generated_by',                  cdf_istp[10],  $
                             'Generation_date',                today_date+' # '+t_routine, $
                             'Rules_of_use',                  cdf_istp[11], $
                             'Acknowledgement',               cdf_istp[13],   $                                                                            
                             'Var_type',  'Data', $    ;can be data, support data, metadata or ignore data
                             'MONOTON', 'INCREASE', $
                             'SCALEMIN', min(data.y), $
                             'SCALEMAX', max(data.y), $        ;..end of required for cdf production.
                             't_epoch'         ,     t_epoch, $
                             'Time_start'      ,     clock_start_t_dt, $
                             'Time_end'        ,     clock_end_t_dt, $
                             'Time_field'      ,     clock_field_str, $
                             'SPICE_kernel_version', kernel_version, $
                             'SPICE_kernel_flag'      ,     spice_used, $
                             'L0_datafile'     ,     filename_L0 , $
                             'cal_vers'        ,     cal_ver+' # '+pkt_ver ,$
                             'cal_y_const1'    ,     'Uses: ' +strcompress(const_E12_LF,/remove_all) ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                             ;'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
                             ;'cal_datafile'    ,     'No calibration file used' , $
                             'cal_source'      ,     'Information from PKT: '+strtrim(packet,2), $
                             'xsubtitle'       ,     '[sec]', $
                             'ysubtitle'       ,     '[uncorr Volt]')
                          ;-------------  limit ----------------
                          limit=create_struct(   $
                            'char_size' ,     lpw_const.tplot_char_size ,$
                            'xtitle' ,        str_xtitle                   ,$
                            'ytitle' ,        'mvn_lpw_'+strtrim(packet,2)+'_e12',$
                            'yrange' ,        [min(data.y),max(data.y)] ,$
                            'ystyle'  ,       1.                       ,$
                            'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                            'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                            'xlim2'    ,      [min(data.x),max(data.x)], $              ;for plotting lpw pkt lab data
                            'noerrorbars', 1)
                          ;------------- store --------------------
                          store_data,'mvn_lpw_'+strtrim(packet,2)+'_e12',data=data,limit=limit,dlimit=dlimit
                          ;---------------------------------------------                
                
                 
     
                 ;------------- variable:  mc_len ---------------------------  needed for the spectra
                data =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum))     ;1-D 
                ;-------------- derive  time/variable ---------------- 
                 data.x = time                                                      
                 data.y = subcycle_length[output.mc_len[output_state_i] ]*4.                                      
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'Product_name',                  'Calibrated PKT mc_len data, mode: '+strtrim(packet,2), $
                   'Project',                       cdf_istp[12], $
                   'Source_name',                   cdf_istp[0], $     ;Required for cdf production...
                   'Discipline',                    cdf_istp[1], $
                   'Instrument_type',               cdf_istp[2], $
                   'Data_type',                     cdf_istp[3] ,  $
                   'Data_version',                  cdf_istp[4], $  ;Keep this text string, need to add v## when we make the CDF file (done later)
                   'Descriptor',                    cdf_istp[5], $
                   'PI_name',                       cdf_istp[6], $
                   'PI_affiliation',                cdf_istp[7], $     
                   'TEXT',                          cdf_istp[8], $
                   'Mission_group',                 cdf_istp[9], $     
                   'Generated_by',                  cdf_istp[10],  $
                   'Generation_date',                today_date+' # '+t_routine, $
                   'Rules_of_use',                  cdf_istp[11], $
                   'Acknowledgement',               cdf_istp[13],   $                                                                             
                   'Var_type',  'Data', $    ;can be data, support data, metadata or ignore data  
                   'MONOTON', 'INCREASE', $
                   'SCALEMIN', 0, $
                   'SCALEMAX', 65, $        ;..end of required for cdf production.
                   't_epoch'         ,     t_epoch, $ 
                   'Time_start'      ,     clock_start_t_dt, $
                   'Time_end'        ,     clock_end_t_dt, $
                   'Time_field'      ,     clock_field_str, $
                   'SPICE_kernel_version', kernel_version, $
                   'SPICE_kernel_flag'      ,     spice_used, $                      
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver+' # '+pkt_ver ,$     
                   'cal_source'      ,     'Information from PKT: '+strtrim(packet,2), $   
                   'xsubtitle'       ,     '[sec]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$     
                  'xtitle' ,        str_xtitle                   ,$   
                  'ytitle' ,        strtrim(packet,2)+'_mc_len',$   
                  'yrange' ,        [0,65]                   ,$   
                  'ystyle'  ,       1.                       ,$   
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,    [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------                        
                 store_data,'mvn_lpw_'+strtrim(packet,2)+'_mc_len',data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------
      
     IF tplot_var EQ 'ALL' THEN BEGIN 
                ;------------- variable:  mode ---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum) )     ;1-D 
                ;-------------- derive  time/variable ---------------- 
                 data.x = time                                                    
                 data.y = output.orb_md[output_state_i]  
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'Product_name',                  'Calibrated PKT Electric field mode data, mode: '+strtrim(packet,2), $
                   'Project',                       cdf_istp[12], $
                   'Source_name',                   cdf_istp[0], $     ;Required for cdf production...
                   'Discipline',                    cdf_istp[1], $
                   'Instrument_type',               cdf_istp[2], $
                   'Data_type',                     cdf_istp[3] ,  $
                   'Data_version',                  cdf_istp[4], $  ;Keep this text string, need to add v## when we make the CDF file (done later)
                   'Descriptor',                    cdf_istp[5], $
                   'PI_name',                       cdf_istp[6], $
                   'PI_affiliation',                cdf_istp[7], $     
                   'TEXT',                          cdf_istp[8], $
                   'Mission_group',                 cdf_istp[9], $     
                   'Generated_by',                  cdf_istp[10],  $
                   'Generation_date',                today_date+' # '+t_routine, $
                   'Rules_of_use',                  cdf_istp[11], $
                   'Acknowledgement',               cdf_istp[13],   $                                                                             
                   'Var_type',  'Data', $    ;can be data, support data, metadata or ignore data
                   'MONOTON', 'INCREASE', $
                   'SCALEMIN', -1, $
                   'SCALEMAX', 18, $        ;..end of required for cdf production.
                   't_epoch'         ,     t_epoch, $    
                   'Time_start'      ,     clock_start_t_dt, $
                   'Time_end'        ,     clock_end_t_dt, $
                   'Time_field'      ,     clock_field_str, $
                   'SPICE_kernel_version', kernel_version, $
                   'SPICE_kernel_flag'      ,     spice_used, $                   
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver+' # '+pkt_ver ,$     
                   'cal_source'      ,     'Information from PKT: '+strtrim(packet,2), $   
                   'xsubtitle'       ,     '[sec]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$     
                  'xtitle' ,        str_xtitle                   ,$   
                  'ytitle' ,        strtrim(packet,2)+'_mode',$   
                  'yrange' ,        [-1,18]                  ,$   
                  'ystyle'  ,       1.                       ,$        
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------                        
                     store_data,'mvn_lpw_'+strtrim(packet,2)+'_mode',data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------
     
     
     
     
              ;------------- variable:  act/pas packet L0b-raw  ---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum) ,  $               ; double 1-D arr
                                         'y',    fltarr(nn_pktnum, nn_steps*3+2))      ;1-D 
                ;-------------- derive  time/variable ----------------                          
                 for i=0L,nn_pktnum-1 do begin
                   data.x[i]                         = time_sc[i]                     ;sc time only 
                   data.y[i,0:nn_steps-1]            = output_state_V1[i,*] 
                   data.y[i,nn_steps:nn_steps*2-1]   = output_state_V2[i,*] 
                   data.y[i,nn_steps*2:nn_steps*3-1] = output_state_E12_LF[i,*]                  
                   data.y[i,nn_steps*3+0]             = subcycle_length[output.mc_len[output_state_i[i]] ]*4. 
                   data.y[i,nn_steps*3+1]             = output.orb_md[output_state_i[i]]                                
                  endfor             
                str1=[ 'V1 DN'+strarr(nn_steps), $
                       'V2 DN'+strarr(nn_steps), $
                       'E12 DN'+strarr(nn_steps), $
                       'Subcycle  Length','Orbit mode']                                     
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $ 
                   'Product_name',                  'MAVEN LPW raw L0b PKT Electric field data, mode: '+strtrim(packet,2), $
                   'Project',                       cdf_istp[12], $
                   'Source_name',                   cdf_istp[0], $     ;Required for cdf production...
                   'Discipline',                    cdf_istp[1], $
                   'Instrument_type',               cdf_istp[2], $
                   'Data_type',                     'RAW>Raw' ,  $
                   'Data_version',                  cdf_istp[4], $  ;Keep this text string, need to add v## when we make the CDF file (done later)
                   'Descriptor',                    cdf_istp[5], $
                   'PI_name',                       cdf_istp[6], $
                   'PI_affiliation',                cdf_istp[7], $     
                   'TEXT',                          cdf_istp[8], $
                   'Mission_group',                 cdf_istp[9], $     
                   'Generated_by',                  cdf_istp[10],  $
                   'Generation_date',                today_date+' # '+t_routine, $
                   'Rules_of_use',                  cdf_istp[11], $
                   'Acknowledgement',               cdf_istp[13],   $
               ;;    'Title',                         'MAVEN LPW RAW Electric field', $   ;####            ;As this is L0b, we need all info here, as there's no prd file for this
                   'x_catdesc',                     'Timestamps for each data point, in UNIX time.', $
                   'y_catdesc',                     'Electric field data, in units of [Volt]', $    ;### ARE UNITS CORRECT? v/m?
                   ;'v_catdesc',                     'test dlimit file, v', $    ;###
                   'dy_catdesc',                    'Error on the data.', $     ;###
                   ;'dv_catdesc',                    'test dlimit file, dv', $   ;###
                   'flag_catdesc',                  'test dlimit file, flag.', $   ; ###
                   'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
                   'y_Var_notes',                   'For mode: '+strtrim(packet,2), $
                   ;'v_Var_notes',                   'Frequency bins', $
                   'dy_Var_notes',                  'The value of dy is the +/- error value on the data.', $
                   ;'dv_Var_notes',                   'Error on frequency', $
                   'flag_Var_notes',                'Flag variable', $
                   'xFieldnam',                     'x: More information', $      ;###
                   'yFieldnam',                     'y: More information', $
                   'vFieldnam',                     'v: More information', $
                   'dyFieldnam',                    'dy: More information', $
                   'dvFieldnam',                    'dv: More information', $
                   'flagFieldnam',                  'flag: More information', $  
                   'derivn',                        'Equation of derivation', $    ;####
                   'sig_digits',                    '# sig digits', $ ;#####
                   'SI_conversion',                 'Convert to SI units', $  ;####                                                                            
                   'Var_type',  'Data', $    ;can be data, support data, metadata or ignore data 
                   'MONOTON',                     'INCREASE', $
                   'SCALEMIN',                    min(data.y), $
                   'SCALEMAX',                    max(data.y), $        
                   't_epoch'         ,            t_epoch, $    
                   'Time_start'      ,            [time_sc(0)-t_epoch,          time_sc(0)] , $
                   'Time_end'        ,            [time_sc(nn_pktnum-1)-t_epoch,time_sc(nn_pktnum-1)], $
                   'Time_field'      ,             ['Spacecraft Clock ', 's/c time seconds from 1970-01-01/00:00'], $
                   'SPICE_kernel_version',        'NaN', $
                   'SPICE_kernel_flag'      ,     'SPICE not used', $    
                   'L0_datafile'     ,            filename_L0 , $ 
                   'cal_source'      ,            'Information from PKT: e12 '+strtrim(packet,2)+'-raw', $            
                   'xsubtitle'       ,            '[sec]', $   
                   'ysubtitle'       ,            '[Raw Packet Information]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $                  
                  'xtitle' ,                      'Time (s/c)'            ,$   
                  'ytitle' ,                      'Misc'                 ,$  
                  'labels' ,                      str1                    ,$   
                  'yrange' ,                      [min(data.y),max(data.y)] )
                ;------------- store --------------------                        
                store_data,'mvn_lpw_'+strtrim(packet,2)+'_l0b',data=data,limit=limit,dlimit=dlimit
               ;---------------------------------------------
   
     
      ENDIF
      
ENDIF ELSE  print, 'mvn_lpw_pkt_e12_dc.pro ('+strtrim(packet,2)+') skipped as no packets found.'

end
;*******************************************************************





