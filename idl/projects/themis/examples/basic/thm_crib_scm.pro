;+
; **********************************************************************
; thm_crib_scm.pro : IDL batch file to get, clean and calibrate SCM data
;  with thm_cal_scm
; K. Bromund
; O. Le Contel & P. Robert, CETP
; **********************************************************************
; $LastChangedBy: pcruce $
; $LastChangedDate: 2013-09-19 11:14:02 -0700 (Thu, 19 Sep 2013) $
; $LastChangedRevision: 13081 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/basic/thm_crib_scm.pro $
;-

;;    ============================
;; 1) Select date and time interval
;;    ============================

  date = '2007-03-23/00:00:00' 
  timespan,date,1,/day

;;    =====================
;; 2) Select probe and mode
;;    =====================

;; Select SATNAME (a,b,c,d or e)
  satname = 'd'

;; Select MODE (scf, scp, scw)
  mode = 'scp'

;;    ==================================
;; 3) get auxiliary data from STAT file
;;    ==================================

thm_load_state, probe=satname, /get_support_data

;;    ==================================
;; 4) get SCM data and SCM header file
;;    ==================================

;; If you want to set up a limited timespan for calibration,
;; you set up a trange array like this:

;; To impose by hand t1 and t2 :
starting_date =strmid(date,0,10)
;; for best cleanup, it is best to specify a relatively short time range,
;; over which the noise signal is relatively uniform.
  starting_time='13:58:10.0'
  ending_time  ='14:02:00.0'

  trange = [starting_date+'/'+starting_time, $
            starting_date+'/'+ending_time]
;;  don't forget to uncomment the trange keyword to thm_load_scm/thm_cal_scm!

;;    ===================================
;; 4a) easy method, including calibration
;;    ===================================

;; load and calibrate data of specified type:
;thm_load_scm,probe=satname, datatype=mode, level=1 , trange=trange

thscs_mode = 'th'+satname+'_'+mode

;tplot, thscs_mode, trange=trange

;print, 'type .c for a demonstration of diagnositic outputs available with '
;print, '        thm_cal_scm'
;stop


;;    =============================================
;; 4b) method for customized and diagnostic calibration
;;    =============================================

;; get data over a whole day

thm_load_scm,probe=satname, level=1,  type='raw',$
			    trange=trange,$
			    /get_support

;; get the raw data in volts (step 1 output) 
thm_cal_scm, probe=satname, datatype=mode, out_suffix = '_volt',$
             trange=trange,$
             step = 1

;; default values of parameters are shown.
;; the '*' appended to mode will get diagnostic parameters
;; (_iano, _dc, _misalign) as well as calibrated output.  Note out_suffix
;; is necessary to get what was former default behavior (_cal on output)
;; To run with different parameters, uncomment and change as
;; you like.
;; Note: the /edge_zero is not a default option, so the output will differ
;; slightly from step 4a) above.

;; Cleanup informations
;; To perform a full cleanup of spin tones (power ripples) and 8/32 Hz tones --> cleanup ='full'
;; cleanup is based on superposed epoch analysis suggested by C. C. Chaston using an averaging window
;; spin tones cleanup corresponds to an averaging window duration exactly equal to the spin period
;; which is fixed in the code (wind_dur_sp = spinper)
;; 8/32 Hz tones cleanup corresponds to an averaging window equal to a multiple of 1s
;; this averaging window duration can be chosen by the keyword wind_dur_1s
;; To perform only a cleanup of spin tones (power ripples) --> cleanup='spin'
;; To perform no cleanup --> comment cleanup keyword

thm_cal_scm, probe=satname, datatype=mode+'*', out_suffix = '_cal', $
             trange=trange, $
;             nk  = 512, $
;             mk = 4, $
;             Despin=1, $
;             N_spinfit = 2, $
 	      cleanup = 'full',$
;             clnup_author = 'ole', $
;	      wind_dur_1s = 1.,$
;	      wind_dur_spin = 1.,$
;             Fdet = 0., $
;             Fcut = 0.1, $
             Fmin = 0.45, $
;             Fmax = 0., $
;             step = 4, $
             /edge_zero

;;    =========================================
;; 5) Plot calibrated data
;;    =========================================

; ytitles are set as follows by thm_cal_scm:
;  options, thscs_mode+'_cal', 'YTITLE', $
;           'th'+satname+' '+mode+' '+str_Fsamp+' (nT)'

;; label the plot with calibration parameter string, which
;; can be retrieved from the metadata:

  get_data, thscs_mode+'_cal', dl = dl

  tplot_options,'charsize',0.7
  tplot_options, 'title', 'SCM calibrated data'
  tplot_options, 'subtitle', dl.data_att.str_cal_param
  tplot,thscs_mode+'_cal', trange=trange

print, 'type .c to plot diagnostic data: '
print, '   the raw signal in volts, '
print, '   the raw signal after despin, before cleanup, '
print, '   the raw signal after despin, spin cleanup, '
print, '   the raw signal after despin, spin cleanup and 8/32Hz cleanup, '
print, '   the misalignment angle between the SCM spin-plane antennas, '
print, '   the DC signal removed in the despin step, and'
print, '   the anomaly code'
stop
 tplot_options, 'title', 'SCM calibrated data and diagnostic outputs'
 tplot_options, 'subtitle', ''
 options, thscs_mode+'_iano',psym=2
 tplot, [thscs_mode+'_[cidmv]*'], trange=trange

print, 'type .c to see an example of the self-calibration signal'
stop
;;========================
;; 6) Load data which shows SCM onboard calibration signal
;;=======================

trange = ['2007-03-14/14:47:52', '2007-03-14/14:49:20']
satname = 'd'
mode = 'scp'

thm_load_scm, probe=satname, datatype=mode+'*', level=1, suffix = '_cal', $
             trange=trange

tplot, ['thd_scp_cal'], trange=trange


print, 'this is the SCM self-calibration signal -- the signal stops'
print, '        at about 14:49:01.'
print, 'type .c to see it properly in SCS (SCM Sensor) coordinates'
stop

thm_load_scm, probe=satname, datatype=mode+'*', level=1, type='raw', $
             trange=trange, /get_support
thm_load_state, probe=satname, /get_support_data

thm_cal_scm, probe=satname, datatype=mode+'*', out_suffix = '_s3', $
             trange=trange, $
             step = 3, $
             /edge_zero

str_Fsamp = string(dl.data_att.Fsamp ,format='(f5.0)')
options, 'thd_scp_s3', 'ytitle', 'thd scp scs!C'+str_Fsamp+'!C[nT]'
 tplot_options, 'title', 'SCM self-calibration signal'
tplot, ['thd_scp','thd_scp_cal', 'thd_scp_s3']

print, 'type .c to zoom in even closer to see the triangle wave'
stop

tlimit, ['2007-03-14/14:48:30', '2007-03-14/14:48:31']

  PRINT, 'Ready for other processing'
  PRINT, 'End of thm_crib_scm.pro batch file'
  PRINT, '-----------------------------------------'

;; ********************************************
;; end of thm_crib_scm.pro
;; ********************************************

end
