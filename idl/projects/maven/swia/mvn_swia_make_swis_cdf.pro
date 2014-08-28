;+
;PROCEDURE: 
;	MVN_SWIA_MAKE_SWIS_CDF
;PURPOSE: 
;	Routine to produce CDF file from SWIA onboard energy spectra data
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	MVN_SWIA_MAKE_SWIS_CDF, FILE=FILE, DATA_VERSION = DATA_VERSION
;KEYWORDS:
;	FILE: Output file name
;	DATA_VERSION: Data version to put in file (default = '1')
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2014-04-14 14:46:07 -0700 (Mon, 14 Apr 2014) $
; $LastChangedRevision: 14816 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_make_swis_cdf.pro $
;
;-

pro mvn_swia_make_swis_cdf, file = file, data_version = data_version

if not keyword_set(data_version) then data_version = '1'

common mvn_swia_data

if not keyword_set(file) then file = 'test.cdf'

data = swis 
tail = 'svy'

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

varlist = ['Epoch','Time_TT2000','Time_MET','Time_Unix','Atten_State','Num_Accum','Decom_Flag','Spectra_Counts','Spectra_Diff_En_Fluxes','Geom_Factor','De_Over_E_Spectra','Accum_Time_Spectra','Energy_Spectra','Num_Spec']
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


cdf_attput,fileid,'Title',0,'MAVEN SWIA Onboard Energy Spectra'
cdf_attput,fileid,'Project',0,'MAVEN'
cdf_attput,fileid,'Discipline',0,'Planetary Physics>Particles'
cdf_attput,fileid,'Source_name',0,'MAVEN>Mars Atmosphere and Volatile Evolution Mission'
cdf_attput,fileid,'Descriptor',0,'SWIA>Solar Wind Ion Analyzer'
cdf_attput,fileid,'Data_type',0,'CAL>Calibrated'
cdf_attput,fileid,'Data_version',0,data_version
cdf_attput,fileid,'TEXT',0,'MAVEN SWIA Onboard Energy Spectra'
cdf_attput,fileid,'Mods',0,'Revision 0'
cdf_attput,fileid,'Logical_file_id',0,file
cdf_attput,fileid,'Logical_source',0,'SWIA.calibrated.onboard_'+tail+'_spec'
cdf_attput,fileid,'Logical_source_description',0,'DERIVED FROM: MAVEN SWIA (Solar Wind Ion Analyzer), Onboard Energy Spectra'
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



;Number of Accumulations per Sample

