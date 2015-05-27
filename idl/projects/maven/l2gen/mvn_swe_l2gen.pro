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
;HISTORY:
; Hacked from Matt F's crib_l0_to_l2.txt, 2014-11-14, jmm,
; jimm@ssl.berkeley.edu
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2015-05-25 17:28:44 -0700 (Mon, 25 May 2015) $
; $LastChangedRevision: 17707 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/l2gen/mvn_swe_l2gen.pro $
;- 
Pro mvn_swe_l2gen, date = date, directory = directory, l2only = l2only, nokp = nokp, $
                   _extra = _extra
; crib for loading l0 data, creating L2 CDF files, and populating structures
; only works for one day at a time -- that's how we make L2 CDFs

@ mvn_swe_com

;Root data directory, sometimes isn't defined
  setenv, 'ROOT_DATA_DIR=/disks/data/'

; pick a day
  If(keyword_set(date)) Then time = time_string(date[0], /date_only) $
  Else time = time_string(systime(/sec), /date_only)

;time = '2014-03-26'
;time = '2014-10-22'
  t_start = time_double(time)
  t_end = time_double(time) + 86400.D ; a full day
  trange = [t_start, t_end]
  trange_str = time_string(trange)
;You need a timespan, so that the clock drift doesn't prompt for one
  message, /info, 'PROCESSING: '+time_string(t_start)
  timespan, t_start, 1
; get SPICE kernels
  mvn_swe_spice_init, trange = trange, /force

; Load L0 SWEA data
  mvn_swe_load_l0, trange_str

; Load highest level MAG data available (for pitch angle sorting)
;   L0 --> MAG angles computed onboard (stored in A2/A3 packets)
;   L1 --> MAG data processed on ground with nominal gains and offsets
;   L2 --> MAG data processed on ground with all corrections

  mvn_swe_addmag
  if (size(swe_mag1,/type) eq 8) then maglev = swe_mag1[0].level else maglev = 0B
  if (keyword_set(l2only) and (maglev lt 2B)) then begin
    print,"No MAG L2 data.  No CDF files created."
    return
  endif

; data variables that will populate CDF files
  ddd_svy = mvn_swe_get3d(trange_str, /all) ; trange_str changed by program
  trange_str = time_string(trange)
  ddd_arc = mvn_swe_get3d(trange_str, /all, /archive)

  trange_str = time_string(trange)
  pad_svy = mvn_swe_getpad(trange_str, /all)
  trange_str = time_string(trange)
  pad_arc = mvn_swe_getpad(trange_str, /all, /archive)

  trange_str = time_string(trange)
  spec_svy = mvn_swe_getspec(trange_str)
  trange_str = time_string(trange)
  spec_arc = mvn_swe_getspec(trange_str, /archive)

; create CDFs -- 6 of them
; version number is inserted from the swea common block

  mvn_swe_makecdf_3d, ddd_svy, directory=directory
  mvn_swe_makecdf_3d, ddd_arc, directory=directory
  
  mvn_swe_makecdf_pad, pad_svy, directory=directory
  mvn_swe_makecdf_pad, pad_arc, directory=directory

  mvn_swe_makecdf_spec, spec_svy, directory=directory
  mvn_swe_makecdf_spec, spec_arc, directory=directory

; stop here if you're only making L2 files
; Make kp save file:
  del_data, '*'                 ;delete all tplot variables so files 
                                ;aren't made from the previous day's data

  if ~keyword_set(nokp) then mvn_swe_kp, trange

Return
End

