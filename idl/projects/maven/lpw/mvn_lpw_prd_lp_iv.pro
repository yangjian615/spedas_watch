
;+
;PROCEDURE:   mvn_lpw_prd_lp_IV
;
; Routine takes IV-cureves from both booms and combines them into one tplot variable for L2-production. 
; The default swp1 and swp2 are from different subcycles.
; The sweep length can vary but the number of points in the sweep is fixed
; There will be error both in the current and the sweep potential
; The error information and flag information is taking also into consideration information from other sources such as spacecraft atitude.
;
;INPUTS:         
; - None directly required by user. 
;   The tplot variables mvn_lpw_swp1_IV and mvn_lpw_swp2_IV  must be loaded into tplot memory before running this routine. 
;   There are additional variables that need to be loaded
;   Presently this routine do not go an grab missing variables.
;   
;KEYWORDS:
; - make_cdf                                ;make one L2-cdf for the NASA DPS archive
; 
;EXAMPLE:
; mvn_lpw_prd_lp_IV,/make_cdf
;
;
;CREATED BY:   Laila Andersson  11-04-13
;FILE:         mvn_lpw_prd_lp_IV.pro
;VERSION:      1.0
;LAST MODIFICATION: 
;
;-

pro mvn_lpw_prd_lp_IV, make_cdf=make_cdf

;---------------------------------------------------------------------------------------------------
;    Check which variables exists for this routine
;    for the moment all variables has to be loaded in all ready, this routine do not call on any other routines 
;---------------------------------------------------------------------------------------------------

; Get the time this routine was sun into the tplot variable
t_routine=SYSTIME(0) 
vers_prd= '1.0'  ; the version number of this routine


;Check tplot variables exist before calling them:
names = tnames(s)                               ;names is an array containing all tplot variable names currently in IDL memory.

missing_variable=' The following variables are missing: '

IF total(strmatch(names, 'mvn_lpw_swp1_IV')) EQ 1 THEN $ 
     get_data,'mvn_lpw_swp1_IV',data=data1,limit=limit1,dlimit=dlimit1 ELSE missing_variable=[missing_variable,'mvn_lpw_swp1_IV was not found']

IF total(strmatch(names, 'mvn_lpw_swp2_IV')) EQ 1 THEN $
     get_data,'mvn_lpw_swp2_IV',data=data2,limit=limit2,dlimit=dlimit2 ELSE missing_variable=[missing_variable,'mvn_lpw_swp2_IV was not found']

IF total(strmatch(names, 'mvn_sc_atitude')) EQ 1 THEN $                            ;<---------- do not yet know the name, this rutine needs the SC to solar-angle information
     get_data, 'mvn_sc_atitude', data=data_sc_att ELSE missing_variable=[missing_variable,'mvn_sc_atitude was not found']

IF n_elements(missing_variable) GT 1 then print,'mvn_lpw_prd_lp_IV: ##### WARNING ###### ',missing_variable

;Check data is present in either the ACT or PAS tplot variables
;Use IDLs size routine to determine if the data is a structure or not.
;If the data is in structure form t_act/pas will = 8.
     type_1 = size(data1, /type)  
     type_2 = size(data2, /type)
     type_sc_att = size(data_sc_att, /type)


;NOTE: we need to check that the data comes from the same day......and everything....
; could it be done something like
; ...we might only check that the day is the same on all three files.......
; 

IF ((type_1 NE 8) and (type_2 NE 8)) EQ 1 then begin
     print,'mvn_lpw_prd_lp_IV: There was no data found '
     IF min(data1.x) GT max(data2.x) OR min(data2.x) GT max(data1.x) THEN $
                       print,'mvn_lpw_prd_lp_IV:### WARNING #### The two time periods do not over lap, check the two tplot variables! '
     IF min(data1.x) GT max(data_sc_att.x) OR min(data_sc_att.x) GT max(data1.x) THEN $
                      print,'mvn_lpw_prd_lp_IV:### WARNING #### The SC attitude file are from another time period '                  
     return                                             
ENDIF  
  
