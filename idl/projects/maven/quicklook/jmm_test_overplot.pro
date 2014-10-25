;date = ['2014-03-19', '2014-03-20', '2014-03-21', '2014-03-26', '2014-03-30', '2014-04-15', '2014-04-21']
;date = '2014-05-26'
;date = '2014-07-16'
;date = '2014-09-23'
date = '2014-10-19'
For j = 0, n_elements(date)-1 Do Begin
   filex = mvn_l0_db2file(date[j])
   mvn_over_shell, l0_input_file = filex, $
                   plot_dir = '~/public_html/maven/test_overplot/', $
                   /date_only, device = 'z'
Endfor

End
