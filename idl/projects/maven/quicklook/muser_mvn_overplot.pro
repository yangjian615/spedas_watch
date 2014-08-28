date = ['2014-03-19', '2014-03-20', '2014-03-21']
;date = '2014-03-19'
For j = 0, n_elements(date)-1 Do Begin
   filex = mvn_l0_db2file(date)
   mvn_over_shell, l0_input_file = filex, $
                   plot_dir = '/disks/data/maven/data/sci/', $
;                   plot_dir = '~/public_html/maven/test_overplot/', $
                   /direct_to_dbase, /date_only, $
                   instr_to_process = ['over', 'lpw','mag','sep', 'sta','swe', 'swia']
Endfor

End
