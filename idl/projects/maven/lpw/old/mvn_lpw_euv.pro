;;+
;PROCEDURE:   mvn_lpw_euv
;PURPOSE:
;  Takes the decumuted data (L0) from the euv packet
;  and turn it the data into L1 and L2 tplot structures
;
;USAGE:
;  mvn_lpw_euv,output,lpw_const
;
;INPUTS:
;       output:         L0 data 
;       lpw_const:      information of lpw calibration etc
;
;KEYWORDS:
;       
;CREATED BY:   Laila Andersson 17 august 2011 
;FILE: mvn_lpw_euv.pro
;VERSION:   1.1
;LAST MODIFICATION:   05/16/13
;-

pro mvn_lpw_euv, output,lpw_const
;--------------------- Constants ------------------------------------
nn_steps=lpw_const.nn_euv               ;number steps in one package
nn_diodes=lpw_const.nn_euv_diodes       ;number of diodes
dt=lpw_const.dt_euv                     ; time step
t_epoch=lpw_const.t_epoch
euv_diod_A=lpw_const.euv_diod_A    ;convert diode from raw to units
euv_diod_B=lpw_const.euv_diod_B    ;convert diode from raw to units
euv_diod_C=lpw_const.euv_diod_C    ;convert diode from raw to units
euv_diod_D=lpw_const.euv_diod_D    ;convert diode from raw to units
euv_temp=lpw_const.euv_temp        ;convert temp  from raw to units
;--------------------------------------------------------------------
nn_pktnum=output.p7                               ; number of data packages 
nn_size=nn_pktnum*nn_steps                        ; number of data points
time = double(output.SC_CLK1(output.EUV_i)+ output.SC_CLK2(output.EUV_i)/2l^16) + t_epoch
;--------------------------------------------------------------------

;------------- Checks ---------------------
if output.p7 NE n_elements(output.euv_i) then stanna
if n_elements(output.euv_i) EQ 0 then print,'(mvn_lpw_euv) No packages where found <---------------'
;-----------------------------------------

;------------- variable:  EUV ---------------------------
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr(nn_size)  ,$
   'y'     ,  fltarr(nn_size,nn_diodes))
dlimit=create_struct(   $      
   'datafile'     ,  'Info of file used'  ,$
   'xsubtitle'    ,  '[sec]', $
   'ysubtitle'    ,  '[raw units]', $
   'data_att'     ,  datatype.type)   
;-------------- derive the time ----------------                                                                                                                 
for i=0L,nn_pktnum-1 do begin
       data.x(nn_steps*i:nn_steps*(i+1)-1)  =time(i)+indgen(nn_steps)*dt 
       data.y(nn_steps*i:nn_steps*(i+1)-1,0)=output.DIODE_A(i,*)*euv_diod_A  ;'DIODE A'
       data.y(nn_steps*i:nn_steps*(i+1)-1,1)=output.DIODE_B(i,*)*euv_diod_B  ;'DIODE B'
       data.y(nn_steps*i:nn_steps*(i+1)-1,2)=output.DIODE_C(i,*)*euv_diod_C  ;'DIODE C'
       data.y(nn_steps*i:nn_steps*(i+1)-1,3)=output.DIODE_D(i,*)*euv_diod_D  ;'DIODE D'
endfor
;-------------
limit=create_struct(   $                                            ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  'mvn_lpw_euv' , $  
   'xtitle',  'Time'  ,$  
   'char_size' ,  2.  ,$                                            ;this is not a tplot variable
   'spec',        0, $                                              ;line plots
   'labels',   ['diod!DA!N','diod!DB!N','diod!DC!N','diod!DD!N'], $ ;lable the different lines
   'labflag',    1 ,$ 
   'colors',    [0,2,4,6] ,$                                        ;color for tplot on the different lines   
   'ystyle'    , 1  ,$                                              ;for plotting purpuses 
   'yrange'  , [min(data.y),max(data.y)], $                         ;for plotting purpuses   working in tplot
   'xrange2'  , [min(data.x),max(data.x)], $                        ;for plotting purpuses   not working in tplot 
   'xstyle2'  ,   1  , $                                            ;for plotting putpuses 
   'xlim2'    , [min(data.x),max(data.x)])                          ;this is the true range
;-------------  
store_data,'mvn_lpw_euv',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------


;------------- variable: EUV_temp ---------------------------
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr(nn_size)  ,$
   'y'     ,  fltarr(nn_size))
