function mvn_sep_rebin_matrix,mapid,sens

   n_p = 30
   n_e = 16
   bmap = mvn_sep_get_bmap(mapid,sens)

     bins = bmap[ where(bmap.name eq 'A-O') ].bin
     rev_ion = fltarr(n_elements(bins),256 )
     for i=0,n_elements(bins)-1 do rev_ion[i,bins[i]] = 1.

     bins = bmap[ where(bmap.name eq 'B-O') ].bin
     for_ion = fltarr(n_elements(bins),256 )
     for i=0,n_elements(bins)-1 do for_ion[i,bins[i]] = 1.
     
     bins = bmap[ where(bmap.name eq 'A-F') ].bin
     for_elec = fltarr(n_elements(bins),256 )
     for i=0,n_elements(bins)-1 do for_elec[i,bins[i]] = 1.

     bins = bmap[ where(bmap.name eq 'B-F') ].bin
     rev_elec = fltarr(n_elements(bins),256 )
     for i=0,n_elements(bins)-1 do rev_elec[i,bins[i]] = 1.
     
     if mapid eq 9 then begin
       for_ion = for_ion[2:*,*]
       rev_ion = rev_ion[2:*,*]
       for_elec = for_elec[2:16,*]
       rev_elec = rev_elec[2:16,*]
     endif
     
     if 0 then  begin     ;  reduce to 4 bins
       remap = intarr(4,30)
       remap[0,2:5] = 1
       remap[1,6:9] = 1
       remap[2,10:19] = 1
       remap[3,20:29] = 1
       rev_ion = remap # rev_ion
       for_ion = remap # for_ion      
     endif
          
     mat={  $
       f_ion : for_ion  , $
       f_ion_energy :   for_ion # bmap.nrg_meas_avg   /  total(for_ion,2)   ,$
       f_ion_denergy :   for_ion # bmap.nrg_meas_delta ,$
       r_ion : rev_ion  , $
       r_ion_energy :   rev_ion # bmap.nrg_meas_avg   /  total(rev_ion,2)   ,$
       r_ion_denergy :   rev_ion # bmap.nrg_meas_delta ,$
       f_elec: for_elec , $
       r_elec: rev_elec , $
       mapid: mapid,  $
       sens: sens, $
       bmap: bmap $
     }
        
return,mat
end






