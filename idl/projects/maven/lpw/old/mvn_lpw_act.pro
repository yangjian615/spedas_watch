;;+
;PROCEDURE:   mvn_lpw_act
;PURPOSE:
;  Takes the decumuted data (L0) from the ACT packet
;  and turn it the data into L1 and L2 data tplot structures
;  This packet contains the information of V1, V2 and E12_LF
;   Should be almost identical to mvn_lpw_pas.pro
;
;USAGE:
;  mvn_lpw_act,output,lpw_const
;
;INPUTS:
;       output:         L0 data 
;       lpw_const:      information of lpw calibration etc
;
;KEYWORDS:
;       
;
;CREATED BY:   Laila Andersson 17 august 2011 
;FILE: mvn_lpw_act.pro
;VERSION:   1.1
; Changes:  Time in the header is now associated with the last measurement point
;LAST MODIFICATION:   05/16/13
;-

pro mvn_lpw_act, output,lpw_const 

;--------------------- Constants ------------------------------------
subcycle_length=lpw_const.sc_lngth
nn_steps=long(lpw_const.nn_pa)                                   ;number of samples in one subcycle
t_epoch=lpw_const.t_epoch              
const_V2_readback=lpw_const.V2_readback
const_V1_readback=lpw_const.V1_readback
const_E12_LF =    lpw_const.E12_lf
;--------------------------------------------------------------------
nn_pktnum=long(output.p12)                                      ; number of data packages 
nn_size=nn_pktnum*nn_steps                                     ; number of data points
dt=subcycle_length(output.mc_len(output.act_i))/nn_steps
t_s=subcycle_length(output.mc_len(output.act_i))*3./64         ;this is how long time each measurement point took
                                                               ;the time in the header is associated with the last point in the measurement
                                                               ;therefore is the time corrected by the thength of the subcycle_length
time      = double(output.SC_CLK1(output.act_i)) + output.SC_CLK2(output.act_i)/2l^16+t_epoch-t_s  -subcycle_length(output.mc_len(output.act_i))
;--------------------------------------------------------------------

;------------- Checks ---------------------
if output.p12 NE n_elements(output.act_i) then stanna
if n_elements(output.act_i) EQ 0 then print,'(mvn_lpw_act) No packages where found <---------------'
;-----------------------------------------

;----------  variable:   V1 ---------------------------
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr(nn_size)  ,$
   'y'     ,  fltarr(nn_size))
dlimit=create_struct(   $      
   'datafile'     ,  'Info of file used'  ,$
   'xsubtitle'    ,  '[sec]', $
   'ysubtitle'    ,  '[V]', $
   'data_att'     ,  datatype.type)   
;-------------- derive the time ---------------- 
for i=0L,nn_pktnum-1 do data.x(nn_steps*i:nn_steps*(i+1)-1) = time(i) + dindgen(nn_steps) * dt(i)  
for i=0L,nn_pktnum-1 do data.y(nn_steps*i:nn_steps*(i+1)-1) = output.act_V1(i,*) * const_V1_readback
;-------------- derive the time ---------------- 
limit=create_struct(   $                            ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  'mvn_lpw_act_V1' , $   
    'xtitle',  'Time'  ,$  
   'char_size' ,  2.  ,$                            ;this is not a tplot variable
   'xrange2'  , [min(data.x),max(data.x)], $        ;for plotting purpuses   
   'xstyle2'  ,   1  , $                            ;for plotting putpuses 
   'xlim2'    , [min(data.x),max(data.x)], $                ;this is the true range
   'ystyle'    , 1  ,$                                        ;for plotting purpuses 
   'yrange'  , [min(data.y),max(data.y)] )             
 ;------------- 
store_data,'mvn_lpw_act_V1',data=data,limit=limit,dlimit=dlimit
;--------------------------------------------------

;----------  variable: V2 ---------------------------
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr(nn_size)  ,$
   'y'     ,  fltarr(nn_size))
dlimit=create_struct(   $      
   'datafile'     ,  'Info of file used'  ,$
   'xsubtitle'    ,  '[sec]', $
   'ysubtitle'    ,  '[V]', $
   'data_att'     ,  datatype.type)   
;-------------- derive the time ---------------- 
for i=0L,nn_pktnum-1 do $                                                        
       data.x(nn_steps*i:nn_steps*(i+1)-1)=time(i) + dindgen(nn_steps)*dt(i)                                                                                                                      
for i=0L,nn_pktnum-1 do $
       data.y(nn_steps*i:nn_steps*(i+1)-1)=output.act_V2(i,*)*const_V2_readback
