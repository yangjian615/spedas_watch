;+
;PROCEDURE:   swe_getmag_ql
;PURPOSE:
;  Loads MAG data based on a time range using quicklook software provided by 
;  the MAG team.  This is mostly a wrapper that combines mvn_mag_ql.pro with
;  mvn_pfp_file_retrieve.  This routine loads MAG data from both sensors and
;  performs rotations to transform to the SWEA instrument frame.
;
;  If trange spans multiple days, this routine can take a long time.
;
;USAGE:
;  swe_getmag_ql
;
;INPUTS:
;       trange:        Time range for loading data.
;
;KEYWORDS:
;       FILENAME:      Full path and file name containing L0 MAG data.
;                      Can be an array of file names.  Loading MAG data
;                      from multiple files can take a long time.
;
;       BOTH:          Load data from both MAG1 and MAG2.  Default is MAG1
;                      only.  (MAG1 is used for SWEA pitch angle mapping.)
;
;       TOFF:          Time offset for MAG data.  This accounts for any
;                      differences in MAG vs. SWEA timing.  Ideally, this
;                      should be zero, once both decommutators are correct.
;                      Use fit_pad_mag to empirically determine the offset.
;
;       SMO:           Smooth the data to the SWEA PAD resolution.  The
;                      mag angles in the SWEA PAD packets (A2, A3) are 
;                      one-second averages over the second half of the 
;                      integration time, rotated into SWEA coordinates.
;
;       DAVIN:         Use Davin's code for loading MAG data.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2014-08-08 12:47:55 -0700 (Fri, 08 Aug 2014) $
; $LastChangedRevision: 15676 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/swe_getmag_ql.pro $
;
;CREATED BY:    David L. Mitchell  03/18/14
;-
pro swe_getmag_ql, trange, filename=filename, both=both, toff=toff, smo=smo, davin=davin

  @mvn_swe_com

  domag1 = 1
  if keyword_set(both) then domag2 = 1 else domag2 = 0
  if keyword_set(toff) then toff = double(toff[0]) else toff = 0D
  if keyword_set(smo) then smo = 1 else smo = 0
  if keyword_set(davin) then dflg = 1 else dflg = 0
  daz = 0.

; Get file names associated with trange or from one or more named
; file(s).  If you specify a time range and are working off-site, 
; then the files are downloaded to your local machine, which might
; take a while.

  if (data_type(filename) eq 7) then begin
    file = filename
    nfiles = n_elements(file)
    trange = 0
  endif else begin
    if (data_type(trange) eq 0) then begin
      if (data_type(mvn_swe_engy) ne 8) then begin
        print,"You must load SWEA data or specify a file name or time range."
        return
      endif
      tmin = min(mvn_swe_engy.time, max=tmax)
      trange = [tmin,tmax]
    endif
    tmin = min(time_double(trange), max=tmax)
    file = mvn_pfp_file_retrieve(trange=[tmin,tmax],/l0)
    nfiles = n_elements(file)
  endelse
  
  finfo = file_info(file)
  indx = where(finfo.exists, nfiles, comp=jndx, ncomp=n)
  for j=0,(n-1) do print,"File not found: ",file[jndx[j]]  
  if (nfiles eq 0) then return
  file = file[indx]

