;;+
;PROCEDURE:   mvn_lpw_adr
;PURPOSE:
;  Takes the decumuted data (L0) from the ADR packet
;  and turn it the data into tplot structures
;  NOTE mvn_lpw_atr needs to be read before this routine (ATR should always be created before ADR on start up)
; Some of the ADR parameters is provided both as raw and unit_converted (per discussion with David Meyer)
;
;
;USAGE:
;  mvn_lpw_adr,output,lpw_const
;
;INPUTS:
;       output:         L0 data 
;       lpw_const:      information of lpw calibration etc
;
;KEYWORDS:
;       
;
;CREATED BY:   Laila Andersson 17 august 2011 
;FILE: mvn_lpw_adr.pro
;VERSION:   1.1
;LAST MODIFICATION:   05/16/13
;-

pro mvn_lpw_adr, output,lpw_const
;--------------------- Constants Used In This Routine ------------------------------------
const_active_steps=lpw_const.nn_active_steps                             ; the last point is omitted, do not contain importnat information 
nn_steps=lpw_const.nn_swp_steps                                          ; nn_steps  number of input in the table note the wvalues is 128-1 because 1 point the instrument wait for everything to setle
nn_steps2=lpw_const.nn_swp                                               ;true number of steps
nn_pktnum=lpw_const.nn_modes
const_sign = lpw_const.sign
const_lp_bias1_DAC=lpw_const.lp_bias1_DAC 
const_w_bias1_DAC=lpw_const.w_bias1_DAC 
const_lp_guard1_DAC=lpw_const.lp_guard1_DAC 
const_w_guard1_DAC=lpw_const.w_guard1_DAC
const_lp_stub1_DAC=lpw_const.lp_stub1_DAC 
const_w_stub1_DAC=lpw_const.w_stub1_DAC
const_lp_bias2_DAC=lpw_const.lp_bias2_DAC 
const_w_bias2_DAC=lpw_const.w_bias2_DAC 
const_lp_guard2_DAC=lpw_const.lp_guard2_DAC 
const_w_guard2_DAC=lpw_const.w_guard2_DAC
const_lp_stub2_DAC=lpw_const.lp_stub2_DAC 
const_w_stub2_DAC=lpw_const.w_stub2_DAC
const_bias1_readback=lpw_const.bias1_readback
const_guard1_readback=lpw_const.guard1_readback
const_stub1_readback=lpw_const.stub1_readback
const_V1_readback =lpw_const.V1_readback
const_bias2_readback=lpw_const.bias2_readback
const_guard2_readback=lpw_const.guard2_readback
const_stub2_readback=lpw_const.stub2_readback
const_V2_readback =lpw_const.V2_readback
t_epoch=lpw_const.t_epoch
;--------------------------------------------------------------------
nn_pktnum = output.p8                                 ; number of data packages 
time      = double(output.SC_CLK1(output.adr_i))+output.SC_CLK2(output.adr_i)/2l^16 +t_epoch
;---------------------------------------------

;------------- Checks ---------------------
if output.p8 NE n_elements(output.adr_DYN_OFFSET1) then stanna
;-----------------------------------------

;----------  variable: LP_BIAS1 RAW + Converted    --------------------------- 
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr(nn_pktnum)  ,$
   'y'     ,  fltarr(nn_pktnum,nn_steps) ,$
   'v'     ,  fltarr(nn_pktnum,nn_steps))
dlimit=create_struct(   $      
   'datafile'     ,  'Info of file used'  ,$
   'xsubtitle'    ,  '[sec]', $
   'ysubtitle'    ,  '[bins]', $
   'zsubtitle'    ,  '[RAW]', $
   'data_att'     ,  datatype.type)   
;-------------- derive the time ---------------- 
data.x = time                                                                                                              
data.y = output.adr_lp_bias1
for i=0,nn_pktnum-1 do data.v(i,*)=indgen(nn_steps)
;-------------
limit=create_struct(   $                                   ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  'mvn_lpw_adr_lp_bias1' , $  
   'xtitle',  'Time'  ,$  
   'char_size' ,  2.  ,$                                  ;this is not a tplot variable
   'spec',        1, $                                    ;line plots
   'ystyle'    , 1  ,$                                    ;for plotting purpuses 
   'yrange'  , [min(data.v),max(data.v)], $  
   'zrange'  , [min(data.y),max(data.y)], $                                 ;for plotting purpuses   working in tplot
   'xrange2'  , [min(data.x),max(data.x)], $              ;for plotting purpuses   not working in tplot 
   'xstyle2'  ,   1  , $                                  ;for plotting putpuses 
   'xlim2'    , [min(data.x),max(data.x)])                ;this is the true range
