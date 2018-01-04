;+
;NAME:
; mvn_sta_l2gen
;PURPOSE:
; Generates MAVEN STA L2 files
;CALLING SEQUENCE:
; mvn_sta_l2gen, date = date, l0_input_file = l0_input_file, $
;                directory = directory
;INPUT:
; Either the date or input L0 file, via keyword:
;KEYWORDS:
; date = If set, the input date.
; l0_input_file = A filename for an input file, if this is set, the
;                 date and time_range keywords are ignored.
; use_l2_files = If set, use current L2 files as input, and not
;                L0's -- for reprocessing
;HISTORY:
; 2014-05-14, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimmpc1 $
; $LastChangedDate: 2017-09-05 11:35:05 -0700 (Tue, 05 Sep 2017) $
; $LastChangedRevision: 23885 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sta/l2util/mvn_sta_l2gen.pro $
;-
Pro mvn_sta_l2gen, date = date, l0_input_file = l0_input_file, $
                   directory = directory, use_l2_files = use_L2_files, $
                   xxx = xxx, yyy = yyy, nocatch = nocatch, _extra = _extra

;Run in Z buffer
  set_plot,'z'

  load_position = 'init'
  einit = 0
  If(~keyword_set(nocatch)) Then Begin
     catch, error_status
     if error_status ne 0 then begin
        print, '%MVN_STA_L2GEN: Got Error Message'
        help, /last_message, output = err_msg
        For ll = 0, n_elements(err_msg)-1 Do print, err_msg[ll]
;Open a file print out the error message, only once
        If(einit Eq 0) Then Begin
           einit = 1
           openw, eunit, '/mydisks/home/maven/muser/sta_l2_err_msg.txt', /get_lun
           For ll = 0, n_elements(err_msg)-1 Do printf, eunit, err_msg[ll]
           If(keyword_set(datein)) Then Begin
              printf, eunit, datein
           Endif Else printf, eunit, 'Date unavailable'
           free_lun, eunit
;mail it to jimm@ssl.berkeley.edu
           cmd_rq = 'mailx -s "Problem with STA L2 process" jimm@ssl.berkeley.edu < /mydisks/home/maven/muser/sta_l2_err_msg.txt'
           spawn, cmd_rq
        Endif
        case load_position of
           'init':begin
              print, 'Problem with initialization'
              goto, skip_db
           end
           'ephemeris_l0':begin
              print, 'Problem with SPICE'
              goto, skip_ephemeris_l0
           end
           'ephemeris_l2':begin
              print, 'Problem with SPICE'
              goto, skip_ephemeris_l2
           end
           '2A':begin
              print, 'Problem in '+load_position
              goto, skip_2a
           end
           'C0':begin
              print, 'Problem in '+load_position
              goto, skip_c0
           end
           'C2':begin
              print, 'Problem in '+load_position
              goto, skip_c2
           end
           'C4':begin
              print, 'Problem in '+load_position
              goto, skip_c4
           end
           'C6':begin
              print, 'Problem in '+load_position
              goto, skip_c6
           end
           'C8':begin
              print, 'Problem in '+load_position
              goto, skip_c8
           end
           'CA':begin
              print, 'Problem in '+load_position
              goto, skip_ca
           end
           'CC':begin
              print, 'Problem in '+load_position
              goto, skip_cc
           end
           'CD':begin
              print, 'Problem in '+load_position
              goto, skip_cd
           end
           'CE':begin
              print, 'Problem in '+load_position
              goto, skip_ce
           end
           'CF':begin
              print, 'Problem in '+load_position
              goto, skip_cf
           end
           'D0':begin
              print, 'Problem in '+load_position
              goto, skip_d0
           end
           'D1':begin
              print, 'Problem in '+load_position
              goto, skip_d1
           end
           'D2':begin
              print, 'Problem in '+load_position
              goto, skip_d2
           end
           'D3':begin
              print, 'Problem in '+load_position
              goto, skip_d3
           end
           'D4':begin
              print, 'Problem in '+load_position
              goto, skip_d4
           end
           'D6':begin
              print, 'Problem in '+load_position
              goto, skip_d6
           end
           'D7':begin
              print, 'Problem in '+load_position
              goto, skip_d7
           end
           'D8':begin
              print, 'Problem in '+load_position
              goto, skip_d8
           end
           'D9':begin
              print, 'Problem in '+load_position
              goto, skip_d9
           end
           'DA':begin
              print, 'Problem in '+load_position
              goto, skip_da
           end
           'DB':begin
              print, 'Problem in '+load_position
              goto, skip_db
           end
           else: goto, skip_db
        endcase
     endif
  Endif
