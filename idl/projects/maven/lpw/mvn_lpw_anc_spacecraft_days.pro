
;+
;pro mvn_lpw_anc_spacecraft_days, unix_in, not_quiet=not_quiet
;
;PROCEDURE:   mvn_lpw_anc_spacecraft
;PURPOSE:
; Routine to determine MAVEN pointing and position using the SPICE kernels. 
; Routine determines angle between MAVEN x,y,z axes and the Sun.
; Routine gets MAVEN and Sun pointing directions in MAVEN spacecraft frame. 
; SPICE is required to run this routine.
; 
; This routine is separate from the pipeline. It can take timestamps across multiple days. It will call upon Davin's SSL software to
; search for the correct kernels covering these dates, find them, and load them. Tplot variables will be created.
; 
;
;USAGE:
; mvn_lpw_cruciform, unix_in
; 
;INPUTS:
;              
;- unix_in: a dblarr of unix times for which attitude information is to be determined for. Routine will automatically check if pointing info
;           is available at each of these time steps, and skip the SPICE routines if not, to avoid crashes. Skipped points appear as nans in the 
;           produced tplot variables.
;
;
;OUTPUTS:
;Tplot variables of the following: 
;
;mvn_lpw_att_mso: pointing vectors for MAVEN x,y,z axes in MSO frame. X,Y,Z vector for each MAVEN axis = 9 in total.
;
;mvn_lpw_pos_mso: MAVEN position in MSO frame. X, Y, Z co-ords, in km.
;
;mvn_lpw_vel_mso MAVEN velocity in MSO frame. Vx, Vy, Vz co-ords, in km/s
;
;mvn_lpw_att_J2000: Pointing for MAVEN x,y,z axes in J2000 frame. X, Y, Z vector for each MAVEN axis = 9 in total.
;
;mvn_lpw_angles: Two entries: 1): Angular offset between MAVEN z axis and Sun look direction. 2) Clock angle between Sun and MAVEN X axis. Both in degrees.
;
;mvn_lpw_abs_angle_z: Absolute angle between MAVEN z axis vector and Sun look direction vector, in degrees.
;
;mvn_lpw_sun_pos_j2000: Sun position in J2000. X, Y, Z in km.
;
;mvn_lpw_pos_J2000: MAVEN position in J2000. X, Y, Z in km.
;
;mvn_lpw_vel_J2000: MAVEN velocity in J2000, Vx, Vy, Vz in km/s.
;                                                      
;                                                      
;KEYWORDS:
;Setting /not_quiet will plot mvn_abs_angles_z and the offset between MAVEN z axis and the Sun (used more for checking the routine worked).
;
;NOTE: even though kernel_dir is a key word it must still be set. See inputs above.
;
;CREATED BY:   Chris Fowler April 16th 2014
;FILE: 
;VERSION:   2.0
;LAST MODIFICATION: 
;April 17th 2014 CF added kernel_dir to inputs, outputs now saved as tplot variables. TO DO: add dlimit and limit fields to tplot variables.
;April 23rd 2014 CF added a check to make sure we have ck kernel pointing before trying to get the rotation matrix, to avoid crashes. Also added
;                   et_time as an input, which is needed for use with SPICE routines.
;April 24th 2014 CF added mvn_lpw_pos_J2000, mvn_lpw_vel_J2000
;April 28/29th 2014 CF added checks to make sure there is ck and spk info before running spice. This avoids crashes. Kernels now automatically loaded
;                      from the SPICE wrapper.
;May 16th 2014 CF: Switched to Davin's routines which call upon SPICE. Mine are commented out here. Fixed bug so routine will check for spk and ck
;                  coverage before attmepting to use SPICE, which causes it to crash if no coverage is present.
;May 27th 2014 CF: edited routine to mvn-lpw-anc-spacecraft-days, to accept unix_in over multiple days.                  
;140718 clean up for check out L. Andersson
;-
;=================

pro mvn_lpw_anc_spacecraft_days, unix_in, not_quiet=not_quiet

;Load kernels:
scid = -202  ;MAVEN s/c ID for SPICE
kernel_version = 'anc_spacecraft_days_ver V2.0'   ;needed for dlimits, add loaded kernels to it
sl = path_sep()  ;/ for unix, \ for Windows

;Make sure unix_in is dblarr:
if size(unix_in, /type) ne 5 then begin
    print, "#######################"
    print, "WARNING: unix_in must be a double array of UNIX times."
    print, "#######################"
    retall
endif

;===================
;---Find kernels----
;===================
;This section is different to mvn-lpw-anc-spacecraft. Here, we find kernels for the entered date range, using Davin's routines:
nele_unix_in = n_elements(unix_in)  ;number of entered unix times
t1 = unix_in[0]  ;start and end times, UNIX
t2 = unix_in[nele_unix_in-1]

          ;This section copied from mvn-lpw-load:
          tt = mvn_spice_kernels(trange = [t1,t2])
          
          ;tt contains the names of all SPICE kernels regardless of the type (ck, pck, lsk, etc). For now, we need ck, tls, spk, sclk. Remove files which
          ;don't contain any of these letters. Then, need to laod kernels in the correct order, which is tt[0] => tt[last].
          nele_tt = n_elements(tt)  ;number of kernels found
          kernels = ['remove_first_string_entry_later']     ;#####
          for aa = 0, nele_tt - 1 do begin
              if (strpos(tt[aa], sl+'ck') ne -1) and (strpos(tt[aa], '_*_') eq -1) then kernels = [kernels, tt[aa]]  ;look for the kernel type, and make sure there's no
              if (strpos(tt[aa], sl+'pck') ne -1) and (strpos(tt[aa], '_*_') eq -1) then kernels = [kernels, tt[aa]] ;'_*_' in the name as this means not found. If present,
              if (strpos(tt[aa], sl+'lsk') ne -1) and (strpos(tt[aa], '_*_') eq -1) then kernels = [kernels, tt[aa]] ;append to kernels.
              if (strpos(tt[aa], sl+'spk') ne -1) and (strpos(tt[aa], '_*_') eq -1) then kernels = [kernels, tt[aa]]  
              if (strpos(tt[aa], sl+'sclk') ne -1) and (strpos(tt[aa], '_*_') eq -1) then kernels = [kernels, tt[aa]] 
              if (strpos(tt[aa], sl+'fk') ne -1) and (strpos(tt[aa], '_*_') eq -1) then kernels = [kernels, tt[aa]]  
              if (strpos(tt[aa], 'maven_v04.tf') ne -1) and (strpos(tt[aa], '_*_') eq -1) then kernels = [kernels, tt[aa]]  ;Davin has latest frame file at SSL
              ;### As .tf file is added manually by Davin, sl is for unix. Windows can use this for directories, but IDL can't match it when string searching
              ;so don't include here.
          endfor
          
          ;Remove first entry of array kernels, as this was just a dummy to set up the array:
          IF n_elements(kernels) GT 1 THEN BEGIN
              nele_k = n_elements(kernels)
              kernels = kernels[1:nele_k-1]  ;get all but first entry
          ENDIF ELSE BEGIN
              print, "#### WARNING ####: No kernels found. Is date outside of MAVEN mission timeline?"
              return
          ENDELSE

          ;Store kernels into the usual tplot variable, this will replace the existing one:
          utc_in = time_string(t1)+' : '+time_string(t2)
                        store_data, 'mvn_lpw_load_kernel_files', data={x:1., y:1.}, dlimit={Kernel_files: kernels, $
                                        Purpose: "Directories to kernel files needed for UTC date "+utc_in, $
                                        Notes: "Load in order first entry to last entry to ensure correct coverage"} 

