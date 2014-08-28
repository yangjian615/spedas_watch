;;+
;PROCEDURE:   mvn_lpw_instrument_constants
;PURPOSE:
;  This allowes different constants and calibration information to be located in one place
;  Old calebration data should be keept so that this routine can be used as a historic document 
;  The calibrations numbers are seperated also based on the board
;  the common structure is used in the initially laboratory software, keep the common structure so that that software is in operation 
;
;USAGE:
;        mvn_lpw_instrument_constants,board,lpw_const2=lpw_const2 
;
;INPUTS:
;       board:      which electronics board is used
;
;KEYWORDS:
;       lpw_const2:   if common block is not used then the information can be called for as one large structure 
;       
;CREATED BY:   Laila Andersson 17 august 2011 
;FILE: mvn_lpw_instrument_constants.pro
;VERSION:   1.1
;LAST MODIFICATION:   05/17/13
;-

pro mvn_lpw_instrument_constants,board,lpw_const2=lpw_const2 

common  data_info,output,expected,lpw_const 

;---------------------

print,'(mvn_lpw_instrument_constants) Selected Board: ',board

;--------------- Board Unique Variables ----------------------- 
case board of
 'EM1': BEGIN
                                                                           ; constants associated with DAC
                                                                           ;const_DAC_volt = 130./2048.                              
                                                                           ;20110916 EM1 & EM2 DAC conversion factor                
                 const_lp_bias1_DAC=   -1.0*(130./2048.)
                 const_w_bias1_DAC=    -1.0*(50./2048.)
                 const_lp_guard1_DAC=  -1.0*(10./2048.)
                 const_w_guard1_DAC=   -1.0*(10./2048.)
                 const_lp_stub1_DAC=   -1.0*(10./2048.)
                 const_w_stub1_DAC=    -1.0*(10./2048.)
                 
                 const_lp_bias2_DAC=   -1.0*(130./2048.)
                 const_w_bias2_DAC=    -1.0*(50./2048.)
                 const_lp_guard2_DAC=  -1.0*(10./2048.)
                 const_w_guard2_DAC=   -1.0*(10./2048.)
                 const_lp_stub2_DAC=   -1.0*(10./2048.)
                 const_w_stub2_DAC=    -1.0*(10./2048.)
                
                 
                 ; Constants associated with Boom 1                
                 const_I1_readback=     2.E-10                                 ;20110916 EM1 & EM2 no change  
                                                                               ;const_V2_readback=2.5/2d^15 * 50                          
                 const_V1_readback=     2.5/2d^15 * 238.                       ;20110916 EM1 & EM2 From Bryans calculated and measured gain
                 const_bias1_readback=  2.5/2d^15 *50.
                 const_guard1_readback= 2.5/2d^15 *50.
                 const_stub1_readback=  2.5/2d^15 *50.
 ;      data.y(*,0)=output.adr_w_bias1*const_bias1_readback
 ;      data.y(*,1)=output.adr_w_guard1*const_guard1_readback
 ;      data.y(*,2)=output.adr_w_stub1*const_stub1_readback
 ;      data.y(*,3)=output.adr_w_v1*const_V1_readback
 ;      data.y(*,4)=output.adr_lp_guard1*const_guard1_readback
 ;      data.y(*,5)=output.adr_lp_stub1*const_stub1_readback          