;First load the data
  If(keyword_set(l0_input_file)) Then Begin
     filex = file_search(l0_input_file[0])
  Endif Else Begin
     filex = mvn_l0_db2file(date)
  Endelse
  If(~is_string(filex)) Then Begin
     dprint, 'No L0 file available: '
     If(keyword_set(l0_input_file)) Then Begin
        dprint, l0_input_file[0]
     Endif Else Begin
        dprint, time_string(date)
     Endelse
     Return
  Endif

;date and timespan
  p1  = strsplit(file_basename(filex), '_',/extract)
  d0 = time_double(time_string(p1[4]))
  timespan, d0, 1

;At this point, I have a date, check to see if it is reasonable
  If(d0 Lt time_double('2013-12-04')) Then Begin
     dprint, 'Bad File Date: '+time_string(d0)
     Return
  Endif
  date = d0
  datein = time_string(date)
  yyyy = strmid(datein, 0, 4)
  mmmm = strmid(datein, 5, 2)
  dddd = strmid(datein, 8, 2)
  If(keyword_set(directory)) Then Begin
     dir_out0 = directory 
     If(keyword_set(xxx)) Then Begin
        dir_out = dir_out0+yyyy+'/'+mmmm+'/'
        dir_out_d1 = dir_out0+'d1_sav/'+yyyy+'/'+mmmm+'/'
     Endif Else Begin
        dir_out = dir_out0
        dir_out_d1 = dir_out0+'d1_sav/'
     Endelse
  Endif Else Begin
     dir_out0 = '/disks/data/maven/data/sci/sta/l2/'
     dir_out = dir_out0+yyyy+'/'+mmmm+'/'
     dir_out_d1 = dir_out0+'d1_sav/'+yyyy+'/'+mmmm+'/'
  Endelse
  If(~is_string(file_search(dir_out))) Then file_mkdir, dir_out
  If(~is_string(file_search(dir_out_d1))) Then file_mkdir, dir_out_d1
;define the common blocks
  common mvn_2a, mvn_2a_ind, mvn_2a_dat ;this one is HKP data
  common mvn_c0, mvn_c0_ind, mvn_c0_dat
  common mvn_c2, mvn_c2_ind, mvn_c2_dat
  common mvn_c4, mvn_c4_ind, mvn_c4_dat
  common mvn_c6, mvn_c6_ind, mvn_c6_dat
  common mvn_c8, mvn_c8_ind, mvn_c8_dat
  common mvn_ca, mvn_ca_ind, mvn_ca_dat
  common mvn_cc, mvn_cc_ind, mvn_cc_dat
  common mvn_cd, mvn_cd_ind, mvn_cd_dat
  common mvn_ce, mvn_ce_ind, mvn_ce_dat
  common mvn_cf, mvn_cf_ind, mvn_cf_dat
  common mvn_d0, mvn_d0_ind, mvn_d0_dat
  common mvn_d1, mvn_d1_ind, mvn_d1_dat
  common mvn_d2, mvn_d2_ind, mvn_d2_dat
  common mvn_d3, mvn_d3_ind, mvn_d3_dat
  common mvn_d4, mvn_d4_ind, mvn_d4_dat
  common mvn_d6, mvn_d6_ind, mvn_d6_dat
  common mvn_d7, mvn_d7_ind, mvn_d7_dat
  common mvn_d8, mvn_d8_ind, mvn_d8_dat
  common mvn_d9, mvn_d9_ind, mvn_d9_dat
  common mvn_da, mvn_da_ind, mvn_da_dat
  common mvn_db, mvn_db_ind, mvn_db_dat

;load l0 data, or L2 data
  If(keyword_set(use_l2_files)) Then Begin
;use no_time_clip to get all data, mvn_sta_l2_load will fill all of
;the common blocks
     mvn_sta_l2_load, /no_time_clip
;Check for 2a data, if not present, try L0, jmm, 2015-03-17
     If(~is_struct(mvn_2a_dat)) Then Begin
        mvn_sta_l0_load, files = filex ;filex is still defined.
     Endif Else mvn_sta_dead_load
;Added dead_time_load, 2015-03-03, jmm, shouldn't need it
;Add mag load, ephemeris_load, 2015-03-15, jmm
     mvn_sta_mag_load
     mvn_sta_qf14_load
