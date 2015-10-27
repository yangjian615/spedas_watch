;+ 
; MMS FPI crib sheet for Quicklook plots
; do you have suggestions for this crib sheet?  
;   please send them to egrimes@igpp.ucla.edu
; 
; History:
; egrimes updated 23Sep2015, to set some metadata for spectra/PADs
; egrimes updated 8Sept2015
; BGILES UPDATED 1Sept2015
; BGILES UPDATED 31AUGUST2015
; 
; $LastChangedBy: crussell $
; $LastChangedDate: 2015-10-26 12:52:11 -0700 (Mon, 26 Oct 2015) $
; $LastChangedRevision: 19157 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/examples/mms_load_fpi_crib_qlplots.pro $
;-

start_time = systime(/seconds)

;preparations and defaults
date = '15-10-06/00:00:00'
timespan, date, 1, /day
probes = [1, 2, 3, 4]
datatype = '*' ; grab all data in the CDF
level = 'sitl'
data_rate = 'fast'
;data_rate = 'srvy'
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
    autoscale = autoscale, /time_clip

; load ephemeris data for all 4 probes
mms_load_state, trange = trange, probes = probes, /ephemeris

; load DFG data for all 4 probes
mms_load_dfg, trange = trange, probes = probes

FOR i=1,n_elements(probes) DO BEGIN    ;step through the observatories
    obsstr='mms'+STRING(i,FORMAT='(I1)')+'_fpi_'
    
    ;SET UP TPLOT VARIABLES
    
    ; convert the position data into Re
    eph_variable = 'mms'+strcompress(string(i), /rem)+'_defeph_pos'
    calc,'"'+eph_variable+'_re" = "'+eph_variable+'"/6371.2'
    
    ; split the position into its components
    split_vec, eph_variable+'_re'
    
    ; set the label to show along the bottom of the tplot
    options, eph_variable+'_re_x',ytitle='X (Re)'
    options, eph_variable+'_re_y',ytitle='Y (Re)'
    options, eph_variable+'_re_z',ytitle='Z (Re)'
    position_vars = [eph_variable+'_re_z', eph_variable+'_re_y', eph_variable+'_re_x']
    
    ; Data quality bar
    qual_bar = mms_quality_bar(obsstr+'dataQuality')
    
    ; combine bent pipe B DSC into a single tplot variable
    prefix = 'mms'+strcompress(string(i), /rem)
    split_vec, prefix+'_dfg_srvy_gse_bvec'
    
    ; time clip the data to -150nT to 150nT
    tclip, prefix+'_dfg_srvy_gse_bvec_?', -150, 150, /overwrite
    tclip, prefix+'_dfg_srvy_gse_btot', -150, 150, /overwrite
    
    store_data, prefix+'_dfg_gse_srvy', data=prefix+['_dfg_srvy_gse_bvec'+['_x', '_y', '_z'], '_dfg_srvy_gse_btot']
    options, prefix+'_dfg_gse_srvy', labflag=-1
    
    ; combine the densities into one tplot variable
    join_vec, [obsstr+'DESnumberDensity', obsstr+'DISnumberDensity'], obsstr+'numberDensity'
    options, obsstr+'numberDensity', 'labels', ['electrons', 'ions']
    options, obsstr+'numberDensity', 'labflag', -1
    options, obsstr+'numberDensity', 'colors', [2, 4]
    
    ; combine the bulk electron velocities into one tplot variable
    get_data, obsstr+'eBulkV_X_DSC', xtimes, bulkx
    get_data, obsstr+'eBulkV_Y_DSC', xtimes, bulky
    get_data, obsstr+'eBulkV_Z_DSC', xtimes, bulkz
    e_bulk_mag=SQRT(bulkx^2+bulky^2+bulkz^2)
    store_data, obsstr+'eBulkV_mag_DSC', data = {x:xtimes, y:e_bulk_mag}
    join_vec, [obsstr+'eBulkV_X_DSC', obsstr+'eBulkV_Y_DSC', obsstr+'eBulkV_Z_DSC', obsstr+'eBulkV_mag_DSC'], obsstr+'eBulkV_DSC'
    options, obsstr+'eBulkV_DSC', 'labels', ['Vx', 'Vy', 'Vz', 'Vmag']
    options, obsstr+'eBulkV_DSC', 'labflag', -1
    options, obsstr+'eBulkV_DSC', 'colors', [2, 4, 6, 8]
    options, obsstr+'eBulkV_DSC', 'ytitle', 'MMS'+STRING(i,FORMAT='(I1)')+'!CeBulkV!CDSC'
    options, obsstr+'eBulkV_DSC', 'ysubtitle', '[km/s]'
    
    ; combine the bulk ion velocity into a single tplot variable
    get_data, obsstr+'iBulkV_X_DSC', xtimes, bulkx
    get_data, obsstr+'iBulkV_Y_DSC', xtimes, bulky
    get_data, obsstr+'iBulkV_Z_DSC', xtimes, bulkz
    i_bulk_mag=SQRT(bulkx^2+bulky^2+bulkz^2)
    store_data, obsstr+'iBulkV_mag_DSC', data = {x:xtimes, y:i_bulk_mag}
    join_vec, [obsstr+'iBulkV_X_DSC', obsstr+'iBulkV_Y_DSC', obsstr+'iBulkV_Z_DSC', obsstr+'iBulkV_mag_DSC'], obsstr+'iBulkV_DSC'
    options, obsstr+'iBulkV_DSC', 'labels', ['Vx', 'Vy', 'Vz', 'Vmag']
    options, obsstr+'iBulkV_DSC', 'labflag', -1
    options, obsstr+'iBulkV_DSC', 'colors', [2, 4, 6, 8]
    options, obsstr+'iBulkV_DSC', 'ytitle', 'MMS'+STRING(i,FORMAT='(I1)')+'!CiBulkV!CDSC'
    options, obsstr+'iBulkV_DSC', 'ysubtitle', '[km/s]'
    
    ; combine the parallel and perpendicular temperatures into a single tplot variable
    join_vec, [obsstr+'DEStempPara', obsstr+'DEStempPerp', obsstr+'DIStempPara', obsstr+'DIStempPerp'], obsstr+'temp'
    options, obsstr+'temp', 'labels', ['eTpara', 'eTperp', 'iTpara', 'iTperp']
    options, obsstr+'temp', 'labflag', -1
    options, obsstr+'temp', 'colors', [2, 4, 6, 8]
    options, obsstr+'temp', 'ytitle', 'MMS'+STRING(i,FORMAT='(I1)')+'!CTemp'

    ; use bss routine to create tplot variables for fast, burst, status, and/or FOM
    trange = timerange(trange)
    mms_load_bss, trange=trange, /include_labels
        
    ;-----------PLOT ELECTRON ENERGY SPECTRA DETAILS -- ONE SPACECRAFT --------------------
    ;PLOT: electron energy spectra for each observatory
    electron_espec = [obsstr+'eEnergySpectr_pX', obsstr+'eEnergySpectr_mX',$
                      obsstr+'eEnergySpectr_pY', obsstr+'eEnergySpectr_mY',$
                      obsstr+'eEnergySpectr_pZ', obsstr+'eEnergySpectr_mZ']
    electron_espec_omni = [obsstr+'eEnergySpectr_omni_sum',obsstr+'eEnergySpectr_omni_avg']
    panels=['mms_bss_burst', 'mms_bss_fast', 'mms_bss_status', qual_bar, $
            prefix+'_dfg_gse_srvy', electron_espec, electron_espec_omni]
    window_caption="MMS FPI Electron energy spectra:  Counts, summed over DSC velocity-dirs +/- X, Y, & Z"
    if ~postscript then window, iw, xsize=width, ysize=height
    ;tplot_options,'title', window_caption
    tplot, panels, window=iw, var_label=position_vars
    xyouts, .01, .98, window_caption, /normal, charsize=1.15
    
    if postscript then tprint, plot_directory + obsstr+"electron_eSpec"
    iw=iw+1
   
    ;-----------ION ENERGY SPECTRA DETAILS -- ONE SPACECRAFT--------------------
    ion_espec =     [obsstr+'iEnergySpectr_pX', obsstr+'iEnergySpectr_mX', $
                     obsstr+'iEnergySpectr_pY', obsstr+'iEnergySpectr_mY', $
                     obsstr+'iEnergySpectr_pZ', obsstr+'iEnergySpectr_mZ']
    ion_espec_omni= [obsstr+'iEnergySpectr_omni_sum',obsstr+'iEnergySpectr_omni_avg']
    panels=['mms_bss_burst', 'mms_bss_fast', 'mms_bss_status', qual_bar, $
             prefix+'_dfg_gse_srvy',ion_espec, ion_espec_omni]
    window_caption="MMS FPI Ion energy spectra:  Counts, summed over DSC velocity-dirs +/- X, Y, & Z"
    if ~postscript then window, iw, xsize=width, ysize=height
