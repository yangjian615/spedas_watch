;+
;PROCEDURE: 
;	MVN_SWIA_PART_MOMENTS
;PURPOSE: 
;	Make tplot variables with moments from SWIA 3d data (coarse and/or fine), 
;	including average energy flux spectra
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE: 
;	MVN_SWIA_PART_MOMENTS, TYPE = TYPE
;KEYWORDS:
;	TYPE: Array of types to calculate moments for, out of ['CS','CA','FS','FA','S']
;		(Coarse survey/archive, Fine survey/archive) - Defaults to all types
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2013-12-17 11:37:06 -0800 (Tue, 17 Dec 2013) $
; $LastChangedRevision: 13696 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_part_moments.pro $
;
;-

pro mvn_swia_part_moments, type = type

compile_opt idl2

common mvn_swia_data

if not keyword_set(type) then type = ['ca','cs','fa','fs','s']

w = where(strupcase(type) eq 'FS',nw)

if nw gt 0 and n_elements(swifs) gt 0 then begin
	ctime = swifs.time_unix + 2.0
	nt = n_elements(ctime)
	
	if nt gt 0 then begin
		
		efluxes = fltarr(nt,48)
		energies = fltarr(nt,48)
		densities = fltarr(nt)
		velocities = fltarr(nt,3)
		pressures = fltarr(nt,6)
		temperatures = fltarr(nt,4)
		heatfluxes = fltarr(nt,3)


		for i = 0L,nt-1 do begin
			if i eq 0 then start = 1 else start = 0
			
			dat = mvn_swia_get_3df(index = i, start = start)
			
			dat = conv_units(dat,'eflux')

			energies[i,*] = total(dat.energy*dat.domega,2)/total(dat.domega,2)
			efluxes[i,*] = total(dat.data*dat.domega,2)/total(dat.domega,2)

			densities[i] = n_3d(dat)
			velocities[i,*] = v_3d(dat)
			pressures[i,*] = p_3d(dat)
			temperatures[i,*] = t_3d(dat)
			heatfluxes[i,*] = je_3d(dat)
		endfor

		store_data,'mvn_swifs_en_eflux',data = {x:ctime, y: efluxes, v:energies, ylog:1, zlog:1, spec: 1, no_interp:1, yrange: [4,30000], ystyle: 1, zrange: [1e5,1e11], ytitle: 'SWIA!cEnergy (eV)', ztitle: 'eV/[eV cm!E2!N s sr]'}, dlimits = {datagap:180}

		store_data,'mvn_swifs_density', data = {x:ctime, y: densities, ytitle: 'SWIA!cDensity!C[cm!E-3!N]'}

		store_data,'mvn_swifs_velocity',data = {x:ctime,y:velocities,v:[0,1,2],labels:['Vx','Vy','Vz'],labflag:1,ytitle:'SWIA!cVelocity!c[km/s]'}

		store_data,'mvn_swifs_pressure',data = {x:ctime,y:pressures, v:[0,1,2,3,4,5], labels: ['Pxx','Pyy','Pzz','Pxy','Pxz','Pyz'], labflag:1, ytitle: 'SWIA!cPressure!c[eV/cm!E3!N]'}

		store_data, 'mvn_swifs_temperature', data = {x:ctime,y:temperatures, v:[0,1,2,3], labels: ['Tx','Ty','Tz','Tmag'], labflag:1, ytitle: 'SWIA!cTemperature!c[eV]'}

		store_data,'mvn_swifs_heatflux', data = {x:ctime,y:heatfluxes, v:[0,1,2], labels: ['Qx','Qy','Qz'], labflag:1, ytitle: 'SWIA!cHeat Flux!c[ergs/cm!E2!N s]'}


	endif
endif

w = where(strupcase(type) eq 'FA',nw)