;======================
;---Kernel directory---
;======================
;The default will be to use the directory as set up by Davin's routines. As this will probably be on the server, there will also be an option
;to work offline. This will be set in mvn_lpw_anc_wrapper. 
;======================
;Code for automatically loading found kernels:
;Get kernel info from tplot variables and load:
tplotnames = tnames()  ;list of tplot variables in memory
if total(strmatch(tplotnames, 'mvn_lpw_load_kernel_files')) eq 1 then begin  ;found kernel tplot variable
    get_data, 'mvn_lpw_load_kernel_files', data=data_kernels, dlimit=dl_kernels  ;dl.kernels contains the kernel names
    nele_kernels = n_elements(dl_kernels.Kernel_files)  ;number of kernels to load
    loaded_kernels_arr=strarr(nele_kernels)  ;string array
    loaded_kernels='';dummy string
    for aa = 0, nele_kernels-1 do begin
        cspice_furnsh, dl_kernels.Kernel_files[aa]  ;load all kernels for now
        
        ;Extract just kernel name and remove directory:
        nind = strpos(dl_kernels.Kernel_files[aa], sl, /reverse_search)  ;nind is the indice of the last '/' in the directory before the kernel name
        lenstr = strlen(dl_kernels.Kernel_files[aa])  ;length of the string directory
        kname = strmid(dl_kernels.Kernel_files[aa], nind+1, lenstr-nind)  ;extract just the kernel name
        loaded_kernels_arr[aa] = kname  ;copy kernels as a string   
        loaded_kernels = loaded_kernels + " # " + kname  ;one long string so can save into dlimit
        kernel_version = kernel_version + " # " + kname  ;add loaded kernel to dlimit field 
    endfor  ;over aa
endif else begin
      print, "####################"
      print, "WARNING: No SPICE kernels found which match this data set.
      print, "Check there are kernels available online for this data.
      print, "If they are present, check the kernel finder to see if it's finding them."
      print, "Did you ask IDL to not use SPICE?"
      print, "####################"
      retall
endelse


;==================
;Check that we have spk (planet), ck, lsk, fk, sclk kernels loaded for attitude information:
spk_p = 0  ;planets (MAVEN below)
ck = 0 ;pointing
fk = 0  ;frame info
lsk = 0  ;leapsecs
sclk = 0 ;MAVEN clock
for hh = 0, nele_kernels-1 do begin
    if stregex(dl_kernels.Kernel_files[hh], sl+'de[^bsp]*bsp', /boolean) eq 1 then spk_p += 1  ;add one to counter
    if stregex(dl_kernels.Kernel_files[hh], sl+'ck', /boolean) eq 1 then ck += 1
    if stregex(dl_kernels.Kernel_files[hh], 'maven_v[^tf]*tf', /boolean) eq 1 then fk += 1
    if stregex(dl_kernels.Kernel_files[hh], sl+'lsk', /boolean) eq 1 then lsk += 1
    if stregex(dl_kernels.Kernel_files[hh], sl+'sclk', /boolean) eq 1 then sclk += 1
endfor

if (spk_p eq 0) then begin
    print, "#### WARNING ####: No planetary ephemeris kernel loaded: check for "+sl+"spk"+sl+"de???.bsp file."
    retall
endif
if (ck eq 0) then begin
    print, "#### WARNING ####: No pointing kernels loaded: check for "+sl+"ck"+sl+"... files."
    retall
endif
if (fk eq 0) then begin
    print, "#### WARNING ####: No frame kernels loaded: check for "+sl+"fk"+sl+"... files."
    retall
endif
if (lsk eq 0) then begin
    print, "#### WARNING ####: No leapsecond kernel loaded: check for "+sl+"lsk"+sl+"... files."
    retall
endif
if (sclk eq 0) then begin
    print, "#### WARNING ####: No spacecraft clock kernel loaded: check for "+sl+"sclk"+sl+"... files."
    retall
endif
;MAVEN spk position kernels are checked for below.
;==================
;Check whether the times fall within kernel coverage for the SPK files:

;Get spk kernel names to feed into routine:
;Search for the spk kernel files, and feed them into here, as we need the names so the routine knows which ones to check:
;Look for 'trj_c' in the names, as these are the MAVEN position kernels (be careful not to include planets for example)
kernels_to_check = ['']  ;empty array to fill in

for bb = 0, nele_kernels-1 do begin
    if stregex(dl_kernels.Kernel_files[bb], 'trj_c', /boolean) eq 1 then kernels_to_check = [kernels_to_check, dl_kernels.Kernel_files[bb]] ;add to list if an spk kernel
endfor  ;over bb
if n_elements(kernels_to_check) gt 1 then kernels_to_check = kernels_to_check[1:n_elements(kernels_to_check)-1] else begin  ;remove first '' from array
      print, "#### WARNING ####: No spk kernels loaded. Check these are loaded. Exiting."
      retall
endelse  

spkcov = mvn_lpw_anc_covtest(unix_in, kernels_to_check)  ;for now use unix times, may change to ET.   ### give spk kernel names here!
if min(spkcov) eq 1 then spk_coverage = 'all' else begin 
    spk_coverage = 'some'
    print, "### WARNING ###: Position (spk) information not available for ", n_elements(where(spkcov) eq 0), " data point(s)."
    print, "These are 'nans' within the tplot attitude information variables."
endelse
;spkcov is an array nele long. 1 means timestep is covered, 0 means timestep is outside of coverage.

;There is a ck check later on, it requires encoded time so is below:

;=======================
;---Checking complete---
;=======================

;Get dlimit and limit info from a tplot variable:
;tnames() is a string array containing the names of all tplot variables in memory. Check this exists, then grab dlimit and limit info 
;from the first variable. This means we don't need to feed in instrument constants. The attitude variable specific fields will be edited 
;as that variable is stored.
tplotnames = tnames()
;If there are no tplot variables stored then tplotnames is the string ''. If there are tplot variables stored tplotnames is either 'tplotname' or
;a string array of tplot names.
if tplotnames[0] ne '' and n_elements(tplotnames) gt 2 then begin  ;if we have tplot variables
    get_data, tplotnames[2], dlimit=dl, limit=ll  ;doesn't matter which variable for now, we just want the CDF fields from this which are identical
                                                  ;for all variables. But, kernel and orbit info are in first two tplot variables
    cdf_istp = strarr(15)  ;copy across the fields from dlimit:
    cdf_istp[0] = dl.Source_name
    cdf_istp[1] = dl.Discipline
    cdf_istp[2] = dl.Data_type
    cdf_istp[3] = dl.Data_version
    cdf_istp[4] = dl.PI_name
    cdf_istp[5] = dl.PI_affiliation
    cdf_istp[6] = dl.TEXT
    cdf_istp[7] = dl.Instrument_type
    cdf_istp[8] = dl.Mission_group
    cdf_istp[9] = dl.Logical_source
    cdf_istp[10] = dl.Logical_source_description
    cdf_istp[11] = dl.Descriptor
    cdf_istp[12] = dl.Logical_file_ID
    cdf_istp[13] = dl.Rules_of_use
    cdf_istp[14] = dl.Project
    t_epoch = dl.t_epoch  
    L0_datafile = dl.L0_datafile                                            
endif else begin
    print, "################"
    print, "WARNING: Some tplot dlimit fields may be missing. Check at least one tplot variable"
    print, "is in IDL memory before running mvn_lpw_spacecraft."
    print, "################"
    ;Create a dummy array containing blank strings so routine won't crash later:
    cdf_istp = strarr(15) + 'dlimit info unavailable'
    t_epoch = 'dlimit info unavailable'
    L0_datafile = 'dlimit info unavailable'
