;;+
;PROCEDURE:   mvn_lpw_pkt_spectra
;PURPOSE:
;  Takes the decumuted data (L0) from the SPEC packets
;  and turn it the data into L1 and L2 data tplot structures
;  ; Warning for the moment am I not correcting for the number of frequency bins the fpga is operating in. 
;  ; if this is changing correct mvn_lpw_wdg_3_spec_freq according to
;  ;Warning for the moment I do not correct that due to the Hanning window 1/2 of the power is missing
;  NOTE E12_HF gain boost is modified manually for the moment
;
;USAGE:
;  mvn_lpw_pkt_spectra,output,lpw_const,subcycle,type,tplot_var
;
;INPUTS:
;       output:         L0 data 
;       lpw_const:      information of lpw calibration etc
;       subcycle:       'PAS' or 'ACT' subcycle    
;       type:           'LF', 'MF' or 'HF' frequency range
;
;KEYWORDS:
;       tplot_var = 'all' or 'sci'    => 'sci' produces tplot variables which have physical units associated with them as is the default
;                                     => 'all' produces all tplot variables
;
;CREATED BY:   Laila Andersson 17 august 2011 
;FILE: mvn_lpw_pkt_spectra.pro
;VERSION:   1.1
;LAST MODIFICATION:   2013, July 11th, Chris Fowler - added IF statement to check for data.
;11/11/13 L. Andersson clean the routine up and change limit/dlimit to fit the CDF labels introduced dy and dv, might need to be disable...
;
;-

pro mvn_lpw_pkt_spectra,output,lpw_const,subcycle,type,tplot_var=tplot_var

If keyword_set(tplot_var) THEN tplot_var = tplot_var ELSE tplot_var = 'sci'  ;Default setting is science tplot variables only.

IF (output.p14 GT 0 AND subcycle EQ 'act' AND type EQ 'lf') OR $  ;check for data, for keywords 'act' and 'lf'
   (output.p15 GT 0 AND subcycle EQ 'act' AND type EQ 'mf') OR $  ;check for data, for keywords 'act' and 'mf'
   (output.p16 GT 0 AND subcycle EQ 'act' AND type EQ 'hf') OR $  ;check for data, for keywords 'act' and 'hf'
   (output.p17 GT 0 AND subcycle EQ 'pas' AND type EQ 'lf') OR $  ;check for data, for keywords 'pas' and 'lf'
   (output.p18 GT 0 AND subcycle EQ 'pas' AND type EQ 'mf') OR $  ;check for data, for keywords 'pas' and 'mf'
   (output.p19 GT 0 AND subcycle EQ 'pas' AND type EQ 'hf') $     ;check for data, for keywords 'pas' and 'hf'
