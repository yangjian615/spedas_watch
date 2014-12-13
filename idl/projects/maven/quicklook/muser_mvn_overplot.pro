;date = ['2014-03-19', '2014-03-20', '2014-03-21']
;date = '2014-03-19'
;date = ['2014-09-22', '2014-09-23', '2014-09-24']
;date = ['2014-10-17', '2014-10-18', '2014-10-19']
set_plot, 'z'

date = ['2014-10-23', '2014-10-21', '2014-10-20']

For j = 0, n_elements(date)-1 Do Begin
   mvn_over_shell, date=date[j], /date_only, instr_to_process = 'over'
Endfor

date = ['2014-10-22', '2014-10-19']

For j = 0, n_elements(date)-1 Do Begin
   mvn_over_shell, date=date[j], /date_only
Endfor

End

