


; *** WARNING: THM_CRIB_SCPOT2DENS is under development.  Contact J. McFadden (mcfadden@ssl.berkeley.edu) or M. Feuerstein (Michael@igpp.ucla.edu) with
; questions about quality of output.
;
message, /info, '*** WARNING: THM_CRIB_SCPOT2DENS is under development.'+ $
  '  Contact J. McFadden (mcfadden@ssl.berkeley.edu) or M. Feuerstein (Michael@igpp.ucla.edu) with questions about quality of output.'
message, /info, "Enter '.c' to continue."
stop


; Pick time span and probe:
;
timespan, '2007-7-20
probe = 'c'


; Load data:
;
thm_load_esa, probe=probe, datat=' peer_avgtemp pe?r_density peer_sc_pot ', level=2


; Extract data:
;
get_data,'th'+probe+'_peer_density',data=d
dens_e= d.y
dens_e_time= d.x
;
get_data,'th'+probe+'_peir_density',data=d
dens_i= d.y
dens_i_time= d.x
;
get_data,'th'+probe+'_peer_sc_pot',data=d
sc_pot = d.y
sc_pot_time = d.x
;
get_data,'th'+probe+'_peer_avgtemp',data=d
Te = d.y
Te_time = d.x


; Calculate density as a function of spacecraft potential, plasma region, and probe, and store as a TPLOT variable:
;
Npot = thm_scpot2dens(sc_pot, sc_pot_time, Te, Te_time, dens_e, dens_e_time, dens_i, dens_i_time, probe)
store_data, 'th'+probe+'_Npot', data= { x: sc_pot_time, y: Npot }


; Store pseudovariable to compare densities:
;
store_data, 'density_pseudovar', data = [ 'th'+probe+'_Npot', 'th'+probe+'_peer_density', 'th'+probe+'_peir_density' ]


; Pick colors and labels:
;
options, 'th'+probe+'_peer_density', 'color', 2                   ;trace
options, 'th'+probe+'_peer_density', 'colors', 2                  ;label
options, 'th'+probe+'_peer_density', 'labels', 'Ne'
;
options, 'th'+probe+'_peir_density', 'color', 4
options, 'th'+probe+'_peir_density', 'colors', 4
options, 'th'+probe+'_peir_density', 'labels', 'Ni'
;
options, 'th'+probe+'_Npot', 'labels', 'th'+probe+'_Npot
options, 'th'+probe+'_Npot', 'colors', 0
options, 'th'+probe+'_Npot', 'color', 0
options, 'th'+probe+'_Npot', 'ylog', 1


; Plot:
;
tplot, [ 'th'+probe+'_peer_sc_pot', $
         'th'+probe+'_peer_avgtemp', $
         'density_pseudovar' $
       ], $
       title = 'Example plot from THM_CRIB_SCPOT2DENS.PRO'
timebar, 6., varname='th'+probe+'_peer_sc_pot', /databar, linestyle = 3, color = 200, thick = 2
timebar, 500., varname='th'+probe+'_peer_avgtemp', /databar, linestyle = 3, color = 200, thick = 2

message, /info, ' *** Shown in plot: '+'th'+probe+'_peer_sc_pot, '+'th'+probe+'_peer_avgtemp' + ', and Ne, Ni, and Npot traces.'

end