;-------------  
store_data,'mvn_lpw_adr_lp_bias1_raw',data=data,limit=limit,dlimit=dlimit
;------------------ Converted ---------------------------
dlimit.zsubtitle='[readback]'
data.y = data.y*const_bias1_readback
limit.zrange=[min(data.y),max(data.y)]
store_data,'mvn_lpw_adr_lp_bias1',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------

;----------  variable: LP_BIAS2   RAW + Converted    --------------------------- 
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr(nn_pktnum)  ,$
   'y'     ,  fltarr(nn_pktnum,nn_steps) ,$
   'v'     ,  fltarr(nn_pktnum,nn_steps))
dlimit=create_struct(   $      
   'datafile'     ,  'Info of file used'  ,$
   'xsubtitle'    ,  '[sec]', $
   'ysubtitle'    ,  '[bin]', $
   'zsubtitle'    ,  '[RAW]', $
   'data_att'     ,  datatype.type)   
;-------------- derive the time ---------------- 
data.x = time                                                                                                              
data.y = output.adr_lp_bias2
for i=0,nn_pktnum-1 do data.v(i,*)=indgen(nn_steps)
;-------------
limit=create_struct(   $                                   ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  'mvn_lpw_adr_lp_bias2' , $  
   'xtitle',  'Time'  ,$  
   'char_size' ,  2.  ,$                                  ;this is not a tplot variable
   'spec',        1, $                                    ;line plots
   'ystyle'    , 1  ,$                                    ;for plotting purpuses 
   'yrange'  , [min(data.v),max(data.v)], $               ;for plotting purpuses   working in tplot
   'zrange'  , [min(data.y),max(data.y)], $ 
   'xrange2'  , [min(data.x),max(data.x)], $              ;for plotting purpuses   not working in tplot 
   'xstyle2'  ,   1  , $                                  ;for plotting putpuses 
   'xlim2'    , [min(data.x),max(data.x)])                ;this is the true range
;-------------  
store_data,'mvn_lpw_adr_lp_bias2_raw',data=data,limit=limit,dlimit=dlimit
;---------------- Converted --------------------
dlimit.zsubtitle='[readback]'
data.y = data.y*const_bias2_readback
limit.zrange=[min(data.y),max(data.y)]
store_data,'mvn_lpw_adr_lp_bias2',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------

;----------  variable: offset1   RAW + Converted    --------------------------- 
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr(nn_pktnum)  ,$
   'y'     ,  fltarr(nn_pktnum))
dlimit=create_struct(   $      
   'datafile'     ,  'Info of file used'  ,$
   'xsubtitle'    ,  '[sec]', $
   'ysubtitle'    ,  '[RAW]', $
   'data_att'     ,  datatype.type)   
;-------------- derive the time ---------------- 
data.x = time                                                                                                               
data.y = output.adr_dyn_offset1
;-------------
limit=create_struct(   $                                   ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  'mvn_lpw_adr_dyn_offset1' , $  
   'xtitle',  'Time'  ,$  
   'char_size' ,  2.  ,$                                  ;this is not a tplot variable
   'spec',        1, $                                    ;line plots
   'ystyle'    , 1  ,$                                    ;for plotting purpuses 
   'yrange'  , [min(data.y),max(data.y)], $ [min(data.y),max(data.y)], $               ;for plotting purpuses   working in tplot
   'xrange2'  , [min(data.x),max(data.x)], $              ;for plotting purpuses   not working in tplot 
   'xstyle2'  ,   1  , $                                  ;for plotting putpuses 
   'xlim2'    , [min(data.x),max(data.x)])                ;this is the true range
;-------------  
store_data,'mvn_lpw_adr_dyn_offset1_raw',data=data,limit=limit,dlimit=dlimit
;---------------- Converted --------------------
dlimit.ysubtitle='DAC [V]'
data.y = (data.y-const_sign)*const_lp_bias1_DAC
limit.yrange=[min(data.y),max(data.y)]
store_data,'mvn_lpw_adr_dyn_offset1',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------

