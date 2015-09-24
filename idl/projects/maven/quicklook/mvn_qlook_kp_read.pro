;+
;NAME:
; mvn_qlook_kp_read
;PURPOSE:
; Reads a MAVEN KP text file,returns an array of values
;CALLING SEQUENCE:
; otp_array = mvn_qlook_kp_read(filename, time_array, column_ids, $
;             tplot = tplot, tvars = tvars)
;INPUT:
; filename = the input filename
;OUTPUT:
; otp_array =  an array of data pointers
; time_array = a time array for the values
; col_quantity = the quantity in the appropriate column
; col_source = the source instrument
; col_units = units
; col_fmt = the format code of the original quantity
; header = a string array of the header lines
;KEYWORDS:
; tplot = if set, create tplot variables
; tvars = a list of tplot variable names
;HISTORY:
; 18-sep-2015, jmm, jimm@ssl.berkeley.edu
;$LastChangedBy: jimm $
;$LastChangedDate: 2015-09-23 13:58:35 -0700 (Wed, 23 Sep 2015) $
;$LastChangedRevision: 18897 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/quicklook/mvn_qlook_kp_read.pro $
;-
Function mvn_qlook_kp_read, filename, time_array, col_quantity, col_source, $
                            col_units, col_fmt, col_ids_arr = col_ids_arr, $
                            tplot = tplot, tvars = tvars, $
                            _extra = _extra

  mvn_qlook_init

;Initialize output
  otp = -1
  time_array = -1
  column_ids = -1
  tvars = ''

;Get file
  filex = file_search(filename)
  If(~is_string(filex)) Then Begin
     dprint, 'File not found: '+filename
     Return, otp
  Endif

;Read the file
  ll = file_lines(filex)
  all_lines = strarr(ll)
  openr, unit, filex, /get_lun
  readf, unit, all_lines
  ss_h = where(strmid(all_lines, 0, 1) Eq '#', nssh)
  header = all_lines(ss_h)

;Search in the header for the number of columns, rows and the format
  ncol = -1 & nrow = -1 & fmt = -1
  For j = 0L, nssh-1 Do Begin
     pc = strpos(header[j], 'Number of parameter columns')
     If(pc[0] Ne -1) Then Begin
        temp = strsplit(header[j], ' ', /extract)
        ncol = long(temp[1])
     Endif
     pr = strpos(header[j], 'Number of lines (rows)')
     If(pr[0] Ne -1) Then Begin
        temp = strsplit(header[j], ' ', /extract)
        nrow = long(temp[1])
     Endif
     pf =  strpos(header[j], 'Format codes (IDL/Fortran)')
     If(pf[0] Ne -1) Then Begin
        temp = strsplit(header[j+1], ' ', /extract)
        fmt = strjoin(temp[1:*])
     Endif
  Endfor

  If(ncol Eq -1) Then Begin
     dprint, 'Bad column number'
     Return, otp
  Endif
  If(nrow Eq -1) Then Begin
     dprint, 'Bad row number'
     Return, otp
  Endif
  If(~is_string(fmt)) Then Begin
     dprint, 'Bad format'
     Return, otp
  Endif

;temp1 is used to find where the column descriptions start
  temp1 = ['#', strcompress(indgen(ncol)+1, /remove_all)]
  pt = -1
  For j = nssh-1, 0L, -1 Do Begin
     temp = strsplit(header[j], ' ', /extract)
     If(array_equal(temp1, temp)) Then Begin
        pt = j
        break
     Endif
  Endfor

  If(pt Eq -1) Then Begin
     dprint, 'Bad column line'
  Endif

;Extract column ids:
  hdr2col = header[pt:*]
  nrow_col_ids = n_elements(hdr2col)
  col_ids_arr = strarr(ncol, nrow_col_ids)
  For j = 0, nrow_col_ids-1 Do Begin
     temp = hdr2col[j]
     For k = 0, ncol-1 Do col_ids_arr[k, j] = strmid(temp, 3+16*k, 16)
  Endfor
  col_quantity = strarr(ncol)
  For k = 0, ncol-1 Do Begin
     temp = reform(strtrim(col_ids_arr[k, *], 2))
     col_quantity[k] = strjoin(temp[1:3], ' ')
  Endfor
  col_source = reform(strcompress(col_ids_arr[*, 4], /remove_all))
  col_units = reform(strtrim(col_ids_arr[*, 5], 2))
  col_fmt = reform(strtrim(col_ids_arr[*, 6], 2))
;For the time variable
  col_fmt[0] = 'A19'

;Oh, how about the data?
  data = temporary(all_lines)   ;maybe this'll help with memory
  data = data[nssh:*]
  ndata = n_elements(data)
  data_arr = strarr(ncol, ndata)
  For j = 0L, ndata-1 Do Begin
     temp = strsplit(data[j], ' ', /extract)
     data_arr[*, j] = temp
  Endfor

