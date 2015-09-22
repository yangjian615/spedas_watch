;+ 
; MMS FPI crib sheet for Quicklook plots
; do you have suggestions for this crib sheet?  
;   please send them to egrimes@igpp.ucla.edu
; 
; egrimes updated 8Sept2015
; BGILES UPDATED 1Sept2015
; BGILES UPDATED 31AUGUST2015
; $LastChangedBy: egrimes $
; $LastChangedDate: 2015-09-21 08:21:18 -0700 (Mon, 21 Sep 2015) $
; $LastChangedRevision: 18849 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/examples/mms_load_fpi_crib_qlplots.pro $
;-

;preparations and defaults
timespan, '15-08-15', 1, /day
;probes = ['3']
datatype = '*' ; grab all data in the CDF
level = 'sitl'
data_rate = 'fast'
autoscale = 1
iw=0
width = 650
height = 750

tplot_options,'xmargin',[15,10]              ; Set left/right margins to 10 characters
;tplot_options,'ymargin',[4,2]                ; Set top/bottom margins to 4/2 lines

;load_undefined_fpi_arrays, ypad, yenergies   ;this is temporary until quantities can be added to FPI CDFs

;load data for all 4 probes
mms_load_fpi, trange = trange, probes = [1, 2, 3, 4], datatype = datatype, $
    level = level, data_rate = data_rate, $
    local_data_dir = local_data_dir, source = source, $
    get_support_data = get_support_data, $
    tplotnames = tplotnames, no_color_setup = no_color_setup

; load ephemeris data for all 4 probes
mms_load_state, trange = trange, probes = [1, 2, 3, 4], /ephemeris

; load DFG data for all 4 probes
mms_load_dfg, trange = trange, probes = [1, 2, 3, 4]

FOR i=1,4 DO BEGIN    ;step through the observatories
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


; setup electron energy spectra into tplot variables
get_data, obsstr+'eEnergySpectr_pX', xtimes, pX, yenergies
get_data, obsstr+'eEnergySpectr_mX', xtimes, mX, yenergies
get_data, obsstr+'eEnergySpectr_pY', xtimes, pY, yenergies
get_data, obsstr+'eEnergySpectr_mY', xtimes, mY, yenergies
get_data, obsstr+'eEnergySpectr_pZ', xtimes, pZ, yenergies
get_data, obsstr+'eEnergySpectr_mZ', xtimes, mZ, yenergies
e_omni_sum=(pX+mX+pY+mY+pZ+mZ)
e_omni_avg=e_omni_sum/6
store_data, obsstr+'eEnergySpectr_pX', data = {x:xtimes, y:pX, v:yenergies}
store_data, obsstr+'eEnergySpectr_mX', data = {x:xtimes, y:mX, v:yenergies}
store_data, obsstr+'eEnergySpectr_pY', data = {x:xtimes, y:pY, v:yenergies}
store_data, obsstr+'eEnergySpectr_mY', data = {x:xtimes, y:mY, v:yenergies}
store_data, obsstr+'eEnergySpectr_pZ', data = {x:xtimes, y:pZ, v:yenergies}
store_data, obsstr+'eEnergySpectr_mZ', data = {x:xtimes, y:mZ, v:yenergies}
store_data, obsstr+'eEnergySpectr_omni_avg', data = {x:xtimes, y:e_omni_avg, v:yenergies}
store_data, obsstr+'eEnergySpectr_omni_sum', data = {x:xtimes, y:e_omni_sum, v:yenergies}

