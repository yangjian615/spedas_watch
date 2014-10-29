;+
;PROCEDURE:	mvn_sta_get_c2
;PURPOSE:	
;	Returns APID c2 data structure at a single time from common generated by mvn_sta_prod_cal.pro
;INPUT:		
;	time:		dbl		time of data to be returned
;
;KEYWORDS:
;	start:		0,1		if set, gets first time in common block
;	en:		0,1		if set, gets last time in common block
;	advance		0,1		if set, gets next time in common block
;	retreat		0,1		if set, gets previous time in common block
;	index		long		gets data at the index value "ind" in common block
;	calib:		0,1		not working yet, allows alternate calibration
;	times		0,1		returns an array of times for all the data, returns 0 if no data
;
;
;CREATED BY:	J. McFadden
;VERSION:	1
;LAST MODIFICATION:  13/11/12
;MOD HISTORY:
;
;NOTES:	  
;	Data structures can be used as inputs to functions such as n_4d.pro, v_4d.pro
;	Or used in conjunction with iterative programs such as get_2dt.pro, get_en_spec.pro
;-
FUNCTION mvn_sta_get_c2,time,START=st,EN=en,ADVANCE=adv,RETREAT=ret,index=ind,calib=calib,times=times

common mvn_c2,get_ind,all_dat

if n_elements(get_ind) eq 0 then begin
	if keyword_set(times) then return,0
	dat = 	{project_name:'MAVEN',valid:0}
	print,' ERROR - mvn c2 data not loaded'
	return,dat
endif else if get_ind eq -1 then begin
	dat = 	{project_name:'MAVEN',valid:0}
	print,' ERROR - mvn c2 data not loaded'
	return,dat
endif else if keyword_set(times) then begin
	dat=(all_dat.time+all_dat.end_time)/2.
endif else begin

if (n_elements(time) eq 0) and (not keyword_set(st)) and (not keyword_set(en)) $
        and (not keyword_set(adv)) and (not keyword_set(ret)) and (n_elements(ind) eq 0) $
	then ctime,time,npoints=1

if keyword_set(st) then ind=0l 						$
	else if keyword_set(en) then ind=n_elements(all_dat.time)-1 	$
	else if keyword_set(adv) then ind=get_ind+1 			$
	else if keyword_set(ret) then ind=get_ind-1 			$
	else if n_elements(ind) ne 0 then ind=ind 			$
	else tmpmin = min(abs(all_dat.time-time),ind)

if ind lt 0 or ind ge n_elements(all_dat.time) then begin

dat = 		{project_name:		all_dat.project_name,		$
		spacecraft:		all_dat.spacecraft, 		$
		data_name:		all_dat.data_name, 		$
		apid:			all_dat.apid,			$
		valid: 			0}

endif else begin

	while (all_dat.valid[ind] eq 0 and ind+1 lt n_elements(all_dat.time)) do ind=ind+1

	mode	= all_dat.mode[ind]
	rate	= all_dat.rate[ind]
	md	= all_dat.md[ind]
	swp_ind	= all_dat.swp_ind[ind]
	mlut_ind= all_dat.mlut_ind[ind]
	eff_ind	= all_dat.eff_ind[ind]
	att_ind	= all_dat.att_ind[ind]
	gf2	= reform(all_dat.gf[swp_ind,*,att_ind])#replicate(1.,all_dat.nmass)

dat = 		{project_name:		all_dat.project_name,			$
		spacecraft:		all_dat.spacecraft, 			$
		data_name:		all_dat.data_name, 			$
		apid:			all_dat.apid,				$
		units_name: 		'counts', 				$
		units_procedure: 	all_dat.units_procedure, 		$
		valid: 			all_dat.valid[ind], 			$
		quality_flag: 		all_dat.quality_flag[ind], 		$

		time: 			all_dat.time[ind], 			$
		end_time: 		all_dat.end_time[ind], 			$
		delta_t: 		all_dat.delta_t[ind],			$
		integ_t: 		all_dat.integ_t[ind],			$

		md:			md,					$
		mode:			mode,					$
		rate:			rate,					$
		swp_ind:		swp_ind,				$
		mlut_ind:		mlut_ind,				$
		eff_ind:		eff_ind,				$
		att_ind:		att_ind,				$

		nenergy: 		all_dat.nenergy, 			$
		energy: 		reform(all_dat.energy[swp_ind,*,*]), 	$
		denergy: 		reform(all_dat.denergy[swp_ind,*,*]),   $

		nbins: 			all_dat.nbins,	 			$
		bins: 			all_dat.bins, 				$
		ndef:			all_dat.ndef,				$
		nanode:			all_dat.nanode,				$

		theta: 			reform(all_dat.theta[swp_ind,*,*]),  	$
		dtheta: 		reform(all_dat.dtheta[swp_ind,*,*]),  	$
		phi: 			reform(all_dat.phi[swp_ind,*,*]),  	$
		dphi: 			reform(all_dat.dphi[swp_ind,*,*]),	$
		domega: 		reform(all_dat.domega[swp_ind,*,*]),  	$

		gf: 			gf2,					$
		eff: 			reform(all_dat.eff[eff_ind,*,*]),	$

		geom_factor: 		all_dat.geom_factor, 			$
;		dead: 			all_dat.dead,				$

		nmass:			all_dat.nmass,				$
		mass: 			all_dat.mass, 				$
		mass_arr: 		reform(all_dat.mass_arr[swp_ind,*,*]), 	$
		tof_arr: 		reform(all_dat.tof_arr[mlut_ind,*,*]), 	$
		twt_arr: 		reform(all_dat.twt_arr[mlut_ind,*,*]), 	$

		charge: 		all_dat.charge, 			$
		sc_pot: 		all_dat.sc_pot[ind], 			$
		magf:	 		reform(all_dat.magf[ind,*]), 		$
		quat_sc:	 	reform(all_dat.quat_sc[ind,*]), 	$
		quat_mso:	 	reform(all_dat.quat_mso[ind,*]), 	$
		bins_sc:		reform(all_dat.bins_sc[ind,*]),		$
		pos_sc_mso:		reform(all_dat.pos_sc_mso[ind,*]),	$

		bkg:	 		reform(all_dat.bkg[ind,*,*]),		$

		data: 			reform(all_dat.data[ind,*,*])}

get_ind=ind

endelse
endelse

return,dat

end
