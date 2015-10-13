;+
; PROCEDURE:
;         mms_load_eis
;         
; PURPOSE:
;         Load data from the MMS Energetic Ion Spectrometer (EIS)
; 
; KEYWORDS:
;         trange:       time range of interest [starttime, endtime] with the format
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         probes:       list of probes, valid values for MMS probes are ['1','2','3','4'].
;                       if no probe is specified the default is probe '1'
;         level:        indicates level of data processing. levels include 'l1a', 'l1b'. 
;                       The default if no level is specified is 'l1b'
;         datatype:     eis data types include ['electronenergy', 'extof', 'partenergy', 'phxtof'].
;                       If no value is given the default is 'extof'.
;         data_rate:    instrument data rates for eis include 'brst' 'srvy'. The
;                       default is 'srvy'.
;         data_units:   desired units for data. for eis units are ['flux', 'cps', 'counts']. 
;                       The default is 'flux'.
;         local_data_dir: local directory to store the CDF files; should be set if
;                       you're on *nix or OSX, the default currently assumes Windows (c:\data\mms\)
;         source:       specifies a different system variable. By default the MMS mission 
;                       system variable is !mms
;         get_support_data: not yet implemented. when set this routine will load any support data
;                       (support data is specified in the CDF file)
;         tplotnames:   names for tplot variables
;         no_color_setup: don't setup graphics configuration; use this keyword when you're 
;                       using this load routine from a terminal without an X server runningdo 
;                       not set colors
;         time_clip:    clip the data to the requested time range; note that if you do not use 
;                       this keyword you may load a longer time range than requested
;         no_update:    set this flag to preserve the original data. if not set and newer 
;                       data is found the existing data will be overwritten
;         no_interp:    if this flag is set no interpolation of the data will occur.
;         suffix:       appends a suffix to the end of the tplot variable name. this is useful for
;                       preserving original tplot variable.
;
; 
; OUTPUT:
; 
; 
; EXAMPLE:
;     See crib sheets mms_load_eis_crib.pro, mms_load_eis_burst_crib.pro, 
;         mms_load_eis_crib_qlplots.pro, and mms_load_data_crib.pro for usage examples
; 
;     load ExTOF burst data:
;     MMS1> mms_load_eis, probes='1', trange=['2015-08-23', '2015-08-24'], $
;            datatype='extof', data_rate='brst', level='l1b'
;            
;     load PHxTOF data:
;     MMS1> mms_load_eis, probes='1', trange=['2015-07-31', '2015-08-01'], datatype='phxtof'
;     calculate the PHxTOF PAD for protons
;     MMS1> mms_eis_pad, probe='1', species='ion', datatype='phxtof', ion_type='proton', data_units='flux', energy=[0, 30]
;
; NOTES:
;     Please see the notes in mms_load_data for more information 
;
; HISTORY:
;     9/15/2015 - Ian Cohen at APL: added modifications to omni-directional calculations to be able to handle 
;                 ExTOF and PHxTOF data
;     9/17/2015 - egrimes: large update, see svn log
;
;$LastChangedBy: crussell $
;$LastChangedDate: 2015-10-12 13:54:05 -0700 (Mon, 12 Oct 2015) $
;$LastChangedRevision: 19056 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/mms_load_eis.pro $
;-

pro mms_eis_spin_avg, probe=probe, species = species, data_units = data_units, datatype = datatype, suffix=suffix
    if undefined(probe) then probe='1' else probe = strcompress(string(probe), /rem)
    if undefined(datatype) then datatype = 'extof'
    if undefined(data_units) then data_units = 'flux'
    if undefined(species) then species = 'proton'
    if undefined(suffix) then species = ''
    if datatype eq 'electronenergy' then species = 'electron'

    prefix = 'mms'+probe+'_epd_eis_'+datatype+'_'
    ; get the spin #s asscoiated with each measurement
    get_data, prefix + 'spin'+suffix, data=spin_nums

    ; find where the spins start
    spin_starts = uniq(spin_nums.Y)

    ; loop over the telescopes
    for scope_idx = 0, 5 do begin
        tn = strcompress(string(scope_idx), /rem)
        get_data, prefix + species + '_' + data_units + '_t'+tn+suffix, data=flux_data, dlimits=flux_dl
        spin_sum_flux = dblarr(n_elements(spin_starts), n_elements(flux_data.Y[0, *]))

        current_start = 0
        ; loop through the spins for this telescope
        for spin_idx = 0, n_elements(spin_starts)-1 do begin
            ; loop over energies
            ;spin_sum_flux[spin_idx, *] = total(flux_data.Y[current_start:spin_starts[spin_idx], *], 1)
            spin_sum_flux[spin_idx, *] = average(flux_data.Y[current_start:spin_starts[spin_idx], *], 1)            
            current_start = spin_starts[spin_idx]+1
        endfor
        sp = '_spin'
        store_data, prefix+species+'_'+data_units+'_t'+tn+sp+suffix, data={x: spin_nums.X[spin_starts], y: spin_sum_flux, v: flux_data.V}, dlimits=flux_dl
        options, prefix+species+'_'+data_units+'_t'+tn+sp+suffix, spec=1
        ylim, prefix+species+'_'+data_units+'_t'+tn+sp+suffix, 50., 500., 1
        zlim, prefix+species+'_'+data_units+'_t'+tn+sp+suffix, 0, 0, 1
    endfor
end