; setup ion energy spectra into tplot variables
get_data, obsstr+'iEnergySpectr_pX', xtimes, pX, yenergies
get_data, obsstr+'iEnergySpectr_mX', xtimes, mX, yenergies
get_data, obsstr+'iEnergySpectr_pY', xtimes, pY, yenergies
get_data, obsstr+'iEnergySpectr_mY', xtimes, mY, yenergies
get_data, obsstr+'iEnergySpectr_pZ', xtimes, pZ, yenergies
get_data, obsstr+'iEnergySpectr_mZ', xtimes, mZ, yenergies
i_omni_sum=(pX+mX+pY+mY+pZ+mZ)
i_omni_avg=i_omni_sum/6
store_data, obsstr+'iEnergySpectr_pX', data = {x:xtimes, y:pX, v:yenergies}
store_data, obsstr+'iEnergySpectr_mX', data = {x:xtimes, y:mX, v:yenergies}
store_data, obsstr+'iEnergySpectr_pY', data = {x:xtimes, y:pY, v:yenergies}
store_data, obsstr+'iEnergySpectr_mY', data = {x:xtimes, y:mY, v:yenergies}
store_data, obsstr+'iEnergySpectr_pZ', data = {x:xtimes, y:pZ, v:yenergies}
store_data, obsstr+'iEnergySpectr_mZ', data = {x:xtimes, y:mZ, v:yenergies}
store_data, obsstr+'iEnergySpectr_omni_sum', data = {x:xtimes, y:i_omni_sum, v:yenergies}
store_data, obsstr+'iEnergySpectr_omni_avg', data = {x:xtimes, y:i_omni_avg, v:yenergies}

; setup electron PAD into tplot variables
get_data, obsstr+'ePitchAngDist_lowEn', xtimes, lowEn, ypad
get_data, obsstr+'ePitchAngDist_midEn', xtimes, midEn, ypad
get_data, obsstr+'ePitchAngDist_highEn', xtimes, highEn, ypad
e_PAD_sum=(lowEn+midEn+highEn)
e_PAD_avg=e_PAD_sum/3
store_data, obsstr+'ePitchAngDist_lowEn', data = {x:xtimes, y:lowEn, v:ypad}
store_data, obsstr+'ePitchAngDist_midEn', data = {x:xtimes, y:midEn, v:ypad}
store_data, obsstr+'ePitchAngDist_highEn', data = {x:xtimes, y:highEn, v:ypad}
store_data, obsstr+'ePitchAngDist_sum', data = {x:xtimes, y:e_PAD_sum, v:ypad}
store_data, obsstr+'ePitchAngDist_avg', data = {x:xtimes, y:e_PAD_avg, v:ypad}

; combine the densities into one tplot variable
join_vec, [obsstr+'DESnumberDensity', obsstr+'fpi_DISnumberDensity'], obsstr+'numberDensity'
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

; combine the parallel and perpendicular temperatures into a single tplot variable
join_vec, [obsstr+'DEStempPara', obsstr+'DEStempPerp', obsstr+'DIStempPara', obsstr+'DIStempPerp'], obsstr+'temp'
options, obsstr+'temp', 'labels', ['eTpara', 'eTperp', 'iTpara', 'iTperp']
options, obsstr+'temp', 'labflag', -1
options, obsstr+'temp', 'colors', [2, 4, 6, 8]


;-----------PLOT ELECTRON ENERGY SPECTRA DETAILS -- ONE SPACECRAFT --------------------
;PLOT: electron energy spectra for each observatory
electron_espec = [obsstr+'eEnergySpectr_pX', obsstr+'eEnergySpectr_mX',$
                  obsstr+'eEnergySpectr_pY', obsstr+'eEnergySpectr_mY',$
                  obsstr+'eEnergySpectr_pZ', obsstr+'eEnergySpectr_mZ']
electron_espec_omni = [obsstr+'eEnergySpectr_omni_sum',obsstr+'eEnergySpectr_omni_avg']
options, electron_espec, spec=1, zlog=1, ylog=1, no_interp=1
options, electron_espec_omni, spec=1, zlog=1, ylog=1, no_interp=1
ylim, electron_espec, min(yenergies), max(yenergies)
if autoscale eq 0 then zlim, electron_espec, min(e_omni_avg), max(e_omni_avg)
panels=[qual_bar, prefix+'_dfg_gse_srvy', electron_espec, electron_espec_omni]
window_caption="MMS FPI Electron energy spectra:  Counts, summed over DSC velocity-dirs +/- X, Y, & Z"
window, iw, xsize=width, ysize=height
tplot_options,'title', window_caption
tplot, panels, window=iw, var_label=position_vars
tprint, obsstr+"electron_eSpec"
iw=iw+1


