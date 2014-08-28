;;+
;PROCEDURE:   mvn_lpw_htime
;PURPOSE:
;  Takes the decumuted data (L0) from the HTIME packet
;  and turn it the data into tplot structures
;  This packet contains the information of when HSBM packets are created
;  The capture time and when they where sent to the archive
;  Noraml operation: HTIME paket is transimtted in the survey pipeline while HSBM is via archive
;
;USAGE:
;  mvn_lpw_pas,output,lpw_const
;
;INPUTS:
;       output:         L0 data 
;       lpw_const:      information of lpw calibration etc
;
;KEYWORDS:
;       
;
;CREATED BY:   Laila Andersson 13 august 2012 
;FILE: mvn_lpw_pas.pro
;VERSION:   1.1
; Changes:  Time in the header is now associated with the last measurement point
;LAST MODIFICATION:   05/16/13
;-

pro mvn_lpw_htime, output,lpw_const

;--------------------- Constants ------------------------------------
t_epoch=lpw_const.t_epoch        
;--------------------------------------------------------------------
;--------------------------------------------------------------------       
; time stamp of the packet it self
time=double(output.SC_CLK1(output.HTIME_i)) + output.SC_CLK2(output.HTIME_i)/2l^16+t_epoch  ;number of packets

length=(((long(output.length[output.HTIME_i])-1)/2)-7)/2+1
lenght_cum0=total(length,/CUMULATIVE)
time_long=dblarr(n_elements(output.htime_type))  ;make time so it matches htime_type

for i=0,n_elements(time)-1 do $ 
  if length(i) GT 0 then $ 
        time_long(lenght_cum0(i)-length(i):lenght_cum0(i)-1)=time(i)
type_3=['lf','mf','hf','unused']  ; 00, 01, 10, 11 see ICD section 9.11 

;--------------------------------------------------------------------    
for iu=0,2  do begin ; loop over the HSBM types lf mf hf
    type=type_3(iu)
    qq=where(output.htime_type EQ iu,nq)  
    
;-------------  compare time with time as function of time  capture time and trensfere time---------------------------
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr(nq)  ,$
   'y'     ,  fltarr(nq))
dlimit=create_struct(   $      
   'datafile'     ,  'Info of file used'  ,$
   'xsubtitle'    ,  '[sec]', $
   'ysubtitle'    ,  '', $
   'data_att'     ,  datatype.type)   
;-------------- derive the time ----------------                                                
       data.x=double(time_long(qq) + output.cap_time(qq))                                                                                                               
       data.y=output.htime_type(qq)+0.8     ; for the plotting routine the yvalue in cap and xfer needs to be different  
;-------------- derive the time ---------------- 
limit=create_struct(   $                           ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  'Capture time '+type , $   
   'xtitle',  'Time (not sorted)'  ,$   
   'char_size' ,  2.  ,$                           ;this is not a tplot variable
   'xrange2'  , [min(data.x),max(data.x)], $       ;for plotting purpuses   
   'xstyle2'  ,   1  , $                           ;for plotting putpuses 
   'xlim2'    , [min(data.x),max(data.x)], $                ;this is the true range
   'ystyle'    , 1  ,$                                        ;for plotting purpuses 
   'yrange'  , [0,3] ) 
;------------- 
store_data,'mvn_lpw_htime_cap_'+type,data=data,limit=limit,dlimit=dlimit
;--------------------------------------------------       
        data.x=double(time_long(qq) + output.xfer_time(qq))
        data.y=output.htime_type(qq) +0.1     ; for the plotting routine the yvalue in cap and xfer needs to be different      
        limit.ytitle='Xfer '+type 
store_data,'mvn_lpw_htime_xfer_'+type,data=data,limit=limit,dlimit=dlimit
;--------------------------------------------------       

endfor  ;end loop over the HSBM types lf mf hf


;------------- variable:  HTIME report rate ---------------------------
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr(n_elements(time))  ,$
   'y'     ,  fltarr(n_elements(time)))
dlimit=create_struct(   $      
   'datafile'     ,  'File info'  ,$
   'data_att'     ,  datatype.type)   
;-------------- derive the time ---------------- 
 data.x = time                                                      
 data.y = 2^output.smp_avg(output.HTIME_i)        ; smp_avg is used for htime to get the HTIME_rate, Equation see table 7.8 ICD
;-------------
limit=create_struct(   $                          ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  'HTIME rate (sec)', $
    'xrange2'  , [min(data.x),max(data.x)], $            ;for plotting purpuses   
    'xtitle',  'Time'  ,$  
   'char_size' ,  2.  ,$                                  ;this is not a tplot variable
    'xstyle2'  ,   1  , $                                ;for plotting putpuses 
   'xlim2'    , [min(data.x),max(data.x)], $                ;this is the true range
    'zstyle'    , 1  ,$ 
    'yrange', [-1,max(data.y)*1.2] )                             
;-------------  
store_data,'mvn_lpw_htime_rate',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------

end
;*******************************************************************









