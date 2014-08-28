;;+
;PROCEDURE:   mvn_lpw_atr
;PURPOSE:
;  Takes the decumuted data (L0) from the ATR packet
;  and turn it the data into tplot structures
;  NOTE mvn_lpw_atr needs to be read before mvn_lpw_adr
; ATR packet will only be provided as raw values expect for the 
; sweep values that is derived into units of Volt
;
;USAGE:
;  mvn_lpw_atr,output,lpw_const
;
;INPUTS:
;       output:         L0 data 
;       lpw_const:      information of lpw calibration etc
;
;KEYWORDS:
;       
;
;CREATED BY:   Laila Andersson 17 august 2011 
;FILE: mvn_lpw_atr.pro
;VERSION:   1.1
;LAST MODIFICATION:   05/16/13
;-

pro mvn_lpw_atr,output,lpw_const
;--------------------- Constants Used In This Routine  ------------------------------------
nn_swp=lpw_const.nn_swp 
nn_dac=lpw_const.nn_dac
const_sign = lpw_const.sign
const_lp_bias1_DAC = lpw_const.lp_bias1_DAC 
t_epoch=lpw_const.t_epoch
;--------------------------------------------------------------------
;----------  variable: --------------------
nn_pktnum=output.p6                               ; number of data packages 
time = double(output.SC_CLK1(output.atr_i))+output.SC_CLK2(output.atr_i)/2l^16 +t_epoch
;-----------------------------------------

;------------- Checks ---------------------
if output.p6 NE n_elements(output.atr_i) then stanna
if n_elements(output.atr_i) EQ 0 then print,'(mvn_lpw_atr) No packages where found <---------------'
;-----------------------------------------

;------------- variable:  atr_swp_table ---------------------------
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr(nn_pktnum)  ,$
   'y'     ,  fltarr(nn_pktnum,nn_swp) ,$    
   'v'     ,  fltarr(nn_pktnum,nn_swp))
dlimit=create_struct(   $      
   'datafile'     ,  'data information'  ,$
   'spec'         ,  1, $
   'log'          ,  1, $
   'xsubtitle'    ,  '[sec]', $
   'ysubtitle'    ,  '[bin number]', $
   'zsubtitle'    ,  '[V]', $
   'data_att'     ,  datatype.type)   
;-------------- derive the time ----------------                                                     
data.x = time
 for i=0,nn_pktnum-1 do begin  
      data.y(i,*)=(output.ATR_SWP(i,*) - const_sign) * const_lp_bias1_DAC  ;output.ATR_SWP(i,flip_the_order)
      data.v(i,*)=indgen(nn_swp) 
endfor
;-------------
limit=create_struct(   $                          ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  'ATR_sweep', $
    'xtitle',  'Time'  ,$  
   'char_size' ,  2.  ,$                                ;this is not a tplot variable
   'xrange2'  , [min(data.x),max(data.x)], $                  ;for plotting purpuses      not for tplot
   'xstyle2'  ,   1  , $                                      ;for plotting putpuses       not for tplot
   'xlim2'    , [min(data.x),max(data.x)], $                  ;this is the true range    not for tplot
   'ystyle'    , 1  ,$                                        ;for plotting purpuses 
   'yrange'  , [min(data.v,/nan),max(data.v,/nan)] +1, $                ;change the plotting range from 0-127 to 1-128
   'zstyle'    , 1  ,$                                        ;for plotting purpuses 
   'zrange'  , [min(data.y,/nan),max(data.y,/nan)])                              ;for plotting purpuses                             
;-------------  
store_data,'mvn_lpw_atr_swp',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------

;------------- variable:  atr_swp_table ---------------------------
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr(nn_pktnum)  ,$
   'y'     ,  fltarr(nn_pktnum,nn_swp) ,$    
   'v'     ,  fltarr(nn_pktnum,nn_swp))
dlimit=create_struct(   $      
   'datafile'     ,  'data information'  ,$
   'spec'         ,  1, $
   'log'          ,  1, $
   'xsubtitle'    ,  '[sec]', $
   'ysubtitle'    ,  '[bin number]', $
   'zsubtitle'    ,  '[raw value]', $
   'data_att'     ,  datatype.type)   
;-------------- derive the time ----------------                                                     
data.x = time
 for i=0,nn_pktnum-1 do begin  
      data.y(i,*)=output.ATR_SWP(i,*)   ;raw data
      data.v(i,*)=indgen(nn_swp) 
endfor
;-------------
limit=create_struct(   $                          ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  'ATR_sweep', $
    'xtitle',  'Time'  ,$  
   'char_size' ,  2.  ,$                                ;this is not a tplot variable
   'xrange2'  , [min(data.x),max(data.x)], $                  ;for plotting purpuses      not for tplot
   'xstyle2'  ,   1  , $                                      ;for plotting putpuses       not for tplot
   'xlim2'    , [min(data.x),max(data.x)], $                  ;this is the true range    not for tplot
   'ystyle'    , 1  ,$                                        ;for plotting purpuses 
   'yrange'  , [min(data.v,/nan),max(data.v,/nan)] +1, $                ;change the plotting range from 0-127 to 1-128
   'zstyle'    , 1  ,$                                        ;for plotting purpuses 
   'zrange'  , [min(data.y,/nan),max(data.y,/nan)])                              ;for plotting purpuses                             