;Output is an array of pointers
  time_array = time_double(reform(data_arr[0, *]))
  otp = ptrarr(ncol)
  For k = 0, ncol-1 Do Begin ;keep string values for strings, use format for others
     x = strupcase(strcompress(col_fmt[k], /remove_all))
     x = strmid(x, 0, 1)
     If(x Eq 'E' Or x Eq 'F') Then Begin
        temp = reform(float(data_arr[k, *]))
        otp[k] = ptr_new(temp)
     Endif Else If(x Eq 'I') Then Begin
        temp = reform(long(data_arr[k, *]))
        otp[k] = ptr_new(temp)
     Endif Else Begin
        temp = reform(data_arr[k, *])
        otp[k] = ptr_new(temp)
     Endelse
  Endfor

;there's a typo
  If(col_quantity[205] Eq 'APP Attitude GEO X') Then Begin
     col_quantity[205] = 'APP Attitude GEO Z'
     col_ids_arr[205, 3] = 'GEO Z'
  Endif

  If(keyword_set(tplot)) Then Begin ;create tplot variables for each quantity
     tplot_name0 = col_source+strcompress(col_quantity, /remove_all)
;Swap 'XQuality' for 'QualityX', Y and Z, this will help, to combine
;variables, now if something ends in 'X', 'Y', 'Z' then this is a
;component that can be combined
     tplot_name0 = ssw_str_replace(tplot_name0, 'XQuality', 'QualityX')
     tplot_name0 = ssw_str_replace(tplot_name0, 'YQuality', 'QualityY')
     tplot_name0 = ssw_str_replace(tplot_name0, 'ZQuality', 'QualityZ')
;Ok, now is this an X, or start of a rotation matrix?
     xvar = bytarr(ncol)
     mtvar = bytarr(ncol)
     For j = 1, ncol-1 Do Begin ;the first column is time
        tplot_namej = tplot_name0[j]
        lastchar = strmid(tplot_namej, strlen(tplot_namej)-1)
        If(lastchar Eq 'X') then xvar[j] = 1
        last9chars = strmid(tplot_namej, strlen(tplot_namej)-9)
        If(last9chars Eq 'Row1,Col1') Then mtvar[j] = 1
     Endfor
;Keep track of variables that have been used:
     used = bytarr(ncol)        ;will need this to make x,y,z, variables
     tvars = ''
     For j = 1, ncol-1 Do Begin
        tplot_namej = tplot_name0[j]
        If(used[j] Eq 0) Then Begin
           If(~xvar[j] && ~mtvar[j]) Then Begin ;just a variable
              tvars = [tvars, tplot_namej]
              store_data, tplot_namej, data = {x:time_array, y:*otp[j]}
              used[j] = 1
           Endif Else If(xvar[j]) Then Begin
;Strip the last character from the name, find the Y and Z components
              tpl0 = strmid(tplot_namej, 0, strlen(tplot_namej)-1)
              ss_yvar = where(tplot_name0 Eq tpl0+'Y', yes_yvar)
              ss_zvar = where(tplot_name0 Eq tpl0+'Z', yes_zvar)
              If(yes_yvar Gt 0 And yes_zvar Gt 0) Then Begin
                 y = replicate((*otp[j])[0], n_elements(time_array), 3)
                 y[*, 0] = *otp[j]
                 y[*, 1] = *otp[ss_yvar[0]]
                 y[*, 2] = *otp[ss_zvar[0]]
                 used[j] = 1
                 used[ss_yvar[0]] = 1
                 used[ss_zvar[0]] = 1
                 tvars = [tvars, tpl0]
                 store_data, tpl0, data = {x:time_array, y:y}
                 options, tpl0, colors = [2, 4, 6], $
                          labels = ['X', 'Y', 'Z'], labflag = 1
              Endif Else Begin  ;shouldn't happen
                 dprint, 'Missing Y or Z for:'+tplot_namej
                 tvars = [tvars, tplot_namej]
                 store_data, tplot_namej, data = {x:time_array, y:*otp[j]}
                 used[j] = 1
              Endelse
           Endif Else If(mtvar[j]) Then Begin
;Strip the last 9 characters from the name, find the other 8 components
              tpl0 = strmid(tplot_namej, 0, strlen(tplot_namej)-9)
              ss_var = bytarr(3, 3)
              For k = 0, 2 Do For l = 0, 2 Do Begin
                 kl_test = tpl0+'Row'+strcompress(k+1, /remove_all)+$
                           ',Col'+strcompress(l+1, /remove_all)
                 ss_var[k, l] = where(tplot_name0 Eq kl_test)
              Endfor
              ok = where(ss_var Ne -1, nok)
              If(nok Eq 9) Then Begin
                 y = replicate((*otp[j])[0], n_elements(time_array), 3, 3)
                 For k = 0, 2 Do For l = 0, 2 Do Begin
                    y[*, l, k] = *otp[ss_var[k, l]] ;note transpose for columns
                    used[ss_var[k, l]] = 1
                 Endfor
                 used[j] = 1    ;redundant
                 tvars = [tvars, tpl0]
                 store_data, tpl0, data = {x:time_array, y:y}
              Endif Else Begin
                 dprint, 'Missing Col or Row for:'+tplot_namej
                 tvars = [tvars, tplot_namej]
                 store_data, tplot_namej, data = {x:time_array, y:*otp[j]}
                 used[j] = 1
              Endelse
           Endif
        Endif; Else message, /info, tplot_namej+'already used'
     Endfor
  Endif

  Return, otp
End