;----------  variable: offset2    RAW + Converted   --------------------------- 
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr(nn_pktnum)  ,$
   'y'     ,  fltarr(nn_pktnum))
dlimit=create_struct(   $      
   'datafile'     ,  'Info of file used'  ,$
   'xsubtitle'    ,  '[sec]', $
   'ysubtitle'    ,  '[RAW]', $
   'data_att'     ,  datatype.type)   
;-------------- derive the time ---------------- 
data.x = time                                                                                                              
data.y = output.adr_dyn_offset2
;-------------
limit=create_struct(   $                                   ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  'mvn_lpw_adr_dyn_offset2' , $  
   'xtitle',  'Time'  ,$  
   'char_size' ,  2.  ,$                                  ;this is not a tplot variable
   'spec',        1, $                                    ;line plots
   'ystyle'    , 1  ,$                                    ;for plotting purpuses 
   'yrange'  , [min(data.y),max(data.y)] , $ [min(data.y),max(data.y)], $               ;for plotting purpuses   working in tplot
   'xrange2'  , [min(data.x),max(data.x)], $              ;for plotting purpuses   not working in tplot 
   'xstyle2'  ,   1  , $                                  ;for plotting putpuses 
   'xlim2'    , [min(data.x),max(data.x)])                ;this is the true range
;-------------  
store_data,'mvn_lpw_adr_dyn_offset2_raw',data=data,limit=limit,dlimit=dlimit
;---------------- Converted --------------------
dlimit.ysubtitle='DAC [V]'
data.y = (data.y-const_sign)*const_lp_bias1_DAC
limit.yrange=[min(data.y),max(data.y)]
store_data,'mvn_lpw_adr_dyn_offset2',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------

;------------- variable:  surface_pot1  RAW + Converted  ---------------------------
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr(nn_pktnum)  ,$
   'y'     ,  fltarr(nn_pktnum,6) )
dlimit=create_struct(   $      
   'datafile'     ,  'tmp'  ,$
   'xsubtitle'    ,  '[sec]', $
   'ysubtitle'    ,  '[RAW]', $
   'data_att'     ,  datatype.type)   
;-------------- derive the time ----------------                                                     
data.x = time     
       data.y(*,0)=output.adr_w_bias1
       data.y(*,1)=output.adr_w_guard1
       data.y(*,2)=output.adr_w_stub1
       data.y(*,3)=output.adr_w_v1
       data.y(*,4)=output.adr_lp_guard1
       data.y(*,5)=output.adr_lp_stub1          
str1=['ADR_W_BIAS1','ADR_W_GUARD1','ADR_W_STUB1','ADR_W_V1' ,'ADR_LP_GUARD1','ADR_LP_STUB1']
;-------------
limit=create_struct(   $                          ;this one I set up the fields as I need, not directly after tplot options
  'labels',   str1, $                                          ;lable the different lines
   'labflag',    1 ,$ 
   'ytitle',  'Different potentials 1', $
   'xtitle',  'Time'  ,$  
   'char_size' ,  2.  ,$  
   'ystyle'    , 1  ,$   
   'yrange', [min(data.y),max(data.y)], $               ;for plotting purpuses   working in tplot
   'xrange2'  , [min(data.x),max(data.x)], $              ;for plotting purpuses   not working in tplot 
   'xstyle2'  ,   1  , $                                  ;for plotting putpuses 
   'xlim2'    , [min(data.x),max(data.x)] )                             ;this is the true range
;-------------  
store_data,'mvn_lpw_adr_surface_pot1_raw',data=data,limit=limit,dlimit=dlimit
;---------------- Converted --------------------
dlimit.ysubtitle='readback [V]'
       data.y(*,0)=data.y(*,0)*const_bias1_readback     ;output.adr_w_bias1*c
       data.y(*,1)=data.y(*,1)*const_guard1_readback     ;output.adr_w_guard1*C
       data.y(*,2)=data.y(*,2)*const_stub1_readback     ;output.adr_w_stub1*C
       data.y(*,3)=data.y(*,3)*const_V1_readback        ;output.adr_w_v1*const_V1_readback
       data.y(*,4)=data.y(*,4)*const_guard1_readback     ;output.adr_lp_guard1*c
       data.y(*,5)=data.y(*,5)*const_stub1_readback     ;output.adr_lp_stub1*c   
limit.yrange=[min(data.y),max(data.y)]
store_data,'mvn_lpw_adr_surface_pot1',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------