;-------------  
store_data,'mvn_lpw_atr_swp_raw',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------

;------------- variable:  atr_dac_table ---------------------------
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr(nn_pktnum)  ,$
   'y'     ,  fltarr(nn_pktnum,nn_dac) ,$    
   'v'     ,  fltarr(nn_pktnum,nn_dac))
dlimit=create_struct(   $      
   'datafile'     ,  'filename'  ,$
   'xsubtitle'    ,  '[sec]', $
   'ysubtitle'    ,  '[RAW]', $
   'data_att'     ,  datatype.type)   
;-------------- derive the time ----------------                                                     
  data.x = time    
for i=0,nn_pktnum-1 do begin  
      data.y(i,0)=output.ATR_W_BIAS1(i) 
      data.y(i,1)=output.ATR_W_GUARD1(i)
      data.y(i,2)=output.ATR_W_STUB1(i)
      data.y(i,3)=output.ATR_LP_BIAS1(i) 
      data.y(i,4)=output.ATR_LP_GUARD1(i)
      data.y(i,5)=output.ATR_LP_STUB1(i) 
      data.y(i,6)=output.ATR_W_BIAS2(i) 
      data.y(i,7)=output.ATR_W_GUARD2(i) 
      data.y(i,8)=output.ATR_W_STUB2(i) 
      data.y(i,9)=output.ATR_LP_BIAS2(i) 
      data.y(i,10)=output.ATR_LP_GUARD2(i) 
      data.y(i,11)=output.ATR_LP_STUB2(i)
      data.v(i,*)=indgen(nn_dac)     
endfor
;-------------
  str1= ['W_BIAS1','W_GUARD1','W_STUB1','LP_BIAS1','LP_GUARD1','LP_STUB1', $
         'W_BIAS2','W_GUARD2','W_STUB2','LP_BIAS2','LP_GUARD2','LP_STUB2'] 
      
limit=create_struct(   $                          ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  'ATR_DAC_table', $
    'xtitle',  'Time'  ,$  
   'labels',   str1, $                                          ;lable the different lines
   'labflag',    1 ,$ 
   'char_size' ,  2.  ,$                                ;this is not a tplot variable
   'xrange2'  , [min(data.x),max(data.x)], $            ;for plotting purpuses   
   'xstyle2'  ,   1  , $                                ;for plotting putpuses 
   'xlim2'    , [min(data.x),max(data.x)], $                ;this is the true range
   'ystyle'    , 1  ,$   
   'yrange', [0,12] )                             
;-------------  
store_data,'mvn_lpw_atr_dac',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------

;------------- variable:  rpt_rate ---------------------------
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr(nn_pktnum)  ,$
   'y'     ,  fltarr(nn_pktnum))
dlimit=create_struct(   $      
   'datafile'     ,  'File info'  ,$
   'data_att'     ,  datatype.type)   
;-------------- derive the time ---------------- 
 data.x=time                                                   
 data.y=2^(output.smp_avg(output.atr_i)+1)       ; from table 7.1.1 2^(rpt_rate_dummy+1) * MCU
;-------------
limit=create_struct(   $                          ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  'atr_rpt_rate * MCU', $
    'xrange2'  , [min(data.x),max(data.x)], $            ;for plotting purpuses   
    'xtitle',  'Time'  ,$  
   'char_size' ,  2.  ,$                                  ;this is not a tplot variable
    'xstyle2'  ,   1  , $                                ;for plotting putpuses 
   'xlim2'    , [min(data.x),max(data.x)], $                ;this is the true range
    'zstyle'    , 1  ,$ 
    'yrange', [0,max(data.y)*1.2] )                             
;-------------  
store_data,'mvn_lpw_atr_rpt_rate',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------

;------------- variable:  atr_mode ---------------------------
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr(nn_pktnum)  ,$
   'y'     ,  fltarr(nn_pktnum))
dlimit=create_struct(   $      
   'datafile'     ,  'File info'  ,$
   'data_att'     ,  datatype.type)   
;-------------- derive the time ---------------- 
 data.x = time                                                      
 data.y = output.ORB_MD(output.atr_i)
;-------------
limit=create_struct(   $                          ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  'ATR_mode' , $
    'xtitle',  'Time'  ,$  
   'char_size' ,  2.  ,$                                ;this is not a tplot variable
   'xrange2'  , [min(data.x),max(data.x)], $            ;for plotting purpuses   
   'xstyle2'  ,   1  , $                                ;for plotting putpuses 
   'xlim2'    , [min(data.x),max(data.x)], $                ;this is the true range
   'ystyle'    , 1  ,$   
   'yrange', [-1,18] )                            ;this is the true range                              
;-------------  
store_data,'mvn_lpw_atr_mode',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------

end
;*******************************************************************






