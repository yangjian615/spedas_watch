pro secs_ui_overlay_plots, trange=trange

  trange=['2008-03-09/09:30:00','2008-03-09/09:30:00']

  ; initialize variables
  defsysv,'!secs',exists=exists
  if not(exists) then secs_init
  defsysv,'!themis',exists=exists
  if not(exists) then thm_init
  thm_config
  
  if (keyword_set(trange) && n_elements(trange) eq 2) $
    then tr = timerange(trange) $
  else tr = timerange()

  inten=6001;

  ; Make the mosaic
  thm_asi_create_mosaic,time_string(tr[0]),/verbose,$            ; removed /thumb
      central_lon=275.0,central_lat=60.,scale=2.8e7,$         ; set lat to 64.5;set area scale=3.5or2.8e7 or scale=5.5e7,
      no_grid='no_grid',$
      show  =['atha','fsmi','fykn','gako','gbay','gill','inuv','kapu','kian','kuuj','mcgr','nrsq','pgeo','pina','tpas','rank','snkq','talo','tpas','whit'] ,$
      minval=[0l, 01, 01, 01, 0l, 0l, 01, 01, 01, 0l, 0l, 01, 01, 01, 0l, 0l, 01, 01, 01, 01],$
      maxval=[inten, 12000, inten, inten, inten, inten, inten, 8000, inten, inten, inten, inten, inten, 8000, inten, 5000,  8000,  inten,  8000, inten  ];
stop  
  
  thm_map_oplot_geographic_grid,$
      geographic_lons=[230,235,240,245,250,255,260,265,270,275,280,285,290,295,300],$
      geographic_lats=[50,52,54,56,58,60,62], $
      geographic_color=3,$
      geographic_linestyle=1
 stop
  
  ; set color table back
  loadct2,34
  xyouts, 235, 60, '60', charsize=2, charthick=2,color=5
  xyouts, 240, 50, '50', charsize=2, charthick=2,color=5
  xyouts, 240, 63, '240', charsize=2, charthick=2,color=5
  xyouts, 270, 60, '270', charsize=2, charthick=2,color=5
  xyouts, 300, 60, '300', charsize=2, charthick=2,color=120  
stop

  ; extract the EICS data from the tplot vars
  ; sort the data into parameters and rotate they for plotxyvec
  secs_load_data, trange=tr,  datatype=['eics']
  get_data, 'secs_eics_latlong', data=latlon
  get_data, 'secs_eics_jxy', data=jxy
stop
  plotxyvec,reverse(latlon.y),jxy.y,/overplot,color='y', thick=2.0,hsize=0.1, $
    uArrowTextPrecision=3, uarrowoffset=0.1, uarrowside='left', $
    uarrowdatasize=200, arrowscale=0.015, uArrowRotation=270
  xyouts, 245, 50.0, 'mA/m',charsize=1.0, charthick=2,color=5
stop

  oplot,[xx],[yy],color=5,psym=2,symsize=0.5,thick=3
stop
;plot position of interest E =psym 2(*); D =psym 4 (diamond); C =psym 7 (x); B=psym6
; March 09, 2008 0231 UT
;xyouts, 278.54,55.62,'E',color=2,charthick=3,charsize=1.5
;xyouts, 281.67,55.60,'D',color=2,charthick=3,charsize=1.5
;xyouts, 283.91,56.71,'C',color=2,charthick=3,charsize=1.5
; March 5, 2008 0631:30
;xyouts, 254.70,59.73,'E',color=2,charthick=3,charsize=1.5
;xyouts, 257.70,59.21,'D',color=2,charthick=3,charsize=1.5
;xyouts, 259.90,59.87,'C',color=2,charthick=3,charsize=1.5
; March 5, 2008 0634
;xyouts, 254.50,59.80,'E',color=2,charthick=3,charsize=1.5
;xyouts, 257.50,59.28,'D',color=2,charthick=3,charsize=1.5
;xyouts, 259.70,59.90,'C',color=2,charthick=3,charsize=1.5
; Feb 29, 2008 0821
;oplot, [239.90],[60.96],color=2,psym=2,symsize=0.99,thick=3
;oplot, [243.50],[60.06],color=2,psym=4,symsize=0.99,thick=3
;oplot, [215.20],[68.69],color=2,psym=7,symsize=0.99,thick=3
;oplot, [223.60],[74.03],color=2,psym=6,symsize=0.99,thick=3
;xyouts, 239.90,60.96,'E',color=2,charthick=3,charsize=1.5
;xyouts, 243.50,60.06,'D',color=2,charthick=3,charsize=1.5
;xyouts, 215.20,68.69,'C',color=2,charthick=3,charsize=1.5
;xyouts, 223.60,74.03,'B',color=2,charthick=3,charsize=1.5

; This command will plot a line across the image
; not in the right coordinates.
;plots,[285,285],[40,80], color='b'
;plots,[285,285],[40,75]


;Export to PNG
;tplot,['asi_eics_example']
;makepng will export your most recent plot to a png file
eicoutfile = 'C:\My Documents\work\THEMIS\ASI\ASI_EIC'+strmid(mstr,0,4)+strmid(mstr,5,2)+strmid(mstr,8,2)+'_'+strmid(mstr,11,2)+strmid(mstr,14,2)+strmid(mstr,17,2)
;makepng,'C:\My Documents\work\THEMIS\ASI\example'  ;extension appended automatically
makepng,eicoutfile
;write_tiff,eicoutfile
print,'  Just exported "example.png" '
print,'Type ".c" to continue crib examples.'


return
end