;---------------------------------------------------------------------------------------------------
;       Variables found and read into memory
;---------------------------------------------------------------------------------------------------
 

;---------------------------------------------------------------------------------------------------
;                  Merge the dlimit and limit information for tplot production
;---------------------------------------------------------------------------------------------------
 
 If (type_1 EQ 8)  then limit=limit1 else limit=limit2          ; if only one of the files exist limit will be defined
 If (type_1 EQ 8)  then dlimit=dlimit1 else dlimit=dlimit2      ; if only one of the files exist dlimit will be defined
  
;---------------------------------------------------------------------------------------------------
;                              dlimit and limit created
;---------------------------------------------------------------------------------------------------




;---------------------------------------------------------------------------------------------------
;                             Creating the data_l2 product:  
;                             Merge the data 
;                             Modify the error information with respect of atitude and other things
;                             Create a quality flag
;---------------------------------------------------------------------------------------------------
 
 ;I think this will crash if not both data1 and data2 exists, needs to be fixed
         
         ;get the size of the structures
          nn1 = n_elements(data1.x)                                        ;number of elements 
          nn2 = n_elements(data2.x)      
          n_row=n_elements(data1.y(0,*))         
          
          data_x    =[data1.x,data2.x]                                     ;get everything in one array  
          data_y    =[data1.y,data2.y]
          data_dy   =[data1.dy,data2.dy]                                  ;this is the error based on only the packet information
          data_v    =[data1.v,data2.v]
          data_dv   =[data1.dv,data2.dv]                                  ;this is the error based on only the packet information
          data_id   =[1+fltarr(nn1),2+fltarr(nn2)]                        ;This is to keep track which variable created which data (1,2...)               
                     
          in_order=SORT(data_x)                                         ;sort in time
          
          data_l2_id  =data_id(in_order)                        ;get everything in one sorted time array                
          data_l2_x   =data_x(in_order)                                       
          data_l2_y   =data_y(in_order,*)                                   
          data_l2_dy  =data_dy(in_order,*)                        ;this error needs to be updated to reflect infromation from other sources such as sc attitude                                    
          data_l2_v   =data_v(in_order,*)                                   
          data_l2_dv  =data_dv(in_order,*)                        ;this error needs to be updated to reflect infromation from other sources such as sc attitude                                    
          data_l2_flag=fltarr(nn1+nn2)                          ;this flag is created here and provide information of our confedence level of the value
        
 
;  ------ evaluate the error and flag                         <---- need information for the other tplot variables for this part.

If (type_sc_att NE 8) then begin
          print,'mvn_lpw_prd_lp_IV: #### WARNING no spacecraft attitude data #### set flag to -1.'
          data_l2_flag=-1.         ; no confidence in the data, the probes can be anywhere!!!
ENDIF 

;  ################ to be written ######################## this is where science are made TBD


;---------------------------------------------------------------------------------------------------
;                                end of creating the data_l2 product  
;---------------------------------------------------------------------------------------------------




;---------------------------------------------------------------------------------------------------
;                            Create the L2 tplot variables
;---------------------------------------------------------------------------------------------------
;------------------ Variables created not stored in CDF files -------------------    
   
;                            None     
 
