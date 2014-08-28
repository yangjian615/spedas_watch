
;+
;NAME: MVN_SEP_SW_VERSION
;Function: mvn_spice_kernels(name)
;PURPOSE:
; Acts as a timestamp file to trigger the regeneration of SEP data products. Also provides Software Version info for the MAVEN SEP instrument.  
;Author: Davin Larson  - January 2014
; $LastChangedBy: rlillis2 $
; $LastChangedDate: 2014-06-17 10:21:22 -0700 (Tue, 17 Jun 2014) $
; $LastChangedRevision: 15387 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sep/mvn_sep_anc_make_cdf.pro $
;-
function mvn_sep_anc_sw_version

tb = scope_traceback(/structure)
this_file = tb[n_elements(tb)-1].filename   
this_file_date = (file_info(this_file)).mtime

sw_structure = {  $
  sw_version : 'v01' , $
  sw_time_stamp_file : this_file , $
  sw_time_stamp : time_string(this_file_date) , $
  sw_runtime : time_string(systime(1))  , $
  sw_runby :  getenv('LOGNAME') , $
  svn_changedby : '$LastChangedBy: rlillis2 $' , $
  svn_changedate: '$LastChangedDate: 2014-06-17 10:21:22 -0700 (Tue, 17 Jun 2014) $' , $
  svn_revision : '$LastChangedRevision: 15387 $' }
return,sw_structure
end





;
;
;
;+
;PROCEDURE: 
;	MVN_SEP_ANC_MAKE_CDF
;PURPOSE: 
;	Routine to produce ancillary and ephemeris data files
;AUTHOR: 
;	Robert Lillis (rlillis@ssl.Berkeley.edu)
;CALLING SEQUENCE:
;	MVN_SEP_MAKE_L2_ANC_CDF, 
;KEYWORDS:
;	FILE: Output file name
;
; $LastChangedBy: rlillis2 $
; $LastChangedDate: 2014-06-17 10:21:22 -0700 (Tue, 17 Jun 2014) $
; $LastChangedRevision: 15387 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sep/mvn_sep_anc_make_cdf.pro $


pro mvn_sep_anc_make_cdf, sep_ancillary,dependencies=dependencies, file = file, data_version = data_version

;  global_attribute_names = global_attribute_names,  global_attribute_values = global_attribute_values

if not keyword_set(data_version) then data_version = '1'
if not keyword_set(dependencies) then dependencies = 'None'

if not keyword_set(file) then file = 'test.cdf'

cdf_leap_second_init

date_range = time_double(['2013-11-18/00:00','2030-12-31/23:59'])

met_range = [0, 100.0d*86400.0*365]

met = mvn_spc_unixtime_to_met(SEP_ancillary.time_UNIX,correct_clockdrift=1)

;date_range - time_double('2000-01-01/12:00')
epoch_range = time_epoch(date_range)
tt2000_range = long64((add_tt2000_offset(date_range)-time_double('2000-01-01/12:00'))*1e9)


epoch = time_epoch(sep_ancillary.time_UNIX)
timett2000 = long64((add_tt2000_offset(sep_ancillary.time_UNIX)-time_double('2000-01-01/12:00'))*1e9)

fileid = cdf_create(file,/single_file,/network_encoding,/clobber)

nrec = n_elements (SEP_ancillary.time_UNIX)

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
idxx = cdf_attcreate(fileid,'Parents',/global_scope)
extra = mvn_sep_anc_sw_version()
if keyword_set(extra) then exnames = tag_names(extra)
for i=0,n_elements(exnames)-1 do  idxx = cdf_attcreate(fileid,exnames[i],/global_scope)


cdf_attput,fileid,'Title',0,'MAVEN SEP Ancillary and Ephemeris Data'
cdf_attput,fileid,'Project',0,'MAVEN'
cdf_attput,fileid,'Discipline',0,'Planetary Space Physics>Particles'
cdf_attput,fileid,'Source_name',0,'MAVEN>Mars Atmosphere and Volatile Evolution Mission'
cdf_attput,fileid,'Descriptor',0,'SEP>Solar Energetic Particle Experiment'
cdf_attput,fileid,'Data_type',0,'Support data'
cdf_attput,fileid,'Data_version',0,data_version
cdf_attput,fileid,'TEXT',0,'MAVEN SEP ancillary and ephemeris data'
cdf_attput,fileid,'Mods',0,'Revision 0'
cdf_attput,fileid,'Logical_file_id',0,file
cdf_attput,fileid,'Logical_source',0,'SEP.ancillary'
cdf_attput,fileid,'Logical_source_description',0,'SEP ancillary and ephemeris data'
     
