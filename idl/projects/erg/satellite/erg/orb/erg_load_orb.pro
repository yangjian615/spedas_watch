;+
; PRO  erg_load_orb
;
; :Description:
;    The data read script for ERG Definitive Orbit data. 
;
; :Params:
; 
; :Keywords:
;    LEVEL: 'l2': Level-2
;           'l3': Level-3
;           'l4': Level-4
;           Default is 'l2'.
;
; :Examples:
;    erg_load_orb ; load definitive orbit data.
;
; :History:
;    Prepared by Kunihiro Keika, ISEE, Nagoya University in July 2016
;    2016/02/01: first protetype
;    2017/02/20: Cut the part of loading predicted orb data in 'erg_load_orb.pro'
;                Pasted it to 'erg_load_orb_predict.pro'
;                by Mariko Teramoto, ISEE, Nagoya University
;
; :Author:
;   
;   Mariko Teramoto, ISEE, Naogya Univ. (teramoto at isee.nagoya-u.ac.jp)
;   Kuni Keika, Department of Earth and Planetary Science,
;     Graduate School of Science,The University of Tokyo (keika at eps.u-tokyo.ac.jp)
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2017-12-05 22:09:27 -0800 (Tue, 05 Dec 2017) $
; $LastChangedRevision: 24403 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/erg/satellite/erg/orb/erg_load_orb.pro $
;-
pro remove_duplicated_tframe, tvars 
  
  if n_params() ne 1 then return 
  tvars = tnames(tvars) 
  if strlen(tvars[0]) lt 1 then return 
  
  for i=0L, n_elements(tvars)-1 do begin
    tvar = tvars[i] 
    
    get_data, tvar, time, data, dl=dl, lim=lim 
    n = n_elements(time) 
    dt = [ time[1:(n-1)], time[n-1]+1 ] - time[0:(n-1)] 
    idx = where( abs(dt) gt 0d, n1 ) 
    
    if n ne n1 then begin
      newtime = time[idx] 
      if size(data,/n_dim) eq 1 then begin
        newdata = data[idx]
      endif else newdata = data[ idx, *] 
      store_data, tvar, data={x:newtime, y:newdata},dl=dl, lim=lim
    endif
    
    
  endfor
  
  
  
  return
end



pro erg_load_orb, $
  level=level, $
  datatype=datatype, $
  trange=trange, $
  coord=coord, $
  get_support_data=get_support_data, $
  downloadonly=downloadonly, $
  no_download=no_download, $
  verbose=verbose, $
  _extra=_extra 
  

  ;Initialize the system variable for ERG 
  ;erg_init 
  
  ;Arguments and keywords 
  if not keyword_set(level) then level='l2'
  if ~keyword_set(downloadonly) then downloadonly = 0
  if ~keyword_set(no_download) then no_download = 0 
  
     ;
     ; - - - FOR CONFIRMED ORBIT DATA - - - 
     ;Local and remote data file paths
     ;remotedir = !erg.remote_data_dir + 'satellite/erg/orb_pre/'
     ;remotedir = 'http://ergsc.isee.nagoya-u.ac.jp/data/ergsc/satellite/erg/orb_pre/' 
     remotedir = 'http://ergsc.isee.nagoya-u.ac.jp/data/ergsc/satellite/erg/orb/def/' 
     ;help, parse_url(remotedir) 
     ; 
     ;localdir =    !erg.local_data_dir      + 'satellite/erg/orb/' 
     localdir = root_data_dir() + 'ergsc/satellite/erg/orb/def/' 
     ;  
     ;Relative file path 
     relfpathfmt = 'YYYY/erg_orb_' + level + '_YYYYMMDD_v??.cdf'
     ;  
     ;Expand the wildcards for the designated time range 
     relfpaths = file_dailynames(file_format=relfpathfmt, trange=trange, times=times) 
     ;  
     ;Download data files 
     datfiles = $
       spd_download( remote_file = relfpaths, $
         remote_path = remotedir, local_path = localdir, /last_version, $
         no_download=no_download, no_update=no_download, _extra=_extra ) 
     ;  
     ;Read CDF files and generate tplot variables 
     prefix = 'erg_orb_'+level+'_' 
     if ~downloadonly then $
      cdf2tplot, file = datfiles, prefix = prefix, get_support_data = get_support_data, $
        verbose = verbose 
		
		tvar_pos = 'erg_orb_l2_pos_gsm'
        get_data, tvar_pos, data=data, dlim=dlim
        str_element, dlim, 'data_att.coord_sys', strmid(tvar_pos,2,3,/rev), /add 
		store_data, tvar_pos, data=data, dlim=dlim
     
    if  total(strlen(tnames('erg_orb_l2_*')) gt 1) eq 19 then begin
      remove_duplicated_tframe, tnames('erg_orb_l2_*') 
	
     ; - - - - OPTIONS FOR TPLOT VARIABLES - - - -
     options, prefix+'pos_'+['gse','gsm','sm'], 'labels', ['X','Y','Z']
     options, prefix+'pos_'+['gse','gsm','sm','rmlatmlt'], 'colors', [2,4,6]
     options, prefix+'pos_'+'rmlatmlt', 'labels', ['Re','MLAT','MLT']
     options, prefix+'pos_'+'eq', 'labels', ['Req','MLT']
     options, prefix+'pos_iono_'+['north','south'], 'labels', ['GLAT','GLON']
     options, prefix+'pos_blocal', 'labels', ['X','Y','Z']
	 options, prefix+'pos_blocal', 'colors', [2,4,6]
	 options, prefix+'pos_blocal_mag', 'labels', 'B(model)!C_at_ERG'
	 options, prefix+'pos_beq','labels', ['X','Y','Z']
	 options, prefix+'pos_beq', 'colors', [2,4,6]
     options, prefix+'pos_beq_mag', 'labels', 'B(model)!C_at_equator'
     options, prefix+'pos_b'+['local','eq']+'_mag', 'ylog', 1
	 options, prefix+'pos_'+'Lm', 'labels', ['90deg','60deg','30deg']
	 options, prefix+'pos_'+'Lm', 'colors', [2,4,6]
     options, prefix+'vel_'+['gse','gsm','sm'], 'labels', ['X[km/s]','Y[km/s]','Z[km/s]']
     options, prefix+'vel_'+['gse','gsm','sm'], 'colors', [2,4,6]
     
	 endif else print,'Orb L2 CDF file has not been created yet!'

  return
end