endelse
;==================
;Convert UNIX times in to et for use with SPICE:
nele = n_elements(unix_in)  ;number of times entered

print, "Determining MAVEN pointing for ", nele, " data points..."

;=============================
;---- Convert UNIX to UTC ----
;=============================
;Davin's routines all require UTC as input, use Berkeley routines here to convert from UNIX to UTC:

et_time = time_ephemeris(unix_in, /ut2et)  ;convert unix to et

cspice_et2utc, et_time, 'ISOC', 6, utc_time  ;convert et to utc time  ### LSK file needed here ###

;Convert ET times to encoded sclk for use with cspice_ckgp later
cspice_sce2c, -202, et_time, enc_time

;CK check:
nele_in = n_elements(unix_in)
ck_check = fltarr(nele_in)
for aa = 0, nele_in-1 do begin
    cspice_ckgp, -202000, enc_time[aa], 0.0, 'MAVEN_SPACECRAFT', mat1, clk, found
    ck_check[aa] = found  ;0 if coverage exists, 1 if not
endfor
if min(ck_check) eq 1 then ck_coverage = 'all' else begin
    ck_coverage = 'some'
    print, "### WARNING ###: Pointing information (ck) not available for ", n_elements(where(ck_check eq 0)), " data point(s)."
endelse
    ;tick_time =strarr(nele)
    ;for aa = 0, nele-1 do begin   ;to test if we get back the sclk string, which we do
    ;    cspice_sce2s, -202, et_time[aa], tick_t
    ;    tick_time[aa] = tick_t
    ;endfor

;============
;Get standard information for other dlimit fields:
;Break up UTC time in a dbl number, just first and last times:
   aa= strsplit(utc_time[0],'T',/extract)  ;first time
   bb= strsplit(aa[0],'-',/extract)
   cc= strsplit(aa[1],':',/extract)
   utc_time1 =10000000000.0 * double( bb[0]) + 100000000.0 * double(bb[1]) + 1000000.0 * double(bb[2]) + 10000.0 *double(cc[0]) + 100.0 * double(cc[1]) +double(cc[2]) 
   aa= strsplit(utc_time[nele-1],'T',/extract)  ;last time
   bb= strsplit(aa[0],'-',/extract)
   cc= strsplit(aa[1],':',/extract)
   utc_time2 =10000000000.0 * double( bb[0]) + 100000000.0 * double(bb[1]) + 1000000.0 * double(bb[2]) + 10000.0 *double(cc[0]) + 100.0 * double(cc[1]) +double(cc[2]) 

;Check these times are predicted or reconstructed:
time_check = mvn_lpw_anc_spice_time_check(et_time[nele-1])  ;we check the last time. If this is predicted, we must run entire orbit later. ## fix this routine


time_start = [unix_in[0], utc_time1, et_time[0]]
time_end = [unix_in[nele-1], utc_time2, et_time[nele-1]]
time_field = ['UNIX time', 'UTC time', 'ET time']
spice_used = 'SPICE used'
str_xtitle = 'Time (UNIX)'+time_check   ;### predicted or reconstructed?
today_date = systime(0)
;===========

;########
;Now et_time and utc_time contain the time steps of input data points, which can be used with Davins SPICE routines.
;########
;Now get MAVEN attitude / orientation info here

mvn_x = [1.d, 0.d, 0.d]  ;look directions for MAVEN s/c
mvn_y = [0.d, 1.d, 0.d]
mvn_z = [0.d, 0.d, 1.d]

;=====
;==1==
;=====
;Absolute angle between Sun and MAVEN
;Get Sun position relative to MAVEN in s/c frame:
;Information needed:
target = 'Sun'
frame    = 'MAVEN_SPACECRAFT'
abcorr   = 'LT+S'  ;correct for light travel time and something
observer = 'MAVEN'  

if (spk_coverage eq 'all') and (ck_coverage eq 'all') then state = spice_body_pos(target, observer, utc=utc_time, frame=frame, abcorr=abcorr) else begin 
;if spk_coverage eq 'all' then cspice_spkpos, target, et_time, frame, abcorr, observer, state, ltime else begin ;state contains R and V [0:5], ltime = light time between observer and object
    state = dblarr(3,nele)  ;must fill this rotation matrix in one time step at a time now. Here time goes in y axis for spice routines
    for aa = 0, nele-1 do begin  ;do each time point individually
          if (spkcov[aa] eq 1) and (ck_check[aa] eq 1) then state_temp = spice_body_pos(target, observer, utc=utc_time[aa], frame=frame, abcorr=abcorr) else state_temp=[!values.f_nan, !values.f_nan, !values.f_nan]
          ;if spkcov[aa] eq 1 then cspice_spkpos, target, et_time[aa], frame, abcorr, observer, state_temp, ltime else state_temp=[!values.f_nan, !values.f_nan, !values.f_nan]
          ;if we don't have coverage, use nans instead
          state[0,aa] = state_temp[0]  ;add time step to overall array
          state[1,aa] = state_temp[1]
          state[2,aa] = state_temp[2]
    endfor
endelse

;state = spice_body_pos(target, observer, utc=utc_time, frame=frame, abcorr=abcorr)  ;Suns position, from MAVEN, in S/C frame

;Extract Sun position, in s/c frame:
pos_s = dblarr(nele,3)
pos_s[*,0] = state[0,*]  ;positions in km
pos_s[*,1] = state[1,*]
pos_s[*,2] = state[2,*]

;Divide Sun's position by it's magnitude to get it as a look vector from MAVEN:
sun_mag = dblarr(nele)
vector_sun = dblarr(nele,3)
mvn_abs_angles_z = dblarr(nele)   ;store absolute angle between Sun and MAVEN z axis.
;Get absolute angle between pointing vectors for MAVEN z axis (EUV boresight) (although this may not be useful)
;cos(theta) = a-dot-b / mag(a) * mag(b)          
mag_sun = 1.D  ;look vector therefore mag is one, as obtained above
mag_mvnz = 1.D  ;by definition this is one.
for aa = 0L, nele -1 do begin
    sun_mag[aa] = sqrt(pos_s[aa,0]^2 + pos_s[aa,1]^2 + pos_s[aa,2]^2)  ;magnitude for each time
    vector_sun[aa,*] = pos_s[aa,*] / sun_mag[aa]  ;divide position vector by magnitude to get look vector (total mag = 1)

    mvn_abs_angles_z[aa] = acos((mvn_z[0]*vector_sun[aa,0] + mvn_z[1]*vector_sun[aa,1] + mvn_z[2]*vector_sun[aa,2]) / (mag_sun * mag_mvnz)) * (180.D/!pi)   ;in degrees
