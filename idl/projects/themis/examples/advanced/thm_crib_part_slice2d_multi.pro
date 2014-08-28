


;===========================================================
; Multiple Slices
;===========================================================
;+
; 
; A Secondary Crib: Create Multiple Slices and Export:
; 
; 
;-

PRO thm_crib_part_slice2d_multi

; Choose output location:

outputfolder='C:\THEMIS\slice_crib\' ;Modify and uncomment this line if you're using Windows
;outputfolder='/THEMIS/slice_crib/'  ;Modify and uncomment this line if you're using Mac/Unix/Linux



; Load Data
;-----------

; Set time range
day = '2008-02-26/'
start_time = time_double(day + '04:50:00')
end_time = time_double(day + '04:55:00')

; pad time range to ensure enough data is loaded
trange=[start_time - 90, end_time + 90]

; set data types
probe = 'b'
type = 'pseb'

; This example will use geometric coordinates so skip loading of mag & velocity data
;thm_load_fgm, probe=probe, datatype = 'fgh', level=2, coord='dsl', trange=trange
;thm_load_esa, probe=probe, datatype = 'peeb_velocity_dsl', trange=trange


; Create array of SST particle distributions
;  -use SST contamination removal
dist_arr = thm_part_dist_array(probe=probe,type=type, trange=trange, $
                method_sunpulse_clean = 'median', mask_remove = .99)



;Set Options
;------------

timewin = 60.   ; set the time window for each slice
incriment = 30. ; time incriment for next slice's start

coord = 'gsm'   ; GSM coordinates

slice_norm = [0,1,0] ; slice along x-z plane
slice_x = [0,0,1]    ; use z-axis as the slice's x-axis

erange = [0,5e5]; limit energy range

range = [2.2e-27, 2.2e-20] ; plot using fixed range



; Use loop to create multiple slices and export plots
;----------------------------------------------------

slice_time = start_time

while slice_time lt end_time do begin
  
  ;Create slice
  thm_part_slice2d, dist_arr, slice_time=slice_time, timewin=timewin, $
                    coord=coord, rotation=rotation, erange=erange, $
                    slice_norm=slice_norm, slice_x=slice_x, $
                    part_slice=part_slice, $
                    fail=fail

  ; Check for errors,
  ; the FAIL variable will contain a string message if something goes wrong
  if keyword_set(fail) then begin
    print, 'An error occured while creating the slice at '+time_string(slice_time)+':'
    print, fail
  endif

  ;create filename for image
  outputfile = outputfolder + time_string(format=2,slice_time) + '_th'+probe+'_'+type


  ;Call plotting procedure
  thm_part_slice2d_plot, part_slice, range=range, $ ;constant range
;                   /eps, $            ;set this keyword to export to postscript
                   export=outputfile   ;automatically export
 


  slice_time += incriment ;increment time
  
endwhile


END