;------------------ Variables created not stored in CDF files -------------------     
;------------------All information based on the SIS document-------------------         
                        
                ;-------------------- tplot variable 'mvn_lpw_lp_IV_L2' ------------------- 
                ;--------------------- SIS name: LPW.calibrated.lp_IV -------------------  
                ;-------------------  There will be 1 CDF file per day --------------------   
                data_l2 =  create_struct(   $            ; Which are used should follow the SIS document for this variable !! Look at: Table 16: : Contents for LPW.calibrated.lp_IV calibrated data file.         
                                         'x',    data_l2_x,  $     ; double 1-D arr
                                         'y',    data_l2_y,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   data_l2_dy,  $    ; same size as y
                                         'v',    data_l2_v,  $     ; same size as y
                                         'dv',   data_l2_dv,  $    ;same size as y
                                         'flag', data_l2_flag)     ;1-D 
                ;-------------------------------------------
                dlimit_l2=create_struct(   $             ; Which are used should follow the SIS document for this variable !! Look at: Table 16: : Contents for LPW.calibrated.lp_IV calibrated data file.                 
                   'generated_date'  ,     dlimit.generated_date+' # '+t_routine, $  ;Gives the date and time the data is derived and the CDF file was created - can be multiple times ponts
                   't_epoch'         ,     dlimit.t_epoch, $                         ; The spacecraft clock zero time represent that is used when converting the time in the packet headers to physical time 
                   'L0_datafile'     ,     dlimit1.L0_datafile  +' # '+dlimit2.L0_datafile, $ ; Gives the name of the L0 file used, if multiple variable use, this can be multiple names of the same or different files 
                   'cal_vers'        ,     dlimit.cal_vers      +' # '+vers_prd   , $  ; Gives the calibration file version
                   'cal_y_const1'    ,     dlimit1.cal_y_const1 +' # '+ dlimit2.cal_y_const1,$  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   'cal_y_const2'    ,     'Merge level:' +strcompress(1,/remove_all) ,$  ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ; not defined for this 'cal_datafile'    ,     dlimit1.cal_datafile + ' # ' + dlimit2.cal_datafile, $; If one or more calibration files has been used the file names is located here (file names of the calibration files included dates and version number of when the are created)
                   'cal_source'      ,     'Merging: mvn_lpw_swp1_IV and mvn_lpw_swp2_IV', $  ; Information of what has been considered in the data production (sc attitude, other instruments etc)       
                   'flag_info'       ,     'Confidence level: 1 high and 0 low',  $   ; Normally flag represent ‘confidence level’ if not stated differently. 0 no confidence at all. Can be used for aperture open/close etc.                                               
                   'flag_source'     ,     'Merging: TBD', $ ; Information of what is considered when the flag is created (such as sc-atitude)
                   'xsubtitle'       ,     '[sec]', $   ; units
                   'ysubtitle'       ,     'V', $   ; units          
                   'cal_v_const1'    ,     dlimit.cal_v_const1 + ' # ' + dlimit2.cal_v_const1,$  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   'cal_v_const2'    ,     'Merge level:' +strcompress(1,/remove_all) ,$  ; Fixed convert information from measured binary values to physical units, variables from space testing
                   'zsubtitle'       ,     '[nA]')   ; units
                ;-------------------------------------------
                limit_l2=create_struct(   $                ; Which are used should follow the SIS document for this variable !! Look at: Table 16: : Contents for LPW.calibrated.lp_IV calibrated data file.
                  'char_size' ,     limit.char_size ,$    
                  'xtitle' ,        limit.xtitle ,$   
                  'ytitle' ,        'Sweep Potential' ,$   
                  'yrange' ,        [-50,50] ,$   
                  'ystyle'  ,       limit.ystyle ,$ 
                  ;'ylog'   ,        limit.ylog   ,$ 
                  'ztitle' ,        'Current' ,$   
                  'zrange' ,        limit.zrange ,$
                  ;'zlog'  ,         limit.zlog   ,$
                  'spec'  ,         limit.spec)   
                 ; 'labels' ,        limit.labels,$   ; not used for this product
                 ; 'colors' ,        limit.colors,$   ; not used for this product 
                 ; 'labflag' ,       limit.labflag)   ; not used for this product                            
                ;---------------------------------------------
                store_data,'mvn_lpw_lp_IV_l2',data=data_l2,limit=limit_l2,dlimit=dlimit_l2 
                ;---------------------------------------------    



;---------------------------------------------------------------------------------------------------
;                              end tplot production
;---------------------------------------------------------------------------------------------------


;---------------------------------------------------------------------------------------------------
;                              In case key-word CDF
;---------------------------------------------------------------------------------------------------

If (keyword_set(make_cdf)) Then $
             mvn_lpw_cdf_write_l2,'mvn_lpw_lp_IV_l2'

;---------------------------------------------------------------------------------------------------
;---------------------------------------------------------------------------------------------------



end
;*******************************************************************

