;+
;PROCEDURE:	mvn_sta_l2_tplot,all=all,units=units,apids=apids,test=test,gf_nor=gf_nor
;PURPOSE:	
;	Creates tplot data from the STATIC common blocks
;INPUT:		
;
;KEYWORDS:
;	all	0/1		if not set, then raw tplot structures are deleted
;	units	string		select the units for generated tplot structures
;	apids	strarr		if set, selectes subset of apids to generate tplot structures
;	test	0/1		if set, prints out MLUT check
;	gf_nor	0/1		if set, keyword for testing 
;
;
;CREATED BY:	J. McFadden	2012/10/04
;VERSION:	1
;LAST MODIFICATION:  2014/03/14
;MOD HISTORY:
;
;
;-
pro mvn_sta_l2_tplot,all=all,units=units,apids=apids,test=test,gf_nor=gf_nor

;loadct2,43
;cols=get_colors()


if not keyword_set(all) then store_data,delete='mvn_sta_*'

;declare all the common block arrays

	common mvn_c0,mvn_c0_ind,mvn_c0_dat 
	common mvn_c2,mvn_c2_ind,mvn_c2_dat 
	common mvn_c4,mvn_c4_ind,mvn_c4_dat 
	common mvn_c6,mvn_c6_ind,mvn_c6_dat 
	common mvn_c8,mvn_c8_ind,mvn_c8_dat 
	common mvn_ca,mvn_ca_ind,mvn_ca_dat 
	common mvn_cc,mvn_cc_ind,mvn_cc_dat 
	common mvn_cd,mvn_cd_ind,mvn_cd_dat 
	common mvn_ce,mvn_ce_ind,mvn_ce_dat 
	common mvn_cf,mvn_cf_ind,mvn_cf_dat 
	common mvn_d0,mvn_d0_ind,mvn_d0_dat 
	common mvn_d1,mvn_d1_ind,mvn_d1_dat 

	common mvn_d2,mvn_d2_ind,mvn_d2_dat 
	common mvn_d3,mvn_d3_ind,mvn_d3_dat 
	common mvn_d4,mvn_d4_ind,mvn_d4_dat 
	common mvn_d6,mvn_d6_ind,mvn_d6_dat 
	common mvn_d7,mvn_d7_ind,mvn_d7_dat 
	common mvn_d8,mvn_d8_ind,mvn_d8_dat 
	common mvn_d9,mvn_d9_ind,mvn_d9_dat 
	common mvn_da,mvn_da_ind,mvn_da_dat 
	common mvn_db,mvn_db_ind,mvn_db_dat 


