
FUNCTION eva_data_load_daily_check, save_var, date
  @tplot_com
  names=tnames('*',nmax,ind=ind)
  tobeDL = 0 ; NOT to be downloaded
  for s=0,n_elements(save_var)-1 do begin; for each required variable
    index = where(strmatch(names,save_var[s]),count)
    case count of
      0:  begin; if not found then download
        tobeDL = 1
      end
      1:  begin; if found, check time range
        i  = ind[index[0]]
        dq = data_quants[i]
        tr = time_string(dq.trange,precision=7)
        da1= strmid(tr[0],0,10); get date
        da2= strmid(tr[1],0,10); get date
        if not (strcmp(date,da1) and strcmp(date,da2)) then tobeDL = 1; to be downloaded
      end
      else:begin
      print, '!!!!! ERROR: something is wrong with count (eva_data_load_daily_check) !!!!!'
      stop
    end
  endcase
endfor; for each required variable
return, tobeDL
END

FUNCTION eva_data_load_daily_prbarr, arr, ilbl
  offset = 2 ; filenames have two-letter offset to indicate mission name. e.g. thb_, thad_, mma_,mmb_
  lbl = strmid(arr,0,offset)
  nmax = strlen(arr)-offset
  prbarr = strarr(nmax)
  for n=0,nmax-1 do begin
    if ilbl then prbarr[n] = lbl + strmid(arr,n+offset,1) $
    else prbarr[n] = strmid(arr,n+offset,1)
  endfor
  return, prbarr
END

FUNCTION eva_data_load_daily, filename, cache_data_dir
  @tplot_com

  catch, error_status
  if error_status ne 0 then begin
    catch, /cancel
    eva_error_message, error_status, msg='filename= '+filename
    return, 'No'
  endif

  ; INITIALIZE

  arr      = strsplit(filename,'_',/extract)
  date     = arr[0]; date
  sc       = arr[1]; spacecraft
  datatype = arr[2]; datatype such as fgl, peir, etc.
  if n_elements(arr) ge 4 then begin
    prod_arr = strsplit(arr[3],'.',/extract)
    prod     = prod_arr[0]; data product, e.g. velocity, edc
  endif else begin
    prod   = ''
  endelse
  type     = datatype
  check    = strpos(datatype,'.')
  if check ge 0 then type = strmid(datatype,0,3)
  prbs     = eva_data_load_daily_prbarr(arr[1],0)
  probes   = eva_data_load_daily_prbarr(arr[1],1)
  pmax     = n_elements(prbs)
  tname    = strmid(filename,11,strlen(filename)-17)
  dir      = cache_data_dir
  timespan, str2time(date),1
  save_var = strarr(1)
  instr    = strmid(type,0,2)
  msn      = strmid(sc,0,2)





  verbose =1; set this 1 to show messages below
  dprint,dlevel=1,verbose = verbose,'Generating file : ', filename
  dprint,dlevel=1,verbose = verbose,'msn  = ',msn
  dprint,dlevel=1,verbose = verbose,'date = ',date
  dprint,dlevel=1,verbose = verbose,'type = ',type
  dprint,dlevel=1,verbose = verbose,'prod = ',prod
  dprint,dlevel=1,verbose = verbose,'prbs = ', prbs
  dprint,dlevel=1,verbose = verbose,'probes = ', probes
  dprint,dlevel=1,verbose = verbose,'tname = ', tname



  ; COORDINATE
  coord = 'gsm'; default (to be obtained from GUI) (code later)
  if strpos(tname,'gsm') ge 0 then coord = 'gsm'
  if strpos(tname,'gse') ge 0 then coord = 'gse'
  if strpos(tname,'dsl') ge 0 then coord = 'dsl'



  ; MAIN
  if eva_data_load_daily_check(tname,date) then begin; check if the tplot variable already exists

    ; LOAD CDF FILES
    matched = 0

    if strmatch(type,'fb') then begin
      thm_load_fbk,probe=prbs,level=2;,datatype=['fb_'+type]
      matched = 1
    endif

    if strmatch(type,'fg?') then begin
      thm_load_fgm,probe=prbs,level=2,coord=coord,datatype=type
      matched = 1
    endif

    ;    if strmatch(type,'Your_data_type') then begin
    ;      load_your_data
    ;      matched = 1
    ;    endif

    if strmatch(type,'pe?m') then begin
      thm_load_mom,probe=prbs,level=2,coord=coord; there is only one option for datatype (default)
      matched = 1
    endif else begin
      if strmatch(type,'pe??') then begin
        ;thm_load_esa,probe=prbs,level=2,coord=coord,datatype=type+'*'
        thm_load_esa,probe=prbs,level=2,coord=coord,datatype=[type+'_density',type+'_velocity_*',type+'_avgtemp']
        matched = 1
      endif
    endelse

    if strmatch(type,'ps??') then begin
      allzeros=[0,8,24,32,40,47,48,55,56]
      bins2mask=make_array(64,/int,value=1)
      bins2mask(allzeros)=0
      units = 'eflux'; 'df' or 'eflux'
      thm_part_getspec, probe=prbs,data_type=type,units=units, suffix='_et_omni',$
        /energy;, enoise_bins=bins2mask, enoise_remove_method='fill';,/sst_cal
      matched = 1
    endif

    if ~matched then begin
      msgtxt = filename + ' cannot be loaded.'
      result = dialog_message(msgtxt)
      return, 'No'
    endif

    save_var = [save_var, tname]

  endif else begin; if tname existed
    save_var = [save_var, tname]
  endelse

  ; SAVE
  if n_elements(save_var) gt 1 then begin
    rst = 1
    ;    if strmatch(filename,'*tdn*') then rst = 0
    ;    if strmatch(filename,'*cdq*') then rst = 0
    ;    if strmatch(filename,'*mdq*') then rst = 0
    ;    if strmatch(filename,'*fom*') then rst = 0



    ; tplot_save
    if rst then begin
      tpv = save_var[1:*]

      ; additional tplot_variable
      index = where(strmatch(tpv,'mms_stlm_output_fom'),c)
      if c eq 1 then begin
        tpv = [tpv,'mms_stlm_input_fom']
      endif

      yyyy  = strmid(date,0,4)
      mmdd  = strmid(date,5,5)
      svdir = dir+yyyy+'/'+mmdd+'/'
      fullname = svdir + strmid(filename,0,strlen(filename)-6)
      file_mkdir,svdir

      print, 'dir='+dir
      eva_tplot_save,file=fullname, tpv
    endif
    answer = 'Yes'
  endif else begin
    answer = 'No'
  endelse

  return, answer
END
