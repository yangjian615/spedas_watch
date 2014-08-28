;;+
;PROCEDURE:   mvn_lpw_swp1
;PURPOSE:
;  Takes the decumuted data (L0) from the SWP1 packet
;  and turn it into L1 and L2 data in tplot structures
;
;USAGE:
;  mvn_lpw_swp1,output,lpw_const
;
;INPUTS:
;       output:         L0 data 
;       lpw_const:      information of lpw calibration etc
;
;KEYWORDS:
;       
;
;CREATED BY:   Laila Andersson 17 august 2011 
;FILE: mvn_lpw_swp1.pro
;VERSION:   1.1
;LAST MODIFICATION:   05/16/13
;-

pro mvn_lpw_swp1, output,lpw_const
;--------------------- Constants ------------------------------------
subcycle_length=lpw_const.sc_lngth
sample_aver=lpw_const.sample_aver
nn_steps=long(lpw_const.nn_swp)  
t_epoch=lpw_const.t_epoch
const_I1_readback= lpw_const.I1_readback
const_V2_readback= lpw_const.V2_readback
const_lp_bias1_DAC = lpw_const.lp_bias1_DAC 
;--------------------------------------------------------------------
nn_pktnum = output.p10                                         ; number of data packages 
nn_size   = long(nn_pktnum)*long(nn_steps)                     ; number of data points
dt=subcycle_length(output.mc_len(output.swp1_i))/nn_steps
t_s=subcycle_length(output.mc_len(output.swp1_i))*3./128       ;this is how long time each measurement point took
                                                               ;the time in the header is associated with the last point in the measurement
                                                               ;therefore is the time corrected by the thength of the subcycle_length
time      = double(output.SC_CLK1(output.swp1_i)) + output.SC_CLK2(output.swp1_i)/2l^16+t_epoch-t_s-subcycle_length(output.mc_len(output.swp1_i))
;---------------------------------------------

;------------- Checks ---------------------
if output.p10 NE n_elements(output.swp1_i) then stanna
if n_elements(output.swp1_i) EQ 0 then print,'(mvn_lpw_swp1) No packages where found <---------------'
;-----------------------------------------

;--------------- variable: V2   ------------------
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
;-------------- derive the time ---------------- 
for i=0L,nn_pktnum-1 do data.x(nn_steps*i:nn_steps*(i+1)-1) = time(i) + dindgen(nn_steps) * dt(i)                                                                                                                  
for i=0L,nn_pktnum-1 do data.y(nn_steps*i:nn_steps*(i+1)-1) = output.swp1_V2(i, *) * const_V2_readback  
;-------------
limit=create_struct(   $                           ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  'mvn_lpw_swp1_V2 !C!C V' , $  
   'xtitle',  'Time'  ,$  
   'char_size' ,  1.  ,$                          ;this is not a tplot variable
   'xrange2'  , [min(data.x),max(data.x)], $      ;for plotting purpuses   
   'xstyle2'  ,   1  , $                          ;for plotting putpuses 
   'xlim2'    , [min(data.x),max(data.x)], $                ;this is the true range
   'ystyle'    , 1  ,$                                        ;for plotting purpuses 
   'yrange'  , [min(data.y),max(data.y)] ) 
;--------------  
store_data,'mvn_lpw_swp1_V2',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------

;--------------- variable:  I1 ---------------------------
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr(nn_size)  ,$
   'y'     ,  fltarr(nn_size,2) ,$
   'v'     ,  fltarr(nn_size,2))              ;this is the raw signal and the corrected signal for the i_zero offset
dlimit=create_struct(   $      
   'datafile'     ,  'Info of file used'  ,$
   'spec'         ,  0, $
   'log'          ,  0, $
   'xsubtitle'    ,  '[sec]', $
   'ysubtitle'    ,  '[raw units]', $
   'data_att'     ,  datatype.type)   
;-------------- derive the time ---------------- 
for i=0L,nn_pktnum-1 do data.x(nn_steps*i:nn_steps*(i+1)-1)= time(i) + dindgen(nn_steps)*dt(i)                                                                                                                 
for i=0L,nn_pktnum-1 do begin
       data.y(nn_steps*i:nn_steps*(i+1)-1,0) = (output.swp1_I1(i,*)-output.I_ZERO1(i)*16)*const_I1_readback   ;with zero correction
       data.y(nn_steps*i:nn_steps*(i+1)-1,1) = (output.swp1_I1(i,*))*const_I1_readback                        ;without zero correction
endfor
;-------------
limit=create_struct(   $                                 ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  'mvn_lpw_swp1_I1 !C!C I' , $  
   'xtitle',  'Time'  ,$  
   'char_size' ,  1.  ,$                                 ;this is not a tplot variable
   'spec',        0, $                                  ;line plots
   'labels',   ['i!Dcorr!N','no i!Dzero!N'], $          ;lable the different lines
   'labflag',    1 ,$ 
   'colors',    [0,6] ,$                                ;color for tplot on the different lines   
   'ystyle'    , 1  ,$                                  ;for plotting purpuses 
   'yrange'  , [min(data.y),max(data.y)], $             ;for plotting purpuses   working in tplot
   'xrange2'  , [min(data.x),max(data.x)], $            ;for plotting purpuses   not working in tplot 
   'xstyle2'  ,   1  , $                                ;for plotting putpuses 
   'xlim2'    , [min(data.x),max(data.x)] ) 
