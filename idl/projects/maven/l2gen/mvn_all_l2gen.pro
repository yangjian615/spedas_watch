;+
;NAME:
; mvn_all_l2gen
;CALLING SEQUENCE:
; mvn_all_l2gen, time_in, instrument
;INPUT:
; time_in = the time for which old files created *after* this date
;           will be processed. E.g., if you pass in '2017-11-07'
;           then all files created after 7-nov-2017/00:00:00 will
;           be reprocessed
; instrument = a string array for the instrument to reprocess, '*' or
;              'all' will process all instruments, the default is to
;               process 'sep','sta','swe','swi'
;KEYWORDS:
; before_time = if set, process all of the files created *before* the
;              input time
; days_in = An array of dates, e.g., ['2009-01-30','2009-02-01'] to
;           process. This ignores the input time. This option
;           replicates the proceesing done by
;           thm_reprocess_l2gen_days.
; data_dir = the directory in which you find the data, default is
;            /disks/data/maven/sci
; out_dir = the directory in which you write the data, default is
;           /disks/data/maven/sci
; no_check_spice = if set, do not check for new spice files.
; use_file4time = if set, use filenames for time test instead of file
;                 modified time, useful for reprocessing
; search_time_range = if set, then use this time range to find files
;                     to be processed, instead of just before or after
;                     time. 
;HISTORY:
;Hacked from thm_all_l1l2_gen, 17-Apr-2014, jmm
; $LastChangedBy: jimm $
; $LastChangedDate: 2014-04-17 11:43:59 -0700 (Thu, 17 Apr 2014) $
; $LastChangedRevision: 14849 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/l2gen/mvn_all_l2gen.pro $
;-
Pro mvn_all_l2gen, time_in, instrument, $
                   before_time = before_time, $
                   data_dir = data_dir, $
                   out_dir = out_dir, $
                   no_check_spice = no_check_spice, $
                   use_file4time = use_file4time, $
                   search_time_range = search_time_range, $
                   days_in = days_in, $
                   _extra = _extra
  
  common temp, load_position
  set_plot, 'z'
  load_position = 'init'
  catch, error_status
  
  if error_status ne 0 then begin
     print, '%MVN_ALL_L2GEN: Got Error Message'
     help, /last_message, output = err_msg
     For ll = 0, n_elements(err_msg)-1 Do print, err_msg[ll]
     case load_position of
        'init':begin
           print, 'Problem with initialization'
           goto, SKIP_ALL
        end
        'instrument':begin
           print, '***************INSTRUMENT SKIPPED****************'
           goto, SKIP_INSTR
        End
        'l2gen':Begin
           print, '***************FILE SKIPPED****************'
           goto, SKIP_FILE
        end
        else: goto, SKIP_ALL
     endcase
  endif
;--------------------------------
  If(keyword_set(data_dir)) Then ddir = data_dir Else ddir = '/disks/data/maven/sci/'
  If(keyword_set(out_dir)) Then odir = out_dir Else odir = '/disks/data/maven/sci/'
  instr = strcompress(/remove_all, strlowcase(instrument))
  If(instr[0] Eq '*' Or instr[0] Eq 'all') Then $
    instr = ['sep', 'sta', 'swe', 'swi']
  ninstr = n_elements(instr)
  btime = time_double(time_in)
;For each instrument
  For k = 0, ninstr-1 Do Begin
     load_position = 'instrument'
     instrk = instr[k]
     If(keyword_set(days_in)) Then Begin
        days = time_string(days_in)
        timep_do = strmid(days, 0, 4)+strmid(days, 5, 2)+strmid(days, 8, 2)
     Endif Else Begin
        Case instrk Of          ;some instruments require multiple directories
           'sep': instr_dir = ['mag']
           'sta': instr_dir = ['mag']
           'swe': instr_dir = ['mag']
           'swi': instr_dir = ['mag']
           Else: instr_dir = instrk
        Endcase
;Set up check directories, l0 is first, then instrument directories
        sdir0 = ddir+'pfp/l0/mvn_pfp_???_l0_*.dat'
        sdir1 = ddir+instr_dir+'/l2/*/*/mvn*'
        sdir = [sdir0, sdir1]

