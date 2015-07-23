pro mvn_sta_sc_bins_load_crib

  time = ['2015-03-08','2015-03-09']  
  timespan, time_double(time)
  mk = mvn_spice_kernels(/all,/load,trange=timerange())
  mvn_sta_l2_load;, sta_apid=['c8','ca']
  mvn_sta_sc_bins_load, perc_block=0.5 ;;50% or more blockage
  stop


end




