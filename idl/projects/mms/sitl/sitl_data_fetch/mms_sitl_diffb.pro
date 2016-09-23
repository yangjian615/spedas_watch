; Routine to get diffB index for display in EVA
; flag = 1 for failure if there are less than 2 spacecraft and calculating diffB is impossible.

; The no_load keyword will bypass calling mms_sitl_get_dfg, however, it assumes that the user
; ran the code for all four spacecraft outside of the routine, and all appropriate tplot variables are stored.

;  $LastChangedBy: rickwilder $
;  $LastChangedDate: 2016-09-22 09:26:48 -0700 (Thu, 22 Sep 2016) $
;  $LastChangedRevision: 21899 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/sitl_data_fetch/mms_sitl_diffb.pro $


pro mms_sitl_diffB, flag, no_load=no_load

flag = 0

mu0 = !pi*4e-7

times = timerange(/current)

if times(0) gt time_double('2016-09-15/00:00:00') then begin
  sep = 7d
endif else begin
  sep = 10d
endelse

; Load the data

if ~keyword_set(no_load) then begin
  mms_sitl_get_dfg, sc_id = ['mms1', 'mms2', 'mms3', 'mms4']
endif

; Define variable names
dataname = '_dfg_srvy_dmpa' ; NEED TO CHANGE THIS FOR SITL
dataname_gse = '_dfg_srvy_gse'


names = ['mms1', 'mms2', 'mms3', 'mms4'] + dataname

; Names for conversion to GSE coordinates
DEC = '_ql_RADec_gse'

decnames = ['mms1', 'mms2', 'mms3', 'mms4'] + DEC

namesgse = ['mms1', 'mms2', 'mms3', 'mms4'] + dataname_gse


; Check to see how many s/c have valid data
ivalid = intarr(4)

for i = 0, 3 do begin
  get_data, names[i], data = d
  get_data, decnames[i], data = d2
  
  if ~is_struct(d) or ~is_struct(d2) then begin
    ivalid[i] = 0
  endif else begin
    ivalid[i] = 1
  endelse
endfor

; Check to see if there are at least two spacecraft.
valloc = where(ivalid eq 1, countvalid)

if countvalid lt 2 then begin
  print, 'NEED AT LEAST TWO SPACECRAFT FOR DIFFB. RETURNING!'
  flag = 1
  return
endif

; How to scale the result if there are less than four s/c
scale = 4d/countvalid

; Get reference time array
get_data, names[min(valloc)], data = d

tref = d.x

; Now we create arrays for all four B-fields, regardless of whether they exist. Zero if they exist

; Load B1
if ivalid[0] eq 1 then begin
  split_vec, decnames[0]
  dsl2gse, names[0], decnames[0] + '_0', decnames[0] + '_1', namesgse[0], /ignore_dlimits
  get_data, namesgse[0], data = d
  
  b1x = d.y(*,0)
  b1y = d.y(*,1)
  b1z = d.y(*,2)
  
endif else begin
  b1x = replicate(0, n_elements(tref))
  b1y = replicate(0, n_elements(tref))
  b1z = replicate(0, n_elements(tref))
endelse

; Load B2
if ivalid[1] eq 1 then begin
  split_vec, decnames[1]
  dsl2gse, names[1], decnames[1] + '_0', decnames[1] + '_1', namesgse[1], /ignore_dlimits
  get_data, namesgse[1], data = d

  if min(valloc) eq 1 then begin
    b2x = d.y(*,0)
    b2y = d.y(*,1)
    b2z = d.y(*,2)
  endif else begin
    b2x = interpol(d.y(*,0), d.x, tref, /NAN)
    b2y = interpol(d.y(*,1), d.x, tref, /NAN)
    b2z = interpol(d.y(*,2), d.x, tref, /NAN)
  endelse

endif else begin
  b2x = replicate(0, n_elements(tref))
  b2y = replicate(0, n_elements(tref))
  b2z = replicate(0, n_elements(tref))
endelse

; Load B3
if ivalid[2] eq 1 then begin
  split_vec, decnames[2]
  dsl2gse, names[2], decnames[2] + '_0', decnames[2] + '_1', namesgse[2], /ignore_dlimits
  get_data, namesgse[2], data = d

  if min(valloc) eq 2 then begin
    b3x = d.y(*,0)
    b3y = d.y(*,1)
    b3z = d.y(*,2)
  endif else begin
    b3x = interpol(d.y(*,0), d.x, tref, /NAN)
    b3y = interpol(d.y(*,1), d.x, tref, /NAN)
    b3z = interpol(d.y(*,2), d.x, tref, /NAN)
  endelse

endif else begin
  b3x = replicate(0, n_elements(tref))
  b3y = replicate(0, n_elements(tref))
  b3z = replicate(0, n_elements(tref))
endelse

; Load B4
if ivalid[3] eq 1 then begin
  split_vec, decnames[3]
  dsl2gse, names[3], decnames[3] + '_0', decnames[3] + '_1', namesgse[3], /ignore_dlimits
  get_data, namesgse[3], data = d

  b4x = interpol(d.y(*,0), d.x, tref, /NAN)
  b4y = interpol(d.y(*,1), d.x, tref, /NAN)
  b4z = interpol(d.y(*,2), d.x, tref, /NAN)

endif else begin
  b4x = replicate(0, n_elements(tref))
  b4y = replicate(0, n_elements(tref))
  b4z = replicate(0, n_elements(tref))
endelse

store_data, [decnames + '_0', decnames + '_1'], /delete

; Now calculate diffB - multiply by zero if spacecraft doesn't exist for one of the values

dBx12 = ivalid[0]*ivalid[1]*(b1x - b2x)^2
dBx13 = ivalid[0]*ivalid[2]*(b1x - b3x)^2
dBx14 = ivalid[0]*ivalid[3]*(b1x - b4x)^2
dBx23 = ivalid[1]*ivalid[2]*(b2x - b3x)^2
dBx24 = ivalid[1]*ivalid[3]*(b2x - b4x)^2
dBx34 = ivalid[2]*ivalid[3]*(b3x - b4x)^2

dBy12 = ivalid[0]*ivalid[1]*(b1y - b2y)^2
dBy13 = ivalid[0]*ivalid[2]*(b1y - b3y)^2
dBy14 = ivalid[0]*ivalid[3]*(b1y - b4y)^2
dBy23 = ivalid[1]*ivalid[2]*(b2y - b3y)^2
dBy24 = ivalid[1]*ivalid[3]*(b2y - b4y)^2
dBy34 = ivalid[2]*ivalid[3]*(b3y - b4y)^2

dBz12 = ivalid[0]*ivalid[1]*(b1z - b2z)^2
dBz13 = ivalid[0]*ivalid[2]*(b1z - b3z)^2
dBz14 = ivalid[0]*ivalid[3]*(b1z - b4z)^2
dBz23 = ivalid[1]*ivalid[2]*(b2z - b3z)^2
dBz24 = ivalid[1]*ivalid[3]*(b2z - b4z)^2
dBz34 = ivalid[2]*ivalid[3]*(b3z - b4z)^2

diffB = scale*(dbx12 + dbx13 + dbx14 + dbx23 + dbx24 + dbx34 + $
  dby12 + dby13 + dby14 + dby23 + dby24 + dby34 + $
  dbz12 + dbz13 + dbz14 + dbz23 + dbz24 + dbz34)
  
diffB = sqrt(diffB)*1e-6/(2*sep*mu0)
  
store_data, 'mms_sitl_diffB', data = {x:tref, y:diffB}

options, 'mms_sitl_diffB', 'ytitle', 'diffB!cuA/m!U2!D'



end