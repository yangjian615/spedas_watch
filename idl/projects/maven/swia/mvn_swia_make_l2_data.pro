;+
;PROCEDURE: 
;	MVN_SWIA_MAKE_L2_DATA
;PURPOSE: 
;	Routine to load SWIA Level 0 data from a file and make Level 2 data files
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	MVN_SWIA_MAKE_L2_DATA, STARTDATE = STARTDATE, DAYS = DAYS, VERSION = VERSION, REVISION = REVISION, TYPE = TYPE
;INPUTS:
;KEYWORDS:
;	STARTDATE: Starting date to process
;	DAYS: Number of days to process
;	VERSION: Software version number to put in file (default '000')
;	REVISION: Data version number to put in file (default '000')
;	TYPE: 'svy' or 'arc' (default = 'svy')
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2014-08-29 11:31:03 -0700 (Fri, 29 Aug 2014) $
; $LastChangedRevision: 15724 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_make_l2_data.pro $
;
;-


pro mvn_swia_make_l2_data, startdate = startdate, days = days,version = version, revision = revision, type = type


compile_opt idl2

common mvn_swia_data

if not keyword_set(version) then version = '000'
if not keyword_set(revision) then revision = '000'
if not keyword_set(type) then type = 'svy'


if type eq 'arc' then archive = 1 else archive = 0

if type eq 'arc' then ftype = 'all' else ftype = 'svy'

opath = '/disks/data/maven/data/sci/swi/l2/'

date = startdate


ct0 = 0.d
ft0 = 0.d
cat0 = 0.d
fat0 = 0.d
mt0 = 0.d
st0 = 0.d
newc = 0
newf = 0
newca= 0
newfa= 0
news = 0
newm = 0

for i = 0,days-1 do begin

 	 date0 = strmid(time_string(date, format=6), 0, 8)
	  yyyy = strmid(date0, 0, 4)
	  mmmm = strmid(date0, 4, 2)
	  dddd = strmid(date0, 6, 2)
	  ppp = mvn_file_source()


	filex = mvn_l0_db2file(date,l0_file_type = ftype,l0_file_path='/disks/data/maven/data/sci/pfp/l0/')
	
	if filex ne '' then mvn_swia_load_l0_data,filex,/tplot,/sync,qlevel = 0.0001
	
	if n_elements(swics) gt 0 then begin
		if swics[0].time_unix ne ct0 then begin
			ct0 = swics[0].time_unix
			newc = 1
		endif else newc = 0
	endif
	
	if n_elements(swifs) gt 0 then begin
		if swifs[0].time_unix ne ft0 then begin
			ft0 = swifs[0].time_unix
			newf = 1
		endif else newf = 0
	endif
	
	if n_elements(swica) gt 0 then begin
		if swica[0].time_unix ne cat0 then begin
			cat0 = swica[0].time_unix
			newca = 1
		endif else newca = 0
	endif
	
	if n_elements(swifa) gt 0 then begin
		if swifa[0].time_unix ne fat0 then begin
			fat0 = swifa[0].time_unix
			newfa = 1
		endif else newfa = 0
	endif
	
	if type eq 'arc' then begin
		newc = newca
		newf = newfa
	endif
	
	if n_elements(swim) gt 0 then begin
		if swim[0].time_unix ne mt0 then begin
			mt0 = swim[0].time_unix
			newm = 1
		endif else newm = 0
	endif
	
	if n_elements(swis) gt 0 then begin
		if swis[0].time_unix ne st0 then begin
			st0 = swis[0].time_unix
			news = 1
		endif else news = 0
	endif
		
	if newc then mvn_swia_make_swic_cdf,archive = archive,data_version='0',file = opath+yyyy+'/'+mmmm+'/mvn_swi_l2_coarse'+type+'3d_'+yyyy+mmmm+dddd+'_v'+version+'_r'+revision+'.cdf'
	if newf then mvn_swia_make_swif_cdf,archive = archive,data_version='0',file = opath+yyyy+'/'+mmmm+'/mvn_swi_l2_fine'+type+'3d_'+yyyy+mmmm+dddd+'_v'+version+'_r'+revision+'.cdf'

	if type eq 'svy' then begin
		mvn_swia_inst2mso
		if news then mvn_swia_make_swis_cdf,data_version='0',file = opath+yyyy+'/'+mmmm+'/mvn_swi_l2_onboardsvyspec_'+yyyy+mmmm+dddd+'_v'+version+'_r'+revision+'.cdf'
		if newm then mvn_swia_make_swim_cdf,data_version='0',file = opath+yyyy+'/'+mmmm+'/mvn_swi_l2_onboardsvymom_'+yyyy+mmmm+dddd+'_v'+version+'_r'+revision+'.cdf'
	endif
	
	date = time_string(time_double(date)+24.*3600)
endfor


end