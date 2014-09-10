;+
; A WRAPPER ROUTINE TO INTERFACE WITH THE BERKELEY TPLOT CODE
;
; :Params:
;    kp_data: in, required, type=structure
;       the INSITU KP data structure from which to plot data
;    field: in, required, type=strarr,intarr
;       the INSITU kp data fields to plot, maybe an integer or string array for multiple choices
;
; :Keywords:
;    list: in, optional, type=boolean
;       if selected, will list the KP data fields included in kp_data
;    range: in, optional, type=boolean
;       if selected, will list the beginning and end times of kp_data
;    altitude: in, optional, type=boolean
;       if selected, will inclue altitude on the xaxis along with time
;    ytitles: in, optional, type=strarr
;       if included, this array allows the user to define the yaxis titles as they like
;    title: in, optional, type=string
;       if included, this provides an overall title to the plot window
;-


@mvn_kp_tag_parser
@mvn_kp_tag_list
@mvn_kp_range
@mvn_kp_range_select
@mvn_kp_tag_verify

pro MVN_KP_TPLOT, kp_data, parameter=parameter, time=time, list=list, ytitles=ytitles,range=range,$
                  createall=createall, prefix=prefix, message=message, quiet=quiet, $
                  euv=euv, lpw=lpw, static=static, swea=swea, swia=swia, mag=mag, sep=sep, ngims=ngims


  MVN_KP_TAG_PARSER, kp_data, base_tag_count, first_level_count, second_level_count, base_tags,  first_level_tags, second_level_tags


    if arg_present(list)  then begin  
      list = strarr(250)
      index2=0
      for i=0,base_tag_count-1 do begin
          if first_level_count[i] ne 0 then begin
              for j=0,first_level_count[i]-1 do begin
                if first_level_count[i] ne 0 then begin 
                    list[index2] = '#'+strtrim(string(index2+1),2)+' '+base_tags[i]+'.'+strtrim(string(first_level_tags[index2-1]),2)
                    index2 = index2+1
                endif 
              endfor
          endif
        endfor
      list = list[0:index2-1]
      return
    endif else begin
      if keyword_set(list) then begin
        MVN_KP_TAG_LIST, kp_data, base_tag_count, first_level_count, base_tags,  first_level_tags
        return
      endif
    endelse


  ;PROVIDE THE TEMPORAL RANGE OF THE DATA SET IN BOTH DATE/TIME AND ORBITS IF REQUESTED.
  if keyword_set(range) then begin
    MVN_KP_RANGE, kp_data
    return
  endif


  ;IF THE USER SUPPLIES A TIME RANGE, SET THE BEGINNING AND END INDICES
  
  if keyword_set(time) then begin     ;determine the start and end indices to plot
    MVN_KP_RANGE_SELECT, kp_data, time, kp_start_index, kp_end_index
  endif else begin                    ;otherwise plot all data within structure
   kp_start_index = 0
   kp_end_index = n_elements(kp_data.orbit)-1
  endelse


  ;SET THE USER DEFINED PREFIX OR DEFAULT TO MVN_KP
  
  if keyword_set(prefix) then begin
    prefix=prefix
  endif else begin
    prefix = 'MVN_KP_'
  endelse
  
  ;SET THE USER DEFINED MESSAGE, IF PROVIDED, OR DEFAULT  
  
  if keyword_set(message) then begin
    message = {source: message}
  endif else begin
    message = {source: 'Created from KP Data'}
  endelse

;SET DEFAULTS COLORS TO BLACK ON WHITE
    device,decompose=0
    !p.background='FFFFFF'x
    !p.color=0
    loadct,39,/silent
    
