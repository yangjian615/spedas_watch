;+
;PROCEDURE: 
;	MVN_SWIA_FIT_STEP
;PURPOSE: 
;	Routine to fit discontinuity, in order to find attenuator and mode switches
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	MVN_SWIA_FIT_STEP, Series, Ratio, Ind
;INPUTS:
;	Series: A series of 17 values
;	Ratio: The expected ratio before/after discontinuity
;OUTPUTS
;	Ind: Index where the change occurred
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2013-12-14 13:53:13 -0800 (Sat, 14 Dec 2013) $
; $LastChangedRevision: 13669 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_fit_step.pro $
;
;-

pro mvn_swia_fit_step, series, ratio, ind

; take one from packet after to pad w/ known value
; result is index where first post-change value should be located

mult = fltarr(17)
cc = fltarr(17)

for i = 1,16 do begin
	mult(0:i-1) = 1.0
	mult(i:16) = ratio

	cc(i) = correlate(mult,series)

endfor

mincc = max(cc,mini)

ind = mini

end