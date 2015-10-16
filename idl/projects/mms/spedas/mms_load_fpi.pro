;+
; PROCEDURE:
;         mms_load_fpi
;         
; PURPOSE:
;         Load data from the Fast Plasma Investigation (FPI) onboard MMS
; 
; KEYWORDS:
;         trange:       time range of interest [starttime, endtime] with the format 
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day 
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         probes:       list of probes, valid values for MMS probes are ['1','2','3','4']. 
;                       If no probe is specified the default is probe '3'
;         level:        indicates level of data processing. fpi levels currently include 'sitl'. 
;         datatype:     currently no data types defined.
;         data_rate:    instrument data rates for MMS fpi include 'fast'. 
;         local_data_dir: local directory to store the CDF files; should be set if
;                       you're on *nix or OSX, the default currently assumes Windows (c:\data\mms\)
;         source:       specifies a different system variable. By default the MMS mission system 
;                       variable is !mms
;         get_support_data: not yet implemented. when set this routine will load any support data
;                       (support data is specified in the CDF file)
;         tplotnames:   names for tplot variables
;         no_color_setup: don't setup graphics configuration; use this keyword when you're 
;                       using  this load routine from a terminal without an X server runningdo 
;                       not set colors
;         time_clip:    clip the data to the requested time range; note that if you do not use 
;                       this keyword you may load a longer time range than requested
;         no_update:    set this flag to preserve the original data. if not set and newer 
;                       data is found the existing data will be overwritten
;         suffix:       appends a suffix to the end of the tplot variable name. this is useful for
;                       preserving original tplot variable.
; 
; 
; EXAMPLE:
;     See crib sheets mms_load_fpi_crib, mms_load_fpi_burst_crib, and mms_load_fpi_crib_qlplots
;     for usage examples
; 
;     MMS>  timespan, '2015-09-19', 1d
;     load fpi burst mode data
;     MMS>  mms_load_fpi, probes = ['1'], level='l1b', data_rate='brst', datatype='des-moms'
;     
;     load fast mode data
;     MMS>  mms_load_fpi, probes = '3', level='sitl', data_rate='fast', datatype='*'
;
; NOTES:
;     Please see the notes in mms_load_data for more information 
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-10-15 15:59:10 -0700 (Thu, 15 Oct 2015) $
;$LastChangedRevision: 19085 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/mms_load_fpi.pro $
;-

function mms_fpi_angles
    return, [0,6,12,18, $
            24,30,36,42,48,54,60,66,72,78,84,90,96,102, $
            108,114,120,126,132,138,144,150,156,162,168,174] + 3
end

function mms_fpi_energies, species
    if undefined(species) || (species ne 'ion' && species ne 'electron') then begin
        dprint, dlevel = 1, "Error, species type ('ion' or 'electron') required for FPI energies"
        return, -1
    endif

    des_energies = [11.66161217, $
        14.95286673, $
        19.17301144, $
        24.58420677, $
        31.52260272, $
        40.41922083, $
        51.82672975, $
        66.45377773, $
        85.20901465, $
        109.2575384, $
        140.0932726, $
        179.63177, $
        230.3292099, $
        295.3349785, $
        378.6873127, $
        485.5641602, $
        622.6048397, $
        798.322484, $
        1023.632885, $
        1312.532598, $
        1682.968421, $
        2157.952275, $
        2766.99073, $
        3547.917992, $
        4549.246205, $
        5833.179086, $
        7479.476099, $
        9590.4072, $
        12297.10598, $
        15767.71584, $
        20217.83525, $
        25923.91101]
    
    dis_energies = [11.32541789, $
        14.54730661, $
        18.68576787, $
        24.00155096, $
        30.82958391, $
        39.60007608, $
        50.86562406, $
        65.33602881, $
        83.92301755, $
        107.7976884, $
        138.4642969, $
        177.8550339, $
        228.4517655, $
        293.4424065, $
        376.9217793, $
        484.1496135, $
        621.8819424, $
        798.7967759, $
        1026.04087, $
        1317.932043, $
        1692.861289, $
        2174.451528, $
        2793.045997, $
        3587.62007, $
        4608.236949, $
        5919.201968, $
        7603.114233, $
        9766.070893, $
        12544.35193, $
        16113.00665, $
        20696.88294, $
        26584.79405]

    if species eq 'ion' then return, dis_energies else return, des_energies
end

pro mms_load_fpi_fix_angles, tplotnames, prefix = prefix
    if undefined(prefix) then prefix = 'mms1'
    fpi_angles = mms_fpi_angles()

    spectra_where = strmatch(tplotnames, prefix + '_fpi_?PitchAngDist_*En')

    if n_elements(spectra_where) ne 0 then begin
        for var_idx = 0, n_elements(tplotnames)-1 do begin
            if spectra_where[var_idx] ne 0 then begin
                get_data, tplotnames[var_idx], data=fpi_d, dlimits=dl
                if is_struct(fpi_d) then begin
                    ; set some metadata before saving
                    en = strsplit(tplotnames[var_idx], '_', /extract)
                    en = en[n_elements(strsplit(tplotnames[var_idx], '_', /extract))-1]
                    options, tplotnames[var_idx], ysubtitle='[deg]'
                    options, tplotnames[var_idx], ytitle=strupcase(prefix)+'!C'+en+'!CPAD'
                    options, tplotnames[var_idx], ztitle='Counts'
                    zlim, tplotnames[var_idx], 0, 0, 1
                    store_data, tplotnames[var_idx], data={x: fpi_d.X, y:fpi_d.Y, v: fpi_angles}, dlimits=dl
                endif
            endif
        endfor
    endif