endfor

                ;Store as tplot variable:
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'Project',                     cdf_istp[14], $                          
                   'Source_name',                 cdf_istp[0], $     ;Required for cdf production...
                   'Discipline',                  cdf_istp[1], $
                   'Var_type',                    'Data', $
                   'Data_type',                   cdf_istp[2] ,  $   
                   'Descriptor',                  cdf_istp[11], $                 
                   'Data_version',                cdf_istp[3], $ 
                   'PI_name',                     cdf_istp[4], $
                   'PI_affiliation',              cdf_istp[5], $
                   'TEXT',                        cdf_istp[6], $
                   'Instrument_type',             cdf_istp[7], $
                   'Mission_group',               cdf_istp[8], $
                   'Logical_file_ID',             cdf_istp[12], $
                   'Logical_source',              cdf_istp[9], $
                   'Logical_source_description',  cdf_istp[10], $ 
                   'Rules_of_use',                cdf_istp[13], $   
                   'MONOTON', 'INCREASE', $
                   'SCALEMIN', min(mvn_abs_angles_z), $
                   'SCALEMAX', max(mvn_abs_angles_z), $        ;..end of required for cdf production.
                   'generated_date'  ,     today_date, $ 
                   't_epoch'         ,     t_epoch, $
                   'Time_start'      ,     time_start, $
                   'Time_end'        ,     time_end, $
                   'Time_field'      ,     time_field, $
                   'SPICE_kernel_version', kernel_version, $
                   'SPICE_kernel_flag'      ,     spice_used, $                       
                   'L0_datafile'     ,     L0_datafile , $ 
                   'cal_vers'        ,     kernel_version ,$     
                   'cal_y_const1'    ,     loaded_kernels , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'SPICE kernels', $     
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[Degrees]');, $                     
                   ;'cal_v_const1'    ,     'PKT level::' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'zsubtitle'       ,     '[Attitude]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     1.2                      ,$    
                  'xtitle' ,        str_xtitle                   ,$   
                  'ytitle' ,        'mvn-abs_angles-z'                 ,$   
                  'yrange' ,        [0.9*min(mvn_abs_angles_z),1.1*max(mvn_abs_angles_z)] ,$   
                  'ystyle'  ,       1.                       ,$  
                  'labflag',        1, $
                  ;'ztitle' ,        'Z-title'                ,$   
                  ;'zrange' ,        [min(data.y),max(data.y)],$                        
                  ;'spec'            ,     1, $           
                  ;'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  ;'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  ;'xlim2'    ,      [min(data.x),max(data.x)], $          ;for plotting lpw pkt lab data
                  'noerrorbars', 1)   
               ;---------------------------------
               store_data, 'mvn_lpw_anc_abs_angle_z', data={x:unix_in, y:mvn_abs_angles_z}, dlimit=dlimit, limit=limit
                          
;=====
;==2==
;=====
offset = dblarr(nele,2)  ;store x,y offsets
;Get offset between MAVEN z axis and Sun, and clock angle from MAVEN X axis, in degrees:
mvn_angles = dblarr(nele,2)  ;array to store angles, first row is radius, second is angle from x axis, counter clockwise

;Plot x and y distances from Sun vector to check the pointing routines are working - should get a cross for the cruciform!
;Define the sun vector as the center:          
for aa = 0L, nele-1 do begin
    center = [vector_sun[aa,0], vector_sun[aa,1]]  ;make Sun vector the 'zero' position for this time step
    mvn_point_z = [mvn_z[0], mvn_z[1]]  ;x,y pointing for z axis on MAVEN
    offset[aa,*] = [[mvn_point_z[0] - center[0]], [mvn_point_z[1] - center[1]]]  ;get offset
    
    ;As co-ordinates are projected onto a 2D screen, we can get "radius angle" and angle from s/c x axis for the Sun vector.
    mvn_angles[aa,0] = acos(vector_sun[aa,2]) * (180.D/!pi)  ;in degrees. Use Sun z vector to get "radius displacement angle". If sun(z) = 1, this equals
                                                                 ;s/c z (also 1), so acos(1) = 0 degrees, which is correct!
    mvn_angles[aa,1] = atan(vector_sun[aa,1], vector_sun[aa,0]) * (180.D/!pi)  ;degrees, tan(y/x) to get angle from s/c x axis.  
endfor  ;over aa

ydata = dblarr(nele,2)
ydata[*,0] = mvn_angles[*,0]
ydata[*,1] = mvn_angles[*,1]
                ;Store as tplot variable:
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'Project',                     cdf_istp[14], $                          
                   'Source_name',                 cdf_istp[0], $     ;Required for cdf production...
                   'Discipline',                  cdf_istp[1], $
                   'Var_type',                    'Data', $
                   'Data_type',                   cdf_istp[2] ,  $   
                   'Descriptor',                  cdf_istp[11], $                 
                   'Data_version',                cdf_istp[3], $ 
                   'PI_name',                     cdf_istp[4], $
                   'PI_affiliation',              cdf_istp[5], $
                   'TEXT',                        cdf_istp[6], $
                   'Instrument_type',             cdf_istp[7], $
                   'Mission_group',               cdf_istp[8], $
                   'Logical_file_ID',             cdf_istp[12], $
                   'Logical_source',              cdf_istp[9], $
                   'Logical_source_description',  cdf_istp[10], $ 
                   'Rules_of_use',                cdf_istp[13], $   
                   'MONOTON', 'INCREASE', $
                   'SCALEMIN', min(mvn_angles), $
                   'SCALEMAX', max(mvn_angles), $        ;..end of required for cdf production.
                   'generated_date'  ,     today_date, $ 
                   't_epoch'         ,     t_epoch, $
                   'Time_start'      ,     time_start, $
                   'Time_end'        ,     time_end, $
                   'Time_field'      ,     time_field, $
                   'SPICE_kernel_version', kernel_version, $
                   'SPICE_kernel_flag'      ,     spice_used, $                       
                   'L0_datafile'     ,     L0_datafile , $ 
                   'cal_vers'        ,     kernel_version ,$     
                   'cal_y_const1'    ,     loaded_kernels , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'SPICE kernels', $     
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[Degrees]');, $                     
                   ;'cal_v_const1'    ,     'PKT level::' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'zsubtitle'       ,     '[Attitude]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     1.2                      ,$    
                  'xtitle' ,        str_xtitle                   ,$   
                  'ytitle' ,        'mvn-angles'                 ,$   
                  'yrange' ,        [1.1*min(mvn_angles),1.1*max(mvn_angles)] ,$   
                  'ystyle'  ,       1.                       ,$ 
                  'labels',         ['Angular_separation', 'Clock_angle'], $ 
                  'labflag',        1, $
                  ;'ztitle' ,        'Z-title'                ,$   
                  ;'zrange' ,        [min(data.y),max(data.y)],$                        
                  ;'spec'            ,     1, $           
                  ;'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  ;'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  ;'xlim2'    ,      [min(data.x),max(data.x)], $          ;for plotting lpw pkt lab data
                  'noerrorbars', 1)   
               ;---------------------------------
               store_data, 'mvn_lpw_anc_angles', data={x:unix_in, y:ydata}, dlimit=dlimit, limit=limit
               
;=====
;==3==
;=====
;Get Sun position in J2000:
target = 'Sun'
frame    = 'J2000'
abcorr   = 'LT+S'  ;correct for light travel time and something
observer = 'MAVEN'  

;cspice_spkpos, target, et_time, frame, abcorr, observer, state_j, ltime_j  ;state contains R and V [0:5], ltime = light time between observer and object

if (spk_coverage eq 'all') and (ck_coverage eq 'all') then state_j = spice_body_pos(target, observer, utc=utc_time, frame=frame, abcorr=abcorr) else begin   
;if spk_coverage eq 'all' then cspice_spkpos, target, et_time, frame, abcorr, observer, state_j, ltime else begin ;state contains R and V [0:5], ltime = light time between observer and object
    state_j = dblarr(3,nele)  ;must fill this rotation matrix in one time step at a time now. Here time goes in y axis for spice routines
    for aa = 0, nele-1 do begin  ;do each time point individually
          if (spkcov[aa] eq 1) and (ck_check[aa] eq 1) then state_temp = spice_body_pos(target, observer, utc=utc_time[aa], frame=frame, abcorr=abcorr) else state_temp=[!values.f_nan, !values.f_nan, !values.f_nan]
          ;if spkcov[aa] eq 1 then cspice_spkpos, target, et_time[aa], frame, abcorr, observer, state_temp, ltime else state_temp=[!values.f_nan, !values.f_nan, !values.f_nan]
          ;if we don't have coverage, use nans instead
          state_j[0,aa] = state_temp[0]  ;add time step to overall array
          state_j[1,aa] = state_temp[1]
          state_j[2,aa] = state_temp[2]
    endfor