;-------------  
store_data,'mvn_lpw_swp1_I1',data=data,limit=limit,dlimit=dlimit
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
data.x = time                                                                                                                
for i=0,nn_pktnum-1 do begin
       data.y(i,0) = output.I_ZERO1(i)     ; RAW ADC value
       data.y(i,1) = output.swp1_dyn_offset1(i)  * const_lp_bias1_DAC      ; Volt 
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
   'yrange'  , [min(data.y),max(data.y)]) 
;-------------  
store_data,'mvn_lpw_swp1_offset',data=data,limit=limit,dlimit=dlimit
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
 data.x = time
print,'(mvn_lpw_swp1) This is using bin to each current, not sorted in any manner'
for i=0,nn_pktnum-1 do  begin
    data.y(i,*)=(output.swp1_I1(i,*)-output.I_ZERO1(i)*16)*const_I1_readback   ;should be the same as for I1
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
  store_data,'mvn_lpw_swp1_IV_bin',data=data,limit=limit,dlimit=dlimit
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
   'ysubtitle'    ,  '[Volt]', $
   'zsubtitle'    ,  '[A]', $
   'data_att'     ,  datatype.type)   
;-------------- derive the time ----------------                                                                                                                       
  data.x = time
  print,'(mvn_lpw_swp1) Warning need to verify that the use of the sweep table is correct!!!!' 
  get_data,'mvn_lpw_atr_swp',data=data2    ;this is what is stored as  the sweep, to make sure I do not twist the orded in two different places  
  get_data,'mvn_lpw_swp1_offset',data=data3
  for i=0,nn_pktnum-1 do  begin
      tmp=min(data.x(i)-data2.x +1e9*(data.x(i)-data2.x LT -0.2),ii)
      tmp=sort(data2.y(ii,*)) 
      data.y(i,*) = (output.swp1_I1(i,tmp)-output.I_ZERO1(i)*16)*const_I1_readback  ;should be the same as for I1
      data.v(i,*) = data2.y(ii,tmp) + data3.y(i,1)   ;*const_lp_bias1_DAC 
  endfor
;-------------
limit=create_struct(   $                                   ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  'Sweep from ATR' , $  
   'xtitle',  'Time'  , $  
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
  store_data,'mvn_lpw_swp1_IV',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------
endif

;------------- variable:  swp1_mc_len ---------------------------
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr(nn_pktnum)  ,$
   'y'     ,  fltarr(nn_pktnum))
dlimit=create_struct(   $      
   'datafile'     ,  'File info'  ,$
   'data_att'     ,  datatype.type)   
;-------------- derive the time ---------------- 
 data.x = time                                                     
 data.y = subcycle_length(output.mc_len(output.swp1_i))*4.   ;ORB_MD
;-------------
limit=create_struct(   $                          ;this one I set up the fields as I need, not directly after tplot options
    'xrange2'  , [min(data.x),max(data.x)], $            ;for plotting purpuses   
    'xtitle',  'Time'  ,$  
  'char_size' ,  1.  ,$                                  ;this is not a tplot variable
    'xstyle2'  ,   1  , $                                ;for plotting putpuses 
   'xlim2'    , [min(data.x),max(data.x)], $                ;this is the true range
   'ytitle',  'swp1_mc_len', $                ;this is the true range
   'ystyle'    , 1  ,$   
   'yrange', [0,300])                             
;-------------  
store_data,'mvn_lpw_swp1_mc_len',data=data,limit=limit,dlimit=dlimit
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
 data.x = time                                                  
 data.y = sample_aver(output.smp_avg(output.swp1_i))       ; from ICD table
;-------------
limit=create_struct(   $                          ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  'swp1_smp_avg', $
    'xrange2'  , [min(data.x),max(data.x)], $            ;for plotting purpuses   
    'xtitle',  'Time'  ,$  
   'char_size' ,  2.  ,$                                  ;this is not a tplot variable
    'xstyle2'  ,   1  , $                                ;for plotting putpuses 
   'xlim2'    , [min(data.x),max(data.x)], $                ;this is the true range
    'zstyle'    , 1  ,$ 
    'yrange', [0,2050] )                             
;-------------  
store_data,'mvn_lpw_swp1_smp_avg',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------

;------------- variable:  swp1_mode ---------------------------
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr(nn_pktnum)  ,$
   'y'     ,  fltarr(nn_pktnum))
dlimit=create_struct(   $      
   'datafile'     ,  'File info'  ,$
   'data_att'     ,  datatype.type)   
;-------------- derive the time ---------------- 
 data.x = time                                                     
 data.y = output.orb_md(output.swp1_i)   ;ORB_MD
;-------------
limit=create_struct(   $                          ;this one I set up the fields as I need, not directly after tplot options
    'xrange2'  , [min(data.x),max(data.x)], $            ;for plotting purpuses   
    'xtitle',  'Time'  ,$  
  'char_size' ,  1.  ,$                                  ;this is not a tplot variable
    'xstyle2'  ,   1  , $                                ;for plotting putpuses 
   'xlim2'    , [min(data.x),max(data.x)], $                ;this is the true range
   'ytitle',  'swp1_mode', $                ;this is the true range
   'ystyle'    , 1  ,$   
   'yrange', [-1,18])                             
;-------------  
store_data,'mvn_lpw_swp1_mode',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------

end
;*******************************************************************









