;+ 
; MMS FPI crib sheet for Quicklook plots
; do you have suggestions for this crib sheet?  
;   please send them to egrimes@igpp.ucla.edu
; 
; History:
; egrimes updated 12/9/2015, changed to GSM coordinates, adding 
;     support for l2pre, switched to use QL data instead of SITL
; egrimes updated 23Sep2015, to set some metadata for spectra/PADs
; egrimes updated 8Sept2015
; BGILES UPDATED 1Sept2015
; BGILES UPDATED 31AUGUST2015
; 
; $LastChangedBy: egrimes $
; $LastChangedDate: 2015-12-11 11:34:54 -0800 (Fri, 11 Dec 2015) $
; $LastChangedRevision: 19607 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/mms_load_fpi_crib_qlplots.pro $
;-

start_time = systime(/seconds)

;preparations and defaults
;date = '15-10-06/00:00:00'
;date = '15-9-01/00:00:00'

; full day for FS
;date = '2015-11-13/00:00:00'
date = '2015-9-1/00:00:00'
timespan, date, 1, /day
data_rate = 'fast'

; small interval for burst
;date = '2015-11-13/4:50
;timespan, date, 10, /min
;data_rate = 'brst'

probes = [1, 2, 3, 4]
datatype = '*' ; grab all data in the CDF
;level = 'sitl'
level = 'ql'
autoscale = 1
iw=0
width = 650
height = 750

; options for send_plots_to:
;   ps: postscript files
;   png: png files
;   win: creates/opens all of the tplot windows

send_plots_to = 'win'
plot_directory = ''

postscript = send_plots_to eq 'ps' ? 1 : 0

tplot_options,'xmargin',[15,15]              ; Set left/right margins to 10 characters
;tplot_options,'ymargin',[4,2]                ; Set top/bottom margins to 4/2 lines

; handle any errors that occur in this script gracefully
catch, errstats
if errstats ne 0 then begin
    error = 1
    dprint, dlevel=1, 'Error: ', !ERROR_STATE.MSG
    catch, /cancel
endif

;load data for all 4 probes
mms_load_fpi, trange = trange, probes = probes, datatype = datatype, $
    level = level, data_rate = data_rate, $
    local_data_dir = local_data_dir, source = source, $
    get_support_data = get_support_data, $
    tplotnames = tplotnames, no_color_setup = no_color_setup, $
    autoscale = autoscale

; load ephemeris data for all 4 probes
;mms_load_state, trange = trange, probes = probes, /ephemeris

; load DFG data for all 4 probes
;mms_load_dfg, trange = trange, probes = probes, level = 'ql', /no_attitude_data
mms_load_fgm, trange = trange, probes = probes, /no_attitude_data, level = dfg_level