cdf_attput,fileid,'PI_name',0,'Davin Larson (davin@ssl.berkeley.edu)'
cdf_attput,fileid,'PI_affiliation',0,'U.C. Berkeley Space Sciences Laboratory'
cdf_attput,fileid,'Instrument_type',0,'Energetic Particle Detector'
cdf_attput,fileid,'Mission_group',0,'MAVEN'
for i=0,n_elements(dependencies)-1 do begin
   str = file_hash(dependencies[i],/add_mtime)
   cdf_attput,fileid,'Parents',i,str[0]
endfor

for  i=0,n_elements(exnames)-1 do cdf_attput,fileid,exnames[i],0,extra.(i)



;Variable Attributes

dummy = cdf_attcreate(fileid,'FIELDNAM',/variable_scope)
dummy = cdf_attcreate(fileid,'MONOTON',/variable_scope)
dummy = cdf_attcreate(fileid,'FORMAT',/variable_scope)
dummy = cdf_attcreate(fileid,'FORM_PTR',/variable_scope)
dummy = cdf_attcreate(fileid,'LABLAXIS',/variable_scope)
dummy = cdf_attcreate(fileid,'VAR_TYPE',/variable_scope)
dummy = cdf_attcreate(fileid,'FILLVAL',/variable_scope)
dummy = cdf_attcreate(fileid,'DEPEND_0',/variable_scope)
dummy = cdf_attcreate(fileid,'DEPEND_TIME',/variable_scope)
dummy = cdf_attcreate(fileid,'DEPEND_1',/variable_scope)
dummy = cdf_attcreate(fileid,'DEPEND_2',/variable_scope)
dummy = cdf_attcreate(fileid,'DISPLAY_TYPE',/variable_scope)
dummy = cdf_attcreate(fileid,'VALIDMIN',/variable_scope)
dummy = cdf_attcreate(fileid,'VALIDMAX',/variable_scope)
dummy = cdf_attcreate(fileid,'SCALEMIN',/variable_scope)
dummy = cdf_attcreate(fileid,'SCALEMAX',/variable_scope)
dummy = cdf_attcreate(fileid,'UNITS',/variable_scope)
dummy = cdf_attcreate(fileid,'CATDESC',/variable_scope)


;Unix Time

