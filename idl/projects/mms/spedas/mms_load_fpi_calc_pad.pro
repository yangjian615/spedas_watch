;+
; PROCEDURE:
;         mms_load_fpi_calc_pad
;
; PURPOSE:
;         Calculates the omni-directional pitch angle distribution (summed and averaged)
;         from the individual tplot variables
;
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-10-28 10:48:21 -0700 (Wed, 28 Oct 2015) $
;$LastChangedRevision: 19175 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/mms_load_fpi_calc_pad.pro $
;-
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