;-------------
limit=create_struct(   $                              ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  'mvn_lpw_act_V2' , $  
   'xtitle',  'Time'  ,$  
   'char_size' ,  2.  ,$                              ;this is not a tplot variable
   'xrange2'  , [min(data.x),max(data.x)], $          ;for plotting purpuses   
   'xstyle2'  ,   1  , $                              ;for plotting putpuses 
   'xlim2'    , [min(data.x),max(data.x)], $                ;this is the true range
   'ystyle'    , 1  ,$                                        ;for plotting purpuses 
   'yrange'  , [min(data.y),max(data.y)] )             
;-------------
store_data,'mvn_lpw_act_V2',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------------

;----------  variable: E12 ---------------------------
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr(nn_size)  ,$
   'y'     ,  fltarr(nn_size))
dlimit=create_struct(   $      
   'datafile'     ,  'Info of file used'  ,$
   'xsubtitle'    ,  '[sec]', $
   'ysubtitle'    ,  '[V]', $
   'data_att'     ,  datatype.type)   
;-------------- derive the time ---------------- 
for i=0L,nn_pktnum-1 do data.x(nn_steps*i:nn_steps*(i+1)-1) = time(i) + dindgen(nn_steps) * dt(i)                                                                                                                                                                                                   
for i=0L,nn_pktnum-1 do data.y(nn_steps*i:nn_steps*(i+1)-1) = output.act_E12_LF(i,*) *const_E12_LF
;--------------
limit=create_struct(   $                                ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  'mvn_lpw_act_E12_LF' , $  
   'xtitle',  'Time'  ,$  
   'char_size' ,  2.  ,$                                ;this is not a tplot variable
   'xrange2'  , [min(data.x),max(data.x)], $            ;for plotting purpuses   
   'xstyle2'  ,   1  , $                                ;for plotting putpuses 
   'xlim2'    , [min(data.x),max(data.x)], $                ;this is the true range
   'ystyle'    , 1  ,$                                        ;for plotting purpuses 
   'yrange'  , [min(data.y),max(data.y)] )             
;--------------
store_data,'mvn_lpw_act_E12_LF',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------

;------------- variable:  act_mc_len ---------------------------
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr(nn_pktnum)  ,$
   'y'     ,  fltarr(nn_pktnum))
dlimit=create_struct(   $      
   'datafile'     ,  'File info'  ,$
   'xsubtitle'    ,  '[sec]', $
   'data_att'     ,  datatype.type)   
;-------------- derive the time ---------------- 
 data.x = time                                                      
 data.y = subcycle_length(output.mc_len(output.act_i) )*4.
;-------------
limit=create_struct(   $                          ;this one I set up the fields as I need, not directly after tplot options
   'xrange2'  , [min(data.x),max(data.x)], $            ;for plotting purpuses   
    'xtitle',  'Time'  ,$  
   'char_size' ,  2.  ,$                                ;this is not a tplot variable
   'xstyle2'  ,   1  , $                                ;for plotting putpuses 
   'xlim2'    , [min(data.x),max(data.x)], $                ;this is the true range
   'ytitle',  'act_mc_len', $
   'ystyle'    , 1  ,$                   ;this is the true range
   'yrange', [0,65])                                
;-------------  
store_data,'mvn_lpw_act_mc_len',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------

;------------- variable:  act_mode ---------------------------
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr(nn_pktnum)  ,$
   'y'     ,  fltarr(nn_pktnum))
dlimit=create_struct(   $      
   'datafile'     ,  'File info'  ,$
   'xsubtitle'    ,  '[sec]', $
   'data_att'     ,  datatype.type)   
;-------------- derive the time ---------------- 
 data.x = time                                                    
 data.y = output.orb_md(output.act_i) 
;-------------
limit=create_struct(   $                          ;this one I set up the fields as I need, not directly after tplot options
   'xrange2'  , [min(data.x),max(data.x)], $            ;for plotting purpuses   
    'xtitle',  'Time'  ,$  
   'char_size' ,  2.  ,$                                ;this is not a tplot variable
   'xstyle2'  ,   1  , $                                ;for plotting putpuses 
   'xlim2'    , [min(data.x),max(data.x)], $                ;this is the true range
   'ytitle',  'act_mode', $                ;this is the true range
   'ystyle'    , 1  ,$   
   'yrange', [-1,18])                             
;-------------  
store_data,'mvn_lpw_act_mode',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------

end
;*******************************************************************





