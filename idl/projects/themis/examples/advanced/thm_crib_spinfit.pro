;+
;	Batch File: THM_SPINFIT
;
;	Purpose:  Demonstration of finding spin fit parameters for spinning data.
;   The FIT module calculates the E-Field and B-Field vectors by taking 32 points at equal angles
;   and fitting a sine wave least squares fit to the data. The best fit of the data is defined by the
;   formula: A + B*cos() + C*sin(). The module calculates the standard deviation of the fit
;   called Sigma, and the number of points remaining in the curve called N.

;	Calling Sequence:
;	  Cut-and-paste the code to the command line.
;
;	Arguments:
;   required parameters:
;     var_name_in = tplot variable name containing data to fit
;
;   keywords:
;    sigma = If set, will cause program to output tplot variable with sigma for each period.
;    npoints = If set, will cause program to output tplot variable with number of points in fit.
;    spinaxis = If set, program will output a tplot variable storing the average over the spin axis dimension
;             for each time period.
;    median  = If spinaxis set, program will output a median of each period instead of the average.
;    plane_dim = Tells program which dimension to treat as the plane. 0=x, 1=y, 2=z. Default 0.
;    axis_dim = Tells program which dimension contains axis to average over. Default 0.  Will not
;             create a tplot variable unless used with /spinaxis.
;    min_points = Minimum number of points to fit.  Default = 5.
;    alpha = A parameter for finding fits.  Points outside of sigma*(alpha + beta*i)
;          will be thrown out.  Default 1.4.
;    beta = A parameter for finding fits.  See above.  Default = 0.4
;    phase_mask_starts = Time to start masking data.  Default = 0
;    phase_mask_ends = Time to stop masking data.  Default = -1
;    sun2sensor = Tells how much to rotate data to align with sun sensor.
;
;
;	Notes:
;	The module determines which data is more than xN * �N (sN = standard deviation) away from fit,
;   and removes those points and repeats the fit. The second time the standard deviation is
;   smaller so the tolerance is increased a bit. The tolerance xN varies with try as:
;   Alpha*NBeta, where A=1.4 and Beta=0.4 provide good results. The operation continues
;   until no points are outside the bounds and the process is considered convergent.
;
;Written by Katherine Ramer
; $LastChangedBy: Katherine Ramer$
; $LastChangedDate: 2013-12-16 14:28:18 -0800 (Mon, 16 Dec 2013) $
; $LastChangedRevision: 13677 $
; $URL $
;-

; FIT Ground Based SpinFit data example.


; set a few TPLOT options.
tplot_title = 'THEMIS FIT Ground Based Spin Fit Examples'
tplot_options, 'title', tplot_title
tplot_options, 'xmargin', [ 15, 10]
tplot_options, 'ymargin', [ 5, 5]

; set the color table.
loadct2, 39

; set the timespan and load the raw data required to perform spin fit.
timespan, '2008-01-01', 1.0, /day

thm_load_fgm,probe='a',level=1,type='raw'
thm_load_efi,probe='a',level=1,type='raw'
thm_load_state,probe='a',/get_support_data

; perform spin fit on fgh data and have it return A, B, C fit parameters plus the
; standard deviation and number of points remaining in curve.

; fit magnetic field data
thm_spinfit, 'th?_fgh', /sigma, /npoints

; fit electric field data
thm_spinfit, 'th?_efp', /sigma, /npoints

;stop


; Now load on board spin fit data to compare.

thm_load_fit, probe='a', type = 'raw'

; tha_fit_efit and tha_fit_bfit contain the A, B, C, sigma, and npoints values in an
; nx5 array for electric and magnetic fields, respectively.

end



