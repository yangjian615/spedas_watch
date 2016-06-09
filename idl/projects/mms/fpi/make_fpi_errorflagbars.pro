;+
; PROCEDURE:
;         make_fpi_errorflagbars
;
; PURPOSE:
;         Make error flag bars
;
; KEYWORDS:
;         tname:   tplot variable name of dis or des errorflag 
;
; EXAMPLE:
;     MMS>  make_fpi_errorflagbars,'mms1_des_errorflags_fast'
;     MMS>  make_fpi_errorflagbars,'mms1_dis_errorflags_fast'
;     MMS>  make_fpi_errorflagbars,'mms1_des_errorflags_brst'
;     MMS>  make_fpi_errorflagbars,'mms1_dis_errorflags_brst'
;
; NOTE:
;     This is only for the error flag from d?s-moms files.
;     Note that the error flag from d?s-dist files have the same tplot variable name.
;     
;     Original by Naritoshi Kitamura
;     
;     June 2016: minor updates by egrimes
;     
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-06-08 15:13:49 -0700 (Wed, 08 Jun 2016) $
; $LastChangedRevision: 21287 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/fpi/make_fpi_errorflagbars.pro $
;-

PRO make_fpi_errorflagbars,tname

  if strmatch(tname,'mms?_dis*') eq 1 then inst='DIS' else if strmatch(tname,'mms?_des*') eq 1 then inst='DES' else return
  if strmatch(tname,'*_fast*') eq 1 then rate='Fast' else if strmatch(tname,'*_brst*') eq 1 then rate='Brst' else return
  get_data,tname,data=d
  
  ; check for valid data before continuing on
  if ~is_struct(d) then return
  
  flags=string(d.y,format='(b011)')
  flagline=fltarr(n_elements(d.x),11)
  for i=0,10 do begin
    for j=0l,n_elements(flags)-1l do begin
      if fix(strmid(flags[j],10-i,1)) eq 0 then flagline[j,i]=!values.f_nan else flagline[j,i]=1.0
    endfor
  endfor
  store_data,tname+'_flagbars',data={x:d.x,y:[[flagline[*,0]],[flagline[*,1]-0.1],[flagline[*,2]-0.2],[flagline[*,3]-0.3],[flagline[*,4]-0.4],[flagline[*,5]-0.5],[flagline[*,6]-0.6],[flagline[*,7]-0.7],[flagline[*,8]-0.8],[flagline[*,9]-0.9],[flagline[*,10]-1.0]]}
  ylim,tname+'_flagbars',-0.1,1.1,0
  options,tname+'_flagbars',colors=[0,6,5,3,2,1,5,0,2,4,6],labels=['bit 0','bit 1','bit 2','bit 3','bit 4','bit 5','bit 6','bit 7','bit 8','bit 9','bit 10'],ytitle=inst+'!C'+rate,thick=3,xstyle=4,ystyle=4,ticklen=0,labflag=-1,psym=-6,symsize=0.1,datagap=5.0
  store_data,tname+'_flagbars_mini',data={x:d.x,y:[[flagline[*,0]-0.1],[flagline[*,1]-0.3],[flagline[*,3]-0.5],[flagline[*,4]-0.7],[flagline[*,5]-0.9]]}
  ylim,tname+'_flagbars_mini',0.0,1.0,0
  options,tname+'_flagbars_mini',colors=[0,6,3,2,1],labels=['Manually flagged','Saturation','Missing s/c pot','Cold (>25%)','Hot (>25%)'],ytitle=inst+'!C'+rate,xstyle=4,ystyle=4,ticklen=0,thick=4,panel_size=0.5,labflag=-1,psym=-6,symsize=0.2,datagap=5.0
  
  ; kludge for the titles to show up on the y axes
  options, tname+'_flagbars', axis={yaxis: 0, ytitle: inst+'!C'+rate, yticks: 1, yminor: 1, ystyle: 0, yticklayout: 1, ytickv: [-1, 2]}
  options, tname+'_flagbars_mini', axis={yaxis: 0, ytitle: inst+'!C'+rate, yticks: 1, yminor: 1, ystyle: 0, yticklayout: 1, ytickv: [-1, 2]}

END