end
pro mms_load_fpi_fix_spectra, tplotnames, prefix = prefix
    if undefined(prefix) then prefix = 'mms1'

    spectra_where = strmatch(tplotnames, prefix + '_fpi_?EnergySpectr_??')

    if n_elements(spectra_where) ne 0 then begin
        for var_idx = 0, n_elements(tplotnames)-1 do begin
            if spectra_where[var_idx] ne 0 then begin
                get_data, tplotnames[var_idx], data=fpi_d, dlimits=dl
                if is_struct(fpi_d) then begin
                    ; set some metadata before saving
                    options, tplotnames[var_idx], ysubtitle='[keV]'
                    
                    ; get the direction and species from the variable name
                    spec_pieces = strsplit(tplotnames[var_idx], '_', /extract)
                    part_direction = (spec_pieces)[n_elements(spec_pieces)-1]
                    species = strmid(spec_pieces[2], 0, 1)
                    species = species eq 'e' ? 'electron' : 'ion'
                    fpi_energies = mms_fpi_energies(species)
                    
                    options, tplotnames[var_idx], ytitle=strupcase(prefix)+'!C'+species+'!C'+part_direction
                    options, tplotnames[var_idx], ysubtitle='[keV]'
                    options, tplotnames[var_idx], ztitle='Counts'
                    ylim, tplotnames[var_idx], 0, 0, 1
                    zlim, tplotnames[var_idx], 0, 0, 1
                    
                    store_data, tplotnames[var_idx], data={x: fpi_d.X, y:fpi_d.Y, v: fpi_energies}, dlimits=dl
                endif
            endif
        endfor
    endif
end

pro mms_load_fpi_calc_omni, probe, autoscale = autoscale
    if undefined(autoscale) then autoscale = 1
    species = ['i', 'e']
    species_str = ['ion', 'electron'] ; for the metadata
    for sidx=0, n_elements(species)-1 do begin
        obsstr='mms'+STRING(probe,FORMAT='(I1)')+'_fpi_'+species[sidx]
        
        ; get the energy spectra from the tplot variables
        get_data, obsstr+'EnergySpectr_pX', data=pX, dlimits=dl
        get_data, obsstr+'EnergySpectr_mX', data=mX, dlimits=dl
        get_data, obsstr+'EnergySpectr_pY', data=pY, dlimits=dl
        get_data, obsstr+'EnergySpectr_mY', data=mY, dlimits=dl
        get_data, obsstr+'EnergySpectr_pZ', data=pZ, dlimits=dl
        get_data, obsstr+'EnergySpectr_mZ', data=mZ, dlimits=dl
        
        ; skip avg/sum when we can't find the tplot names
        if ~is_struct(pX) || ~is_struct(mX) || ~is_struct(pY) || ~is_struct(mY) || ~is_struct(pZ) || ~is_struct(mZ) then continue
        
        e_omni_sum=(pX.Y+mX.Y+pY.Y+mY.Y+pZ.Y+mZ.Y)
        e_omni_avg=e_omni_sum/6.0

        if is_array(e_omni_sum) then begin
            store_data, obsstr+'EnergySpectr_omni_avg', data = {x:pX.X, y:e_omni_avg, v:pX.V}, dlimits=dl
            store_data, obsstr+'EnergySpectr_omni_sum', data = {x:pX.X, y:e_omni_sum, v:pX.V}, dlimits=dl
        endif
    
        ; set the metadata for omnidirectional spectra
        options, obsstr+'EnergySpectr_omni_sum', ytitle='MMS'+STRING(probe,FORMAT='(I1)')+'!C'+species_str[sidx]+'!Csum'
        options, obsstr+'EnergySpectr_omni_avg', ytitle='MMS'+STRING(probe,FORMAT='(I1)')+'!C'+species_str[sidx]+'!Cavg'
        options, obsstr+'EnergySpectr_omni_sum', ysubtitle='[keV]'
        options, obsstr+'EnergySpectr_omni_avg', ysubtitle='[keV]'
        options, obsstr+'EnergySpectr_omni_sum', ztitle='Counts'
        options, obsstr+'EnergySpectr_omni_avg', ztitle='Counts'
        ylim, obsstr+'EnergySpectr_omni_avg', min(pX.V), max(pX.V), 1
        if autoscale then zlim, obsstr+'EnergySpectr_omni_avg', 0, 0, 1 else $
            zlim, obsstr+'EnergySpectr_omni_avg', min(e_omni_avg), max(e_omni_avg), 1
        ylim, obsstr+'EnergySpectr_omni_sum', min(pX.V), max(pX.V), 1
        if autoscale then zlim, obsstr+'EnergySpectr_omni_sum', 0, 0, 1 else $
            zlim, obsstr+'EnergySpectr_omni_sum', min(e_omni_sum), max(e_omni_sum), 1
            
        ; if autoscale isn't set, set the scale to the min/max of the average
        if ~autoscale then zlim, obsstr+'EnergySpectr_'+['pX', 'mX', 'pY', 'mY', 'pZ', 'mZ'], min(e_omni_avg), max(e_omni_avg), 1
    endfor