;data.y = output.adr_lp_bias1*const_bias1_readback
                 
                 ; Constants associated with Sweep/boom 2
                 const_I2_readback=     2.E-10                                   ;20110916 EM1 & EM2 no change
                                                                                 ;const_V1_readback=2.5/2d^15 * 50                            ;old
                 const_V2_readback=     2.5/2d^15 * 238.                         ;20110916 EM1 & EM2 From Bryans calculated and measured gain                 
                 const_bias2_readback=  2.5/2d^15 *50.
                 const_guard2_readback= 2.5/2d^15 *50.
                 const_stub2_readback=  2.5/2d^15 *50.
                 
                ; Constants associated with Pass, Active and HSBM                          
                 const_E12_LF =         2.5  / 2d^15                               ;20110921 EM1 & EM2 From David M  (used in PAS_AVG, ACT_AVG and LF_HSBM) 
                 const_E12_MF =         2.5  / 2d^15                               ;20110921 EM1 & EM2 From David M  (used in MF_HSBM)
                 const_E12_HF =         6.25 / 2d^15                               ;20110921 EM1 & EM2 From David M   (used in HF_HSBM)                                 
 ;     data.y(i,0)=output.ATR_W_BIAS1(i) 
 ;     data.y(i,1)=output.ATR_W_GUARD1(i)
 ;     data.y(i,2)=output.ATR_W_STUB1(i)
 ;     data.y(i,3)=output.ATR_LP_BIAS1(i) 
 ;     data.y(i,4)=output.ATR_LP_GUARD1(i)
 ;     data.y(i,5)=output.ATR_LP_STUB1(i)      
 ;     data.y(i,6)=output.ATR_W_BIAS2(i) 
 ;     data.y(i,7)=output.ATR_W_GUARD2(i) 
 ;     data.y(i,8)=output.ATR_W_STUB2(i) 
 ;     data.y(i,9)=output.ATR_LP_BIAS2(i) 
 ;     data.y(i,10)=output.ATR_LP_GUARD2(i) 
 ;     data.y(i,11)=output.ATR_LP_STUB2(i)
 
        END
 'EM2': BEGIN
            print,'(mvn_lpw_instrument_constants) EM2 not activated yet below from EM1 on october 5'           
                 ; constants associated with DAC                             ;20110916 EM1 & EM2 DAC conversion factor
                 const_lp_bias1_DAC=   -1.0*(130./2048.)
                 const_w_bias1_DAC=    -1.0*(50./2048.)
;                 const_lp_bias1_DAC=   -1.0*(180./2048.)
;                 const_w_bias1_DAC=    -1.0*(85./2048.)
                 const_lp_guard1_DAC=  -1.0*(10./2048.)
                 const_w_guard1_DAC=   -1.0*(10./2048.)
                 const_lp_stub1_DAC=   -1.0*(10./2048.)
                 const_w_stub1_DAC=    -1.0*(10./2048.)
                 
                 const_lp_bias2_DAC=   -1.0*(130./2048.)
                 const_w_bias2_DAC=    -1.0*(50./2048.)
