;+
;PROCEDURE: 
;	MVN_SWIA_MAKE_SWIM_CDF
;PURPOSE: 
;	Routine to produce CDF file from SWIA onboard moment data
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	MVN_SWIA_MAKE_SWIM_CDF, FILE=FILE, DATA_VERSION = DATA_VERSION
;KEYWORDS:
;	FILE: Output file name
;	DATA_VERSION: Data version to put in file (default = '1')
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2014-04-14 14:46:07 -0700 (Mon, 14 Apr 2014) $
; $LastChangedRevision: 14816 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_make_swim_cdf.pro $
;
;-

pro mvn_swia_make_swim_cdf, file = file, data_version = data_version

if not keyword_set(data_version) then data_version = '1'

;Need to put in real rotation code

common mvn_swia_data

if not keyword_set(file) then file = 'test.cdf'

data = swim
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

varlist = ['Epoch','Time_TT2000','Time_MET','Time_Unix','Atten_State','Telem_Mode','Quality_Flag','Decom_Flag','Density','Pressure','Velocity','Velocity_MSO','Temperature','Temperature_MSO','Num_Mom']
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


cdf_attput,fileid,'Title',0,'MAVEN SWIA Onboard Moments'
cdf_attput,fileid,'Project',0,'MAVEN'
cdf_attput,fileid,'Discipline',0,'Planetary Physics>Particles'
cdf_attput,fileid,'Source_name',0,'MAVEN>Mars Atmosphere and Volatile Evolution Mission'
cdf_attput,fileid,'Descriptor',0,'SWIA>Solar Wind Ion Analyzer'
cdf_attput,fileid,'Data_type',0,'CAL>Calibrated'
cdf_attput,fileid,'Data_version',0,data_version
cdf_attput,fileid,'TEXT',0,'MAVEN SWIA Onboard Moments'
cdf_attput,fileid,'Mods',0,'Revision 0'
cdf_attput,fileid,'Logical_file_id',0,file
cdf_attput,fileid,'Logical_source',0,'SWIA.calibrated.onboard_'+tail+'_mom'
cdf_attput,fileid,'Logical_source_description',0,'DERIVED FROM: MAVEN SWIA (Solar Wind Ion Analyzer), Onboard Moments'
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


;Telemetry Mode

