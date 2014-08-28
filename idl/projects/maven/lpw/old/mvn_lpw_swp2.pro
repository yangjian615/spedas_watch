;;+
;PROCEDURE:   mvn_lpw_swp2
;PURPOSE:
;  Takes the decumuted data (L0) from the SWP2 packet
;  and turn it into L1 and L2 data in tplot structures
;
;USAGE:
;  mvn_lpw_swp2,output,lpw_const
;
;INPUTS:
;       output:         L0 data 
;       lpw_const:      information of lpw calibration etc
;
;KEYWORDS:
;       
;
;CREATED BY:   Laila Andersson 17 august 2011 
;FILE: mvn_lpw_swp2.pro
;VERSION:   1.1
;LAST MODIFICATION:   05/16/13
;-

;*******************************************************************

pro mvn_lpw_swp2, output,lpw_const
;--------------------- Constants ------------------------------------
subcycle_length=lpw_const.sc_lngth
sample_aver=lpw_const.sample_aver
nn_steps=long(lpw_const.nn_swp)  
t_epoch=lpw_const.t_epoch
const_I2_readback= lpw_const.I2_readback
const_V1_readback= lpw_const.V1_readback
const_lp_bias2_DAC = lpw_const.lp_bias2_DAC 

;Zero Crossing Offset (unsigned)  Effective Zero Crossing = I_ZERO2 + DYN_XING*32 ; from ICD 7.12.3
;--------------------------------------------------------------------
nn_pktnum = output.p11                                ; number of data packages 
nn_size   = long(nn_pktnum)*long(nn_steps)                         ; number of data points
t_s=subcycle_length(output.mc_len(output.swp2_i))*3./128       ;this is to correct for the sub-second delay
dt=subcycle_length(output.mc_len(output.swp2_i))/nn_steps      ;this is how long time each measurement point took
                                                               ;the time in the header is associated with the last point in the measurement
                                                               ;therefore is the time corrected by the thength of the subcycle_length
time      = double(output.SC_CLK1(output.swp2_i)) + output.SC_CLK2(output.swp2_i)/2l^16+t_epoch-t_s-subcycle_length(output.mc_len(output.swp2_i))
;--------------------------------------------------------------------

;------------- Checks ---------------------
if output.p11 NE n_elements(output.swp2_i) then stanna
if n_elements(output.swp2_i) EQ 0 then print,'(mvn_lpw_swp2) No packages where found <---------------'
;-----------------------------------------

;--------------- variable: V1  -------------------------
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr(nn_size)  ,$
   'y'     ,  fltarr(nn_size))
dlimit=create_struct(   $      
   'datafile'     ,  'Info of file used'  ,$
   'spec'         ,  0, $
   'log'          ,  0, $
   'xsubtitle'    ,  '[sec]', $
   'ysubtitle'    ,  '[raw units]', $
   'data_att'     ,  datatype.type)   
;-------------- the information ---------------- 
print,'(mvn_lpw_swp2) Warning needs to get year and date into the time array'
for i=0L,nn_pktnum-1 do data.x(nn_steps*i:nn_steps*(i+1)-1) = time(i) + dindgen(nn_steps)*dt(i)                                                                                                                      
for i=0L,nn_pktnum-1 do data.y(nn_steps*i:nn_steps*(i+1)-1) = output.swp2_V1(i,*) * const_V1_readback 
;------------- 
limit=create_struct(   $                              ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  'mvn_lpw_swp2_V1 !C!C V' , $  
   'xtitle',  'Time'  ,$  
   'char_size' ,  1.  ,$                              ;this is not a tplot variable
   'xrange2'  , [min(data.x),max(data.x)], $          ;for plotting purpuses   
   'xstyle2'  ,   1  , $                              ;for plotting putpuses 
   'xlim2'    , [min(data.x),max(data.x)], $                ;this is the true range
   'ystyle'    , 1  ,$                                        ;for plotting purpuses 
   'yrange'  , [min(data.y),max(data.y)] ) 
