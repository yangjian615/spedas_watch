;; mvn_mag_batch  - to be run from a cron job

;;---------------------------------------------
;; Create 32Hz IDL .sav files for level 1 and 2
mvn_mag_gen_sav,init=1, coord='pl'
mvn_mag_gen_sav,init=1, coord='ss'
mvn_mag_gen_sav,init=1, coord='sc'

;;---------------------------------------------
;; Create 1 second binning for level 1 and 2
;path = 'maven/data/sci/mag/l1/sav/$RES/YYYY/MM/mvn_mag_l1_pl_full_YYYYMMDD.sav'
;mvn_save_reduce_timeres,init=1,resstr='1sec',verbose=1

path = 'maven/data/sci/mag/l1/sav/$RES/YYYY/MM/mvn_mag_l2_pl_full_YYYYMMDD.sav'
mvn_save_reduce_timeres,init=1,resstr='1sec',verbose=1

path = 'maven/data/sci/mag/l1/sav/$RES/YYYY/MM/mvn_mag_l2_ss_full_YYYYMMDD.sav'
mvn_save_reduce_timeres,init=1,resstr='1sec',verbose=1

path = 'maven/data/sci/mag/l1/sav/$RES/YYYY/MM/mvn_mag_l2_sc_full_YYYYMMDD.sav'
mvn_save_reduce_timeres,init=1,resstr='1sec',verbose=1


;;---------------------------------------------
;; Create 30 second binning for level 1 and 2
;path = 'maven/data/sci/mag/l1/sav/$RES/YYYY/MM/mvn_mag_l1_pl_full_YYYYMMDD.sav'
;mvn_save_reduce_timeres,init=1,/mag,resstr='30sec',verbose=1

path = 'maven/data/sci/mag/l1/sav/$RES/YYYY/MM/mvn_mag_l2_pl_full_YYYYMMDD.sav'
mvn_save_reduce_timeres,init=1,/mag,resstr='30sec',verbose=1

path = 'maven/data/sci/mag/l1/sav/$RES/YYYY/MM/mvn_mag_l2_ss_full_YYYYMMDD.sav'
mvn_save_reduce_timeres,init=1,/mag,resstr='30sec',verbose=1

path = 'maven/data/sci/mag/l1/sav/$RES/YYYY/MM/mvn_mag_l2_sc_full_YYYYMMDD.sav'
mvn_save_reduce_timeres,init=1,/mag,resstr='30sec',verbose=1


exit