;------------- variable:  surface_pot2   RAW + Converted  ---------------------------
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr(nn_pktnum)  ,$
   'y'     ,  fltarr(nn_pktnum,6) )
dlimit=create_struct(   $      
   'datafile'     ,  'tmp'  ,$
   'xsubtitle'    ,  '[sec]', $
   'ysubtitle'    ,  '[RAW]', $
   'data_att'     ,  datatype.type)    
;-------------- derive the time ----------------                                                     
data.x = time    
       data.y(*,0)=output.adr_w_bias2
       data.y(*,1)=output.adr_w_guard2
       data.y(*,2)=output.adr_w_stub2
       data.y(*,3)=output.adr_w_v2
       data.y(*,4)=output.adr_lp_guard2
       data.y(*,5)=output.adr_lp_stub2          
str1=['ADR_W_BIAS2','ADR_W_GUARD2','ADR_W_STUB2','ADR_W_V2' ,'ADR_LP_GUARD2','ADR_LP_STUB2']
;-------------
limit=create_struct(   $                          ;this one I set up the fields as I need, not directly after tplot options
  'labels',   str1, $                                          ;lable the different lines
   'labflag',    1 ,$ 
   'ytitle',  'Different potentials 2', $
   'xtitle',  'Time'  ,$ 
   'char_size' ,  2.  ,$   
   'ystyle'    , 1  ,$   
   'yrange',    [min(data.y),max(data.y)] , $               ;for plotting purpuses   working in tplot
   'xrange2'  , [min(data.x),max(data.x)], $              ;for plotting purpuses   not working in tplot 
   'xstyle2'  ,   1  , $                                  ;for plotting putpuses 
   'xlim2'    , [min(data.x),max(data.x)])                             ;this is the true range
;-------------  
store_data,'mvn_lpw_adr_surface_pot2_raw',data=data,limit=limit,dlimit=dlimit
;---------------- Converted --------------------
dlimit.ysubtitle='readback [V]'
       data.y(*,0)=data.y(*,0)*const_bias2_readback     ;output.adr_w_bias2*c
       data.y(*,1)=data.y(*,1)*const_guard2_readback     ;output.adr_w_guard2*C
       data.y(*,2)=data.y(*,2)*const_stub2_readback     ;output.adr_w_stub2*C
       data.y(*,3)=data.y(*,3)*const_V2_readback        ;output.adr_w_v2*constV21_readback
       data.y(*,4)=data.y(*,4)*const_guard2_readback     ;output.adr_lp_guard2*c
       data.y(*,5)=data.y(*,5)*const_stub2_readback     ;output.adr_lp_stub2*c   
limit.yrange=[min(data.y),max(data.y)]
store_data,'mvn_lpw_adr_surface_pot2',data=data,limit=limit,dlimit=dlimit
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
 data.y = 2^(output.smp_avg(output.adr_i)+1)       ;from table 7.6  2^(smp_avg+1)
;-------------
limit=create_struct(   $                          ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  'adr_smp_avg', $
    'xrange2'  , [min(data.x),max(data.x)], $            ;for plotting purpuses   
    'xtitle',  'Time'  ,$  
   'char_size' ,  2.  ,$                                  ;this is not a tplot variable
    'xstyle2'  ,   1  , $                                ;for plotting putpuses 
   'xlim2'    , [min(data.x),max(data.x)], $                ;this is the true range
    'zstyle'    , 1  ,$ 
    'yrange', [0,max(data.y)*1.2] )                             
;-------------  
store_data,'mvn_lpw_adr_smp_avg',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------

;------------- variable:  adr_mode ---------------------------
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr(nn_pktnum)  ,$
   'y'     ,  fltarr(nn_pktnum)  )
dlimit=create_struct(   $      
   'datafile'     ,  'File info'  ,$
   'data_att'     ,  datatype.type)                               
;-------------- derive the time ---------------- 
 data.x = time                                                      
 data.y = output.ORB_MD(output.adr_i)
;-------------
limit=create_struct(   $                          ;this one I set up the fields as I need, not directly after tplot options
   'xrange2'  , [min(data.x),max(data.x)], $            ;for plotting purpuses   
    'xtitle',  'Time'  ,$  
   'char_size' ,  2.  ,$                                ;this is not a tplot variable
   'xstyle2'  ,   1  , $                                ;for plotting putpuses 
   'xlim2'    , [min(data.x),max(data.x)], $                ;this is the true range
   'ytitle',  'adr_mode', $                ;this is the true range
   'ystyle'    , 1  ,$   
   'yrange', [-1,18])                             
