;+
;Procedure: goes_mag_overviews
;
;Purpose:
;   Makes overview plot of GOES magnetometer data.
;   Current version is not designed to work in Z device or run on cron.
;   For now it should just be run as the occasional batch job, as GOES data
;   is not downloaded automatically.
;  
;Inputs:
;  date: string date for which plots should be made.  Makes day long plots.
;  
;Keywords:
;  makepng: Set to generate png plots for the provided date.  Plots will be made
;           for 12x2 hr,4x6 hr, 1x24hr intervals
;  directory: Specify the directory for png output
;
;Notes:
;  1. Deletes all tplot variables stored in memory.
;  2. Probably crashes if you try to run on Z-device
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2014-02-28 14:10:44 -0800 (Fri, 28 Feb 2014) $
; $LastChangedRevision: 14467 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/deprecated/goesmag/goes_mag_overviews.pro $

;-

pro goes_mag_overviews,date,makepng=makepng,directory=directory

  compile_opt idl2
  
  del_data,'*'
  timespan,date
  
  if keyword_set(makepng) then begin
    window,xsize=750,ysize=800
    tplot_options,'charsize',1.3
    tplot_options,'xmargin',[12,7]
    tplot_options,'ymargin',[3,3]
  endif
  
  if ~keyword_set(directory) then begin
    directory = './'
  endif
  
  thm_load_goesmag
  
  ;9999.0 is a flag. This removes it so that data plots correctly
  get_data,'g10_b_enp',data=d,limit=l,dlimit=dl
  idx = where(d.y eq 9999.0,c)
  if c gt 0 then begin
    d.y[idx]=!VALUES.D_NAN
  endif
  store_data,'g10_b_enp_cln',data=d,limit=l,dlimit=dl
  
  get_data,'g11_b_enp',data=d,limit=l,dlimit=dl
  idx = where(d.y eq 9999.0,c)
  if c gt 0 then begin
    d.y[idx]=!VALUES.D_NAN
  endif
  store_data,'g11_b_enp_cln',data=d,limit=l,dlimit=dl
  
  get_data,'g12_b_enp',data=d,limit=l,dlimit=dl
  idx = where(d.y eq 9999.0,c)
  if c gt 0 then begin
    d.y[idx]=!VALUES.D_NAN
  endif
  store_data,'g12_b_enp_cln',data=d,limit=l,dlimit=dl
  
  start_time = date
  end_time = time_string(time_double(start_time)+60.*60.*24.)
  
  ;if data is missing create dummy data
  if ~tdexists('g10_b_enp_cln',start_time,end_time) then begin
    store_data,'g10_b_enp_cln',data={x:time_double([start_time,end_time]),y:[!VALUES.D_NAN,!VALUES.D_NAN]}  
  endif
  
  if ~tdexists('g11_b_enp_cln',start_time,end_time) then begin
    store_data,'g11_b_enp_cln',data={x:time_double([start_time,end_time]),y:[!VALUES.D_NAN,!VALUES.D_NAN]}  
  endif
  
  if ~tdexists('g12_b_enp_cln',start_time,end_time) then begin
    store_data,'g12_b_enp_cln',data={x:time_double([start_time,end_time]),y:[!VALUES.D_NAN,!VALUES.D_NAN]}  
  endif

  if ~tdexists('g10_mlt',start_time,end_time) then begin
    store_data,'g10_mlt',data={x:time_double([start_time,end_time]),y:[!VALUES.D_NAN,!VALUES.D_NAN]}  
  endif
  
  if ~tdexists('g11_mlt',start_time,end_time) then begin
    store_data,'g11_mlt',data={x:time_double([start_time,end_time]),y:[!VALUES.D_NAN,!VALUES.D_NAN]}  
  endif
  
  if ~tdexists('g12_mlt',start_time,end_time) then begin
    store_data,'g12_mlt',data={x:time_double([start_time,end_time]),y:[!VALUES.D_NAN,!VALUES.D_NAN]}  
  endif
  
  tplot,['g10_b_enp_cln','g11_b_enp_cln','g12_b_enp_cln'],var_label=['g12_mlt','g11_mlt','g10_mlt'],title='GOES Magnetometer Data'

  if keyword_set(makepng) then begin
  
    ts = time_struct(start_time)
    file_stem = directory + '/goes_mag_'+num_to_str_pad(ts.year,4)+num_to_str_pad(ts.month,2)+num_to_str_pad(ts.date,2)+'_'
    
    tplot
    makepng,file_stem+'0024'
    
    td = time_double(start_time) ;simply for convienience
    
    for i = 0,3 do begin
      tlimit,td+i*6.*60.*60.,td+(i+1)*6.*60.*60.
      makepng,file_stem+num_to_str_pad(i*6,2)+num_to_str_pad((i+1)*6,2) 
    endfor  
    
    for i = 0,11 do begin
      tlimit,td+i*2.*60.*60.,td+(i+1)*2.*60.*60.
      makepng,file_stem+num_to_str_pad(i*2,2)+num_to_str_pad((i+1)*2,2) 
    endfor  
      
  endif
end