;IF THE USER SELECTS ANY OF THE INSTRUMENT FLAGS, THEY TAKE PRECEDENCE AND OVER-WRITE PARAMETERS REQUESTED
  if keyword_set(euv) or keyword_set(lpw) or keyword_set(static) or keyword_set(swea) or keyword_set(swia) $
      or keyword_set(mag) or keyword_set(sep) or keyword_set(ngims) then begin
      
      temp_parameters = intarr(300)
      temp_index=0
      
      ;PULL ALL THE LPW DATA FIELDS 
        if keyword_set(lpw) then begin
          x1 = where(base_tags eq 'LPW')
          for i=1,first_level_count[x1[0]] do begin
            temp_parameters[temp_index] = total(first_level_count[0:x1-1])+i
            temp_index=temp_index+1
          endfor
        endif
      
      ;PULL ALL THE STATIC DATA FIELDS
        if keyword_set(static) then begin
          x1 = where(base_tags eq 'STATIC')
          for i=1,first_level_count[x1[0]] do begin
            temp_parameters[temp_index] = total(first_level_count[0:x1-1])+i
            temp_index=temp_index+1
          endfor
        endif
      
       ;PULL ALL THE SWEA DATA FIELDS
        if keyword_set(swea) then begin
          x1 = where(base_tags eq 'SWEA')
          for i=1,first_level_count[x1[0]] do begin
            temp_parameters[temp_index] = total(first_level_count[0:x1-1])+i
            temp_index=temp_index+1
          endfor
        endif
      
       ;PULL ALL THE SWIA DATA FIELDS
        if keyword_set(swia) then begin
          x1 = where(base_tags eq 'SWIA')
          for i=1,first_level_count[x1[0]] do begin
            temp_parameters[temp_index] = total(first_level_count[0:x1-1])+i
            temp_index=temp_index+1
          endfor
        endif
        
       ;PULL ALL THE MAG DATA FIELDS
        if keyword_set(mag) then begin
          x1 = where(base_tags eq 'MAG')
          for i=1,first_level_count[x1[0]] do begin
            temp_parameters[temp_index] = total(first_level_count[0:x1-1])+i
            temp_index=temp_index+1
          endfor
        endif
      
       ;PULL ALL THE SEP DATA FIELDS
        if keyword_set(sep) then begin
          x1 = where(base_tags eq 'SEP')
          for i=1,first_level_count[x1[0]] do begin
            temp_parameters[temp_index] = total(first_level_count[0:x1-1])+i
            temp_index=temp_index+1
          endfor
        endif

       ;PULL ALL THE NGIMS DATA FIELDS
        if keyword_set(ngims) then begin
          x1 = where(base_tags eq 'NGIMS')
          for i=1,first_level_count[x1[0]] do begin
            temp_parameters[temp_index] = total(first_level_count[0:x1-1])+i
            temp_index=temp_index+1
          endfor
        endif

      parameter = temp_parameters[0:temp_index-1]
     
  endif
    
    
;IF USER CHOOSES CREATEALL, BUILD TPLOT VARIABLES FROM ALL PARAMETERS AND THEN QUIT

  if keyword_set(createall) then begin
    print,'**** Creating Tplot variables from all available KP Parameters ****'
    index=0
    for i=0, n_elements(first_level_count)-1 do begin
      if first_level_count[i] gt 0 then begin
        for j=0, first_level_count[i]-1 do begin
          tplot_name = strtrim(prefix+base_tags[i],2)+':'+strtrim(first_level_tags[index])
          store_data,tplot_name, data={x:kp_data[kp_start_index:kp_end_index].time, y:kp_data[kp_start_index:kp_end_index].(i).(j)},dlimits=message,verbose=0
          index=index+1
        endfor
      endif
    endfor
    if (keyword_set(quiet) ne 1) then tplot_names
    return
  endif else begin
     
    ;OTHERWISE CREAT ONLY THE TPLOT VARIABLES REQUESTED
      ;CREATE THE PLOT VECTORS
      
      for i=0, n_elements(parameter)-1 do begin                                   
              MVN_KP_TAG_VERIFY, kp_data, parameter[i],base_tag_count, first_level_count, base_tags,  $
                          first_level_tags, check, level0_index, level1_index, tag_array
    
           if check eq 0 then begin            ;CHECK THAT THE REQUESTED PARAMETER EXISTS
    
              tplot_name = strtrim(prefix+tag_array[0],2)+':'+strtrim(tag_array[1],2)
              store_data,tplot_name, data={x:kp_data[kp_start_index:kp_end_index].time, y:kp_data[kp_start_index:kp_end_index].(level0_index).(level1_index)},dlimits=message,verbose=0
            
           endif else begin
             print,'Requested plot parameter is not included in the data. Try /LIST to confirm your parameter choice.'
             return
           endelse
     endfor
 endelse
 
 if (keyword_set(quiet) ne 1) then tplot_names
  


end