;        If(~keyword_set(no_check_spice)) Then Begin
;           instr_dir = [instr_dir, 'spice'] ;trigger process for new spice files
;        Endif

        pfile = file_search(sdir)
        If(keyword_set(use_file4time)) Then Begin
 ;Get the file date
           timep = file_basename(pfile)
            For i = 0L, n_elements(pfile)-1L Do Begin
               ppp = strsplit(timep[i], '_', /extract)
               the_date = where((strlen(ppp) Eq 8) And (strmid(ppp, 0, 1)) Eq '2', nthe_date)
               If(nthe_date Eq 0) Then timep[i] = '' $
               Else timep[i] = ppp[the_date]
            Endfor
            test_time = time_double(time_string(temporary(timep), /date_only))
         Endif Else Begin
            finfo = file_info(pfile)
            test_time = finfo.mtime
         Endelse
         If(keyword_set(search_time_range)) Then Begin
            atime_test = test_time Ge time_double(search_time_range[0])
            btime_test = temporary(test_time) Lt time_double(search_time_range[1])
            proc_file = where(temporary(atime_test) Eq 1 And $
                              temporary(btime_test) Eq 1, nproc) ;do all of these temporarys really save memory?
         Endif Else If(keyword_set(before_time)) Then Begin
            proc_file = where(temporary(test_time) Le btime, nproc)
         Endif Else Begin
            proc_file = where(temporary(test_time) Ge btime, nproc)
         Endelse
         If(nproc Gt 0) Then Begin
;Get the file date
            timep = file_basename(pfile[proc_file])
            For i = 0, nproc-1 Do Begin
               ppp = strsplit(timep[i], '_', /extract)
               the_date = where((strlen(ppp) Eq 8) And (strmid(ppp, 0, 1)) Eq '2', nthe_date)
               If(nthe_date Eq 0) Then timep[i] = '' $
               Else timep[i] = ppp[the_date]
            Endfor
;process the unique dates
            dummy = is_string(timep, timep_ok) ;timep_ok are nonblank strings
            If(dummy Gt 0) Then Begin
               ss_timep = bsort(timep_ok, timep_s)
               timep_do = timep_s[uniq(timep_s)]
            Endif Else timep_do = ''
         Endif Else timep_do = ''
      Endelse
  Endelse
;If there are any dates to process, do them
  If(is_string(timep_do) Eq 0) Then Begin
     message, /info, 'No Files to process for Instrument: '+instrk
  Endif Else Begin
     nproc = n_elements(timep_do)
;extract the date from the filename
     For i = 0, nproc-1 Do Begin
        timei0 = timep_do[i]
        timei = strmid(timei0, 0, 4)+$
                '-'+strmid(timei0, 4, 2)+'-'+strmid(timei0, 6, 2)
        yr = strmid(timei0, 0, 4)
        mo = strmid(timei0, 4, 2)
;filei_dir is the output directory, not necessarily the search
;directory
        filei_dir = odir+instrk+'/l2/yr/mo/'
        If(is_string(file_search(filei_dir)) Eq 0) Then Begin
           message, /info, 'Creating: '+filei_dir
           file_mkdir, filei_dir
        Endif
        load_position = 'l2gen'
        message, /info, 'PROCESSING: '+instrk+' FOR: '+timei
        Case instrk Of
           'sep': mvn_sep_l2gen, date = timei, directory = filei_dir, _extra=_extra
           'sta': mvn_sta_l2gen, date = timei, directory = filei_dir, _extra=_extra
           'swi': mvn_swi_l2gen, date = timei, directory = filei_dir, _extra=_extra
           'swe': mvn_swe_l2gen, date = timei, directory = filei_dir, _extra=_extra
        Endcase
        SKIP_FILE: 
        del_data, '*'
        heap_gc                 ;added this here to avoid memory issues
     Endfor
     SKIP_INSTR: load_position = 'instrument'
  Endelse
  SKIP_ALL:
End


   