;;-------------  
store_data,'mvn_lpw_adr_mode',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------




;*******************************************************************************************
;***************     Second half where ADR is compared with ATR    *************************
;*******************************************************************************************
;adr is always after atr, hence match to a atr before this time stamp 

;-------------- Set up the fundamental so  Expected ATR can be derived (12 different values is created below)----------------
;------------------------------ This is will then be compared to ADR_raw*const ----------------------------------------------
;----------------------------------   The time is based on the ATR time stamp ----------------------------------------------
;---- To get the ADR time-stamp I expect the  ATR(data0) packet first for the matching ADR(data1) packet  ------------
get_data,'mvn_lpw_atr_dac',data=data0    ; this is what we based it on
get_data,'mvn_lpw_adr_surface_pot1_raw',data=data1  ;data1.y(*,3)=output.adr_w_v1  
;----------  ------   --------------------------- 
dlimit=create_struct(   $      
   'datafile'     ,  'Info of file used'  ,$
   'xsubtitle'    ,  '[sec]', $
   'ysubtitle'    ,  'DAC [V?]')   
;-------------- derive the time ---------------- 
data=create_struct(   $        
   'x'     ,  dblarr(n_elements(data0.x))  ,$
   'y'     ,  fltarr(n_elements(data0.x))  )
data.x = data0.x                                                                                                              
;data.y =   ; will be different for all 12 variables  ;this will change below
;-------------
limit=create_struct(   $                                   
   'ytitle',  'expect_ATR_bias1_wave' , $    ;this will change below 
   'xtitle',  'Time'  ,$  
   'char_size' ,  2.  ,$                                  
   'spec',        1, $                                    
   'ystyle'    , 1  ,$                                     
   'yrange'  , [min(data.y),max(data.y)] , $         ;this will change below
   'xrange2'  , [min(data.x),max(data.x)], $               
   'xstyle2'  ,   1  , $                                  
   'xlim2'    , [min(data.x),max(data.x)])                
;-------------  
;---------------- Create 10 of the 12 variables ----------------------
;---------------- mvn_lpw_expect_ATR_bias1_wave --------------------
                                  ;mvn_lpw_atr_dac:  data0.y(*,0)=output.ATR_W_BIAS1(i)
get_data,'mvn_lpw_atr_dac',data=data0    ; this is what we based it on
get_data,'mvn_lpw_adr_surface_pot1_raw',data=data1  ;data1.y(*,3)=output.adr_w_v1                                   
sort_data1=fltarr(n_elements(data0.x))     ;DO I HAVE TO DO THIS ON ALL VARIABLES BELOW?
for i=0,n_elements(data0.x)-1 do BEGIN
     qq=min(abs( (data0.x(i)-data1.x) +1e9*(data0.x(i)-data1.x LT 0)),nq)  ;find the right ADR(data1) match to the ATR(data0) time
     sort_data1(i)=nq
  ;   print,i,nq,data0.x(i)-data1.x(nq),' EE ',(data0.x(i)-data1.x)
endfor                            
data.y = (data0.y(*,0)-const_sign)*const_w_bias1_DAC +(data1.y(sort_data1,3)*const_V1_readback)
limit.yrange=[min(data.y),max(data.y)]
limit.ytitle='expected_ATR_bias1_wave'
store_data,'mvn_lpw_exp_ATR_bias1_wave',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------
;---------------- mvn_lpw_expect_ATR_guard1_wave --------------------
                                  ;mvn_lpw_atr_dac:  data0.y(i,1)=output.ATR_W_GUARD1(i)
get_data,'mvn_lpw_adr_surface_pot1_raw',data=data1  ;data1.y(*,3)=output.adr_w_v1                           
data.y = (data0.y(*,1)-const_sign)*const_w_guard1_DAC +(data1.y(sort_data1,3)*const_V1_readback)
limit.yrange=[min(data.y),max(data.y)]
limit.ytitle='expected_ATR_guard1_wave'
store_data,'mvn_lpw_exp_ATR_guard1_wave',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------
;---------------- mvn_lpw_expect_ATR_stub1_wave --------------------
                                  ;mvn_lpw_atr_dac:  data0.y(i,2)=output.ATR_W_STUB1(i)
