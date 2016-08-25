;+
; PROCEDURE:
;         mms_fpi_make_compressionlossbars
;
; PURPOSE:
;         Make compressionloss flag bars
;         
; KEYWORDS:
;         tname:   tplot variable name of dis or des compressionloss
;         lossy:   the value for lossy compression (use this keyword only for special case)
;
; EXAMPLES:
;     MMS>  mms_fpi_make_compressionlossbars,'mms1_des_compressionloss_fast'
;     MMS>  mms_fpi_make_compressionlossbars,'mms1_dis_compressionloss_fast'
;     MMS>  mms_fpi_make_compressionlossbars,'mms1_des_compressionloss_brst'
;     MMS>  mms_fpi_make_compressionlossbars,'mms1_dis_compressionloss_brst'
;
;   For DES/DIS distribution function (Brst and Fast):
;     bit 0 = manually flagged interval --> contact the FPI team for direction when utilizing this data; further correction is required
;     bit 1 = overcounting/saturation effects likely present in skymap
;      
;     Original by Naritoshi Kitamura
;     
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-08-24 08:54:55 -0700 (Wed, 24 Aug 2016) $
;$LastChangedRevision: 21707 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/fpi/mms_fpi_make_compressionlossbars.pro $
;-

PRO mms_fpi_make_compressionlossbars,tname,lossy=lossy

  if strmatch(tname,'mms?_dis*') eq 1 then inst='DIS' else if strmatch(tname,'mms?_des*') eq 1 then inst='DES' else return
  if inst eq 'DES' then col=6 else col=2
  if strmatch(tname,'*_fast*') eq 1 then rate='Fast' else if strmatch(tname,'*_brst*') eq 1 then rate='Brst' else return
  if rate eq 'Fast' then gap=5.d else if inst eq 'DIS' then gap=0.16d else gap=0.032d
  get_data,tname,data=d,dlimit=dl
  
  ; check for valid data before continuing on
  if ~is_struct(dl) then return
  if ~is_struct(d) then return else flags=d.y
  flagline=fltarr(n_elements(d.x))
  
  if rate eq 'Brst' then begin
    if undefined(lossy) then if fix(strmid(dl.cdf.gatt.data_version,0,1)) ne 0 then lossy=1 else lossy=3
    for j=0l,n_elements(d.x)-1l do if d.y[j] ne lossy then flagline[j]=!values.f_nan else flagline[j]=0.5
    store_data,tname+'_flagbars',data={x:d.x,y:flagline}
    ylim,tname+'_flagbars',0.0,1.0,0
    options,tname+'_flagbars',colors=col,labels=inst+' '+rate+'!C  Lossy',xstyle=4,ystyle=4,ticklen=0,thick=4,panel_size=0.2,labflag=-1,psym=-6,symsize=0.2,datagap=gap
  endif else begin
    for j=0l,n_elements(d.x)-1l do if flags eq 0 then flagline[j]=!values.f_nan else flagline[j]=0.5
    store_data,tname+'_flagbars',data={x:d.x,y:flagline}
    ylim,tname+'_flagbars',0.0,1.0,0
    options,tname+'_flagbars',colors=col,labels=inst+' '+rate+'!C  Lossy',xstyle=4,ystyle=4,ticklen=0,thick=4,panel_size=0.2,labflag=-1,psym=-6,symsize=0.2,datagap=gap
  endelse

END