;-------------
store_data,'mvn_lpw_swp2_V1',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------

;--------------- variable: I2 ---------------------------
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr(nn_size)  ,$
   'y'     ,  fltarr(nn_size,2) ,$
   'v'     ,  fltarr(nn_size,2))
dlimit=create_struct(   $      
   'datafile'     ,  'Info of file used'  ,$
   'spec'         ,  0, $
   'log'          ,  0, $
   'xsubtitle'    ,  '[sec]', $
   'ysubtitle'    ,  '[raw units]', $
   'data_att'     ,  datatype.type)   
;-------------- derive the time ---------------- 
print,'(mvn_lpw_swp2) Warning needs to get year and date into the time array'
for i=0L,nn_pktnum-1 do data.x(nn_steps*i:nn_steps*(i+1)-1)=time(i) +  dindgen(nn_steps)*dt(i)                                                                                                                
for i=0L,nn_pktnum-1 do begin
       data.y(nn_steps*i:nn_steps*(i+1)-1,0)=(output.swp2_I2(i,*)-output.I_ZERO2(i)*16)*const_I2_readback   ;with zero correction
       data.y(nn_steps*i:nn_steps*(i+1)-1,1)=(output.swp2_I2(i,*))*const_I2_readback                        ;without zero correction
endfor
;--------------------------------------------------
limit=create_struct(   $                               ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  'mvn_lpw_swp2_I2 !C!C I' , $  
   'xtitle',  'Time'  ,$  
   'char_size' ,  1.  ,$                              ;this is not a tplot variable
   'spec',        0, $                                ;line plots
   'labels',   ['i!Dcorr!N','no i!Dzero!N'], $        ;lable the different lines
   'labflag',    1 ,$ 
   'colors',    [0,6] ,$                              ;color for tplot on the different lines   
   'xrange2'  , [min(data.x),max(data.x)], $          ;for plotting purpuses   not working in tplot 
   'xstyle2'  ,   1  , $                              ;for plotting putpuses 
   'xlim2'    , [min(data.x),max(data.x)], $                ;this is the true range
   'ystyle'    , 1  ,$                                        ;for plotting purpuses 
   'yrange'  , [min(data.y),max(data.y)] ) 
;-------------  
store_data,'mvn_lpw_swp2_I2',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------

;--------------- variable:  offsets ---------------------------
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr(nn_pktnum )  ,$
   'y'     ,  fltarr(nn_pktnum ,2))
dlimit=create_struct(   $      
   'datafile'     ,  'Info of file used' , $
   'data_att'     ,  datatype.type)   
;-------------- derive the time ---------------- 
data.x=time                                                                                                               
for i=0,nn_pktnum-1 do begin
       data.y(i,0)=output.I_ZERO2(i)               ; RAW ADC value
       data.y(i,1)=output.swp2_dyn_offset2(i) * const_lp_bias2_DAC      ; Volt 
endfor
;-------------
limit=create_struct(   $                                 ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  'I_zero and Dyn_offset', $  
   'xtitle',  'Time'  ,$  
   'char_size' ,  1.  ,$                              ;this is not a tplot variable
   'spec',        0, $                                ;line plots
   'labels',   ['i!Dzero!N','Dyn!Doffset!N'], $        ;lable the different lines
   'labflag',    1 ,$ 
   'colors',    [0,6] ,$                              ;color for tplot on the different lines   
   'xrange2'  , [min(data.x),max(data.x)], $          ;for plotting purpuses   not working in tplot 
   'xstyle2'  ,   1  , $                              ;for plotting putpuses 
   'xlim2'    , [min(data.x),max(data.x)], $                ;this is the true range
   'ystyle'    , 1  ,$                                        ;for plotting purpuses 
   'yrange'  , [0.9*min(data.y),1.1*max(data.y)]) 
;-------------  
store_data,'mvn_lpw_swp2_offset',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------

