;+
;PROCEDURE: 
;	MVN_SWIA_LOAD_L2_DATA
;PURPOSE: 
;	Routine to load SWIA Level 2 data and produce common blocks and Tplot variables
;	This routine is still preliminary and will include a lot more bells and whistles
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	MVN_SWIA_LOAD_L2_DATA, /TPLOT, /LOADALL, /EFLUX, TRANGE = TRANGE
;INPUTS:
;	Files: An array of filenames containing PF Level 2 data, by default just the dates in 'YYYYMMDD' format
;KEYWORDS:
;	PATH: Directory path for level 2 files (default '/disks/data/maven/data/sci/swi/l2/')
;	VERSION: Software version number to put in file (default '000')
;	REVISION: Data version number to put in file (default '000')
;	TPLOT: Produce Tplot variables
;	QLEVEL: Set this keyword to not plot moments or spectra with a low quality flag
;		or decommutation quality flag.  Default cutoff = 0.5
;	LOADMOM: Load moments data
;	LOADSPEC: Load spectra data
;	LOADFINE: Load fine resolution 3d data (survey + archive)
;	LOADCOARSE: Load coarse resolution 3d data (survey + archive)
;	LOADALL: Load all data for a given day or days
;	TRANGE: Load data for all files within given range (one day granularity, supercedes file list)
;	EFLUX: Load eflux data instead of counts for 3ds and spectra
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2014-08-29 11:31:03 -0700 (Fri, 29 Aug 2014) $
; $LastChangedRevision: 15724 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_load_l2_data.pro $
;
;-

pro mvn_swia_load_l2_data, files, path = path, version = version, revision = revision, tplot = tplot, qlevel = qlevel, loadmom = loadmom, loadspec = loadspec, loadfine = loadfine, loadcoarse = loadcoarse, loadall = loadall, trange = trange, eflux = eflux

;FIXME: Figure out valid time ranges for /novary stuff in info_str
;FIXME: Might want to make sure everything is sorted in time after loading
;FIXME: Automatically find most recent version/revision?

compile_opt idl2

common mvn_swia_data, info_str, swihsk, swics, swica, swifs, swifa, swim, swis


if keyword_set(loadall) then begin
	loadmom = 1
	loadspec = 1
	loadfine = 1
	loadcoarse = 1
endif


if not keyword_set(path) then path = '/disks/data/maven/data/sci/swi/l2/'
if not keyword_set(version) then version = '000'
if not keyword_set(revision) then revision = '000'
if keyword_set(eflux) then units = 'eflux' else units = 'counts'

if not keyword_set(qlevel) then qlevel = 0.5

if keyword_set(trange) then begin
	trange = time_double(trange)
	days = (trange[1]-trange[0])/(24.*3600)
	t0 = time_double(strmid(time_string(trange[0]),0,10))
	dates = time_string(t0 + indgen(days)*24.d*3600, format = 6)
	files = strmid(dates, 0, 8)
endif

nfiles = n_elements(files)


mvn_swia_make_info_str,info_str

info_str = replicate(info_str,nfiles)


swif_str = {time_met: 0.d, $
time_unix: 0.d, $
data: fltarr(48,12,10), $
estep_first: 0, $
dstep_first: 0, $
atten_state: 0., $
grouping: 0, $
info_index: 0, $
units: units}

swic_str = {time_met: 0.d, $
time_unix: 0.d, $
data: fltarr(48,4,16), $
atten_state: 0., $
grouping: 0, $
num_accum: 0, $
info_index: 0, $
units: units}

swis_str = {time_met: 0.d, $
time_unix: 0.d, $
data: fltarr(48), $
atten_state: 0., $
num_accum: 0, $
info_index: 0, $
units: units, $
decom_flag: 1.0}

swim_str = {time_met: 0.d, $
time_unix: 0.d, $
density: 0., $
velocity: fltarr(3), $
velocity_mso: fltarr(3), $
pressure: fltarr(6), $
temperature: fltarr(3), $
temperature_mso: fltarr(3), $
heat_flux: fltarr(3), $
swi_mode: 0, $
atten_state: 0., $
info_index: 0, $
coordinates: 'Instrument', $
quality_flag: 1.0, $
decom_flag: 1.0}


swics = 0
swifs = 0
swica = 0
swifa = 0
swim = 0
swis = 0

