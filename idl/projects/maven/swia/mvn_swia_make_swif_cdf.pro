;+
;PROCEDURE: 
;	MVN_SWIA_MAKE_SWIF_CDF
;PURPOSE: 
;	Routine to produce CDF file from SWIA fine survey or archive data
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	MVN_SWIA_MAKE_SWIF_CDF, FILE=FILE, /ARCHIVE, DATA_VERSION = DATA_VERSION
;KEYWORDS:
;	FILE: Output file name
;	ARCHIVE: If set, produce a file with archive data rather than survey (default)
;	DATA_VERSION: Data version to put in file (default = '1')
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2014-04-11 13:44:44 -0700 (Fri, 11 Apr 2014) $
; $LastChangedRevision: 14812 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_make_swif_cdf.pro $
;
;-

pro mvn_swia_make_swif_cdf, file = file, archive = archive, data_version = data_version

if not keyword_set(data_version) then data_version = '1'

common mvn_swia_data

if not keyword_set(file) then file = 'test.cdf'

if keyword_set(archive) then begin
	data = swifa 
	tail = 'arc'
endif else begin
	data = swifs
	tail = 'svy'
endelse

;FIXME - Need to consider case where parameters change during the day being processed (probably split files)

info = data[0].info_index
use_info_str = info_str[info]

nrec = n_elements(data)

cdf_leap_second_init

date_range = time_double(['2013-11-18/00:00','2030-12-31/23:59'])
met_range = date_range - time_double('2000-01-01/12:00')
epoch_range = time_epoch(date_range)
tt2000_range = long64((add_tt2000_offset(date_range)-time_double('2000-01-01/12:00'))*1e9)


epoch = time_epoch(data.time_unix)
timett2000 = long64((add_tt2000_offset(data.time_unix)-time_double('2000-01-01/12:00'))*1e9)

fileid = cdf_create(file,/single_file,/network_encoding,/clobber)

varlist = ['Epoch','Time_TT2000','Time_MET','Time_Unix','Atten_State','Grouping','Estep_First','Dstep_First','Counts','Diff_En_Fluxes','Geom_Factor','De_Over_E_Fine','Accum_Time_Fine','Energy_Fine','Theta_Fine','Theta_Atten_Fine','G_Theta_Fine','G_Theta_Atten_Fine','Phi_Fine','G_Phi_Fine','G_Phi_Atten_Fine','Num_Dists']
nvars = n_elements(varlist)


id0 = cdf_attcreate(fileid,'Title',/global_scope)
id1 = cdf_attcreate(fileid,'Project',/global_scope)
id2 = cdf_attcreate(fileid,'Discipline',/global_scope)
id3 = cdf_attcreate(fileid,'Source_name',/global_scope)
id4 = cdf_attcreate(fileid,'Descriptor',/global_scope)
id5 = cdf_attcreate(fileid,'Data_type',/global_scope)
id6 = cdf_attcreate(fileid,'Data_version',/global_scope)
id7 = cdf_attcreate(fileid,'TEXT',/global_scope)
id8 = cdf_attcreate(fileid,'Mods',/global_scope)
id9 = cdf_attcreate(fileid,'Logical_file_id',/global_scope)
id10 = cdf_attcreate(fileid,'Logical_source',/global_scope)
id11 = cdf_attcreate(fileid,'Logical_source_description',/global_scope)
id12 = cdf_attcreate(fileid,'PI_name',/global_scope)
id13 = cdf_attcreate(fileid,'PI_affiliation',/global_scope)
id14 = cdf_attcreate(fileid,'Instrument_type',/global_scope)
id15 = cdf_attcreate(fileid,'Mission_group',/global_scope)
id16 = cdf_attcreate(fileid,'Parents',/global_scope)


