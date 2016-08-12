;+
;Procedure:
;     mms_neutral_sheet_crib
;
;Purpose:
;     Example on how to load MMS position data and retrieve the 
;     distance from the S/C to the neutral sheet
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-08-11 13:30:56 -0700 (Thu, 11 Aug 2016) $
;$LastChangedRevision: 21633 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/advanced/mms_neutral_sheet_crib.pro $
;-

pro mms_neutral_sheet_crib

re=6378.

;------------------------------
; MMS Predicted Data Example
;------------------------------

; Get MMS Predicted position data using mms_load_state (for non predicted data use mms_load_mec)
mms_load_state, probe='1', trange=['2016-08-09','2016-08-26'], datatypes='pos' 
; convert j2000 (default mms position coord sys) to gsm
spd_cotrans,'mms1_predeph_pos','mms1_predeph_pos_gsm',out_coord='gsm' 

; extract the position data from the tplot variable
get_data, 'mms1_predeph_pos_gsm', data=mms1_predeph_pos_gsm, dlimits=dl, limits=1
; mms1_predeph_pos_gsm.x = time in sec
; mms1_predeph_pos_gei.y = x,y,z in km
help, mms1_predeph_pos_gsm

; plot the orbit in the xy and xz planes
plot, mms1_predeph_pos_gsm.y[*,0], mms1_predeph_pos_gsm.y[*,1], /iso
stop
plot, mms1_predeph_pos_gsm.y[*,0], mms1_predeph_pos_gsm.y[*,2], /iso
stop

; get neutral sheet z position in RE (see neutral_sheet header for parameter descriptions) 
neutral_sheet, mms1_predeph_pos_gsm.x, mms1_predeph_pos_gsm.y/re, model='lopez', distance2NS=z2NS

; plot results
days=(mms1_predeph_pos_gsm.x - mms1_predeph_pos_gsm.x[0])/86400.
title='MMS1 Predicted Position and Neutral Sheet (Lopez Model)'
subtitle='[Blue: MMS1_Predicted_Position, Red: Neutral Sheet]'
xtitle='Days since '+time_string(mms1_predeph_pos_gsm.x[0])
plot, days, mms1_predeph_pos_gsm.y[*,2]/re, xtitle=xtitle, ytitle='z-gsm [re]', title=title, yrange=[-5, 5], $
      subtitle=subtitle 
oplot, days, mms1_predeph_pos_gsm.y[*,2]/re, color=80
oplot, days, z2NS, color=250
stop

;---------------------------------------
; get Z displacement from the spacecraft 
;---------------------------------------
; Set sc2NS flag (spacecraft to neutral sheet)
neutral_sheet, mms1_predeph_pos_gsm.x, mms1_predeph_pos_gsm.y/re, model='lopez', distance2NS=sc2NS, /sc2NS

; plot results
subtitle='[Blue: MMS1_Predicted_Position, Red: Neutral Sheet, Green: dz2NS]'
plot, days, mms1_predeph_pos_gsm.y[*,2]/re, xtitle=xtitle, ytitle='z-gsm [re]', title=title, yrange=[-5, 5], $
  subtitle=subtitle
oplot, days, mms1_predeph_pos_gsm.y[*,2]/re, color=80
oplot, days, z2NS, color=250
oplot, days, sc2NS, color=150
stop

end