; C0
	if size(mvn_c0_dat,/type) eq 8 then begin

		npts = n_elements(mvn_c0_dat.time)
		iswp = mvn_c0_dat.swp_ind
		ieff = mvn_c0_dat.eff_ind
		iatt = mvn_c0_dat.att_ind
		mlut = mvn_c0_dat.mlut_ind
		nenergy = mvn_c0_dat.nenergy
		nmass = mvn_c0_dat.nmass

		time = (mvn_c0_dat.time + mvn_c0_dat.end_time)/2.
		data = mvn_c0_dat.data
		eflux = mvn_c0_dat.eflux
		energy = reform(mvn_c0_dat.energy[iswp,*,0])
		mass = total(mvn_c0_dat.mass_arr[mlut,*,*],2)/nenergy

		bkg = mvn_c0_dat.bkg
		dead = mvn_c0_dat.dead
		gf = reform(mvn_c0_dat.gf[iswp,*,0]*(iatt eq 0)#replicate(1.,nenergy) +$
		            mvn_c0_dat.gf[iswp,*,1]*(iatt eq 1)#replicate(1.,nenergy) +$
		            mvn_c0_dat.gf[iswp,*,2]*(iatt eq 2)#replicate(1.,nenergy) +$
		            mvn_c0_dat.gf[iswp,*,3]*(iatt eq 3)#replicate(1.,nenergy), npts*nenergy)#replicate(1.,nmass)
		gf = mvn_c0_dat.geom_factor*reform(gf,npts,nenergy,nmass)
		eff = mvn_c0_dat.eff[ieff,*,*]
		dt = mvn_c0_dat.integ_t#replicate(1.,nenergy*nmass)
		eflux = (data-bkg)*dead/(gf*eff*dt)
		eflux = float(eflux)
		if max(abs((eflux-mvn_c0_dat.eflux)/eflux)) gt 0. then print,'Error in c0 eflux ',max(abs((eflux-mvn_c0_dat.eflux)/eflux))

		store_data,'mvn_sta_c0_P1A_E',data={x:time,y:total(data,3),v:energy}
		store_data,'mvn_sta_c0_P1A_M',data={x:time,y:total(data,2),v:mass}
		store_data,'mvn_sta_c0_E',data={x:time,y:total(eflux,3),v:energy}
		store_data,'mvn_sta_c0_M',data={x:time,y:total(eflux,2),v:mass}
		store_data,'mvn_sta_c0_tot',data={x:time,y:total(total(data,3),2)}
		store_data,'mvn_sta_c0_att',data={x:time,y:iatt}

			ylim,'mvn_sta_c0_tot',0,0,1
			ylim,'mvn_sta_c0_P1A_E',.4,40000.,1
			ylim,'mvn_sta_c0_P1A_M',.5,100,1
			ylim,'mvn_sta_c0_E',.4,40000.,1
			ylim,'mvn_sta_c0_M',.5,100,1
			ylim,'mvn_sta_c0_att',-1,5,0

			zlim,'mvn_sta_c0_P1A_E',1,1.e4,1
			zlim,'mvn_sta_c0_P1A_M',1,1.e4,1
			zlim,'mvn_sta_c0_E',1.e3,1.e8,1
			zlim,'mvn_sta_c0_M',1.e3,1.e8,1

			datagap=7.
			options,'mvn_sta_c0_P1A_E',datagap=datagap
			options,'mvn_sta_c0_P1A_M',datagap=datagap
			options,'mvn_sta_c0_E',datagap=datagap
			options,'mvn_sta_c0_M',datagap=datagap
			options,'mvn_sta_c0_tot',datagap=datagap
	
			options,'mvn_sta_c0_P1A_E','spec',1
			options,'mvn_sta_c0_P1A_M','spec',1
			options,'mvn_sta_c0_E','spec',1
			options,'mvn_sta_c0_M','spec',1

			options,'mvn_sta_c0_P1A_E',ytitle='sta!CP1A-c0!C!CEnergy!CeV'
			options,'mvn_sta_c0_P1A_M',ytitle='sta!CP1A-c0!C!CMass!Camu'
			options,'mvn_sta_c0_E',ytitle='sta!Cc0!C!CEnergy!CeV'
			options,'mvn_sta_c0_M',ytitle='sta!Cc0!C!CMass!Camu'
			options,'mvn_sta_c0_tot',ytitle='sta!Cc0!C!CCounts'
			options,'mvn_sta_c0_att',ytitle='sta!Cc0!C!CAttenuator'

			options,'mvn_sta_c0_E',ztitle='eflux'
			options,'mvn_sta_c0_M',ztitle='eflux'
	endif

; C2
	if size(mvn_c2_dat,/type) eq 8 then begin

		npts = n_elements(mvn_c2_dat.time)
		iswp = mvn_c2_dat.swp_ind
		ieff = mvn_c2_dat.eff_ind
		iatt = mvn_c2_dat.att_ind
		mlut = mvn_c2_dat.mlut_ind
		nenergy = mvn_c2_dat.nenergy
		nmass = mvn_c2_dat.nmass

		time = (mvn_c2_dat.time + mvn_c2_dat.end_time)/2.
		data = mvn_c2_dat.data
		eflux = mvn_c2_dat.eflux
		energy = reform(mvn_c2_dat.energy[iswp,*,0])
		mass = total(mvn_c2_dat.mass_arr[mlut,*,*],2)/nenergy

		bkg = mvn_c2_dat.bkg
		dead = mvn_c2_dat.dead
		gf = reform(mvn_c2_dat.gf[iswp,*,0]*(iatt eq 0)#replicate(1.,nenergy) +$
		            mvn_c2_dat.gf[iswp,*,1]*(iatt eq 1)#replicate(1.,nenergy) +$
		            mvn_c2_dat.gf[iswp,*,2]*(iatt eq 2)#replicate(1.,nenergy) +$
		            mvn_c2_dat.gf[iswp,*,3]*(iatt eq 3)#replicate(1.,nenergy), npts*nenergy)#replicate(1.,nmass)
		gf = mvn_c2_dat.geom_factor*reform(gf,npts,nenergy,nmass)
		eff = mvn_c2_dat.eff[ieff,*,*]
		dt = mvn_c2_dat.integ_t#replicate(1.,nenergy*nmass)
		eflux = (data-bkg)*dead/(gf*eff*dt)
		eflux = float(eflux)
		if max(abs((eflux-mvn_c2_dat.eflux)/eflux)) gt 0. then print,'Error in c2 eflux ',max(abs((eflux-mvn_c2_dat.eflux)/eflux))

		store_data,'mvn_sta_c2_P1D_E',data={x:time,y:total(data,3),v:energy}
		store_data,'mvn_sta_c2_P1D_M',data={x:time,y:total(data,2),v:mass}
		store_data,'mvn_sta_c2_E',data={x:time,y:total(eflux,3),v:energy}
		store_data,'mvn_sta_c2_M',data={x:time,y:total(eflux,2),v:mass}
		store_data,'mvn_sta_c2_tot',data={x:time,y:total(total(data,3),2)}
		store_data,'mvn_sta_c2_att',data={x:time,y:iatt}

			ylim,'mvn_sta_c2_tot',0,0,1
			ylim,'mvn_sta_c2_P1D_E',.4,40000.,1
			ylim,'mvn_sta_c2_P1D_M',.5,100.,1
			ylim,'mvn_sta_c2_E',.4,40000.,1
			ylim,'mvn_sta_c2_M',.5,100.,1
			ylim,'mvn_sta_c2_att',-1,5,0

			zlim,'mvn_sta_c2_P1D_E',1,1.e4,1
			zlim,'mvn_sta_c2_P1D_M',1,1.e4,1
			zlim,'mvn_sta_c2_E',1.e3,1.e8,1
			zlim,'mvn_sta_c2_M',1.e3,1.e8,1

			datagap=7.
			options,'mvn_sta_c2_P1D_E',datagap=datagap
			options,'mvn_sta_c2_P1D_M',datagap=datagap
			options,'mvn_sta_c2_E',datagap=datagap
			options,'mvn_sta_c2_M',datagap=datagap
			options,'mvn_sta_c2_tot',datagap=datagap
			options,'mvn_sta_c2_att',datagap=datagap

			options,'mvn_sta_c2_P1D_E','spec',1
			options,'mvn_sta_c2_P1D_M','spec',1
			options,'mvn_sta_c2_E','spec',1
			options,'mvn_sta_c2_M','spec',1

			options,'mvn_sta_c2_P1D_E',ytitle='sta!CP1D-c2!C!CEnergy!CeV'
			options,'mvn_sta_c2_P1D_M',ytitle='sta!CP1D-c2!C!CMass!Camu'
			options,'mvn_sta_c2_E',ytitle='sta!Cc2!C!CEnergy!CeV'
			options,'mvn_sta_c2_M',ytitle='sta!Cc2!C!CMass!Camu'
			options,'mvn_sta_c2_tot',ytitle='sta!Cc2!C!CCounts'
			options,'mvn_sta_c2_att',ytitle='sta!Cc2!C!CAttenuator'

			options,'mvn_sta_c2_E',ztitle='eflux'
			options,'mvn_sta_c2_M',ztitle='eflux'
	endif

; C4
	if size(mvn_c4_dat,/type) eq 8 then begin

		npts = n_elements(mvn_c4_dat.time)
		iswp = mvn_c4_dat.swp_ind
		ieff = mvn_c4_dat.eff_ind
		iatt = mvn_c4_dat.att_ind
		mlut = mvn_c4_dat.mlut_ind
		nenergy = mvn_c4_dat.nenergy
		nmass = mvn_c4_dat.nmass

		time = (mvn_c4_dat.time + mvn_c4_dat.end_time)/2.
		data = mvn_c4_dat.data
		eflux = mvn_c4_dat.eflux
		energy = reform(mvn_c4_dat.energy[iswp,*,0])
		mass = total(mvn_c4_dat.mass_arr[mlut,*,*],2)/nenergy

		bkg = mvn_c4_dat.bkg
		dead = mvn_c4_dat.dead
		gf = reform(mvn_c4_dat.gf[iswp,*,0]*(iatt eq 0)#replicate(1.,nenergy) +$
		            mvn_c4_dat.gf[iswp,*,1]*(iatt eq 1)#replicate(1.,nenergy) +$
		            mvn_c4_dat.gf[iswp,*,2]*(iatt eq 2)#replicate(1.,nenergy) +$
		            mvn_c4_dat.gf[iswp,*,3]*(iatt eq 3)#replicate(1.,nenergy), npts*nenergy)#replicate(1.,nmass)
		gf = mvn_c4_dat.geom_factor*reform(gf,npts,nenergy,nmass)
		eff = mvn_c4_dat.eff[ieff,*,*]
		dt = mvn_c4_dat.integ_t#replicate(1.,nenergy*nmass)
		eflux = (data-bkg)*dead/(gf*eff*dt)
		eflux = float(eflux)
		if max(abs((eflux-mvn_c4_dat.eflux)/eflux)) gt 0. then print,'Error in c4 eflux ',max(abs((eflux-mvn_c4_dat.eflux)/eflux))

		store_data,'mvn_sta_c4_P1D_E',data={x:time,y:total(data,3),v:energy}
		store_data,'mvn_sta_c4_P1D_M',data={x:time,y:total(data,2),v:mass}
		store_data,'mvn_sta_c4_E',data={x:time,y:total(eflux,3),v:energy}
		store_data,'mvn_sta_c4_M',data={x:time,y:total(eflux,2),v:mass}
		store_data,'mvn_sta_c4_tot',data={x:time,y:total(total(data,3),2)}
		store_data,'mvn_sta_c4_att',data={x:time,y:iatt}

			ylim,'mvn_sta_c4_tot',0,0,1
			ylim,'mvn_sta_c4_P1D_E',.4,40000.,1
			ylim,'mvn_sta_c4_P1D_M',.5,100.,1
			ylim,'mvn_sta_c4_E',.4,40000.,1
			ylim,'mvn_sta_c4_M',.5,100.,1
			ylim,'mvn_sta_c4_att',-1,5,0

			zlim,'mvn_sta_c4_P1D_E',1,1.e4,1
			zlim,'mvn_sta_c4_P1D_M',1,1.e4,1
			zlim,'mvn_sta_c4_E',1.e3,1.e8,1
			zlim,'mvn_sta_c4_M',1.e3,1.e8,1

			datagap=7.
			options,'mvn_sta_c4_P1D_E',datagap=datagap
			options,'mvn_sta_c4_P1D_M',datagap=datagap
			options,'mvn_sta_c4_E',datagap=datagap
			options,'mvn_sta_c4_M',datagap=datagap
			options,'mvn_sta_c4_tot',datagap=datagap
			options,'mvn_sta_c4_att',datagap=datagap

			options,'mvn_sta_c4_P1D_E','spec',1
			options,'mvn_sta_c4_P1D_M','spec',1
			options,'mvn_sta_c4_E','spec',1
			options,'mvn_sta_c4_M','spec',1

			options,'mvn_sta_c4_P1D_E',ytitle='sta!CP1D-c4!C!CEnergy!CeV'
			options,'mvn_sta_c4_P1D_M',ytitle='sta!CP1D-c4!C!CMass!Camu'
			options,'mvn_sta_c4_E',ytitle='sta!Cc4!C!CEnergy!CeV'
			options,'mvn_sta_c4_M',ytitle='sta!Cc4!C!CMass!Camu'
			options,'mvn_sta_c4_tot',ytitle='sta!Cc4!C!CCounts'
			options,'mvn_sta_c4_att',ytitle='sta!Cc4!C!CAttenuator'

			options,'mvn_sta_c4_E',ztitle='eflux'
			options,'mvn_sta_c4_M',ztitle='eflux'
	endif

; C6
	if size(mvn_c6_dat,/type) eq 8 then begin

		npts = n_elements(mvn_c6_dat.time)
		iswp = mvn_c6_dat.swp_ind
		ieff = mvn_c6_dat.eff_ind
		iatt = mvn_c6_dat.att_ind
		mlut = mvn_c6_dat.mlut_ind
		nenergy = mvn_c6_dat.nenergy
		nmass = mvn_c6_dat.nmass

		time = (mvn_c6_dat.time + mvn_c6_dat.end_time)/2.
		data = mvn_c6_dat.data
		eflux = mvn_c6_dat.eflux
		energy = reform(mvn_c6_dat.energy[iswp,*,0])
		mass = total(mvn_c6_dat.mass_arr[mlut,*,*],2)/nenergy

		bkg = mvn_c6_dat.bkg
		dead = mvn_c6_dat.dead
		gf = reform(mvn_c6_dat.gf[iswp,*,0]*(iatt eq 0)#replicate(1.,nenergy) +$
		            mvn_c6_dat.gf[iswp,*,1]*(iatt eq 1)#replicate(1.,nenergy) +$
		            mvn_c6_dat.gf[iswp,*,2]*(iatt eq 2)#replicate(1.,nenergy) +$
		            mvn_c6_dat.gf[iswp,*,3]*(iatt eq 3)#replicate(1.,nenergy), npts*nenergy)#replicate(1.,nmass)
		gf = mvn_c6_dat.geom_factor*reform(gf,npts,nenergy,nmass)
		eff = mvn_c6_dat.eff[ieff,*,*]
		dt = mvn_c6_dat.integ_t#replicate(1.,nenergy*nmass)
		eflux = (data-bkg)*dead/(gf*eff*dt)
		eflux = float(eflux)
		if max(abs((eflux-mvn_c6_dat.eflux)/eflux)) gt 0. then print,'Error in c6 eflux ',max(abs((eflux-mvn_c6_dat.eflux)/eflux))

		store_data,'mvn_sta_c6_P1D_E',data={x:time,y:total(data,3),v:energy}
		store_data,'mvn_sta_c6_P1D_M',data={x:time,y:total(data,2),v:mass}
		store_data,'mvn_sta_c6_E',data={x:time,y:total(eflux,3),v:energy}
		store_data,'mvn_sta_c6_M',data={x:time,y:total(eflux,2),v:mass}
		store_data,'mvn_sta_c6_tot',data={x:time,y:total(total(data,3),2)}
		store_data,'mvn_sta_c6_att',data={x:time,y:iatt}

			ylim,'mvn_sta_c6_tot',0,0,1
			ylim,'mvn_sta_c6_P1D_E',.4,40000.,1
			ylim,'mvn_sta_c6_P1D_M',.5,100.,1
			ylim,'mvn_sta_c6_E',.4,40000.,1
			ylim,'mvn_sta_c6_M',.5,100.,1
			ylim,'mvn_sta_c6_att',-1,5,0

			zlim,'mvn_sta_c6_P1D_E',1,1.e4,1
			zlim,'mvn_sta_c6_P1D_M',1,1.e4,1
			zlim,'mvn_sta_c6_E',1.e3,1.e8,1
			zlim,'mvn_sta_c6_M',1.e3,1.e8,1

			datagap=7.
			options,'mvn_sta_c6_P1D_E',datagap=datagap
			options,'mvn_sta_c6_P1D_M',datagap=datagap
			options,'mvn_sta_c6_E',datagap=datagap
			options,'mvn_sta_c6_M',datagap=datagap
			options,'mvn_sta_c6_tot',datagap=datagap
			options,'mvn_sta_c6_att',datagap=datagap

			options,'mvn_sta_c6_P1D_E','spec',1
			options,'mvn_sta_c6_P1D_M','spec',1
			options,'mvn_sta_c6_E','spec',1
			options,'mvn_sta_c6_M','spec',1

			options,'mvn_sta_c6_P1D_E',ytitle='sta!CP1D-c6!C!CEnergy!CeV'
			options,'mvn_sta_c6_P1D_M',ytitle='sta!CP1D-c6!C!CMass!Camu'
			options,'mvn_sta_c6_E',ytitle='sta!Cc6!C!CEnergy!CeV'
			options,'mvn_sta_c6_M',ytitle='sta!Cc6!C!CMass!Camu'
			options,'mvn_sta_c6_tot',ytitle='sta!Cc6!C!CCounts'
			options,'mvn_sta_c6_att',ytitle='sta!Cc6!C!CAttenuator'

			options,'mvn_sta_c6_E',ztitle='eflux'
			options,'mvn_sta_c6_M',ztitle='eflux'
	endif

; C8
	if size(mvn_c8_dat,/type) eq 8 then begin

		npts = n_elements(mvn_c8_dat.time)
		iswp = mvn_c8_dat.swp_ind
		ieff = mvn_c8_dat.eff_ind
		iatt = mvn_c8_dat.att_ind
		mlut = mvn_c8_dat.mlut_ind
		nenergy = mvn_c8_dat.nenergy
		ndef = mvn_c8_dat.ndef

		time = (mvn_c8_dat.time + mvn_c8_dat.end_time)/2.
		data = mvn_c8_dat.data
		eflux = mvn_c8_dat.eflux
		energy = reform(mvn_c8_dat.energy[iswp,*,0])
		theta = reform(mvn_c8_dat.theta[mlut,nenergy-1,*])

		bkg = mvn_c8_dat.bkg
		dead = mvn_c8_dat.dead
		gf = reform(mvn_c8_dat.gf[iswp,*,*,0]*(iatt eq 0)#replicate(1.,nenergy*ndef) +$
		            mvn_c8_dat.gf[iswp,*,*,1]*(iatt eq 1)#replicate(1.,nenergy*ndef) +$
		            mvn_c8_dat.gf[iswp,*,*,2]*(iatt eq 2)#replicate(1.,nenergy*ndef) +$
		            mvn_c8_dat.gf[iswp,*,*,3]*(iatt eq 3)#replicate(1.,nenergy*ndef), npts,nenergy,ndef)
		gf = mvn_c8_dat.geom_factor*gf
		eff = mvn_c8_dat.eff[ieff,*,*]
		dt = mvn_c8_dat.integ_t#replicate(1.,nenergy*ndef)
		eflux = (data-bkg)*dead/(gf*eff*dt)
		eflux = float(eflux)
		if max(abs((eflux-mvn_c8_dat.eflux)/eflux)) gt 0. then print,'Error in c8 eflux ',max(abs((eflux-mvn_c8_dat.eflux)/eflux))

		store_data,'mvn_sta_c8_P2_E',data={x:time,y:total(data,3),v:energy}
		store_data,'mvn_sta_c8_P2_D',data={x:time,y:total(data,2),v:theta}
		store_data,'mvn_sta_c8_E',data={x:time,y:total(eflux,3)/ndef,v:energy}
		store_data,'mvn_sta_c8_D',data={x:time,y:total(eflux,2)/nenergy,v:theta}
		store_data,'mvn_sta_c8_tot',data={x:time,y:total(total(data,3),2)}
		store_data,'mvn_sta_c8_att',data={x:time,y:iatt}

			ylim,'mvn_sta_c8_tot',0,0,1
			ylim,'mvn_sta_c8_P2_E',.4,40000.,1
			ylim,'mvn_sta_c8_P2_D',-50,50,0
			ylim,'mvn_sta_c8_E',.4,40000.,1
			ylim,'mvn_sta_c8_D',-50,50,0
			ylim,'mvn_sta_c8_att',-1,5,0

			zlim,'mvn_sta_c8_P2_E',1,1.e4,1
			zlim,'mvn_sta_c8_P2_D',1,1.e4,1
			zlim,'mvn_sta_c8_E',1.e3,1.e8,1
			zlim,'mvn_sta_c8_D',1.e3,1.e8,1

			datagap=7.
			options,'mvn_sta_c8_P2_E',datagap=datagap
			options,'mvn_sta_c8_P2_D',datagap=datagap
			options,'mvn_sta_c8_E',datagap=datagap
			options,'mvn_sta_c8_D',datagap=datagap
			options,'mvn_sta_c8_tot',datagap=datagap
	
			options,'mvn_sta_c8_P2_E','spec',1
			options,'mvn_sta_c8_P2_D','spec',1
			options,'mvn_sta_c8_E','spec',1
			options,'mvn_sta_c8_D','spec',1

			options,'mvn_sta_c8_P2_E',ytitle='sta!CP2-c8!C!CEnergy!CeV'
			options,'mvn_sta_c8_P2_D',ytitle='sta!CP2-c8!C!CTheta!Cdeg'
			options,'mvn_sta_c8_E',ytitle='sta!Cc8!C!CEnergy!CeV'
			options,'mvn_sta_c8_D',ytitle='sta!Cc8!C!CTheta!Cdeg'
			options,'mvn_sta_c8_tot',ytitle='sta!Cc8!C!CCounts'
			options,'mvn_sta_c8_att',ytitle='sta!Cc8!C!CAttenuator'

			options,'mvn_sta_c8_E',ztitle='eflux'
			options,'mvn_sta_c8_D',ztitle='eflux'
	endif

; CA
	if size(mvn_ca_dat,/type) eq 8 then begin

		npts = n_elements(mvn_ca_dat.time)
		iswp = mvn_ca_dat.swp_ind
		ieff = mvn_ca_dat.eff_ind
		iatt = mvn_ca_dat.att_ind
		nenergy = mvn_ca_dat.nenergy
		nbins = mvn_ca_dat.nbins
		ndef = mvn_ca_dat.ndef
		nanode = mvn_ca_dat.nanode

		time = (mvn_ca_dat.time + mvn_ca_dat.end_time)/2.
		data = mvn_ca_dat.data
		eflux = mvn_ca_dat.eflux
		energy = reform(mvn_ca_dat.energy[iswp,*,0])
		theta = total(reform(mvn_ca_dat.theta[iswp,nenergy-1,*],npts,ndef,nanode),3)/nanode
		phi = total(reform(mvn_ca_dat.phi[iswp,nenergy-1,*],npts,ndef,nanode),2)/ndef

		bkg = mvn_ca_dat.bkg
		dead = mvn_ca_dat.dead
		gf = reform(mvn_ca_dat.gf[iswp,*,*,0]*(iatt eq 0)#replicate(1.,nenergy*nbins) +$
		            mvn_ca_dat.gf[iswp,*,*,1]*(iatt eq 1)#replicate(1.,nenergy*nbins) +$
		            mvn_ca_dat.gf[iswp,*,*,2]*(iatt eq 2)#replicate(1.,nenergy*nbins) +$
		            mvn_ca_dat.gf[iswp,*,*,3]*(iatt eq 3)#replicate(1.,nenergy*nbins), npts*nenergy*nbins)
		gf = mvn_ca_dat.geom_factor*reform(gf,npts,nenergy,nbins)
		eff = mvn_ca_dat.eff[ieff,*,*]
		dt = mvn_ca_dat.integ_t#replicate(1.,nenergy*nbins)
		eflux = (data-bkg)*dead/(gf*eff*dt)
		eflux = float(eflux)
		if max(abs((eflux-mvn_ca_dat.eflux)/eflux)) gt 0. then print,'Error in ca eflux ',max(abs((eflux-mvn_ca_dat.eflux)/eflux))

		store_data,'mvn_sta_ca_P3_E',data={x:time,y:total(data,3)/nbins,v:energy}
		store_data,'mvn_sta_ca_P3_D',data={x:time,y:total(total(reform(data,npts,nenergy,ndef,nanode),4),2),v:theta}
		store_data,'mvn_sta_ca_P3_A',data={x:time,y:total(total(reform(data,npts,nenergy,ndef,nanode),3),2),v:phi}
		store_data,'mvn_sta_ca_tot',data={x:time,y:total(total(data,3),2)}

		store_data,'mvn_sta_ca_E',data={x:time,y:total(eflux,3)/nbins,v:energy}
		store_data,'mvn_sta_ca_D',data={x:time,y:total(total(reform(eflux,npts,nenergy,ndef,nanode),4),2),v:theta}
		store_data,'mvn_sta_ca_A',data={x:time,y:total(total(reform(eflux,npts,nenergy,ndef,nanode),3),2),v:phi}

			ylim,'mvn_sta_ca_P3_E',.4,40000.,1
			ylim,'mvn_sta_ca_P3_D',-50,50,0
			ylim,'mvn_sta_ca_P3_A',-180,200.,0
			ylim,'mvn_sta_ca_tot',0,0,1

			ylim,'mvn_sta_ca_E',.4,40000.,1
			ylim,'mvn_sta_ca_D',-50,50,0
			ylim,'mvn_sta_ca_A',-180,200.,0

			zlim,'mvn_sta_ca_P3_E',1,1.e4,1
			zlim,'mvn_sta_ca_P3_D',1,1.e4,1
			zlim,'mvn_sta_ca_P3_A',1,1.e4,1

			zlim,'mvn_sta_ca_E',1.e3,1.e8,1
			zlim,'mvn_sta_ca_D',1.e3,1.e8,1
			zlim,'mvn_sta_ca_A',1.e3,1.e8,1

			datagap=600.
			options,'mvn_sta_ca_P3_E',datagap=datagap
			options,'mvn_sta_ca_P3_D',datagap=datagap
			options,'mvn_sta_ca_P3_A',datagap=datagap
			options,'mvn_sta_ca_tot',datagap=datagap

			options,'mvn_sta_ca_E',datagap=datagap
			options,'mvn_sta_ca_D',datagap=datagap
			options,'mvn_sta_ca_A',datagap=datagap
	
			options,'mvn_sta_ca_P3_E','spec',1
			options,'mvn_sta_ca_P3_D','spec',1
			options,'mvn_sta_ca_P3_A','spec',1

			options,'mvn_sta_ca_E','spec',1
			options,'mvn_sta_ca_D','spec',1
			options,'mvn_sta_ca_A','spec',1

			options,'mvn_sta_ca_P3_E',ytitle='sta!CP3-ca!C!CEnergy!CeV'
			options,'mvn_sta_ca_P3_D',ytitle='sta!CP3-ca!C!CTheta!Cdeg'
			options,'mvn_sta_ca_P3_A',ytitle='sta!CP3-ca!C!CPhi!Cdeg'
			options,'mvn_sta_ca_tot',ytitle='sta!Cca!C!CCounts'

			options,'mvn_sta_ca_E',ytitle='sta!Cca!C!CEnergy!CeV'
			options,'mvn_sta_ca_D',ytitle='sta!Cca!C!CTheta!Cdeg'
			options,'mvn_sta_ca_A',ytitle='sta!Cca!C!CPhi!Cdeg'

			options,'mvn_sta_ca_E',ztitle='eflux'
			options,'mvn_sta_ca_D',ztitle='eflux'
			options,'mvn_sta_ca_A',ztitle='eflux'
	endif

; CE
	if size(mvn_ce_dat,/type) eq 8 then begin

		npts = n_elements(mvn_ce_dat.time)
		iswp = mvn_ce_dat.swp_ind
		ieff = mvn_ce_dat.eff_ind
		iatt = mvn_ce_dat.att_ind
		mlut = mvn_ce_dat.mlut_ind
		nenergy = mvn_ce_dat.nenergy
		nbins = mvn_ce_dat.nbins
		ndef = mvn_ce_dat.ndef
		nanode = mvn_ce_dat.nanode
		nmass = mvn_ce_dat.nmass

		time = (mvn_ce_dat.time + mvn_ce_dat.end_time)/2.
		data = mvn_ce_dat.data
		eflux = mvn_ce_dat.eflux
		energy = reform(mvn_ce_dat.energy[iswp,*,0,0])
		mass = reform(total(mvn_ce_dat.mass_arr[mlut,*,0,*],2)/nenergy)
		theta = total(reform(mvn_ce_dat.theta[iswp,nenergy-1,*,0],npts,ndef,nanode),3)/nanode
		phi = total(reform(mvn_ce_dat.phi[iswp,nenergy-1,*,0],npts,ndef,nanode),2)/ndef

		bkg = mvn_ce_dat.bkg
		dead = mvn_ce_dat.dead
		gf = reform(mvn_ce_dat.gf[iswp,*,*,0]*(iatt eq 0)#replicate(1.,nenergy*nbins) +$
		            mvn_ce_dat.gf[iswp,*,*,1]*(iatt eq 1)#replicate(1.,nenergy*nbins) +$
		            mvn_ce_dat.gf[iswp,*,*,2]*(iatt eq 2)#replicate(1.,nenergy*nbins) +$
		            mvn_ce_dat.gf[iswp,*,*,3]*(iatt eq 3)#replicate(1.,nenergy*nbins), npts*nenergy*nbins)$
				#replicate(1.,nmass)
		gf = mvn_ce_dat.geom_factor*reform(gf,npts,nenergy,nbins,nmass)
		eff = mvn_ce_dat.eff[ieff,*,*,*]
		dt = mvn_ce_dat.integ_t#replicate(1.,nenergy*nbins*nmass)
		eflux = (data-bkg)*dead/(gf*eff*dt)
		eflux = float(eflux)
		if max(abs((eflux-mvn_ce_dat.eflux)/eflux)) gt 0. then print,'Error in ce eflux ',max(abs((eflux-mvn_ce_dat.eflux)/eflux))

		store_data,'mvn_sta_ce_P4B_E',data={x:time,y:total(total(data,4),3)/nbins,v:energy}
		store_data,'mvn_sta_ce_P4B_D',data={x:time,y:total(total(total(reform(data,npts,nenergy,ndef,nanode,nmass),5),4),2),v:theta}
		store_data,'mvn_sta_ce_P4B_A',data={x:time,y:total(total(total(reform(data,npts,nenergy,ndef,nanode,nmass),5),3),2),v:phi}
		store_data,'mvn_sta_ce_P4B_M',data={x:time,y:total(total(data,3),2),v:mass}
		store_data,'mvn_sta_ce_E',data={x:time,y:total(total(eflux,4),3)/nbins,v:energy}
		store_data,'mvn_sta_ce_D',data={x:time,y:total(total(total(reform(eflux,npts,nenergy,ndef,nanode,nmass),5),4),2),v:theta}
		store_data,'mvn_sta_ce_A',data={x:time,y:total(total(total(reform(eflux,npts,nenergy,ndef,nanode,nmass),5),3),2),v:phi}
		store_data,'mvn_sta_ce_M',data={x:time,y:total(total(eflux,3),2),v:mass}
		store_data,'mvn_sta_ce_tot',data={x:time,y:total(total(total(data,4),3),2)}
		store_data,'mvn_sta_ce_att',data={x:time,y:iatt}

			ylim,'mvn_sta_ce_tot',0,0,1
			ylim,'mvn_sta_ce_P4B_E',.4,40000.,1
			ylim,'mvn_sta_ce_P4B_D',-50,50,0
			ylim,'mvn_sta_ce_P4B_A',-180,200.,0
			ylim,'mvn_sta_ce_P4B_M',.5,100,1
			ylim,'mvn_sta_ce_E',.4,40000.,1
			ylim,'mvn_sta_ce_D',-50,50,0
			ylim,'mvn_sta_ce_A',-180,200.,0
			ylim,'mvn_sta_ce_M',.5,100,1
			ylim,'mvn_sta_ce_att',-1,5,0

			zlim,'mvn_sta_ce_P4B_E',10,1.e5,1
			zlim,'mvn_sta_ce_P4B_D',10,1.e5,1
			zlim,'mvn_sta_ce_P4B_A',10,1.e5,1
			zlim,'mvn_sta_ce_P4B_M',10,1.e5,1
			zlim,'mvn_sta_ce_E',1.e3,1.e8,1
			zlim,'mvn_sta_ce_D',1.e3,1.e8,1
			zlim,'mvn_sta_ce_A',1.e3,1.e8,1
			zlim,'mvn_sta_ce_M',1.e3,1.e8,1

			datagap=600.
			options,'mvn_sta_ce_P4B_E',datagap=datagap
			options,'mvn_sta_ce_P4B_D',datagap=datagap
			options,'mvn_sta_ce_P4B_A',datagap=datagap
			options,'mvn_sta_ce_P4B_M',datagap=datagap
			options,'mvn_sta_ce_E',datagap=datagap
			options,'mvn_sta_ce_D',datagap=datagap
			options,'mvn_sta_ce_A',datagap=datagap
			options,'mvn_sta_ce_M',datagap=datagap
			options,'mvn_sta_ce_tot',datagap=datagap
	
			options,'mvn_sta_ce_P4B_E','spec',1
			options,'mvn_sta_ce_P4B_D','spec',1
			options,'mvn_sta_ce_P4B_A','spec',1
			options,'mvn_sta_ce_P4B_M','spec',1
			options,'mvn_sta_ce_E','spec',1
			options,'mvn_sta_ce_D','spec',1
			options,'mvn_sta_ce_A','spec',1
			options,'mvn_sta_ce_M','spec',1

			options,'mvn_sta_ce_P4B_E',ytitle='sta!CP4B-ce!C!CEnergy!CeV'
			options,'mvn_sta_ce_P4B_D',ytitle='sta!CP4B-ce!C!CTheta!Cdeg'
			options,'mvn_sta_ce_P4B_A',ytitle='sta!CP4B-ce!C!CPhi!Cdeg'
			options,'mvn_sta_ce_P4B_M',ytitle='sta!CP4B-ce!C!CMass!Camu'
			options,'mvn_sta_ce_E',ytitle='sta!Cce!C!CEnergy!CeV'
			options,'mvn_sta_ce_D',ytitle='sta!Cce!C!CTheta!Cdeg'
			options,'mvn_sta_ce_A',ytitle='sta!Cce!C!CPhi!Cdeg'
			options,'mvn_sta_ce_M',ytitle='sta!Cce!C!CMass!Camu'
			options,'mvn_sta_ce_tot',ytitle='sta!Cce!C!CCounts'
			options,'mvn_sta_ce_att',ytitle='sta!Cce!C!CAttenuator'

			options,'mvn_sta_ce_E',ztitle='eflux'
			options,'mvn_sta_ce_D',ztitle='eflux'
			options,'mvn_sta_ce_A',ztitle='eflux'
			options,'mvn_sta_ce_M',ztitle='eflux'
	endif

; CF
	if size(mvn_cf_dat,/type) eq 8 then begin

		npts = n_elements(mvn_cf_dat.time)
		iswp = mvn_cf_dat.swp_ind
		ieff = mvn_cf_dat.eff_ind
		iatt = mvn_cf_dat.att_ind
		mlut = mvn_cf_dat.mlut_ind
		nenergy = mvn_cf_dat.nenergy
		nbins = mvn_cf_dat.nbins
		ndef = mvn_cf_dat.ndef
		nanode = mvn_cf_dat.nanode
		nmass = mvn_cf_dat.nmass

		time = (mvn_cf_dat.time + mvn_cf_dat.end_time)/2.
		data = mvn_cf_dat.data
		eflux = mvn_cf_dat.eflux
		energy = reform(mvn_cf_dat.energy[iswp,*,0,0])
		mass = reform(total(mvn_cf_dat.mass_arr[mlut,*,0,*],2)/nenergy)
		theta = total(reform(mvn_cf_dat.theta[iswp,nenergy-1,*,0],npts,ndef,nanode),3)/nanode
		phi = total(reform(mvn_cf_dat.phi[iswp,nenergy-1,*,0],npts,ndef,nanode),2)/ndef

		bkg = mvn_cf_dat.bkg
		dead = mvn_cf_dat.dead
		gf = reform(mvn_cf_dat.gf[iswp,*,*,0]*(iatt eq 0)#replicate(1.,nenergy*nbins) +$
		            mvn_cf_dat.gf[iswp,*,*,1]*(iatt eq 1)#replicate(1.,nenergy*nbins) +$
		            mvn_cf_dat.gf[iswp,*,*,2]*(iatt eq 2)#replicate(1.,nenergy*nbins) +$
		            mvn_cf_dat.gf[iswp,*,*,3]*(iatt eq 3)#replicate(1.,nenergy*nbins), npts*nenergy*nbins)$
				#replicate(1.,nmass)
		gf = mvn_cf_dat.geom_factor*reform(gf,npts,nenergy,nbins,nmass)
		eff = mvn_cf_dat.eff[ieff,*,*,*]
		dt = mvn_cf_dat.integ_t#replicate(1.,nenergy*nbins*nmass)
		eflux = (data-bkg)*dead/(gf*eff*dt)
		eflux = float(eflux)
		if max(abs((eflux-mvn_cf_dat.eflux)/eflux)) gt 0. then print,'Error in cf eflux ',max(abs((eflux-mvn_cf_dat.eflux)/eflux))

		store_data,'mvn_sta_cf_P4B_E',data={x:time,y:total(total(data,4),3)/nbins,v:energy}
		store_data,'mvn_sta_cf_P4B_D',data={x:time,y:total(total(total(reform(data,npts,nenergy,ndef,nanode,nmass),5),4),2),v:theta}
		store_data,'mvn_sta_cf_P4B_A',data={x:time,y:total(total(total(reform(data,npts,nenergy,ndef,nanode,nmass),5),3),2),v:phi}
		store_data,'mvn_sta_cf_P4B_M',data={x:time,y:total(total(data,3),2),v:mass}
		store_data,'mvn_sta_cf_E',data={x:time,y:total(total(eflux,4),3)/nbins,v:energy}
		store_data,'mvn_sta_cf_D',data={x:time,y:total(total(total(reform(eflux,npts,nenergy,ndef,nanode,nmass),5),4),2),v:theta}
		store_data,'mvn_sta_cf_A',data={x:time,y:total(total(total(reform(eflux,npts,nenergy,ndef,nanode,nmass),5),3),2),v:phi}
		store_data,'mvn_sta_cf_M',data={x:time,y:total(total(eflux,3),2),v:mass}
		store_data,'mvn_sta_cf_tot',data={x:time,y:total(total(total(data,4),3),2)}
		store_data,'mvn_sta_cf_att',data={x:time,y:iatt}

			ylim,'mvn_sta_cf_tot',0,0,1
			ylim,'mvn_sta_cf_P4B_E',.4,40000.,1
			ylim,'mvn_sta_cf_P4B_D',-50,50,0
			ylim,'mvn_sta_cf_P4B_A',-180,200.,0
			ylim,'mvn_sta_cf_P4B_M',.5,100,1
			ylim,'mvn_sta_cf_E',.4,40000.,1
			ylim,'mvn_sta_cf_D',-50,50,0
			ylim,'mvn_sta_cf_A',-180,200.,0
			ylim,'mvn_sta_cf_M',.5,100,1
			ylim,'mvn_sta_cf_att',-1,5,0

			zlim,'mvn_sta_cf_P4B_E',10,1.e5,1
			zlim,'mvn_sta_cf_P4B_D',10,1.e5,1
			zlim,'mvn_sta_cf_P4B_A',10,1.e5,1
			zlim,'mvn_sta_cf_P4B_M',10,1.e5,1
			zlim,'mvn_sta_cf_E',1.e3,1.e8,1
			zlim,'mvn_sta_cf_D',1.e3,1.e8,1
			zlim,'mvn_sta_cf_A',1.e3,1.e8,1
			zlim,'mvn_sta_cf_M',1.e3,1.e8,1

			datagap=600.
			options,'mvn_sta_cf_P4B_E',datagap=datagap
			options,'mvn_sta_cf_P4B_D',datagap=datagap
			options,'mvn_sta_cf_P4B_A',datagap=datagap
			options,'mvn_sta_cf_P4B_M',datagap=datagap
			options,'mvn_sta_cf_E',datagap=datagap
			options,'mvn_sta_cf_D',datagap=datagap
			options,'mvn_sta_cf_A',datagap=datagap
			options,'mvn_sta_cf_M',datagap=datagap
			options,'mvn_sta_cf_tot',datagap=datagap
	
			options,'mvn_sta_cf_P4B_E','spec',1
			options,'mvn_sta_cf_P4B_D','spec',1
			options,'mvn_sta_cf_P4B_A','spec',1
			options,'mvn_sta_cf_P4B_M','spec',1
			options,'mvn_sta_cf_E','spec',1
			options,'mvn_sta_cf_D','spec',1
			options,'mvn_sta_cf_A','spec',1
			options,'mvn_sta_cf_M','spec',1

			options,'mvn_sta_cf_P4B_E',ytitle='sta!CP4B-cf!C!CEnergy!CeV'
			options,'mvn_sta_cf_P4B_D',ytitle='sta!CP4B-cf!C!CTheta!Cdeg'
			options,'mvn_sta_cf_P4B_A',ytitle='sta!CP4B-cf!C!CPhi!Cdeg'
			options,'mvn_sta_cf_P4B_M',ytitle='sta!CP4B-cf!C!CMass!Camu'
			options,'mvn_sta_cf_E',ytitle='sta!Ccf!C!CEnergy!CeV'
			options,'mvn_sta_cf_D',ytitle='sta!Ccf!C!CTheta!Cdeg'
			options,'mvn_sta_cf_A',ytitle='sta!Ccf!C!CPhi!Cdeg'
			options,'mvn_sta_cf_M',ytitle='sta!Ccf!C!CMass!Camu'
			options,'mvn_sta_cf_tot',ytitle='sta!Ccf!C!CCounts'
			options,'mvn_sta_cf_att',ytitle='sta!Ccf!C!CAttenuator'

			options,'mvn_sta_cf_E',ztitle='eflux'
			options,'mvn_sta_cf_D',ztitle='eflux'
			options,'mvn_sta_cf_A',ztitle='eflux'
			options,'mvn_sta_cf_M',ztitle='eflux'
	endif

; D0
	if size(mvn_d0_dat,/type) eq 8 then begin

		npts = n_elements(mvn_d0_dat.time)
		iswp = mvn_d0_dat.swp_ind
		ieff = mvn_d0_dat.eff_ind
		iatt = mvn_d0_dat.att_ind
		mlut = mvn_d0_dat.mlut_ind
		nenergy = mvn_d0_dat.nenergy
		nbins = mvn_d0_dat.nbins
		ndef = mvn_d0_dat.ndef
		nanode = mvn_d0_dat.nanode
		nmass = mvn_d0_dat.nmass

		time = (mvn_d0_dat.time + mvn_d0_dat.end_time)/2.
		data = mvn_d0_dat.data
		eflux = mvn_d0_dat.eflux
		energy = reform(mvn_d0_dat.energy[iswp,*,0,0])
		mass = reform(total(mvn_d0_dat.mass_arr[mlut,*,0,*],2)/nenergy)
		theta = total(reform(mvn_d0_dat.theta[iswp,nenergy-1,*,0],npts,ndef,nanode),3)/nanode
		phi = total(reform(mvn_d0_dat.phi[iswp,nenergy-1,*,0],npts,ndef,nanode),2)/ndef

		bkg = mvn_d0_dat.bkg
		dead = mvn_d0_dat.dead
		gf = reform(mvn_d0_dat.gf[iswp,*,*,0]*(iatt eq 0)#replicate(1.,nenergy*nbins) +$
		            mvn_d0_dat.gf[iswp,*,*,1]*(iatt eq 1)#replicate(1.,nenergy*nbins) +$
		            mvn_d0_dat.gf[iswp,*,*,2]*(iatt eq 2)#replicate(1.,nenergy*nbins) +$
		            mvn_d0_dat.gf[iswp,*,*,3]*(iatt eq 3)#replicate(1.,nenergy*nbins), npts*nenergy*nbins)$
				#replicate(1.,nmass)
		gf = mvn_d0_dat.geom_factor*reform(gf,npts,nenergy,nbins,nmass)
		eff = mvn_d0_dat.eff[ieff,*,*,*]
		dt = mvn_d0_dat.integ_t#replicate(1.,nenergy*nbins*nmass)
		eflux = (data-bkg)*dead/(gf*eff*dt)
		eflux = float(eflux)
		if max(abs((eflux-mvn_d0_dat.eflux)/eflux)) gt 0. then print,'Error in d0 eflux ',max(abs((eflux-mvn_d0_dat.eflux)/eflux))

		store_data,'mvn_sta_d0_P4C_E',data={x:time,y:total(total(data,4),3)/nbins,v:energy}
		store_data,'mvn_sta_d0_P4C_D',data={x:time,y:total(total(total(reform(data,npts,nenergy,ndef,nanode,nmass),5),4),2),v:theta}
		store_data,'mvn_sta_d0_P4C_A',data={x:time,y:total(total(total(reform(data,npts,nenergy,ndef,nanode,nmass),5),3),2),v:phi}
		store_data,'mvn_sta_d0_P4C_M',data={x:time,y:total(total(data,3),2),v:mass}
		store_data,'mvn_sta_d0_E',data={x:time,y:total(total(eflux,4),3)/nbins,v:energy}
		store_data,'mvn_sta_d0_D',data={x:time,y:total(total(total(reform(eflux,npts,nenergy,ndef,nanode,nmass),5),4),2),v:theta}
		store_data,'mvn_sta_d0_A',data={x:time,y:total(total(total(reform(eflux,npts,nenergy,ndef,nanode,nmass),5),3),2),v:phi}
		store_data,'mvn_sta_d0_M',data={x:time,y:total(total(eflux,3),2),v:mass}
		store_data,'mvn_sta_d0_tot',data={x:time,y:total(total(total(data,4),3),2)}
		store_data,'mvn_sta_d0_att',data={x:time,y:iatt}

			ylim,'mvn_sta_d0_tot',0,0,1
			ylim,'mvn_sta_d0_P4C_E',.4,40000.,1
			ylim,'mvn_sta_d0_P4C_D',-50,50,0
			ylim,'mvn_sta_d0_P4C_A',-180,200.,0
			ylim,'mvn_sta_d0_P4C_M',.5,100,1
			ylim,'mvn_sta_d0_E',.4,40000.,1
			ylim,'mvn_sta_d0_D',-50,50,0
			ylim,'mvn_sta_d0_A',-180,200.,0
			ylim,'mvn_sta_d0_M',.5,100,1
			ylim,'mvn_sta_d0_att',-1,5,0

			zlim,'mvn_sta_d0_P4C_E',10,1.e5,1
			zlim,'mvn_sta_d0_P4C_D',10,1.e5,1
			zlim,'mvn_sta_d0_P4C_A',10,1.e5,1
			zlim,'mvn_sta_d0_P4C_M',10,1.e5,1
			zlim,'mvn_sta_d0_E',1.e3,1.e8,1
			zlim,'mvn_sta_d0_D',1.e3,1.e8,1
			zlim,'mvn_sta_d0_A',1.e3,1.e8,1
			zlim,'mvn_sta_d0_M',1.e3,1.e8,1

			datagap=600.
			options,'mvn_sta_d0_P4C_E',datagap=datagap
			options,'mvn_sta_d0_P4C_D',datagap=datagap
			options,'mvn_sta_d0_P4C_A',datagap=datagap
			options,'mvn_sta_d0_P4C_M',datagap=datagap
			options,'mvn_sta_d0_E',datagap=datagap
			options,'mvn_sta_d0_D',datagap=datagap
			options,'mvn_sta_d0_A',datagap=datagap
			options,'mvn_sta_d0_M',datagap=datagap
			options,'mvn_sta_d0_tot',datagap=datagap
	
			options,'mvn_sta_d0_P4C_E','spec',1
			options,'mvn_sta_d0_P4C_D','spec',1
			options,'mvn_sta_d0_P4C_A','spec',1
			options,'mvn_sta_d0_P4C_M','spec',1
			options,'mvn_sta_d0_E','spec',1
			options,'mvn_sta_d0_D','spec',1
			options,'mvn_sta_d0_A','spec',1
			options,'mvn_sta_d0_M','spec',1

			options,'mvn_sta_d0_P4C_E',ytitle='sta!CP4C-d0!C!CEnergy!CeV'
			options,'mvn_sta_d0_P4C_D',ytitle='sta!CP4C-d0!C!CTheta!Cdeg'
			options,'mvn_sta_d0_P4C_A',ytitle='sta!CP4C-d0!C!CPhi!Cdeg'
			options,'mvn_sta_d0_P4C_M',ytitle='sta!CP4C-d0!C!CMass!Camu'
			options,'mvn_sta_d0_E',ytitle='sta!Cd0!C!CEnergy!CeV'
			options,'mvn_sta_d0_D',ytitle='sta!Cd0!C!CTheta!Cdeg'
			options,'mvn_sta_d0_A',ytitle='sta!Cd0!C!CPhi!Cdeg'
			options,'mvn_sta_d0_M',ytitle='sta!Cd0!C!CMass!Camu'
			options,'mvn_sta_d0_tot',ytitle='sta!Cd0!C!CCounts'
			options,'mvn_sta_d0_att',ytitle='sta!Cd0!C!CAttenuator'

			options,'mvn_sta_d0_E',ztitle='eflux'
			options,'mvn_sta_d0_D',ztitle='eflux'
			options,'mvn_sta_d0_A',ztitle='eflux'
			options,'mvn_sta_d0_M',ztitle='eflux'
	endif

; D1
	if size(mvn_d1_dat,/type) eq 8 then begin

		npts = n_elements(mvn_d1_dat.time)
		iswp = mvn_d1_dat.swp_ind
		ieff = mvn_d1_dat.eff_ind
		iatt = mvn_d1_dat.att_ind
		mlut = mvn_d1_dat.mlut_ind
		nenergy = mvn_d1_dat.nenergy
		nbins = mvn_d1_dat.nbins
		ndef = mvn_d1_dat.ndef
		nanode = mvn_d1_dat.nanode
		nmass = mvn_d1_dat.nmass

		time = (mvn_d1_dat.time + mvn_d1_dat.end_time)/2.
		data = mvn_d1_dat.data
		eflux = mvn_d1_dat.eflux
		energy = reform(mvn_d1_dat.energy[iswp,*,0,0])
		mass = reform(total(mvn_d1_dat.mass_arr[mlut,*,0,*],2)/nenergy)
		theta = total(reform(mvn_d1_dat.theta[iswp,nenergy-1,*,0],npts,ndef,nanode),3)/nanode
		phi = total(reform(mvn_d1_dat.phi[iswp,nenergy-1,*,0],npts,ndef,nanode),2)/ndef

		bkg = mvn_d1_dat.bkg
		dead = mvn_d1_dat.dead
		gf = reform(mvn_d1_dat.gf[iswp,*,*,0]*(iatt eq 0)#replicate(1.,nenergy*nbins) +$
		            mvn_d1_dat.gf[iswp,*,*,1]*(iatt eq 1)#replicate(1.,nenergy*nbins) +$
		            mvn_d1_dat.gf[iswp,*,*,2]*(iatt eq 2)#replicate(1.,nenergy*nbins) +$
		            mvn_d1_dat.gf[iswp,*,*,3]*(iatt eq 3)#replicate(1.,nenergy*nbins), npts*nenergy*nbins)$
				#replicate(1.,nmass)
		gf = mvn_d1_dat.geom_factor*reform(gf,npts,nenergy,nbins,nmass)
		eff = mvn_d1_dat.eff[ieff,*,*,*]
		dt = mvn_d1_dat.integ_t#replicate(1.,nenergy*nbins*nmass)
		eflux = (data-bkg)*dead/(gf*eff*dt)
		eflux = float(eflux)
		if max(abs((eflux-mvn_d1_dat.eflux)/eflux)) gt 0. then print,'Error in d1 eflux ',max(abs((eflux-mvn_d1_dat.eflux)/eflux))

		store_data,'mvn_sta_d1_P4C_E',data={x:time,y:total(total(data,4),3)/nbins,v:energy}
		store_data,'mvn_sta_d1_P4C_D',data={x:time,y:total(total(total(reform(data,npts,nenergy,ndef,nanode,nmass),5),4),2),v:theta}
		store_data,'mvn_sta_d1_P4C_A',data={x:time,y:total(total(total(reform(data,npts,nenergy,ndef,nanode,nmass),5),3),2),v:phi}
		store_data,'mvn_sta_d1_P4C_M',data={x:time,y:total(total(data,3),2),v:mass}
		store_data,'mvn_sta_d1_E',data={x:time,y:total(total(eflux,4),3)/nbins,v:energy}
		store_data,'mvn_sta_d1_D',data={x:time,y:total(total(total(reform(eflux,npts,nenergy,ndef,nanode,nmass),5),4),2),v:theta}
		store_data,'mvn_sta_d1_A',data={x:time,y:total(total(total(reform(eflux,npts,nenergy,ndef,nanode,nmass),5),3),2),v:phi}
		store_data,'mvn_sta_d1_M',data={x:time,y:total(total(eflux,3),2),v:mass}
		store_data,'mvn_sta_d1_tot',data={x:time,y:total(total(total(data,4),3),2)}
		store_data,'mvn_sta_d1_att',data={x:time,y:iatt}

			ylim,'mvn_sta_d1_tot',0,0,1
			ylim,'mvn_sta_d1_P4C_E',.4,40000.,1
			ylim,'mvn_sta_d1_P4C_D',-50,50,0
			ylim,'mvn_sta_d1_P4C_A',-180,200.,0
			ylim,'mvn_sta_d1_P4C_M',.5,100,1
			ylim,'mvn_sta_d1_E',.4,40000.,1
			ylim,'mvn_sta_d1_D',-50,50,0
			ylim,'mvn_sta_d1_A',-180,200.,0
			ylim,'mvn_sta_d1_M',.5,100,1
			ylim,'mvn_sta_d1_att',-1,5,0

			zlim,'mvn_sta_d1_P4C_E',10,1.e5,1
			zlim,'mvn_sta_d1_P4C_D',10,1.e5,1
			zlim,'mvn_sta_d1_P4C_A',10,1.e5,1
			zlim,'mvn_sta_d1_P4C_M',10,1.e5,1
			zlim,'mvn_sta_d1_E',1.e3,1.e8,1
			zlim,'mvn_sta_d1_D',1.e3,1.e8,1
			zlim,'mvn_sta_d1_A',1.e3,1.e8,1
			zlim,'mvn_sta_d1_M',1.e3,1.e8,1

			datagap=600.
			options,'mvn_sta_d1_P4C_E',datagap=datagap
			options,'mvn_sta_d1_P4C_D',datagap=datagap
			options,'mvn_sta_d1_P4C_A',datagap=datagap
			options,'mvn_sta_d1_P4C_M',datagap=datagap
			options,'mvn_sta_d1_E',datagap=datagap
			options,'mvn_sta_d1_D',datagap=datagap
			options,'mvn_sta_d1_A',datagap=datagap
			options,'mvn_sta_d1_M',datagap=datagap
			options,'mvn_sta_d1_tot',datagap=datagap
	
			options,'mvn_sta_d1_P4C_E','spec',1
			options,'mvn_sta_d1_P4C_D','spec',1
			options,'mvn_sta_d1_P4C_A','spec',1
			options,'mvn_sta_d1_P4C_M','spec',1
			options,'mvn_sta_d1_E','spec',1
			options,'mvn_sta_d1_D','spec',1
			options,'mvn_sta_d1_A','spec',1
			options,'mvn_sta_d1_M','spec',1

			options,'mvn_sta_d1_P4C_E',ytitle='sta!CP4C-d1!C!CEnergy!CeV'
			options,'mvn_sta_d1_P4C_D',ytitle='sta!CP4C-d1!C!CTheta!Cdeg'
			options,'mvn_sta_d1_P4C_A',ytitle='sta!CP4C-d1!C!CPhi!Cdeg'
			options,'mvn_sta_d1_P4C_M',ytitle='sta!CP4C-d1!C!CMass!Camu'
			options,'mvn_sta_d1_E',ytitle='sta!Cd1!C!CEnergy!CeV'
			options,'mvn_sta_d1_D',ytitle='sta!Cd1!C!CTheta!Cdeg'
			options,'mvn_sta_d1_A',ytitle='sta!Cd1!C!CPhi!Cdeg'
			options,'mvn_sta_d1_M',ytitle='sta!Cd1!C!CMass!Camu'
			options,'mvn_sta_d1_tot',ytitle='sta!Cd1!C!CCounts'
			options,'mvn_sta_d1_att',ytitle='sta!Cd1!C!CAttenuator'

			options,'mvn_sta_d1_E',ztitle='eflux'
			options,'mvn_sta_d1_D',ztitle='eflux'
			options,'mvn_sta_d1_A',ztitle='eflux'
			options,'mvn_sta_d1_M',ztitle='eflux'
	endif

; D4
	if size(mvn_d4_dat,/type) eq 8 then begin

		npts = n_elements(mvn_d4_dat.time)
		iswp = mvn_d4_dat.swp_ind
		ieff = mvn_d4_dat.eff_ind
		iatt = mvn_d4_dat.att_ind
		mlut = mvn_d4_dat.mlut_ind
		nenergy = mvn_d4_dat.nenergy
		nbins = mvn_d4_dat.nbins
		ndef = mvn_d4_dat.ndef
		nanode = mvn_d4_dat.nanode
		nmass = mvn_d4_dat.nmass

		time = (mvn_d4_dat.time + mvn_d4_dat.end_time)/2.
		data = mvn_d4_dat.data
		eflux = mvn_d4_dat.eflux
		mass = reform(total(mvn_d4_dat.mass_arr[mlut,*,0,*],2)/nenergy)
		theta = total(reform(mvn_d4_dat.theta[iswp,nenergy-1,*,0],npts,ndef,nanode),3)/nanode
		phi = total(reform(mvn_d4_dat.phi[iswp,nenergy-1,*,0],npts,ndef,nanode),2)/ndef

		bkg = mvn_d4_dat.bkg
		dead = mvn_d4_dat.dead
		gf = reform(mvn_d4_dat.gf[iswp,*,*,0]*(iatt eq 0)#replicate(1.,nbins) +$
		            mvn_d4_dat.gf[iswp,*,*,1]*(iatt eq 1)#replicate(1.,nbins) +$
		            mvn_d4_dat.gf[iswp,*,*,2]*(iatt eq 2)#replicate(1.,nbins) +$
		            mvn_d4_dat.gf[iswp,*,*,3]*(iatt eq 3)#replicate(1.,nbins), npts*nbins)$
				#replicate(1.,nmass)
		gf = mvn_d4_dat.geom_factor*reform(gf,npts,nenergy,nbins,nmass)
		eff = mvn_d4_dat.eff[ieff,*,*,*]
		dt = mvn_d4_dat.integ_t#replicate(1.,nenergy*nbins*nmass)
		eflux = (data-bkg)*dead/(gf*eff*dt)
		eflux = float(eflux)
		if max(abs((eflux-mvn_d4_dat.eflux)/eflux)) gt 0. then print,'Error in d4 eflux ',max(abs((eflux-mvn_d4_dat.eflux)/eflux))

		store_data,'mvn_sta_d4_P4E_D',data={x:time,y:total(total(total(reform(data,npts,nenergy,ndef,nanode,nmass),5),4),2),v:theta}
		store_data,'mvn_sta_d4_P4E_A',data={x:time,y:total(total(total(reform(data,npts,nenergy,ndef,nanode,nmass),5),3),2),v:phi}
		store_data,'mvn_sta_d4_P4E_M',data={x:time,y:total(total(data,3),2),v:mass}
		store_data,'mvn_sta_d4_D',data={x:time,y:total(total(total(reform(eflux,npts,nenergy,ndef,nanode,nmass),5),4),2),v:theta}
		store_data,'mvn_sta_d4_A',data={x:time,y:total(total(total(reform(eflux,npts,nenergy,ndef,nanode,nmass),5),3),2),v:phi}
		store_data,'mvn_sta_d4_M',data={x:time,y:total(total(eflux,3),2),v:mass}
		store_data,'mvn_sta_d4_tot',data={x:time,y:total(total(data,4),3)}
		store_data,'mvn_sta_d4_att',data={x:time,y:iatt}

			ylim,'mvn_sta_d4_tot',0,0,1
			ylim,'mvn_sta_d4_P4E_D',-50,50,0
			ylim,'mvn_sta_d4_P4E_A',-180,200.,0
			ylim,'mvn_sta_d4_P4E_M',.5,100,1
			ylim,'mvn_sta_d4_D',-50,50,0
			ylim,'mvn_sta_d4_A',-180,200.,0
			ylim,'mvn_sta_d4_M',.5,100,1
			ylim,'mvn_sta_d4_att',-1,5,0

			zlim,'mvn_sta_d4_P4E_D',10,1.e5,1
			zlim,'mvn_sta_d4_P4E_A',10,1.e5,1
			zlim,'mvn_sta_d4_P4E_M',10,1.e5,1
			zlim,'mvn_sta_d4_D',1.e3,1.e8,1
			zlim,'mvn_sta_d4_A',1.e3,1.e8,1
			zlim,'mvn_sta_d4_M',1.e3,1.e8,1

			datagap=7.
			options,'mvn_sta_d4_P4E_D',datagap=datagap
			options,'mvn_sta_d4_P4E_A',datagap=datagap
			options,'mvn_sta_d4_P4E_M',datagap=datagap
			options,'mvn_sta_d4_D',datagap=datagap
			options,'mvn_sta_d4_A',datagap=datagap
			options,'mvn_sta_d4_M',datagap=datagap
			options,'mvn_sta_d4_tot',datagap=datagap
	
			options,'mvn_sta_d4_P4E_D','spec',1
			options,'mvn_sta_d4_P4E_A','spec',1
			options,'mvn_sta_d4_P4E_M','spec',1
			options,'mvn_sta_d4_D','spec',1
			options,'mvn_sta_d4_A','spec',1
			options,'mvn_sta_d4_M','spec',1

			options,'mvn_sta_d4_P4E_D',ytitle='sta!CP4E-d4!C!CTheta!Cdeg'
			options,'mvn_sta_d4_P4E_A',ytitle='sta!CP4E-d4!C!CPhi!Cdeg'
			options,'mvn_sta_d4_P4E_M',ytitle='sta!CP4E-d4!C!CMass!Camu'
			options,'mvn_sta_d4_D',ytitle='sta!Cd4!C!CTheta!Cdeg'
			options,'mvn_sta_d4_A',ytitle='sta!Cd4!C!CPhi!Cdeg'
			options,'mvn_sta_d4_M',ytitle='sta!Cd4!C!CMass!Camu'
			options,'mvn_sta_d4_tot',ytitle='sta!Cd4!C!CCounts'
			options,'mvn_sta_d4_att',ytitle='sta!Cd4!C!CAttenuator'

			options,'mvn_sta_d4_D',ztitle='eflux'
			options,'mvn_sta_d4_A',ztitle='eflux'
			options,'mvn_sta_d4_M',ztitle='eflux'
	endif

; D6
	if size(mvn_d6_dat,/type) eq 8 then begin

		time = mvn_d6_dat.time

		tdc_1 = mvn_d6_dat.tdc_1	
		tdc_2 = mvn_d6_dat.tdc_2	
		tdc_3 = mvn_d6_dat.tdc_3	
		tdc_4 = mvn_d6_dat.tdc_4	
		event_code = mvn_d6_dat.event_code 
		cyclestep = mvn_d6_dat.cyclestep
		energy = mvn_d6_dat.energy

			ev1 = (event_code and 1)
			ev2 = (event_code and 2)
			ev3 = (event_code and 4)/4*3
			ev4 = (event_code and 8)/8*4
			ev5 = (event_code and 16)/16*5
			ev6 = (event_code and 32)/32*6
			ev_cd = [[ev1],[ev2],[ev3],[ev4],[ev5],[ev6]]
		store_data,'mvn_sta_d6_tdc1',data={x:time_unix,y:tdc_1+1}
		store_data,'mvn_sta_d6_tdc2',data={x:time_unix,y:tdc_2+1}
		store_data,'mvn_sta_d6_tdc3',data={x:time_unix,y:tdc_3*(-2*ev1+1)}
		store_data,'mvn_sta_d6_tdc4',data={x:time_unix,y:tdc_4*(-ev2+1)}
		store_data,'mvn_sta_d6_ev',data={x:time_unix,y:ev_cd,v:[1,2,3,4,5,6]}
		store_data,'mvn_sta_d6_cy',data={x:time_unix,y:cyclestep}
		store_data,'mvn_sta_d6_en',data={x:time_unix,y:energy}

		ylim,'mvn_sta_d6_tdc1',.5,1024,1
		ylim,'mvn_sta_d6_tdc2',.5,1024,1
		ylim,'mvn_sta_d6_tdc3',-530,530,0
		ylim,'mvn_sta_d6_tdc4',-530,530,0
		ylim,'mvn_sta_d6_ev',-1,7,0
		ylim,'mvn_sta_d6_cy',-1,1024,0
		ylim,'mvn_sta_d6_en',.1,30000.,1
		options,'mvn_sta_d6_tdc1',psym=3
		options,'mvn_sta_d6_tdc2',psym=3
		options,'mvn_sta_d6_tdc3',psym=3
		options,'mvn_sta_d6_tdc4',psym=3
		options,'mvn_sta_d6_ev',psym=3
		options,'mvn_sta_d6_cy',psym=3
		options,'mvn_sta_d6_en',psym=3

	endif

; D7
	if size(mvn_d7_dat,/type) eq 8 then begin

		time = mvn_d7_dat.time
		store_data,'mvn_sta_d7_data',data={x:time,y:1.*mvn_d7_dat.hkp_raw}
		store_data,'mvn_sta_d7_data_cal',data={x:time,y:mvn_d7_dat.hkp_calib}
		store_data,'mvn_sta_d7_data_mux',data={x:time,y:mvn_d7_dat.hkp_ind}
			options,'mvn_sta_d7_data_cal',datagap=1.
			options,'mvn_sta_d7_data_mux',datagap=1.
			options,'mvn_sta_d7_data',datagap=1.

	endif

	options,'mvn_sta*',no_interp=1

end