get_data,'mvn_lpw_adr_surface_pot1_raw',data=data1  ;data1.y(*,3)=output.adr_w_v1                           
data.y = (data0.y(*,2)-const_sign)*const_w_stub1_DAC +(data1.y(sort_data1,3)*const_V1_readback)
limit.yrange=[-5,5] ;[min(data.y),max(data.y)]
limit.ytitle='expected_ATR_stub1_wave'
store_data,'mvn_lpw_exp_ATR_stub1_wave',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------
;---------------- mvn_lpw_expect_ATR_bias2_wave --------------------
                                  ;mvn_lpw_atr_dac:  data0.y(*,6)=output.ATR_W_BIAS2(i)
get_data,'mvn_lpw_adr_surface_pot2_raw',data=data1  ;data1.y(*,3)=output.adr_w_v2                           
data.y = (data0.y(*,6)-const_sign)*const_w_bias2_DAC +(data1.y(sort_data1,3)*const_V2_readback)
limit.yrange=[min(data.y),max(data.y)]
limit.ytitle='expected_ATR_bias2_wave'
store_data,'mvn_lpw_exp_ATR_bias2_wave',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------
;---------------- mvn_lpw_expect_ATR_guard2_wave --------------------
                                  ;mvn_lpw_atr_dac:  data0.y(i,7)=output.ATR_W_GUARD2(i)
get_data,'mvn_lpw_adr_surface_pot2_raw',data=data1  ;data1.y(*,3)=output.adr_w_v2                           
data.y = (data0.y(*,7)-const_sign)*const_w_guard2_DAC +(data1.y(sort_data1,3)*const_V2_readback)
limit.yrange=[min(data.y),max(data.y)]
limit.ytitle='expected_ATR_guard2_wave'
store_data,'mvn_lpw_exp_ATR_guard2_wave',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------
;---------------- mvn_lpw_expect_ATR_stub2_wave --------------------
                                  ;mvn_lpw_atr_dac:  data0.y(i,8)=output.ATR_W_STUB2(i)
get_data,'mvn_lpw_adr_surface_pot2_raw',data=data1  ;data1.y(*,3)=output.adr_w_v2                           
data.y = (data0.y(*,8)-const_sign)*const_w_stub2_DAC +(data1.y(sort_data1,3)*const_V2_readback)
limit.yrange=[-5,5] ;[min(data.y),max(data.y)]
limit.ytitle='expected_ATR_stub2_wave'
store_data,'mvn_lpw_exp_ATR_stub2_wave',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------
;---------------- mvn_lpw_expect_ATR_bias1_LP   moved down since this will be 128 of them --------------------
;---------------------------------------------
;---------------- mvn_lpw_expect_ATR_guard1_LP --------------------
                                  ;mvn_lpw_atr_dac:  data0.y(i,4)=output.ATR_LP_GUARD1(i)
get_data,'mvn_lpw_adr_lp_bias1_raw',data=data1           ;data1.y(*,127)=output.adr_lp_bias1(*,127)                        
data.y = (data0.y(*,4)-const_sign)*const_lp_guard1_DAC +(data1.y(sort_data1,126)*const_bias1_readback)
limit.yrange=[min(data.y),max(data.y)]
limit.ytitle='expected_ATR_guard1_LP'
store_data,'mvn_lpw_exp_ATR_guard1_LP',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------
;---------------- mvn_lpw_expect_ATR_stub1_LP --------------------
                                  ;mvn_lpw_atr_dac:  data0.y(i,5)=output.ATR_LP_STUB1(i)
get_data,'mvn_lpw_adr_lp_bias1_raw',data=data1           ;data1.y(*,127)=output.adr_lp_bias1(*,127)                          
data.y = (data0.y(*,5)-const_sign)*const_lp_stub1_DAC +(data1.y(sort_data1,126)*const_bias1_readback)
limit.yrange=[min(data.y),max(data.y)]
limit.ytitle='expected_ATR_stub1_LP'
store_data,'mvn_lpw_exp_ATR_stub1_LP',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------
;---------------- mvn_lpw_expect_ATR_bias2_LP   moved down since this will be 128 of them --------------------
;---------------------------------------------
;---------------- mvn_lpw_expect_ATR_guard12_LP --------------------
                                  ;mvn_lpw_atr_dac:  data0.y(i,10)=output.ATR_LP_GUARD2(i)