pro mvn_sep_conv_units,  rawdat, bkgdat,  exmat, bmap,  subflux=subflux, uncflux=uncflux, nrg=nrg_nt, dnrg=dnrg_nt, sub_eflux=sub_eflux,unc_eflux=unc_eflux, $
   tot_eflux_sub=tot_eflux_sub, tot_eflux_unc=tot_eflux_unc
  ; exmat                          ; n_s x 256

  geoms = [!values.f_nan,.18, .0018, !values.f_nan]
  dt = rawdat.duration            ;  n_t
  att_state = rawdat.ATT          ;  n_t
  geom = geoms[att_state]             ;  n_t
  ;     one_nt  = replicate(1.,nt)
  data = rawdat.data            ;  256 x n_t

  eff = 1.   ; Note : efficiency not yet included!!!

  dim = size(/dimen,exmat)            ;  [n_s,256]
  n_s = dim[0]
  n_t = n_elements(rawdat)
  one_nt = replicate(1,n_t)
  one_ns = replicate(1,n_s)           ;  n_s
  nrg  = exmat # bmap.nrg_meas_avg   / ( total(exmat,2) )  ;    n_s
  dnrg = exmat # bmap.nrg_meas_delta                       ;    n_s
  
  nrg_nt = nrg # one_nt
  dnrg_nt = dnrg # one_nt

  bkgcnts = exmat # bkgdat.data                   ;  n_s
  bkgrate = bkgcnts / bkgdat.duration             ;  n_s
  cnts = exmat # data                             ;  n_s x n_t
  subcnts = cnts ;- (bkgrate # dt)                 ;  n_s x n_t
  unccnts = sqrt((cnts) + (bkgrate # dt))    ;  n_s x n_t       ; Note: no artificial counts are added to cnts for sigma
  subrate = subcnts / ( one_ns # dt)
  uncrate = unccnts / ( one_ns # dt)
  subflux = subrate / ((dnrg*eff) # geom)
  uncflux = uncrate / ((dnrg*eff) # geom)
  
  if arg_present(sub_eflux) then sub_eflux = subrate / ( (dnrg*eff/nrg) # geom )
  if arg_present(unc_eflux) then unc_eflux = uncrate / ( (dnrg*eff/nrg) # geom )
  
 ; if arg_present(tot_eflux_sub) then tot_eflux_sub = total(sub_eflux[3;*,*],1)
 ; if arg_present(tot_eflux_sub) then tot_eflux_unc = total(unc_eflux[3;*,*],1)

end  




pro mvn_sep_rebin,data,ddata,rebin
data = rebin # data
ddata = sqrt( rebin # ddata^2)
end


function mvn_sep_get_cal_units ,rawdat  ,units_names=units_name,background=bkgdat

  if not keyword_set(rawdat) then begin
    dprint,'No data'    
    return,0
  endif


 if keyword_set(units_name) then zval = units_name
 if not keyword_set(yval) then yval = 'Energy'
 if not keyword_set(zval) then zval = 'Rate'

 sepn = byte(median(rawdat.sensor))


if ~keyword_set(bkgdat) then begin
  dprint,dlevel=1,"Background distribution not provided - using default
  bkgdat = rawdat[0]
  bkgdat.data = .2
  bkgdat.duration = 1
  bkgdat.trange = 0
endif

nan=!values.f_nan
n_p = 28
n_e = 15
n_x = 8
n_cr = 10

str_additions = {   $
    bkg_timeRange:     [0d,0d], $
    F_ion_flux :     replicate(nan,n_p),  $
    F_ion_flux_unc : replicate(nan,n_p),  $
    F_ion_eflux :     replicate(nan,n_p),  $
    F_ion_eflux_unc : replicate(nan,n_p),  $
    F_ion_energy:    replicate(nan,n_p),  $
    F_ion_denergy:    replicate(nan,n_p),  $
    F_elec_flux:     replicate(nan,n_e),  $
    F_elec_flux_unc: replicate(nan,n_e),  $
    F_elec_eflux:     replicate(nan,n_e),  $
    F_elec_eflux_unc: replicate(nan,n_e),  $
    F_elec_energy:   replicate(nan,n_e) , $
    F_elec_denergy:   replicate(nan,n_e) , $
    R_ion_flux :     replicate(nan,n_p),  $
    R_ion_flux_unc : replicate(nan,n_p),  $
    R_ion_eflux :     replicate(nan,n_p),  $
    R_ion_eflux_unc : replicate(nan,n_p),  $
    R_ion_energy:    replicate(nan,n_p),  $
    R_ion_denergy:    replicate(nan,n_p),  $
    R_elec_flux:     replicate(nan,n_e),  $
    R_elec_flux_unc: replicate(nan,n_e),  $
    R_elec_eflux:     replicate(nan,n_e),  $
    R_elec_eflux_unc: replicate(nan,n_e),  $
    R_elec_energy:   replicate(nan,n_e) , $
    R_elec_denergy:   replicate(nan,n_e) , $
    A_xray_rate:       replicate(nan,n_x) ,  $
    B_xray_rate:       replicate(nan,n_x) ,  $
    A_fto_rate:        replicate(nan,n_cr) ,  $
    B_fto_rate:        replicate(nan,n_cr) ,  $
    F_Ion_eflux_tot:   nan, $
    F_elec_eflux_tot:  nan, $
    R_Ion_eflux_tot:   nan, $
    R_elec_eflux_tot:  nan, $
    F_Ion_eflux_tot_unc:   nan, $
    F_elec_eflux_tot_unc:  nan, $
    R_Ion_eflux_tot_unc:   nan, $
    R_elec_eflux_tot_unc:  nan, $
    F_Ion_flux_tot:   nan, $
    F_elec_flux_tot:  nan, $
    R_Ion_flux_tot:   nan, $
    R_elec_flux_tot:  nan, $
    F_Ion_flux_tot_unc:   nan, $
    F_elec_flux_tot_unc:  nan, $
    R_Ion_flux_tot_unc:   nan, $
    R_elec_flux_tot_unc:  nan, $
    F_lookdir:      [nan,nan,nan] , $
    R_lookdir:      [nan,nan,nan] , $
    quality_flag: 0ul $    
  }
  
  
  str_additions.bkg_timerange = bkgdat.trange

  rawdat0 = rawdat[0]
  data_str0 = create_struct(rawdat0,str_additions)
  
  caldata = replicate(data_str0,n_elements(rawdat))
  
  
  tags0 = tag_names(rawdat0)
  for i=0,n_elements(tags0)-1 do caldata.(i) = rawdat.(i)      ; copy contents
  
  ;  geoms = [!values.f_nan,.18, .0018, !values.f_nan]


  if not keyword_set(mapids) then begin
      mapids1 = byte(median(rawdat.mapid))    ;  get most common mapnum
      mapids2 = where( histogram(rawdat.mapid) ne 0 ,n_mapids)   ; all mapids found
      dprint,dlevel=3,verbose=verbose,/phelp,mapids
      mapids=mapids1   ; do only most common one  
  endif 
  

  for i = 0,n_elements(mapids)-1 do begin
     mapid = mapids[i]
     if mapid ne 9 then continue
     wt = where(rawdat.mapid eq mapid,nt)
     if nt le 0 then continue  
 
     convmat = mvn_sep_rebin_matrix(mapid,sepn)
     bmap = convmat.bmap
     
     mvn_sep_conv_units, rawdat[wt], bkgdat, convmat.f_ion ,bmap,  subflux=subflux, uncflux=uncflux, nrg=nrg, dnrg=dnrg, sub_eflux=sub_eflux, unc_eflux=unc_eflux
     caldata[wt].f_ion_flux = subflux
     caldata[wt].f_ion_flux_unc = uncflux
     caldata[wt].f_ion_eflux = sub_eflux
     caldata[wt].f_ion_eflux_unc = unc_eflux
     caldata[wt].f_ion_energy  = nrg
     caldata[wt].f_ion_denergy = dnrg
     caldata[wt].f_ion_eflux_tot = total(sub_eflux * dnrg,1)
     caldata[wt].f_ion_eflux_tot_unc = sqrt( total((unc_eflux * dnrg)^2,1))
     caldata[wt].f_ion_flux_tot = total(subflux * dnrg,1)
     caldata[wt].f_ion_flux_tot_unc = sqrt( total((uncflux * dnrg)^2,1))

     mvn_sep_conv_units, rawdat[wt], bkgdat, convmat.r_ion ,bmap,  subflux=subflux, uncflux=uncflux, nrg=nrg, dnrg=dnrg, sub_eflux=sub_eflux, unc_eflux=unc_eflux
     caldata[wt].r_ion_flux = subflux
     caldata[wt].r_ion_flux_unc = uncflux
     caldata[wt].r_ion_eflux = sub_eflux
     caldata[wt].r_ion_eflux_unc = unc_eflux
     caldata[wt].r_ion_energy  = nrg
     caldata[wt].r_ion_denergy = dnrg
     caldata[wt].r_ion_eflux_tot = total(sub_eflux * dnrg,1)
     caldata[wt].r_ion_eflux_tot_unc = sqrt( total((unc_eflux * dnrg)^2,1))

     mvn_sep_conv_units, rawdat[wt], bkgdat, convmat.f_elec ,bmap,  subflux=subflux, uncflux=uncflux, nrg=nrg, dnrg=dnrg, sub_eflux=sub_eflux, unc_eflux=unc_eflux
     caldata[wt].f_elec_flux = subflux
     caldata[wt].f_elec_flux_unc = uncflux
     caldata[wt].f_elec_eflux = sub_eflux
     caldata[wt].f_elec_eflux_unc = unc_eflux
     caldata[wt].f_elec_energy  = nrg
     caldata[wt].f_elec_denergy = dnrg
     caldata[wt].f_elec_eflux_tot = total(sub_eflux * dnrg,1)
     caldata[wt].f_elec_eflux_tot_unc = sqrt( total((unc_eflux * dnrg)^2,1))

     mvn_sep_conv_units, rawdat[wt], bkgdat, convmat.r_elec ,bmap,  subflux=subflux, uncflux=uncflux, nrg=nrg, dnrg=dnrg, sub_eflux=sub_eflux, unc_eflux=unc_eflux
     caldata[wt].r_elec_flux = subflux
     caldata[wt].r_elec_flux_unc = uncflux
     caldata[wt].r_elec_eflux = sub_eflux
     caldata[wt].r_elec_eflux_unc = unc_eflux
     caldata[wt].r_elec_energy  = nrg
     caldata[wt].r_elec_denergy = dnrg
     caldata[wt].r_elec_eflux_tot = total(sub_eflux * dnrg,1)
     caldata[wt].r_elec_eflux_tot_unc = sqrt( total((unc_eflux * dnrg)^2,1))

     dprint,verbose=verbose,dlevel=3,/phelp,mapnum,mapname,sepn
   endfor
   
;   lookdir_SC = [[0,-1,1],[0,1,1]]/sqrt(2)
;   ldir = lookdir_sc[*,sepn]
;   printdat,ldir
;   if spice_test() then caldata. spice_vector_rotate(ldir
   
;   caldata.f_lookdir
   
   return,caldata
end





mvn_sep_extract_data,'mvn_sep2_svy',rawdat;,trange=[time_double('14 9 22 21'),systime(1)]
;printdat,rawdat

raw_data=transpose(rawdat.data)
raw_data=smooth_counts(raw_data)
rawdat.data=transpose(raw_data)

bkgfile=mvn_pfp_file_retrieve('maven/data/sci/sep/l1/sav/sep2_bkg.sav')
restore,file=bkgfile,/verb
; mvn_sep_spectra_plot,bkg2

newdat = mvn_sep_get_cal_units(rawdat,background = bkg2)


;
data = newdat.f_ion_flux
;ddata = newdat.f_ion_flux_unc
;

dim = size(/dimen,data)
r = intarr( dim[0] )
r[0:2] = 0
r[3:9] = 0
r[10:19] = 1
r[20:*]  = 2
;printdat,r
;printdat,minmax(r)
d1 = max(r) +1
rr = fltarr( d1, dim[0] )
h = histogram(r,reverse=rev)
for i=0,d1-1 do if h[i] ne 0 then  rr[i,  Rev[Rev[i] : Rev[i+1]-1] ] =1

rr = fltarr( d1, dim[0] )
rr[0,5:12]=1
rr[1,13:20]=1
rr[2,21:27]=1


data = newdat.f_ion_eflux
ddata = newdat.f_ion_eflux_unc


bad = data lt .0* ddata 
w = where(bad)
;data[w] = !values.f_nan
store_data,'sep2F_ion_eflux',newdat.time,transpose(data),transpose(newdat.f_ion_energy),dlim={spec:1,yrange:[10,6000.],ystyle:1,ylog:1,zrange:[100.,1e5],zlog:1,panel_size:2}





data = newdat.r_ion_eflux
ddata = newdat.r_ion_eflux_unc
bad = data lt .0* ddata
;w = where(bad)
data[w] = !values.f_nan
store_data,'sep2R_ion_eflux',newdat.time,transpose(data),transpose(newdat.R_ion_energy),dlim={spec:1,yrange:[10,6000.],ystyle:1,ylog:1,zrange:[100.,1e5],zlog:1,panel_size:2}

data = newdat.f_ion_flux
ddata = newdat.f_ion_flux_unc
bad = data lt .0* ddata
w = where(bad)
;data[w] = !values.f_nan
store_data,'sep2F_ion_flux',newdat.time,transpose(data),transpose(newdat.f_ion_energy),dlim={spec:1,yrange:[10,6000.],ystyle:1,ylog:1,zrange:[1,1e4],zlog:1,panel_size:2}
data= rr # data
ddata= sqrt(rr # (ddata ^2))
eval0 = newdat[0].f_ion_energy
eval = (rr # eval0) / total(rr,2)
store_data,'sep2F_ion_flux_red',newdat.time,transpose(data),eval,dlim={spec:0,yrange:[.01,1e5],ystyle:1,ylog:1,zrange:[1,1e4],zlog:1,panel_size:2}

store_data,'sep2F_ion_eflux_tot',data={x:newdat.time,y:newdat.f_ion_eflux_tot},dlim={ylog:1,yrange:[1e3,1e8]}
store_data,'sep2R_ion_eflux_tot',data={x:newdat.time,y:newdat.r_ion_eflux_tot},dlim={ylog:1,yrange:[1e3,1e8]}

store_data,'sep2F_ion_flux_tot',data={x:newdat.time,y:newdat.f_ion_flux_tot},dlim={ylog:1,yrange:[100.,1e6]}
store_data,'sep2R_ion_flux_tot',data={x:newdat.time,y:newdat.r_ion_flux_tot},dlim={ylog:1,yrange:[100.,1e6]}


;print,(eval0* reform(rr[0,*]))
;print,(eval0* reform(rr[1,*]))
;print,(eval0* reform(rr[2,*]))
print,eval0[where(rr[0,*])]
print,eval0[where(rr[1,*])]
print,eval0[where(rr[2,*])]
end





