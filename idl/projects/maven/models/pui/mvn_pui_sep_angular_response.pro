;20170222 Ali
;SEP effective area vs angle of incidence
;the first 3 arguments are inputs
;the next 2 arguments are outputs
;use keyword /plot to plot the angular response

pro mvn_pui_sep_angular_response,cosvsep1,cosvsep2,cosvswiy,sdea1,sdea2,plot_response=plot_response

cosfovsep  =cos(!dtor*30.0) ;sep half opening angle (assuming conic)
cosfovsepxy=cos(!dtor*21.0) ;sep cross angle (half angular extent) in sep xy plane (s/c xz)
cosfovsepxz=cos(!dtor*15.5) ;sep ref   angle (half angular extent) in sep xz plane (s/c yz)
eda=1.083 ;effective detector area (cm2) from GEANT4 and CAD model

if keyword_set(plot_response) then begin
  phi=!dtor*findgen(360)
  theta=!dtor*findgen(30)
  x=sin(theta)#cos(phi)
  y=sin(theta)#sin(phi)
  z=cos(theta)#replicate(1.,360)
  cosvsep1=z
  cosvsep2=x
  cosvswiy=y
endif

cosvsep1xy=cosvsep1/sqrt(cosvsep1^2+cosvswiy^2); cosine of angle b/w projected -v on sep1 xy plane and sep1 fov
cosvsep2xy=cosvsep2/sqrt(cosvsep2^2+cosvswiy^2); cosine of angle b/w projected -v on sep2 xy plane and sep2 fov
cosvsep1xz=cosvsep1/sqrt(cosvsep1^2+cosvsep2^2); cosine of angle b/w projected -v on sep1 xz plane and sep1 fov
cosvsep2xz=cosvsep2/sqrt(cosvsep1^2+cosvsep2^2); cosine of angle b/w projected -v on sep2 xz plane and sep2 fov
sdea1xy=(cosvsep1xy-cosfovsepxy)/(1-cosfovsepxy) ;sep projected detector effective area on sep1 xy plane
sdea2xy=(cosvsep2xy-cosfovsepxy)/(1-cosfovsepxy)
sdea1xz=(cosvsep1xz-cosfovsepxz)/(1-cosfovsepxz)
sdea2xz=(cosvsep2xz-cosfovsepxz)/(1-cosfovsepxz)

sdea1=eda*sdea1xy*sdea1xz ;sep detector effective area factor (cm2)
sdea2=eda*sdea2xy*sdea2xz

;very small sep detector area within cosfovsep (cm2)
sdea1[where((cosvsep1xy lt cosfovsepxy) or (cosvsep1xz lt cosfovsepxz),/null)]=1e-2 ;similar to a closed attenuator
sdea2[where((cosvsep2xy lt cosfovsepxy) or (cosvsep2xz lt cosfovsepxz),/null)]=1e-2
sdea1[where(cosvsep1 lt cosfovsep,/null)]=0.
sdea2[where(cosvsep2 lt cosfovsep,/null)]=0.

if keyword_set(plot_response) then begin
  p=image(transpose(sdea1),min=0,max=1.2,aspect_ratio=0,margin=.2,axis_style=2,rgb_table=33,xtitle='Azimuth Angle (Degrees)',ytitle='Polar Angle (Degrees)',title='SEP FOV Response')
  p=colorbar(orientation=1,title='Effective Area (cm2)')
endif

end