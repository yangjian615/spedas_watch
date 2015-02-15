pro mvn_spc_fov_blockage, swea=swea,$
                          static=static, $
                          oplot=oplot, $
                          clr=clr


  ;;---------------------------
  ;;Get MAVEN Vertices
  inst=maven_spacecraft_vertices()
  vertex=inst.vertex
  index=inst.index


  ;;---------------------------
  ;;Instrument and Gimbal location

  ;;Inner Gimbal
  g1_gim_loc=[2585.00,203.50, 2044.00]
  ;;Outer Gimbal
  g2_gim_loc=[2775.00,203.50, 2044.00]
  ;;STATIC
  sta_loc=[ 3127.00, 1847.00, 1847.50]
  ;;SWEA
  swe_loc=[ -2360.00,   0.00,-1115.00]
  ;;SWIA
  swi_loc=[ 3126.00, 1847.00, -450.00]
  ;;SEP 
  sep_loc=[ 3126.00, 1847.00, -450.00]





  goto, skip
  ;;-------------------------------------------------------------
  ;;If STATIC, find all rotations for the first and second gimbal
  ttt=timerange()
  tt=time_string(ttt)
  mk = mvn_spice_kernels(/all,/load,trange=trange,verbose=verbose)
  cspice_str2et,tt,et
  time_valid = spice_valid_times(et,object=check_objects,tol=tol)

 
  ;;#####
  ;;1st: Rotate STATIC FOV location about Xs/c by theta degrees
  ;;This is the equivalent of rotating around the outer gimble.
  ;;We must therefore set the outer gimbal as the center of rotation,
  ;;rotate the point describing STATIC FOV focus, and then back to the
  ;;original positon.
  shift=g2_gim_loc
  sta_loc_new=sta_loc-shift
  cspice_pxform, 'MAVEN_APP_OG', 'MAVEN_APP_IG', et, rot_g1
  theta=0
  rot1=[[1.,         0.,             0.],$
        [0., cos(theta), -1.*sin(theta)],$
        [0., sin(theta), -1.*cos(theta)]]
  sta_loc_new2=transpose(rot1) # sta_loc_new
  sta_loc=sta_loc_new2+shift




  ;;######
  ;;2nd: Rotate new_loc about Ys/c by phi degrees
  ;;This is the equivalent of rotating around the inner gimble
  shift=g1_gim_loc
  sta_loc_new=sta_loc-shift
  cspice_pxform, 'MAVEN_APP_IG', 'MAVEN_APP_BP', et, rot_g2
  phi=0.
  rot2=[[cos(phi),   0.,       sin(phi)],$
        [0.,         1.,             0.],$
        [0., sin(theta), -1.*cos(theta)]]
  sta_loc_new2=transpose(rot2) # sta_loc_new
  sta_loc=sta_loc_new2+shift
  skip:







  if keyword_set(oplot) then begin

     ;window,2,xsize=900,ysize=900

     ;;Shift over to Instrument location
     if keyword_set(swea) then shift=swe_loc else shift=sta_loc
     vertex[0,*,*]=vertex[0,*,*]-shift[0]
     vertex[1,*,*]=vertex[1,*,*]-shift[1]
     vertex[2,*,*]=vertex[2,*,*]-shift[2]


     ;;--------------------------
     ;;Check array size
     n1=3
     n2=8
     n3=n_elements(vertex)/n1/n2
     
     ;;----------------------------------------------
     ;;Change coordinates from cartesian to spherical
     cspice_recsph, reform(vertex,n1,n2*n3), r, theta, phi
     theta=reform(theta, n2, n3)
     phi=reform(phi, n2, n3)

     ;plot, [0,180],[0,360], $
     ;      /nodata, $
     ;      ytitle='THETA (0-180)',$
     ;      xtitle='PHI (-180-180)',$
     ;      yrange=[0,180],$
     ;      xrange=[-180,180],$
     ;      xstyle=1,$
     ;      ystyle=1
           

     ;;-------------------------------------
     ;;Start Drawing
     if keyword_set(clr) then clr1=clr else clr1=0
     for iobj=0, 11 do begin
        for i=0, 5 do begin
           phi_temp=phi[*,iobj]*!RADEG
           theta_temp=theta[*,iobj]*!RADEG
           ind=index[*,*,iobj]           
           indd=[ind[*,i],ind[0,i]]
           oplot, phi_temp[indd], theta_temp[indd],color=clr1 
        endfor
     endfor    

  endif







end


