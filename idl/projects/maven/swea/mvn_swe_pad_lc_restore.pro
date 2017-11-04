;+ 
;PROCEDURE:   mvn_swe_pad_lc_restore
;PURPOSE:
;  Reads in save files mvn_swe_padscore
;                                      
;USAGE: 
;  mvn_swe_pad_lc_restore, trange
;
;INPUTS: 
;       trange:        Restore data over this time range.  If not
;                      specified, then uses the current tplot range 
;                      or timerange() will be called                         
; 
;KEYWORDS: 
;       ORBIT:         Restore mvn_swe_padscore data by orbit number.
;
;       RESULTS:       Hold the full structure of PAD score and
;                      other parameters
;
;       storeTPLOT:         Create tplot varibles
;                                                                                                         
; $LastChangedBy: xussui $  
; $LastChangedDate: 2017-11-03 13:49:26 -0700 (Fri, 03 Nov 2017) $  
; $LastChangedRevision: 24260 $ 
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_pad_lc_restore.pro $     
; 
;CREATED BY:    Tristan Weber
;FILE: mvn_swe_pad_lc_restore
;-
pro mvn_swe_pad_lc_restore, trange = trange, orbit = orbit, loadonly=loadonly, result = result, storeTplot = storeTplot, singlePad = singlePad
    
    
;    if keyword_set(singlePad) then rootPath = 'maven/data/sci/swe/l3/swe_pad_lc_single/YYYY/MM/'$
;       else rootPath = 'maven/data/sci/swe/l3/swe_pad_lc/YYYY/MM/'
;    rootPath = 'maven/data/sci/swe/l3/swe_pad_lc/YYYY/MM/'
    rootPath = 'maven/data/sci/swe/l3/padscore/YYYY/MM/'
    rootFilename = 'mvn_swe_l3_padscore_YYYYMMDD_v00_r01.sav' 
    if keyword_set(orbit) then begin
      orbMin = min(orbit, max=orbMax)
      
      trange = mvn_orbit_num(orbnum=[orbMin-0.5,orbMax+0.5])
    endif else begin
      if ~keyword_set(trange) then begin
        tplot_options, get_opt=topt
        tspan_exists = (max(topt.trange_full) gt time_double('2013-11-18'))
        if tspan_exists then trange = topt.trange_full else begin
          print, 'Must provide either a time range, orbit numbers, or have a current tplot timerange to use'
          return
        endelse
      endif
    endelse
    
    file = mvn_pfp_file_retrieve(rootPath+rootFilename,trange=trange,/daily_names)
    nfiles = n_elements(file)
    
    finfo = file_info(file)
    indx = where(finfo.exists, nfiles, comp=jndx, ncomp=n)
    for j=0,(n-1) do print,"File not found: ",file[jndx[j]]
    if (nfiles eq 0) then return
    file = file[indx]
    
    if keyword_set(loadonly) then begin
      print,''
      print,'Files found:'
      for i=0,(nfiles-1) do print,file[i],format='("  ",a)'
      print,''
      return
    endif

    for i=0,(nfiles-1) do begin 
      print,"Processing file: ",file_basename(file[i])
      restore, filename=file[i]
      if (i eq 0) then begin
        padTopoCombined = temporary(padTopo)
      endif else begin
        padTopoCombined = [temporary(padTopoCombined), temporary(padTopo)]
      endelse
    endfor
    
    ;Trim Data
    inTimeRange = where(padTopoCombined[*].time ge time_double(trange[0]) and padTopoCombined[*].time le time_double(trange[-1]), numInRange)
    if numInRange eq 0 then begin
      print, 'No Data in Time Range!'
      return
    endif else begin
      padTopoCombined = padTopoCombined[inTimeRange]
    endelse  
    
    result = padTopoCombined
    if keyword_set(storeTplot) then begin
       
    endif
end
