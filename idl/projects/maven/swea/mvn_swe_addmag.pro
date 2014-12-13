;+
;PROCEDURE:   mvn_swe_addmag
;PURPOSE:
;  Loads MAG data from one of two sources:
;
;      (1) MAG quicklook sts files provided by the MAG team.  These are converted
;          into IDL save files -- this routine restores the save files.  These
;          data include corrections for nominal offsets.  MAG1 data only.  Typically
;          available one day after the L0 data arrive.
;
;      (2) Davin's decommutator.  These are loaded directly from the L0 data.
;          Both MAG1 and MAG2 data are provided.  Nominal calibration applied but
;          do not assume that it is correct.
;
;  Once loaded, the data are smoothed to the 1-sec SWEA MAG sampling resolution and
;  stored in a common block for quick access by mvn_swe_getpad and mvn_swe_get3d.
;
;USAGE:
;  mvn_swe_addmag, level
;
;INPUTS:
;       level:     Data level and resolution.  Default = 'L1_1SEC'.
;
;KEYWORDS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2014-12-11 16:24:16 -0800 (Thu, 11 Dec 2014) $
; $LastChangedRevision: 16470 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_addmag.pro $
;
;CREATED BY:    David L. Mitchell  03/18/14
;-
pro mvn_swe_addmag, level

  @mvn_swe_com
  
  domag1 = 0
  domag2 = 0
  
  if (size(level,/type) ne 7) then level = 'L1_1SEC' else level = strupcase(level)

  lvl = strmid(level,0,2)
  case lvl of
    'L1' : ; do nothing
    'L2' : ; do nothing
    else : begin
             print,"Unknown MAG data level: ",lvl
             return
           end
  endcase
  
  res = strmid(level,3,5)
  case res of
    '1SEC'  : ; do nothing
    '30SEC' : ; do nothing
    'FULL'  : ; do nothing
    else    : begin
                print,"Unknown MAG resolution: ",res
                return
              end
  endcase

  tname = 'mvn_B_' + strlowcase(res)

; Try to load data from sts save file(s)

  if (size(mvn_swe_engy,/type) ne 8) then begin
    print,"You must load SWEA data first."
    return
  endif

  tmin = min(mvn_swe_engy.time, max=tmax)
  
  mvn_mag_load, level, trange=[tmin,tmax]
  get_data,tname,data=mag1,index=i
  if (i gt 0) then indx = where(finite(mag1.y), count) else count = 0L
  
  if (count gt 0L) then begin
    t1 = mag1.x
    B1x = mag1.y[*,0]
    B1y = mag1.y[*,1]
    B1z = mag1.y[*,2]
    mag1 = 0
    domag1 = 1
    pl = 1
  endif else pl = 0

; If necessary, extract the data directly from L0

  if (~domag1 and (getenv('USER') eq 'mitchell')) then begin
    file = mvn_pfp_file_retrieve(trange=[tmin,tmax],/l0)
    nfiles = n_elements(file)

    finfo = file_info(file)
    indx = where(finfo.exists, nfiles, comp=jndx, ncomp=n)
    for j=0,(n-1) do print,"File not found: ",file[jndx[j]]  
    if (nfiles eq 0) then return
    file = file[indx]

    t1 = [0D]
    B1x = [0.]
    B1y = [0.]
    B1z = [0.]

    t2 = [0D]
    B2x = [0.]
    B2y = [0.]
    B2z = [0.]

    for i=0,(nfiles-1) do begin
      domag1 = 1
      domag2 = 1  ; MAG2 comes for free

      mvn_pfp_l0_file_read, file=file, /mag

      get_data,'mvn_mag1_svy_BAVG',data=mag1
    
      t1 = [temporary(t1), mag1.x]
      B1x = [temporary(B1x), mag1.y[*,0]]
      B1y = [temporary(B1y), mag1.y[*,1]]
      B1z = [temporary(B1z), mag1.y[*,2]]
      mag1 = 0

      get_data,'mvn_mag2_svy_BAVG',data=mag2
    
      t2 = [temporary(t2), mag2.x]
      B2x = [temporary(B2x), mag2.y[*,0]]
      B2y = [temporary(B2y), mag2.y[*,1]]
      B2z = [temporary(B2z), mag2.y[*,2]]
      mag2 = 0

    endfor
  endif
  
  if (~domag1) then begin
    print,"No MAG data found."
    return
  endif