name = 'TIME_UNIX'
varid = cdf_varcreate(fileid, name, /CDF_DOUBLE, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,name,/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.3',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,name,/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,sqrt(-7.3),/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','TIME_UNIX',date_range[0],/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','TIME_UNIX',date_range[1],/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','TIME_UNIX',sep_ancillary[0].time_UNIX,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','TIME_UNIX',sep_ancillary[nrec-1].time_UNIX,/ZVARIABLE
cdf_attput,fileid,'UNITS','TIME_UNIX','s',/ZVARIABLE
cdf_attput,fileid,'MONOTON','TIME_UNIX','INCREASE',/ZVARIABLE
cdf_attput,fileid,'CATDESC','TIME_UNIX','Time, middle of sample, in Unix time',/ZVARIABLE

cdf_varput,fileid,'TIME_UNIX',sep_ancillary.time_UNIX


;EPOCH

name = 'EPOCH'
varid = cdf_varcreate(fileid, name, /CDF_EPOCH, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,name,/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.3',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,name,/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,!values.d_nan,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','EPOCH',epoch_range[0],/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','EPOCH',epoch_range[1],/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','EPOCH',epoch[0],/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','EPOCH',epoch[nrec-1],/ZVARIABLE
cdf_attput,fileid,'UNITS','EPOCH','ms',/ZVARIABLE
cdf_attput,fileid,'MONOTON','EPOCH','INCREASE',/ZVARIABLE
cdf_attput,fileid,'CATDESC','EPOCH','Time, middle of sample, in NSSDC EPOCH',/ZVARIABLE

cdf_varput,fileid,'EPOCH',epoch


;TT2000
name ='TIME_TT2000'
varid = cdf_varcreate(fileid, name, /CDF_TIME_TT2000, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,name,/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'I22',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,name,/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-9223372036854775807,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN',varid,tt2000_range[0],/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','TIME_TT2000',tt2000_range[1],/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','TIME_TT2000',timett2000[0],/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','TIME_TT2000',timett2000[nrec-1],/ZVARIABLE
cdf_attput,fileid,'UNITS','TIME_TT2000','ns',/ZVARIABLE
cdf_attput,fileid,'MONOTON','TIME_TT2000','INCREASE',/ZVARIABLE
cdf_attput,fileid,'CATDESC','TIME_TT2000','Time, middle of sample, in TT2000 time base',/ZVARIABLE

cdf_varput,fileid,'TIME_TT2000',timett2000


;MET
name = 'TIME_MET'
varid = cdf_varcreate(fileid, name, /CDF_DOUBLE, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,name,/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.3',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,name,/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,sqrt(-7.3),/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN',varid,met_range[0],/ZVARIABLE
cdf_attput,fileid,'VALIDMAX',varid,met_range[1],/ZVARIABLE
cdf_attput,fileid,'SCALEMIN',varid,met[0],/ZVARIABLE
cdf_attput,fileid,'SCALEMAX',varid,met[nrec-1],/ZVARIABLE
cdf_attput,fileid,'UNITS',varid,'s',/ZVARIABLE
cdf_attput,fileid,'MONOTON',varid,'INCREASE',/ZVARIABLE
cdf_attput,fileid,'CATDESC',varid,'Time, middle of sample, in raw mission elapsed time',/ZVARIABLE

cdf_varput,fileid,name,met

;Ephemeris time
name = 'TIME_EPHEMERIS'
varid = cdf_varcreate(fileid, name, /CDF_DOUBLE, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,name,/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.3',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,name,/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,sqrt(-7.3),/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN',name,met_range[0],/ZVARIABLE
cdf_attput,fileid,'VALIDMAX',name,met_range[1],/ZVARIABLE
cdf_attput,fileid,'SCALEMIN',name,met[0],/ZVARIABLE
cdf_attput,fileid,'SCALEMAX',name,met[nrec-1],/ZVARIABLE
cdf_attput,fileid,'UNITS',name,'s',/ZVARIABLE
cdf_attput,fileid,'MONOTON',name,'INCREASE',/ZVARIABLE
cdf_attput,fileid,'CATDESC',name,'Time, middle of sample, in ephemeris time (used by SPICE)',/ZVARIABLE

cdf_varput,fileid,name,SEP_ancillary.time_ephemeris


;Look directions. 

dim_vary = [1]  
dim = [3]  
numdir = ['1F','1R', '2F', '2R']
coord = ['MSO', 'SSO', 'GEO']
direction = ['1-Forward', '1-Reverse', '2-Forward', '2-Reverse']
names = ('SEP-' + replicate_array (numdir, 3) + '_FOV_')+ replicate_array (coord, 4,/Before)
coordinate_descriptions = ['Mars-solar-orbital', 'spacecraft-solar-orbital', 'IAU Mars']
for J = 0, 2 do begin
  for M = 0, 3 do begin
    varid = cdf_varcreate(fileid, names[M, J],dim_vary, /CDF_FLOAT, DIM = dim, /REC_VARY,/ZVARIABLE) 
    cdf_attput,fileid,'FIELDNAM',varid,names[M, J],/ZVARIABLE
    cdf_attput,fileid,'FORMAT',varid,'F8.4',/ZVARIABLE
    cdf_attput,fileid,'LABLAXIS',varid,'FOV_'+coord[J],/ZVARIABLE
    cdf_attput,fileid,'VAR_TYPE',varid,'data',/ZVARIABLE
    cdf_attput,fileid,'FILLVAL',varid,!values.d_nan,/ZVARIABLE
    cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
    cdf_attput,fileid,'VALIDMIN',names[M, J],-1.0,/ZVARIABLE
    cdf_attput,fileid,'VALIDMAX',names[M, J],1.0,/ZVARIABLE
    cdf_attput,fileid,'SCALEMIN',names[M, J],-1.0,/ZVARIABLE
    cdf_attput,fileid,'SCALEMAX',names[M, J],1.0,/ZVARIABLE
    cdf_attput,fileid,'UNITS',names[M, J],'Unit vector',/ZVARIABLE
    cdf_attput,fileid,'CATDESC',names[M, J],'Geometric center of the '+ direction[M] + ' field of view in ' + $
      coordinate_descriptions [J]+ ' coordinates.',/ZVARIABLE
    cdf_attput,fileid,'DEPEND_0',names[M, J],'EPOCH',/ZVARIABLE
    cdf_attput,fileid,'DEPEND_1',names[M, J],'VECTOR_COMPONENT_NUM',/ZVARIABLE
    cdf_attput,fileid,'DEPEND_TIME',names[M, J],'TIME_UNIX',/ZVARIABLE
    cdf_varput,fileid,names[M, J],sep_ancillary.(2+4*J+M)
  endfor
endfor


; we require the no-vary vector number, i.e. 1 to 3
dim_vary = [1]
dim = 3
name = 'VECTOR_COMPONENT_NUM'
varid = cdf_varcreate(fileid, name, dim_vary, /CDF_UINT1, DIM = dim, /REC_NOVARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,name,/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'i2',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,name,/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'metadata',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,0,/ZVARIABLE
cdf_attput,fileid,'VALIDMIN',name,1,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX',name,3,/ZVARIABLE
cdf_attput,fileid,'UNITS',name,'N/A',/ZVARIABLE
cdf_attput,fileid,'CATDESC',name,'XYZ Look Direction vector component number',/ZVARIABLE

cdf_varput,fileid,name,[1,2,3]

; also require the quaternion number
dim_vary = [1]
dim = 4
name = 'QUATERNION_COMPONENT_NUM'
varid = cdf_varcreate(fileid, name, dim_vary, /CDF_UINT1, DIM = dim, /REC_NOVARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,name,/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'i2',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,name,/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'metadata',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,0,/ZVARIABLE
cdf_attput,fileid,'VALIDMIN',name,1,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX',name,4,/ZVARIABLE
cdf_attput,fileid,'UNITS',name,'N/A',/ZVARIABLE
cdf_attput,fileid,'CATDESC',name,'Quaternion component number',/ZVARIABLE

cdf_varput,fileid,name,[1,2,3]


; also require the no-vary FOV number, i.e. 1 to 4
dim_vary = [1]
dim = 4
name = 'FOV_NUM'
varid = cdf_varcreate(fileid, name, dim_vary, /CDF_UINT1, DIM = dim, /REC_NOVARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,name,/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'i2',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,name,/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'metadata',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-243657,/ZVARIABLE
cdf_attput,fileid,'VALIDMIN',name,1,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX',name,4,/ZVARIABLE
cdf_attput,fileid,'UNITS',name,'N/A',/ZVARIABLE
cdf_attput,fileid,'CATDESC',name,'Field of view number',/ZVARIABLE

;cdf_varput,fileid,name,[1,2,3,4]

; now do the sun angle of the boresight of the FOV
dim_vary = [1]  
numdir = ['1F','1R', '2F', '2R']
names = ('SEP-' + numdir + '_FOV_SUN_ANGLE')
 for M = 0, 3 do begin
    varid = cdf_varcreate(fileid, names[M], /CDF_FLOAT, /REC_VARY,/ZVARIABLE) 
    cdf_attput,fileid,'FIELDNAM',varid,names[M],/ZVARIABLE
    cdf_attput,fileid,'FORMAT',varid,'F9.4',/ZVARIABLE
    cdf_attput,fileid,'LABLAXIS',varid,'Sun Angle, Degrees',/ZVARIABLE
    cdf_attput,fileid,'VAR_TYPE',varid,'data',/ZVARIABLE
    cdf_attput,fileid,'FILLVAL',varid,!values.d_nan,/ZVARIABLE
    cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
    cdf_attput,fileid,'VALIDMIN',names[M],0.0,/ZVARIABLE
    cdf_attput,fileid,'VALIDMAX',names[M],180.0,/ZVARIABLE
    cdf_attput,fileid,'SCALEMIN',names[M],0.0,/ZVARIABLE
    cdf_attput,fileid,'SCALEMAX',names[M],180.0,/ZVARIABLE
    cdf_attput,fileid,'UNITS',names[M],'Degrees',/ZVARIABLE
    cdf_attput,fileid,'CATDESC',names[M],'Angle between the geometric center of the ' + direction [M] +' field of view and the direction of the sun',/ZVARIABLE
    cdf_attput,fileid,'DEPEND_0',names[M],'EPOCH',/ZVARIABLE
    cdf_attput,fileid,'DEPEND_TIME',names[M],'TIME_UNIX',/ZVARIABLE
    cdf_varput,fileid,names[M],sep_ancillary.(14+M)
endfor

; now do the angle between the spacecraft RAM direction and the FOVs
dim_vary = [1]  
numdir = ['1F','1R', '2F', '2R']
names = ('SEP-' + numdir + '_FOV_RAM_ANGLE')
 for M = 0, 3 do begin
    varid = cdf_varcreate(fileid, names[M], /CDF_FLOAT, /REC_VARY,/ZVARIABLE) 
    cdf_attput,fileid,'FIELDNAM',varid,names[M],/ZVARIABLE
    cdf_attput,fileid,'FORMAT',varid,'F9.4',/ZVARIABLE
    cdf_attput,fileid,'LABLAXIS',varid,'Sun Angle, Degrees',/ZVARIABLE
    cdf_attput,fileid,'VAR_TYPE',varid,'data',/ZVARIABLE
    cdf_attput,fileid,'FILLVAL',varid,!values.d_nan,/ZVARIABLE
    cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
    cdf_attput,fileid,'VALIDMIN',names[M],0.0,/ZVARIABLE
    cdf_attput,fileid,'VALIDMAX',names[M],180.0,/ZVARIABLE
    cdf_attput,fileid,'SCALEMIN',names[M],0.0,/ZVARIABLE
    cdf_attput,fileid,'SCALEMAX',names[M],180.0,/ZVARIABLE
    cdf_attput,fileid,'UNITS',names[M],'Degrees',/ZVARIABLE
    cdf_attput,fileid,'CATDESC',names[M],'Angle between the geometric center of the ' + direction [M] +' field of view and the spacecraft RAM direction',/ZVARIABLE
    cdf_attput,fileid,'DEPEND_0',names[M],'EPOCH',/ZVARIABLE
    cdf_attput,fileid,'DEPEND_TIME',names[M],'TIME_UNIX',/ZVARIABLE
    cdf_varput,fileid,names[M],sep_ancillary.(18+M)
endfor


;; now the fraction of the FOV taken up by Mars
dim_vary = [1]  
dim = [1]  
numdir = ['1F','1R', '2F', '2R']
names = ('SEP-' + numdir + '_FRAC_FOV_MARS')
 for M = 0, 3 do begin
    varid = cdf_varcreate(fileid, names[M], /CDF_FLOAT, /REC_VARY,/ZVARIABLE) 
    cdf_attput,fileid,'FIELDNAM',varid,names[M],/ZVARIABLE
    cdf_attput,fileid,'FORMAT',varid,'F8.4',/ZVARIABLE
    cdf_attput,fileid,'LABLAXIS',varid,'Fraction of FOV',/ZVARIABLE
    cdf_attput,fileid,'VAR_TYPE',varid,'data',/ZVARIABLE
    cdf_attput,fileid,'FILLVAL',varid,!values.d_nan,/ZVARIABLE
    cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
    cdf_attput,fileid,'VALIDMIN',names[M],0.0,/ZVARIABLE
    cdf_attput,fileid,'VALIDMAX',names[M],1.0,/ZVARIABLE
    cdf_attput,fileid,'SCALEMIN',names[M],0.0,/ZVARIABLE
    cdf_attput,fileid,'SCALEMAX',names[M],1.0,/ZVARIABLE
    cdf_attput,fileid,'UNITS',names[M],'None',/ZVARIABLE
    cdf_attput,fileid,'CATDESC',names[M],'Fraction of each field of view taken up by Mars',/ZVARIABLE
    cdf_attput,fileid,'DEPEND_0',names[M],'EPOCH',/ZVARIABLE
    cdf_attput,fileid,'DEPEND_TIME',names[M],'TIME_UNIX',/ZVARIABLE
    cdf_varput,fileid,names[M],sep_ancillary.(22+M)
endfor

; now the field of view taken up by sunlit Mars, weighted by the illumination angle.  
;This is important because it is a measure of the total amount of Mars-shine reaching the detector.
; 1.0 would mean the entire field of view is facing Martian noontime.
dim_vary = [1]  
dim = [1]  
numdir = ['1F','1R', '2F', '2R']
names = ('SEP-' + numdir + '_FRAC_FOV_ILL')
 for M = 0, 3 do begin
    varid = cdf_varcreate(fileid, names[M],/CDF_FLOAT, /REC_VARY,/ZVARIABLE) 
    cdf_attput,fileid,'FIELDNAM',varid,names[M],/ZVARIABLE
    cdf_attput,fileid,'FORMAT',varid,'F8.4',/ZVARIABLE
    cdf_attput,fileid,'LABLAXIS',varid,'Fraction of FOV',/ZVARIABLE
    cdf_attput,fileid,'VAR_TYPE',varid,'data',/ZVARIABLE
    cdf_attput,fileid,'FILLVAL',varid,!values.d_nan,/ZVARIABLE
    cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
    cdf_attput,fileid,'VALIDMIN',names[M],0.0,/ZVARIABLE
    cdf_attput,fileid,'VALIDMAX',names[M],1.0,/ZVARIABLE
    cdf_attput,fileid,'SCALEMIN',names[M],0.0,/ZVARIABLE
    cdf_attput,fileid,'SCALEMAX',names[M],1.0,/ZVARIABLE
    cdf_attput,fileid,'UNITS',names[M],'None',/ZVARIABLE
    cdf_attput,fileid,'CATDESC',names[M],'Fraction of each field of view taken up by Mars, weighted by illumination angle',/ZVARIABLE
    cdf_attput,fileid,'DEPEND_0',names[M],'EPOCH',/ZVARIABLE
    cdf_attput,fileid,'DEPEND_TIME',names[M],'TIME_UNIX',/ZVARIABLE
    cdf_varput,fileid,names[M],sep_ancillary.(26+M)
endfor

; fraction of the sky filled by Mars
dim_vary = [1]  
dim = [1]  
name = 'MARS_FRAC_SKY'
    varid = cdf_varcreate(fileid, name, /CDF_FLOAT, /REC_VARY,/ZVARIABLE) 
    cdf_attput,fileid,'FIELDNAM',varid,name,/ZVARIABLE
    cdf_attput,fileid,'FORMAT',varid,'F8.4',/ZVARIABLE
    cdf_attput,fileid,'LABLAXIS',varid,'Mars fraction of sky',/ZVARIABLE
    cdf_attput,fileid,'VAR_TYPE',varid,'data',/ZVARIABLE
    cdf_attput,fileid,'FILLVAL',varid,!values.d_nan,/ZVARIABLE
    cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
    cdf_attput,fileid,'VALIDMIN',name,0.0,/ZVARIABLE
    cdf_attput,fileid,'VALIDMAX',name,1.0,/ZVARIABLE
    cdf_attput,fileid,'SCALEMIN',name,0.0,/ZVARIABLE
    cdf_attput,fileid,'SCALEMAX',name,1.0,/ZVARIABLE
    cdf_attput,fileid,'UNITS',name,'None',/ZVARIABLE
    cdf_attput,fileid,'CATDESC',name,'Fraction of the sky filled by the disk of Mars',/ZVARIABLE
    cdf_attput,fileid,'DEPEND_0',name,'EPOCH',/ZVARIABLE
    cdf_attput,fileid,'DEPEND_TIME',name,'TIME_UNIX',/ZVARIABLE
    cdf_varput,fileid,name,sep_ancillary.fraction_sky_filled_by_Mars


; rotation quaternions between each of the two SEP coordinates systems and the three  geophysical coordinate systems
dim_vary = [1]  
dim = 4  
numsep = ['1', '2']
names = 'SEP-' + replicate_array (numsep, 3) + '_QROT2'+ replicate_array (coord,2, /before)
 for J = 0, 2 do begin
  for M = 0, 1 do begin
    varid = cdf_varcreate(fileid, names[M, J],dim_vary, /CDF_FLOAT, DIM = dim, /REC_VARY,/ZVARIABLE) 
    cdf_attput,fileid,'FIELDNAM',varid,names[M, J],/ZVARIABLE
    cdf_attput,fileid,'FORMAT',varid,'F8.4',/ZVARIABLE
    cdf_attput,fileid,'LABLAXIS',varid,'QROT_'+coord[J],/ZVARIABLE
    cdf_attput,fileid,'VAR_TYPE',varid,'data',/ZVARIABLE
    cdf_attput,fileid,'FILLVAL',varid,!values.d_nan,/ZVARIABLE
    cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
    cdf_attput,fileid,'VALIDMIN',names[M, J],-1.0,/ZVARIABLE
    cdf_attput,fileid,'VALIDMAX',names[M, J],1.0,/ZVARIABLE
    cdf_attput,fileid,'SCALEMIN',names[M, J],-1.0,/ZVARIABLE
    cdf_attput,fileid,'SCALEMAX',names[M, J],1.0,/ZVARIABLE
    cdf_attput,fileid,'UNITS',names[M, J],'None',/ZVARIABLE
    cdf_attput,fileid,'CATDESC',names[M, J],'quaternions of rotation from the SEP' + numsep[M] + $
      ' coordinate system to the '+ coordinate_descriptions [J]+ ' coordinate system.',/ZVARIABLE
    cdf_attput,fileid,'DEPEND_0',names[M, J],'EPOCH',/ZVARIABLE
    cdf_attput,fileid,'DEPEND_1',names[M, J],'QUATERNION_COMPONENT_NUM',/ZVARIABLE
    cdf_attput,fileid,'DEPEND_TIME',names[M, J],'TIME_UNIX',/ZVARIABLE
    cdf_varput,fileid,names[M, J],sep_ancillary.(31+3*M+J)
  endfor
endfor
 
; spacecraft and planet positions
dim_vary = [1]  
dim = 3
coord = ['MSO', 'GEO', 'ECLIPJ2000', 'ECLIPJ2000','ECLIPJ2000']
object = [replicate ('MVN', 3), 'EARTH', 'MARS']
scale_min = [replicate (-1e4, 2),replicate (-2.75e8, 3)]
scale_max = -1.0*scale_min
names = object + '_POS_'+coord
 for M = 0, 4 do begin
    varid = cdf_varcreate(fileid, names[M],dim_vary, /CDF_FLOAT, DIM = dim, /REC_VARY,/ZVARIABLE) 
    cdf_attput,fileid,'FIELDNAM',varid,names[M],/ZVARIABLE
    cdf_attput,fileid,'FORMAT',varid,'F15.4',/ZVARIABLE
    cdf_attput,fileid,'LABLAXIS',varid,'km',/ZVARIABLE
    cdf_attput,fileid,'VAR_TYPE',varid,'data',/ZVARIABLE
    cdf_attput,fileid,'FILLVAL',varid,!values.d_nan,/ZVARIABLE
    cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
    cdf_attput,fileid,'VALIDMIN',names[M],-1e9,/ZVARIABLE
    cdf_attput,fileid,'VALIDMAX',names[M],1e9,/ZVARIABLE
    cdf_attput,fileid,'SCALEMIN',names[M],scale_min [M],/ZVARIABLE
    cdf_attput,fileid,'SCALEMAX',names[M],scale_max [M],/ZVARIABLE
    cdf_attput,fileid,'UNITS',names[M],'km',/ZVARIABLE
    cdf_attput,fileid,'CATDESC',names[M],'Position of '+object[M]+' in '+coord[M]+' coordinates.',/ZVARIABLE
    cdf_attput,fileid,'DEPEND_0',names[M],'EPOCH',/ZVARIABLE
    cdf_attput,fileid,'DEPEND_1',names[M],'VECTOR_COMPONENT_NUM',/ZVARIABLE
    cdf_attput,fileid,'DEPEND_TIME',names[M],'TIME_UNIX',/ZVARIABLE
    cdf_varput,fileid,names[M],sep_ancillary.(37+M)
endfor

dim_vary = [1]  
dim = [1]  
name = 'MVN_LAT_GEO'
    varid = cdf_varcreate(fileid, name,/CDF_FLOAT, /REC_VARY,/ZVARIABLE) 
    cdf_attput,fileid,'FIELDNAM',varid,name,/ZVARIABLE
    cdf_attput,fileid,'FORMAT',varid,'F8.3',/ZVARIABLE
    cdf_attput,fileid,'LABLAXIS',varid,'Latitude, degrees',/ZVARIABLE
    cdf_attput,fileid,'VAR_TYPE',varid,'data',/ZVARIABLE
    cdf_attput,fileid,'FILLVAL',varid,!values.d_nan,/ZVARIABLE
    cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
    cdf_attput,fileid,'VALIDMIN',name,-90.0,/ZVARIABLE
    cdf_attput,fileid,'VALIDMAX',name,90.0,/ZVARIABLE
    cdf_attput,fileid,'SCALEMIN',name,-90.0,/ZVARIABLE
    cdf_attput,fileid,'SCALEMAX',name,90.0,/ZVARIABLE
    cdf_attput,fileid,'UNITS',name,'Degrees',/ZVARIABLE
    cdf_attput,fileid,'CATDESC',name,'Spacecraft Latitude in planet-fixed IAU Mars coordinates.',/ZVARIABLE
    cdf_attput,fileid,'DEPEND_0',name,'EPOCH',/ZVARIABLE
    cdf_attput,fileid,'DEPEND_TIME',name,'TIME_UNIX',/ZVARIABLE
    cdf_varput,fileid,name,sep_ancillary.spacecraft_latitude_GEO


dim_vary = [1]  
dim = [1]  
name = 'MVN_ELON_GEO'
    varid = cdf_varcreate(fileid, name, /CDF_FLOAT, /REC_VARY,/ZVARIABLE) 
    cdf_attput,fileid,'FIELDNAM',varid,name,/ZVARIABLE
    cdf_attput,fileid,'FORMAT',varid,'F8.3',/ZVARIABLE
    cdf_attput,fileid,'LABLAXIS',varid,'Longitude, degrees',/ZVARIABLE
    cdf_attput,fileid,'VAR_TYPE',varid,'data',/ZVARIABLE
    cdf_attput,fileid,'FILLVAL',varid,!values.d_nan,/ZVARIABLE
    cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
    cdf_attput,fileid,'VALIDMIN',name,0.0,/ZVARIABLE
    cdf_attput,fileid,'VALIDMAX',name,360.0,/ZVARIABLE
    cdf_attput,fileid,'SCALEMIN',name,0.0,/ZVARIABLE
    cdf_attput,fileid,'SCALEMAX',name,360.0,/ZVARIABLE
    cdf_attput,fileid,'UNITS',name,'Degrees',/ZVARIABLE
    cdf_attput,fileid,'CATDESC',name,'Spacecraft East Longitude in planet-fixed IAU Mars coordinates.',/ZVARIABLE
    cdf_attput,fileid,'DEPEND_0',name,'EPOCH',/ZVARIABLE
    cdf_attput,fileid,'DEPEND_TIME',name,'TIME_UNIX',/ZVARIABLE
    cdf_varput,fileid,name,sep_ancillary.spacecraft_east_longitude_GEO


dim_vary = [1]  
dim = [1]  
name = 'MVN_SZA'
    varid = cdf_varcreate(fileid, name, /CDF_FLOAT, /REC_VARY,/ZVARIABLE) 
    cdf_attput,fileid,'FIELDNAM',varid,name,/ZVARIABLE
    cdf_attput,fileid,'FORMAT',varid,'F8.3',/ZVARIABLE
    cdf_attput,fileid,'LABLAXIS',varid,'SZA, degrees',/ZVARIABLE
    cdf_attput,fileid,'VAR_TYPE',varid,'data',/ZVARIABLE
    cdf_attput,fileid,'FILLVAL',varid,!values.d_nan,/ZVARIABLE
    cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
    cdf_attput,fileid,'VALIDMIN',name,0.0,/ZVARIABLE
    cdf_attput,fileid,'VALIDMAX',name,180.0,/ZVARIABLE
    cdf_attput,fileid,'SCALEMIN',name,0.0,/ZVARIABLE
    cdf_attput,fileid,'SCALEMAX',name,180.0,/ZVARIABLE
    cdf_attput,fileid,'UNITS',name,'Degrees',/ZVARIABLE
    cdf_attput,fileid,'CATDESC',name,'Spacecraft Solar Zenith Angle',/ZVARIABLE
    cdf_attput,fileid,'DEPEND_0',name,'EPOCH',/ZVARIABLE
    cdf_attput,fileid,'DEPEND_TIME',name,'TIME_UNIX',/ZVARIABLE
    cdf_varput,fileid,name,sep_ancillary.spacecraft_solar_zenith_angle


dim_vary = [1]  
dim = [1]  
name = 'MVN_SLT'
    varid = cdf_varcreate(fileid, name, /CDF_FLOAT, /REC_VARY,/ZVARIABLE) 
    cdf_attput,fileid,'FIELDNAM',varid,name,/ZVARIABLE
    cdf_attput,fileid,'FORMAT',varid,'F8.3',/ZVARIABLE
    cdf_attput,fileid,'LABLAXIS',varid,'Local Time',/ZVARIABLE
    cdf_attput,fileid,'VAR_TYPE',varid,'data',/ZVARIABLE
    cdf_attput,fileid,'FILLVAL',varid,!values.d_nan,/ZVARIABLE
    cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
    cdf_attput,fileid,'VALIDMIN',name,0.0,/ZVARIABLE
    cdf_attput,fileid,'VALIDMAX',name,180.0,/ZVARIABLE
    cdf_attput,fileid,'SCALEMIN',name,0.0,/ZVARIABLE
    cdf_attput,fileid,'SCALEMAX',name,180.0,/ZVARIABLE
    cdf_attput,fileid,'UNITS',name,'Mars Hours',/ZVARIABLE
    cdf_attput,fileid,'CATDESC',name,'Spacecraft Solar Local Time',/ZVARIABLE
    cdf_attput,fileid,'DEPEND_0',name,'EPOCH',/ZVARIABLE
    cdf_attput,fileid,'DEPEND_TIME',name,'TIME_UNIX',/ZVARIABLE
    cdf_varput,fileid,name,sep_ancillary.spacecraft_local_time




cdf_close,fileid

end