;added mvn_sta_sc_bins_load, 2015-10-25, jmm
     mk = mvn_spice_kernels(/all,/load,trange=timerange())
     If(is_struct(mvn_c8_dat)) Then mvn_sta_sc_bins_load
;ephemeris might crash, don't kill the process, jmm, 2016-02-03
     load_position = 'ephemeris_l2'
     mvn_sta_ephemeris_load
     If(is_struct(mvn_c6_dat) && is_struct(mvn_c0_dat) && $
        is_struct(mvn_ca_dat)) Then mvn_sta_scpot_load
skip_ephemeris_l2:
  Endif Else Begin
     mvn_sta_l0_load, files = filex
;Only call ephemeris_load if the date is more than 5 days ago
;Changed to 10 days, 2015-09-30, jmm, back to 2 (!) days, 2016-10-18
     ttest = systime(/sec)-time_double(date)
     If(ttest Gt 2.0*86400.0d0) Then Begin
        load_position = 'ephemeris_l0'
        mvn_sta_mag_load
;        mvn_sta_qf14_load -- these are done in L0 load process
;        mvn_sta_dead_load
        mk = mvn_spice_kernels(/all,/load,trange=timerange())
        If(is_struct(mvn_c8_dat)) Then mvn_sta_sc_bins_load
;ephemeris might crash, don't kill the process, jmm, 2016-02-03
        mvn_sta_ephemeris_load
;scpot uses c6 eflux, but only if it exists
        If(is_struct(mvn_c6_dat) && is_struct(mvn_c0_dat) && $
           is_struct(mvn_ca_dat)) Then Begin
           mvn_sta_l2eflux, mvn_c6_dat
           mvn_sta_scpot_load
        Endif
skip_ephemeris_l0:
     Endif
  Endelse
;If yyy is set, we are replicating some app id's
  If(keyword_set(yyy)) Then Begin
;cd, cf, d1, d3, d6, d7

; cd = 32e32m8d same as cc
; cf = 16e16m4d16a same as ce
; d1 = 32e8m4d16a same as d0
; d3 = 32e8m16a same as d2

     mvn_cd_dat = mvn_cc_dat
     mvn_cd_dat.data_name= 'CD Energy-Angle-Mass'
     mvn_cd_dat.apid = 'CD'
     mvn_cd_dat.delta_t = mvn_cd_dat.delta_t/16.0
     tim_arr = mvn_cc_dat.time[0]+[0.0, total(/cumulative, mvn_cd_dat.delta_t)]
     ntimes = n_elements(tim_arr)-1
     mvn_cd_dat.time[*] = tim_arr[0:ntimes-1]
     mvn_cd_dat.end_time[*] = tim_arr[1:*]


     mvn_cf_dat = mvn_ce_dat
     mvn_cf_dat.data_name= 'CF Energy-Angle-Mass'
     mvn_cf_dat.apid = 'CF'
     mvn_cf_dat.delta_t = mvn_cf_dat.delta_t/16.0
     tim_arr = mvn_ce_dat.time[0]+[0.0, total(/cumulative, mvn_cf_dat.delta_t)]
     ntimes = n_elements(tim_arr)-1
     mvn_cf_dat.time[*] = tim_arr[0:ntimes-1]
     mvn_cf_dat.end_time[*] = tim_arr[1:*]

     mvn_d1_dat = mvn_d0_dat
     mvn_d1_dat.data_name= 'D1 Energy-Angle-Mass'
     mvn_d1_dat.apid = 'D1'
     mvn_d1_dat.delta_t = mvn_d1_dat.delta_t/16.0
     tim_arr = mvn_d0_dat.time[0]+[0.0, total(/cumulative, mvn_d1_dat.delta_t)]
     ntimes = n_elements(tim_arr)-1
     mvn_d1_dat.time[*] = tim_arr[0:ntimes-1]
     mvn_d1_dat.end_time[*] = tim_arr[1:*]

     mvn_d3_dat = mvn_d2_dat
     mvn_d3_dat.data_name= 'D3 Energy-Angle-Mass'
     mvn_d3_dat.apid = 'D3'
     tim_arr = mvn_d2_dat.time[0]+[0.0, total(/cumulative, mvn_d3_dat.delta_t)]
     ntimes = n_elements(tim_arr)-1
     mvn_d3_dat.time[*] = tim_arr[0:ntimes-1]
     mvn_d3_dat.end_time[*] = tim_arr[1:*]

  Endif

