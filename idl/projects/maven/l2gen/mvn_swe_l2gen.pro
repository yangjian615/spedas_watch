;+
;NAME:
; mvn_swe_l2gen
;PURPOSE:
; Loads L0 data, creates L2 files for 1 day
;CALLING SEQUENCE:
; mvn_swe_l2gen, date = date
;INPUT:
; date keyword
;KEYWORDS:
; date = If set, the input date. The default is today
; directory = If set, output into this directory, for testing
;             purposes, don't forget a slash '/'  at the end.
; l2only = If set, only generate PAD L2 data if MAG L2 data are available.
; nokp = If set, do not generate SWEA KP data.
; nol2 = If set, do not generate SWEA L2 data.
;HISTORY:
; Hacked from Matt F's crib_l0_to_l2.txt, 2014-11-14, jmm,
; jimm@ssl.berkeley.edu
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2015-05-27 18:04:20 -0700 (Wed, 27 May 2015) $
; $LastChangedRevision: 17754 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/l2gen/mvn_swe_l2gen.pro $
;- 
pro mvn_swe_l2gen, date = date, directory = directory, l2only = l2only, nokp = nokp, $
                   nol2=nol2, _extra = _extra

  @mvn_swe_com
  
  if keyword_set(l2only) then l2only = 1 else l2only = 0

; Root data directory, sometimes isn't defined

  setenv, 'ROOT_DATA_DIR=/disks/data/'

; Pick a day

  if (keyword_set(date)) then time = time_string(date[0], /date_only) $
                         else time = time_string(systime(/sec,/utc), /date_only)

  t0 = time_double(time)
  t1 = t0 + 86400D

  message, /info, 'PROCESSING: '+time_string(t0)
  timespan, t0, 1

; get SPICE kernels

  mvn_swe_spice_init, /force

; Load L0 SWEA data

  mvn_swe_load_l0

; Load highest level MAG data available (for pitch angle sorting)
;   L0 --> MAG angles computed onboard (stored in A2/A3 packets)
;   L1 --> MAG data processed on ground with nominal gains and offsets
;   L2 --> MAG data processed on ground with all corrections

  mvn_swe_addmag
  if (size(swe_mag1,/type) eq 8) then maglev = swe_mag1[0].level else maglev = 0B
  if (l2only and (maglev lt 2B)) then begin
    print,"No MAG L2 data.  No CDF files created."
    return
  endif

; Create CDF files (up to 6 of them)

  if ~keyword_set(nol2) then begin

    ddd_svy = mvn_swe_get3d([t0,t1], /all)
    mvn_swe_makecdf_3d, ddd_svy, directory=directory
    ddd_svy = 0

    ddd_arc = mvn_swe_get3d([t0,t1], /all, /archive)
    mvn_swe_makecdf_3d, ddd_arc, directory=directory
    ddd_arc = 0

    pad_svy = mvn_swe_getpad([t0,t1], /all)
    mvn_swe_makecdf_pad, pad_svy, directory=directory
    pad_svy = 0

    pad_arc = mvn_swe_getpad([t0,t1], /all, /archive)
    mvn_swe_makecdf_pad, pad_arc, directory=directory
    pad_arc = 0

    spec_svy = mvn_swe_getspec([t0,t1])
    mvn_swe_makecdf_spec, spec_svy, directory=directory
    spec_svy = 0

    spec_arc = mvn_swe_getspec([t0,t1], /archive)
    mvn_swe_makecdf_spec, spec_arc, directory=directory
    spec_arc = 0

  endif

; Create KP save file

  if ~keyword_set(nokp) then mvn_swe_kp, l2only=l2only

; Clean up

  store_data, '*', /delete 

  return

end

