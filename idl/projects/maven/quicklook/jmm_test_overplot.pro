set_plot, 'z'
date = '2015-03-28'
date = '2015-01-01'
;date = ['2015-04-22', '2015-04-23']
For j = 0, n_elements(date)-1 Do Begin
   filex = mvn_l0_db2file(date[j])
;   mvn_over_shell, l0_input_file = filex, /makepng, $
;                   plot_dir = '~/public_html/maven/test_overplot/', $
;                   device = 'z'
   mvn_over_shell, date=date[j], /multipngplot, $
                   plot_dir = '~/public_html/maven/test_overplot/', $
                   device = 'z', instr=['genl2']
Endfor

End