;Write the files
  load_position = '2A' & Print, load_position
  mvn_sta_cmn_2a_l2gen, mvn_2a_dat, directory = dir_out, _extra = _extra
  skip_2a:
  load_position = 'C0' & Print, load_position
  mvn_sta_cmn_l2gen, mvn_c0_dat, directory = dir_out, _extra = _extra
  skip_c0:
  load_position = 'C2' & Print, load_position
  mvn_sta_cmn_l2gen, mvn_c2_dat, directory = dir_out, _extra = _extra
  skip_c2:
  load_position = 'C4' & Print, load_position
  mvn_sta_cmn_l2gen, mvn_c4_dat, directory = dir_out, _extra = _extra
  skip_c4:
  load_position = 'C6' & Print, load_position
  mvn_sta_cmn_l2gen, mvn_c6_dat, directory = dir_out, _extra = _extra
  skip_c6:
  load_position = 'C8' & Print, load_position
  mvn_sta_cmn_l2gen, mvn_c8_dat, directory = dir_out, _extra = _extra
  skip_c8:
  load_position = 'CA' & Print, load_position
  mvn_sta_cmn_l2gen, mvn_ca_dat, directory = dir_out, _extra = _extra
  skip_ca:
  load_position = 'CC' & Print, load_position
  mvn_sta_cmn_l2gen, mvn_cc_dat, directory = dir_out, _extra = _extra
  skip_cc:
  load_position = 'CD' & Print, load_position
  mvn_sta_cmn_l2gen, mvn_cd_dat, directory = dir_out, _extra = _extra
  skip_cd:
  load_position = 'CE' & Print, load_position
  mvn_sta_cmn_l2gen, mvn_ce_dat, directory = dir_out, _extra = _extra
  skip_ce:
  load_position = 'CF' & Print, load_position
  mvn_sta_cmn_l2gen, mvn_cf_dat, directory = dir_out, _extra = _extra
  skip_cf:
  load_position = 'D0' & Print, load_position
  mvn_sta_cmn_l2gen, mvn_d0_dat, directory = dir_out, _extra = _extra
  skip_d0:
  load_position = 'D1' & Print, load_position
  mvn_sta_cmn_l2gen, mvn_d1_dat, directory = dir_out, _extra = _extra
;special save of D1 data
  If(is_struct(mvn_d1_dat)) Then Begin
     save, mvn_d1_dat, file = dir_out_d1+'mvn_sta_d1_'+yyyy+mmmm+dddd+'.sav'
     message, /info, 'Saved: '+dir_out_d1+'mvn_sta_d1_'+yyyy+mmmm+dddd+'.sav'
  Endif
  skip_d1:
  load_position = 'D2' & Print, load_position
  mvn_sta_cmn_l2gen, mvn_d2_dat, directory = dir_out, _extra = _extra
  skip_d2:
  load_position = 'D3' & Print, load_position
  mvn_sta_cmn_l2gen, mvn_d3_dat, directory = dir_out, _extra = _extra
  skip_d3:
  load_position = 'D4' & Print, load_position
  mvn_sta_cmn_l2gen, mvn_d4_dat, directory = dir_out, _extra = _extra
  skip_d4:
  load_position = 'D6' & Print, load_position
  mvn_sta_cmn_d6_l2gen, mvn_d6_dat, directory = dir_out, _extra = _extra
  skip_d6:
  load_position = 'D7' & Print, load_position
  mvn_sta_cmn_d7_l2gen, mvn_d7_dat, directory = dir_out, _extra = _extra
  skip_d7:
  load_position = 'D8' & Print, load_position
  mvn_sta_cmn_d89a_l2gen, mvn_d8_dat, directory = dir_out, _extra = _extra
  skip_d8:
  load_position = 'D9' & Print, load_position
  mvn_sta_cmn_d89a_l2gen, mvn_d9_dat, directory = dir_out, _extra = _extra
  skip_d9:
  load_position = 'DA' & Print, load_position
  mvn_sta_cmn_d89a_l2gen, mvn_da_dat, directory = dir_out, _extra = _extra
  skip_da:
  load_position = 'DB' & Print, load_position
  mvn_sta_cmn_db_l2gen, mvn_db_dat, directory = dir_out, _extra = _extra
  skip_db:
  print, 'All App_ids finished'

;Manage htaccess here
;  mvn_manage_l2access, 'sta'

  Return

End

