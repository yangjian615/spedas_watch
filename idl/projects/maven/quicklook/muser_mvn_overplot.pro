;date = ['2014-03-19', '2014-03-20', '2014-03-21']
;date = '2014-03-19'
;date = ['2014-09-22', '2014-09-23', '2014-09-24']
date = ['2014-10-17', '2014-10-18', '2014-10-19']
For j = 0, n_elements(date)-1 Do Begin
   filex = mvn_l0_db2file(date)
   mvn_over_shell, l0_input_file = filex, /date_only, instr_to_process = ['over']
Endfor

End
