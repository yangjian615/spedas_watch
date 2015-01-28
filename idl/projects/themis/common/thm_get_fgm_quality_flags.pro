;+
;NAME:
; thm_get_fgm_quality_flags
;
;PURPOSE:
; returns an spd_qf_list object with quality flags
;
;CALLING SEQUENCE:
; fgm_qf = thm_get_fgm_quality_flags('tha',trange=trange) ;
;
;INPUT:
; probe = string, has to me a single probe 'tha' or thb' etc
;
;KEYWORDS:
; trange = time range
;
;OUTPUT:
; fgm_qf = quality flags for FGM
;
;EXAMPLES:
; qf = thm_get_fgm_quality_flags('tha')
;
;NOTES:
;FGM/SCM boom deploy:
;THEMIS_A: 2007/056 21:00
;THEMIS_B: 2007/056 10:20
;THEMIS_C: 2007/056 09:40
;THEMIS_D: 2007/058 00:05
;THEMIS_E: 2007/058 00:40
;
;EFI deploy completed:
;THEMIS_A: spin plane: 2008/012 21:43
;axial: 2008/014 16:30
;THEMIS_B: spin plane: 2007/321 18:43
;axial: 2007/322 06:05
;THEMIS_C: spin plane: 2007/134 22:25
;axial: 2007/136 20:40
;THEMIS_D: spin plane: 2007/156 22:50
;axial: 2007/158 17:40
;THEMIS_E: spin plane: 2007/156 23:55
;axial: 2007/158 18:45
;
;HISTORY:;
;$LastChangedBy: nikos $
;$LastChangedDate: 2015-01-23 09:57:59 -0800 (Fri, 23 Jan 2015) $
;$LastChangedRevision: 16713 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/common/thm_get_fgm_quality_flags.pro $
;-

function thm_get_fgm_quality_flags, probe, trange=trange

  if (probe eq 'tha') then begin
    t1 = time_double('2007/056 21:00', TFORMAT='YYYY/DOY hh:mm')
    t2 = time_double('2008/014 16:30', TFORMAT='YYYY/DOY hh:mm')
  endif else if (probe eq 'thb') then begin
    t1 = time_double('2007/056 21:00', TFORMAT='YYYY/DOY hh:mm')
    t2 = time_double('2007/322 06:05', TFORMAT='YYYY/DOY hh:mm')
  endif else if (probe eq 'thc') then begin
    t1 = time_double('2007/056 21:00', TFORMAT='YYYY/DOY hh:mm')
    t2 = time_double('2007/136 20:40', TFORMAT='YYYY/DOY hh:mm')
  endif else if (probe eq 'thd') then begin
    t1 = time_double('2007/058 21:00', TFORMAT='YYYY/DOY hh:mm')
    t2 = time_double('2007/158 17:40', TFORMAT='YYYY/DOY hh:mm')
  endif else if (probe eq 'the') then begin
    t1 = time_double('2007/058 21:00', TFORMAT='YYYY/DOY hh:mm')
    t2 = time_double('2007/158 18:45', TFORMAT='YYYY/DOY hh:mm')
  endif else begin
    t1 = time_double('2007/001 00:00', TFORMAT='YYYY/DOY hh:mm')
    t2 = time_double('2007/001 00:00', TFORMAT='YYYY/DOY hh:mm')
  endelse

  fgm_qf = obj_new('SPD_QF_LIST', t_start=[t1,t2], t_end=[t2,SYSTIME(1)], qf_bits=[1,0])
  if (keyword_set(trange) && (n_elements(trange) eq 2) && (trange[1] ge trange[0])) then begin
    if (trange[0] ge t2) then begin
      fgm_qf= obj_new('SPD_QF_LIST', t_start=[trange[0]], t_end=[trange[1]], qf_bits=[0])
    endif else if (trange[1] le t1) then begin
      fgm_qf= obj_new('SPD_QF_LIST', t_start=[trange[0]], t_end=[trange[1]], qf_bits=[0])
    endif else if (trange[0] lt t1) and (trange[1] gt t2) then begin
      fgm_qf= obj_new('SPD_QF_LIST', t_start=[trange[0],t1,t2], t_end=[t1,t2,trange[1]], qf_bits=[0,1,0])
    endif else if (trange[0] lt t1) and (trange[1] le t2) then begin
      fgm_qf= obj_new('SPD_QF_LIST', t_start=[trange[0],t1], t_end=[t1,trange[1]], qf_bits=[0,1])
    endif else if (trange[0] ge t1) and (trange[1] gt t2) then begin
      fgm_qf= obj_new('SPD_QF_LIST', t_start=[trange[0],t2], t_end=[t2,trange[1]], qf_bits=[1,0])
    endif else if (trange[0] ge t1) and (trange[1] le t2) then begin
      fgm_qf= obj_new('SPD_QF_LIST', t_start=[trange[0]], t_end=[trange[1]], qf_bits=[1])
    endif
  endif

  return, fgm_qf

end