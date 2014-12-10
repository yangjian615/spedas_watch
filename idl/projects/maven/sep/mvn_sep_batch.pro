;   mvn_sep_batch  - to be run from a cron job typically
!quiet = 1
dprint,print_trace=4,print_dtime=1,setdebug=2,dlevel=3
set_plot,'z'
@idl_startup
!quiet = 1
dummy = mvn_file_source(/set,verbose=1,dir_mode='775'o)
t0 = systime(1)
dprint,'Starting SEP batch job at: '+time_string(systime(1),/local)

mvn_mag_gen_l1_sav,init=1
mvn_save_reduce_timeres,init=1,/mag,resstr='1sec',verbose=1
mvn_save_reduce_timeres,init=1,/mag,resstr='30sec',verbose=1

mvn_sep_gen_plots,init=-10

t1=systime(1)
dprint,'Finished SEP batch job at: '+time_string(systime(1),/local), ' in ',(t1-t0), ' seconds.'

exit


