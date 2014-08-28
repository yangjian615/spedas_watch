;;+
;PROCEDURE:   mvn_lpw_spectra
;PURPOSE:
;  Takes the decumuted data (L0) from the SPEC packets
;  and turn it the data into L1 and L2 data tplot structures
;  ; Warning for the moment am I not correcting for the number of frequency bins the fpga is operating in. 
;  ; if this is changing correct mvn_lpw_wdg_3_spec_freq according to
;  ;Warning for the moment I do not correct that due to the Hanning window 1/2 of the power is missing
;  NOTE E12_HF gain boost is modified manually for the moment
;
;USAGE:
;  mvn_lpw_spectra,output,lpw_const,subcycle,type
;
;INPUTS:
;       output:         L0 data 
;       lpw_const:      information of lpw calibration etc
;       subcycle:       'PAS' or 'ACT' subcycle    
;       type:           'LF', 'MF' or 'HF' frequency range
;
;KEYWORDS:
;       
;
;CREATED BY:   Laila Andersson 17 august 2011 
;FILE: mvn_lpw_spectra.pro
;VERSION:   1.1
;LAST MODIFICATION:   05/16/13
;-

pro mvn_lpw_spectra,output,lpw_const,subcycle,type
;--------------------- Constants Used In This Routine ------------------------------------               
t_epoch=lpw_const.t_epoch
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
time = double(output.SC_CLK1(nn_index))+output.SC_CLK2(nn_index)/2l^16 +t_epoch  
nn_pktnum_extra=total(pktarr)-nn_pktnum  ; if multiple spectras is in one and the same spectra here is how many

;------------------      
 n_lines_temp1 = n_bins_spec/2   
;---------------------------------------------
    
;----------  variable:  spectra   ------------------
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr( nn_pktnum+nn_pktnum_extra)  ,$
   'y'     ,  dblarr( nn_pktnum+nn_pktnum_extra, n_bins_spec),$
   'v'     ,  fltarr( nn_pktnum+nn_pktnum_extra, n_bins_spec))
dlimit=create_struct(   $      
   'datafile'     ,  'Info of file used'  ,$
   'spec'         ,  1, $
   'log'          ,  1, $
   'xsubtitle'    ,  '[sec]', $
   'ysubtitle'    ,  '[alog10(Hz)]', $
   'zsubtitle'    ,  '[raw]', $
   'data_att'     ,  datatype.type)   
;-------------- get the data into the structures  ---------------- 
get_data,'mvn_lpw_pas_mc_len',data=data_mc_len  ; WARNING THIS CAN FAIL AT A BOUNDARY OF A MODE CHANGE
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
;-------------
limit=create_struct(   $                                      ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  subcycle+'_'+type+' Frequency (Hz)' , $  
   'xtitle',  'Time'  ,$  
   'ztitle',  'Power (LSB)'  ,$ 
   'zlog',        1.,  $ 
   'ylog',        1.,  $ 
   'char_size' ,  2.  ,$                                      ;this is not a tplot variable
   'xrange2'  , [min(data.x),max(data.x)], $                  ;for plotting purpuses      not for tplot
   'xstyle2'  ,   1  , $                                      ;for plotting putpuses       not for tplot
   'xlim2'    , [min(data.x),max(data.x)], $                  ;this is the true range    not for tplot
   'ystyle'    , 1  ,$                                        ;for plotting purpuses 
   'yrange'  , [0.9*min(center_freq),1.1*max(center_freq,/nan)], $    ;  'yrange'  , [0.9*min(data.v,/nan),1.1*max(data.v,/nan)], $                   ;this is the true range
   'zstyle'    , 1  ,$                                        ;for plotting purpuses 
   'zrange'  , [1.*power_scale,1.e8])  ;max(data.y,/nan)]))                              ;for plotting purpuses 
;-------------
 store_data,'mvn_lpw_spec_'+type+'_'+subcycle,data=data,limit=limit,dlimit=dlimit
;---------------------------------------------

;----------  variable:  spectra2  value/freq  ------------------
   dlimit.zsubtitle='[power/freq units]'
   data.y=data.y/data.v
;-------------
limit=create_struct(   $                                      ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  subcycle+'_'+type+' Frequency (Hz)' , $  
   'xtitle',  'Time'  ,$  
   'ztitle',  'power/freq'  ,$ 
   'zlog',        1.,  $ 
   'ylog',        1.,  $ 
   'char_size' ,  2.  ,$                                      ;this is not a tplot variable
   'xrange2'  , [min(data.x),max(data.x)], $                  ;for plotting purpuses      not for tplot
   'xstyle2'  ,   1  , $                                      ;for plotting putpuses       not for tplot
   'xlim2'    , [min(data.x),max(data.x)], $                  ;this is the true range    not for tplot
   'ystyle'    , 1  ,$                                        ;for plotting purpuses 
     'yrange'  , [0.9*min(center_freq),1.1*max(center_freq,/nan)], $  ;'yrange'  , [min(data.v,/nan),max(data.v,/nan)], $                   ;this is the true range
   'zstyle'    , 1  ,$                                        ;for plotting purpuses 
   'zrange'  , [min(data.y,/nan)>1.,max(data.y,/nan)*2])                              ;for plotting purpuses 