;--------------- variable:  IV-bin-spectra ---------------------------
data=create_struct(   $        
   'x'     ,  dblarr(nn_pktnum)  ,$
   'y'     ,  fltarr(nn_pktnum,nn_steps) ,$
   'v'     ,  fltarr(nn_pktnum,nn_steps)  )
dlimit=create_struct(   $      
   'datafile'     ,  'Info of file used'  ,$
   'spec'         ,  1, $
   'log'          ,  0, $
   'xsubtitle'    ,  '[sec]', $
   'ysubtitle'    ,  '[Bin number]', $
   'zsubtitle'    ,  '[I-zero raw units]', $
   'data_att'     ,  datatype.type)   
;-------------- derive the time ----------------                                                                                                                       
 data.x=time
print,'(mvn_lpw_swp2) This is using bin to each current, nott sorted in any manner'
for i=0,nn_pktnum-1 do  begin
    data.y(i,*)=(output.swp2_I2(i,*)-output.I_ZERO2(i)*16)*const_I2_readback   ;should be the same as for I1
    data.v(i,*)=indgen(nn_steps)                                 ;the potential-sweep based on the atr, do not use output information!!!
endfor
;-------------
limit=create_struct(   $                                   ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  'Bin' , $  
   'xtitle',  'Time'  ,$  
   'ztitle',  'Current (corr i_zero)'  ,$  
   'char_size' ,  1.  ,$                                  ;this is not a tplot variable
   'xrange2'  , [min(data.x),max(data.x)], $              ;for plotting purpuses    not for tplot  
   'xstyle2'  ,   1  , $                                  ;for plotting putpuses     not for tplot
   'xlim2'    , [min(data.x),max(data.x)], $              ;this is the true range
    'zstyle'    , 1  ,$                                    ;for plotting purpuses 
    'yrange'  , [min(data.v),max(data.v)], $
    'ystyle'  ,   1  , $                               ;for plotting putpuses    
    'zrange'  , [min(data.y),max(data.y)])                 ;for plotting purpuses 
;-------------
  store_data,'mvn_lpw_swp2_IV_bin',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------

get_data,'mvn_lpw_atr_swp',data=data2  
tmp=size(data2)
if tmp(0) EQ 1 then begin
;--------------- variable:  IV-spectra ---------------------------
data=create_struct(   $        
   'x'     ,  dblarr(nn_pktnum)  ,$
   'y'     ,  fltarr(nn_pktnum,nn_steps) ,$
   'v'     ,  fltarr(nn_pktnum,nn_steps)  )
dlimit=create_struct(   $      
   'datafile'     ,  'Info of file used'  ,$
   'spec'         ,  1, $
   'log'          ,  0, $
   'xsubtitle'    ,  '[sec]', $
   'ysubtitle'    ,  '[V raw units]', $
   'zsubtitle'    ,  '[I-zero raw units]', $
   'data_att'     ,  datatype.type)   
;-------------- derive the time ----------------                                                                                                                       
 data.x=time
print,'(mvn_lpw_swp2) Warning need to verify that the use of the sweep table is correct!!!!' 
get_data,'mvn_lpw_atr_swp',data=data2    ;this is what is stored as  the sweep, to make sure I do not twist the orded in two different places  
get_data,'mvn_lpw_swp2_offset',data=data3
for i=0,nn_pktnum-1 do  begin
      tmp=min(data.x(i)-data2.x +1e9*(data.x(i)-data2.x LT -0.2),ii)
      tmp=sort(data2.y(ii,*)) 
    data.y(i,*) = (output.swp2_I2(i,tmp(*))-output.I_ZERO2(i)*16)*const_I2_readback   ;should be the same as for I1
    data.v(i,*) = data2.y(ii,tmp(*)) + data3.y(i,1)  ;* const_lp_bias2_DAC 
 endfor