FOR i=1,n_elements(probes) DO BEGIN    ;step through the observatories
   ; obsstr='mms'+STRING(i,FORMAT='(I1)')+'_fpi_'
    obsstr='mms'+STRING(i,FORMAT='(I1)')+'_'
    
    ;SET UP TPLOT VARIABLES

    ; ephemeris data is loaded in with J2000 coordinates, need
    ; to cotrans to GSM
    ;spd_cotrans, 'mms'+STRING(i,FORMAT='(I1)')+'_defeph_pos', $
    ;    'mms'+STRING(i,FORMAT='(I1)')+'_defeph_pos_gsm', in_coord='j2000',$
    ;    out_coord='gsm', /ignore_dlimits
         
    ; convert the position data into Re
   ; eph_variable = 'mms'+strcompress(string(i), /rem)+'_defeph_pos'
    if dfg_level eq 'l2pre' then begin
        eph_variable = 'mms'+strcompress(string(i), /rem)+'_pos_gsm'
        b_variable = '_dfg_srvy_l2pre_gsm'
        suffix_kludge = ['0', '1', '2'] ; because the suffix is different depending on the level...
    endif else begin
        eph_variable = 'mms'+strcompress(string(i), /rem)+'_ql_pos_gsm'
        b_variable = '_dfg_srvy_gsm'
        suffix_kludge = ['x', 'y', 'z'] ; because the suffix is different depending on the level...
    endelse
   ; eph_variable = 'mms'+strcompress(string(i), /rem)+'_dfg_srvy_gsm_dmpa'
    calc,'"'+eph_variable+'_re" = "'+eph_variable+'"/6371.2'
    
    ; split the position into its components
    split_vec, eph_variable+'_re'
    
    ; set the label to show along the bottom of the tplot
    options, eph_variable+'_re_'+suffix_kludge[0],ytitle='X-GSM (Re)'
    options, eph_variable+'_re_'+suffix_kludge[1],ytitle='Y-GSM (Re)'
    options, eph_variable+'_re_'+suffix_kludge[2],ytitle='Z-GSM (Re)'
    ;position_vars = [eph_variable+'_re_'+suffix_kludge[0], eph_variable+'_re_'+suffix_kludge[1], eph_variable+'_re_'+suffix_kludge[2]]
    position_vars = [eph_variable+'_re_'+suffix_kludge[2], eph_variable+'_re_'+suffix_kludge[1], eph_variable+'_re_'+suffix_kludge[0]]

    ; Data quality bar
    qual_bar = mms_quality_bar(obsstr+'dataQuality')
    
    ; combine bent pipe B DSC into a single tplot variable
    prefix = 'mms'+strcompress(string(i), /rem)
    ;split_vec, prefix+'_dfg_srvy_gse_bvec'
    split_vec, prefix+b_variable+'_bvec'
    
    ; time clip the data to -150nT to 150nT
    tclip, prefix+b_variable+'_bvec_?', -150, 150, /overwrite
    tclip, prefix+b_variable+'_btot', -150, 150, /overwrite
    
    store_data, prefix+'_dfg_gsm_srvy', data=prefix+[b_variable+'_bvec'+['_x', '_y', '_z'], b_variable+'_btot']
    options, prefix+'_dfg_gsm_srvy', labflag=-1
    options, prefix+'_dfg_gsm_srvy', labels=['Bx', 'By', 'Bz', 'Bmag']
    options, prefix+'_dfg_gsm_srvy', colors=[2, 4, 6, 0]
    options, prefix+'_dfg_gsm_srvy', ytitle=prefix+'!CFGM!CGSM'
    
    ; combine the densities into one tplot variable
    ;join_vec, [obsstr+'DESnumberDensity', obsstr+'DISnumberDensity'], obsstr+'numberDensity'
    join_vec, [obsstr+'des_numberDensity', obsstr+'dis_numberDensity'], obsstr+'numberDensity'
    options, obsstr+'des_numberDensity', 'labels', 'Ne, electrons'
    options, obsstr+'dis_numberDensity', 'labels', 'Ni, ions'
    options, obsstr+'des_numberDensity', 'colors', 2
    options, obsstr+'dis_numberDensity', 'colors', 4
   ; options, obsstr+'numberDensity', 'labels', ['electrons', 'ions']
   ; options, obsstr+'numberDensity', 'labflag', -1
   ; options, obsstr+'numberDensity', 'colors', [2, 4]
    
    ; combine the bulk electron velocities into one tplot variable
    get_data, obsstr+'des_bulkX', xtimes, bulkx
    get_data, obsstr+'des_bulkY', xtimes, bulky
    get_data, obsstr+'des_bulkZ', xtimes, bulkz
    e_bulk_mag=SQRT(bulkx^2+bulky^2+bulkz^2)
    store_data, obsstr+'eBulkV_mag_DSC', data = {x:xtimes, y:e_bulk_mag}
    join_vec, [obsstr+'des_bulkX', obsstr+'des_bulkY', obsstr+'des_bulkZ', obsstr+'eBulkV_mag_DSC'], obsstr+'eBulkV_DSC'
    options, obsstr+'eBulkV_DSC', 'labels', ['Vx', 'Vy', 'Vz', 'Vmag']
    options, obsstr+'eBulkV_DSC', 'labflag', -1
    options, obsstr+'eBulkV_DSC', 'colors', [2, 4, 6, 8]
    options, obsstr+'eBulkV_DSC', 'ytitle', 'MMS'+STRING(i,FORMAT='(I1)')+'!CeBulkV!CDSC'
    options, obsstr+'eBulkV_DSC', 'ysubtitle', '[km/s]'
    
    ; combine the bulk ion velocity into a single tplot variable
    get_data, obsstr+'dis_bulkX', xtimes, bulkx
    get_data, obsstr+'dis_bulkY', xtimes, bulky
    get_data, obsstr+'dis_bulkZ', xtimes, bulkz
    i_bulk_mag=SQRT(bulkx^2+bulky^2+bulkz^2)
    store_data, obsstr+'iBulkV_mag_DSC', data = {x:xtimes, y:i_bulk_mag}
    join_vec, [obsstr+'dis_bulkX', obsstr+'dis_bulkY', obsstr+'dis_bulkZ', obsstr+'iBulkV_mag_DSC'], obsstr+'iBulkV_DSC'
    options, obsstr+'iBulkV_DSC', 'labels', ['Vx', 'Vy', 'Vz', 'Vmag']
    options, obsstr+'iBulkV_DSC', 'labflag', -1
    options, obsstr+'iBulkV_DSC', 'colors', [2, 4, 6, 8]
    options, obsstr+'iBulkV_DSC', 'ytitle', 'MMS'+STRING(i,FORMAT='(I1)')+'!CiBulkV!CDSC'
    options, obsstr+'iBulkV_DSC', 'ysubtitle', '[km/s]'
    
    ; combine the parallel and perpendicular temperatures into a single tplot variable
