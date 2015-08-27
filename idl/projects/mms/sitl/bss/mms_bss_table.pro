;+
; NAME: mms_bss_table
;
; PURPOSE: 
;   To create a table of segments in the back-structure
;   organized by categories.
;
; USAGE:
;   With no keyword, this program diplays a table of segments from the
;   entire mission. Use the keywords to select certain types of segments.
;
; KEYWORDS:
;   BSS: back-structure created by mms_bss_query
;   TRANGE: narrow the time range. It can be in either string or double.
;   OVERWRITTEN: Set this keyword to show overwritten segments only.
;   BAD:         Set this keyword to show bad segments only. Bad segments mean
;                segments with TRIMMED, SUBSUMED, DELETED statuses. Some of
;                the bad segments have infinite number of buffers. In such
;                cases, 'Nbuffs' and 'min' will be shown as *******.
;   _EXTRA: See 'mms_bss_query' for other optional keywords
;
; CREATED BY: Mitsuo Oka  Aug 2015
;
; $LastChangedBy: moka $
; $LastChangedDate: 2015-08-26 18:01:27 -0700 (Wed, 26 Aug 2015) $
; $LastChangedRevision: 18636 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/bss/mms_bss_table.pro $
;-
PRO mms_bss_table, bss=bss, trange=trange, bad=bad, overwritten=overwritten, $
  _extra=_extra
  compile_opt idl2
  
  mms_init

  ;----------------
  ; LOAD DATA
  ;----------------
  if n_elements(bss) eq 0 then begin
  
    if keyword_set(overwritten) then begin
      a = mms_bss_query(exclude='INCOMPLETE',_extra=_extra)
      bss = mms_bss_query(bss=a, status='DEMOTED DERELICT', _extra=_extra)
    endif
  
    if keyword_set(bad) then begin
      a = mms_bss_load(); load all segments including bad ones
      bss = mms_bss_query(bss=a, status='trimmed subsumed deleted obsolete')
    endif
  
    if n_tags(bss) eq 0 then begin
      bss = mms_bss_query(trange=trange,_extra=_extra)
    endif
  endif
  
  ;------------------
  ; COUNT BY CATEGORY
  ;------------------
  pmax = 6
  title = 'Category '+strtrim(string(sindgen(pmax)),2)
  title[pmax-1] = 'Total     '
  wNsegs = lindgen(pmax)
  wNbuffs = lindgen(pmax)
  wTmin = dindgen(pmax)
  wstrTlast = sindgen(pmax)
  for p=0,pmax-1 do begin
    b = mms_bss_query(bss=bss,cat=p)
    ct = (n_tags(b) eq 0) ? 0: n_elements(b.FOM)
    if ct eq 0 then begin
      wNsegs[p] = 0L
      wNbuffs[p] = 0L
      wTmin[p] = 0.d0
      wstrTlast[p] = ''
    endif else begin
      wNsegs[p] = ct; total number of segments
      wNbuffs[p] = total(b.SEGLENGTHS); total number of buffers
      wTmin[p] = double(wNbuffs[p])/6.d0; total number of minutes
      wstrTlast[p] = time_string(min(b.START))
    endelse
  endfor

  ;------------------
  ; OUTPUT
  ;------------------
  print,' As of '+time_string(systime(/utc,/seconds))+' UTC'
  print,' -------------------------------------------------------------------'
  print,'           ,   Nsegs,  Nbuffs,   [min],      %,  Oldest segment'
  print,' -------------------------------------------------------------------'
  for p=0,pmax-1 do begin
    ttlPrcnt = 100.*wTmin[p]/wTmin[pmax-1]
    print, title[p],wNsegs[p],wNbuffs[p],wTmin[p],ttlPrcnt,wstrTlast[p], format='(A11," ",I8," ",I8," ",I8," ",F7.1," ",A20)'
  endfor
END 