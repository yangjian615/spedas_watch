pro restore_plot_state,ps

if !d.name eq 'X' || !d.name eq 'WIN' then wset, ps.d.window
!p = ps.p
!x = ps.x
!y = ps.y
!z = ps.z

end
