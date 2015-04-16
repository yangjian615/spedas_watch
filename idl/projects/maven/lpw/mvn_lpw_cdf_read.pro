
;+
;Edited on 2015-01-09 by CF: this rouinte takes a date, works out which files to load, and sends those to mvn_lpw_cdf_read_file
;
;Program written by Chris Fowler on Jan 6th 2014 as a wrapper for all the IDL routines needed to load cdf files into tplot memory
;for the lpw instrument.
;
; INPUTS:
; - date: a string variable with the date you want to load files for in the form: 'yyyy-mm-dd'
; 
; OUTPUTS:
; - the tplot variables and corresponding limit and dlimit data are loaded into IDL tplot memory.
; 
; KEYWORDS:
; - vars: variable that you wish to load. Entered as a string, or string array if you want multiple variables loaded. Entries can be upper or lower case. 
;         The default (if not set) is to load all. There are twelve products LPW produces:
;         wspecact
;         wspecpas
;         we12burstlf
;         we12burstmf
;         we12bursthf
;         wn
;         lpiv
;         lpnt
;         mrgexb
;         mrgscpot
;         euv
;         e12
; 
; - level: level of data to load, entered as a string, or string array for multiple levels. Entries can be uppder or lower case. The default (if not set) is just L2. There are four options:
;   l1a, l1b, l2, all 
; 
; - newdir: the default directory should be a mirror of SSL. Set this keyword if you want to look at files stored at another location. Note that sub folders within newdir are assumed to have the structure newdir/yyyy/mm/file.cdf
;
; EXAMPLE: to load the following two CDF files:
; 
; EDITS:
; - Througn till Jan 7 2014 (CF).
; - June 23 2014 CF: modified dir input to be either the same length as varlist (for multiple paths) or jsut one entry (the same path for
;                    each cdf file)
; -140718 clean up for check out L. Andersson
; -2015-01-09: CF: routine changed to accept date. This routine calls upon mvn_lpw_cdf_read_file and provides the filenames to do the loading.
;
; Version 2.0
;-

pro mvn_lpw_cdf_read, date, vars=vars, level=level, newdir=newdir

name = 'mvn_lpw_cdf_read: '
sl = path_sep()

;May need password:
if getenv('MAVENPFP_USER_PASS') eq '' then begin
   passwd = getenv('USER')+':'+getenv('USER')+'_pfp';this is the default password, jmm, 2015-02-07
endif else passwd = getenv('MAVENPFP_USER_PASS')

;Check date is correct format:
IF size(date, /type) EQ 7 THEN BEGIN  ;utc_in must be a string
  IF n_elements(date) NE 1 THEN BEGIN  ;only one date entry
    print, "#### WARNING ####: date entered must be a string in the format 'yyyy-mm-dd'."
    print, "For example: '2014-02-01'. You can only read in one day at a time."
    retall
  ENDIF
  IF strmatch(date, '[0123456789][0123456789][0123456789][0123456789]-[0123456789][0123456789]-[0123456789][0123456789]') NE 1 THEN BEGIN
    print, "#### WARNING ####: entered date must be a string in the format 'yyyy-mm-dd'."
    print, "For example: '2014-02-01'. You can only read in one day at a time."
    retall
  ENDIF
ENDIF ELSE BEGIN
  print, "#### WARNING ####:entered date must be a string in the format 'yyyy-mm-dd'."
  print, "For example: '2014-02-01'. You can only read in one day at a time."
  retall
ENDELSE

;Check vars, levels. Make lower case, as all file names will be lower case.
if keyword_set(vars) then vars = strlowcase(vars) else vars=['wspecact', 'wspecpas', 'we12burstlf', 'we12burstmf', 'we12bursthf', 'wn', 'lpiv', 'lpnt', 'mrgexb', 'mrgscpot', 'e12']  ;default ;make everything lower case
if keyword_set(levels) then levels = strlowcase(levels) else levels = ['l2']
euvcall = 0.
euvget = 0.
if total(strmatch(vars, 'euv')) eq 1. then begin
    neleV = n_elements(vars)
    if neleV gt 1 then euvcall = 1.  ;print error message at end of routine
    if neleV eq 1 then euvget = 1.  ;if vars='EUV' then get EUV
endif