varid = cdf_varcreate(fileid, varlist[5], /CDF_INT2, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[5],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'I7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[5],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-32767,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Num_Accum',0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Num_Accum',512,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Num_Accum',0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Num_Accum',512,/ZVARIABLE
cdf_attput,fileid,'CATDESC','Num_Accum','Number of Accumulations Summed',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0','Num_Accum','Epoch',/ZVARIABLE

cdf_varput,fileid,'Num_Accum',data.num_accum


;Decommutation Flag

varid = cdf_varcreate(fileid, varlist[6], /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[6],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[6],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e30,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Decom_Flag',0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Decom_Flag',1,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Decom_Flag',0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Decom_Flag',1,/ZVARIABLE
cdf_attput,fileid,'CATDESC','Decom_Flag','Decommutation Flag: 0 = uncertain mode/attenuator flags, 1 = known mode/attenuator flags',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0','Decom_Flag','Epoch',/ZVARIABLE

cdf_varput,fileid,'Decom_Flag',data.decom_flag



;Counts

dim_vary = 1  
dim = [48]  
varid = cdf_varcreate(fileid, varlist[7],dim_vary, DIM = dim, /REC_VARY,/ZVARIABLE) 
cdf_attput,fileid,'FIELDNAM',varid,varlist[7],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[7],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e30,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Spectra_Counts',0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Spectra_Counts',1e10,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Spectra_Counts',0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Spectra_Counts',1e5,/ZVARIABLE
cdf_attput,fileid,'UNITS','Spectra_Counts','counts',/ZVARIABLE
cdf_attput,fileid,'CATDESC','Spectra_Counts','Raw Instrument Counts',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0','Spectra_Counts','Epoch',/ZVARIABLE

for i = 0,nrec-1 do begin
	if i eq 0 then start = 1 else start = 0
			
	dat = mvn_swia_get_3ds(index = i, start = start)
			
	dat = conv_units(dat,'Counts')

	data[i].data = dat.data

endfor

cdf_varput,fileid,'Spectra_Counts',data.data



;Differential Energy Flux

dim_vary = 1  
dim = [48]  
varid = cdf_varcreate(fileid, varlist[8],dim_vary, DIM = dim, /REC_VARY,/ZVARIABLE) 
cdf_attput,fileid,'FIELDNAM',varid,varlist[8],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[8],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'data',/ZVARIABLE 
cdf_attput,fileid,'FILLVAL',varid,-1.0e30,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Spectra_Diff_En_Fluxes',0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Spectra_Diff_En_Fluxes',1e14,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Spectra_Diff_En_Fluxes',0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Spectra_Diff_En_Fluxes',1e11,/ZVARIABLE
cdf_attput,fileid,'UNITS','Spectra_Diff_En_Fluxes','ev/[eV cm^2 sr s]',/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE','Spectra_Diff_En_Fluxes','data',/ZVARIABLE
cdf_attput,fileid,'CATDESC','Spectra_Diff_En_Fluxes','Calibrated Differential Energy Flux',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0','Spectra_Diff_En_Fluxes','Epoch',/ZVARIABLE

for i = 0,nrec-1 do begin
	if i eq 0 then start = 1 else start = 0
			
	dat = mvn_swia_get_3ds(index = i, start = start)
			
	dat = conv_units(dat,'Eflux')

	data[i].data = dat.data

endfor

cdf_varput,fileid,'Spectra_Diff_En_Fluxes',data.data


;Geometric Factor

varid = cdf_varcreate(fileid, varlist[9], /REC_NOVARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[9],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[9],/ZVARIABLE
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

varid = cdf_varcreate(fileid, varlist[10], /REC_NOVARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[10],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[10],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e30,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','De_Over_E_Spectra',0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','De_Over_E_Spectra',1.0,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','De_Over_E_Spectra',0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','De_Over_E_Spectra',0.2,/ZVARIABLE
cdf_attput,fileid,'UNITS','De_Over_E_Spectra','eV/eV',/ZVARIABLE
cdf_attput,fileid,'CATDESC','De_Over_E_Spectra','Spectra DeltaE/E',/ZVARIABLE

cdf_varput,fileid,'De_Over_E_Spectra',use_info_str.deovere_coarse


;Accumulation Time

varid = cdf_varcreate(fileid, varlist[11], /REC_NOVARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[11],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[11],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e30,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Accum_Time_Spectra',0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Accum_Time_Spectra',1.0,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Accum_Time_Spectra',0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Accum_Time_Spectra',0.1,/ZVARIABLE
cdf_attput,fileid,'UNITS','Accum_Time_Spectra','s',/ZVARIABLE
cdf_attput,fileid,'CATDESC','Accum_Time_Spectra','Spectra Integration Time',/ZVARIABLE

cdf_varput,fileid,'Accum_Time_Spectra',use_info_str.dt_int*12*64


;Energy

dim_vary = [1]
dim = 48

varid = cdf_varcreate(fileid, varlist[12], dim_vary, DIM = dim, /REC_NOVARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[12],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[12],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e30,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Energy_Spectra',0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Energy_Spectra',5e4,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Energy_Spectra',0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Energy_Spectra',3e4,/ZVARIABLE
cdf_attput,fileid,'UNITS','Energy_Spectra','eV',/ZVARIABLE
cdf_attput,fileid,'CATDESC','Energy_Spectra','Spectra Energy Table',/ZVARIABLE

cdf_varput,fileid,'Energy_Spectra',use_info_str.energy_coarse


;Number of Distributions

varid = cdf_varcreate(fileid, varlist[13], /CDF_INT2, /REC_NOVARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[13],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'I7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[13],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-32767,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Num_Spec',0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Num_Spec',21600,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Num_Spec',0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Num_Spec',21600,/ZVARIABLE
cdf_attput,fileid,'CATDESC','Num_Spec','Number of Spectra in File',/ZVARIABLE

cdf_varput,fileid,'Num_Spec',nrec



cdf_close,fileid

end
