;+
;PROCEDURE:   mvn_swe_load_l0
;PURPOSE:
;  Reads in MAVEN Level 0 telemetry files (PFDPU packets wrapped in 
;  spacecraft packets).  SWEA packets are identified, decompressed if
;  necessary, and decomuted.  SWEA housekeeping and data are stored in 
;  a common block (mvn_swe_com).
;
;  The packets can be any combination of:
;
;    Housekeeping:      normal rate  (APID 28)
;                       fast rate    (APID A6)
;
;    3D Distributions:  survey mode  (APID A0)
;                       archive mode (APID A1)
;
;    PAD Distributions: survey mode  (APID A2)
;                       archive mode (APID A3)
;
;    ENGY Spectra:      survey mode  (APID A4)
;                       archive mode (APID A5)
;
;  Sampling and averaging of 3D, PAD, and ENGY data are controlled by group
;  and cycle parameters.  The group parameter (G = 0,1,2) sets the summing of
;  adjacent energy bins.  The cycle parameter (N = 0,1,2,3,4,5) sets sampling 
;  of 2-second measurement cycles.  Data products are sampled every 2^N cycles.
;
;  3D distributions are stored in 1, 2 or 4 packets, depending on the group 
;  parameter.  Multiple packets must be stitched together (see swe_plot_dpu).
;
;  PAD packets have one of 3 possible lengths, depending on the group parameter.
;  The PAD data array is sized to accomodate the largest packet (G = 0).  When
;  energies are summed, only 1/2 or 1/4 of this data array is used.
;
;  ENGY spectra always have 64 energy channels (G = 0).
;
;USAGE:
;  mvn_swe_load_l0, trange
;
;INPUTS:
;       trange:        Load SWEA packets from L0 data spanning this time range.
;                      (Reads multiple L0 files, if necessary.  Use MAXBYTES to
;                      protect against brobdingnagian loads.)
;
;KEYWORDS:
;       FILENAME:      Full path and file name for loading data.  Can be multiple
;                      files.  Takes precedence over trange, ORBIT, and LATEST.
;
;       ORBIT:         Load SWEA data by orbit number or range of orbit numbers 
;                      (trange and LATEST are ignored).  Orbits are numbered using 
;                      the NAIF convention, where the orbit number increments at 
;                      periapsis.  Data are loaded from the apoapsis preceding the
;                      first orbit (periapsis) number to the apoapsis following the
;                      last orbit number.
;
;       LATEST:        Ignore trange (if present), and load all data within the
;                      LATEST days leading up to the current date.
;
;       CDRIFT:        Correct for spacecraft clock drift using SPICE.
;                      Default = 1 (yes).
;
;       MAXBYTES:      Maximum number of bytes to process.  Default is all data
;                      within specified time range.
;
;       BADPKT:        An array of structures providing details of bad packets.
;
;       STATUS:        Report statistics of data actually loaded.
;
;       SUMPLOT:       Create a summary plot of the loaded data.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2014-12-11 16:22:51 -0800 (Thu, 11 Dec 2014) $
; $LastChangedRevision: 16467 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_load_l0.pro $
;
;CREATED BY:    David L. Mitchell  04-25-13
;FILE: mvn_swe_load_l0.pro
;-
pro mvn_swe_load_l0, trange, filename=filename, latest=latest, maxbytes=maxbytes, badpkt=badpkt, $
                             cdrift=cdrift, sumplot=sumplot, status=status, orbit=orbit

  @mvn_swe_com

  if not keyword_set(maxbytes) then maxbytes = 0
  nodupe = 1
  oneday = 86400D
  
  if keyword_set(status) then silent = 0 else silent = 1
  
  if keyword_set(orbit) then begin
    imin = min(orbit, max=imax)
    trange = mvn_orbit_num(orbnum=[imin-0.5,imax+0.5])
    latest = 0
  endif
  
  if keyword_set(latest) then begin
    tmax = double(ceil(systime(/sec,/utc)/oneday))*oneday
    tmin = tmax - (double(latest[0])*oneday)
    trange = [tmin, tmax]
  endif
  
  if (size(cdrift, /type) eq 0) then dflg = 1 else dflg = keyword_set(cdrift)

; Get file names associated with trange or from one or more named
; file(s).  If you specify a time range and are working off-site, 
; then the files are downloaded to your local machine, which might
; take a while.

  if (size(filename,/type) eq 7) then begin
    file = filename
    nfiles = n_elements(file)
    trange = 0
  endif else begin
    if (size(trange,/type) eq 0) then begin
      print,"You must specify a file name or time range."
      return
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

; If time range is undefined, get it from the file name(s)

  if (size(trange,/type) eq 0) then begin
    trange = [0D]
    for i=0,(nfiles-1) do begin
      fbase = file_basename(file[i])
      yyyy = strmid(fbase,16,4,/reverse)
      mm = strmid(fbase,12,2,/reverse)
      dd = strmid(fbase,10,2,/reverse)
      t0 = time_double(yyyy + '-' + mm + '-' + dd)
      trange = [trange, t0, (t0 + oneday)]
    endfor
    trange = minmax(trange[1:*])
  endif
  
  timespan, trange

; Initialize SPICE

  mvn_swe_spice_init, trange=trange

; Define telemetry conversion factors

  if (size(decom,/type) eq 0) then begin