endelse

;Extract Sun position and velocities in J2000:
sun_pos_j2000 = dblarr(nele,3)
sun_pos_j2000[*,0] = state_j[0,*]  ;in km
sun_pos_j2000[*,1] = state_j[1,*]
sun_pos_j2000[*,2] = state_j[2,*]

                ;Store as tplot variable:
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'Project',                     cdf_istp[14], $                          
                   'Source_name',                 cdf_istp[0], $     ;Required for cdf production...
                   'Discipline',                  cdf_istp[1], $
                   'Var_type',                    'Data', $
                   'Data_type',                   cdf_istp[2] ,  $   
                   'Descriptor',                  cdf_istp[11], $                 
                   'Data_version',                cdf_istp[3], $ 
                   'PI_name',                     cdf_istp[4], $
                   'PI_affiliation',              cdf_istp[5], $
                   'TEXT',                        cdf_istp[6], $
                   'Instrument_type',             cdf_istp[7], $
                   'Mission_group',               cdf_istp[8], $
                   'Logical_file_ID',             cdf_istp[12], $
                   'Logical_source',              cdf_istp[9], $
                   'Logical_source_description',  cdf_istp[10], $ 
                   'Rules_of_use',                cdf_istp[13], $   
                   'MONOTON', 'INCREASE', $
                   'SCALEMIN', min(sun_pos_j2000), $
                   'SCALEMAX', max(sun_pos_j2000), $        ;..end of required for cdf production.
                   'generated_date'  ,     today_date, $ 
                   't_epoch'         ,     t_epoch, $
                   'Time_start'      ,     time_start, $
                   'Time_end'        ,     time_end, $
                   'Time_field'      ,     time_field, $
                   'SPICE_kernel_version', kernel_version, $
                   'SPICE_kernel_flag'      ,     spice_used, $                       
                   'L0_datafile'     ,     L0_datafile , $ 
                   'cal_vers'        ,     kernel_version ,$     
                   'cal_y_const1'    ,     loaded_kernels , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'SPICE kernels', $     
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[km (J2000 frame)]');, $                     
                   ;'cal_v_const1'    ,     'PKT level::' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'zsubtitle'       ,     '[Attitude]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     1.2                      ,$    
                  'xtitle' ,        str_xtitle                   ,$   
                  'ytitle' ,        'Sun-pos_J2000'                 ,$   
                  'yrange' ,        [0.9*min(sun_pos_J2000),1.1*max(sun_pos_j2000)] ,$   
                  'ystyle'  ,       1.                       ,$
                  'labels',         ['X', 'Y', 'Z'], $  
                  'labflag',        1, $
                  ;'ztitle' ,        'Z-title'                ,$   
                  ;'zrange' ,        [min(data.y),max(data.y)],$                        
                  ;'spec'            ,     1, $           
                  ;'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  ;'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  ;'xlim2'    ,      [min(data.x),max(data.x)], $          ;for plotting lpw pkt lab data
                  'noerrorbars', 1)   
               ;---------------------------------
               store_data, 'mvn_lpw_anc_sun_pos_j2000', data={x:unix_in, y:sun_pos_j2000}, dlimit=dlimit, limit=limit

;========
;==4, 5==
;========
;MAVEN position J2000:
;Position:
target = 'MAVEN'
frame    = 'J2000'
abcorr   = 'LT+S'  ;correct for light travel time and something
observer = 'Sun' 

if (spk_coverage eq 'all') and (ck_coverage eq 'all') then state = spice_body_pos(target, observer, utc=utc_time, frame=frame, abcorr=abcorr) else begin  
;if spk_coverage eq 'all' then cspice_spkezr, target, et_time, frame, abcorr, observer, state, ltime else begin ;state contains R and V [0:5], ltime = light time between observer and object
    state = dblarr(3,nele)  ;must fill this rotation matrix in one time step at a time now. Here time goes in y axis for spice routines
    for aa = 0, nele-1 do begin  ;do each time point individually
          if (spkcov[aa] eq 1) and (ck_check[aa] eq 1) then cspice_spkezr, target, et_time[aa], frame, abcorr, observer, state_temp, ltime else state_temp=[!values.f_nan, !values.f_nan, !values.f_nan]
          ;if we don't have coverage, use nans instead
          state[0,aa] = state_temp[0]  ;add time step to overall array
          state[1,aa] = state_temp[1]
          state[2,aa] = state_temp[2]
    endfor
endelse

;cspice_spkezr, target, et_time, frame, abcorr, observer, state, ltime  ;state contains R and V [0:5], ltime = light time between observer and object

mvn_pos_j2000 = dblarr(nele,3)
mvn_vel_j2000 = dblarr(nele,3)
mvn_pos_j2000[*,0] = state[0,*]  ;positions in km
mvn_pos_j2000[*,1] = state[1,*]  ;positions in km
mvn_pos_j2000[*,2] = state[2,*]  ;positions in km    
;mvn_vel_j2000[*,0] = state[3,*]  ;velocities in km   ### Currently spice_body_pos doesn't return velocity
;mvn_vel_j2000[*,1] = state[4,*]  ;velocities in km
;mvn_vel_j2000[*,2] = state[5,*]  ;velocities in km
    
