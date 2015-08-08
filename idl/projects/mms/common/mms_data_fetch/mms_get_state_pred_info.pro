;+
; PROCEDURE:
;         mms_get_state_file_info
;
; PURPOSE:
;         Gets information (filenames, sizes) on ancillary files via the MMS web services API
;
; KEYWORDS:
;         filename: filename to get information on
;         sc_id: MMS spacecraft ID (mms1, mms2, etc)
;         product: ancillary product info ("defatt", etc)
;         start_date: starting date
;         end_date: end date
;
; OUTPUT:
;        returns information on the available files
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-06-19 16:07:09 -0700 (Fri, 19 Jun 2015) $
;$LastChangedRevision: 17926 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/mms_data_fetch/mms_get_ancillary_file_info.pro $
;-

function mms_get_state_pred_info, filename=filename, sc_id=sc_id, product=product, $
  start_date=start_date, end_date=end_date

  ; need yeardoy format for matching with MMS file names
  start_struc=time_struct(start_date)
  end_struc=time_struct(end_date)
  start_time=long(start_struc.year)*1000 + start_struc.doy
  end_time=long(end_struc.year)*1000 + end_struc.doy
  
  if ~undefined(sc_id) then sc_id = strlowcase(sc_id)
  if ~undefined(product) then product = strlowcase(product)

  if ~undefined(filename) then append_array, query_args, "file=" + strjoin(filename, ",")
  if ~undefined(sc_id) then append_array, query_args, "sc_id=" + strjoin(sc_id, ",")
  if ~undefined(product) then append_array, query_args, "product=" + strjoin(product, ",")

  ; join the query arguments with "&"
  if n_elements(query_args) lt 2 then query = '' $
  else query = strjoin(query_args, '&')

  file_data = get_mms_file_info('ancillary', query=query)

  file_data[0]=' '+file_data[0]
  file_start = long(strmid(strtrim(file_data),29,7))
  file_end = long(strmid(strtrim(file_data),37,7))
  ; remove files that are not in this start/end date timeframe
  idx = where(file_end GE start_time AND file_start LE end_time, ncnt)
  if ncnt EQ 0 then return, ''

  ; for the short term find the first file that spans the timerange
  ; eventually will want to handle large time spans that require multiple files
  for i = 0, n_elements(idx)-1 do begin
      if file_start[idx[i]] LE start_time AND file_end[idx[i]] GE end_time then begin
         new_idx = [idx[i],idx[i]+1]
         break
      endif
  endfor
  if undefined(new_idx) then begin
    new_idx=[idx,idx+1]
    new_idx=new_idx[sort(new_idx)]
  endif

  ;remove duplicates
;  didx=uniq(file_start[idx])

  return, file_data[new_idx]

end