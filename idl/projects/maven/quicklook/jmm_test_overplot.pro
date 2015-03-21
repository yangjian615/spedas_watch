set_plot, 'z'
date = '2015-02-22'
For j = 0, n_elements(date)-1 Do Begin
   filex = mvn_l0_db2file(date[j])
   mvn_over_shell, l0_input_file = filex, /makepng, $
                   plot_dir = '~/public_html/maven/test_overplot/', $
                   device = 'z'
Endfor

End