end

pro mms_load_fpi_calc_pad, probe, autoscale = autoscale
    if undefined(autoscale) then autoscale = 1
    species = ['i', 'e']
    species_str = ['ion', 'electron'] ; for the metadata
    for sidx=0, n_elements(species)-1 do begin
        obsstr='mms'+STRING(probe,FORMAT='(I1)')+'_fpi_'+species[sidx]
        
        ; get the PAD from the tplot variables
        get_data, obsstr+'PitchAngDist_lowEn', data=lowEn, dlimits=dl
        get_data, obsstr+'PitchAngDist_midEn', data=midEn, dlimits=dl
        get_data, obsstr+'PitchAngDist_highEn', data=highEn, dlimits=dl
        
        ; skip avg/sum when we can't find the tplot names
        if ~is_struct(lowEn) || ~is_struct(midEn) || ~is_struct(highEn) then continue

        e_PAD_sum=(lowEn.Y+midEn.Y+highEn.Y)
        e_PAD_avg=e_PAD_sum/3.0

        if is_array(e_PAD_sum) then begin
            store_data, obsstr+'PitchAngDist_sum', data = {x:lowEn.X, y:e_PAD_sum, v:lowEn.V}, dlimits=dl
            store_data, obsstr+'PitchAngDist_avg', data = {x:lowEn.X, y:e_PAD_avg, v:lowEn.V}, dlimits=dl
        endif
        
        ; set the metadata for the PADs
        options, obsstr+'PitchAngDist_sum', ytitle='MMS'+STRING(probe,FORMAT='(I1)')+'!C'+species_str[sidx]+'!CPAD!Csum'
        options, obsstr+'PitchAngDist_avg', ytitle='MMS'+STRING(probe,FORMAT='(I1)')+'!C'+species_str[sidx]+'!CPAD!Cavg'
        options, obsstr+'PitchAngDist_sum', ysubtitle='[deg]'
        options, obsstr+'PitchAngDist_avg', ysubtitle='[deg]'
        options, obsstr+'PitchAngDist_sum', ztitle='Counts'
        options, obsstr+'PitchAngDist_avg', ztitle='Counts'
        if autoscale then zlim, obsstr+'PitchAngDist_avg', 0, 0, 1 else $
            zlim, obsstr+'PitchAngDist_avg', min(e_PAD_avg), max(e_PAD_avg), 1
        ylim, obsstr+'PitchAngDist_avg', 0, 180, 0
        if autoscale then zlim, obsstr+'PitchAngDist_sum', 0, 0, 1 else $
            zlim, obsstr+'PitchAngDist_sum', min(e_PAD_sum), max(e_PAD_sum), 1
        ylim, obsstr+'PitchAngDist_sum', 0, 180, 0
        
        if ~autoscale then zlim, obsstr+'PitchAngDist_'+['lowEn', 'midEn', 'highEn'], min(e_PAD_avg), max(e_PAD_avg), 1
    endfor
end

pro mms_load_fpi, trange = trange, probes = probes, datatype = datatype, $
                  level = level, data_rate = data_rate, $
                  local_data_dir = local_data_dir, source = source, $
                  get_support_data = get_support_data, $
                  tplotnames = tplotnames, no_color_setup = no_color_setup, $
                  time_clip = time_clip, no_update = no_update, suffix = suffix, $
                  autoscale = autoscale

    if undefined(trange) then trange = timerange() else trange = timerange(trange)
    if undefined(probes) then probes = ['3'] ; default to MMS 3
    if undefined(datatype) then datatype = '*' ; grab all data in the CDF
    if undefined(level) then level = 'sitl' 
    if undefined(data_rate) then data_rate = 'fast'
    if undefined(autoscale) then autoscale = 1
      
    mms_load_data, trange = trange, probes = probes, level = level, instrument = 'fpi', $
        data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
        datatype = datatype, get_support_data = get_support_data, $
        tplotnames = tplotnames, no_color_setup = no_color_setup, time_clip = time_clip, $
        no_update = no_update, suffix = suffix

    ; correct the energies in the spectra for each probe
    if ~undefined(tplotnames) && n_elements(tplotnames) ne 0 then begin
        for probe_idx = 0, n_elements(probes)-1 do begin
            mms_load_fpi_fix_spectra, tplotnames, prefix = 'mms'+strcompress(string(probes[probe_idx]), /rem)
            mms_load_fpi_fix_angles, tplotnames, prefix = 'mms'+strcompress(string(probes[probe_idx]), /rem)
            mms_load_fpi_calc_omni, probes[probe_idx], autoscale = autoscale
            mms_load_fpi_calc_pad, probes[probe_idx]
        endfor
    endif
end