dlimit=create_struct(   $      
   'datafile'     ,  'Info of file used'  ,$
   'spec'         ,  0, $
   'xsubtitle'    ,  '[sec]', $
   'ysubtitle'    ,  '[raw units]', $
   'data_att'     ,  datatype.type)   
;-------------- derive the time ---------------- 
for i=0L,nn_pktnum-1 do $                                                        
       data.x(nn_steps*i:nn_steps*(i+1)-1)=time(i)+indgen(nn_steps)*dt                                                                                                                   
for i=0L,nn_pktnum-1 do $
       data.y(nn_steps*i:nn_steps*(i+1)-1)=output.THERM(i,*)
;-------------
limit=create_struct(   $                                          ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  'mvn_lpw_euv_temp' , $  
   'xtitle',  'Time'  ,$  
   'char_size' ,  2.  ,$                                          ;this is not a tplot variable
   'ystyle'    , 1  ,$                                            ;for plotting purpuses 
   'yrange'  , [min(data.y),max(data.y)], $                       ;for plotting purpuses   working in tplot
   'xrange2'  , [min(data.x),max(data.x)], $                      ;for plotting purpuses   not working in tplot 
   'xstyle2'  ,   1  , $                                          ;for plotting putpuses 
   'xlim2'    , [min(data.x),max(data.x)])                        ;this is the true range
;-------------  
store_data,'mvn_lpw_euv_temp',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------


;------------- variable: EUV_temp ---------------------------
;If you take the 20 bit temperature data and divide it by 16 to get 16 bit numbers, the numbers should follow the following conversion:
;Temp_in_DN(16 bit) = 41.412 x Temp_in_deg_C - 8160.7
 ;    (measured *  euv_temp(0) +   euv_temp(1)) /euv_temp(2)  = Temp_in_deg_C
datatype=create_struct('type', '{deg C}')
data=create_struct(   $        
   'x'     ,  dblarr(nn_size)  ,$
   'y'     ,  fltarr(nn_size))
dlimit=create_struct(   $      
   'datafile'     ,  'Info of file used'  ,$
   'spec'         ,  0, $
   'xsubtitle'    ,  '[sec]', $
   'ysubtitle'    ,  '[deg C]', $
   'data_att'     ,  datatype.type)   
;-------------- derive the time ---------------- 
for i=0L,nn_pktnum-1 do $                                                        
       data.x(nn_steps*i:nn_steps*(i+1)-1)=time(i)+indgen(nn_steps)*dt                                                                                                                   
for i=0L,nn_pktnum-1 do $
       data.y(nn_steps*i:nn_steps*(i+1)-1)= (output.THERM(i,*) *  euv_temp(0) +   euv_temp(1)) /euv_temp(2) 
;-------------
limit=create_struct(   $                                          ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  'mvn_lpw_euv_temp_C' , $  
   'xtitle',  'Time'  ,$  
   'char_size' ,  2.  ,$                                          ;this is not a tplot variable
   'ystyle'    , 1  ,$                                            ;for plotting purpuses 
   'yrange'  , [min(data.y),max(data.y)], $                       ;for plotting purpuses   working in tplot
   'xrange2'  , [min(data.x),max(data.x)], $                      ;for plotting purpuses   not working in tplot 
   'xstyle2'  ,   1  , $                                          ;for plotting putpuses 
   'xlim2'    , [min(data.x),max(data.x)])                        ;this is the true range
;-------------  
store_data,'mvn_lpw_euv_temp_C',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------


;---------variable: info of the packet start -----------------
nn_size=nn_pktnum    ; number of data packages
data=create_struct(   $        
   'x'     ,  dblarr(nn_size)  ,$
   'y'     ,  fltarr(nn_size))
   data.x= time
   data.y=1.0
;-------------
   store_data,'mvn_lpw_euv_packet_start',data=data
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
 data.y=2.^(output.smp_avg(output.euv_i)+6)       ; from ICD section 7.6
;-------------
limit=create_struct(   $                          ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  'EUV_smp_avg', $
    'xrange2'  , [min(data.x),max(data.x)], $            ;for plotting purpuses   
    'xtitle',  'Time'  ,$  
   'char_size' ,  2.  ,$                                  ;this is not a tplot variable
    'xstyle2'  ,   1  , $                                ;for plotting putpuses 
   'xlim2'    , [min(data.x),max(data.x)], $                ;this is the true range
    'zstyle'    , 1  ,$ 
    'yrange', [2^6,max(data.y)] )                             
;-------------  
store_data,'mvn_lpw_euv_smp_avg',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------

end
;*******************************************************************







