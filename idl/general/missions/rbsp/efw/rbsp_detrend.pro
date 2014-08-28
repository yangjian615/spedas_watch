;Detrends tplot data with boxcar average. 
;Returns two new tplot variables
;	tname + '_mean' -> the mean value
;	tname + '_detrend' -> original data - mean value 


;tnames -> array of tplot variables
;sec -> seconds used to calculate the mean value
;mean -> set to do mean value instead of boxcar average


;Created by: Aaron Breneman
;2012-11-05



pro rbsp_detrend,tnames,sec,mean=mean

	tn = tnames(tnames)

	;Defaults to boxcar average
	if ~keyword_set(mean) then boxcar = 1


	if ~keyword_set(sec) then sec = 60.
	
	for j=0,n_elements(tn)-1 do begin

		get_data,tn[j],data=dat

		if is_struct(dat) then begin

			;Calculate sample rate	
			sr = 1/(dat.x[1]-dat.x[0])
			n_samples = sr*sec
			num = n_elements(dat.x)/n_samples
		

			;----------------------------------
			;Do boxcar average (default)
			;----------------------------------

			if keyword_set(boxcar) then begin

				;calculate width to smooth over
				width = floor(sec * sr)


				dat_smoothed = smooth(dat.y,width,/nan)

				store_data,tn[j] + '_smoothed',data={x:dat.x,y:dat_smoothed}
				store_data,tn[j] + '_detrend',data={x:dat.x,y:dat.y - dat_smoothed}
		
			endif


			;---------------------------
			;Average using mean value
			;---------------------------

			if keyword_set(mean) then begin

				;Find the mean value over a timespan of "sec"
				avg_vals = fltarr(num)
				for i=0L,num-2 do avg_vals[i] = mean(dat.y[i*n_samples:i*n_samples+n_samples,0])
			
				;Remove the last value which is zero
				avg_vals[n_elements(avg_vals)-1] = !values.f_nan
			
				;define time array (use middle value of X min period as time definition for each bin)
				t0 = dat.x[n_samples/2.]
				ttmp = indgen(num)*sec + t0
			
				;Interpolate mean-value data up to the sample rate	
				vals2 = interpol(avg_vals,ttmp,dat.x)
			
	
				store_data,tn[j] + '_mean',data={x:dat.x,y:vals2}
				store_data,tn[j] + '_detrend',data={x:dat.x,y:dat.y[*,0]-vals2}
			
				rbsp_remove_spikes,tn[j] + '_detrend',/samename

			endif
		

		endif else print,'NO TPLOT VARIABLE ' + tn[j]


	endfor

end