varid = cdf_varcreate(fileid, varlist[5], /CDF_INT1, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[5],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'I7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[5],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-127,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Telem_Mode',0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Telem_Mode',1,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Telem_Mode',0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Telem_Mode',1,/ZVARIABLE
cdf_attput,fileid,'CATDESC','Telem_Mode','Telemetry Mode: 1 = Sheath, 0 = Solar Wind',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0','Telem_Mode','Epoch',/ZVARIABLE

cdf_varput,fileid,'Telem_Mode',data.swi_mode


;Quality Flag

varid = cdf_varcreate(fileid, varlist[6], /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[6],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[6],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e30,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Quality_Flag',0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Quality_Flag',1,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Quality_Flag',0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Quality_Flag',1,/ZVARIABLE
cdf_attput,fileid,'CATDESC','Quality_Flag','Quality Flag: 0 = bad, 1 = good',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0','Quality_Flag','Epoch',/ZVARIABLE

cdf_varput,fileid,'Quality_Flag',data.quality_flag


;Decommutation Flag

varid = cdf_varcreate(fileid, varlist[7], /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[7],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[7],/ZVARIABLE
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


;Density

varid = cdf_varcreate(fileid, varlist[8], /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[8],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[8],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e30,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Density',0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Density',1e6,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Density',0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Density',1e3,/ZVARIABLE
cdf_attput,fileid,'UNITS','Density','cm^-3',/ZVARIABLE
cdf_attput,fileid,'CATDESC','Density','Onboard Density Moment',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0','Density','Epoch',/ZVARIABLE

cdf_varput,fileid,'Density',data.density



;Pressure
dim_vary = [1]
dim = 6

varid = cdf_varcreate(fileid, varlist[9], dim_vary, DIM = dim, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[9],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[9],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e30,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Pressure',-1e6,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Pressure',1e6,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Pressure',-1e5,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Pressure',1e5,/ZVARIABLE
cdf_attput,fileid,'UNITS','Pressure','eV/cm^-3',/ZVARIABLE
cdf_attput,fileid,'CATDESC','Pressure','Onboard Pressure Moment (Inst. Coords)',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0','Pressure','Epoch',/ZVARIABLE

cdf_varput,fileid,'Pressure',data.pressure



;Velocity (Inst)
dim_vary = [1]
dim = 3

varid = cdf_varcreate(fileid, varlist[10], dim_vary, DIM = dim, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[10],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[10],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e30,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Velocity',-1e10,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Velocity',1e10,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Velocity',-1e3,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Velocity',1e3,/ZVARIABLE
cdf_attput,fileid,'UNITS','Velocity','km/s',/ZVARIABLE
cdf_attput,fileid,'CATDESC','Velocity','Onboard Velocity Moment (Inst. Coords)',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0','Velocity','Epoch',/ZVARIABLE

cdf_varput,fileid,'Velocity',data.velocity


;Velocity (MSO)

dim_vary = [1]
dim = 3

varid = cdf_varcreate(fileid, varlist[11], dim_vary, DIM = dim, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[11],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[11],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e30,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Velocity_MSO',-1e10,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Velocity_MSO',1e10,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Velocity_MSO',-1e3,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Velocity_MSO',1e3,/ZVARIABLE
cdf_attput,fileid,'UNITS','Velocity_MSO','km/s',/ZVARIABLE
cdf_attput,fileid,'CATDESC','Velocity_MSO','Onboard Velocity Moment (MSO Coords)',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0','Velocity_MSO','Epoch',/ZVARIABLE

get_data,'mvn_swim_velocity_mso',data = vmso
cdf_varput,fileid,'Velocity_MSO',transpose(vmso.y[*,0:2])    ; FIX ME, put in real rotation code here




;Temperature (Inst)
dim_vary = [1]
dim = 3

varid = cdf_varcreate(fileid, varlist[12], dim_vary, DIM = dim, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[12],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[12],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e30,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Temperature',0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Temperature',1e6,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Temperature',0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Temperature',1e3,/ZVARIABLE
cdf_attput,fileid,'UNITS','Temperature','eV',/ZVARIABLE
cdf_attput,fileid,'CATDESC','Temperature','Onboard Temperature Moment (Inst. Coords)',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0','Temperature','Epoch',/ZVARIABLE

cdf_varput,fileid,'Temperature',data.temperature


;Temperature (MSO)

dim_vary = [1]
dim = 3

varid = cdf_varcreate(fileid, varlist[13], dim_vary, DIM = dim, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[13],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[13],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e30,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Temperature_MSO',0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Temperature_MSO',1e6,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Temperature_MSO',0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Temperature_MSO',1e3,/ZVARIABLE
cdf_attput,fileid,'UNITS','Temperature_MSO','eV',/ZVARIABLE
cdf_attput,fileid,'CATDESC','Temperature_MSO','Onboard Temperature Moment (MSO Coords)',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0','Temperature_MSO','Epoch',/ZVARIABLE

get_data,'mvn_swim_temperature_mso',data = tmso
cdf_varput,fileid,'Temperature_MSO',transpose(tmso.y[*,0:2])    ; FIX ME, put in real rotation code here


;Number of Moments 

varid = cdf_varcreate(fileid, varlist[14], /CDF_INT2, /REC_NOVARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[14],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'I7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[14],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-32767,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Num_Mom',0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Num_Mom',21600,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Num_Mom',0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Num_Mom',21600,/ZVARIABLE
cdf_attput,fileid,'CATDESC','Num_Mom','Number of Moment Sets in File',/ZVARIABLE

cdf_varput,fileid,'Num_Mom',nrec






cdf_close,fileid

end