;mvn_pos_au = mvn_pos_mso / (1.496D8)   ;position in AU

                ;Store as tplot variable:
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'Project',                     cdf_istp[14], $                          
                   'Source_name',                 cdf_istp[0], $     ;Required for cdf production...
                   'Discipline',                  cdf_istp[1], $
                   'Var_type',                    'Data', $
                   'Data_type',                   cdf_istp[2] ,  $   
                   'Descriptor',                  cdf_istp[11], $                 
                   'Data_version',                cdf_istp[3], $ 
                   'PI_name',                     cdf_istp[4], $
                   'PI_affiliation',              cdf_istp[5], $
                   'TEXT',                        cdf_istp[6], $
                   'Instrument_type',             cdf_istp[7], $
                   'Mission_group',               cdf_istp[8], $
                   'Logical_file_ID',             cdf_istp[12], $
                   'Logical_source',              cdf_istp[9], $
                   'Logical_source_description',  cdf_istp[10], $ 
                   'Rules_of_use',                cdf_istp[13], $   
                   'MONOTON', 'INCREASE', $
                   'SCALEMIN', min(mvn_pos_j2000), $
                   'SCALEMAX', max(mvn_pos_j2000), $        ;..end of required for cdf production.
                   'generated_date'  ,     today_date, $ 
                   't_epoch'         ,     t_epoch, $
                   'Time_start'      ,     time_start, $
                   'Time_end'        ,     time_end, $
                   'Time_field'      ,     time_field, $
                   'SPICE_kernel_version', kernel_version, $
                   'SPICE_kernel_flag'      ,     spice_used, $                       
                   'L0_datafile'     ,     L0_datafile , $ 
                   'cal_vers'        ,     kernel_version ,$     
                   'cal_y_const1'    ,     loaded_kernels , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'SPICE kernels', $     
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[km (J2000 frame)]');, $                     
                   ;'cal_v_const1'    ,     'PKT level::' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'zsubtitle'       ,     '[Attitude]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     1.2                      ,$    
                  'xtitle' ,        str_xtitle                   ,$   
                  'ytitle' ,        'mvn-pos_(J2000-frame)'                 ,$   
                  'yrange' ,        [min(mvn_pos_j2000),max(mvn_pos_j2000)] ,$   
                  'ystyle'  ,       1.                       ,$ 
                  'labels',         ['X', 'Y', 'Z'], $ 
                  'labflag',        1, $
                  ;'ztitle' ,        'Z-title'                ,$   
                  ;'zrange' ,        [min(data.y),max(data.y)],$                        
                  ;'spec'            ,     1, $           
                  ;'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  ;'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  ;'xlim2'    ,      [min(data.x),max(data.x)], $          ;for plotting lpw pkt lab data
                  'noerrorbars', 1)   
               ;---------------------------------
               store_data, 'mvn_lpw_anc_pos_j2000', data={x:unix_in, y:mvn_pos_j2000}, dlimit=dlimit, limit=limit
               ;---------------------------------
               
                ;Store as tplot variable:
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'Project',                     cdf_istp[14], $                          
                   'Source_name',                 cdf_istp[0], $     ;Required for cdf production...
                   'Discipline',                  cdf_istp[1], $
                   'Var_type',                    'Data', $
                   'Data_type',                   cdf_istp[2] ,  $   
                   'Descriptor',                  cdf_istp[11], $                 
                   'Data_version',                cdf_istp[3], $ 
                   'PI_name',                     cdf_istp[4], $
                   'PI_affiliation',              cdf_istp[5], $
                   'TEXT',                        cdf_istp[6], $
                   'Instrument_type',             cdf_istp[7], $
                   'Mission_group',               cdf_istp[8], $
                   'Logical_file_ID',             cdf_istp[12], $
                   'Logical_source',              cdf_istp[9], $
                   'Logical_source_description',  cdf_istp[10], $ 
                   'Rules_of_use',                cdf_istp[13], $   
                   'MONOTON', 'INCREASE', $
                   'SCALEMIN', min(mvn_vel_j2000), $
                   'SCALEMAX', max(mvn_vel_j2000), $        ;..end of required for cdf production.
                   'generated_date'  ,     today_date, $ 
                   't_epoch'         ,     t_epoch, $
                   'Time_start'      ,     time_start, $
                   'Time_end'        ,     time_end, $
                   'Time_field'      ,     time_field, $
                   'SPICE_kernel_version', kernel_version, $
                   'SPICE_kernel_flag'      ,     spice_used, $                       
                   'L0_datafile'     ,     L0_datafile , $ 
                   'cal_vers'        ,     kernel_version ,$     
                   'cal_y_const1'    ,     loaded_kernels , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'SPICE kernels', $     
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[km/s (J2000 frame)]');, $                     
                   ;'cal_v_const1'    ,     'PKT level::' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'zsubtitle'       ,     '[Attitude]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     1.2                      ,$    
                  'xtitle' ,        str_xtitle                   ,$   
                  'ytitle' ,        'mvn-vel_(J2000-frame)'                 ,$   
                  'yrange' ,        [min(mvn_vel_j2000),max(mvn_vel_j2000)] ,$   
                  'ystyle'  ,       1.                       ,$ 
                  'labels',         ['Vx', 'Vy', 'Vz'], $ 
                  'labflag',        1, $
                  ;'ztitle' ,        'Z-title'                ,$   
                  ;'zrange' ,        [min(data.y),max(data.y)],$                        
                  ;'spec'            ,     1, $           
                  ;'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  ;'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  ;'xlim2'    ,      [min(data.x),max(data.x)], $          ;for plotting lpw pkt lab data
                  'noerrorbars', 1)   
               ;---------------------------------             
            ;   store_data, 'mvn_lpw_anc_vel_j2000', data={x:unix_in, y:mvn_vel_j2000}, dlimit=dlimit, limit=limit  ### need velocity added to Davin's spice routines
               ;---------------------------------

;========
;==6, 7==
;========
;MAVEN position and velocity in MSO frame:
;General info:  
frame    = 'MAVEN_MSO'
abcorr   = 'LT+S'
observer = 'Mars'
target = 'MAVEN'

if (spk_coverage eq 'all') and (ck_coverage eq 'all') then stateezr = spice_body_pos(target, observer, utc=utc_time, frame=frame, abcorr=abcorr) else begin
;if spk_coverage eq 'all' then cspice_spkezr, target, et_time, frame, abcorr, observer, stateezr, ltime else begin ;state contains R and V [0:5], ltime = light time between observer and object
    stateezr = dblarr(3,nele)  ;must fill this rotation matrix in one time step at a time now. Here time goes in y axis for spice routines
    for aa = 0, nele-1 do begin  ;do each time point individually          
          if (spkcov[aa] eq 1) and (ck_check[aa] eq 1) then state_temp = spice_body_pos(target, observer, utc=utc_time[aa], frame=frame, abcorr=abcorr) else state_temp=[!values.f_nan, !values.f_nan, !values.f_nan]
          ;if spkcov[aa] eq 1 then cspice_spkezr, target, et_time[aa], frame, abcorr, observer, state_temp, ltime else state_temp=[!values.f_nan, !values.f_nan, !values.f_nan]
          ;if we don't have coverage, use nans instead
          stateezr[0,aa] = state_temp[0]  ;add time step to overall array
          stateezr[1,aa] = state_temp[1]
          stateezr[2,aa] = state_temp[2]
    endfor
endelse

;statebody = spice_body_pos(target, observer, utc=utc_time, frame=frame, abcorr=abcorr)  
;cspice_spkezr, target, et_time, frame, abcorr, observer, stateezr, ltime  ;state contains R and V [0:5], ltime = light time between observer and object
    
