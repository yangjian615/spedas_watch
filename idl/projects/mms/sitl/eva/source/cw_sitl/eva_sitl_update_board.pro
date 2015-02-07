; activate = 0; not sensitive
; activate = 1; sensitive (update)
; activate = 2; sensitive (initialize)

PRO eva_sitl_update_board, state, activate
  compile_opt idl2
  @eva_sitl_com
  
  
  
  ;widget_control, state.mainbase, SENSITIVE=activate
  widget_control, state.subbase, SENSITIVE=activate
  widget_control, state.drDash, GET_VALUE=mywindow
  
  ; window margin
  x0 = 0.03; left edge
  x1 = 0.97; right edge
  y0 = 0.05; bottom edge
  y1 = 1.00;0.87; top edge
  
  ; Basic info
  yB1 = 0.52;0.48
  yB2 = 0.32;0.28
  yB3 = 0.18;0.10
  yB4 = 0.06
  
  ; Buffer Levels
  xL = 0.68
  yL2 = 0.89
  yL1 = 0.53
  yL0 = 0.17
  xLL =0.63
  xLLL = x1
  
  ; Color Bar
  xC = 0.52 ; x-position
  yC = 0.09 ; y-position
  wC = 0.08 ; width
  hC = 0.84 ; height
  redValues = bytarr(256)
  grnValues = bytarr(256)
  bluValues = bytarr(256)
  
  dy = 0.12; line height
  cwindow = [240B,240B,240B]
  cwhite  = [255B,255B,255B]
  cred    = [255B,  0B,  0B]
  cgreen  = [  0B,255B,  0B]
  cblue   = [  0B,  0B,255B]
  cyellow = [255B,255B,  0B]
  cblack  = [  0B,  0B,  0B]
  
  
  ; initialize
  if activate eq 2 then begin
    
    ;//// VIEW B: for backstructure mode /////////////
    
    myviewB  = obj_new('IDLgrView',VIEWPLANE_RECT=[0,0,1,1], COLOR=cwindow)
    mymodel3 = obj_new('IDLgrModel')
    
    
    oBackStr = obj_new('IDLgrText','Back Structure Mode',FONT=myfontL,COLOR=cred,  LOCATION=[x0,yB1])
    ;oBackStr = obj_new('IDLgrText','Back Structure Mode',FONT=myfontL,COLOR=cred,  LOCATION=convert_coord(x0,yB1, /NORMAL, /TO_DATA))
    myviewB->Add, mymodel3
    mymodel3 ->Add, oBackStr

    
    ;///// MAIN VIEW /////////////////////////////////
    
    myview   = obj_new('IDLgrView',VIEWPLANE_RECT=[0,0,1,1], COLOR=cwindow)
    myfont   = obj_new('IDLgrFont', 'Helvetica*bold')
    myfontL  = obj_new('IDLgrFont', 'Helvetica*bold',SIZE=18)
    mymodel  = obj_new('IDLgrModel')
    mymodel2 = obj_new('IDLgrModel')
    
    oTime    = obj_new('IDLgrText','time',FONT=myfont,COLOR=cwindow,   LOCATION=[x0,y1-dy])
    oTimeCtdn= obj_new('IDLgrText','remaining',FONT=myfont,COLOR=cwindow,LOCATION=[x0,y1-2*dy])
    oNsegs   = obj_new('IDLgrText','Segs',FONT=myfontL,COLOR=cwindow,  LOCATION=[x0,yB1])
    oNBuffs  = obj_new('IDLgrText','NBuffs',FONT=myfontL,COLOR=cwindow,LOCATION=[x0,yB2])
    oMinu    = obj_new('IDLgrText','min',FONT=myfont,COLOR=cwindow,    LOCATION=[x0,yB3])
    oErr     = obj_new('IDLgrText','err',FONT=myfont,COLOR=cwindow,    LOCATION=[x0,yB4])