;-------------
limit=create_struct(   $                                   ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  'Volt' , $  
   'xtitle',  'Time'  ,$  
   'ztitle',  'Current (corr i_zero)'  ,$  
   'char_size' ,  1.  ,$                                  ;this is not a tplot variable
   'xrange2'  , [min(data.x),max(data.x)], $              ;for plotting purpuses    not for tplot  
   'xstyle2'  ,   1  , $                                  ;for plotting putpuses     not for tplot
   'xlim2'    , [min(data.x),max(data.x)], $              ;this is the true range
   'yrange'  , [min(data.v),max(data.v)], $
    'ystyle'  ,   1  , $                               ;for plotting putpuses       
    'zstyle'    , 1  ,$                                    ;for plotting purpuses 
   'zrange'  , [min(data.y),max(data.y)])                 ;for plotting purpuses 
;-------------
  store_data,'mvn_lpw_swp2_IV',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------
endif

;------------- variable:  swp2_mc_len ---------------------------
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr(nn_pktnum)  ,$
   'y'     ,  fltarr(nn_pktnum))
dlimit=create_struct(   $      
   'datafile'     ,  'File info'  ,$
   'data_att'     ,  datatype.type)   
;-------------- derive the time ---------------- 
 data.x=time                                                      
 data.y=subcycle_length(output.mc_len(output.swp2_i))*4.
;-------------
limit=create_struct(   $                          ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  'swp2_mc_len', $
   'xtitle',  'Time'  ,$  
  'char_size' ,  1.  ,$                                  ;this is not a tplot variable
   'xrange2'  , [min(data.x),max(data.x)], $            ;for plotting purpuses   
   'xstyle2'  ,   1  , $                                ;for plotting putpuses 
   'xlim2'    , [min(data.x),max(data.x)], $                ;this is the true range
   'ystyle'    , 1  ,$   
   'yrange', [0,300])                                 
;-------------  
store_data,'mvn_lpw_swp2_mc_len',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------

;------------- variable:  smp_avg ---------------------------
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr(nn_pktnum)  ,$
   'y'     ,  fltarr(nn_pktnum))
dlimit=create_struct(   $      
   'datafile'     ,  'File info'  ,$
   'data_att'     ,  datatype.type)   
;-------------- derive the time ---------------- 
 data.x=time                                                   
 data.y=sample_aver(output.smp_avg(output.swp2_i))       ; from ICD table
;-------------
limit=create_struct(   $                                 ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  'swp2_smp_avg', $
    'xrange2'  , [min(data.x),max(data.x)], $            ;for plotting purpuses   
    'xtitle',  'Time'  ,$  
   'char_size' ,  2.  ,$                                  ;this is not a tplot variable
    'xstyle2'  ,   1  , $                                 ;for plotting putpuses 
   'xlim2'    , [min(data.x),max(data.x)], $                ;this is the true range
    'zstyle'    , 1  ,$ 
    'yrange', [0,2050] )                             
;-------------  
store_data,'mvn_lpw_swp2_smp_avg',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------

;------------- variable:  swp2_mode ---------------------------
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr(nn_pktnum)  ,$
   'y'     ,  fltarr(nn_pktnum))
dlimit=create_struct(   $      
   'datafile'     ,  'File info'  ,$
   'data_att'     ,  datatype.type)   
;-------------- derive the time ---------------- 
 data.x=time                                                      
 data.y=output.orb_md(output.swp2_i)
;-------------
limit=create_struct(   $                          ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  'swp2_mode', $
   'xtitle',  'Time'  ,$  
  'char_size' ,  1.  ,$                                  ;this is not a tplot variable
   'xrange2'  , [min(data.x),max(data.x)], $            ;for plotting purpuses   
   'xstyle2'  ,   1  , $                                ;for plotting putpuses 
   'xlim2'    , [min(data.x),max(data.x)], $                ;this is the true range
   'ystyle'    , 1  ,$   
   'yrange', [-1,18])                             
;-------------  
store_data,'mvn_lpw_swp2_mode',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------

end
;*******************************************************************