mvn_pos_mso = dblarr(nele,3)
mvn_vel_mso = dblarr(nele,3)
mvn_pos_mso[*,0] = stateezr[0,*]  ;positions in km
mvn_pos_mso[*,1] = stateezr[1,*]  ;positions in km
mvn_pos_mso[*,2] = stateezr[2,*]  ;positions in km    
;mvn_vel_mso[*,0] = state[3,*]  ;velocities in km   ### No velocity yet, speak with Davin
;mvn_vel_mso[*,1] = state[4,*]  ;velocities in km
;mvn_vel_mso[*,2] = state[5,*]  ;velocities in km
    
                ;Store as tplot variable:
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'Project',                     cdf_istp[14], $                          
                   'Source_name',                 cdf_istp[0], $     ;Required for cdf production...
                   'Discipline',                  cdf_istp[1], $
                   'Var_type',                    'Data', $
                   'Data_type',                   cdf_istp[2] ,  $   
                   'Descriptor',                  cdf_istp[11], $                 
                   'Data_version',                cdf_istp[3], $ 
                   'PI_name',                     cdf_istp[4], $
                   'PI_affiliation',              cdf_istp[5], $
                   'TEXT',                        cdf_istp[6], $
                   'Instrument_type',             cdf_istp[7], $
                   'Mission_group',               cdf_istp[8], $
                   'Logical_file_ID',             cdf_istp[12], $
                   'Logical_source',              cdf_istp[9], $
                   'Logical_source_description',  cdf_istp[10], $ 
                   'Rules_of_use',                cdf_istp[13], $   
                   'MONOTON', 'INCREASE', $
                   'SCALEMIN', min(mvn_pos_mso), $
                   'SCALEMAX', max(mvn_pos_mso), $        ;..end of required for cdf production.
                   'generated_date'  ,     today_date, $ 
                   't_epoch'         ,     t_epoch, $
                   'Time_start'      ,     time_start, $
                   'Time_end'        ,     time_end, $
                   'Time_field'      ,     time_field, $
                   'SPICE_kernel_version', kernel_version, $
                   'SPICE_kernel_flag'      ,     spice_used, $                       
                   'L0_datafile'     ,     L0_datafile , $ 
                   'cal_vers'        ,     kernel_version ,$     
                   'cal_y_const1'    ,     loaded_kernels , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'SPICE kernels', $     
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[km (MSO frame)]');, $                     
                   ;'cal_v_const1'    ,     'PKT level::' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'zsubtitle'       ,     '[Attitude]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     1.2                      ,$    
                  'xtitle' ,        str_xtitle                   ,$   
                  'ytitle' ,        'mvn-pos_(MSO-frame)'                 ,$   
                  'yrange' ,        [min(mvn_pos_mso),max(mvn_pos_mso)] ,$   
                  'ystyle'  ,       1.                       ,$ 
                  'labels',         ['X', 'Y', 'Z'], $ 
                  'labflag',        1, $
                  ;'ztitle' ,        'Z-title'                ,$   
                  ;'zrange' ,        [min(data.y),max(data.y)],$                        
                  ;'spec'            ,     1, $           
                  ;'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  ;'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  ;'xlim2'    ,      [min(data.x),max(data.x)], $          ;for plotting lpw pkt lab data
                  'noerrorbars', 1)   
               ;---------------------------------
               store_data, 'mvn_lpw_anc_pos_mso', data={x:unix_in, y:mvn_pos_mso}, dlimit=dlimit, limit=limit
               ;---------------------------------
               
                ;Store as tplot variable:
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'Project',                     cdf_istp[14], $                          
                   'Source_name',                 cdf_istp[0], $     ;Required for cdf production...
                   'Discipline',                  cdf_istp[1], $
                   'Var_type',                    'Data', $
                   'Data_type',                   cdf_istp[2] ,  $   
                   'Descriptor',                  cdf_istp[11], $                 
                   'Data_version',                cdf_istp[3], $ 
                   'PI_name',                     cdf_istp[4], $
                   'PI_affiliation',              cdf_istp[5], $
                   'TEXT',                        cdf_istp[6], $
                   'Instrument_type',             cdf_istp[7], $
                   'Mission_group',               cdf_istp[8], $
                   'Logical_file_ID',             cdf_istp[12], $
                   'Logical_source',              cdf_istp[9], $
                   'Logical_source_description',  cdf_istp[10], $ 
                   'Rules_of_use',                cdf_istp[13], $   
                   'MONOTON', 'INCREASE', $
                   'SCALEMIN', min(mvn_vel_mso), $
                   'SCALEMAX', max(mvn_vel_mso), $        ;..end of required for cdf production.
                   'generated_date'  ,     today_date, $ 
                   't_epoch'         ,     t_epoch, $
                   'Time_start'      ,     time_start, $
                   'Time_end'        ,     time_end, $
                   'Time_field'      ,     time_field, $
                   'SPICE_kernel_version', kernel_version, $
                   'SPICE_kernel_flag'      ,     spice_used, $                       
                   'L0_datafile'     ,     L0_datafile , $ 
                   'cal_vers'        ,     kernel_version ,$     
                   'cal_y_const1'    ,     loaded_kernels , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'SPICE kernels', $     
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[km/s (MSO frame)]');, $                     
                   ;'cal_v_const1'    ,     'PKT level::' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'zsubtitle'       ,     '[Attitude]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     1.2                      ,$    
                  'xtitle' ,        str_xtitle                   ,$   
                  'ytitle' ,        'mvn-vel_(MSO-frame)'                 ,$   
                  'yrange' ,        [min(mvn_vel_mso),max(mvn_vel_mso)] ,$   
                  'ystyle'  ,       1.                       ,$ 
                  'labels',         ['Vx', 'Vy', 'Vz'], $ 
                  'labflag',        1, $
                  ;'ztitle' ,        'Z-title'                ,$   
                  ;'zrange' ,        [min(data.y),max(data.y)],$                        
                  ;'spec'            ,     1, $           
                  ;'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  ;'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  ;'xlim2'    ,      [min(data.x),max(data.x)], $          ;for plotting lpw pkt lab data
                  'noerrorbars', 1)   
               ;---------------------------------             
            ;   store_data, 'mvn_lpw_anc_vel_mso', data={x:unix_in, y:mvn_vel_mso}, dlimit=dlimit, limit=limit  ;#### no velocity yet
               ;---------------------------------
               
;========
;==8, 9==
;========
;Get MAVEN look vectors:
;Use SPICE to get the MAVEN s/c look vectors for X, Y, and Z:
;Convert from s/c frame to J2000 and MSO frame:

mvn_pointing = dblarr(3,3,nele)  ;array to store all MAVEN pointing info, x in first column, y in second, z in third

;Here, need to check that there is always pointing info for MAVEN. Go through each timestep and check there is pointing.
;Use the encoded clock time, as determined at start of code using SPICE
matrix_j2000=dblarr(3,3,nele)  ;store the rotation matrix in
matrix_mso=dblarr(3,3,nele)  ;store MSO rotation matrix
for aa = 0l, nele-1 do begin 
    cspice_ckgp, -202000, enc_time[aa], 0.0, 'MAVEN_SPACECRAFT', mat1, clk, found
    if found eq 1. then begin  ;if we have pointing info, carry on...
        mat_j = spice_body_att('MAVEN_SPACECRAFT', 'J2000', utc_time[aa])  ;one at a time to Davin's routine
        ;cspice_pxform, "MAVEN_SPACECRAFT", "J2000", et_time[aa], mat_j  ;MAVEN pointing in J2000 frame
        matrix_j2000[*,*,aa] = mat_j[*,*]
            
        mat_mso = spice_body_att('MAVEN_SPACECRAFT', 'MAVEN_MSO', utc_time[aa])
        ;cspice_pxform, "MAVEN_SPACECRAFT", "MAVEN_MSO", et_time[aa], mat_mso  ;MAVEN pointing in MSO frame
        matrix_mso[*,*,aa] = mat_mso[*,*]
    endif else begin
        matrix_j2000[*,*,aa] = !values.f_nan  ;nans if we don't find pointing
        matrix_mso[*,*,aa] = !values.f_nan
    endelse
endfor

mvn_att_j2000 = dblarr(3,3,nele)  ;store x vector (3 components in J2000) in row 1, y in row 2, z in 3. Time in nele.
mvn_att_mso = dblarr(3,3,nele)  ;store x vector (3 components in MSO) in row 1, y in row 2, z in 3. Time in nele.

for aa = 0L, nele-1 do begin
        ;Transform MAVEN xyz vectors into J2000:
        cspice_mxv, matrix_j2000[*,*,aa], mvn_x, mvn_x_j2000   ;can only take one vector at a time.
          mvn_att_j2000[*,0,aa] = mvn_x_j2000  ;store mvn x in j2000 for time nele
        cspice_mxv, matrix_j2000[*,*,aa], mvn_y, mvn_y_j2000
          mvn_att_j2000[*,1,aa] = mvn_y_j2000
        cspice_mxv, matrix_j2000[*,*,aa], mvn_z, mvn_z_j2000
          mvn_att_j2000[*,2,aa] = mvn_z_j2000
          
        ;Transform MAVEN xyz vectors into MSO:
        cspice_mxv, matrix_mso[*,*,aa], mvn_x, mvn_x_mso   ;can only take one vector at a time.
          mvn_att_mso[*,0,aa] = mvn_x_mso  ;store mvn x in mso for time nele
        cspice_mxv, matrix_mso[*,*,aa], mvn_y, mvn_y_mso
          mvn_att_mso[*,1,aa] = mvn_y_mso
        cspice_mxv, matrix_mso[*,*,aa], mvn_z, mvn_z_mso
          mvn_att_mso[*,2,aa] = mvn_z_mso                                                        
