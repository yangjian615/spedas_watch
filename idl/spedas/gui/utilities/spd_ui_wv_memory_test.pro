;+
;NAME:
;spd_ui_wv_memory_test
;PURPOSE: 
;Estimate of memory used by a wavelet transform. The estimated memory
;use is 36.26*n_elements(transformed_data.y). The factor of 36 comes
;from testing different transforms for different types of data, for
;fgm (FGH and FGS) data, 2009-01-14, for ESA L2 density data
;2007-07-07, and for GMAG data for both of those days. Note that this
;is currently only useful for default inputs.
;INPUT: 
; t = the time array
;OUTPUT: 
; jv = the number of wavelets to eventually be used, jv must be GT 1
;      for the wavelet2 routine to work.
;HISTORY:
; 10-jun-2009, jmm, added jv output to test for a reasonable number of
; wavelets later.
; 19-Jan-2015, jmm, Changed the name and separated into a new file
;$LastChangedBy: jimm $
;$LastChangedDate: 2015-01-20 13:26:51 -0800 (Tue, 20 Jan 2015) $
;$LastChangedRevision: 16692 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas/gui/utilities/spd_ui_wv_memory_test.pro $
;-
Function spd_ui_wv_memory_test, t, jv      ;t is the input time array, jv is the number of wavelets used
  n = n_elements(t)
  dt = (t[1:*]-t)
  
  ;dt = mean(t[1:*]-t)
;Hacked from wavelet2.pro -- these are defaults different from wavelet.pro
  ;w0 = 2.*!pi
  ;dj = 1/8.*(2.*!pi/w0)
  ;prange = [2.*dt, 0.05*n*dt] ; default range = nyquist period - 5% of time period
  ;srange = (2.*dt > prange < n*dt) * (w0+sqrt(2+w0^2))/4/!pi
  ;srange = (prange) * (w0+sqrt(2+w0^2))/4/!pi ;srange are the scales of the wavelets
  ;jv = FIX((ALOG(srange[1]/srange[0])/ALOG(2))/dj);jv+1 is the number of wavelets used


;Check for resampling later in wave_data procedure,
;default is to use mean value
  if total(abs(minmax(dt)/mean(dt)-1)) gt .01 then begin
    dprint,'Using resampled estimate'
        
    ;Resampling will occur at intervals of the median period, 
    times = round(dt/median(dt))

    ;Get total number of points in resample
    n = total(times, /preserve) + 1
    
  endif
  ;jv+1 is the number of wavelets used
  jv = fix( 8*( alog(.05*n)/alog(2) -1 ) ) ;simplified calculation
  
;The memory used in bytes is approximately 36 times the number of
;elements in the final product.  Added 16% margin to account for spikes.
  Return, 1.16*36.26*float(n)*float(jv+1)
  
End