;                 const_lp_bias2_DAC=   -1.0*(80./2048.)
;                 const_w_bias2_DAC=    -1.0*(85./2048.)
                 const_lp_guard2_DAC=  -1.0*(10./2048.)
                 const_w_guard2_DAC=   -1.0*(10./2048.)
                 const_lp_stub2_DAC=   -1.0*(10./2048.)
                 const_w_stub2_DAC=    -1.0*(10./2048.)
 
                 ; Constants associated with Boom 1                
                 const_I1_readback=     2.E-10                                     ;20110916 EM1 & EM2 no change                           
                 const_V1_readback=     2.5/2d^15 * 238.                           ;20110916 EM1 & EM2 From Bryans calculated and measured gain
                 const_bias1_readback=  2.5/2d^15 *50.
                 const_guard1_readback= 2.5/2d^15 *50.
                 const_stub1_readback=  2.5/2d^15 *50.                 
                 ; Constants associated with Sweep/boom 2
                 const_I2_readback=     2.E-10                                     ;20110916 EM1 & EM2 no change                          ;old
                 const_V2_readback=     2.5/2d^15 * 238.                           ;20110916 EM1 & EM2 From Bryans calculated and measured gain                
                 const_bias2_readback=  2.5/2d^15 *50.
                 const_guard2_readback= 2.5/2d^15 *50.
                 const_stub2_readback=  2.5/2d^15 *50.                
                ; Constants associated with Pass, Active and HSBM                          
                 const_E12_LF =         2.5  / 2d^15                               ;20110921 EM1 & EM2 From David M  (used in PAS_AVG, ACT_AVG and LF_HSBM) 
                 const_E12_MF =         2.5  / 2d^15                               ;20110921 EM1 & EM2 From David M  (used in MF_HSBM)
                 const_E12_HF =         6.25 / 2d^15                               ;20110921 EM1 & EM2 From David M   (used in HF_HSBM)                               
        END
 'EM3': BEGIN
            print,'(mvn_lpw_instrument_constants) EM3 not activated yet below from EM1 on october 5'           
                 ; constants associated with DAC                             ;20110916 EM1 & EM2 DAC conversion factor
                 const_lp_bias1_DAC=   -1.0*(50./2048.)
                 const_w_bias1_DAC=    -1.0*(85./2048.)
                 const_lp_guard1_DAC=  -1.0*(10./2048.)
                 const_w_guard1_DAC=   -1.0*(12./2048.)
                 const_lp_stub1_DAC=   -1.0*(10./2048.)
                 const_w_stub1_DAC=    -1.0*(12./2048.)
                 
                 const_lp_bias2_DAC=   -1.0*(50./2048.)
                 const_w_bias2_DAC=    -1.0*(85./2048.)
                 const_lp_guard2_DAC=  -1.0*(10./2048.)
                 const_w_guard2_DAC=   -1.0*(12./2048.)
                 const_lp_stub2_DAC=   -1.0*(10./2048.)
                 const_w_stub2_DAC=    -1.0*(12./2048.)
                 ; Constants associated with Boom 1                
                 const_I1_readback=     2.E-10     ;amps/count                    ;20110916 EM1 & EM2 no change                           
                 const_V1_readback=     2.5/2d^15 * 50.                           ;20110916 EM1 & EM2 From Bryans calculated and measured gain
                 const_bias1_readback=  2.5/2d^15 *50.
                 const_guard1_readback= 2.5/2d^15 *50.
                 const_stub1_readback=  2.5/2d^15 *50.                 
                 ; Constants associated with Sweep/boom 2
                 const_I2_readback=     2.E-10                                    ;20110916 EM1 & EM2 no change                          ;old
                 const_V2_readback=     2.5/2d^15 * 50.                           ;20110916 EM1 & EM2 From Bryans calculated and measured gain                
                 const_bias2_readback=  2.5/2d^15 *50.
                 const_guard2_readback= 2.5/2d^15 *50.
                 const_stub2_readback=  2.5/2d^15 *50.                
                ; Constants associated with Pass, Active and HSBM                          
                 const_E12_LF =         2.22 * 2.5  / 2d^15                        ;20110921 EM1 & EM2 From David M  (used in PAS_AVG, ACT_AVG and LF_HSBM) 
                 const_E12_MF =         2.5  / 2d^15                               ;20110921 EM1 & EM2 From David M  (used in MF_HSBM)
                 const_E12_HF =         1.667 * 2.0 / 2d^13                        ;20110921 EM1 & EM2 From David M   (used in HF_HSBM)   
                 const_E12_HF_HG =      0.333 * 2.0 / 2d^13                            
       END
 'FM': BEGIN
                 ; constants associated with DAC                             ;20110916 EM1 & EM2 DAC conversion factor
                 const_lp_bias1_DAC=   -1.0*(50./2048.)
                 const_w_bias1_DAC=    -1.0*(60./2048.)
                 const_lp_guard1_DAC=  -1.0*(10./2048.)
                 const_w_guard1_DAC=   -1.0*(12./2048.)
                 const_lp_stub1_DAC=   -1.0*(10./2048.)
                 const_w_stub1_DAC=    -1.0*(12./2048.)
                 
                 const_lp_bias2_DAC=   -1.0*(50./2048.)
                 const_w_bias2_DAC=    -1.0*(60./2048.)
                 const_lp_guard2_DAC=  -1.0*(10./2048.)
                 const_w_guard2_DAC=   -1.0*(12./2048.)
                 const_lp_stub2_DAC=   -1.0*(10./2048.)
                 const_w_stub2_DAC=    -1.0*(12./2048.)

                 ; Constants associated with Boom 1                
                 const_I1_readback=     2.E-10                                         ;20110916 EM1 & EM2 no change                           
                 const_V1_readback=     2.5/2d^15 * 50.                                ;20110916 EM1 & EM2 From Bryans calculated and measured gain
                 const_bias1_readback=  2.5/2d^15 *50.
                 const_guard1_readback= 2.5/2d^15 *50.
                 const_stub1_readback=  2.5/2d^15 *50.                 
                 ; Constants associated with Sweep/boom 2
                 const_I2_readback=     2.E-10                                          ;20110916 EM1 & EM2 no change                          ;old
                 const_V2_readback=     2.5/2d^15 * 50.                                 ;20110916 EM1 & EM2 From Bryans calculated and measured gain                
                 const_bias2_readback=  2.5/2d^15 *50.
                 const_guard2_readback= 2.5/2d^15 *50.
                 const_stub2_readback=  2.5/2d^15 *50.                
                ; Constants associated with Pass, Active and HSBM  
                 const_E12_LF =         2.22 * 2.5  / 2d^15                               ;20110921 EM1 & EM2 From David M  (used in PAS_AVG, ACT_AVG and LF_HSBM) 
                 const_E12_MF =         2.5  / 2d^15                                      ;20110921 EM1 & EM2 From David M  (used in MF_HSBM)
                 const_E12_HF =         1.667 * 2.0 / 2d^13                               ;20110921 EM1 & EM2 From David M   (used in HF_HSBM)   
                 const_E12_HF_HG =      0.333 * 2.0 / 2d^13                                                         
   
              ;   const_E12_LF =         0.9*2.22 * 2.5  / 2d^15                          ;20120413  Laila's attempt to correct the above
              ;   const_E12_MF =         0.94*2.5  / 2d^15                                ;20120413  Laila's attempt to correct the above
              ;   const_E12_HF =         0.9*1.667 * 2.0 / 2d^13                          ;20120413  Laila's attempt to correct the above
              ;   const_E12_HF_HG =      0.333 * 2.0 / 2d^13                                                         
 
       END