;    tplot_options,'title', window_caption
    tplot, panels, window=iw, var_label=position_vars
    xyouts, .05, .98, window_caption, /normal, charsize=1.15
    if postscript then tprint, plot_directory + obsstr+"ion_eSpec"
    iw=iw+1
      
                 
    ;-----------ONE SPACECRAFT ePAD DETAILS PLOT--------------------
    e_pad = [obsstr+'ePitchAngDist_lowEn', obsstr+'ePitchAngDist_midEn', $
              obsstr+'ePitchAngDist_highEn' ]
    e_pad_allE = [obsstr+'ePitchAngDist_sum', obsstr+'ePitchAngDist_avg']
    panels=['mms_bss_burst', 'mms_bss_fast', 'mms_bss_status', qual_bar, $
             prefix+'_dfg_gse_srvy',e_pad, e_pad_allE]
    window_caption="MMS FPI Electron PAD:  Counts, summed/averaged over energy bands
    if ~postscript then window, iw, xsize=width, ysize=height
    ;tplot_options,'title', window_caption
    tplot, panels, window=iw, var_label=position_vars
    xyouts, .15, .98, window_caption, /normal, charsize=1.15
    if postscript then tprint, plot_directory + obsstr+"ePAD"
    iw=iw+1    
           
              
    ;-----------ONE SPACECRAFT FPI SUMMARY PLOT--------------------
    fpi_moments = [prefix+'_dfg_gse_srvy', obsstr+'numberDensity', obsstr+'eBulkV_DSC',  $
                   obsstr+'iBulkV_DSC', obsstr+'temp']
    fpi_espects = [obsstr+'iEnergySpectr_omni_avg', obsstr+'eEnergySpectr_omni_avg']
    panels=['mms_bss_burst', 'mms_bss_fast', 'mms_bss_status', qual_bar, $
            fpi_moments, obsstr+'ePitchAngDist_avg', fpi_espects]                    
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
   prefix = 'mms'+STRING(i,FORMAT='(I1)')
   obsstr=prefix+'_fpi_'
   panels=[panels,prefix+'_dfg_gse_srvy',obsstr+'eEnergySpectr_omni_sum',obsstr+'iEnergySpectr_omni_sum'] 
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