; Trim data to requested time range
  
  if (domag1) then begin
    indx = where((t1 ge tmin) and (t1 le tmax), count)
    if (count gt 0L) then begin
      mag1 = {x:dblarr(count), y:fltarr(count,3)}
      mag1.x = temporary(t1[indx])
      mag1.y[*,0] = temporary(B1x[indx])
      mag1.y[*,1] = temporary(B1y[indx])
      mag1.y[*,2] = temporary(B1z[indx])
    endif else begin
      mag1 = 0
      domag1 = 0
    endelse
  endif

  if (domag2) then begin
    indx = where((t2 ge tmin) and (t2 le tmax), count)
    if (count gt 0L) then begin
      mag2 = {x:dblarr(count), y:fltarr(count,3)}
      mag2.x = temporary(t2[indx])
      mag2.y[*,0] = temporary(B2x[indx])
      mag2.y[*,1] = temporary(B2y[indx])
      mag2.y[*,2] = temporary(B2z[indx])
    endif else begin
      mag2 = 0
      domag2 = 0
    endelse
  endif

; Rotate to SWEA coordinates (without SPICE)

  if (domag1) then begin
    indx = where((mag1.x gt t_mtx[0]) and (mag1.x lt t_mtx[2]), nstow, $
                 complement=jndx, ncomplement=ndeploy)

    if (nstow gt 0L) then begin
      print,"Using stowed boom rotation matrix for MAG1"
      mag1.y[indx,*] = rotate_mag_to_swe(mag1.y[indx,*], magu=1, /stow, payload=pl)
    endif
    if (ndeploy gt 0L) then begin
      print,"Using deployed boom rotation matrix for MAG1"
      mag1.y[jndx,*] = rotate_mag_to_swe(mag1.y[jndx,*], magu=1, payload=pl)
    endif
  endif
  if (domag2) then begin
    indx = where((mag2.x gt t_mtx[0]) and (mag2.x lt t_mtx[2]), nstow, $
                 complement=jndx, ncomplement=ndeploy)

    if (nstow gt 0L) then begin
      print,"Using stowed boom rotation matrix for MAG2"
      mag2.y[indx,*] = rotate_mag_to_swe(mag2.y[indx,*], magu=2, /stow, payload=pl)
    endif
    if (ndeploy gt 0L) then begin
      print,"Using deployed boom rotation matrix for MAG2"
      mag2.y[jndx,*] = rotate_mag_to_swe(mag2.y[jndx,*], magu=2, payload=pl)
    endif
  endif

; Smooth the mag vectors to SWEA MAG sampling resolution (1 sec)

  if (domag1) then begin
    dt = median(mag1.x - shift(mag1.x,1))
    if (dt lt 0.5D) then mag1.y = smooth_in_time(mag1.y, mag1.x, 1D, /double)
  endif

  if (domag2) then begin
    dt = median(mag2.x - shift(mag2.x,1))
    if (dt lt 0.5D) then mag2.y = smooth_in_time(mag2.y, mag2.x, 1D, /double)
  endif