;    join_vec, [obsstr+'DEStempPara', obsstr+'DEStempPerp', obsstr+'DIStempPara', obsstr+'DIStempPerp'], obsstr+'temp'
;    options, obsstr+'temp', 'labels', ['eTpara', 'eTperp', 'iTpara', 'iTperp']
;    options, obsstr+'temp', 'labflag', -1
;    options, obsstr+'temp', 'colors', [2, 4, 6, 8]
;    options, obsstr+'temp', 'ytitle', 'MMS'+STRING(i,FORMAT='(I1)')+'!CTemp'

    ; use bss routine to create tplot variables for fast, burst, status, and/or FOM
    trange = timerange(trange)
    spd_mms_load_bss, datatype=['fast', 'burst'], /include_labels
        
    ;-----------PLOT ELECTRON ENERGY SPECTRA DETAILS -- ONE SPACECRAFT --------------------
    ;PLOT: electron energy spectra for each observatory
    electron_espec = [obsstr+'des_energySpectr_pX', obsstr+'des_energySpectr_mX',$
                      obsstr+'des_energySpectr_pY', obsstr+'des_energySpectr_mY',$
                      obsstr+'des_energySpectr_pZ', obsstr+'des_energySpectr_mZ']
    electron_espec_omni = [obsstr+'des_EnergySpectr_omni_sum',obsstr+'des_EnergySpectr_omni_avg']
    ; replace gaps with NaNs so tplot doesn't interpolate on the X axis
    tdegap, electron_espec, /overwrite
    tdegap, electron_espec_omni, /overwrite
    panels=['mms_bss_burst', 'mms_bss_fast', 'mms_bss_status', qual_bar, $
            prefix+'_dfg_gsm_srvy', electron_espec, electron_espec_omni]
    window_caption="MMS FPI Electron energy spectra:  Counts, summed over DSC velocity-dirs +/- X, Y, & Z"
    if ~postscript then window, iw, xsize=width, ysize=height
    ;tplot_options,'title', window_caption
    tplot, panels, window=iw, var_label=position_vars
    xyouts, .01, .98, window_caption, /normal, charsize=1.15
    
    if postscript then tprint, plot_directory + obsstr+"electron_eSpec"
    iw=iw+1
   
    ;-----------ION ENERGY SPECTRA DETAILS -- ONE SPACECRAFT--------------------
    ion_espec =     [obsstr+'dis_energySpectr_pX', obsstr+'dis_energySpectr_mX', $
                     obsstr+'dis_energySpectr_pY', obsstr+'dis_energySpectr_mY', $
                     obsstr+'dis_energySpectr_pZ', obsstr+'dis_energySpectr_mZ']
    ion_espec_omni= [obsstr+'dis_EnergySpectr_omni_sum',obsstr+'dis_EnergySpectr_omni_avg']
    ; replace gaps with NaNs so tplot doesn't interpolate on the X axis
    tdegap, ion_espec, /overwrite
    tdegap, ion_espec_omni, /overwrite
    
    panels=['mms_bss_burst', 'mms_bss_fast', 'mms_bss_status', qual_bar, $
             prefix+'_dfg_gsm_srvy',ion_espec, ion_espec_omni]
    window_caption="MMS FPI Ion energy spectra:  Counts, summed over DSC velocity-dirs +/- X, Y, & Z"
    if ~postscript then window, iw, xsize=width, ysize=height