; Load MAG data

  if (dflg) then begin
    domag2 = 1  ; MAG2 comes for free

    mvn_pfp_l0_file_read,file=file,/mag
    options,'mvn_mag1_svy_BAVG',spice_frame='MAVEN_MAG1', $
            spice_master_frame='MAVEN_SPACECRAFT'
    options,'mvn_mag2_svy_BAVG',spice_frame='MAVEN_MAG2', $
            spice_master_frame='MAVEN_SPACECRAFT'

    get_data,'mvn_mag1_svy_BAVG',data=mag1
    t1 = mag1.x
    B1x = mag1.y[*,0]
    B1y = mag1.y[*,1]
    B1z = mag1.y[*,2]
    mag1 = 0

    get_data,'mvn_mag2_svy_BAVG',data=mag2
    t2 = mag2.x
    B2x = mag2.y[*,0]
    B2y = mag2.y[*,1]
    B2z = mag2.y[*,2]
    mag2 = 0

  endif else begin
    for n=0,(nfiles-1) do begin
      i = rstrpos(file[n],'/')
      mpath = strmid(file[n],0,i+1)
      mname = strmid(file[n],i+1)
      pkt_type = 'ccsds'
      mvn_mag_ql, datafile=mname, pkt_type=pkt_type, input_path=mpath, $
                  data_output_path='./', plot_save_path='./', /tsmake, $
                  /mag1, /tplot

      get_data,'mvn_ql_mag1',data=mag1
      if (n eq 0) then begin
        t1 = mag1.x
        B1x = mag1.y[*,0]
        B1y = mag1.y[*,1]
        B1z = mag1.y[*,2]
      endif else begin
        t1 = [temporary(t1), mag1.x]
        B1x = [temporary(B1x), mag1.y[*,0]]
        B1y = [temporary(B1y), mag1.y[*,1]]
        B1z = [temporary(B1z), mag1.y[*,2]]
      endelse

      if (domag2) then begin
        mpath = strmid(file[n],0,i+1)
        mname = strmid(file[n],i+1)
        pkt_type = 'ccsds'
        mvn_mag_ql, datafile=mname, pkt_type=pkt_type, input_path=mpath, $
                    data_output_path='./', plot_save_path='./', /tsmake, $
                    /mag2, /tplot

        get_data,'mvn_ql_mag2',data=mag2
        if (n eq 0) then begin
          t2 = mag2.x
          B2x = mag2.y[*,0]
          B2y = mag2.y[*,1]
          B2z = mag2.y[*,2]
        endif else begin
          t2 = [temporary(t2), mag2.x]
          B2x = [temporary(B2x), mag2.y[*,0]]
          B2y = [temporary(B2y), mag2.y[*,1]]
          B2z = [temporary(B2z), mag2.y[*,2]]
        endelse
      endif
    endfor
  endelse

; Trim data to requested time range
  
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

; Rotate to SWEA coordinates

  if (domag1) then begin
    indx = where((mag1.x gt t_mtx[0]) and (mag1.x lt t_mtx[2]), nstow, $
                 complement=jndx, ncomplement=ndeploy)

    if (nstow gt 0L) then mag1.y[indx,*] = rotate_mag_to_swe(mag1.y[indx,*], magu=1, /stow)
    if (ndeploy gt 0L) then mag1.y[jndx,*] = rotate_mag_to_swe(mag1.y[jndx,*], magu=1)
  endif
  if (domag2) then begin
    indx = where((mag2.x gt t_mtx[0]) and (mag2.x lt t_mtx[2]), nstow, $
                 complement=jndx, ncomplement=ndeploy)

    if (nstow gt 0L) then mag2.y[indx,*] = rotate_mag_to_swe(mag2.y[indx,*], magu=2, /stow)
    if (ndeploy gt 0L) then mag2.y[jndx,*] = rotate_mag_to_swe(mag2.y[jndx,*], magu=2)
  endif

; Smooth the mag vectors to SWEA MAG sampling resolution (1 sec)

  if (smo) then begin
    if (domag1) then begin
      dt = median(mag1.x - shift(mag1.x,1))
      nsmo = round(1D/dt)
      mag1.y = smooth(mag1.y, [nsmo,1])
    endif

    if (domag2) then begin
      dt = median(mag2.x - shift(mag2.x,1))
      nsmo = round(1D/dt)
      mag2.y = smooth(mag2.y, [nsmo,1])
    endif
  endif

; Store the results in TPLOT and the SWEA common block

  if (data_type(swe_mag_struct) ne 8) then mvn_swe_struct

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

    swe_mag2.valid = 1B
  endif else swe_mag2 = 0

; Store results and comparisons in TPLOT variables
  
  if (domag1) then begin
  
    store_data,'Bphi1',data={x:swe_mag1.time - toff, y:(swe_mag1.Bphi - daz)*!radeg}
    store_data,'Bthe1',data={x:swe_mag1.time - toff, y:swe_mag1.Bthe*!radeg}
    store_data,'Bamp1',data={x:swe_mag1.time - toff, y:swe_mag1.Bamp}

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
  
    if (data_type(foo) eq 8) then begin
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
    store_data,'Bphi2',data={x:swe_mag2.time - toff, y:(swe_mag2.Bphi - daz)*!radeg}
    store_data,'Bthe2',data={x:swe_mag2.time - toff, y:swe_mag2.Bthe*!radeg}
    store_data,'Bamp2',data={x:swe_mag2.time - toff, y:swe_mag2.Bamp}

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