ENDCASE        
;--------------- LPW Variables Independend of Board ----------------------- 


    ;------------------------- TIME: unique information ---------------------------------------------
    ;t_epoch=time_double('2000-01-02/00:00:00')
    t_epoch = time_double('2000-01-01/12:00:00')                    ; Working for ATLO fall 2012 
    ;t_epoch=time_double('2001-01-01/00:00:00')                     ; the GSE epoch time     
    ; From Tim Quin December 21, 2012 9:37 AM
    ;    The Spacecraft Simulator GSE (SSG) Software on the EM laptop has been updated
    ;    so the EPOCH now matches the LM spacecraft EPOCH of 1Jan2000, 12:00 UTC.
    
    ;
    ;t_epoch_expected=t_epoch  +6.*60.*60.      ;summer  the GSE epoch time   seems to be UT vs local time difference
    t_epoch_expected=t_epoch  +7.*60.*60.      ;winter  the GSE epoch time   seems to be UT vs local time difference
   ;-------------------------END: TIME ---------------------------------------------
   
  
   ;-------------------------Operation constants ---------------------------------------------
    const_sign = 2048                                              ; to convert value to a sign value
    subcycle_length=[4.,8.,16.,32., 64.,128,256.]/4.               ; table from ICD 7.12.3 and a subcycle is a quarter of the time
    nn_modes=16                                        ; assumption, number of modes.....
    nn_dac=12                                         ; number of predefined DAC points pre mode , note there are 16 slots, 4 are reserve therefore is the number 12
    sample_aver=[16,32,64,128,256,512,1024,2048]             ; table from ICD  7.12.3
   ;-------------------------END: Operation constants ---------------------------------------------
        
    
    ;-------------------------SWEEP: unique information ---------------------------------------------   
    ;swp specific  (this is the number of table element in the sweep hance also adr specific)
    nn_swp =128                   ; number of sampels per subcycle -for the potential in sweep cycle
    nn_swp_steps=127                  ; for the sweep wait the first point to settle then sample
    nn_active_steps=126           ; the last point is omitted, do not contain important information  
    ;-------------------------END: SWEEP ---------------------------------------------
   
   
    ;------------------------- HSBM: unique inforamtion --------------------------------------------- 
    ;hsbm sepcific
    nn_hsbm_lf=1024L
    nn_hsbm_mf=4096L
    nn_hsbm_hf=4096L
    nn_bin_lf=56
    f_bin_lf=intarr(nn_bin_lf)   ;64ks/s channel 
    f_bin_lf( 0:15)=1
    f_bin_lf(16:23)=2
    f_bin_lf(24:31)=4
    f_bin_lf(32:39)=8
    f_bin_lf(40:47)=16
    f_bin_lf(48:55)=32
    nn_bin_mf=56
    f_bin_mf=intarr(nn_bin_mf)   ;64ks/s channel 
    f_bin_mf( 0:15)=1
    f_bin_mf(16:23)=2
    f_bin_mf(24:31)=4
    f_bin_mf(32:39)=8
    f_bin_mf(40:47)=16
    f_bin_mf(48:55)=32   
    nn_bin_hf=128
    f_bin_hf=intarr(nn_bin_hf)   ;4Ms/s channel 
    f_bin_hf( 0:47)=1
    f_bin_hf(48:71)=2
    f_bin_hf(72:95)=4
    f_bin_hf(96:119)=8
    f_bin_hf(120:127)=16                                 ;mf and hf is the same
    dt_hsbm_lf=1./(2.^10)                                    ;1024 samples /sec
    dt_hsbm_mf=1./(2.^16)                                    ;~64k samples /sec
    dt_hsbm_hf=1./(2.^22)                                    ;~4M samples /sec
     ;-------------------------END: HSBM ---------------------------------------------
  
  
     ;-------------------------POWER SPECTRAS: unique information---------------------------------------------    
    ;pas/act specific
    nn_pa = 64 ; number of sampels per subcycle
    
    ;I cannot find this used yet, not yet included in lpw_const
    new_name_lf=[1,2,4,8,16,32,64,128]                      ;pas_spec number of 1024 FFT's to ave together on E12_LF channel   ; table from ICD 7.12.3
    new_name_mf=[1,2,4,8,16,32,64,128]                      ;pas_spec number of 1024 FFT's to ave together on E12_MF channel reserve   ; table from ICD 7.12.3
    new_name_hf=[1,2,4,8,16,32,64,128]                      ;pas_spec number of 1024 FFT's to ave together on E12_HF channel reserve   ; table from ICD 7.12.3
    
    ;spectra specific
    nn_fft_size = 1024d                                                   ;number of points the fft in the FPGA work with, fix
    nn_fft_lf =   1d                                                ;n_bins_spec: 1 ks/S = 56
    nn_fft_mf =  64d                                               ;n_bins_spec: 64 ks/S = 56
    nn_fft_hf =  4096d                                             ;n_bins_spec: 4 Ms/S = 128 
    power_scale_hf=1./16 ;dt_hsbm_lf  ;^2    ;yscale  smallest value ->1 count level
    power_scale_mf=1./16 ;dt_hsbm_mf ;^2    ;yscale smallest value ->1 count level
    power_scale_lf=1./16 ;dt_hsbm_hf ;^2    ;yscale smallest value ->1 count level
                                                                  ; pre-define spectra frequency ranges in the fpga:
     center_freq_lf = 1.0*[.25,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16.5,18.5,20.5,22.5,24.5,26.5,28.5,30.5,$
                   33.5,37.5,41.5,45.5,49.5,53.5,57.5,61.5,67.5,75.5,83.5,91.5,99.5,107.5,115.5,123.5,$
                   135.5,151.5,167.5,183.5,199.5,215.5,231.5,247.4,271.5,303.5,335.5,367.5,399.5,431.5,$
                   463.5,495.5] 
     f_low_mf=1.0*[10,32,96,160,224,288,352,416,480,544,608,672,736,800,864,928,992,1120,1248,1376,1504,1632, $  
                   1760,1888,2016,2272,2528,2784,3040,3296,3552,3808,4064,4576,5088,5600,6112,6624,7136,7648,8160, $
                   9184,10208,11232,12256,13280,14304,15328,16352,18400,20448,22496,24544,26592,28640,30688]
    center_freq_mf=1.0*[16,64,128,192,256,320,384,448,512,576,640,704,768,832,896,960,1056,1184,1312,1440,1568, $
                   1696,1824,1952,2144,2400,2656,2912,3168,3424,3680,3936,4320,4832,5344,5856,6368,6880,7392,7904, $
                   8672,9696,10720,11744,12768,13792,14816,15840,17376,19424,21472,23520,25568,27616,29664,31712]  
     center_freq_hf = 1.0*[1,4,8,12,16,20,24,28,32,36,40,44,48,52,56,60,64,68,72,76,80,84,88,92,96,100,104,108,$
                   112,116,120,124,128,132,136,140,144,148,152,156,160,164,168,172,176,180,184,188,194,202,210,$
                   218,226,234,242,250,258,266,274,282,290,298,306,314,322,330,338,346,354,362,370,378,390,406,422,438,$
                   454,470,486,502,518,534,550,566,582,598,614,630,646,662,678,694,710,726,742,758,782,814,846,878,$
                   910,942,974,1006,1038,1070,1102,1134,1166,1198,1230,1262,1294,1326,1358,1390,1422,1454,1486,1518,$
                   1566,1630,1694,1758,1822,1886,1950,2014]*nn_fft_size   
   ;   print,'(mvn_lpw_spectra ) is it correct to take table value * fft_size ???'  
    
    f_zero_freq=1./1.     ; is the FPGA code corrected such that all power is not dumped in the zero bin? 
     ;print,'(mvn_lpw_spectra )  Check with Max what and if we need to correct the first bin!!!' 
    ;-------------------------END: POWER SPECTRAS---------------------------------------------
   
     
    ;------------------------- EUV  unique information ---------------------------------------------
    ;euv specific
    nn_euv=16                                            ;number of samples in one package (constant, not associated with the subcycle period)
    nn_euv_diodes=4                                      ;number of diodes
    dt_euv=1.0                                           ;sampling rate [sec]
    euv_diod_A=1.0                                       ; conversion number to be identified
    euv_diod_B=1.0                                       ; conversion number to be identified
    euv_diod_C=1.0                                       ; conversion number to be identified
    euv_diod_D=1.0                                       ; conversion number to be identified
    ;euv_temp=1.0                                        ; conversion number to be identified  
    ;from David Summers 2012 July
    ;If you take the 20 bit temperature data and divide it by 16 to get 16 bit numbers, the numbers should follow the following conversion:
    ;Temp_in_DN(16 bit) = 41.412 x Temp_in_deg_C - 8160.7
    euv_temp=[1.0/16 ,  8160.7,  41.412]   ;    (measured *  euv_temp(0) +   euv_temp(1)) /euv_temp(2)  = Temp_in_deg_C
     ;-------------------------END: EUV---------------------------------------------
   
      
       
    
