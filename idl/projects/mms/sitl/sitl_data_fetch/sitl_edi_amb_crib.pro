; docformat = 'rst'
;
; NAME:
;    unh_edi_amb_crib
;
; PURPOSE:
;+
;   Plot EDI ambient data
;
; :Categories:
;    MMS, SITL
;
; :Examples:
;   To use::
;       IDL> .r unh_edi_amb_crib
;
; :Author:
;    Matthew Argall::
;    University of New Hampshire
;    Morse Hall Room 348
;    8 College Road
;    Durham, NH 03824
;    matthew.argall@unh.edu
;
; :History:
;    Modification History::
;       2015/08/03  -   Written by Matthew Argall
;       2015/09/06  -   Include EDP E-field. Plot 0 & 180 separately. - MRA
;-
;*****************************************************************************************

;Set the time range and spacecraft ID
timespan,'2015-08-28/00:00', 24, /hour
sc_id   = 'mms3'
tf_load = 1

;Load Data into TPlot
if tf_load then begin
	mms_sitl_get_dfg, SC_ID=sc_id
	mms_load_edp,     PROBES=strmid(sc_id,3), LEVEL='ql', DATA_RATE='fast'
	mms_sitl_get_edi_amb, SC_ID=sc_id
endif

;-----------------------------------------------------
; MMS Colors \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
;-----------------------------------------------------

;Load colors into color table. MMS Colors:
;   - MMS1:  BLACK (change to white if using dark background)
;   - MMS2:  RED
;   - MMS3:  GREEN
;   - MMS4:  BLUE
;   - X,Y,Z is BLUE, GREEN, RED, solid, dashed, dotted  
;
;   - Red = RGB [213, 94, 0] 
;   - Green = RGB [0, 158, 115]   
;   - Blue = RGB [86, 180, 233]
tvlct, r, g, b, /GET
red   = [[213], [ 94], [  0]]
green = [[  0], [158], [115]]
blue  = [[ 86], [180], [233]]

ired   = 1
igreen = 2
iblue  = 3
tvlct, red,   ired
tvlct, green, igreen
tvlct, blue,  iblue

;-----------------------------------------------------
; DFG \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
;-----------------------------------------------------
;Set plot properties
options, sc_id + '_dfg_srvy_gsm_dmpa', 'colors', [iblue, igreen, ired]
options, sc_id + '_dfg_srvy_gsm_dmpa', 'labels', ['Bx', 'By', 'Bz']
options, sc_id + '_dfg_srvy_gsm_dmpa', 'yrange', [-100, 100]
options, sc_id + '_dfg_srvy_gsm_dmpa', 'labflag', -1

;-----------------------------------------------------
; EDP \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
;-----------------------------------------------------
;Set plot properties
options, sc_id + '_edp_fast_dce_dsl', 'colors', [iblue, igreen, ired]
options, sc_id + '_edp_fast_dce_dsl', 'labels', ['Ex', 'Ey', 'Ez']
options, sc_id + '_edp_fast_dce_dsl', 'yrange', [-30, 30]
options, sc_id + '_edp_fast_dce_dsl', 'labflag', -1

;-----------------------------------------------------
; EDI \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
;-----------------------------------------------------
;Instead of plotting counts from GDU1 and GDU2, plot
;0 & 180 degree pitch angle counts.
get_data, sc_id + '_edi_pitch_gdu1',           DATA=pitch_gdu1
get_data, sc_id + '_edi_pitch_gdu2',           DATA=pitch_gdu2
get_data, sc_id + '_edi_amb_gdu1_raw_counts1', DATA=counts_gdu1
get_data, sc_id + '_edi_amb_gdu2_raw_counts1', DATA=counts_gdu2


