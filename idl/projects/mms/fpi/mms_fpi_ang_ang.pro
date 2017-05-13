;+
; PROCEDURE:
;         mms_fpi_ang_ang
;
; PURPOSE:
;         Creates various plots directly from the
;         FPI distribution functions, including:
;
;         - angle-angle (azimuth vs zenith)
;         - angle-energy (azimuth and zenith vs energy)
;         - pitch angle - energy
;
; INPUT:
;          time: exact time you'd like to see plotted
;
; KEYWORDS:
;          all_energies: generate azimuth vs zenith plots at
;              all energies, one plot for each energy
;
;          probe: probe to plot
;          energy_range: energy range to include in the
;              azimuth vs zenith plot (default: 10-30000)
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-05-12 10:57:17 -0700 (Fri, 12 May 2017) $
;$LastChangedRevision: 23309 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/fpi/mms_fpi_ang_ang.pro $
;-

pro mms_fpi_ang_ang, time, probe=probe, energy_range=energy_range, data_rate=data_rate, $
  species=species, all_energies=all_energies, subtract_bulk=subtract_bulk, pa_en_units = pa_en_units, $
  postscript=postscript, png=png, center_measurement=center_measurement, xsize=xsize, ysize=ysize

  if undefined(time) then begin
    dprint, dlevel = 0, 'Error, time required for this routine.'
    return
  endif else trange = time_double(time) + [-300., 300]
  trange_pad = time_double(time)+[0., 0.2]
  if undefined(probe) then probe = '1' else probe = strcompress(string(probe), /rem)
  if undefined(species) then species = 'e'
  if undefined(xsize) then xsize = 550
  if undefined(ysize) then ysize = 450
  if undefined(energy_range) then energy_range = [10., 30000]
  if undefined(data_rate) then data_rate = 'fast'
  if undefined(pa_en_units) then pa_en_units = 'df'

  mms_load_fpi, datatype=['d'+species+'s-dist', 'd'+species+'s-moms'], data_rate=data_rate, trange=trange, probe=probe, center_measurement=center_measurement, /time_clip
  mms_load_fgm, trange=trange, data_rate=data_rate, probe=probe

  get_data, 'mms'+probe+'_d'+species+'s_dist_'+data_rate, data=d

  if ~is_struct(d) then begin
    dprint, dlevel = 0, 'Error, no data found.'
    return
  endif

  closest_time = find_nearest_neighbor(d.X, time_double(time))
  closest_idx = where(d.X eq closest_time)
  closest_idx = closest_idx-1

  data = reform(d.Y[closest_idx, *, *, *])
  phi = reform(d.V1[closest_idx, *])
  theta = d.V2
  energies = reform(d.V3[closest_idx, *])

  idx_of_ens = where(energies ge energy_range[0] and energies le energy_range[1])
  data_at_ens = data[*, *, idx_of_ens]
  data_summed = total(data_at_ens, 3, /nan)

  dist = mms_get_dist('mms'+probe+'_d'+species+'s_dist_'+data_rate, single_time=time)

  d = *dist
  ; theta is stored as co-latitude
  theta_colat = reform(d.theta[0, 0, *])

  ; convert to latitude
  theta_flow_direction = 90-theta_colat
  phi = reform(d.phi[0, *, 0])

  if undefined(all_energies) then begin
    if ~undefined(postscript) then popen, 'azimuth_vs_zenith', /landscape else window, 1, xsize=xsize, ysize=ysize
    ; angle-angle over the energy range
    plotxyz, window=1, phi, theta_flow_direction, data_summed, /zlog, /noisotropic, xrange=[0, 360], yrange=[0, 180], $
      xtitle='Az flow angle (deg)', $
      ytitle='Zenith flow angle (deg)', $
      ztitle='f (s!U3!N/cm!U6!N)', $
      title=time_string(closest_time, tformat='YYYY-DD-MM/hh:mm:ss.fff')+' (' + strcompress(string(energy_range[0]) + '-'+string(energy_range[1]), /rem)+ ' eV)'
    if ~undefined(png) then makepng, 'azimuth_vs_zenith'
    if ~undefined(postscript) then pclose

    if ~undefined(postscript) then popen, 'zenith_vs_energy', /landscape else window, 2, xsize=xsize, ysize=ysize
    theta_en = total(data, 1)
    ; Zenith vs. energy
    plotxyz, window=2, energies, theta_flow_direction, transpose(theta_en), /noisotropic, /zlog, $
      xtitle='Energy (eV)', $
      ytitle='Zenith flow angle (deg)', $
      ztitle='f (s!U3!N/cm!U6!N)', $
      title=time_string(closest_time, tformat='YYYY-DD-MM/hh:mm:ss.fff'), $
      /xlog, yrange=[0, 180.], yticks=6
    if ~undefined(png) then makepng, 'zenith_vs_energy'
    if ~undefined(postscript) then pclose

    if ~undefined(postscript) then popen, 'azimuth_vs_energy', /landscape else window, 3, xsize=xsize, ysize=ysize
    phi_en = total(data, 2)
    ; Azimuth vs. energy
    plotxyz, window=3, energies, phi, transpose(phi_en), /noisotropic, /zlog, $
      xtitle='Energy (eV)', $
      ytitle='Azimuth flow angle (deg)', $
      ztitle='f (s!U3!N/cm!U6!N)', $
      title=time_string(closest_time, tformat='YYYY-DD-MM/hh:mm:ss.fff'), $
      /xlog, yrange=[0, 360.], yticks=6
    if ~undefined(png) then makepng, 'azimuth_vs_energy'
    if ~undefined(postscript) then pclose

    if ~undefined(subtract_bulk) then $
        pad = moka_mms_pad('mms'+probe+'_fgm_b_dmpa_'+data_rate+'_l2_bvec', 'mms'+probe+'_d'+species+'s_dist_'+data_rate, trange_pad, vname='mms'+probe+'_d'+species+'s_bulkv_dbcs_'+data_rate, subtract_bulk=subtract_bulk, units=pa_en_units) $
    else $
      pad = moka_mms_pad('mms'+probe+'_fgm_b_dmpa_'+data_rate+'_l2_bvec', 'mms'+probe+'_d'+species+'s_dist_'+data_rate, trange_pad, subtract_bulk=0, units=pa_en_units)

    window, 4
    plotxyz, pad.PA, pad.EGY, pad.DATA, /noisotropic, /ylog, /zlog, title=time_string(trange[0])+'-'+time_string(trange[1]), $
      xrange=[0,180], xtitle='Pitch angle (deg)', ytitle='Energy (eV)', ztitle=pad.units, window=4
  endif else if keyword_set(all_energies) then begin
    for en_idx=0, n_elements(idx_of_ens)-1 do begin
      window, en_idx, xsize=xsize, ysize=ysize
      data_at_this_en = reform(data[*, *, idx_of_ens[en_idx]])
      plotxyz, window=en_idx, phi, theta_flow_direction, data_at_this_en, /zlog, /noisotropic, xrange=[0, 360], yrange=[0, 180], $
        xtitle='Az flow angle (deg)', $
        ytitle='Zenith flow angle (deg)', $
        ztitle='f (s!U3!N/cm!U6!N)', $
        title=time_string(closest_time, tformat='YYYY-DD-MM/hh:mm:ss.fff') + ' (' + strcompress(string(energies[idx_of_ens[en_idx]]), /rem) + ' eV)'
      makepng, 'azimuth_vs_zenith_'+strcompress(string(energies[idx_of_ens[en_idx]]), /rem)
    endfor
  endif

end