;-----------ION ENERGY SPECTRA DETAILS -- ONE SPACECRAFT--------------------
ion_espec =     [obsstr+'iEnergySpectr_pX', obsstr+'iEnergySpectr_mX', $
                 obsstr+'iEnergySpectr_pY', obsstr+'iEnergySpectr_mY', $
                 obsstr+'iEnergySpectr_pZ', obsstr+'iEnergySpectr_mZ']
ion_espec_omni= [obsstr+'iEnergySpectr_omni_sum',obsstr+'iEnergySpectr_omni_avg']
options, ion_espec, spec=1, zlog=1, ylog=1, no_interp=1
options, ion_espec_omni, spec=1, zlog=1, ylog=1, no_interp=1
ylim, ion_espec, min(yenergies), max(yenergies)
if autoscale eq 0 then zlim, ion_espec, min(i_omni_avg), max(i_omni_avg)
panels=[qual_bar, prefix+'_dfg_gse_srvy',ion_espec, ion_espec_omni]
window_caption="MMS FPI Ion energy spectra:  Counts, summed over DSC velocity-dirs +/- X, Y, & Z"
window, iw, xsize=width, ysize=height
tplot_options,'title', window_caption
tplot, panels, window=iw, var_label=position_vars
tprint, obsstr+"ion_eSpec"
iw=iw+1
  
             
;-----------ONE SPACECRAFT ePAD DETAILS PLOT--------------------
e_pad = [obsstr+'ePitchAngDist_lowEn', obsstr+'ePitchAngDist_midEn', $
          obsstr+'ePitchAngDist_highEn' ]
e_pad_allE = [obsstr+'ePitchAngDist_sum', obsstr+'ePitchAngDist_avg'] 
options, e_pad, spec=1, zlog=1, no_interp=1
options, e_pad_allE, spec=1, zlog=1, no_interp=1
if autoscale eq 0 then zlim, e_pad, min(e_PAD_avg), max(e_PAD_avg)
ylim, e_pad, 0, 180
ylim, e_pad_allE, 0, 180
panels=[qual_bar, prefix+'_dfg_gse_srvy',e_pad, e_pad_allE]
window_caption="MMS FPI Electron PAD:  Counts, summed/averaged over energy bands
window, iw, xsize=width, ysize=height
tplot_options,'title', window_caption
tplot, panels, window=iw, var_label=position_vars
tprint, obsstr+"ePAD"
iw=iw+1
 
          
;-----------ONE SPACECRAFT FPI SUMMARY PLOT--------------------
fpi_moments = [obsstr+'numberDensity', prefix+'_dfg_gse_srvy', obsstr+'eBulkV_DSC',  $
               obsstr+'iBulkV_DSC', obsstr+'temp']
fpi_espects = [obsstr+'iEnergySpectr_omni_avg', obsstr+'eEnergySpectr_omni_avg']
options, obsstr+'ePitchAngDist_avg', spec=1, zlog=1, no_interp=1
options, fpi_espects, spec=1, zlog=1, no_interp=1
ylim, obsstr+'ePitchAngDist_avg', 0, 180
ylim, fpi_espects, min(yenergies), max(yenergies)
panels=[qual_bar, fpi_moments, obsstr+'ePitchAngDist_avg', fpi_espects]                    
window_caption="MMS FPI Observatory Summary:"+"MMS"+STRING(i,FORMAT='(I1)')
window, iw, xsize=width, ysize=height
tplot_options,'title', window_caption
tplot, panels, window=iw, var_label=position_vars
tprint, obsstr+"Observatory Summary"
iw=iw+1

ENDFOR


;-----------FOUR SPACECRAFT SUMMARY PLOT--------------------
panels=[obsstr+'dataQuality']
FOR i=1,4 DO BEGIN
   prefix = 'mms'+STRING(i,FORMAT='(I1)')
   obsstr=prefix+'_fpi_'
   panels=[panels,prefix+'_dfg_gse_srvy',obsstr+'eEnergySpectr_omni_sum',obsstr+'iEnergySpectr_omni_sum'] 
ENDFOR
window_caption="MMS FPI Observatory Summary: MMS1, MMS2, MMS3, MMS4"
window, iw, xsize=width, ysize=height
tplot_options,'title', window_caption
tplot, panels, window=iw, var_label='mms'+strcompress(string(i), /rem)+'_defeph_pos'
tprint, "MMS-all FPI Observatory Summary"

END
