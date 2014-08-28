;+
;NAME:
; mvn_all_l2gen0
;PURPOSE:
; Top shell for production of MAVEN PFP KL2 files
;CALLING SEQUENCE:
; mvn_all_l2gen0, date = date, $
;                num_days = num_days, $
;                instr_to_process = instr_to_process, $
;                direct_to_dbase=direct_to_dbase, $
;                start_date=start_date, end_date=end_date
;INPUT:
; All via keyword
;OUTPUT:
; No explicit outputs, just L2 files
;KEYWORDS:
; date = start date for process, default is today
; num_days = number of days to process, the default is 5
; instr_to_process = which instruments, currently one or more
;                    of: ['sep', 'sta', 'swe', 'swia']
; direct_to_dbase = set this to have the l2 file written to appropriate database
;                   directory.

; l2 file_dir = the output directory -- if direct_to_dbase is set,
;                                       then for each instrument
;                                       add 'instrument/l2/' to the
;                                       path. The deafult is
;                                       '/disks/data/maven/data/sci/'
; start_date, end_date = Start and end dates to facilitate
;                        reprocessing.
;HISTORY:
; Hacked from mvn_over_shell, 2014-04-16, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2014-04-17 11:43:59 -0700 (Thu, 17 Apr 2014) $
; $LastChangedRevision: 14849 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/l2gen/mvn_all_l2gen0.pro $
;-
Pro mvn_all_l2gen0, date = date, $
                   num_days = num_days, $
                   instr_to_process = instr_to_process, $
                   direct_to_dbase = direct_to_dbase, $
                   l2_file_dir = l2_file_dir, $
                   start_date = start_date, end_date = end_date, $
                   l0_input_file = l0_input_file, xxx = xxx, _extra=_extra

;Hold load position for error handling
  common mvn_all_l2gen0_private, load_position

  If(~keyword_set(datein)) Then $
     datein = time_string(systime(/seconds), precision = -3)

  catch, error_status
  If(error_status Ne 0) Then Begin
     dprint, dlevel = 0, 'Got Error Message'
     help, /last_message, output = err_msg
     For ll = 0, n_elements(err_msg)-1 Do print, err_msg[ll]
     Case load_position Of
        'sep':Begin
           print, 'Skipped SEP L2gen: '+time_string(datein)
           Goto, skip_sep
        End
        'sta':Begin
           print, 'Skipped STA L2gen: '+time_string(datein)
           Goto, skip_sta
        End
        'swe':Begin
           print, 'Skipped Swe L2gen: '+time_string(datein)
           Goto, skip_swe
        End
        'swia':Begin
           print, 'Skipped Swia L2gen: '+time_string(datein)
           Goto, skip_swia
        End
        Else: Begin
           print, 'MVN_ALL_L2GEN0 exiting with no clue'
        End
     Endcase
  Endif

  load_position = 'init'

  mvn_qlook_init, device ='z', _extra = _extra ;not sure what this will do yet

  If(keyword_set(instr_to_process)) Then Begin
     instx = strcompress(/remove_all, strlowcase(instr_to_process))
  Endif Else instx = ['sep', 'sta', 'swe', 'swia']

  If(keyword_set(l0_input_file)) Then Begin
     p1  = strsplit(file_basename(l0_input_file), '_',/extract)
     date = p1[4]
     start_date = time_double(date)
     end_date= start_date
  Endif Else Begin
     If(Not keyword_set(date)) Then $
        date = time_string(systime(/seconds), precision = -3)
     If(keyword_set(start_date)) Then Begin
        start_date = time_double(start_date) 
     Endif Else Begin
        If(keyword_set(num_days)) Then ndays = num_days Else ndays = 5
        start_date = time_double(date)-86400.*(ndays-1)
     Endelse
     If(keyword_set(end_date)) Then end_date = time_double(end_date) $
     Else end_date = time_double(date)
  Endelse

  i = 0.

  While start_date+86400.*i Le end_date Do Begin
     If(~keyword_set(xxx)) Then del_data,'*'
     datein = time_string(start_date+86400.*i)
     dprint, 'Processing: '+time_string(datein)
     datein = time_string(datein)
     datein_d = time_double(datein)
     yyyy = strmid(datein, 0, 4)
     mmmm = strmid(datein, 5, 2)
;l2_file_dir check down here, to allow direct output
     If(keyword_set(l2_file_dir)) Then pdir = l2_file_dir $
     Else pdir = '/disks/data/maven/data/sci/'
;Do each individual instrument
     do_sep = where(instx Eq 'sep')
     If(do_sep[0] Ne -1) Then Begin
        load_position = 'sep'
        If(keyword_set(direct_to_dbase)) Then pdir1 = pdir+'sep/l2/'+yyyy+'/'+mmmm+'/' $
        Else pdir1 = pdir
        If(~is_string(file_search(pdir1))) Then file_mkdir, pdir1
        mvn_sep_l2gen, date = datein, l0_input_file = l0_input_file, directory = pdir1, _extra=_extra
        skip_sep: 
     Endif
     do_sta = where(instx Eq 'sta')
     If(do_sta[0] Ne -1) Then Begin
        load_position = 'sta'
        If(keyword_set(direct_to_dbase)) Then pdir1 = pdir+'sta/l2/'+yyyy+'/'+mmmm+'/' $
        Else pdir1 = pdir
        If(~is_string(file_search(pdir1))) Then file_mkdir, pdir1
        mvn_sta_l2gen, date = datein, l0_input_file = l0_input_file, directory = pdir1, _extra=_extra
        skip_sta: 
     Endif
     do_swe = where(instx Eq 'swe')
     If(do_swe[0] Ne -1) Then Begin
        load_position = 'swe'
        If(keyword_set(direct_to_dbase)) Then pdir1 = pdir+'swe/l2/'+yyyy+'/'+mmmm+'/' $
        Else pdir1 = pdir
        If(~is_string(file_search(pdir1))) Then file_mkdir, pdir1
        mvn_swe_l2gen, date = datein, l0_input_file = l0_input_file, directory = pdir1, _extra=_extra
        skip_swe: 
     Endif
     do_swia = where(instx Eq 'swia')
     If(do_swia[0] Ne -1) Then Begin
        load_position = 'swia'
        If(keyword_set(direct_to_dbase)) Then pdir1 = pdir+'swi/l2/'+yyyy+'/'+mmmm+'/' $
        Else pdir1 = pdir
        If(~is_string(file_search(pdir1))) Then file_mkdir, pdir1
        mvn_swia_l2gen, date = datein, l0_input_file = l0_input_file, directory = pdir1, _extra=_extra
        skip_swia: 
     Endif
     i=i+1
  Endwhile

  Return
End