;------------- Put the information into a structure: LPW_const,LPW_const2 -------------

lpw_const=create_struct(   $        ;To export the data in workable form
   't_epoch',                   t_epoch,  $
   't_epoch_expected',          t_epoch_expected,$
   'sign',                      const_sign, $
   'sc_lngth',                  subcycle_length,$ 
   'sample_aver',               sample_aver,$
   'nn_modes',                  nn_modes ,$ 
   'nn_dac',                    nn_dac,$
   'nn_pa',                     nn_pa,$
   'nn_swp',                    nn_swp,$  
   'nn_swp_steps',              nn_swp_steps,$ 
   'nn_active_steps',           nn_active_steps,$
   'nn_hsbm_lf',                nn_hsbm_lf,$
   'nn_hsbm_mf',                nn_hsbm_mf, $
   'nn_hsbm_hf',                nn_hsbm_hf, $
   'nn_bin_lf',                 nn_bin_lf, $
   'nn_bin_mf',                 nn_bin_mf, $
   'nn_bin_hf',                 nn_bin_hf, $
   'nn_fft_size',               nn_fft_size,$  
   'nn_fft_lf',                 nn_fft_lf,$  
   'nn_fft_mf',                 nn_fft_mf,$  
   'nn_fft_hf',                 nn_fft_hf,$    
   'nn_euv',                    nn_euv, $
   'nn_euv_diodes',             nn_euv_diodes, $
   'lp_bias1_DAC',              const_lp_bias1_DAC, $
   'w_bias1_DAC',               const_w_bias1_DAC, $
   'lp_guard1_DAC',             const_lp_guard1_DAC, $
   'w_guard1_DAC',              const_w_guard1_DAC, $  
   'lp_stub1_DAC',              const_lp_stub1_DAC, $
   'w_stub1_DAC',               const_w_stub1_DAC, $       
   'lp_bias2_DAC',              const_lp_bias2_DAC, $
   'w_bias2_DAC',               const_w_bias2_DAC, $
   'lp_guard2_DAC',             const_lp_guard2_DAC, $
   'w_guard2_DAC',              const_w_guard2_DAC, $  
   'lp_stub2_DAC',              const_lp_stub2_DAC, $
   'w_stub2_DAC',               const_w_stub2_DAC, $     
   'I1_readback',               const_I1_readback, $
   'V1_readback',               const_V1_readback, $ 
   'bias1_readback',            const_bias1_readback, $
   'guard1_readback',           const_guard1_readback, $
   'stub1_readback',            const_stub1_readback, $
   'I2_readback',               const_I2_readback, $
   'V2_readback',               const_V2_readback, $ 
   'bias2_readback',            const_bias2_readback, $
   'guard2_readback',           const_guard2_readback, $
   'stub2_readback',            const_stub2_readback, $  
   'E12_lf',                    const_E12_lf, $   
   'E12_mf',                    const_E12_mf, $  
   'E12_hf',                    const_E12_hf, $ 
   'E12_hf_hg',                 const_E12_HF_HG,$ 
   'f_bin_lf',                  f_bin_lf,$
   'f_bin_mf',                  f_bin_mf, $  
   'f_bin_hf',                  f_bin_hf, $
   'f_zero_freq' ,              f_zero_freq, $
   'power_scale_lf',            power_scale_lf,$  
   'power_scale_mf',            power_scale_mf,$  
   'power_scale_hf',            power_scale_hf,$  
   'center_freq_lf',            center_freq_lf,$  
   'center_freq_mf',            center_freq_mf ,$  
   'center_freq_hf',            center_freq_hf,$  
   'dt_hsbm_lf',                dt_hsbm_lf ,$                               
   'dt_hsbm_mf',                dt_hsbm_mf ,$                               
   'dt_hsbm_hf',                dt_hsbm_hf ,$                                  
   'dt_euv',                    dt_euv, $
   'euv_diod_A',                euv_diod_A, $
   'euv_diod_B',                euv_diod_B, $
   'euv_diod_C',                euv_diod_C, $
   'euv_diod_D',                euv_diod_D, $
   'euv_temp',                  euv_temp   )
 
lpw_const2=lpw_const 
  
end

;*********************************************************************************

