;+
; NAME: spd_mms_load_bss
;
; PURPOSE: To display horizontal color bars indicating burst data availability
;
; KEYWORDS: 
; 
;   trange:          time frame for bss
;   datatype:        type of BSS data ['fast','burst','status','fom']. default includes 'fast' and 'burst'
;   include_labels:  set this flag to have the horizontal bars labeled
; 
; NOTES: 
;   "bss" stands for Burst Segment Status (a term used in the MMS-SDC2SITL-ICD document). 
;   By default, it produces the following tplot-variables.
;   
;   1. mms_bss_fast  (red bar) 
;      the time periods of fast-survey mode (more precisely, the time periods of ROIs)
;      
;   2. mms_bss_burst (blue bar) 
;      the time periods (segments) selected by SITLs for burst data
;      
;   3. mms_bss_status (green bar) 
;      Represents segment statuses. 
;
;   4. mms_bss_fom (histogram, black) 
;      The height represents the FOM values (i.e., priority level defined by SITLs)
;
;   See also "spd_load_bss_crib" and "mms_load_bss_crib" for examples.
;
;   5. To labels bss bars set the include_labels flag, /include_labels
;   
; CREATED BY: Mitsuo Oka   Oct 2015
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-04-12 09:17:43 -0700 (Tue, 12 Apr 2016) $
;$LastChangedRevision: 20779 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/data_status_bar/spd_mms_load_bss.pro $
;-

PRO spd_mms_load_bss, trange=trange, datatype=datatype, include_labels=include_labels
  compile_opt idl2

  if undefined(trange) then trange = timerange() else trange = timerange(trange)
  if undefined(datatype) then datatype = ['fast','burst']
  datatype = strlowcase(datatype)
  
  nmax = n_elements(datatype)
  for n=0,nmax-1 do begin
    case datatype[n] of
      'fast':   mms_load_bss_fast, trange=trange, include_labels=include_labels
      'burst':  spd_mms_load_bss_burst, trange=trange, include_labels=include_labels
      'status': mms_load_bss_status, trange=trange, include_labels=include_labels
      'fom':    mms_load_bss_fom, trange=trange
      else: message,'datatype: '+datatype[n]+' is not allowed.'
    endcase
  endfor

  burst_label = keyword_set(include_labels) ? 'Burst' : ''
  fast_label = keyword_set(include_labels) ? 'Fast' : ''
  status_label = keyword_set(include_labels) ? 'Status' : ''
  fom_label = keyword_set(include_labels) ? 'FoM' : ''
 
  panel_size = keyword_set(include_labels) ? 0.09 : 0.01
  
  ; set some options so the labels sizes are set properly
  options,'mms_bss_burst',thick=5,xstyle=4,ystyle=4,yrange=[-0.001,0.001],ytitle='',$
    ticklen=0,panel_size=panel_size,colors=2, labels=[burst_label], labsize=1, charsize=1.
  options,'mms_bss_fast',thick=5,xstyle=4,ystyle=4,yrange=[-0.001,0.001],ytitle='',$
    ticklen=0,panel_size=panel_size,colors=6, labels=[fast_label], labsize=1, charsize=1.
  options,'mms_bss_status',thick=5,xstyle=4,ystyle=4,yrange=[-0.001,0.001],ytitle='',$
    ticklen=0,panel_size=panel_size,colors=4, labels=[status_label], labsize=1, charsize=1.
  options,'mms_bss_fom',thick=5,xstyle=4,ystyle=4,yrange=[-0.001,0.001],ytitle='',$
    ticklen=0,panel_size=panel_size,colors=0, labels=[fom_label], labsize=1, charsize=1.
END