;    tplot_options,'title', window_caption
    tplot, panels, window=iw, var_label=position_vars
    xyouts, .05, .98, window_caption, /normal, charsize=1.15
    if postscript then tprint, plot_directory + obsstr+"ion_eSpec"
    iw=iw+1
      
                 
    ;-----------ONE SPACECRAFT ePAD DETAILS PLOT--------------------
    e_pad = [obsstr+'des_pitchAngDist_lowEn', obsstr+'des_pitchAngDist_midEn', $
              obsstr+'des_pitchAngDist_highEn' ]
    e_pad_allE = [obsstr+'des_PitchAngDist_sum', obsstr+'des_PitchAngDist_avg']
    ; replace gaps with NaNs so tplot doesn't interpolate on the X axis
    tdegap, e_pad, /overwrite
    tdegap, e_pad_allE, /overwrite
    
    panels=['mms_bss_burst', 'mms_bss_fast', 'mms_bss_status', qual_bar, $
             prefix+'_dfg_gsm_srvy',e_pad, e_pad_allE]
    window_caption="MMS FPI Electron PAD:  Counts, summed/averaged over energy bands"
    if ~postscript then window, iw, xsize=width, ysize=height
    ;tplot_options,'title', window_caption
    tplot, panels, window=iw, var_label=position_vars
    xyouts, .15, .98, window_caption, /normal, charsize=1.15
    if postscript then tprint, plot_directory + obsstr+"ePAD"
    iw=iw+1    
           
              
    ;-----------ONE SPACECRAFT FPI SUMMARY PLOT--------------------
    fpi_moments = [prefix+'_dfg_gsm_srvy', [obsstr+'des_numberDensity', obsstr+'dis_numberDensity'], obsstr+'eBulkV_DSC',  $
                   obsstr+'iBulkV_DSC', obsstr+'temp']
    fpi_espects = [obsstr+'dis_EnergySpectr_omni_avg', obsstr+'des_EnergySpectr_omni_avg']
    panels=['mms_bss_burst', 'mms_bss_fast', 'mms_bss_status', qual_bar, $
            fpi_moments, obsstr+'des_PitchAngDist_avg', fpi_espects]                    
    window_caption="MMS FPI Observatory Summary:"+"MMS"+STRING(i,FORMAT='(I1)')
    if ~postscript then window, iw, xsize=width, ysize=height
    ;tplot_options,'title', window_caption
    tplot, panels, window=iw, var_label=position_vars
    xyouts, .3, .98, window_caption, /normal, charsize=1.15
    if postscript then tprint, plot_directory + obsstr+"Observatory Summary"
    iw=iw+1
    if send_plots_to eq 'png' then begin
        thm_gen_multipngplot, obsstr, date, directory = plot_directory, /mkdir
    endif
ENDFOR


;-----------FOUR SPACECRAFT SUMMARY PLOT--------------------
panels=['mms_bss_burst', 'mms_bss_fast', 'mms_bss_status', qual_bar, obsstr+'dataQuality']
FOR i=1,4 DO BEGIN
   obsstr = 'mms'+STRING(i,FORMAT='(I1)')
   panels=[panels,obsstr+'_dfg_gsm_srvy',obsstr+'_des_EnergySpectr_omni_sum',obsstr+'_dis_EnergySpectr_omni_sum'] 
ENDFOR
window_caption="MMS FPI Observatory Summary: MMS1, MMS2, MMS3, MMS4"
if ~postscript then window, iw, xsize=width, ysize=height
;tplot_options,'title', window_caption
tplot, panels, window=iw, var_label='mms'+strcompress(string(i), /rem)+'_defeph_pos'
xyouts, .25, .98, window_caption, /normal, charsize=1.15
if postscript then tprint, plot_directory + "MMS-all FPI Observatory Summary"

; make the PNGs
if send_plots_to eq 'png' then begin
    thm_gen_multipngplot, 'mms_fpi_all', date, directory = plot_directory, /mkdir
endif
print, 'FPI QL script took: ' + string(systime(/sec)-start_time) + ' seconds to run'

stop

END