;-----------------------------------------------------
; EDI: Sort By Pitch Angle 0 \\\\\\\\\\\\\\\\\\\\\\\\\
;-----------------------------------------------------
;Find 0 and 180 pitch angles
igdu1_0   = where(pitch_gdu1.y eq   0, ngdu1_0)
igdu2_0   = where(pitch_gdu2.y eq   0, ngdu2_0)
igdu1_180 = where(pitch_gdu1.y eq 180, ngdu1_180)
igdu2_180 = where(pitch_gdu2.y eq 180, ngdu2_180)

;Select 0 pitch angle
if ngdu1_0 gt 0 && ngdu2_0 gt 0 then begin
	t_0      = [ counts_gdu1.x[igdu1_0], counts_gdu2.x[igdu2_0] ]
	counts_0 = [ counts_gdu1.y[igdu1_0], counts_gdu2.y[igdu2_0] ]
	
	;Sort times
	isort    = sort(t_0)
	t_0      = t_0[isort]
	counts_0 = counts_0[isort]
	
	;Mark GDU
	gdu_0          = bytarr(ngdu1_0 + ngdu2_0)
	gdu_0[igdu1_0] = 1B
	gdu_0[igdu2_0] = 2B

;Only GDU1 data
endif else if ngdu1_0 gt 0 then begin
	t_0      = counts_gdu1.x[igdu1_0]
	counts_0 = counts_gdu1.y[igdu1_0]
	gdu_0    = replicate(1B, ngdu1_0)

;Only GDU2 data
endif else if ngdu2_0 gt 0 then begin
	t_0      = counts_gdu2.x[igdu2_0]
	counts_0 = counts_gdu2.y[igdu2_0]
	gdu_0    = replicate(2B, ngdu2_0)
endif

;Store data
if n_elements(counts_0) gt 0 $
	then store_data, sc_id + '_edi_amb_pa0_raw_counts', DATA={x: t_0, y: counts_0}

;Set options
options, sc_id + '_edi_amb_pa0_raw_counts', 'ylog', 1

;-----------------------------------------------------
; EDI: Sort By Pitch Angle 180 \\\\\\\\\\\\\\\\\\\\\\\
;-----------------------------------------------------

;Select 180 pitch angle
if ngdu1_180 gt 0 && ngdu2_180 gt 0 then begin
	t_180      = [ counts_gdu1.x[igdu1_180], counts_gdu2.x[igdu2_180] ]
	counts_180 = [ counts_gdu1.y[igdu1_180], counts_gdu2.y[igdu2_180] ]
	
	;Sort times
	isort    = sort(t_180)
	t_180      = t_180[isort]
	counts_180 = counts_180[isort]
	
	;Mark GDU
	gdu_180            = bytarr(ngdu1_180 + ngdu2_180)
	gdu_180[igdu1_180] = 1B
	gdu_180[igdu2_180] = 2B

;Only GDU1 data
endif else if ngdu1_180 gt 0 then begin
	t_180      = counts_gdu1.x[igdu1_180]
	counts_180 = counts_gdu1.y[igdu1_180]
	gdu_180    = replicate(1B, ngdu1_180)

;Only GDU2 data
endif else if ngdu2_180 gt 0 then begin
	t_180      = counts_gdu2.x[igdu2_180]
	counts_180 = counts_gdu2.y[igdu2_180]
	gdu_180    = replicate(2B, ngdu2_180)
endif

;Store data
if n_elements(counts_180) gt 0 $
	then store_data, sc_id + '_edi_amb_pa180_raw_counts', DATA={x: t_180, y: counts_180}

;Set options
options, sc_id + '_edi_amb_pa180_raw_counts', 'ylog', 1

;-----------------------------------------------------
; Plot \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
;-----------------------------------------------------

;Plot the data
;   1. B GSM-DMPA
;   2. E DSL
;   3. Counts GDU1
;   4. Counts GDU2
tplot, [sc_id + '_dfg_srvy_gsm_dmpa', $
        sc_id + '_edp_fast_dce_dsl', $
        sc_id + '_edi_amb_pa0_raw_counts', $
        sc_id + '_edi_amb_pa180_raw_counts']

;Restore the old color table
tvlct, r, b, b

end