get_data,'mvn_lpw_adr_lp_bias2_raw',data=data1           ;data1.y(*,127)=output.adr_lp_bias2(*,127)                          
data.y = (data0.y(*,10)-const_sign)*const_lp_guard2_DAC +(data1.y(sort_data1,126)*const_bias2_readback)
limit.yrange=[min(data.y),max(data.y)]
limit.ytitle='expected_ATR_guard2_LP'
store_data,'mvn_lpw_exp_ATR_guard2_LP',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------
;---------------- mvn_lpw_expect_ATR_stub2_LP --------------------
                                  ;mvn_lpw_atr_dac:  data0.y(i,11)=output.ATR_LP_STUB2(i)
get_data,'mvn_lpw_adr_lp_bias2_raw',data=data1           ;data1.y(*,127)=output.adr_lp_bias2(*,127)                          
data.y = (data0.y(*,11)-const_sign)*const_lp_stub2_DAC +(data1.y(sort_data1,126)*const_bias2_readback)
limit.yrange=[min(data.y),max(data.y)]
limit.ytitle='expected_ATR_stub2_LP'
store_data,'mvn_lpw_exp_ATR_stub2_LP',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------
;---------------- Create the last 2 of the 12 variables ----------------------
;;LP
data=create_struct(   $        
   'x'     ,  dblarr(n_elements(data0.x))  ,$
   'y'     ,  fltarr(n_elements(data0.x),nn_steps2) ,$
   'v'     ,  fltarr(n_elements(data0.x),nn_steps2))
  ;---------------- mvn_lpw_expect_ATR_bias1_LP     128 of them --------------------
                                  ;mvn_lpw_atr_dac:  data0.y(*,3)=output.ATR_LP_BIAS1(i)
get_data,'mvn_lpw_atr_swp',data=data1  ;data1.y(i,*)=(output.ATR_SWP(i,*) - const_sign) *const_DAC_volt   ;  not unique to boom 1 or boom 2 
data.x=data0.x  ;(sort_data0)
print,'#################'
sort_data1=fltarr(n_elements(data0.x))
for i=0,n_elements(data0.x)-1 do BEGIN
     qq=min(abs( (data0.x(i)-data1.x) +1e9*(data0.x(i)-data1.x LT 0)),nq)  ;find the right ADR(data1) match to the ATR(data0) time
     sort_data1(i)=nq
    ; print,i,nq,data0.x(i)-data1.x(nq),' EE ',(data0.x(i)-data1.x)
endfor                            
for i=0,n_elements(data0.x)-1 do begin  
;change to 
 ;where Func(TBD) is first ATR packet that has the applicable orbital mode in the tertiary header                     
        data.y(i,*) =(data0.y(i,3)-const_sign)*const_lp_bias1_DAC+data1.y(sort_data1(i),*) + 0.  ;the '0' is because this is grounded
        data.v(i,*)=data1.v(sort_data1(i),*)
endfor
;---------------------------------------------
limit=create_struct(   $                                   
   'ytitle',  'expected_ATR_bias1_LP' , $    ;this will change below 
   'xtitle',  'Time'  ,$  
   'char_size' ,  2.  ,$                                  
   'spec',        1, $                                    
   'ystyle'    , 1  ,$                                     
   'yrange'  , [min(data.v),max(data.v)] , $         ;this will change below
   'xrange2'  , [min(data.x),max(data.x)], $               
   'xstyle2'  ,   1  , $                                  
   'xlim2'    , [min(data.x),max(data.x)], $
   'zstyle'    , 1  ,$                                        ;for plotting purpuses 
   'zrange'  , [min(data.y),max(data.y)])
;---------------------------------------------
store_data,'mvn_lpw_exp_ATR_bias1_LP',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------
;---------------- mvn_lpw_expect_ATR_bias2_LP     128 of them --------------------
                                  ;mvn_lpw_atr_dac:  data0.y(*,9)=output.ATR_LP_BIAS2(i)                       
for i=0,n_elements(data0.x)-1 do $                        
        data.y(i,*) =(data0.y(i,9)-const_sign)*const_lp_bias2_DAC+data1.y(sort_data1(i),*) + 0.  ;the '0' is because this is grounded
limit.zrange=[min(data.y),max(data.y)]
limit.ytitle='expected_ATR_bias2_LP'
store_data,'mvn_lpw_exp_ATR_bias2_LP',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------

end
;*******************************************************************




