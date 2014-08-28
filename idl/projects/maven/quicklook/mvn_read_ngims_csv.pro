;+
;NAME:
; mvn_read_ngims_csv
;PURPOSE:
; Reads an NGIMS csv file
;CALLING SEQUENCE:
; p = mvn_read_ngims_csv(filename)
;INPUT:
; filename = the input file name, full path.
;OUTPUT:
; p = a structure with tags corresponding to the columns in the file
; tplot_vars = an array of tplot var names, one for each column
; Currently:
;     TIME, MASS, SCRIPT, COUNTS_PER_SECOND, MODE, CS_FIL1_EMISSION,
;     CS_FIL2_EMISSION, OS_FIL1_EMISSION, OS_FIL2_EMISSION,
;     EM1_VOLTAGE, EM2_VOLTAGE
; The column names ar encodes in the file.
;HISTORY:
; 2014-07-28, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2014-07-28 14:23:51 -0700 (Mon, 28 Jul 2014) $
; $LastChangedRevision: 15620 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/quicklook/mvn_read_ngims_csv.pro $
;-
Function mvn_read_ngims_csv, filename, tplot_vars

  filex = file_search(filename)
  If(~is_string(filex)) Then Begin
     dprint, 'File: '+filename+' Not found.'
     Return, -1
  Endif

  p0 = read_csv(filex)
  If(~is_struct(p0)) Then Begin
     dprint, 'Bad File: '+filex
     Return, -1
  Endif

;Assume that the first column is 'TIME', and get the columns
;definitions
  xstart = where(strupcase(p0.field01) Eq 'TIME')
;Just build up the output structure using str_element
  tags0 = tag_names(p0)
  ntags = n_elements(tags0)
  varcount = 0
  For j = 0, ntags-1 Do Begin
     tagj = p0.(j)
     tj_name = strupcase(tagj[xstart])
     tj_val = tagj[xstart+1:*]
     If(tj_name Eq 'TIME') Then Begin
        tj_val = mvn_spc_met_to_unixtime(double(tj_val))
     Endif Else If(tj_name Ne 'SCRIPT' And tj_name Ne 'MODE') Then Begin
        tj_val = float(tj_val)
     Endif

     If(j Eq 0) Then Begin
        p = create_struct(tj_name, tj_val)
     Endif Else str_element, p, tj_name, tj_val, /add_replace

;create tplot variables here too
     If(j Eq 0) Then Begin
        time = tj_val
     Endif Else Begin
        tj_vname = 'mvn_ngims_'+strlowcase(tj_name[0])
        nj = n_elements(tj_val)
        If(tj_name Eq 'SCRIPT' Or tj_name Eq 'MODE') Then Begin
           ss = bsort(tj_val)
           x2 = tj_val[ss]
           ssu = uniq(x2)
           uvals = x2[ssu]
           all_flag = bytarr(nj)
           For k = 0, n_elements(uvals)-1 Do Begin
              one_flag = bytarr(nj)
              okk = where(tj_val Eq uvals[k])
              one_flag[okk] = 1b
              all_flag = all_flag+(2b^k)*one_flag
           Endfor
           store_data, tj_vname, data = {x:time, y:all_flag}
           options, tj_vname, 'tplot_routine', 'bitplot'
           options, tj_vname, 'labels', uvals
        Endif Else Begin
           store_data, tj_vname, data = {x:time, y:tj_val}
        Endelse
        If(varcount eq 0) Then tplot_vars = tj_vname $
        Else tplot_vars = [tplot_vars, tj_vname]
        varcount = varcount+1
     Endelse
  Endfor

  Return, p
End

        