cdf_attput,fileid,'Title',0,'MAVEN SWIA Fine 3d Distributions'
cdf_attput,fileid,'Project',0,'MAVEN'
cdf_attput,fileid,'Discipline',0,'Planetary Physics>Particles'
cdf_attput,fileid,'Source_name',0,'MAVEN>Mars Atmosphere and Volatile Evolution Mission'
cdf_attput,fileid,'Descriptor',0,'SWIA>Solar Wind Ion Analyzer'
cdf_attput,fileid,'Data_type',0,'CAL>Calibrated'
cdf_attput,fileid,'Data_version',0,data_version
cdf_attput,fileid,'TEXT',0,'MAVEN SWIA Fine 3d Distributions'
cdf_attput,fileid,'Mods',0,'Revision 0'
cdf_attput,fileid,'Logical_file_id',0,file
cdf_attput,fileid,'Logical_source',0,'SWIA.calibrated.fine_'+tail+'_3d'
cdf_attput,fileid,'Logical_source_description',0,'DERIVED FROM: MAVEN SWIA (Solar Wind Ion Analyzer), Fine 3d Distributions'
cdf_attput,fileid,'PI_name',0,'J.S. Halekas'
cdf_attput,fileid,'PI_affiliation',0,'U.C. Berkeley Space Sciences Laboratory'
cdf_attput,fileid,'Instrument_type',0,'Plasma and Solar Wind'
cdf_attput,fileid,'Mission_group',0,'MAVEN'
cdf_attput,fileid,'Parents',0,'None'


dummy = cdf_attcreate(fileid,'FIELDNAM',/variable_scope)
dummy = cdf_attcreate(fileid,'MONOTON',/variable_scope)
dummy = cdf_attcreate(fileid,'FORMAT',/variable_scope)
dummy = cdf_attcreate(fileid,'FORM_PTR',/variable_scope)
dummy = cdf_attcreate(fileid,'LABLAXIS',/variable_scope)
dummy = cdf_attcreate(fileid,'VAR_TYPE',/variable_scope)
dummy = cdf_attcreate(fileid,'FILLVAL',/variable_scope)
dummy = cdf_attcreate(fileid,'DEPEND_0',/variable_scope)
dummy = cdf_attcreate(fileid,'DISPLAY_TYPE',/variable_scope)
dummy = cdf_attcreate(fileid,'VALIDMIN',/variable_scope)
dummy = cdf_attcreate(fileid,'VALIDMAX',/variable_scope)
dummy = cdf_attcreate(fileid,'SCALEMIN',/variable_scope)
dummy = cdf_attcreate(fileid,'SCALEMAX',/variable_scope)
dummy = cdf_attcreate(fileid,'UNITS',/variable_scope)
dummy = cdf_attcreate(fileid,'CATDESC',/variable_scope)


;Epoch