;    oTime    = obj_new('IDLgrText','time',FONT=myfont,COLOR=cwindow,   LOCATION=convert_coord(x0,y1-dy, /NORMAL, /TO_DATA))
;    oTimeCtdn= obj_new('IDLgrText','remaining',FONT=myfont,COLOR=cwindow,LOCATION=convert_coord(x0,y1-2*dy, /NORMAL, /TO_DATA))
;    oNsegs   = obj_new('IDLgrText','Segs',FONT=myfontL,COLOR=cwindow,  LOCATION=convert_coord(x0,yB1, /NORMAL, /TO_DATA))
;    oNBuffs  = obj_new('IDLgrText','NBuffs',FONT=myfontL,COLOR=cwindow,LOCATION=convert_coord(x0,yB2, /NORMAL, /TO_DATA))
;    oMinu    = obj_new('IDLgrText','min',FONT=myfont,COLOR=cwindow,    LOCATION=convert_coord(x0,yB3, /NORMAL, /TO_DATA))
;    oErr     = obj_new('IDLgrText','err',FONT=myfont,COLOR=cwindow,    LOCATION=convert_coord(x0,yB4, /NORMAL, /TO_DATA))
    
    myview ->Add, mymodel
    myview ->Add, mymodel2

    
    mymodel ->Add, oTime
    mymodel ->Add, oTimeCtdn
    mymodel ->Add, oNsegs
    mymodel ->Add, oNBuffs
    mymodel ->Add, oMinu
    mymodel ->Add, oErr
    
    ; color bar (level 2)
    crd = [xL,yL2-dy]
    ;crd = convert_coord(xL,yL2-dy,/normal,/to_data)
    oL2_Label = obj_new('IDLgrText','Warning',FONT=myfont,COLOR=cwindow,LOCATION=[xL,yL2])
    ;oL2_Label = obj_new('IDLgrText','Warning',FONT=myfont,COLOR=cwindow,LOCATION=convert_coord(xL,yL2,/normal,/to_data))
    oL2_Number = obj_new('IDLgrText','XX',FONT=myfont,COLOR=cwindow,LOCATION=crd)
    oL2_Line = OBJ_NEW('IDLgrPlot', [0,0],[0,0], COLOR=cwindow)
    mymodel ->Add,oL2_Label
    mymodel ->Add,oL2_Number
    mymodel ->Add,oL2_Line
    
    ; color bar (level 1)
    oL1_Label = obj_new('IDLgrText','Redundant',FONT=myfont,COLOR=cwindow,LOCATION=[xL,yL1])
    ;oL1_Label = obj_new('IDLgrText','Redundant',FONT=myfont,COLOR=cwindow,LOCATION=convert_coord(xL,yL1,/normal,/to_data))
    oL1_Number= obj_new('IDLgrText','XX',FONT=myfont,COLOR=cwindow,LOCATION=[xL,yL1-dy])
    ;oL1_Number= obj_new('IDLgrText','XX',FONT=myfont,COLOR=cwindow,LOCATION=convert_coord(xL,yL1-dy,/normal,/to_data))
    oL1_Line = OBJ_NEW('IDLgrPlot', [0,0],[0,0], COLOR=cwindow)
    mymodel ->Add,oL1_Label
    mymodel ->Add,oL1_Number
    mymodel ->Add,oL1_Line
    
    ; color bar (level 0)
    oL0_Label = obj_new('IDLgrText','Target',FONT=myfont,COLOR=cwindow,LOCATION=[xL,yL0])
    ;oL0_Label = obj_new('IDLgrText','Target',FONT=myfont,COLOR=cwindow,LOCATION=convert_coord(xL,yL0,/normal,/to_data))
    oL0_Number= obj_new('IDLgrText','XX',FONT=myfont,COLOR=cwindow,LOCATION=[xL,yL0-dy])
    ;oL0_Number= obj_new('IDLgrText','XX',FONT=myfont,COLOR=cwindow,LOCATION=convert_coord(xL,yL0-dy,/normal,/to_data))
    oL0_Line = OBJ_NEW('IDLgrPlot', [0,0],[0,0], COLOR=cwindow)
    mymodel ->Add,oL0_Label
    mymodel ->Add,oL0_Number
    mymodel ->Add,oL0_Line
    
    ; color bar (main)
    redValues[0:*] = cwindow[0]
    grnValues[0:*] = cwindow[1]
    bluValues[0:*] = cwindow[2]
    oColorBar = OBJ_NEW('IDLgrColorbar', redValues, grnValues, bluValues,DIMENSIONS=[wC,hC], /SHOW_OUTLINE,color=cwindow)
    mymodel2 ->Add,oColorBar
    mymodel2 ->Translate, xC, yC, 0
    
    str_element,/add,sg,'myviewB',myviewB
    
    str_element,/add,sg,'myview',myview
    str_element,/add,sg,'mymodel',mymodel
    str_element,/add,sg,'mymodel2',mymodel2
    str_element,/add,sg,'myfont',myfont
    str_element,/add,sg,'myfontL',myfontL
    str_element,/add,sg,'oTime',oTime
    str_element,/add,sg,'oTimeCtdn',oTimeCtdn
    str_element,/add,sg,'oNsegs',oNsegs
    str_element,/add,sg,'oNBuffs',oNBuffs
    str_element,/add,sg,'oMinu',oMinu
    str_element,/add,sg,'oErr',oErr
    str_element,/add,sg,'oL2_Number',oL2_Number
    str_element,/add,sg,'oL2_Line',oL2_Line
    str_element,/add,sg,'oL1_Number',oL1_Number
    str_element,/add,sg,'oL1_Line',oL1_Line
    str_element,/add,sg,'oL0_Number',oL0_Number
    str_element,/add,sg,'oL0_Line',oL0_Line
    str_element,/add,sg,'oColorBar',oColorBar
    
    mywindow->Draw, sg.myview
    
  endif
  
  ; update
  if activate eq 1 then begin
    ok = 1
    if state.PREF.ENABLE_ADVANCED then begin
      mywindow->Draw, sg.myviewB
    endif else begin
    ;if ok then begin
      get_data,'mms_stlm_fomstr',lim=lim
      f = lim.unix_FOMStr_mod
      
      ; level setting
      val = mms_load_fom_validation()
      NBuffsMax       = val.BUFF_MAX
      if NBuffsMax lt f.TargetBuffs then message, "something is wrong with Target Buffers or Buffer Max"
      BuffExtra = NBuffsMax - f.TargetBuffs
      NBuffsTarget    = f.TargetBuffs
      NBuffsRedundant = f.TargetBuffs + 0.2*BuffExtra
      NBuffsWarning   = f.TargetBuffs + 0.7*BuffExtra
      
      lvlTarget    = long((255.0/NBuffsMax)*NBuffsTarget)
      lvlRedundant = long((255.0/NBuffsMax)*NBuffsRedundant)
      lvlWarning   = long((255.0/NBuffsMax)*NBuffsWarning)
      lvlCurrent   = long((255.0/NBuffsMax)*f.NBuffs) < 255
      
      ; level coloring
      color=cred
      if f.NBuffs le NBuffsWarning   then color=cyellow
      if f.NBuffs le NBuffsRedundant then color=cgreen
      if f.NBuffs le NBuffsTarget    then color=cgreen;cwhite
      redValues[lvlCurrent:255] = 0B
      grnValues[lvlCurrent:255] = 0B
      bluValues[lvlCurrent:255] = 0B
      redValues[0:lvlCurrent] = color[0]
      grnValues[0:lvlCurrent] = color[1]
      bluValues[0:lvlCurrent] = color[2]

      sg.myview ->SetProperty,COLOR=cblack;................ background
      
      cst = time_string(systime(1,/utc));................. current time
      css = strmid(cst, 5,2)+'/'+strmid(cst, 8,2)+$
        ' '+strmid(cst, 11,5) + ' UT'
      sg.oTime ->SetProperty,STRING=css
      
      ;..................................................... countdown
      dst = systime(1,/utc) - state.launchtime ; number of seconds passed since the launch of EVA
      rem_sec = 3.123*3600.d0 - dst
      rem_hr = string(floor(rem_sec/3600.d0),format='(I02)')
      rem_mn = string(floor((rem_sec-rem_hr*3600.d0)/60.d0),format='(I02)')
      rem_ss = string(floor(rem_sec-rem_hr*3600.d0-rem_mn*60.d0),format='(I02)')
      css = 'remaining '+rem_hr+':'+rem_mn+':'+rem_ss
      sg.oTimeCtdn ->SetProperty,STRING=css
      
      txt = strtrim(string(f.NSegs),2)+' Segs';........... # of Segment
      if f.NBuffs ge 3600 then txt = 'Hard Limit'
      sg.oNsegs ->SetProperty,STRING=txt, COLOR=color
      
      txt = strtrim(string(f.NBuffs),2)+' Buffs';........ # of Buffs
      if f.NBuffs ge 3600 then txt = '3600 Buffs'
      sg.oNBuffs ->SetProperty,STRING = txt, COLOR=color
      
      minu = round((f.NBuffs*10.0)/60.0);................... Minutes
      txt = strtrim(string(minu),2)+' min of data'
      sg.oMinu ->SetProperty,STRING = txt, COLOR=cwhite
      
      ;....................................................... Error Counts
      ;      mms_convert_fom_unix2tai, lim.unix_FOMStr,    new_tai_fomstr; Modified FOM to be checked
      ;      mms_convert_fom_unix2tai, limin.unix_FOMStr,  old_tai_fomstr; Original FOM for reference
      ;      mms_check_fom_structure, new_tai_fomstr, old_tai_fomstr, $
      ;        error_flags,  orange_warning_flags,  yellow_warning_flags,$; Error Flags
      ;        error_msg,    orange_warning_msg,    yellow_warning_msg,  $; Error Messages
      ;        error_times,  orange_warning_times,  yellow_warning_times,$; Erroneous Segments (ptr_arr)
      ;        error_indices,orange_warning_indices,yellow_warning_indices; Error Indices (ptr_arr)
      ;      loc_error = where(error_flags ne 0, count_error)
      ;      terr = 0
      ;      if count_error ne 0 then begin
      ;        for c=0,count_error-1 do begin; for each error
      ;          tstr = *(error_times[loc_error[c]]); get the erroneous times as an array
      ;          terr += n_elements(tstr); count erroneous segments
      ;        endfor
      ;      endif
      ;      ptr_free, error_times, orange_warning_times, yellow_warning_times
      ;      ptr_free, error_indices, orange_warning_indices, yellow_warning_indices
      
      terr = 0
      if terr gt 0 then ecolor=cred else ecolor=cwhite
      if terr gt 1 then txt_sfx = ' error segs' else txt_sfx = ' error seg'
      txt = strtrim(string(terr),2)+txt_sfx
      sg.oErr ->SetProperty,STRING = txt, COLOR=ecolor
      
      ; Color Bar
      crd1 = [xC+wC,yC+hC*NBuffsWarning/NBuffsMax]
      crd2 = [xL   ,yL2-dy-0.02                  ]
      sg.oL2_Number ->SetProperty,STRING=strtrim(string(long(NBuffsWarning)),2),COLOR=cywhite
      sg.oL2_Line ->SetProperty, DATAX = [crd1[0],xLL,crd2[0],xLLL], DATAY=[crd1[1],crd1[1],crd2[1],crd2[1]], COLOR=cwhite
      
      crd1 = [xC+wC,yC+hC*NBuffsRedundant/NBuffsMax]
      crd2 = [xL   ,yL1-dy-0.02                    ]
      sg.oL1_Number ->SetProperty,STRING=strtrim(string(long(NBuffsRedundant)),2),COLOR=cwhite
      sg.oL1_Line ->SetProperty, DATAX = [crd1[0],xLL,crd2[0],xLLL], DATAY=[crd1[1],crd1[1],crd2[1],crd2[1]], COLOR=cwhite
      
      crd1 = [xC+wC,yC+hC*NBuffsTarget/NBuffsMax]
      crd2 = [xL   ,yL0-dy-0.02                 ]
      sg.oL0_Number ->SetProperty,STRING=strtrim(string(long(NBuffsTarget)),2),COLOR=cwhite
      sg.oL0_Line ->SetProperty, DATAX = [crd1[0],xLL,crd2[0],xLLL], DATAY=[crd1[1],crd1[1],crd2[1],crd2[1]], COLOR=cwhite
      
      sg.oColorBar ->SetProperty, red_Values=redValues,green_values=grnValues,blue_values=bluValues,color=cwhite
      
      mywindow->Draw, sg.myview
    endelse
  endif
  
  if activate eq 0 then begin
    mywindow->Erase
  endif
END