; Store the results in TPLOT and the SWEA common block

  if (size(swe_mag_struct,/type) ne 8) then mvn_swe_struct

  if (domag1) then begin
    store_data,'mvn_ql_mag1',data=mag1
    
    swe_mag1 = replicate(swe_mag_struct, n_elements(mag1.x))
    swe_mag1.time = mag1.x
    swe_mag1.magf = transpose(mag1.y)

    swe_mag1.Bamp = sqrt(total(mag1.y * mag1.y, 2))
    swe_mag1.Bphi = atan(mag1.y[*,1], mag1.y[*,0])
    indx = where(swe_mag1.Bphi lt 0., count)
    if (count gt 0L) then swe_mag1[indx].Bphi = swe_mag1[indx].Bphi + (2.*!pi)
    swe_mag1.Bthe = asin(mag1.y[*,2]/swe_mag1.Bamp)

    swe_mag1.level = 0B
    swe_mag1.valid = 1B
  endif else swe_mag1 = 0

  if (domag2) then begin
    store_data,'mvn_ql_mag2',data=mag2
    
    swe_mag2 = replicate(swe_mag_struct, n_elements(mag2.x))
    swe_mag2.time = mag2.x
    swe_mag2.magf = transpose(mag2.y)

    swe_mag2.Bamp = sqrt(total(mag2.y * mag2.y, 2))
    swe_mag2.Bphi = atan(mag2.y[*,1], mag2.y[*,0])
    indx = where(swe_mag2.Bphi lt 0., count)
    if (count gt 0L) then swe_mag2[indx].Bphi = swe_mag2[indx].Bphi + (2.*!pi)
    swe_mag2.Bthe = asin(mag2.y[*,2]/swe_mag2.Bamp)

    swe_mag2.level = 0B
    swe_mag2.valid = 1B
  endif else swe_mag2 = 0

; Store results and comparisons in TPLOT variables
  
  if (domag1) then begin
  
    store_data,'Bphi1',data={x:swe_mag1.time, y:swe_mag1.Bphi*!radeg}
    store_data,'Bthe1',data={x:swe_mag1.time, y:swe_mag1.Bthe*!radeg}
    store_data,'Bamp1',data={x:swe_mag1.time, y:swe_mag1.Bamp}

    ylim,'Bphi1',0,360,0
    options,'Bphi1','yticks',4
    options,'Bphi1','yminor',3
    options,'Bphi1','psym',3

    ylim,'Bthe1',-90,90,0
    options,'Bthe1','yticks',2
    options,'Bthe1','yminor',3
    options,'Bthe1','psym',3

    ylim,'Bamp1',0,0,1

; Compare MAG1 angles with SWEA PAD angles

    get_data,'swe_mag_svy',data=foo
  
    if (size(foo,/type) eq 8) then begin
      store_data,'Sphi',data={x:foo.x, y:foo.y[*,0]}
      store_data,'Sthe',data={x:foo.x, y:foo.y[*,1]-90.}
      store_data,'PAD_Phi',data=['Bphi1','Sphi']
      store_data,'PAD_The',data=['Bthe1','Sthe']
      ylim,'PAD_Phi',0,360,0
      options,'PAD_Phi','ytitle','PAD Phi'
      options,'PAD_Phi','yticks',4
      options,'PAD_Phi','yminor',3
      ylim,'PAD_The',-90,90,0
      options,'PAD_The','ytitle','PAD The'
      options,'PAD_The','yticks',2
      options,'PAD_The','yminor',3
      options,'Sphi','color',2
      options,'Sthe','color',2
      options,'Sphi','psym',3
      options,'Sthe','psym',3
    endif

  endif
  
  if (domag2) then begin
    store_data,'Bphi2',data={x:swe_mag2.time, y:swe_mag2.Bphi*!radeg}
    store_data,'Bthe2',data={x:swe_mag2.time, y:swe_mag2.Bthe*!radeg}
    store_data,'Bamp2',data={x:swe_mag2.time, y:swe_mag2.Bamp}

    ylim,'Bphi2',0,360,0
    options,'Bphi2','yticks',4
    options,'Bphi2','yminor',3
    options,'Bphi2','psym',3

    ylim,'Bthe2',-90,90,0
    options,'Bthe2','yticks',2
    options,'Bthe2','yminor',3
    options,'Bthe2','psym',3

    ylim,'Bamp2',0,0,1
    
    if (domag1) then begin
      store_data,'Bamp',data=['Bamp1','Bamp2']
      options,'Bamp2','color',6
      store_data,'Bphi',data=['Bphi1','Bphi2']
      options,'Bphi2','color',6
      ylim,'Bphi',0,360,0
      options,'Bphi','yticks',4
      options,'Bphi','yminor',3
      store_data,'Bthe',data=['Bthe1','Bthe2']
      options,'Bthe2','color',6
      ylim,'Bthe',-90,90,0
      options,'Bthe','yticks',2
      options,'Bthe','yminor',3
    endif
  endif

  return

end