varid = cdf_varcreate(fileid, varlist[0], /CDF_EPOCH, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[0],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F25.16',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[0],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,0.0,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Epoch',epoch_range[0],/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Epoch',epoch_range[1],/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Epoch',epoch[0],/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Epoch',epoch[nrec-1],/ZVARIABLE
cdf_attput,fileid,'UNITS','Epoch','ms',/ZVARIABLE
cdf_attput,fileid,'MONOTON','Epoch','INCREASE',/ZVARIABLE
cdf_attput,fileid,'CATDESC','Epoch','Time, start of sample, in NSSDC Epoch',/ZVARIABLE

cdf_varput,fileid,'Epoch',epoch


;TT2000

varid = cdf_varcreate(fileid, varlist[1], /CDF_TIME_TT2000, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[1],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'I22',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[1],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-9223372036854775807,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Time_TT2000',tt2000_range[0],/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Time_TT2000',tt2000_range[1],/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Time_TT2000',timett2000[0],/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Time_TT2000',timett2000[nrec-1],/ZVARIABLE
cdf_attput,fileid,'UNITS','Time_TT2000','ns',/ZVARIABLE
cdf_attput,fileid,'MONOTON','Time_TT2000','INCREASE',/ZVARIABLE
cdf_attput,fileid,'CATDESC','Time_TT2000','Time, start of sample, in TT2000 time base',/ZVARIABLE

cdf_varput,fileid,'Time_TT2000',timett2000


;MET

varid = cdf_varcreate(fileid, varlist[2], /CDF_DOUBLE, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[2],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F25.6',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[2],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e30,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Time_MET',met_range[0],/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Time_MET',met_range[1],/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Time_MET',data[0].time_met,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Time_MET',data[nrec-1].time_met,/ZVARIABLE
cdf_attput,fileid,'UNITS','Time_MET','s',/ZVARIABLE
cdf_attput,fileid,'MONOTON','Time_MET','INCREASE',/ZVARIABLE
cdf_attput,fileid,'CATDESC','Time_MET','Time, start of sample, in raw mission elapsed time',/ZVARIABLE

cdf_varput,fileid,'Time_MET',data.time_met


;Unix Time

varid = cdf_varcreate(fileid, varlist[3], /CDF_DOUBLE, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[3],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F25.6',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[3],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e30,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Time_Unix',date_range[0],/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Time_Unix',date_range[1],/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Time_Unix',data[0].time_unix,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Time_Unix',data[nrec-1].time_unix,/ZVARIABLE
cdf_attput,fileid,'UNITS','Time_Unix','s',/ZVARIABLE
cdf_attput,fileid,'MONOTON','Time_Unix','INCREASE',/ZVARIABLE
cdf_attput,fileid,'CATDESC','Time_Unix','Time, start of sample, in Unix time',/ZVARIABLE

cdf_varput,fileid,'Time_Unix',data.time_unix


;Attenuator State

varid = cdf_varcreate(fileid, varlist[4], /CDF_INT1, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[4],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'I7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[4],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-127,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Atten_State',1,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Atten_State',3,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Atten_State',1,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Atten_State',3,/ZVARIABLE
cdf_attput,fileid,'CATDESC','Atten_State','Attenuator state, 1 = open, 2 = closed, 3 = cover closed',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0','Atten_State','Epoch',/ZVARIABLE

cdf_varput,fileid,'Atten_State',data.atten_state



;Grouping

varid = cdf_varcreate(fileid, varlist[5], /CDF_INT1, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[5],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'I7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[5],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-127,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Grouping',0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Grouping',2,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Grouping',0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Grouping',2,/ZVARIABLE
cdf_attput,fileid,'CATDESC','Grouping','Data Coverage Flag: 0 = 48E x 12D x 10A, 1 = 32E x 8D x 6A',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0','Grouping','Epoch',/ZVARIABLE

cdf_varput,fileid,'Grouping',data.grouping


;Starting Energy Step

varid = cdf_varcreate(fileid, varlist[6], /CDF_INT1, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[6],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'I7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[6],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-127,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Estep_First',0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Estep_First',47,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Estep_First',0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Estep_First',47,/ZVARIABLE
cdf_attput,fileid,'CATDESC','Estep_First','Starting Energy Step',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0','Estep_First','Epoch',/ZVARIABLE

cdf_varput,fileid,'Estep_First',data.estep_first


;Starting Deflector Step

varid = cdf_varcreate(fileid, varlist[7], /CDF_INT1, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[7],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'I7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[7],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-127,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Dstep_First',0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Dstep_First',23,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Dstep_First',0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Dstep_First',23,/ZVARIABLE
cdf_attput,fileid,'CATDESC','Dstep_First','Starting Deflection Step',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0','Dstep_First','Epoch',/ZVARIABLE

cdf_varput,fileid,'Dstep_First',data.dstep_first


;Counts

dim_vary = [1,1,1]  
dim = [48,12,10]  
varid = cdf_varcreate(fileid, varlist[8],dim_vary, DIM = dim, /REC_VARY,/ZVARIABLE) 
cdf_attput,fileid,'FIELDNAM',varid,varlist[8],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[8],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e30,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Counts',0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Counts',1e10,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Counts',0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Counts',1e5,/ZVARIABLE
cdf_attput,fileid,'UNITS','Counts','counts',/ZVARIABLE
cdf_attput,fileid,'CATDESC','Counts','Raw Instrument Counts',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0','Counts','Epoch',/ZVARIABLE

for i = 0,nrec-1 do begin
	if i eq 0 then start = 1 else start = 0
			
	dat = mvn_swia_get_3df(index = i, start = start, archive = archive)
			
	dat = conv_units(dat,'Counts')

	data[i].data = reform(dat.data,48,12,10)

endfor

cdf_varput,fileid,'Counts',data.data



;Differential Energy Flux

dim_vary = [1,1,1]  
dim = [48,12,10]  
varid = cdf_varcreate(fileid, varlist[9],dim_vary, DIM = dim, /REC_VARY,/ZVARIABLE) 
cdf_attput,fileid,'FIELDNAM',varid,varlist[9],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[9],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'data',/ZVARIABLE 
cdf_attput,fileid,'FILLVAL',varid,-1.0e30,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Diff_En_Fluxes',0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Diff_En_Fluxes',1e14,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Diff_En_Fluxes',0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Diff_En_Fluxes',1e11,/ZVARIABLE
cdf_attput,fileid,'UNITS','Diff_En_Fluxes','ev/[eV cm^2 sr s]',/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE','Diff_En_Fluxes','data',/ZVARIABLE
cdf_attput,fileid,'CATDESC','Diff_En_Fluxes','Calibrated Differential Energy Flux',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0','Diff_En_Fluxes','Epoch',/ZVARIABLE

for i = 0,nrec-1 do begin
	if i eq 0 then start = 1 else start = 0
			
	dat = mvn_swia_get_3df(index = i, start = start, archive = archive)
			
	dat = conv_units(dat,'Eflux')

	data[i].data = reform(dat.data,48,12,10)

endfor

cdf_varput,fileid,'Diff_En_Fluxes',data.data


;Geometric Factor

varid = cdf_varcreate(fileid, varlist[10], /REC_NOVARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[10],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[10],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e30,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Geom_Factor',0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Geom_Factor',1.0,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Geom_Factor',0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Geom_Factor',1e-2,/ZVARIABLE
cdf_attput,fileid,'UNITS','Geom_Factor','cm^2 sr eV/eV',/ZVARIABLE
cdf_attput,fileid,'CATDESC','Geom_Factor','Full Analyzer Geometric Factor',/ZVARIABLE

cdf_varput,fileid,'Geom_Factor',use_info_str.geom


;DE/E

varid = cdf_varcreate(fileid, varlist[11], /REC_NOVARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[11],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[11],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e30,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','De_Over_E_Fine',0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','De_Over_E_Fine',1.0,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','De_Over_E_Fine',0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','De_Over_E_Fine',0.2,/ZVARIABLE
cdf_attput,fileid,'UNITS','De_Over_E_Fine','eV/eV',/ZVARIABLE
cdf_attput,fileid,'CATDESC','De_Over_E_Fine','Fine DeltaE/E',/ZVARIABLE

cdf_varput,fileid,'De_Over_E_Fine',use_info_str.deovere_fine



;Accumulation Time

varid = cdf_varcreate(fileid, varlist[12], /REC_NOVARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[12],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[12],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e30,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Accum_Time_Fine',0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Accum_Time_Fine',1.0,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Accum_Time_Fine',0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Accum_Time_Fine',0.1,/ZVARIABLE
cdf_attput,fileid,'UNITS','Accum_Time_Fine','s',/ZVARIABLE
cdf_attput,fileid,'CATDESC','Accum_Time_Fine','Fine Integration Time',/ZVARIABLE

cdf_varput,fileid,'Accum_Time_Fine',use_info_str.dt_int



;Energy

dim_vary = [1]
dim = 96

varid = cdf_varcreate(fileid, varlist[13], dim_vary, DIM = dim, /REC_NOVARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[13],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[13],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e30,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Energy_Fine',0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Energy_Fine',5e4,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Energy_Fine',0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Energy_Fine',3e4,/ZVARIABLE
cdf_attput,fileid,'UNITS','Energy_Fine','eV',/ZVARIABLE
cdf_attput,fileid,'CATDESC','Energy_Fine','Fine Energy Table',/ZVARIABLE

cdf_varput,fileid,'Energy_Fine',use_info_str.energy_fine


;Theta

dim_vary = [1,1]
dim = [96,24]

varid = cdf_varcreate(fileid, varlist[14], dim_vary, DIM = dim, /REC_NOVARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[14],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[14],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e30,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Theta_Fine',-180,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Theta_Fine',180,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Theta_Fine',-45,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Theta_Fine',45,/ZVARIABLE
cdf_attput,fileid,'UNITS','Theta_Fine','degrees',/ZVARIABLE
cdf_attput,fileid,'CATDESC','Theta_Fine','Fine Deflection Angle (Theta) Table for Attenuator Open',/ZVARIABLE

cdf_varput,fileid,'Theta_Fine',use_info_str.theta_fine


;Theta Atten

dim_vary = [1,1]
dim = [96,24]

varid = cdf_varcreate(fileid, varlist[15], dim_vary, DIM = dim, /REC_NOVARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[15],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[15],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e30,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Theta_Atten_Fine',-180,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Theta_Atten_Fine',180,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Theta_Atten_Fine',-45,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Theta_Atten_Fine',45,/ZVARIABLE
cdf_attput,fileid,'UNITS','Theta_Atten_Fine','degrees',/ZVARIABLE
cdf_attput,fileid,'CATDESC','Theta_Atten_Fine','Fine Deflection Angle (Theta) Table for Attenuator Closed',/ZVARIABLE

cdf_varput,fileid,'Theta_Atten_Fine',use_info_str.theta_fine_atten


;G Theta

dim_vary = [1,1]
dim = [96,24]

varid = cdf_varcreate(fileid, varlist[16], dim_vary, DIM = dim, /REC_NOVARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[16],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[16],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e30,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','G_Theta_Fine',0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','G_Theta_Fine',1,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','G_Theta_Fine',0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','G_Theta_Fine',1,/ZVARIABLE
cdf_attput,fileid,'CATDESC','G_Theta_Fine','Fine Relative Sensitivity Table for Attenuator Open',/ZVARIABLE

cdf_varput,fileid,'G_Theta_Fine',use_info_str.g_th_fine


;G Theta Atten

dim_vary = [1,1]
dim = [96,24]

varid = cdf_varcreate(fileid, varlist[17], dim_vary, DIM = dim, /REC_NOVARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[17],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[17],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e30,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','G_Theta_Atten_Fine',0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','G_Theta_Atten_Fine',1,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','G_Theta_Atten_Fine',0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','G_Theta_Atten_Fine',1,/ZVARIABLE
cdf_attput,fileid,'CATDESC','G_Theta_Atten_Fine','Fine Relative Sensitivity Table for Attenuator Closed',/ZVARIABLE

cdf_varput,fileid,'G_Theta_Atten_Fine',use_info_str.g_th_fine_atten


;Phi

dim_vary = [1]
dim = 10

varid = cdf_varcreate(fileid, varlist[18], dim_vary, DIM = dim, /REC_NOVARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[18],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[18],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e30,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Phi_Fine',0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Phi_Fine',360,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Phi_Fine',0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Phi_Fine',360,/ZVARIABLE
cdf_attput,fileid,'UNITS','Phi_Fine','degrees',/ZVARIABLE
cdf_attput,fileid,'CATDESC','Phi_Fine','Fine Anode Angle (Phi) Table',/ZVARIABLE

cdf_varput,fileid,'Phi_Fine',use_info_str.phi_fine


;G Phi

dim_vary = [1]
dim = 10

varid = cdf_varcreate(fileid, varlist[19], dim_vary, DIM = dim, /REC_NOVARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[19],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[19],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e30,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','G_Phi_Fine',0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','G_Phi_Fine',1,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','G_Phi_Fine',0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','G_Phi_Fine',1,/ZVARIABLE
cdf_attput,fileid,'CATDESC','G_Phi_Fine','Fine Relative Sensitivity Table for Attenuator Open',/ZVARIABLE

cdf_varput,fileid,'G_Phi_Fine',use_info_str.geom_fine


;G Phi Atten

dim_vary = [1]
dim = 10

varid = cdf_varcreate(fileid, varlist[20], dim_vary, DIM = dim, /REC_NOVARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[20],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[20],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e30,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','G_Phi_Atten_Fine',0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','G_Phi_Atten_Fine',1,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','G_Phi_Atten_Fine',0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','G_Phi_Atten_Fine',1,/ZVARIABLE
cdf_attput,fileid,'CATDESC','G_Phi_Atten_Fine','Fine Relative Sensitivity Table for Attenuator Closed',/ZVARIABLE

cdf_varput,fileid,'G_Phi_Atten_Fine',use_info_str.geom_fine_atten


;Number of Distributions

varid = cdf_varcreate(fileid, varlist[21], /CDF_INT2, /REC_NOVARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[21],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'I7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[21],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-32767,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Num_Dists',0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Num_Dists',21600,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Num_Dists',0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Num_Dists',21600,/ZVARIABLE
cdf_attput,fileid,'CATDESC','Num_Dists','Number of Fine Distributions in File',/ZVARIABLE

cdf_varput,fileid,'Num_Dists',nrec



cdf_close,fileid

end
