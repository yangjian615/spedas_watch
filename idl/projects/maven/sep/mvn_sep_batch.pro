;   mvn_sep_batch  - to be run from a cron job typically
!quiet = 1
dprint,print_trace=4,print_dtime=1,setdebug=2,dlevel=3
set_plot,'z'
@idl_startup
!quiet = 1
dummy = mvn_file_source(/set,verbose=1)
dprint,'Running SEP batch job at: '+time_string(systime(1),/local)

mvn_sep_gen_plots,init=-10
exit


