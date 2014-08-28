;;+
;PROCEDURE:   mvn_lpw_hsk
;PURPOSE:
;  Takes the decumuted data (L0) from the HSK packet
;  and turn it the data into tplot structures
;  WARNING the temperature calibration information should move into instrument_calibration file!! (lwp_const)
;
;USAGE:
;  mvn_lpw_hsk,output,lpw_const
;
;INPUTS:
;       output:         L0 data 
;       lpw_const:      information of lpw calibration etc
;
;KEYWORDS:
;       
;
;CREATED BY:   Laila Andersson 17 august 2011 
;FILE: mvn_lpw_hsk.pro
;VERSION:   1.1
; Changes:  Time in the header is now associated with the last measurement point
;LAST MODIFICATION:   05/16/13
;-

pro mvn_lpw_hsk, output,lpw_const
;--------------------- Constants ------------------------------------
t_epoch=lpw_const.t_epoch
;--------------------------------------------------------------------

;------------------------------------------------------------
nn_pktnum=output.p9                              ; number of data packages
nn_size=nn_pktnum                                 ; number of data points 
;--------------------------------------------------------------------

;------------- Checks ---------------------
if output.p9 NE n_elements(output.hsk_i) then stanna
if n_elements(output.hsk_i) EQ 0 then print,'(mvn_lpw_hsk) No packages where found <---------------'
;-----------------------------------------

time=double(output.SC_CLK1(output.hsk_i)+output.SC_CLK2(output.hsk_i)/2l^16)+t_epoch    


;------------- variable:  hsk ---------------------------
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr(nn_size)  ,$
   'y'     ,  fltarr(nn_size,17))
dlimit=create_struct(   $      
   'datafile'     ,  'Info of file used'  ,$
   'data_att'     ,  datatype.type)   
;-------------- derive the time ----------------                                                     
       data.x=time                                                                                                                 
for i=0,nn_pktnum-1 do begin
       ;data.y(i,0)= output.Preamp_Temp1(i)  * 0.02648 + 172.9     ;* 0.0331 + 262.9  ;  ((0.003152-7.78491e-5*output.Preamp_Temp1(i))-5.815e-1)/(-2.351e-3)  ;  * 0.0331 + 262.9  ;Boom1    -0.00315212  7.78491e-05
       ;data.y(i,1)= output.Preamp_Temp2(i)  * 0.024825 + 165.9    ;  * 0.0331 + 262.9  ;Boom2     -0.0153951  7.62035e-05
     
       ;data.y(i,0)= output.Preamp_Temp1(i)  * 0.02648*1.05 + 182.9     ;* 0.0331 + 262.9  ;  ((0.003152-7.78491e-5*output.Preamp_Temp1(i))-5.815e-1)/(-2.351e-3)  ;  * 0.0331 + 262.9  ;Boom1    -0.00315212  7.78491e-05
       ;data.y(i,1)= output.Preamp_Temp2(i)  * 0.024825*1.05 + 175.9    ;  * 0.0331 + 262.9  ;Boom2     -0.0153951  7.62035e-05
 
       data.y(i,0) =(output.Preamp_Temp1(i)* 0.033113 + 262.68) -6. ;  
       data.y(i,1) =(output.Preamp_Temp2(i)  * 0.033113 + 262.68) -8. ;
              
       data.y(i,2)=output.Beb_Temp(i)          * 0.0325 + 256.29
       data.y(i,3)=output.plus12va(i)          * 0.0004581
       data.y(i,4)=output.minus12va(i)         * 0.0004699
       data.y(i,5)=output.plus5va(i)           * 0.0001913
       data.y(i,6)=output.minus5va(i)          * 0.0001923
       data.y(i,7)=output.plus90va(i)          * 0.0077058
       data.y(i,8)=output.minus90va(i)         * 0.0077058
       data.y(i,9)=output.CMD_ACCEPT(i)
       data.y(i,10)=output.CMD_REJECT(i)
       data.y(i,11)=output.MEM_SEU_COUNTER(i)
       data.y(i,12)=output.INT_STAT(i)
       data.y(i,13)=output.CHKSUM(i)
       data.y(i,14)=output.EXT_STAT(i)
       data.y(i,15)=output.DPLY1_CNT(i)
       data.y(i,16)=output.DPLY2_CNT(i)   
endfor
str1=['Preamp_Temp1','Preamp_Temp2','Beb_Temp','plus12va','minus12va','plus5va','minus5va','plus90va','minus90va','CMD_ACCEPT','CMD_REJECT', $
      'MEM_SEU_COUNTER','INT_STAT','CHKSUM','EXT_STAT','DPLY1_CNT','DPLY2_CNT']
;-------------
limit=create_struct(   $                          ;this one I set up the fields as I need, not directly after tplot options  
   'labels',   str1, $                                          ;lable the different lines
   'labflag',    1 ,$ 
   'ytitle',  'hsk'  , $                                      ;this one I set up the fields as I need, not directly after tplot options
   'xtitle',  'Time'  ,$  
   'ztitle',  'power/freq'  ,$  
   'char_size' ,  2.  ,$                                      ;this is not a tplot variable
   'xrange2'  , [min(data.x),max(data.x)], $                  ;for plotting purpuses      not for tplot
   'xstyle2'  ,   1  , $                                      ;for plotting putpuses       not for tplot
   'xlim2'    , [min(data.x),max(data.x)])                             ;this is the true range
;-------------  
store_data,'mvn_lpw_hsk',data=data,limit=limit,dlimit=dlimit
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
 data.y=2^(output.smp_avg(output.hsk_i)+1)       ; from ICD section 7.6
;-------------
limit=create_struct(   $                          ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  'hsk_smp_avg', $
    'xrange2'  , [min(data.x),max(data.x)], $            ;for plotting purpuses   
    'xtitle',  'Time'  ,$  
   'char_size' ,  2.  ,$                                  ;this is not a tplot variable
    'xstyle2'  ,   1  , $                                ;for plotting putpuses 
   'xlim2'    , [min(data.x),max(data.x)], $                ;this is the true range
    'zstyle'    , 1  ,$ 
    'yrange', [0,max(data.y)*1.2] )                             
;-------------  
store_data,'mvn_lpw_hsk_smp_avg',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------


end
;*******************************************************************