;Determine how many levels we have. Then, for each level, find the correct file based on vars:
yr = strmid(date, 0, 4)
mm = strmid(date, 5, 2)
dd = strmid(date, 8, 2)

nl = n_elements(levels)
nv = n_elements(vars)

;To get the base dir to the server, root_data_dir os /spg/maven/data; the production files are saved on /spg/mavenlpw/. BUT, spg mounts differently depending on desktop vs laptop. Need to use getenv and break apart the variable.
udir = getenv('ROOT_DATA_DIR')  ;at LASP this is usually /Volumes/spg/maven/data/ or /spg/maven/data
fbase=udir+'maven'+sl+'data'+sl+'sci'+sl+'lpw'+sl   ;Need some files to test this, so it may not work yet!
if euvget eq 1. then fbase=udir+'maven'+sl+'data'+sl+'sci'+sl+'euv'+sl

;if strmatch(udir, '*Volumes*') eq 1. then fbase = '/Volumes/spg/mavenlpw/products/automatic_production/' else fbase = '/spg/mavenlpw/products/automatic_production/'
if keyword_set(newdir) then fbase = newdir  ;### NOT checked or tested yet

fvars = ['']  ;store found variables

for ll = 0, nl-1 do begin
    for vv = 0, nv -1 do begin
          ;Search for latest file:
          fname = 'mvn_lpw_'+levels[ll]+'_'+vars[vv]+'_'+yr+mm+dd   ;cdf_latest will find latest v and r; this is first part of filename
          if euvget eq 1. then fname = 'mvn_euv_'+levels[ll]+'_bands_'+yr+mm+dd
          
          fname2 = fbase+levels[ll]+sl+yr+sl+mm+sl+fname   ;full directory to file, minus v and r numbers.
;jmm, 2015-02-05 to use mvn_pfp_file_retrieve, don't include the root_data_dir 
          fname2_tst = 'maven'+sl+'data'+sl+'sci'+sl+'lpw'+sl+ $
                       levels[ll]+sl+yr+sl+mm+sl+fname+'_v??_r??.cdf'
          if euvget eq 1. then fname2_tst = 'maven'+sl+'data'+sl+'sci'+sl+'euv'+sl+ $  ;get EUV based on euvget
                                            levels[ll]+sl+yr+sl+mm+sl+fname+'_v??_r??.cdf'
          fname2 = mvn_pfp_file_retrieve(fname2_tst, user_pass = passwd)

          ff = mvn_lpw_cdf_latest_file(fname2)  ;latest file
          if ff ne 'none_found' then fvars = [fvars, ff]     
    endfor 
endfor

nfound = n_elements(fvars)

if nfound eq 1 then begin
    print, ""
    print, name, "### No cdf files found matching input, variables, and levels: "
    print, date
    print, vars
    print, levels
    print, ""
    fvars = 'none_found'
endif else begin
    fvars = fvars[1:nfound-1]  ;first point is a dummy point
    nfound -= 1.   ;subtract first dummy point
  
    ;Need to split up each filename into directory and filename before feeding to mvn_lpw_cdf_read_file.
    dirs = strarr(nfound)  ;store dirs and names
    names = strarr(nfound)
    
    for ff = 0, nfound -1 do begin
;        ni = strpos(fvars[ff], 'mvn_lpw_')  ;indices at which the filename starts
;        slen = strlen(fvars[ff])  ;length of whole string
;        dirs[ff] = strmid(fvars[ff], 0, ni)
;        names[ff] = strmid(fvars[ff], ni, slen-56)    
;jmm, 2014-02-05, use file_basename, file_dirname
       dirs[ff] = file_dirname(fvars[ff])
       names[ff] = file_basename(fvars[ff])
    endfor    

    ;Feed found files into read routine:
    mvn_lpw_cdf_read_file, dir=dirs, varlist=names
   
endelse

if (euvcall eq 1.) and (euvget eq 0.) then begin
    print, name, "### WARNING ### : currently you must load EUV data in a separate call to mvn_lpw_cdf_read, which does not call on any LP data. This run"
    print, "will load the following variables: "
    print, ""
    print, fvars
    print, ""
    print, "Now run mvn_lpw_cdf_read, date, vars='euv'
    print, "To load EUV data as well."
    print,""
endif


end





