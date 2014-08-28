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
;HISTORY:
; 2014-05-14, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2014-06-16 17:20:26 -0700 (Mon, 16 Jun 2014) $
; $LastChangedRevision: 15384 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/l2gen/mvn_sta_l2gen.pro $
;-
Pro mvn_sta_l2gen, date = date, l0_input_file = l0_input_file, $
                   directory = directory, xxx=xxx, _extra = _extra

;Run in Z buffer
  set_plot,'z'
;First load the data
  If(keyword_set(l0_input_file)) Then Begin
     filex = file_search(l0_input_file[0])
  Endif Else Begin
     filex = mvn_l0_db2file(date)
  Endelse
  If(~is_string(filex)) Then Begin
     dprint, 'No Input file available: '
     If(keyword_set(l0_input_file)) Then Begin
        dprint, l0_input_file[0]
     Endif Else Begin
        dprint, time_string(date)
     Endelse
     Return
  Endif
  If(~keyword_set(noload_data)) Then Begin
;I need a timespan here
     p1  = strsplit(file_basename(filex), '_',/extract)
     d0 = time_double(time_string(p1[4]))
     timespan, d0, 1
;     mvn_sta_gen_ql, file = filex ;, pathname=file_dirname(filex), file=file_basename(filex)
  Endif

  datein = time_string(date)
  yyyy = strmid(datein, 0, 4)
  mmmm = strmid(datein, 5, 2)
  If(keyword_set(directory)) Then Begin
     dir_out = directory 
     If(keyword_set(xxx)) Then Begin
        dir_out = dir_out+yyyy+'/'+mmmm+'/'
     Endif
  Endif Else Begin
     dir_out = '/disks/data/maven/pfp/sta/l2/'
     dir_out = dir_out+yyyy+'/'+mmmm+'/' 
  Endelse
  If(~is_string(file_search(dir_out))) Then file_mkdir, dir_out

;load l0 data
  mvn_sta_l0_load, files = filex

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

;Write the files
  Print, '2A'
  mvn_sta_cmn_2a_l2gen, mvn_2a_dat, directory = dir_out, _extra = _extra
  Print, 'C0'
  mvn_sta_cmn_l2gen, mvn_c0_dat, directory = dir_out, _extra = _extra
  Print, 'C2'
  mvn_sta_cmn_l2gen, mvn_c2_dat, directory = dir_out, _extra = _extra
  Print, 'C4'
  mvn_sta_cmn_l2gen, mvn_c4_dat, directory = dir_out, _extra = _extra
  Print, 'C6'
  mvn_sta_cmn_l2gen, mvn_c6_dat, directory = dir_out, _extra = _extra
  Print, 'C8'
  mvn_sta_cmn_l2gen, mvn_c8_dat, directory = dir_out, _extra = _extra
  Print, 'CA'
  mvn_sta_cmn_l2gen, mvn_ca_dat, directory = dir_out, _extra = _extra
  Print, 'CC'
  mvn_sta_cmn_l2gen, mvn_cc_dat, directory = dir_out, _extra = _extra
  Print, 'CD'
  mvn_sta_cmn_l2gen, mvn_cd_dat, directory = dir_out, _extra = _extra
  Print, 'CE'
  mvn_sta_cmn_l2gen, mvn_ce_dat, directory = dir_out, _extra = _extra
  Print, 'CF'
  mvn_sta_cmn_l2gen, mvn_cf_dat, directory = dir_out, _extra = _extra
  Print, 'D0'
  mvn_sta_cmn_l2gen, mvn_d0_dat, directory = dir_out, _extra = _extra
  Print, 'D1'
  mvn_sta_cmn_l2gen, mvn_d1_dat, directory = dir_out, _extra = _extra
  Print, 'D2'
  mvn_sta_cmn_l2gen, mvn_d2_dat, directory = dir_out, _extra = _extra
  Print, 'D3'
  mvn_sta_cmn_l2gen, mvn_d3_dat, directory = dir_out, _extra = _extra
  Print, 'D4'
  mvn_sta_cmn_l2gen, mvn_d4_dat, directory = dir_out, _extra = _extra
;  Print, 'D6'
;  mvn_sta_cmn_d6_l2gen, mvn_d6_dat, directory = dir_out, _extra = _extra
;  Print, 'D7'
;  mvn_sta_cmn_d7_l2gen, mvn_d7_dat, directory = dir_out, _extra = _extra
  Print, 'D8'
  mvn_sta_cmn_d89a_l2gen, mvn_d8_dat, directory = dir_out, _extra = _extra
  Print, 'D9'
  mvn_sta_cmn_d89a_l2gen, mvn_d9_dat, directory = dir_out, _extra = _extra
  Print, 'DA'
  mvn_sta_cmn_d89a_l2gen, mvn_da_dat, directory = dir_out, _extra = _extra
  Print, 'DB'
  mvn_sta_cmn_db_l2gen, mvn_db_dat, directory = dir_out, _extra = _extra

End

