
start_time_unix = str2time('2009-02-06')
stop_time_unix = str2time('2009-02-07')
mms_get_back_structure, start_time_unix, stop_time_unix, backstr, pw_flag, pw_message

stop
unix_backstr = backstr
str_element,/add,unix_backstr,'START', mms_tai2unix(backstr.START)
str_element,/add,unix_backstr,'STOP',  mms_tai2unix(backstr.STOP)
stop


;****************************************************************

tshift = str2time('2009-02-06 12:00')-str2time('1980-04-01')


sav_file = '/Users/moka/IDLWorkspace82/back_structure_data.sav'

restore, sav_file, /verbose
mms_convert_fom_tai2unix, backstr, unix_backstr, start_string

stop

str_element,/add,unix_backstr,'cyclestart', unix_backstr.CYCLESTART + tshift
str_element,/add,unix_backstr,'timestamps', unix_backstr.TIMESTAMPS + tshift

mms_convert_fom_unix2tai, unix_backstr, backstr

shifted_file = '/Users/moka/IDLWorkspace82/back_structure_data_shifted.sav'
save,backstr, filename=shifted_file

stop;*************************************

restore, shifted_file, /verbose
mms_convert_fom_tai2unix, backstr, unix_backstr, start_string

Nseg = n_elements(unix_backstr.FOM)

fom = fltarr(n_elements(unix_backstr.TIMESTAMPS))

for i=0,Nseg-1 do begin; for each segment
  fom[unix_backstr.start[i]:unix_backstr.stop[i]] = unix_backstr.FOM[i]
endfor

; Make a tplot-variable from FOM
store_data, 'mms_soca_fom',data={x:unix_backstr.timestamps, y:fom}
options,    'mms_soca_fom','ytitle', 'FOM'
options,    'mms_soca_fom','ysubtitle', '(ABS)'
options,    'mms_soca_fom','psym', 10

stop

end