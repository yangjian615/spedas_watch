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
	common mvn_d4,mvn_d4_ind,mvn_d4_dat 

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

	options,'mvn_sta*',no_interp=1

end


