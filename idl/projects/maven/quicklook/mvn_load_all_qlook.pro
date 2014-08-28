;+
;NAME:
; mvn_load_all_qlook
;PURPOSE:
; Loads all of the data needed to do ALL of the qlook plots, this is
; done to avoid multiple data loads in mvn_over shell, the individual
; plot routines can then be called with a /noload_data option.
;CALLING SEQUENCE:
; mvn_load_all_qlook, date = date, $
;      l0_input_file = l0_input_file, _extra=_extra
;INPUT:
; No explicit input, everthing is via keyword.
;OUTPUT:
; No explicit outputs, a bunch of tplot variables are created
;KEYWORDS:
; date = If set, a plot for the input date.
; l0_input_file = A filename for an input file, if this is set, the
;                 date and trange keywords are ignored.
;HISTORY:
; 16-jul-2013, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2014-05-12 10:50:00 -0700 (Mon, 12 May 2014) $
; $LastChangedRevision: 15100 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/quicklook/mvn_load_all_qlook.pro $
Pro mvn_load_all_qlook, date = date, l0_input_file = l0_input_file, $
                        device = device, _extra=_extra

;Hold load position for error handling
common mvn_load_all_qlook, load_position

catch, error_status
If(error_status Ne 0) Then Begin
  dprint, dlevel = 0, 'Got Error Message'
  help, /last_message, output = err_msg
  For ll = 0, n_elements(err_msg)-1 Do print, err_msg[ll]
  Case load_position Of
    'init':Begin
      print, 'Bad initialization: Exiting'
      Return
    End
    'lpw':Begin
      print, 'Skipped LPW Load: '+filex
      Goto, skip_lpw
    End
    'mag':Begin
      print, 'Skipped MAG Load: '+filex
      Goto, skip_mag
    End
    'sep':Begin
      print, 'Skipped SEP Load: '+filex
      Goto, skip_sep
    End
    'swe':Begin
      print, 'Skipped Swe Load: '+filex
      Goto, skip_swe
    End
    'swia':Begin
      print, 'Skipped Swia load: '+filex
      Goto, skip_swia
    End
    'sta':Begin
      print, 'Skipped STA Load: '+filex
      Goto, skip_sta
    End
    Else: Begin
      print, 'MVN_OVER_SHELL exiting with no clue'
    End
  Endcase
Endif

load_position = 'init'

mvn_qlook_init, device = device

;Load all of the data
If(keyword_set(l0_input_file)) Then Begin
   filex = l0_input_file[0]
Endif Else If(keyword_set(date)) Then Begin
   filex = mvn_l0_db2file(date)
Endif Else Begin
   message, /info, 'Need to set data or l0_input_file keyword'
Endelse

If(~is_string(filex)) Then message, 'No file found:'

load_position = 'lpw'
;LPW data
mvn_lpw_load, filex, filetype='L0', tplot_var='all'
mvn_lpw_ql_3panels
mvn_lpw_ql_instr_page

skip_lpw:

load_position = 'mag'

;MAG data
mdatafile = file_basename(filex)
minput_path = file_dirname(filex)
mdata_output_path = './'         ;still used, but may not be used later
mplot_save_path='.'              ;not used here
mvn_mag_ql, datafile=mdatafile, input_path=minput_path, $
            data_output_path=mdata_output_path, plot_save_path=mplot_save_path, $
            /tsmake, /mag1, /tplot, out_varname = out_varname, pkt_type = 'ccsds',$
            /delete_save_file
mvn_mag_ql, datafile=mdatafile, input_path=minput_path, $
            data_output_path=mdata_output_path, plot_save_path=mplot_save_path, $
            /tsmake, /mag2, /tplot, out_varname = out_varname, pkt_type = 'ccsds',$
            /delete_save_file

;If(is_struct(d)) Then Begin 
;drop bad time tags here, may not be necessary later, jmm, 2013-12-02
;    ok = where(d.x Gt time_double('2013'), nok)
;    If(nok Gt 0) Then Begin
;        xok = d.x[ok]
;        yok = d.y[ok, *]
;        db2 = sqrt(total(yok, 2))
;        y1 = fltarr(nok, 4)
;        y1[*,0:2] = yok
;        y1[*,3] = db2
;        d1 = {x:xok, y:y1}
;        dl1 = dl
;        str_element, dl1, 'colors', [2, 4, 6, 0], /add_replace
;        str_element, dl1, 'labels', ['x','y','z','T'], /add_replace
;Despike this data, if necessary
;        For k = 0, n_elements(d1.y[0,*])-1 Do Begin
;            d1yk = simple_despike_1d(d1.y[*, k], width = 10)
;            d1.y[*, k] = d1yk
;        Endfor
;        store_data, 'mvn_ql_magplustot', data=d1, dlimits=dl1
;    Endif
;Endif

skip_mag:

load_position = 'sep'
;SEP data
mvn_pfp_l0_file_read, file=filex, /sep 

skip_sep:

load_position = 'swe'
;SWE data, may need a time range
If(is_string(filex)) Then Begin
   p1  = strsplit(file_basename(filex), '_',/extract)
   date = p1[4]
   d0 = time_double(strmid(date,0,4)+'-'+strmid(date,4,2)+'-'+strmid(date,6,2))
   time_range = d0+[0.0, 86400.0]
Endif Else If(n_elements(date) Gt 0) Then Begin
   d0 = time_double(date[0])
   time_range = d0+[0.0, 86400.0]
Endif Else time_range = [0.0d0, 0.0d0]
mvn_swe_load_l0, time_range, filename = filex
mvn_swe_ql

skip_swe:
load_position = 'swia'
;SWI data
mvn_swia_load_l0_data, filex, /tplot, /sync
;Create an "energy spectrogram"
get_data, 'mvn_swis_en_counts', data=ddd
ddd1 = ddd
ddd1.y = ddd1.y*ddd1.v
ddd1.zrange = minmax(ddd1.zrange) & ddd1.zrange[0] = 10.0
ddd1.ztitle = 'SWIA!cEnergy'
store_data, 'mvn_swis_en_energy', data = ddd1

skip_swia:

load_position = 'sta'
;STA data
;I need a timespan here
p1  = strsplit(file_basename(filex), '_',/extract)
date = p1[4]
d0 = time_double(strmid(date,0,4)+'-'+strmid(date,4,2)+'-'+strmid(date,6,2))
timespan, d0, 1
mvn_sta_gen_ql, file = filex

skip_sta:

mvn_qlook_init, device = device


Return
End
