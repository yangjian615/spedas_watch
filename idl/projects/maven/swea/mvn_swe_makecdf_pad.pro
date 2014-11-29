;+
; NAME:
;   MVN_SWE_MAKECDF_PAD
; SYNTAX:
;   MVN_SWEA_MAKECDF_PAD, DATA, FILE = FILE, VERSION = VERSION
; PURPOSE:
;   Routine to produce CDF file from SWEA pad data structures
; INPUT:
;   DATA: Structure with which to populate the CDF file
;         (nominally created by mvn_swe_getpad.pro)
; OUTPUT:
;   CDF file
; KEYWORDS:
;   FILE: full file name of the output file - only used for testing
;         if not specified (usually won't be), the program creates the appropriate filename
;   VERSION: integer; software version - should be hardcoded when/if software changes
; HISTORY: 
;   Created by Matt Fillingim (with code stolen from JH and RL)
;   Added directory keyword, jmm, 2104-11-14
; VERSION:
;   $LastChangedBy: jimm $
;   $LastChangedDate: 2014-11-26 13:47:48 -0800 (Wed, 26 Nov 2014) $
;   $LastChangedRevision: 16314 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_makecdf_pad.pro $
;
;-

pro mvn_swe_makecdf_pad, data, file = file, version = version, directory = directory

@mvn_swe_com

if (n_elements(data) eq 1) then begin ; no data!
  print, 'No PAD data!'
  print, 'CDF file not created'
  return
endif

; get data type -- survey or archive
CASE data[0].apid OF
  162: BEGIN
         tag = 'svy'
         title = 'MAVEN SWEA PAD Survey'
       END
  163: BEGIN
         tag = 'arc'
         title = 'MAVEN SWEA PAD Archive'
       END
  ELSE: BEGIN
          PRINT, 'Invalid APID: ', data[0].apid
          tag = 'und'
          title = 'MAVEN SWEA PAD Undefined'
          STOP ; kind of harsh
        END
ENDCASE

; get date
nrec = n_elements(data)
mid = nrec/2
dum_str = time_string(data[mid].time) ; use midpoint of day
; (avoid any potential weird first-file-of-day timing)
yyyy = strmid(dum_str, 0, 4)
mm = strmid(dum_str, 5, 2)
dd = strmid(dum_str, 8, 2)
yyyymmdd = yyyy + mm + dd

if (not keyword_set(file)) then begin

; hardcoded data directory path
; Added directory keyword, for testing, jmm, 2014-11-14
  if (keyword_set(directory)) then path = directory[0] else $
  path = '/disks/data/maven/data/sci/swe/l2/' + yyyy + '/' + mm + '/'
  if (n_elements(file_search(path)) Eq 0) then file_mkdir2, path, mode = '0774'o

; create file name using SIS convention
  file = 'mvn_swe_l2_' + tag + 'pad_' + yyyymmdd

; specify version number
  if (not keyword_set(version)) then version = 1

; search for CDF files for this day
  file_list = file_search(path + file + '*.cdf', count = nfiles)
  if (nfiles gt 0) then begin ; file for this day already exists
; check for latest reversion number, add one to it (delete/overwrite old version)
    latest = file_list[nfiles-1] ;  latest should be last in list
    old_rev_str = strmid(latest, 5, 2, /reverse_offset)
    revision = fix(old_rev_str) + 1
  endif else begin ; file for this day does not exist
    revision = 1
  endelse

;revision number
  rev_str = strtrim(revision, 2)
  if (strlen(rev_str) eq 1) then rev_str = '0' + rev_str

; version number
  vers_str = strtrim(version, 2)
  if (strlen(vers_str) eq 1) then vers_str = '0' + vers_str
  head_file = file + '_v' + vers_str + '_r' + rev_str + '.cdf'
  file = path + head_file

endif else $ ; if (not keyword_set(file))
  rev_str = '01' ; needed in the header

print, file

; compute various times
; load leap seconds
cdf_leap_second_init

; get date ranges (for CDF files)
date_range = time_double(['2013-11-18/00:00', '2030-12-31/23:59'])
;met_range = date_range - time_double('2000-01-01/12:00') ; JH
met_range = date_range - date_range[0] ; RL -- start at 0
epoch_range = time_epoch(date_range)
tt2000_range = long64((add_tt2000_offset(date_range) $
             - time_double('2000-01-01/12:00'))*1e9)

; *** uses general/misc/time/time_epoch.pro ***
; time_epoch ==> return, 1000.d*(time_double(time) + 719528.d*24.d*3600.d)
; epoch is milliseconds from 0000-01-01/00:00:00.000
epoch = time_epoch(data.time) ; time is unix time in swea structures

; JH method
tt2000 = long64((add_tt2000_offset(data.time) $
       - time_double('2000-01-01/12:00'))*1e9)

; DM method ; not quite the same
;cdf_epoch, epoch, year, month, date, hour, min, sec, msec, /breakdown
;cdf_tt2000, tt2000, year, month, date, hour, min, sec, msec, /compute

t_start_str = time_string(data[0].time, tformat = 'YYYY-MM-DDThh:mm:ss.fffZ')
t_end_str = time_string(data[nrec-1].end_time, tformat = 'YYYY-MM-DDThh:mm:ss.fffZ')

; include SPICE kernels used
; spacecraft clock kernel
i = where(strmatch(swe_kernels,'*sclk*',/fold), count)
if (count gt 0) then driftname = file_basename(swe_kernels[i])

; leapseconds kernel
j = where(strmatch(swe_kernels,'*.tls',/fold), count)
if (count gt 0) then leapname = file_basename(swe_kernels[j])

; create and populate CDF file
fileid = cdf_create(file, /single_file, /network_encoding, /clobber)

varlist = ['epoch', 'time_tt2000', 'time_met', 'time_unix', $
           'binning', 'counts', 'diff_en_fluxes', 'geom_factor', $
           'g_engy', 'de_over_e', 'accum_time', 'energy', 'pa', $
	   'd_pa', 'g_pa', 'b_azim', 'b_elev', 'num_dists']

id0  = cdf_attcreate(fileid, 'Title',                      /global_scope)
id1  = cdf_attcreate(fileid, 'Project',                    /global_scope)
id2  = cdf_attcreate(fileid, 'Discipline',                 /global_scope)
id3  = cdf_attcreate(fileid, 'Source_name',                /global_scope)
id4  = cdf_attcreate(fileid, 'Descriptor',                 /global_scope)
id5  = cdf_attcreate(fileid, 'Data_type',                  /global_scope)
id6  = cdf_attcreate(fileid, 'Data_version',               /global_scope)
id7  = cdf_attcreate(fileid, 'TEXT',                       /global_scope)
id8  = cdf_attcreate(fileid, 'Mods',                       /global_scope)
id9  = cdf_attcreate(fileid, 'Logical_file_id',            /global_scope)
id10 = cdf_attcreate(fileid, 'Logical_source',             /global_scope)
id11 = cdf_attcreate(fileid, 'Logical_source_description', /global_scope)
id12 = cdf_attcreate(fileid, 'PI_name',                    /global_scope)
id13 = cdf_attcreate(fileid, 'PI_affiliation',             /global_scope)
id14 = cdf_attcreate(fileid, 'Instrument_type',            /global_scope)
id15 = cdf_attcreate(fileid, 'Mission_group',              /global_scope)
id16 = cdf_attcreate(fileid, 'Parents',                    /global_scope)
id17 = cdf_attcreate(fileid, 'Spacecraft_clock_kernel',    /global_scope)
id18 = cdf_attcreate(fileid, 'Leapseconds_kernel',         /global_scope)
id19 = cdf_attcreate(fileid, 'PDS_collection_id',          /global_scope)
id20 = cdf_attcreate(fileid, 'PDS_start_time',             /global_scope)
id21 = cdf_attcreate(fileid, 'PDS_stop_time',              /global_scope)
id22 = cdf_attcreate(fileid, 'PDS_sclk_start_count',       /global_scope)
id23 = cdf_attcreate(fileid, 'PDS_sclk_stop_count',        /global_scope)

cdf_attput, fileid, 'Title',                      0, $
  title
cdf_attput, fileid, 'Project',                    0, $
  'MAVEN>Mars Atmosphere and Volatile EvolutioN Mission'
cdf_attput, fileid, 'Discipline',                 0, $
;  'Planetary Physics>Planetary Plasma Interactions'
  'Planetary Physics>Particles'
cdf_attput, fileid, 'Source_name',                0, $
  'MAVEN>Mars Atmosphere and Volatile EvolutioN Mission'
cdf_attput, fileid, 'Descriptor',                 0, $
  'SWEA>Solar Wind Electron Analyzer'
cdf_attput, fileid, 'Data_type',                  0, $
  'CAL>Calibrated'
cdf_attput, fileid, 'Data_version',               0, $
;  revision
  rev_str
cdf_attput, fileid, 'TEXT',                       0, $
  'MAVEN SWEA Pitch Angle Distributions'
cdf_attput, fileid, 'Mods',                       0, $
  'Revision 0'
cdf_attput, fileid, 'Logical_file_id',            0, $
  file
cdf_attput, fileid, 'Logical_source',             0, $
  'swea.calibrated.' + tag + '_pad'
cdf_attput, fileid, 'Logical_source_description', 0, $
  'DERIVED FROM: MAVEN SWEA (Solar Wind Electron Analyzer) Pitch Angle Distributions'
cdf_attput, fileid, 'PI_name', 0, $
  'David L. Mitchell (mitchell@ssl.berkeley.edu)'
cdf_attput, fileid, 'PI_affiliation',             0, $
  'UC Berkeley Space Sciences Laboratory'
cdf_attput, fileid, 'Instrument_type',            0, $
  'Plasma and Solar Wind'
cdf_attput, fileid, 'Mission_group',              0, $
  'MAVEN'
cdf_attput, fileid, 'Parents',                    0, $
  'None'
cdf_attput, fileid, 'Spacecraft_clock_kernel',    0, $
  driftname[0]
cdf_attput, fileid, 'Leapseconds_kernel',         0, $
  leapname[0]
cdf_attput, fileid, 'PDS_collection_id',          0, $
;  'urn:nasa:pds:maven.swea.calibrated:data.' + tag + '_3d'
  'data.' + tag + '_pad'
cdf_attput, fileid, 'PDS_start_time',             0, $     
  t_start_str
cdf_attput, fileid, 'PDS_stop_time',              0, $     
  t_end_str
cdf_attput, fileid, 'PDS_sclk_start_count',       0, $     
  data[0].met
cdf_attput, fileid, 'PDS_sclk_stop_count',        0, $     
  data[nrec-1].met

dummy = cdf_attcreate(fileid, 'FIELDNAM',     /variable_scope)
dummy = cdf_attcreate(fileid, 'MONOTON',      /variable_scope)
dummy = cdf_attcreate(fileid, 'FORMAT',       /variable_scope)
dummy = cdf_attcreate(fileid, 'FORM_PTR',     /variable_scope)
dummy = cdf_attcreate(fileid, 'LABLAXIS',     /variable_scope)
dummy = cdf_attcreate(fileid, 'VAR_TYPE',     /variable_scope)
dummy = cdf_attcreate(fileid, 'FILLVAL',      /variable_scope)
dummy = cdf_attcreate(fileid, 'DEPEND_0',     /variable_scope)
dummy = cdf_attcreate(fileid, 'DISPLAY_TYPE', /variable_scope)
dummy = cdf_attcreate(fileid, 'VALIDMIN',     /variable_scope)
dummy = cdf_attcreate(fileid, 'VALIDMAX',     /variable_scope)
dummy = cdf_attcreate(fileid, 'SCALEMIN',     /variable_scope)
dummy = cdf_attcreate(fileid, 'SCALEMAX',     /variable_scope)
dummy = cdf_attcreate(fileid, 'UNITS',        /variable_scope)
dummy = cdf_attcreate(fileid, 'CATDESC',      /variable_scope)

; for each item in varlist

;; *** epoch ***
;varid = cdf_varcreate(fileid, varlist[0], /CDF_EPOCH, /REC_VARY, /ZVARIABLE)
;
;cdf_attput, fileid, 'FIELDNAM',     varid, varlist[0],     /ZVARIABLE
;cdf_attput, fileid, 'FORMAT',       varid, 'F25.16',       /ZVARIABLE
;cdf_attput, fileid, 'LABLAXIS',     varid, varlist[0],     /ZVARIABLE
;cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
;cdf_attput, fileid, 'FILLVAL',      varid, 0.0,            /ZVARIABLE
;cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE
;
;cdf_attput, fileid, 'VALIDMIN', 'epoch', epoch_range[0], /ZVARIABLE
;cdf_attput, fileid, 'VALIDMAX', 'epoch', epoch_range[1], /ZVARIABLE
;cdf_attput, fileid, 'SCALEMIN', 'epoch', epoch[0],       /ZVARIABLE
;cdf_attput, fileid, 'SCALEMAX', 'epoch', epoch[nrec-1],  /ZVARIABLE
;cdf_attput, fileid, 'UNITS',    'epoch', 'ms',           /ZVARIABLE
;cdf_attput, fileid, 'MONOTON',  'epoch', 'INCREASE',     /ZVARIABLE
;cdf_attput, fileid, 'CATDESC',  'epoch', $
;  'Time, start of sample, in NSSDC Epoch', /ZVARIABLE
;
;cdf_varput, fileid, 'epoch', epoch

; *** epoch *** (Actually tt2000)
varid = cdf_varcreate(fileid, varlist[0], /CDF_TIME_TT2000, /REC_VARY, /ZVARIABLE)

cdf_attput, fileid, 'FIELDNAM',     varid, varlist[1],           /ZVARIABLE
cdf_attput, fileid, 'FORMAT',       varid, 'I22',                /ZVARIABLE
cdf_attput, fileid, 'LABLAXIS',     varid, varlist[1],           /ZVARIABLE
cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data',       /ZVARIABLE
cdf_attput, fileid, 'FILLVAL',      varid, -9223372036854775808, /ZVARIABLE, /CDF_EPOCH
cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',        /ZVARIABLE

cdf_attput, fileid, 'VALIDMIN', 'epoch', tt2000_range[0], /ZVARIABLE, /CDF_EPOCH
cdf_attput, fileid, 'VALIDMAX', 'epoch', tt2000_range[1], /ZVARIABLE, /CDF_EPOCH
cdf_attput, fileid, 'SCALEMIN', 'epoch', tt2000[0],       /ZVARIABLE, /CDF_EPOCH
cdf_attput, fileid, 'SCALEMAX', 'epoch', tt2000[nrec-1],  /ZVARIABLE, /CDF_EPOCH
cdf_attput, fileid, 'UNITS',    'epoch', 'ns',            /ZVARIABLE
cdf_attput, fileid, 'MONOTON',  'epoch', 'INCREASE',      /ZVARIABLE
cdf_attput, fileid, 'CATDESC',  'epoch', $
  'Time, center of sample, in TT2000 time base', /ZVARIABLE

cdf_varput, fileid, 'epoch', tt2000

; *** time_met ***
varid = cdf_varcreate(fileid, varlist[2], /CDF_DOUBLE, /REC_VARY, /ZVARIABLE)

cdf_attput, fileid, 'FIELDNAM',     varid, varlist[2],     /ZVARIABLE
cdf_attput, fileid, 'FORMAT',       varid, 'F25.6',        /ZVARIABLE
cdf_attput, fileid, 'LABLAXIS',     varid, varlist[2],     /ZVARIABLE
cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
cdf_attput, fileid, 'FILLVAL',      varid, -1.d31,         /ZVARIABLE
cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

cdf_attput, fileid, 'VALIDMIN', 'time_met', met_range[0],     /ZVARIABLE
cdf_attput, fileid, 'VALIDMAX', 'time_met', met_range[1],     /ZVARIABLE
cdf_attput, fileid, 'SCALEMIN', 'time_met', data[0].met,      /ZVARIABLE
cdf_attput, fileid, 'SCALEMAX', 'time_met', data[nrec-1].met, /ZVARIABLE
cdf_attput, fileid, 'UNITS',    'time_met', 's',              /ZVARIABLE
cdf_attput, fileid, 'MONOTON',  'time_met', 'INCREASE',       /ZVARIABLE
cdf_attput, fileid, 'CATDESC',  'time_met', $
  'Time, center of sample, in raw mission elapsed time', /ZVARIABLE

cdf_varput, fileid, 'time_met', data.met

; *** time_unix ***
varid = cdf_varcreate(fileid, varlist[3], /CDF_DOUBLE, /REC_VARY, /ZVARIABLE)

cdf_attput, fileid, 'FIELDNAM',     varid, varlist[3],     /ZVARIABLE
cdf_attput, fileid, 'FORMAT',       varid, 'F25.6',        /ZVARIABLE
cdf_attput, fileid, 'LABLAXIS',     varid, varlist[3],     /ZVARIABLE
cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
cdf_attput, fileid, 'FILLVAL',      varid, -1.d31,         /ZVARIABLE
cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

cdf_attput, fileid, 'VALIDMIN', 'time_unix', date_range[0],     /ZVARIABLE
cdf_attput, fileid, 'VALIDMAX', 'time_unix', date_range[1],     /ZVARIABLE
cdf_attput, fileid, 'SCALEMIN', 'time_unix', data[0].time,      /ZVARIABLE
cdf_attput, fileid, 'SCALEMAX', 'time_unix', data[nrec-1].time, /ZVARIABLE
cdf_attput, fileid, 'UNITS',    'time_unix', 's',               /ZVARIABLE
cdf_attput, fileid, 'MONOTON',  'time_unix', 'INCREASE',        /ZVARIABLE
cdf_attput, fileid, 'CATDESC',  'time_unix', $
  'Time, center of sample, in Unix time', /ZVARIABLE

cdf_varput, fileid, 'time_unix', data.time

; *** binning ***
varid = cdf_varcreate(fileid, varlist[4], /CDF_INT1, /REC_VARY, /ZVARIABLE)

cdf_attput, fileid, 'FIELDNAM',     varid, varlist[4],     /ZVARIABLE
cdf_attput, fileid, 'FORMAT',       varid, 'I7',           /ZVARIABLE
cdf_attput, fileid, 'LABLAXIS',     varid, varlist[4],     /ZVARIABLE
cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
cdf_attput, fileid, 'FILLVAL',      varid, -128,           /ZVARIABLE
cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

cdf_attput, fileid, 'VALIDMIN', 'binning', 1,       /ZVARIABLE
cdf_attput, fileid, 'VALIDMAX', 'binning', 4,       /ZVARIABLE
cdf_attput, fileid, 'SCALEMIN', 'binning', 1,       /ZVARIABLE
cdf_attput, fileid, 'SCALEMAX', 'binning', 4,       /ZVARIABLE
cdf_attput, fileid, 'CATDESC',  'binning', $
  'Energy binning factor: 1 = 64 energies, 2 = 32 energies, 4 = 16 energies', $
  /ZVARIABLE
cdf_attput, fileid, 'DEPEND_0', 'binning', 'epoch', /ZVARIABLE

cdf_varput, fileid, 'binning', 2^data.group

; *** counts ***
dim_vary = [1, 1]
dim = [64, 16]  
varid = cdf_varcreate(fileid, varlist[5], dim_vary, DIM = dim, /REC_VARY, /ZVARIABLE) 

cdf_attput, fileid, 'FIELDNAM',     varid, varlist[5],     /ZVARIABLE
cdf_attput, fileid, 'FORMAT',       varid, 'F15.7',        /ZVARIABLE
cdf_attput, fileid, 'LABLAXIS',     varid, varlist[5],     /ZVARIABLE
cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
cdf_attput, fileid, 'FILLVAL',      varid, -1.e31,         /ZVARIABLE
cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

cdf_attput, fileid, 'VALIDMIN', 'counts', 0,                       /ZVARIABLE
cdf_attput, fileid, 'VALIDMAX', 'counts', 1e10,                    /ZVARIABLE
cdf_attput, fileid, 'SCALEMIN', 'counts', 0,                       /ZVARIABLE
cdf_attput, fileid, 'SCALEMAX', 'counts', 1e5,                     /ZVARIABLE
cdf_attput, fileid, 'UNITS',    'counts', 'counts',                /ZVARIABLE
cdf_attput, fileid, 'CATDESC',  'counts', 'Raw Instrument Counts', /ZVARIABLE
cdf_attput, fileid, 'DEPEND_0', 'counts', 'epoch',                 /ZVARIABLE

; convert to units of counts
mvn_swe_convert_units, data, 'counts'
cdf_varput, fileid, 'counts', data.data

; *** diff_en_fluxes -- Differrential energy fluxes ***
dim_vary = [1, 1]
dim = [64, 16]  
varid = cdf_varcreate(fileid, varlist[6], dim_vary, DIM = dim, /REC_VARY, $
  /ZVARIABLE) 

cdf_attput, fileid, 'FIELDNAM',     varid, varlist[6],    /ZVARIABLE
cdf_attput, fileid, 'FORMAT',       varid, 'F15.7',       /ZVARIABLE
cdf_attput, fileid, 'LABLAXIS',     varid, varlist[6],    /ZVARIABLE
cdf_attput, fileid, 'VAR_TYPE',     varid, 'data',        /ZVARIABLE
cdf_attput, fileid, 'FILLVAL',      varid, -1.e31,        /ZVARIABLE
cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series', /ZVARIABLE

cdf_attput, fileid, 'VALIDMIN', 'diff_en_fluxes', 0,       /ZVARIABLE
cdf_attput, fileid, 'VALIDMAX', 'diff_en_fluxes', 1e14,    /ZVARIABLE
cdf_attput, fileid, 'SCALEMIN', 'diff_en_fluxes', 0,       /ZVARIABLE
cdf_attput, fileid, 'SCALEMAX', 'diff_en_fluxes', 1e11,    /ZVARIABLE
cdf_attput, fileid, 'UNITS',    'diff_en_fluxes', $
  'eV/[eV cm^2 sr s]', /ZVARIABLE
cdf_attput, fileid, 'VAR_TYPE', 'diff_en_fluxes', 'data',  /ZVARIABLE
cdf_attput, fileid, 'CATDESC',  'diff_en_fluxes', $
  'Calibrated differential energy flux', /ZVARIABLE
cdf_attput, fileid, 'DEPEND_0', 'diff_en_fluxes', 'epoch', /ZVARIABLE

; convert to units of energy flux
mvn_swe_convert_units, data, 'eflux'
cdf_varput, fileid, 'diff_en_fluxes', data.data

; *** geom_factor -- Geometric factor ***
varid = cdf_varcreate(fileid, varlist[7], /REC_NOVARY, /ZVARIABLE)

cdf_attput, fileid, 'FIELDNAM',     varid, varlist[7],     /ZVARIABLE
cdf_attput, fileid, 'FORMAT',       varid, 'F15.7',        /ZVARIABLE
cdf_attput, fileid, 'LABLAXIS',     varid, varlist[7],     /ZVARIABLE
cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
cdf_attput, fileid, 'FILLVAL',      varid, -1.e31,         /ZVARIABLE
cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

cdf_attput, fileid, 'VALIDMIN', 'geom_factor', 0,               /ZVARIABLE
cdf_attput, fileid, 'VALIDMAX', 'geom_factor', 1.0,             /ZVARIABLE
cdf_attput, fileid, 'SCALEMIN', 'geom_factor', 0,               /ZVARIABLE
cdf_attput, fileid, 'SCALEMAX', 'geom_factor', 1e-2,            /ZVARIABLE
cdf_attput, fileid, 'UNITS',    'geom_factor', 'cm^2 sr eV/eV', /ZVARIABLE
cdf_attput, fileid, 'CATDESC',  'geom_factor', $
  'Full sensor geometric factor (per anode) at 1.4 keV', /ZVARIABLE

geom_factor = 0.009/16./2.9
cdf_varput, fileid, 'geom_factor', geom_factor

; *** g_engy -- Relative sensitivity as a function of energy ***
dim_vary = [1]
dim = 64
varid = cdf_varcreate(fileid, varlist[8], dim_vary, DIM = dim, /REC_NOVARY, $
  /ZVARIABLE)

cdf_attput, fileid, 'FIELDNAM',     varid, varlist[8],     /ZVARIABLE
cdf_attput, fileid, 'FORMAT',       varid, 'F15.7',        /ZVARIABLE
cdf_attput, fileid, 'LABLAXIS',     varid, varlist[8],     /ZVARIABLE
cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
cdf_attput, fileid, 'FILLVAL',      varid, -1.e31,         /ZVARIABLE
cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

cdf_attput, fileid, 'VALIDMIN', 'g_engy', 0,   /ZVARIABLE
cdf_attput, fileid, 'VALIDMAX', 'g_engy', 1.0, /ZVARIABLE
cdf_attput, fileid, 'SCALEMIN', 'g_engy', 0,   /ZVARIABLE
cdf_attput, fileid, 'SCALEMAX', 'g_engy', 0.2, /ZVARIABLE
cdf_attput, fileid, 'CATDESC',  'g_engy', $
  'Relative sensitivity as a function of energy', /ZVARIABLE

; average over angles to get gf as a function of energy
; use midpoint of the data
g_engy = total(data[mid].eff*data[mid].gf, 2)/float(data[mid].nbins) ; [64]
g_engy = g_engy/geom_factor

cdf_varput, fileid, 'g_engy', g_engy

; *** de_over_e -- DE/E ***
dim_vary = [1]
dim = 64
varid = cdf_varcreate(fileid, varlist[9], dim_vary, DIM = dim, /REC_NOVARY, $
  /ZVARIABLE)

cdf_attput, fileid, 'FIELDNAM',     varid, varlist[9],     /ZVARIABLE
cdf_attput, fileid, 'FORMAT',       varid, 'F15.7',        /ZVARIABLE
cdf_attput, fileid, 'LABLAXIS',     varid, varlist[9],     /ZVARIABLE
cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
cdf_attput, fileid, 'FILLVAL',      varid, -1.e31,         /ZVARIABLE
cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

cdf_attput, fileid, 'VALIDMIN', 'de_over_e', 0,                 /ZVARIABLE
cdf_attput, fileid, 'VALIDMAX', 'de_over_e', 1.0,               /ZVARIABLE
cdf_attput, fileid, 'SCALEMIN', 'de_over_e', 0,                 /ZVARIABLE
cdf_attput, fileid, 'SCALEMAX', 'de_over_e', 0.3,               /ZVARIABLE
cdf_attput, fileid, 'UNITS',    'de_over_e', 'eV/eV',           /ZVARIABLE
cdf_attput, fileid, 'CATDESC',  'de_over_e', 'DeltaE/E (FWHM)', /ZVARIABLE

de_over_e = data[mid].denergy[*, 0]/data[mid].energy[*, 0] ; 64

cdf_varput, fileid, 'de_over_e', de_over_e

; *** accum_time -- Accumulation Time ***
varid = cdf_varcreate(fileid, varlist[10], /REC_NOVARY, /ZVARIABLE)

cdf_attput, fileid, 'FIELDNAM',     varid, varlist[10],    /ZVARIABLE
cdf_attput, fileid, 'FORMAT',       varid, 'F15.7',        /ZVARIABLE
cdf_attput, fileid, 'LABLAXIS',     varid, varlist[10],    /ZVARIABLE
cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
cdf_attput, fileid, 'FILLVAL',      varid, -1.e31,         /ZVARIABLE
cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

cdf_attput, fileid, 'VALIDMIN', 'accum_time', 0,                   /ZVARIABLE
cdf_attput, fileid, 'VALIDMAX', 'accum_time', 1.0,                 /ZVARIABLE
cdf_attput, fileid, 'SCALEMIN', 'accum_time', 0,                   /ZVARIABLE
cdf_attput, fileid, 'SCALEMAX', 'accum_time', 0.1,                 /ZVARIABLE
cdf_attput, fileid, 'UNITS',    'accum_time', 's',                 /ZVARIABLE
cdf_attput, fileid, 'CATDESC',  'accum_time', 'Accumulation Time', /ZVARIABLE

cdf_varput, fileid, 'accum_time', data[mid].integ_t

; *** energy ***
dim_vary = [1]
dim = 64
varid = cdf_varcreate(fileid, varlist[11], dim_vary, DIM = dim, /REC_NOVARY, $
  /ZVARIABLE)

cdf_attput, fileid, 'FIELDNAM',     varid, varlist[11],    /ZVARIABLE
cdf_attput, fileid, 'FORMAT',       varid, 'F15.7',        /ZVARIABLE
cdf_attput, fileid, 'LABLAXIS',     varid, varlist[11],    /ZVARIABLE
cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
cdf_attput, fileid, 'FILLVAL',      varid, -1.e31,         /ZVARIABLE
cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

cdf_attput, fileid, 'VALIDMIN', 'energy', 0,          /ZVARIABLE
cdf_attput, fileid, 'VALIDMAX', 'energy', 5e4,        /ZVARIABLE
cdf_attput, fileid, 'SCALEMIN', 'energy', 0,          /ZVARIABLE
cdf_attput, fileid, 'SCALEMAX', 'energy', 5e3,        /ZVARIABLE
cdf_attput, fileid, 'UNITS',    'energy', 'eV',       /ZVARIABLE
cdf_attput, fileid, 'CATDESC',  'energy', 'Energies', /ZVARIABLE

cdf_varput, fileid, 'energy', data[mid].energy[*, 0]

; *** pa -- Pitch Angle ***
dim_vary = [1, 1]
dim = [64, 16]
varid = cdf_varcreate(fileid, varlist[12], dim_vary, DIM = dim, /REC_VARY, $
/ZVARIABLE)

cdf_attput, fileid, 'FIELDNAM',     varid, varlist[12],    /ZVARIABLE
cdf_attput, fileid, 'FORMAT',       varid, 'F15.7',        /ZVARIABLE
cdf_attput, fileid, 'LABLAXIS',     varid, varlist[12],    /ZVARIABLE
cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
cdf_attput, fileid, 'FILLVAL',      varid, -1.e31,         /ZVARIABLE
cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

cdf_attput, fileid, 'VALIDMIN', 'pa', -180,           /ZVARIABLE
;cdf_attput, fileid, 'VALIDMIN', 'pa', 0,              /ZVARIABLE
cdf_attput, fileid, 'VALIDMAX', 'pa', 180,            /ZVARIABLE
cdf_attput, fileid, 'SCALEMIN', 'pa', 0,              /ZVARIABLE
cdf_attput, fileid, 'SCALEMAX', 'pa', 180,            /ZVARIABLE
cdf_attput, fileid, 'UNITS',    'pa', 'degrees',      /ZVARIABLE
cdf_attput, fileid, 'CATDESC',  'pa', 'Pitch Angle',  /ZVARIABLE
cdf_attput, fileid, 'DEPEND_0', 'pa', 'epoch',        /ZVARIABLE

cdf_varput, fileid, 'pa', data.pa*!radeg

; *** d_pa -- Pitch Angle Width ***
dim_vary = [1, 1]
dim = [64, 16]
varid = cdf_varcreate(fileid, varlist[13], dim_vary, DIM = dim, /REC_VARY, $
/ZVARIABLE)

cdf_attput, fileid, 'FIELDNAM',     varid, varlist[13],    /ZVARIABLE
cdf_attput, fileid, 'FORMAT',       varid, 'F15.7',        /ZVARIABLE
cdf_attput, fileid, 'LABLAXIS',     varid, varlist[13],    /ZVARIABLE
cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
cdf_attput, fileid, 'FILLVAL',      varid, -1.e31,         /ZVARIABLE
cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

cdf_attput, fileid, 'VALIDMIN', 'd_pa', -180,                /ZVARIABLE
;cdf_attput, fileid, 'VALIDMIN', 'd_pa', -0,                  /ZVARIABLE
cdf_attput, fileid, 'VALIDMAX', 'd_pa', 180,                 /ZVARIABLE
cdf_attput, fileid, 'SCALEMIN', 'd_pa', 0,                   /ZVARIABLE
cdf_attput, fileid, 'SCALEMAX', 'd_pa', 180,                 /ZVARIABLE
cdf_attput, fileid, 'UNITS',    'd_pa', 'degrees',           /ZVARIABLE
cdf_attput, fileid, 'CATDESC',  'd_pa', 'Pitch Angle Width', /ZVARIABLE
cdf_attput, fileid, 'DEPEND_0', 'd_pa', 'epoch',             /ZVARIABLE

cdf_varput, fileid, 'd_pa', data.dpa*!radeg

; *** g_pa -- Relative Sensitivity as a Function of Pitch Angle ***
dim_vary = [1, 1]
dim = [64, 16]
varid = cdf_varcreate(fileid, varlist[14], dim_vary, DIM = dim, /REC_VARY, $
/ZVARIABLE)

cdf_attput, fileid, 'FIELDNAM',     varid, varlist[14],    /ZVARIABLE
cdf_attput, fileid, 'FORMAT',       varid, 'F15.7',        /ZVARIABLE
cdf_attput, fileid, 'LABLAXIS',     varid, varlist[14],    /ZVARIABLE
cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
cdf_attput, fileid, 'FILLVAL',      varid, -1.e31,         /ZVARIABLE
cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

cdf_attput, fileid, 'VALIDMIN', 'g_pa', 0, /ZVARIABLE
cdf_attput, fileid, 'VALIDMAX', 'g_pa', 2, /ZVARIABLE
cdf_attput, fileid, 'SCALEMIN', 'g_pa', 0, /ZVARIABLE
cdf_attput, fileid, 'SCALEMAX', 'g_pa', 2, /ZVARIABLE
cdf_attput, fileid, 'CATDESC',  'g_pa', $
  'Relative sensitivity as a function of pitch angle', /ZVARIABLE
cdf_attput, fileid, 'DEPEND_0', 'g_pa', 'epoch', /ZVARIABLE

; for each data point, for each energy, normalize data.eff across pa
dum_g_pa = fltarr(64, 16, nrec)
avg_eff = total(data.eff, 2)/16. ; 16 = n_pa ; [64, nrec]
;t = systime(1)
for i = 0l, nrec-1 do $ 
  for j = 0, 63 do $
    dum_g_pa[j, *, i] = data[i].eff[j, *]/avg_eff[j, i]
;print, systime(1) - t

cdf_varput, fileid, 'g_pa', dum_g_pa

; *** b_Azim -- Magnetic Field Azimuth ***
varid = cdf_varcreate(fileid, varlist[15], /REC_VARY, /ZVARIABLE)

cdf_attput, fileid, 'FIELDNAM',     varid, varlist[15],    /ZVARIABLE
cdf_attput, fileid, 'FORMAT',       varid, 'F15.7',        /ZVARIABLE
cdf_attput, fileid, 'LABLAXIS',     varid, varlist[15],    /ZVARIABLE
cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
cdf_attput, fileid, 'FILLVAL',      varid, -1.e31,         /ZVARIABLE
cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

cdf_attput, fileid, 'VALIDMIN', 'b_azim', 0,         /ZVARIABLE
cdf_attput, fileid, 'VALIDMAX', 'b_azim', 360,       /ZVARIABLE
cdf_attput, fileid, 'SCALEMIN', 'b_azim', 0,         /ZVARIABLE
cdf_attput, fileid, 'SCALEMAX', 'b_azim', 360,       /ZVARIABLE
cdf_attput, fileid, 'UNITS',    'b_azim', 'degrees', /ZVARIABLE
cdf_attput, fileid, 'CATDESC',  'b_azim', $
  'Magnetic field azimuth in instrument coordiantes', /ZVARIABLE
cdf_attput, fileid, 'DEPEND_0', 'b_azim', 'epoch',   /ZVARIABLE

cdf_varput, fileid, 'b_azim', data.Baz*!radeg

; *** b_elev -- Magnetic Field Elevation ***
varid = cdf_varcreate(fileid, varlist[16], /REC_VARY, /ZVARIABLE)

cdf_attput, fileid, 'FIELDNAM',     varid, varlist[16],    /ZVARIABLE
cdf_attput, fileid, 'FORMAT',       varid, 'F15.7',        /ZVARIABLE
cdf_attput, fileid, 'LABLAXIS',     varid, varlist[16],    /ZVARIABLE
cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
cdf_attput, fileid, 'FILLVAL',      varid, -1.e31,         /ZVARIABLE
cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

cdf_attput, fileid, 'VALIDMIN', 'b_elev', -180,      /ZVARIABLE
cdf_attput, fileid, 'VALIDMAX', 'b_elev', 180,       /ZVARIABLE
cdf_attput, fileid, 'SCALEMIN', 'b_elev', -90,       /ZVARIABLE
cdf_attput, fileid, 'SCALEMAX', 'b_elev', -90,       /ZVARIABLE
cdf_attput, fileid, 'UNITS',    'b_elev', 'degrees', /ZVARIABLE
cdf_attput, fileid, 'CATDESC',  'b_elev', $
  'Magnetic field elevation in instrument coordiantes', /ZVARIABLE
cdf_attput, fileid, 'DEPEND_0', 'b_elev', 'epoch',   /ZVARIABLE

cdf_varput, fileid, 'b_elev', data.Bel*!radeg

; *** num_dists -- Number of Distributions ***
varid = cdf_varcreate(fileid, varlist[17], /CDF_INT4, /REC_NOVARY, /ZVARIABLE)

cdf_attput, fileid, 'FIELDNAM',     varid, varlist[17],    /ZVARIABLE
;cdf_attput, fileid, 'FORMAT',       varid, 'I7',           /ZVARIABLE
cdf_attput, fileid, 'FORMAT',       varid, 'I12',          /ZVARIABLE
cdf_attput, fileid, 'LABLAXIS',     varid, varlist[17],    /ZVARIABLE
cdf_attput, fileid, 'VAR_TYPE',     varid, 'support_data', /ZVARIABLE
;cdf_attput, fileid, 'FILLVAL',      varid, -32768,         /ZVARIABLE
cdf_attput, fileid, 'FILLVAL',      varid, -2147483648,    /ZVARIABLE
cdf_attput, fileid, 'DISPLAY_TYPE', varid, 'time_series',  /ZVARIABLE

cdf_attput, fileid, 'VALIDMIN', 'num_dists', 0,     /ZVARIABLE
cdf_attput, fileid, 'VALIDMAX', 'num_dists', 43200, /ZVARIABLE
cdf_attput, fileid, 'SCALEMIN', 'num_dists', 0,     /ZVARIABLE
cdf_attput, fileid, 'SCALEMAX', 'num_dists', 43200, /ZVARIABLE
cdf_attput, fileid, 'CATDESC',  'num_dists', $
  'Number of distributions in file', /ZVARIABLE

cdf_varput, fileid, 'num_dists', nrec

cdf_close,fileid

; compression, and md5
mvn_l2file_compress, file

;Delete old files, jmm, 2014-11-14, include md5's, jmm, 2014-11-25
if (nfiles Gt 0) then begin
   for j = 0, nfiles-1 do begin
      file_delete, file_list[j]
      md5j = file_dirname(file_list[j])+'/'+$
             file_basename(file_list[j], '.cdf')+'.md5'
      if(keyword_set(file_search(md5j))) then file_delete, md5j
   endfor
endif

end
