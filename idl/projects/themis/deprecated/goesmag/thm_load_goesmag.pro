;+
;Procedure: THM_LOAD_GOESMAG
;keywords:
;  probe = Probe name. The default is 'all', i.e., load all available probes.
;          This can be an array of strings, e.g., ['a', 'b'] or a
;          single string delimited by spaces, e.g., 'a b'
;  datatype = The type of data to be loaded, can be an array of strings
;          or single string separate by spaces.  The default is 'all'
;  TRANGE= (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded
;  level = the level of the data, the default is 'l1', or level-1
;          data. A string (e.g., 'l2') or an integer can be used. 'all'
;          can be passed in also, to get all levels.
;  CDF_DATA: named variable in which to return cdf data structure: only works
;          for a single spacecraft and datafile name.
;  VARNAMES: names of variables to load from cdf: default is all.
;  /GET_SUPPORT_DATA: load support_data variables as well as data variables
;                      into tplot variables.
;  /DOWNLOADONLY: download file but don't read it.
;  /NO_DOWNLOAD: set this option to use only locally available files
;  /valid_names, if set, then this routine will return the valid
;probe, datatype
;
;          and/or level options in named variables supplied as
;          arguments to the corresponding keywords.
;  files   named varible for output of pathnames of local files.
;  /VERBOSE  set to output some useful info
;  /relpathnames_all: the names of the files loaded will be returned
;in this named variable
;suffix: the name of the suffix to be added to returned tplot variables
;
;Example:
;   thm_load_goesmag,probe='g10'


pro thm_load_goesmag_post, sname=probe, datatype=dt, level=lvl, $
                       tplotnames=tplotnames, $
                       suffix=suffix, proc_type=proc_type, coord=coord, $
                       delete_support_data=delete_support_data, _extra=_extra

  compile_opt idl2, hidden
  
  ; add DLIMIT tags to data quantities
  for i=0, n_elements(tplotnames)-1 do begin
    tplot_var = tplotnames[i]
    get_data, tplot_var, data=d_str, limit=l_str, dlimit=dl_str
    if size(/type,dl_str) eq 8 && dl_str.cdf.vatt.var_type eq 'data' then begin

      thm_new_units, tplot_var
      thm_new_coords, tplot_var
    
      get_data, tplot_var, dlimits = dl_str

      str_element, dl_str, 'data_att', success=yes_data_att
      if ~yes_data_att then begin
        data_att = {units:'', coord_sys:'none'}
        str_element, dl_str, 'data_att', data_att, /add
      endif

      ; add 'none' to coord_sys if it doesn't exist
      str_element, dl_str.data_att, 'coord_sys', success=yes_coord
      if yes_coord then coord=dl_str.data_att.coord_sys

      case strmid(tplot_var, 4,2) of
        'b_': begin ; B field
          unit='nT'
          
          case strmid(tplot_var, 6, 3) of
            'enp': begin
              labels = [ 'E', 'N', 'P']
              colors = [2, 4, 6]
            end
            'gei' or 'gsm': begin
              labels = [ 'bx', 'by', 'bz']
              colors = [2, 4, 6]
            end
            'gsm': begin
              labels = [ 'bx', 'by', 'bz']
              colors = [2, 4, 6]
            end
            'tot': begin
              labels = '|B|'
              colors = 0
            end
          endcase
        end
        'da': begin ; data quality flags
          unit = 'none'
          labels = 'Data Quality'
          colors = 0
        end
        'lo': begin ; longitude
          unit='Deg'
          labels = 'Geographic west longitude at noon UTC'
          colors = 0
        end
        'ml': begin ; magnetic local time
          unit='Hours'
          labels = 'Magnetic local time at satellite position'
          colors = 0
        end
        'pe': begin ; perpendicular
          unit='unitvec' ; unit vector
          if keyword_set(coord) then labels = [ 'x_'+coord, 'y_'+coord, 'z_'+coord] $
            else labels = ['x', 'y', 'z'] 
          colors = [2, 4, 6]
        end
        'po': begin ; position
          unit='km'
          if keyword_set(coord) then labels = [ 'x_'+coord, 'y_'+coord, 'z_'+coord] $
            else labels = ['x', 'y', 'z'] 
          colors = [2, 4, 6]
        end
        't1': begin ; magnetotorquer filtered counts
          unit='Counts'
          ;labels = 'Filtered counts'
          colors = 0
        end
        't2': begin ; magnetotorquer filtered counts
          unit='Counts'
          ;labels = 'Filtered counts'
          colors = 0
        end
        've': begin ; velocity
          unit='km/s'
          if keyword_set(coord) then labels = [ 'vx_'+coord, 'vy_'+coord, 'vz_'+coord] $
            else labels = ['vx', 'vy', 'vz'] 
          colors = [2, 4, 6]
        end
        else: dprint, 'no matches for: ', tplot_var 
      endcase

      dprint, dlevel=4,'TPLOT_VAR: ', tplot_var

      if stregex(tplot_var,'^g1[0-2]_pos',/boolean) then begin
        str_element,dl_str,'data_att.st_type','pos',/add
      endif else if stregex(tplot_var,'^g1[0-2]_vel',/boolean) then begin
        str_element,dl_str,'data_att.st_type','vel',/add
      endif else begin
        str_element,dl_str,'data_att.st_type','none',/add
      endelse

      str_element, dl_str, 'data_att.units', unit, /add

      ;str_element, dl_str, 'data_att', data_att, /add
      str_element, dl_str, 'colors', colors, /add
      str_element, dl_str, 'labels', labels, /add
      str_element, dl_str, 'labflag', 1, /add
      str_element, dl_str, 'ytitle', tplot_var, /add
      str_element, dl_str, 'ysubtitle', '['+unit+']', /add
      store_data, tplot_var, data=d_str, limit=l_str, dlimit=dl_str
    endif
   
  endfor  

end

pro thm_load_goesmag,probe=probe, datatype=datatype, trange=trange, $
                 level=level, verbose=verbose, downloadonly=downloadonly, $
                 cdf_data=cdf_data,get_support_data=get_support_data,no_download=no_download, $
                 varnames=varnames, valid_names = valid_names, files=files,relpathnames_all=relpathnames_all,$
                 suffix=suffix

  ;thm_init
  goes_init
 
  thm_load_xxx,sname=probe, datatype=datatype, trange=trange, no_download=no_download,$
               level=level, verbose=verbose, downloadonly=downloadonly, $
               cdf_data=cdf_data,get_cdf_data=arg_present(cdf_data), $
               get_support_data=get_support_data, $
               varnames=varnames, valid_names = valid_names, files=files, $
               relpathnames_all=relpathnames_all,suffix=suffix,$
               vsnames = 'g10 g11 g12', $
               type_sname = 'probe', $
               vdatatypes = 'b_gsm b_gei b_enp b_total pos_gsm pos_gei vel_gei t1_counts t2_counts dataqual longitude mlt', $
               file_vdatatypes = 'mag', $
               vlevels = 'l2', $
               deflevel = 'l2', $
               version = 'v01', $
               relpath_funct = 'thm_load_goesmag_relpath', $
               post_process_proc='thm_load_goesmag_post', $
               alternate_load_params=!goes, $
               _extra = _extra; , varformat='*'



end