; PURPOSE:
;       Calculates the omni-directional flux for all 6 telescopes
;
; NOTES:
;       based on Brian Walsh's EIS code from 7/29/2015
;
pro mms_eis_omni, probe, species = species, datatype = datatype, tplotnames = tplotnames, suffix = suffix, data_units = data_units
    ; default to electrons
    if undefined(species) then species = 'electron'
    if undefined(datatype) then datatype = 'electronenergy'
    if undefined(suffix) then suffix = ''
    if undefined(data_units) then data_units = 'flux'
    units_label = data_units eq 'flux' ? '#/(cm!U2!N-sr-s-keV)' : 'Counts/s'
    ; 10 - 50 keV for PHxTOF data
    ; 40 - 1000 keV for ExTOF and electron data
    en_range = datatype eq 'phxtof' ?  [9., 50.] : [40., 1000.]
    
    probe = strcompress(string(probe), /rem)
    species_str = datatype+'_'+species

    get_data, 'mms'+probe+'_epd_eis_'+species_str+'_'+data_units+'_t0'+suffix, data = d, dlimits=dl
   
    if is_struct(d) then begin
        flux_omni = dblarr(n_elements(d.x),n_elements(d.v))
        for i=0, 5 do begin ; loop through each detector
            get_data, 'mms'+probe+'_epd_eis_'+species_str+'_'+data_units+'_t'+STRTRIM(i, 1)+suffix, data = d
            flux_omni = flux_omni + d.Y
        endfor
        newname = 'mms'+probe+'_epd_eis_'+species_str+'_'+data_units+'_omni'+suffix
        store_data, newname, data={x:d.x, y:flux_omni/6., v:d.v}, dlimits=dl

        options, newname, ylog = 1, spec = 1, yrange = en_range, zlog = 1, $
            ytitle = 'MMS'+probe+' EIS '+species, ysubtitle='Energy [keV]', ztitle=units_label, ystyle=1, /default
        append_array, tplotnames, newname
        ; degap the data
        tdegap, newname, /overwrite
    endif
end

pro mms_load_eis, trange = trange, probes = probes, datatype = datatype, $
                  level = level, data_rate = data_rate, data_units = data_units, $
                  local_data_dir = local_data_dir, source = source, $
                  get_support_data = get_support_data, $
                  tplotnames = tplotnames, no_color_setup = no_color_setup, $
                  time_clip = time_clip, no_update = no_update, no_interp = no_interp, $
                  suffix = suffix

    if undefined(trange) then trange = timerange() else trange = timerange(trange)
    if undefined(probes) then probes = ['1'] ; default to MMS 1
    if undefined(datatype) then datatype = 'extof'
    if undefined(level) then level = 'l1b' 
    if undefined(data_rate) then data_rate = 'srvy'
    if undefined(data_units) then data_units = 'flux'
    if undefined(suffix) then suffix = ''

    mms_load_data, trange = trange, probes = probes, level = level, instrument = 'epd-eis', $
        data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
        datatype = datatype, get_support_data = get_support_data, $
        tplotnames = tplotnames, no_color_setup = no_color_setup, time_clip = time_clip, $
        no_update = no_update, suffix = suffix
    
    ; calculate the omni-directional quantities
    for probe_idx = 0, n_elements(probes)-1 do begin
        ;try both ions and electrons in case multiple datatypes were loaded
        if (datatype eq 'electronenergy') then begin
          mms_eis_spin_avg, probe=probes[probe_idx], datatype=datatype, species='electron', data_units = data_units, suffix=suffix
          mms_eis_omni, probes[probe_idx], species='electron', datatype='electronenergy', tplotnames = tplotnames, suffix = '_spin'+suffix, data_units = data_units
        endif
        if (datatype eq 'extof') then begin
          mms_eis_spin_avg, probe=probes[probe_idx], datatype=datatype, species='proton', data_units = data_units, suffix=suffix
          mms_eis_spin_avg, probe=probes[probe_idx], datatype=datatype, species='oxygen', data_units = data_units, suffix=suffix
          mms_eis_spin_avg, probe=probes[probe_idx], datatype=datatype, species='alpha', data_units = data_units, suffix=suffix
          mms_eis_omni, probes[probe_idx], species='proton', datatype='extof',tplotnames = tplotnames, suffix = '_spin'+suffix, data_units = data_units
          mms_eis_omni, probes[probe_idx], species='alpha', datatype='extof',tplotnames = tplotnames, suffix = '_spin'+suffix, data_units = data_units
          mms_eis_omni, probes[probe_idx], species='oxygen', datatype='extof',tplotnames = tplotnames, suffix = '_spin'+suffix, data_units = data_units
        endif
        if (datatype eq 'phxtof') then begin
          mms_eis_spin_avg, probe=probes[probe_idx], datatype=datatype, species='proton', data_units = data_units, suffix=suffix
          mms_eis_spin_avg, probe=probes[probe_idx], datatype=datatype, species='oxygen', data_units = data_units, suffix=suffix
          mms_eis_omni, probes[probe_idx], species='proton', datatype='phxtof',tplotnames = tplotnames, suffix = '_spin'+suffix, data_units = data_units
          mms_eis_omni, probes[probe_idx], species='oxygen', datatype='phxtof',tplotnames = tplotnames, suffix = '_spin'+suffix, data_units = data_units
        endif  
    endfor
    if undefined(no_interp) && data_rate eq 'srvy' then options, '*_omni_spin*', no_interp=0, y_no_interp=0
end