; Decompression: 19-to-8
;   16-bit instrument messages are summed into 19-bit counters 
;   in the PFDPU.  These 19-bit values are rounded down onboard
;   to fit into the 8-bit compression scheme, so each compressed
;   value corresponds to a range of possible counts.  I take the
;   middle of each range for decompression, so there are half 
;   counts.  This is less than a ~3% (systematic) correction.
;
;   Compression introduces digitization noise, which dominates
;   the variance at high count rates.  I treat digitization noise
;   as additive white noise.

    decom = fltarr(16,16)
    decom[0,*] = findgen(16)
    decom[1,*] = 16. + findgen(16)
    for i=2,15 do decom[i,*] = 2.*decom[(i-1),*]
    
    d_floor = reform(transpose(decom),256)        ; FSW rounds down
    d_ceil = shift(d_floor,-1) - 1.
    d_ceil[255] = 2.^19. - 1.                     ; 19-bit counter max
    d_mid = (d_ceil + d_floor)/2.                 ; mid-point
    n_pts = d_ceil - d_floor + 1.                 ; number of values in range
    d_var = d_mid + (n_pts^2. - 1.)/12.           ; variance w/ dig. noise
    
    decom = d_mid  ; decompressed counts
    devar = d_var  ; variance w/ digitization noise

; Housekeeping conversions

    swe_v = [ 1.000     , $   ;  0: LVPS Temperature
             -0.153355  , $   ;  1: MCP HV Voltage
             -0.000203  , $   ;  2: NRHV +5V Supply Voltage
             -0.030795  , $   ;  3: Analyzer Voltage
             -0.076870  , $   ;  4: Deflector 1 Voltage
             -0.075839  , $   ;  5: Deflector 2 Voltage
              1.000     , $   ;  6: ground/spare
              1.000     , $   ;  7: ground/spare
              0.000763  , $   ;  8: V0 Voltage
              1.000     , $   ;  9: Analyzer Temperature
             -0.000459  , $   ; 10: +12V Voltage
             -0.000459  , $   ; 11: -12V Voltage
             -0.001055  , $   ; 12: +28V Voltage (after MCPHV enable plug)
             -0.001055  , $   ; 13: +28V Voltage (after NRHV enable plug)
              1.000     , $   ; 14: ground/spare
              1.000     , $   ; 15: ground/spare
              1.000     , $   ; 16: Digital Temperature
             -0.000169  , $   ; 17: +2.5V Digital Voltage
             -0.000191  , $   ; 18: +5V Digital Voltage
             -0.000169  , $   ; 19: +3.3V Digital Voltage
             -0.000191  , $   ; 20: +5V Analog Voltage
             -0.000191  , $   ; 21: -5V Analog Voltage
             -0.001055  , $   ; 22: +28V Voltage
              1.000        ]  ; 23: ground/spare

    swe_t = [1.6484d2, 3.9360d-2, 5.6761d-6, 4.4329d-10, 1.6701d-14, 2.4223d-19]

; Grouping and Period

    swe_ne = [64, 32, 16, 0]       ; number of energy bins for group=0,1,2
    swe_dt = 2D^(dindgen(6) + 1D)  ; sample interval (sec) for period=0,1,2,3,4,5

  endif
  
; Read in the telemetry file and store the packets in a byte array

  for i=0,(nfiles-1) do begin
    print,"Processing file: ",file_basename(file[i])

    if (i eq 0) then begin
      mvn_swe_clear
      badpkt = 0
      mvn_swe_read_l0, file[i], trange=trange, maxbytes=maxbytes, badpkt=badpkt, cdrift=dflg
    endif else begin
      mvn_swe_read_l0, file[i], trange=trange, maxbytes=maxbytes, badpkt=badpkt, cdrift=dflg, /append
    endelse

  endfor

; Check to see if data were actually loaded

  mvn_swe_stat, npkt=npkt, silent=silent
  
  if (total(npkt) eq 0L) then begin
    print,"No data were loaded!"
    return
  endif
  
  if (npkt[7] eq 0L) then begin
    print,"No SWEA housekeeping!"
    return
  endif

; Stitch together 3D packets
  
  swe_3d_stitch

; Filter out duplicate packets

  if keyword_set(nodupe) then begin

    if (size(swe_hsk,/type) eq 8) then begin
      indx = uniq(swe_hsk.met,sort(swe_hsk.met))
      swe_hsk = temporary(swe_hsk[indx])
    endif

    if (size(swe_3d,/type) eq 8) then begin
      if (n_elements(swe_3d) gt 0L) then begin
        indx = uniq(swe_3d.met,sort(swe_3d.met))
        swe_3d = temporary(swe_3d[indx])
      endif
    endif

    if (size(swe_3d_arc,/type) eq 8) then begin
      if (n_elements(swe_3d_arc) gt 0L) then begin
        indx = uniq(swe_3d_arc.met,sort(swe_3d_arc.met))
        swe_3d_arc = temporary(swe_3d_arc[indx])
      endif
    endif

    if (size(a2,/type) eq 8) then begin
      indx = uniq(a2.met,sort(a2.met))
      a2 = temporary(a2[indx])
    endif

    if (size(a3,/type) eq 8) then begin
      indx = uniq(a3.met,sort(a3.met))
      a3 = temporary(a3[indx])
    endif

    if (size(a4,/type) eq 8) then begin
      indx = uniq(a4.met,sort(a4.met))
      a4 = temporary(a4[indx])
    endif

    if (size(a5,/type) eq 8) then begin
      indx = uniq(a5.met,sort(a5.met))
      a5 = temporary(a5[indx])
    endif

    if (size(a6,/type) eq 8) then begin
      indx = uniq(a6.met,sort(a6.met))
      a6 = temporary(a6[indx])
    endif

  endif

; Define times of configuration changes

  mvn_swe_config

; Determine calibration factors

  mvn_swe_calib

; Define the 3D, PAD, and SPEC data structures

  mvn_swe_struct

; Extract energy spectra

  mvn_swe_makespec

; Create a summary plot

  if keyword_set(sumplot) then mvn_swe_sumplot

  return

end