THEN BEGIN  
      
      ;--------------------- Constants Used In This Routine ------------------------------------            
               t_routine=SYSTIME(0) 
               t_epoch=lpw_const.t_epoch
               today_date=lpw_const.today_date
               cal_ver=lpw_const.version_calib_routine              
               filename_L0=output.filename     
      ;--------------------------------------------------------------------
       IF type EQ 'hf' and subcycle EQ 'act' and output.p16 GT 0 then begin
                  nn_pktnum      =output.p16          ; number of data packages
                  n_bins_spec    =lpw_const.nn_bin_hf
                  data_Spec      =output.ACT_S_HF    
                  timestep       = lpw_const.nn_fft_size/(lpw_const.nn_fft_hf*lpw_const.nn_fft_size)           ; 4MS/s -- 1/datarate of waveform 
                  center_freq    =lpw_const.center_freq_hf
                  nn_index       =output.ACT_S_HF_i   
                  power_scale    =lpw_const.power_scale_hf
                  pktarr         =output.act_HF_pktarr
                  
                  print,'###HF ACT  E12_HF gain boost ####',output.E12_HF_GB(nn_index)
                  
             endif
       IF type EQ 'mf' and subcycle EQ 'act' and output.p15 GT 0 then begin
                  nn_pktnum=output.p15                                    ; number of data packages
                  n_bins_spec=lpw_const.nn_bin_mf 
                  data_Spec=output.ACT_S_MF  
                  timestep = lpw_const.nn_fft_size/(lpw_const.nn_fft_mf*lpw_const.nn_fft_size)            ; 64kS/s -- 1/datarate of waveform 
                  center_freq=lpw_const.center_freq_mf  
                  nn_index=output.ACT_S_MF_i 
                  power_scale=lpw_const.power_scale_mf 
                  pktarr=output.act_MF_pktarr      
             endif
       IF type EQ 'lf' and subcycle EQ 'act' and output.p14 GT 0 then begin
                  nn_pktnum=output.p14                                    ; number of data packages
                  n_bins_spec=lpw_const.nn_bin_lf
                  data_Spec=output.ACT_S_LF     
                  timestep = lpw_const.nn_fft_size/(lpw_const.nn_fft_lf*lpw_const.nn_fft_size)            ; kS/s -- 1/datarate of waveform 
                  center_freq=lpw_const.center_freq_lf
                  nn_index=output.ACT_S_LF_i 
                  power_scale=lpw_const.power_scale_lf  
                  pktarr=output.act_LF_pktarr  
             endif
       IF type EQ 'hf' and subcycle EQ 'pas' and output.p19 GT 0 then begin
                  nn_pktnum      =output.p19                                     ; number of data packages
                  n_bins_spec    =lpw_const.nn_bin_hf
                  data_Spec      =output.PAS_S_HF     
                  timestep       = lpw_const.nn_fft_size/(lpw_const.nn_fft_hf*lpw_const.nn_fft_size)           ; 4MS/s -- 1/datarate of waveform 
                  center_freq    =lpw_const.center_freq_hf
                  nn_index       =output.PAS_S_HF_i 
                  power_scale    =lpw_const.power_scale_hf 
                  pktarr         =output.pas_HF_pktarr    
                  
                   print,'### HF PAS  E12_HF gain boost ####',output.E12_HF_GB(nn_index)
                  
             endif
       IF type EQ 'mf' and subcycle EQ 'pas' and output.p18 GT 0 then begin
                  nn_pktnum=output.p18                                     ; number of data packages
                  n_bins_spec=lpw_const.nn_bin_mf
                  data_Spec=output.PAS_S_MF 
                   timestep = lpw_const.nn_fft_size/(lpw_const.nn_fft_mf*lpw_const.nn_fft_size)            ; 64kS/s -- 1/datarate of waveform
                  center_freq=lpw_const.center_freq_mf
                  nn_index=output.PAS_S_MF_i 
                  power_scale=lpw_const.power_scale_mf 
                  pktarr=output.pas_MF_pktarr     
             endif
       IF type EQ 'lf' and subcycle EQ 'pas' and output.p17 GT 0 then begin
                  nn_pktnum=output.p17 ;n_elements(nn_index)                                  ; number of data packages
                  n_bins_spec=lpw_const.nn_bin_lf
                  data_Spec=output.PAS_S_LF           
                  timestep = lpw_const.nn_fft_size/(lpw_const.nn_fft_lf*lpw_const.nn_fft_size)           ; kS/s -- 1/datarate of waveform
                  center_freq=lpw_const.center_freq_lf
                  nn_index=output.PAS_S_LF_i  
                  power_scale=lpw_const.power_scale_lf
                  pktarr=output.pas_LF_pktarr                   
             endif
       if total(data_Spec) EQ 0 OR nn_pktnum EQ 0 then begin
                                Print,'(mvn_lpw_spectra) Either no data or wrong cycle/type ',subcycle,type
                                return;
                             endif

       ;reset nn_pktnum to match nn_index, jmm, 2015-01-15
       nn_pktnum = n_elements(nn_index)
       time = double(output.SC_CLK1(nn_index))+output.SC_CLK2(nn_index)/2l^16 +t_epoch
       nn_pktnum_extra=total(pktarr)-nn_pktnum ; if multiple spectras is in one and the same spectra here is how many
      
      ;------------------      
       n_lines_temp1 = n_bins_spec/2   
      ;---------------------------------------------
          
      ;----------  variable:  spectra   ------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum+nn_pktnum_extra) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum+nn_pktnum_extra, n_bins_spec) ,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   fltarr(nn_pktnum+nn_pktnum_extra, n_bins_spec) ,  $    ; same size as y
                                         'v',    fltarr(nn_pktnum+nn_pktnum_extra, n_bins_spec) ,  $     ; same size as y
                                         'dv',   fltarr(nn_pktnum+nn_pktnum_extra, n_bins_spec) )     ;1-D 
                ;-------------- derive  time/variable ---------------- 
                   get_data,'mvn_lpw_'+subcycle+'_mc_len',data=data_mc_len  ; WARNING THIS CAN FAIL AT A BOUNDARY OF A MODE CHANGE
                   PRINT,'(mvn_lpw_spectra) Warning at a mode change I might look a the wrong packet, should just be one master cycle off'
                   ti=0
                   for i=0,nn_pktnum-1 do $
                       for ii=0,pktarr(i)-1 DO BEGIN
                          IF MAX(size(data_mc_len)) GT 0 THEN BEGIN                                                      ; pas-packet has not been read in?
                                   qq=min(abs(time(i)-data_mc_len.x),nq)
                                   data.x(ti) = time(i)+ii*data_mc_len.y(nq)                             ; get the right time, one spectra per master cycle
                          ENDIF ELSE data.x(ti) = time(i)+ii*4                                           ; assume 4 second time if the pas-packet has not been read in
                          ti=ti+1
                       ENDFOR                ; over ii         
                   for i=0,nn_pktnum+nn_pktnum_extra-1 do data.v(i,*) = center_freq                                            ;frequency value
                            ; data_cpec will be  nn_pktnum* pktarr*( n_bins_spec+1)   -> where 1 is the packet number witnin each spectra which needs to be striped off
                            ;each spectra will be the packet number followed by n_bins_spec/2 numbers make that as a variable:
                        nn_bins_total=1+n_bins_spec/2  ;-1
                              ;------------- Break into Different Data Points
                        split_E_M=fltarr(4)                           ;for each row in the package (n_lines_temp1) there will be 4 values extracted       
                              ;------------
                         iu=0
                        for iu1 = 0 , nn_pktnum-1 do begin
                             for iu2 = 0 , pktarr(iu1)-1, 1 do begin
                                for ie=0L, nn_bins_total-2 do begin ; 0:nn_bins_total-2 is values used to get the information into data.y but they are located inlocated in from 1:nn_bins_total-1 in data_spec        
                                   nn_data_spec=long(iu)*long(nn_bins_total)+long(ie+1) ;+ui1  ;try to read the rigth values from data_spec
                                   string_tmp=string(data_spec(nn_data_spec),format='(B016)')  ;string(data_spec(i,ie),format='(B016)')
                                   reads,string_tmp,split_E_M,format='(B005,B003,B005,B003)'         ;break each row into 4 values    
                                         ;-------------                                 Taking every fourth number of array (mattisa+exponent * two_values =4 for each row in the package)
                                   data.y(iu,ie*2) =    (split_E_M(3) + 8d) * 2d^(split_E_M(2) - 1d)
                                   data.y(iu,ie*2+1)  = (split_E_M(1) + 8d) * 2d^(split_E_M(0) - 1d)
                                         ;-------------                                 Checking for exponent = 0, if 0 only mantissa is used
                                   data.y(iu,ie*2)     = data.y(iu,ie*2)  *(split_E_M(2) NE 0 ) + (split_E_M(2) EQ 0) * split_E_M(3)
                                   data.y(iu,ie*2+1)   = data.y(iu,ie*2+1) *(split_E_M(0) NE 0 ) + (split_E_M(0) EQ 0) * split_E_M(1) 
                                  endfor                ;ie
                                 iu=iu+1              ;spectra number
                            endfor  ;iu2  
                        endfor ;iu1
                        data.y = data.y*power_scale                                ;get the right y-sacle for the three different frequency ranges
                        data.y(*,0)=data.y(*,0)*lpw_const.f_zero_freq              ; This is what was needed on MMS to correct for too much power in 0-bin from FPGA algorithm
                        data.dy=0
                        data.dv=0
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'generated_date'  ,     today_date+' # '+t_routine, $ 
                   't_epoch'         ,     t_epoch, $    
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver ,$     
                   'cal_y_const1'    ,     'PKT level:' +strcompress(power_scale,/remove_all) ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'Information from PKT: SPEC_'+type +' and ACT/PAS', $     
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[alog10(Hz)]', $        
                   'cal_v_const1'    ,     'PKT level::' + strcompress(min(lpw_const.f_zero_freq ), /remove_all) + ' # '+ $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                                                           strcompress(max(lpw_const.f_zero_freq ), /remove_all) ,$
                   ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   'zsubtitle'       ,     '[raw]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     1.2                      ,$    
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        subcycle+'_'+type+' Frequency (Hz)',$   
                  'yrange' ,        [0.9*min(center_freq),1.1*max(center_freq,/nan)] ,$   
                  'ystyle'  ,       1.                       ,$  
                  'ylog'   ,        1.                       ,$
                  'ztitle' ,        'Power (LSB)'            ,$   
                  'zrange' ,        [1.*power_scale,1.e8]    ,$   
                  'zlog'   ,        1.                       ,$  
                  'spec'   ,        1.                       ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------                        
                 store_data,'mvn_lpw_spec_'+type+'_'+subcycle,data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------
    
                ;----------  variable:  spectra2  value/freq  ------------------
                ;-------------- derive  time/variable ----------------                          
                         dlimit.zsubtitle='[Power/Freq units]'
                         data.y=data.y/data.v
                         limit.ztitle='Power/Freq'
                         limit.zrange=[min(data.y,/nan)>1.,max(data.y,/nan)*2]
                ;-------------------------------------------
                       store_data,'mvn_lpw_spec2_'+type+'_'+subcycle,data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------
   
      
                ;-------------  HSBM FFT power---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum+nn_pktnum_extra) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum+nn_pktnum_extra,2) ,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   fltarr(nn_pktnum+nn_pktnum_extra,2) )     ;1-D 
                ;-------------- derive  time/variable ----------------                          
                    get_data,'mvn_lpw_spec_'+type+'_'+subcycle,data=data2
                    data.x=data2.x
                    data.y(*,0)=alog10(total(data2.y,2))
                    for i=0,nn_pktnum+nn_pktnum_extra-1 do $
                                data.y(i,1)=alog10(total(   data2.y(i,2:n_elements(data2.y(0,*))-1)   ))
                    data.dy=0
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
                   'cal_source'      ,     'Information from PKT: SPEC_'+type +' and ACT/PAS', $  
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[alog 10 raw]')          
                ;-------------  limit ---------------- 
                qq=where(data.y(*,0) GT 0,nq) ; only sum over points > 0 to get the lower yrange correct
                limit=create_struct(   $               
                  'char_size' ,     1.2                      ,$    
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'mvn_lpw_spec_tot_power_'+type,$   
                  'yrange' ,        [0.95*min(data.y(qq,0),/nan),1.05*max(data.y,/nan)],$   
                  'ystyle'  ,       1.                       ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------                              
                store_data,'mvn_lpw_spec_total_'+type+'_'+subcycle,data=data,limit=limit,dlimit=dlimit
                ;--------------------------------------------------
 
      
      IF tplot_var EQ 'all' THEN BEGIN     
                ;------------- variable:  smp_avg ---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum))     ;1-D 
                ;-------------- derive  time/variable ----------------  
                 data.x = time                                                      
                 data.y = output.smp_avg(nn_index)    
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
                   'cal_source'      ,     'Information from PKT: SPEC_'+type, $  
                   'xsubtitle'       ,     '[sec]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     1.2                      ,$    
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'Spectra_'+type+'_smp_avg',$   
                  'yrange' ,        [-1,max(data.y)+1] ,$   
                  'ystyle'  ,       1.                       ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------                               
                   store_data,'mvn_lpw_spec_'+type+'_'+subcycle+'_smp_avg',data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------

     
                ;------------- variable:  spec_mode --------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum) )     ;1-D 
                ;-------------- derive  time/variable ----------------  
                 data.x = time                                                      
                 data.y = output.orb_md(nn_index)    
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
                   'cal_source'      ,     'Information from PKT: SPEC_'+type, $  
                   'xsubtitle'       ,     '[sec]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     1.2                      ,$    
                  'xtitle' ,        'Time'                   ,$   
                  'ytitle' ,        'Spectra_'+type+'_mode'  ,$   
                  'yrange' ,        [-1,18]                  ,$   
                  'ystyle'  ,       1.                       ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------                               
                   store_data,'mvn_lpw_spec_'+type+'_'+subcycle+'_mode',data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------
      ENDIF
      
ENDIF

IF output.p14 LE 0 AND subcycle EQ 'act' AND type EQ 'lf' THEN print, "mvn_lpw_spectra.pro skipped for keywords 'act' and 'lf' as no packets found."
IF output.p15 LE 0 AND subcycle EQ 'act' AND type EQ 'mf' THEN print, "mvn_lpw_spectra.pro skipped for keywords 'act' and 'mf' as no packets found."
IF output.p16 LE 0 AND subcycle EQ 'act' AND type EQ 'hf' THEN print, "mvn_lpw_spectra.pro skipped for keywords 'act' and 'hf' as no packets found."
IF output.p17 LE 0 AND subcycle EQ 'pas' AND type EQ 'lf' THEN print, "mvn_lpw_spectra.pro skipped for keywords 'pas' and 'lf' as no packets found."
IF output.p18 LE 0 AND subcycle EQ 'pas' AND type EQ 'mf' THEN print, "mvn_lpw_spectra.pro skipped for keywords 'pas' and 'mf' as no packets found."
IF output.p19 LE 0 AND subcycle EQ 'pas' AND type EQ 'hf' THEN print, "mvn_lpw_spectra.pro skipped for keywords 'pas' and 'hf' as no packets found."

END
;*******************************************************************