if nw gt 0 and n_elements(swifa) gt 0 then begin
	ctime = swifa.time_unix + 2.0
	nt = n_elements(ctime)
	
	if nt gt 0 then begin
		
		efluxes = fltarr(nt,48)
		energies = fltarr(nt,48)
		densities = fltarr(nt)
		velocities = fltarr(nt,3)
		pressures = fltarr(nt,6)
		temperatures = fltarr(nt,4)
		heatfluxes = fltarr(nt,3)


		for i = 0L,nt-1 do begin
			if i eq 0 then start = 1 else start = 0

			dat = mvn_swia_get_3df(index = i,/archive, start = start)
			
			dat = conv_units(dat,'eflux')

			energies[i,*] = total(dat.energy*dat.domega,2)/total(dat.domega,2)
			efluxes[i,*] = total(dat.data*dat.domega,2)/total(dat.domega,2)

			densities[i] = n_3d(dat)
			velocities[i,*] = v_3d(dat)
			pressures[i,*] = p_3d(dat)
			temperatures[i,*] = t_3d(dat)
			heatfluxes[i,*] = je_3d(dat)
		endfor

		store_data,'mvn_swifa_en_eflux',data = {x:ctime, y: efluxes, v:energies, ylog:1, zlog:1, spec: 1, no_interp:1, yrange: [4,30000], ystyle: 1, zrange: [1e5,1e11], ytitle: 'SWIA!cEnergy (eV)', ztitle: 'eV/[eV cm!E2!N s sr]'}, dlimits = {datagap:180}

		store_data,'mvn_swifa_density', data = {x:ctime, y: densities, ytitle: 'SWIA!cDensity!C[cm!E-3!N]'}

		store_data,'mvn_swifa_velocity',data = {x:ctime,y:velocities,v:[0,1,2],labels:['Vx','Vy','Vz'],labflag:1,ytitle:'SWIA!cVelocity!c[km/s]'}

		store_data,'mvn_swifa_pressure',data = {x:ctime,y:pressures, v:[0,1,2,3,4,5], labels: ['Pxx','Pyy','Pzz','Pxy','Pxz','Pyz'], labflag:1, ytitle: 'SWIA!cPressure!c[eV/cm!E3!N]'}

		store_data, 'mvn_swifa_temperature', data = {x:ctime,y:temperatures, v:[0,1,2,3], labels: ['Tx','Ty','Tz','Tmag'], labflag:1, ytitle: 'SWIA!cTemperature!c[eV]'}

		store_data,'mvn_swifa_heatflux', data = {x:ctime,y:heatfluxes, v:[0,1,2], labels: ['Qx','Qy','Qz'], labflag:1, ytitle: 'SWIA!cHeat Flux!c[ergs/cm!E2!N s]'}


	endif
endif


w = where(strupcase(type) eq 'CS',nw)

if nw gt 0 and n_elements(swics) gt 0 then begin
	ctime = swics.time_unix + 4.0*swics.num_accum/2
	nt = n_elements(ctime)
	
	if nt gt 0 then begin
		
		efluxes = fltarr(nt,48)
		energies = fltarr(nt,48)
		densities = fltarr(nt)
		velocities = fltarr(nt,3)
		pressures = fltarr(nt,6)
		temperatures = fltarr(nt,4)
		heatfluxes = fltarr(nt,3)


		for i = 0L,nt-1 do begin
			if i eq 0 then start = 1 else start = 0
			
			dat = mvn_swia_get_3dc(index = i, start = start)
			
			dat = conv_units(dat,'eflux')

			energies[i,*] = total(dat.energy*dat.domega,2)/total(dat.domega,2)
			efluxes[i,*] = total(dat.data*dat.domega,2)/total(dat.domega,2)

			densities[i] = n_3d(dat)
			velocities[i,*] = v_3d(dat)
			pressures[i,*] = p_3d(dat)
			temperatures[i,*] = t_3d(dat)
			heatfluxes[i,*] = je_3d(dat)
		endfor

		store_data,'mvn_swics_en_eflux',data = {x:ctime, y: efluxes, v:energies, ylog:1, zlog:1, spec: 1, no_interp:1, yrange: [4,30000], ystyle: 1, zrange: [1e5,1e11], ytitle: 'SWIA!cEnergy (eV)', ztitle: 'eV/[eV cm!E2!N s sr]'}, dlimits = {datagap:180}

		store_data,'mvn_swics_density', data = {x:ctime, y: densities, ytitle: 'SWIA!cDensity!C[cm!E-3!N]'}

		store_data,'mvn_swics_velocity',data = {x:ctime,y:velocities,v:[0,1,2],labels:['Vx','Vy','Vz'],labflag:1,ytitle:'SWIA!cVelocity!c[km/s]'}

		store_data,'mvn_swics_pressure',data = {x:ctime,y:pressures, v:[0,1,2,3,4,5], labels: ['Pxx','Pyy','Pzz','Pxy','Pxz','Pyz'], labflag:1, ytitle: 'SWIA!cPressure!c[eV/cm!E3!N]'}

		store_data, 'mvn_swics_temperature', data = {x:ctime,y:temperatures, v:[0,1,2,3], labels: ['Tx','Ty','Tz','Tmag'], labflag:1, ytitle: 'SWIA!cTemperature!c[eV]'}

		store_data,'mvn_swics_heatflux', data = {x:ctime,y:heatfluxes, v:[0,1,2], labels: ['Qx','Qy','Qz'], labflag:1, ytitle: 'SWIA!cHeat Flux!c[ergs/cm!E2!N s]'}


	endif