for i = 0,nfiles-1 do begin


	print,'Reading File for Date: ',files[i]

	yyyy = strmid(files[i],0,4)
	mm = strmid(files[i],4,2)
	dd = strmid(files[i],6,2)

	fine_svy_file = path+yyyy+'/'+mm+'/mvn_swi_l2_finesvy3d_'+files[i]+'_v'+version+'_r'+revision+'.cdf'
	fine_arc_file = path+yyyy+'/'+mm+'/mvn_swi_l2_finearc3d_'+files[i]+'_v'+version+'_r'+revision+'.cdf'
	coarse_svy_file = path+yyyy+'/'+mm+'/mvn_swi_l2_coarsesvy3d_'+files[i]+'_v'+version+'_r'+revision+'.cdf'
	coarse_arc_file = path+yyyy+'/'+mm+'/mvn_swi_l2_coarsearc3d_'+files[i]+'_v'+version+'_r'+revision+'.cdf'
	spec_file = path+yyyy+'/'+mm+'/mvn_swi_l2_onboardsvyspec_'+files[i]+'_v'+version+'_r'+revision+'.cdf'
	mom_file = path+yyyy+'/'+mm+'/mvn_swi_l2_onboardsvymom_'+files[i]+'_v'+version+'_r'+revision+'.cdf'

	result = file_search(fine_svy_file)
	if keyword_set(loadfine) and result ne '' then begin
		print,'Fine Survey'
		id = cdf_open(fine_svy_file,/readonly)
		cdf_varget,id,'Num_Dists',nrec,/zvariable
		
		if i eq 0 or n_elements(swifs) lt 2 then begin
			offset = 0L
			swifs = replicate(swif_str,nrec) 
		endif else begin
			offset = n_elements(swifs)
			swifs = [swifs,replicate(swif_str,nrec)]
		endelse

		cdf_varget,id,'Time_Unix',output,rec_count = nrec,/zvariable
		swifs[offset:offset+nrec-1].time_unix = reform(output)
		cdf_varget,id,'Time_MET',output,rec_count = nrec,/zvariable
		swifs[offset:offset+nrec-1].time_met = reform(output)
		cdf_varget,id,'Atten_State',output,rec_count = nrec,/zvariable
		swifs[offset:offset+nrec-1].atten_state = reform(output)
		cdf_varget,id,'Grouping',output,rec_count = nrec,/zvariable
		swifs[offset:offset+nrec-1].grouping = reform(output)
		cdf_varget,id,'Estep_First',output,rec_count = nrec,/zvariable
		swifs[offset:offset+nrec-1].estep_first = reform(output)
		cdf_varget,id,'Dstep_First',output,rec_count = nrec,/zvariable
		swifs[offset:offset+nrec-1].dstep_first = reform(output)

		if keyword_set(eflux) then begin
			cdf_varget,id,'Diff_En_Fluxes',output,rec_count = nrec,/zvariable
		endif else begin
			cdf_varget,id,'Counts',output,rec_count = nrec,/zvariable
		endelse
		swifs[offset:offset+nrec-1].data = output

		swifs[offset:offset+nrec-1].info_index = i

		cdf_varget,id,'Geom_Factor',output,/zvariable
		info_str[i].geom = output
		cdf_varget,id,'De_Over_E_Fine',output,/zvariable
		info_str[i].deovere_fine = output
		cdf_varget,id,'Accum_Time_Fine',output,/zvariable
		info_str[i].dt_int = output
		cdf_varget,id,'Energy_Fine',output,/zvariable
		info_str[i].energy_fine = output
		cdf_varget,id,'Theta_Fine',output,/zvariable
		info_str[i].theta_fine = output
		cdf_varget,id,'Theta_Atten_Fine',output,/zvariable
		info_str[i].theta_fine_atten = output
		cdf_varget,id,'G_Theta_Fine',output,/zvariable
		info_str[i].g_th_fine = output
		cdf_varget,id,'G_Theta_Atten_Fine',output,/zvariable
		info_str[i].g_th_fine_atten = output
		cdf_varget,id,'Phi_Fine',output,/zvariable
		info_str[i].phi_fine = output
		cdf_varget,id,'G_Phi_Fine',output,/zvariable
		info_str[i].geom_fine = output
		cdf_varget,id,'G_Phi_Atten_Fine',output,/zvariable
		info_str[i].geom_fine_atten = output

		cdf_close,id
	endif else print,'No Fine Survey'


	result = file_search(fine_arc_file)
	if keyword_set(loadfine) and result ne '' then begin
		print,'Fine Archive'
		id = cdf_open(fine_arc_file,/readonly)
		cdf_varget,id,'Num_Dists',nrec,/zvariable
		
		if i eq 0 or n_elements(swifa) lt 2 then begin
			offset = 0L
			swifa = replicate(swif_str,nrec) 
		endif else begin
			offset = n_elements(swifa)
			swifa = [swifa,replicate(swif_str,nrec)]
		endelse

		cdf_varget,id,'Time_Unix',output,rec_count = nrec,/zvariable
		swifa[offset:offset+nrec-1].time_unix = reform(output)
		cdf_varget,id,'Time_MET',output,rec_count = nrec,/zvariable
		swifa[offset:offset+nrec-1].time_met = reform(output)
		cdf_varget,id,'Atten_State',output,rec_count = nrec,/zvariable
		swifa[offset:offset+nrec-1].atten_state = reform(output)
		cdf_varget,id,'Grouping',output,rec_count = nrec,/zvariable
		swifa[offset:offset+nrec-1].grouping = reform(output)
		cdf_varget,id,'Estep_First',output,rec_count = nrec,/zvariable
		swifa[offset:offset+nrec-1].estep_first = reform(output)
		cdf_varget,id,'Dstep_First',output,rec_count = nrec,/zvariable
		swifa[offset:offset+nrec-1].dstep_first = reform(output)

		if keyword_set(eflux) then begin
			cdf_varget,id,'Diff_En_Fluxes',output,rec_count = nrec,/zvariable
		endif else begin
			cdf_varget,id,'Counts',output,rec_count = nrec,/zvariable
		endelse
		swifa[offset:offset+nrec-1].data = output

		swifa[offset:offset+nrec-1].info_index = i

		cdf_varget,id,'Geom_Factor',output,/zvariable
		info_str[i].geom = output
		cdf_varget,id,'De_Over_E_Fine',output,/zvariable
		info_str[i].deovere_fine = output
		cdf_varget,id,'Accum_Time_Fine',output,/zvariable
		info_str[i].dt_int = output
		cdf_varget,id,'Energy_Fine',output,/zvariable
		info_str[i].energy_fine = output
		cdf_varget,id,'Theta_Fine',output,/zvariable
		info_str[i].theta_fine = output
		cdf_varget,id,'Theta_Atten_Fine',output,/zvariable
		info_str[i].theta_fine_atten = output
		cdf_varget,id,'G_Theta_Fine',output,/zvariable
		info_str[i].g_th_fine = output
		cdf_varget,id,'G_Theta_Atten_Fine',output,/zvariable
		info_str[i].g_th_fine_atten = output
		cdf_varget,id,'Phi_Fine',output,/zvariable
		info_str[i].phi_fine = output
		cdf_varget,id,'G_Phi_Fine',output,/zvariable
		info_str[i].geom_fine = output
		cdf_varget,id,'G_Phi_Atten_Fine',output,/zvariable
		info_str[i].geom_fine_atten = output

		cdf_close,id
	endif else print,'No Fine Archive'


	result = file_search(coarse_svy_file)
	if keyword_set(loadcoarse) and result ne '' then begin
		print,'Coarse Survey'
		id = cdf_open(coarse_svy_file,/readonly)
		cdf_varget,id,'Num_Dists',nrec,/zvariable
		
		if i eq 0 or n_elements(swics) lt 2 then begin
			offset = 0L
			swics = replicate(swic_str,nrec) 
		endif else begin
			offset = n_elements(swics)
			swics = [swics,replicate(swic_str,nrec)]
		endelse

		cdf_varget,id,'Time_Unix',output,rec_count = nrec,/zvariable
		swics[offset:offset+nrec-1].time_unix = reform(output)
		cdf_varget,id,'Time_MET',output,rec_count = nrec,/zvariable
		swics[offset:offset+nrec-1].time_met = reform(output)
		cdf_varget,id,'Atten_State',output,rec_count = nrec,/zvariable
		swics[offset:offset+nrec-1].atten_state = reform(output)
		cdf_varget,id,'Grouping',output,rec_count = nrec,/zvariable
		swics[offset:offset+nrec-1].grouping = reform(output)
		cdf_varget,id,'Num_Accum',output,rec_count = nrec,/zvariable
		swics[offset:offset+nrec-1].num_accum = reform(output)
		if keyword_set(eflux) then begin
			cdf_varget,id,'Diff_En_Fluxes',output,rec_count = nrec,/zvariable
		endif else begin
			cdf_varget,id,'Counts',output,rec_count = nrec,/zvariable
		endelse
		swics[offset:offset+nrec-1].data = output

		swics[offset:offset+nrec-1].info_index = i

		cdf_varget,id,'Geom_Factor',output,/zvariable
		info_str[i].geom = output
		cdf_varget,id,'De_Over_E_Coarse',output,/zvariable
		info_str[i].deovere_coarse = output
		cdf_varget,id,'Accum_Time_Coarse',output,/zvariable
		info_str[i].dt_int = output/12
		cdf_varget,id,'Energy_Coarse',output,/zvariable
		info_str[i].energy_coarse = output
		cdf_varget,id,'Theta_Coarse',output,/zvariable
		info_str[i].theta_coarse = output
		cdf_varget,id,'Theta_Atten_Coarse',output,/zvariable
		info_str[i].theta_coarse_atten = output
		cdf_varget,id,'G_Theta_Coarse',output,/zvariable
		info_str[i].g_th_coarse = output
		cdf_varget,id,'G_Theta_Atten_Coarse',output,/zvariable
		info_str[i].g_th_coarse_atten = output
		cdf_varget,id,'Phi_Coarse',output,/zvariable
		info_str[i].phi_coarse = output
		cdf_varget,id,'G_Phi_Coarse',output,/zvariable
		info_str[i].geom_coarse = output
		cdf_varget,id,'G_Phi_Atten_Coarse',output,/zvariable
		info_str[i].geom_coarse_atten = output

		cdf_close,id
	endif else print,'No Coarse Survey'


	result = file_search(coarse_arc_file)
	if keyword_set(loadcoarse) and result ne '' then begin
		print,'Coarse Archive'
		id = cdf_open(coarse_arc_file,/readonly)
		cdf_varget,id,'Num_Dists',nrec,/zvariable
		
		if i eq 0 or n_elements(swica) lt 2 then begin
			offset = 0L
			swica = replicate(swic_str,nrec) 
		endif else begin
			offset = n_elements(swica)
			swica = [swica,replicate(swic_str,nrec)]
		endelse

		cdf_varget,id,'Time_Unix',output,rec_count = nrec,/zvariable
		swica[offset:offset+nrec-1].time_unix = reform(output)
		cdf_varget,id,'Time_MET',output,rec_count = nrec,/zvariable
		swica[offset:offset+nrec-1].time_met = reform(output)
		cdf_varget,id,'Atten_State',output,rec_count = nrec,/zvariable
		swica[offset:offset+nrec-1].atten_state = reform(output)
		cdf_varget,id,'Grouping',output,rec_count = nrec,/zvariable
		swica[offset:offset+nrec-1].grouping = reform(output)
		cdf_varget,id,'Num_Accum',output,rec_count = nrec,/zvariable
		swica[offset:offset+nrec-1].num_accum = reform(output)
		if keyword_set(eflux) then begin
			cdf_varget,id,'Diff_En_Fluxes',output,rec_count = nrec,/zvariable
		endif else begin
			cdf_varget,id,'Counts',output,rec_count = nrec,/zvariable
		endelse
		swica[offset:offset+nrec-1].data = output

		swica[offset:offset+nrec-1].info_index = i

		cdf_varget,id,'Geom_Factor',output,/zvariable
		info_str[i].geom = output
		cdf_varget,id,'De_Over_E_Coarse',output,/zvariable
		info_str[i].deovere_coarse = output
		cdf_varget,id,'Accum_Time_Coarse',output,/zvariable
		info_str[i].dt_int = output/12
		cdf_varget,id,'Energy_Coarse',output,/zvariable
		info_str[i].energy_coarse = output
		cdf_varget,id,'Theta_Coarse',output,/zvariable
		info_str[i].theta_coarse = output
		cdf_varget,id,'Theta_Atten_Coarse',output,/zvariable
		info_str[i].theta_coarse_atten = output
		cdf_varget,id,'G_Theta_Coarse',output,/zvariable
		info_str[i].g_th_coarse = output
		cdf_varget,id,'G_Theta_Atten_Coarse',output,/zvariable
		info_str[i].g_th_coarse_atten = output
		cdf_varget,id,'Phi_Coarse',output,/zvariable
		info_str[i].phi_coarse = output
		cdf_varget,id,'G_Phi_Coarse',output,/zvariable
		info_str[i].geom_coarse = output
		cdf_varget,id,'G_Phi_Atten_Coarse',output,/zvariable
		info_str[i].geom_coarse_atten = output

		cdf_close,id
	endif else print,'No Coarse Archive'


	result = file_search(spec_file)
	if keyword_set(loadspec) and result ne '' then begin
		print,'Spectra'
		id = cdf_open(spec_file,/readonly)
		cdf_varget,id,'Num_Spec',nrec,/zvariable
		
		if i eq 0 or n_elements(swis) lt 2 then begin
			offset = 0L
			swis = replicate(swis_str,nrec) 
		endif else begin
			offset = n_elements(swis)
			swis = [swis,replicate(swis_str,nrec)]
		endelse

		cdf_varget,id,'Time_Unix',output,rec_count = nrec,/zvariable
		swis[offset:offset+nrec-1].time_unix = reform(output)
		cdf_varget,id,'Time_MET',output,rec_count = nrec,/zvariable
		swis[offset:offset+nrec-1].time_met = reform(output)
		cdf_varget,id,'Atten_State',output,rec_count = nrec,/zvariable
		swis[offset:offset+nrec-1].atten_state = reform(output)
		cdf_varget,id,'Decom_Flag',output,rec_count = nrec,/zvariable
		swis[offset:offset+nrec-1].decom_flag = reform(output)
		cdf_varget,id,'Num_Accum',output,rec_count = nrec,/zvariable
		swis[offset:offset+nrec-1].num_accum = reform(output)
		if keyword_set(eflux) then begin
			cdf_varget,id,'Spectra_Diff_En_Fluxes',output,rec_count = nrec,/zvariable
		endif else begin
			cdf_varget,id,'Spectra_Counts',output,rec_count = nrec,/zvariable
		endelse
		swis[offset:offset+nrec-1].data = output

		swis[offset:offset+nrec-1].info_index = i

		cdf_varget,id,'Geom_Factor',output,/zvariable
		info_str[i].geom = output
		cdf_varget,id,'De_Over_E_Spectra',output,/zvariable
		info_str[i].deovere_coarse = output
		cdf_varget,id,'Accum_Time_Spectra',output,/zvariable
		info_str[i].dt_int = output/12/64
		cdf_varget,id,'Energy_Spectra',output,/zvariable
		info_str[i].energy_coarse = output

		cdf_close,id
	endif else print,'No Spectra'


	result = file_search(mom_file)
	if keyword_set(loadmom) and result ne '' then begin
		print,'Moments'
		id = cdf_open(mom_file,/readonly)
		cdf_varget,id,'Num_Mom',nrec,/zvariable
		
		if i eq 0 or n_elements(swim) lt 2 then begin
			offset = 0L
			swim = replicate(swim_str,nrec) 
		endif else begin
			offset = n_elements(swim)
			swim = [swim,replicate(swim_str,nrec)]
		endelse

		cdf_varget,id,'Time_Unix',output,rec_count = nrec,/zvariable
		swim[offset:offset+nrec-1].time_unix = reform(output)
		cdf_varget,id,'Time_MET',output,rec_count = nrec,/zvariable
		swim[offset:offset+nrec-1].time_met = reform(output)
		cdf_varget,id,'Atten_State',output,rec_count = nrec,/zvariable
		swim[offset:offset+nrec-1].atten_state = reform(output)
		cdf_varget,id,'Telem_Mode',output,rec_count = nrec,/zvariable
		swim[offset:offset+nrec-1].swi_mode = reform(output)
		cdf_varget,id,'Decom_Flag',output,rec_count = nrec,/zvariable
		swim[offset:offset+nrec-1].decom_flag = reform(output)
		cdf_varget,id,'Quality_Flag',output,rec_count = nrec,/zvariable
		swim[offset:offset+nrec-1].quality_flag = reform(output)
		cdf_varget,id,'Density',output,rec_count = nrec,/zvariable
		swim[offset:offset+nrec-1].density = reform(output)
		cdf_varget,id,'Velocity',output,rec_count = nrec,/zvariable
		swim[offset:offset+nrec-1].velocity = output
		cdf_varget,id,'Velocity_MSO',output,rec_count = nrec,/zvariable
		swim[offset:offset+nrec-1].velocity_mso = output
		cdf_varget,id,'Temperature',output,rec_count = nrec,/zvariable
		swim[offset:offset+nrec-1].temperature = output
		cdf_varget,id,'Temperature_MSO',output,rec_count = nrec,/zvariable
		swim[offset:offset+nrec-1].temperature_mso = output
		cdf_varget,id,'Pressure',output,rec_count = nrec,/zvariable
		swim[offset:offset+nrec-1].pressure = output

		swim[offset:offset+nrec-1].info_index = i

		cdf_close,id
	endif else print,'No Moments'