endfor  ;over aa

ydata = dblarr(nele,9)
for bb = 0, 2 do ydata[*,bb] = mvn_att_j2000[bb,0,*]
for bb = 0, 2 do ydata[*,3+bb] = mvn_att_j2000[bb,1,*]
for bb = 0, 2 do ydata[*,6+bb] = mvn_att_j2000[bb,2,*]
                ;Store as tplot variable:
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'Project',                     cdf_istp[14], $                          
                   'Source_name',                 cdf_istp[0], $     ;Required for cdf production...
                   'Discipline',                  cdf_istp[1], $
                   'Var_type',                    'Data', $
                   'Data_type',                   cdf_istp[2] ,  $   
                   'Descriptor',                  cdf_istp[11], $                 
                   'Data_version',                cdf_istp[3], $ 
                   'PI_name',                     cdf_istp[4], $
                   'PI_affiliation',              cdf_istp[5], $
                   'TEXT',                        cdf_istp[6], $
                   'Instrument_type',             cdf_istp[7], $
                   'Mission_group',               cdf_istp[8], $
                   'Logical_file_ID',             cdf_istp[12], $
                   'Logical_source',              cdf_istp[9], $
                   'Logical_source_description',  cdf_istp[10], $ 
                   'Rules_of_use',                cdf_istp[13], $   
                   'MONOTON', 'INCREASE', $
                   'SCALEMIN', min(mvn_att_j2000), $
                   'SCALEMAX', max(mvn_att_j2000), $        ;..end of required for cdf production.
                   'generated_date'  ,     today_date, $ 
                   't_epoch'         ,     t_epoch, $
                   'Time_start'      ,     time_start, $
                   'Time_end'        ,     time_end, $
                   'Time_field'      ,     time_field, $
                   'SPICE_kernel_version', kernel_version, $
                   'SPICE_kernel_flag'      ,     spice_used, $                       
                   'L0_datafile'     ,     L0_datafile , $ 
                   'cal_vers'        ,     kernel_version ,$     
                   'cal_y_const1'    ,     loaded_kernels , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'SPICE kernels', $     
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[Degrees]');, $                     
                   ;'cal_v_const1'    ,     'PKT level::' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'zsubtitle'       ,     '[Attitude]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     1.2                      ,$    
                  'xtitle' ,        str_xtitle                   ,$   
                  'ytitle' ,        'mvn-att_(Look-vector_J2000-frame)'                 ,$   
                  'yrange' ,        [1.1*min(mvn_att_j2000),1.1*max(mvn_att_j2000)] ,$   
                  'ystyle'  ,       1.                       ,$ 
                  'labels',         ['Xx', 'Xy', 'Xz', 'Yx', 'Yy', 'Yz', 'Zx', 'Zy', 'Zz'], $ 
                  'labflag',        1, $
                  ;'ztitle' ,        'Z-title'                ,$   
                  ;'zrange' ,        [min(data.y),max(data.y)],$                        
                  ;'spec'            ,     1, $           
                  ;'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  ;'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  ;'xlim2'    ,      [min(data.x),max(data.x)], $          ;for plotting lpw pkt lab data
                  'noerrorbars', 1)   
               ;---------------------------------
               store_data, 'mvn_lpw_anc_att_j2000', data={x:unix_in, y:ydata}, dlimit=dlimit, limit=limit


ydata = dblarr(nele,9)
for bb = 0, 2 do ydata[*,bb] = mvn_att_mso[bb,0,*]
for bb = 0, 2 do ydata[*,3+bb] = mvn_att_mso[bb,1,*]
for bb = 0, 2 do ydata[*,6+bb] = mvn_att_mso[bb,2,*]

                ;Store as tplot variable:
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'Project',                     cdf_istp[14], $                          
                   'Source_name',                 cdf_istp[0], $     ;Required for cdf production...
                   'Discipline',                  cdf_istp[1], $
                   'Var_type',                    'Data', $
                   'Data_type',                   cdf_istp[2] ,  $   
                   'Descriptor',                  cdf_istp[11], $                 
                   'Data_version',                cdf_istp[3], $ 
                   'PI_name',                     cdf_istp[4], $
                   'PI_affiliation',              cdf_istp[5], $
                   'TEXT',                        cdf_istp[6], $
                   'Instrument_type',             cdf_istp[7], $
                   'Mission_group',               cdf_istp[8], $
                   'Logical_file_ID',             cdf_istp[12], $
                   'Logical_source',              cdf_istp[9], $
                   'Logical_source_description',  cdf_istp[10], $ 
                   'Rules_of_use',                cdf_istp[13], $   
                   'MONOTON', 'INCREASE', $
                   'SCALEMIN', min(mvn_att_mso), $
                   'SCALEMAX', max(mvn_att_mso), $        ;..end of required for cdf production.
                   'generated_date'  ,     today_date, $ 
                   't_epoch'         ,     t_epoch, $
                   'Time_start'      ,     time_start, $
                   'Time_end'        ,     time_end, $
                   'Time_field'      ,     time_field, $
                   'SPICE_kernel_version', kernel_version, $
                   'SPICE_kernel_flag'      ,     spice_used, $                       
                   'L0_datafile'     ,     L0_datafile , $ 
                   'cal_vers'        ,     kernel_version ,$     
                   'cal_y_const1'    ,     loaded_kernels , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'SPICE kernels', $     
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[Look-vector_(MSO frame)]');, $                     
                   ;'cal_v_const1'    ,     'PKT level::' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'zsubtitle'       ,     '[Attitude]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     1.2                      ,$    
                  'xtitle' ,        str_xtitle                   ,$   
                  'ytitle' ,        'mvn-att_(Look-vector_MSO frame)'                 ,$   
                  'yrange' ,        [1.1*min(mvn_att_mso),1.1*max(mvn_att_mso)] ,$   
                  'ystyle'  ,       1.                       ,$ 
                  'labels',         ['Xx', 'Xy', 'Xz', 'Yx', 'Yy', 'Yz', 'Zx', 'Zy', 'Zz'], $
                  'labflag',        1, $ 
                  ;'ztitle' ,        'Z-title'                ,$   
                  ;'zrange' ,        [min(data.y),max(data.y)],$                        
                  ;'spec'            ,     1, $           
                  ;'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  ;'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  ;'xlim2'    ,      [min(data.x),max(data.x)], $          ;for plotting lpw pkt lab data
                  'noerrorbars', 1)   
               ;---------------------------------
               store_data, 'mvn_lpw_anc_att_mso', data={x:unix_in, y:ydata}, dlimit=dlimit, limit=limit
               ;---------------------------------
              
if keyword_set(not_quiet) then begin
    ;Plot offsets:
    ;window, 0, xsize=600, ysize=600  ;makes some machines crash using the window routine
    !p.multi=[0,1,2]
    plot, offset[*,0], offset[*,1], xtitle='Offset in X', ytitle='Offset in Y', title='Offset between MVN Z and Sun (s/c frame)' ;, xrange=[-0.5, 0.5], yrange=[-0.5,0.5] xsty=1, ysty=1
    plot, mvn_angles[*,0], title='Absolute angle between Sun and MAVEN z axis', xtitle='Timestep', ytitle='Abs angle (deg)'
    !p.multi=0
endif

mvn_lpw_anc_clear_spice_kernels ;Clear kernel_verified flag, jmm, 2015-02-11

;print, "==========================="
;print, "Routine finished"
;print, "==========================="

end