endif

w = where(strupcase(type) eq 'CA',nw)

if nw gt 0 and n_elements(swica) gt 0 then begin
	ctime = swica.time_unix + 4.0*swica.num_accum/2
	nt = n_elements(ctime)
	
	if nt gt 0 then begin
		
		efluxes = fltarr(nt,48)
		energies = fltarr(nt,48)
		densities = fltarr(nt)
		velocities = fltarr(nt,3)
		pressures = fltarr(nt,6)
		temperatures = fltarr(nt,4)
		heatfluxes = fltarr(nt,3)


		for i = 0L,nt-1 do begin
			if i eq 0 then start = 1 else start = 0
			
			dat = mvn_swia_get_3dc(index = i,/archive, start = start)
			
			dat = conv_units(dat,'eflux')

			energies[i,*] = total(dat.energy*dat.domega,2)/total(dat.domega,2)
			efluxes[i,*] = total(dat.data*dat.domega,2)/total(dat.domega,2)

			densities[i] = n_3d(dat)
			velocities[i,*] = v_3d(dat)
			pressures[i,*] = p_3d(dat)
			temperatures[i,*] = t_3d(dat)
			heatfluxes[i,*] = je_3d(dat)
		endfor

		store_data,'mvn_swica_en_eflux',data = {x:ctime, y: efluxes, v:energies, ylog:1, zlog:1, spec: 1, no_interp:1, yrange: [4,30000], ystyle: 1, zrange: [1e5,1e11], ytitle: 'SWIA!cEnergy (eV)', ztitle: 'eV/[eV cm!E2!N s sr]'}, dlimits = {datagap:180}

		store_data,'mvn_swica_density', data = {x:ctime, y: densities, ytitle: 'SWIA!cDensity!C[cm!E-3!N]'}

		store_data,'mvn_swica_velocity',data = {x:ctime,y:velocities,v:[0,1,2],labels:['Vx','Vy','Vz'],labflag:1,ytitle:'SWIA!cVelocity!c[km/s]'}

		store_data,'mvn_swica_pressure',data = {x:ctime,y:pressures, v:[0,1,2,3,4,5], labels: ['Pxx','Pyy','Pzz','Pxy','Pxz','Pyz'], labflag:1, ytitle: 'SWIA!cPressure!c[eV/cm!E3!N]'}

		store_data, 'mvn_swica_temperature', data = {x:ctime,y:temperatures, v:[0,1,2,3], labels: ['Tx','Ty','Tz','Tmag'], labflag:1, ytitle: 'SWIA!cTemperature!c[eV]'}

		store_data,'mvn_swica_heatflux', data = {x:ctime,y:heatfluxes, v:[0,1,2], labels: ['Qx','Qy','Qz'], labflag:1, ytitle: 'SWIA!cHeat Flux!c[ergs/cm!E2!N s]'}


	endif
endif



w = where(strupcase(type) eq 'S',nw)

; Note that the moments from the spectra are not great with the attenuator in if the 
; count rate is not relatively uniform in phi. The convolution of non-uniform geometric
; factor and non-uniform count rate can't really be captured in the spectra. I put in an
; correction with the assumption that if the attenuator is in, this implies we're in the
; solar wind and all the counts are in the attenuated direction, which should be pretty 
; good for most realistic cases.  

if nw gt 0 and n_elements(swis) gt 0 then begin
	ctime = swis.time_unix + 4.0*swis.num_accum/2
	nt = n_elements(ctime)
	
	if nt gt 0 then begin
		
		efluxes = fltarr(nt,48)
		energies = fltarr(nt,48)
		densities = fltarr(nt)


		for i = 0L,nt-1 do begin
			if i eq 0 then start = 1 else start = 0
			
			dat = mvn_swia_get_3ds(index = i, start = start)
			
			dat = conv_units(dat,'eflux')

			energies[i,*] = dat.energy
			efluxes[i,*] = dat.data

			densities[i] = n_3d_new(dat)
		endfor

		store_data,'mvn_swis_en_eflux',data = {x:ctime, y: efluxes, v:energies, ylog:1, zlog:1, spec: 1, no_interp:1, yrange: [4,30000], ystyle: 1, zrange: [1e5,1e11], ytitle: 'SWIA!cEnergy (eV)', ztitle: 'eV/[eV cm!E2!N s sr]'}, dlimits = {datagap:180}

		store_data,'mvn_swis_density', data = {x:ctime, y: densities, ytitle: 'SWIA!cDensity!C[cm!E-3!N]'}

	endif
endif

end