endfor



if keyword_set(tplot) then begin
	if n_elements(swihsk) gt 0 then begin
		store_data,'mvn_swia_temps', data = {x:swihsk.time_unix, y: [[swihsk.lvpst],[swihsk.digt]], v:[0,1], labels: ['LVPS','DIG'],labflag:1, ytitle: 'SWIA!cTemp'}
		store_data,'mvn_swia_imons', data = {x:swihsk.time_unix, y: [[swihsk.imon_mcp],[swihsk.imon_raw]], v:[0,1], labels: ['MCP','RAW'],labflag:1, ytitle: 'SWIA!cHV Imon'}
		store_data,'mvn_swia_vmon_fixed', data = {x:swihsk.time_unix, y: [[swihsk.vmon_mcp],[swihsk.vmon_raw_def],[swihsk.vmon_raw_swp]], v:[0,1,2], labels: ['MCP','DEF','SWP'],labflag:1, ytitle: 'SWIA!cHV RAW'}
		store_data,'mvn_swia_vmon_sweep', data = {x:swihsk.time_unix, y: [[swihsk.vmon_swp],[swihsk.vmon_def1],[swihsk.vmon_def2]], v:[0,1,2], labels: ['SWP','DEF1','DEF2'],labflag:1, ytitle: 'SWIA!cHV SWEEP'}
		store_data,'mvn_swia_voltages', data = {x:swihsk.time_unix, y: [[swihsk.v25d],[swihsk.v5d],[swihsk.v33d],[swihsk.v5a],[swihsk.vn5a],[swihsk.v12],[swihsk.v28]], v:[0,1,2,3,4,5,6], labels: ['2.5d','5d','3.3d','5a','-5a','12','28'],var_label:1, ytitle: 'SWIA!cVoltages'}
		store_data,'mvn_swia_voltages_sub', data = {x:swihsk.time_unix, y: [[swihsk.v25d-2.5],[swihsk.v5d-5],[swihsk.v33d-3.3],[swihsk.v5a-5],[swihsk.vn5a+5],[swihsk.v12-12]], v:[0,1,2,3,4,5], labels: ['2.5d','5d','3.3d','5a','-5a','12'],labflag:1, ytitle: 'SWIA!cOffsets'}
		store_data,'mvn_swia_dighsk', data = {x:swihsk.time_unix,y:[[mvn_swia_subword(swihsk.dighsk,bit1=7,bit2=7)],[mvn_swia_subword(swihsk.dighsk,bit1=3,bit2=3)],[mvn_swia_subword(swihsk.dighsk,bit1=2,bit2=2)]],v:[0,1,2],spec:1,no_interp:1,psym:10, ytitle: 'SWIA!cDigHSK'}
	store_data,'mvn_swia_trates',data = {x:swihsk.time_unix,y:[[swihsk.coarse_options[0]],[swihsk.coarse_options[1]],[swihsk.fine_options[0]],[swihsk.fine_options[1]],[swihsk.mom_options],[swihsk.spec_options]],labels:['CS','CA','FS','FA','MS','SS'],v:[0,1,2,3,4,5],labflag:1,psym:10, ytitle: 'SWIA!cOptions'}
	store_data,'mvn_swia_diagdata',data = {x:swihsk.time_unix,y:[[mvn_swia_subword(swihsk.diagdata,bit1=15,bit2=15)],[mvn_swia_subword(swihsk.diagdata,bit1=14,bit2=12)],[mvn_swia_subword(swihsk.diagdata,bit1=11,bit2=11)],[mvn_swia_subword(swihsk.diagdata,bit1=10,bit2=10)],[mvn_swia_subword(swihsk.diagdata,bit1=9,bit2=0)]],v:[0,1,2,3,4],labels:['slut','diag','enbswp','p1mode','mask'],labflag:1,psym:10, ytitle: 'SWIA!cDiag'}



	endif

	if n_elements(swics) gt 1 then begin

		ctime = swics.time_unix +4.0*swics.num_accum/2	;center time of sample/sum

		espec = transpose(total(total(swics.data,2),2))
		energies = transpose(info_str[swics.info_index].energy_coarse)

		if keyword_set(eflux) then begin
			store_data,'mvn_swics_en_eflux',data = {x:ctime, y: espec, v:energies, ylog:1, zlog:1, spec:1, no_interp:1,yrange:[4,30000],ystyle:1,zrange:[1e5,1e11],ytitle:'Energy (eV)',ztitle:'eV/[eV cm!E2!N s sr]'}, dlimits = {datagap:180}
		endif else begin	
			store_data,'mvn_swics_en_counts',data = {x:ctime, y: espec, v:energies, ylog:1, zlog:1, spec:1, no_interp:1,yrange:[4,30000],ystyle:1,zrange:[10,1e6],ytitle:'Energy (eV)',ztitle:'SWIA!cCounts'}, dlimits = {datagap:180}

			phspec = transpose(total(total(swics.data,1),1))
			phis = transpose(info_str[swics.info_index].phi_coarse)
			for i = 0,n_elements(swics)-1 do begin
				s = sort(phis[i,*])
				phis[i,*] = phis[i,s]
				phspec[i,*] = phspec[i,s]
			endfor
			store_data,'mvn_swics_ph_counts',data = {x:ctime, y: phspec, v:phis, zlog:0, spec:1, no_interp:1, ytitle:'Phi',ztitle:'SWIA!cCounts'}, dlimits = {datagap:180}


			thspec = transpose(total(total(swics.data,3),1))
			thetas = transpose(info_str[swics.info_index].theta_coarse[47,*,*])
			store_data,'mvn_swics_th_counts',data = {x:ctime,y:thspec,v:thetas,zlog:0,spec:1, no_interp:1, ytitle:'Theta',ztitle:'SWIA!cCounts'}, dlimits = {datagap:180}

		endelse
	endif

	if n_elements(swica) gt 1 then begin
		ctime = swica.time_unix +4.0*swica.num_accum/2	;center time of sample/sum

		espec = transpose(total(total(swica.data,2),2))
		energies = transpose(info_str[swica.info_index].energy_coarse)

		if keyword_set(eflux) then begin
			store_data,'mvn_swica_en_eflux',data = {x:ctime, y: espec, v:energies, ylog:1, zlog:1, spec:1, no_interp:1,yrange:[4,30000],ystyle:1,zrange:[1e5,1e11],ytitle:'Energy (eV)',ztitle:'eV/[eV cm!E2!N s sr]'}, dlimits = {datagap:180}
		endif else begin	
			store_data,'mvn_swica_en_counts',data = {x:ctime, y: espec, v:energies, ylog:1, zlog:1, spec:1, no_interp:1,yrange:[4,30000],ystyle:1,zrange:[10,1e6],ytitle:'Energy (eV)',ztitle:'SWIA!cCounts'}, dlimits = {datagap:180}

			phspec = transpose(total(total(swica.data,1),1))
			phis = transpose(info_str[swica.info_index].phi_coarse)
			for i = 0,n_elements(swica)-1 do begin
				s = sort(phis[i,*])
				phis[i,*] = phis[i,s]
				phspec[i,*] = phspec[i,s]
			endfor
			store_data,'mvn_swica_ph_counts',data = {x:ctime, y: phspec, v:phis, zlog:0, spec:1, no_interp:1, ytitle:'Phi',ztitle:'SWIA!cCounts'}, dlimits = {datagap:180}


			thspec = transpose(total(total(swica.data,3),1))
			thetas = transpose(info_str[swica.info_index].theta_coarse[47,*,*])
			store_data,'mvn_swica_th_counts',data = {x:ctime,y:thspec,v:thetas,zlog:0,spec:1, no_interp:1, ytitle:'Theta',ztitle:'SWIA!cCounts'}, dlimits = {datagap:180}

		endelse

	endif

	if n_elements(swifs) gt 1 then begin
		ctime = swifs.time_unix + 2.0				;center time of sample
		nsw = n_elements(swifs)

		espec = transpose(total(total(swifs.data,2),2))
		energy_all = transpose(info_str[swifs.info_index].energy_fine)
		energies = fltarr(nsw,48)
		for i = 0,nsw-1 do energies[i,*] =  energy_all[i,swifs[i].estep_first:swifs[i].estep_first+47]
		if keyword_set(eflux) then begin
			store_data,'mvn_swifs_en_eflux',data = {x:ctime, y:espec, v:energies, ylog:1, zlog:1, spec:1, no_interp:1,yrange:[4,30000],ystyle:1,zrange:[1e5,1e11],ytitle:'Energy (eV)',ztitle:'eV/[eV cm!E2!N s sr]'}, dlimits = {datagap:180}
		endif else begin
			store_data,'mvn_swifs_en_counts',data = {x:ctime, y:espec, v:energies, ylog:1, zlog:1, spec:1, no_interp:1,yrange:[4,30000],ystyle:1,zrange:[10,1e6],ytitle:'Energy (eV)',ztitle:'SWIA!cCounts'}, dlimits = {datagap:180}

			phspec = transpose(total(total(swifs.data,1),1))
			phis = transpose(info_str[swifs.info_index].phi_fine)
			store_data,'mvn_swifs_ph_counts',data = {x:ctime, y:phspec, v:phis, spec:1, no_interp:1, ytitle:'Phi',ztitle:'SWIA!cCounts'}, dlimits = {datagap:180}


			thspec = transpose(total(total(swifs.data,3),1))
			theta_all = transpose(info_str[swifs.info_index].theta_fine[95,*,*])
			thetas = fltarr(nsw,12)
			for i = 0,nsw-1 do thetas[i,*] = theta_all[i,swifs[i].dstep_first:swifs[i].dstep_first+11]
			store_data,'mvn_swifs_th_counts',data = {x:ctime,y: thspec, v: thetas, spec:1, no_interp:1, ytitle:'Theta',ztitle:'SWIA!cCounts'}, dlimits = {datagap:180}
		endelse
	endif

	if n_elements(swifa) gt 1 then begin
		ctime = swifa.time_unix + 2.0				;center time of sample
		nsw = n_elements(swifa)

		espec = transpose(total(total(swifa.data,2),2))
		energy_all = transpose(info_str[swifa.info_index].energy_fine)
		energies = fltarr(nsw,48)
		for i = 0,nsw-1 do energies[i,*] =  energy_all[i,swifa[i].estep_first:swifa[i].estep_first+47]	

		if keyword_set(eflux) then begin
			store_data,'mvn_swifa_en_eflux',data = {x:ctime, y:espec, v:energies, ylog:1, zlog:1, spec:1, no_interp:1,yrange:[4,30000],ystyle:1,zrange:[1e5,1e11],ytitle:'Energy (eV)',ztitle:'eV/[eV cm!E2!N s sr]'}, dlimits = {datagap:180}
		endif else begin
			store_data,'mvn_swifa_en_counts',data = {x:ctime, y:espec, v:energies, ylog:1, zlog:1, spec:1, no_interp:1,yrange:[4,30000],ystyle:1,zrange:[10,1e6],ytitle:'Energy (eV)',ztitle:'SWIA!cCounts'}, dlimits = {datagap:180}

			phspec = transpose(total(total(swifa.data,1),1))
			phis = transpose(info_str[swifa.info_index].phi_fine)
			store_data,'mvn_swifa_ph_counts',data = {x:ctime, y:phspec, v:phis, spec:1, no_interp:1, ytitle:'Phi',ztitle:'SWIA!cCounts'}, dlimits = {datagap:180}


			thspec = transpose(total(total(swifa.data,3),1))
			theta_all = transpose(info_str[swifa.info_index].theta_fine[95,*,*])
			thetas = fltarr(nsw,12)
			for i = 0,nsw-1 do thetas[i,*] = theta_all[i,swifa[i].dstep_first:swifa[i].dstep_first+11]
			store_data,'mvn_swifa_th_counts',data = {x:ctime,y: thspec, v: thetas, spec:1, no_interp:1, ytitle:'Theta',ztitle:'SWIA!cCounts'}, dlimits = {datagap:180}
		endelse

	endif
	
	if n_elements(swim) gt 1 then begin
		w = where(swim.quality_flag ge qlevel and swim.decom_flag ge qlevel)
		ctime = swim[w].time_unix + 2.0				;center time of sample

		store_data,'mvn_swim_density',data = {x:ctime,y:swim[w].density,ytitle:'SWIA!cDensity!c[cm!E-3!N]'}
		store_data,'mvn_swim_velocity',data = {x:ctime,y:transpose(swim[w].velocity),v:[0,1,2],labels:['Vx','Vy','Vz'],labflag:1,ytitle:'SWIA!cVelocity!c[km/s]'}
		store_data,'mvn_swim_velocity_MSO',data = {x:ctime,y:transpose(swim[w].velocity_mso),v:[0,1,2],labels:['Vx','Vy','Vz'],labflag:1,ytitle:'SWIA!cVelocity!c[km/s]'}

		store_data,'mvn_swim_pressure',data = {x:ctime,y:transpose(swim[w].pressure), v:[0,1,2,3,4,5], labels: ['Pxx','Pyy','Pzz','Pxy','Pxz','Pyz'], labflag:1, ytitle: 'SWIA!cPressure!c[eV/cm!E3!N]'}

		store_data, 'mvn_swim_temperature', data = {x:ctime,y:transpose(swim[w].temperature), v:[0,1,2], labels: ['Tx','Ty','Tz'], labflag:1, ytitle: 'SWIA!cTemperature!c[eV]'}
		store_data, 'mvn_swim_temperature_MSO', data = {x:ctime,y:transpose(swim[w].temperature_mso), v:[0,1,2], labels: ['Tx','Ty','Tz'], labflag:1, ytitle: 'SWIA!cTemperature!c[eV]'}

	endif

	if n_elements(swis) gt 1 then begin
		w = where(swis.decom_flag ge qlevel)
		ctime = swis[w].time_unix + 4.0*swis[w].num_accum/2		;center time of sample
		energies = transpose(info_str[swis[w].info_index].energy_coarse)

		if keyword_set(eflux) then begin
			store_data,'mvn_swis_en_eflux',data = {x:ctime,y:transpose(swis[w].data),v:energies, ylog:1, zlog:1, spec:1, no_interp:1, yrange:[4,30000], ystyle:1,zrange:[1e5,1e11],ytitle:'Energy (eV)',ztitle:'eV/[eV cm!E2!N s sr]'}, dlimits = {datagap:180}
		endif else begin
			store_data,'mvn_swis_en_counts',data = {x:ctime,y:transpose(swis[w].data),v:energies, ylog:1, zlog:1, spec:1, no_interp:1, yrange:[4,30000], ystyle:1,zrange:[10,1e6],ytitle:'Energy (eV)',ztitle:'SWIA!cCounts'}, dlimits = {datagap:180}
		endelse
	endif

endif

end