;-------------
 store_data,'mvn_lpw_spec2_'+type+'_'+subcycle,data=data,limit=limit,dlimit=dlimit
;---------------------------------------------

;-------------  HSBM FFT power---------------------------
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr(nn_pktnum+nn_pktnum_extra)  ,$
   'y'     ,  fltarr(nn_pktnum+nn_pktnum_extra,2) )  ;second line is omitting the 2 lowest bins
   dlimit=create_struct(   $      
   'datafile'     ,  'Info of file used'  ,$
   'xsubtitle'    ,  '[sec]', $
   'ysubtitle'    ,  '[alog 10 raw]', $
     'data_att'     ,  datatype.type)   
   ;-------------- 
get_data,'mvn_lpw_spec_'+type+'_'+subcycle,data=data2
;-------------- 
data.x=data2.x
data.y(*,0)=alog10(total(data2.y,2))
for i=0,nn_pktnum+nn_pktnum_extra-1 do $
      data.y(i,1)=alog10(total(   data2.y(i,2:n_elements(data2.y(0,*))-1)   ))
;------------- 
qq=where(data.y(*,0) GT 0,nq) ; only sum over points > 0 to get the lower yrange correct
limit=create_struct(   $                           ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  'mvn_lpw_spec_tot_power_'+type , $   
    'xtitle',  'Time'  ,$   
   'char_size' ,  2.  ,$                           ;this is not a tplot variable
   'xrange2'  , [min(data.x),max(data.x)], $       ;for plotting purpuses   
   'xstyle2'  ,   1  , $                           ;for plotting putpuses 
   'xlim2'    , [min(data.x),max(data.x)], $                ;this is the true range
   'ystyle'    , 1  ,$                                        ;for plotting purpuses 
   'yrange'  , [0.95*min(data.y(qq,0),/nan),1.05*max(data.y,/nan)] )                              ;for plotting purpuses 
;------------- 
store_data,'mvn_lpw_spec_total_'+type+'_'+subcycle,data=data,limit=limit,dlimit=dlimit
;--------------------------------------------------

;------------- variable:  smp_avg ---------------------------
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr(nn_pktnum)  ,$
   'y'     ,  fltarr(nn_pktnum))
dlimit=create_struct(   $      
   'datafile'     ,  'File info'  ,$
   'data_att'     ,  datatype.type)   
;-------------- derive the time ---------------- 
 data.x = time                                                      
 data.y = output.smp_avg(nn_index)  
;-------------
limit=create_struct(   $                          ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  'Spectra_'+type+'_smp_avg', $
    'xrange2'  , [min(data.x),max(data.x)], $            ;for plotting purpuses   
    'xtitle',  'Time'  ,$  
   'char_size' ,  2.  ,$                                  ;this is not a tplot variable
    'xstyle2'  ,   1  , $                                ;for plotting putpuses 
   'xlim2'    , [min(data.x),max(data.x)], $                ;this is the true range
    'zstyle'    , 1  ,$ 
    'yrange', [-1,max(data.y)+1] )                             
;-------------  
store_data,'mvn_lpw_spec_'+type+'_'+subcycle+'_smp_avg',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------

;------------- variable:  spec_mode --------------------------
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr(nn_pktnum)  ,$
   'y'     ,  fltarr(nn_pktnum))
dlimit=create_struct(   $      
   'datafile'     ,  'File info'  ,$
   'data_att'     ,  datatype.type)   
;-------------- derive the time ---------------- 
 data.x = time                                                      
 data.y = output.orb_md(nn_index)  
;-------------
limit=create_struct(   $                                 ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  'Spectra_'+type+'_mode', $
    'xrange2'  , [min(data.x),max(data.x)], $             ;for plotting purpuses   
    'xtitle',  'Time'  ,$  
   'char_size' ,  2.  ,$                                  ;this is not a tplot variable
    'xstyle2'  ,   1  , $                                ;for plotting putpuses 
   'xlim2'    , [min(data.x),max(data.x)], $                ;this is the true range
    'zstyle'    , 1  ,$ 
    'yrange', [-1,18] )                             
;-------------  
store_data,'mvn_lpw_spec_'+type+'_'+subcycle+'_mode',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------

END
;*******************************************************************







