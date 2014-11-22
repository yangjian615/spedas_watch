;+
;NAME: MVN_SPICE_KERNELS
; function: mvn_spice_kernels(name)
;PURPOSE:
; Provides maven spice kernel filename of specified type
;  
;Typical CALLING SEQUENCE:
;  kernels=mvn_spice_kernel() 
;TYPICAL USAGE:
;INPUT:
;  string must be one of:
;    Not implemented yet.  currently retrieves ALL files
;KEYWORDS:
; LOAD:   Set keyword to also load file
; TRANGE:  Set keyword to UT timerange to provide range of needed files. 
; RECONSTRUCT: If set, then only kernels with reconstructed data (no predicts) are returned.
;OUTPUT:
; fully qualified kernel filename(s)
;Author: Davin Larson  - January 2014
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2014-11-19 10:33:12 -0800 (Wed, 19 Nov 2014) $
; $LastChangedRevision: 16238 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/spice/mvn_spice_kernels.pro $
;-
function mvn_spice_kernels,names,trange=trange,all=all,load=load,reset=reset,verbose=verbose,source=source,valid_only=valid_only,sck=sck,clear=clear,reconstruct=reconstruct

common mvn_spice_kernels_com,   kernels,retrievetime,tranges
    if spice_test() eq 0 then return,''
    tb = scope_traceback(/structure)
    this_dir = file_dirname(tb[n_elements(tb)-1].filename)+'/'   ; the directory this file resides in (determined at run time)

    naif = spice_file_source(preserve_mtime=1,valid_only=valid_only)
 ;   sprg = mvn_file_source()
;all=1
if keyword_set(sck) then names = ['STD','SCK']
if keyword_set(all) or not keyword_set(names) then names=['STD','SCK','FRM','IK','SPK','CK']
if keyword_set(reset) then kernels=0
ct = systime(1)
waittime = 10.                 ; search no more often than this number of seconds
if ~keyword_set(kernels) || (ct - retrievetime) gt waittime then begin   
    if ~keyword_set(source) then     source=naif
;    source.no_update=1
    if keyword_set(verbose) then source.verbose = verbose
    kernels=0
    for i=0,n_elements(names)-1 do begin
      case strupcase(names[i]) of 
     'STD':    begin
               append_array,kernels,  spice_standard_kernels(source=source,/mars)          ;  "Standard" kernels
;               append_array,kernels,  file_retrieve('generic_kernels/spk/comets/siding_spring_v?.bsp',_extra=source,/last_version)
               end
     'SCK':    append_array,kernels,  file_retrieve('MAVEN/kernels/sclk/MVN_SCLKSCET.000??.tsc',_extra=source,/last_version)           ; spacecraft time
     'FRM':    begin                                                                                                            ; Frame kernels
;               append_array,kernels,  file_retrieve('MAVEN/kernels/fk/maven_v??*.tf',_extra=source,/last)                
;               append_array,kernels,  file_retrieve('MAVEN/misc/updates/maven_v04_draft?.tf',_extra=source,/last)
               append_array,kernels,  this_dir+'kernels/maven_v04.tf'   ; file_retrieve('MAVEN/misc/updates/maven_v04_draft?.tf',_extra=source,/last)
               append_array,kernels,  this_dir+'kernels/maven_misc.tf'  ; Use this file to make temporary changes to the maven_v??.tf file
               end
     'IK':    begin                                                                      ; Instrument Kernels                                                                               ; Frame kernels
               append_array,kernels,  this_dir+'kernels/ik/maven_ant.ti'  
               append_array,kernels,  this_dir+'kernels/ik/maven_euv.ti'  
               append_array,kernels,  this_dir+'kernels/ik/maven_iuvs.ti'  
               append_array,kernels,  this_dir+'kernels/ik/maven_lpw.ti'  
               append_array,kernels,  this_dir+'kernels/ik/maven_mag.ti'  
               append_array,kernels,  this_dir+'kernels/ik/maven_ngims.ti'  
               append_array,kernels,  this_dir+'kernels/ik/maven_sep.ti'  
               append_array,kernels,  this_dir+'kernels/ik/maven_static.ti'  
               append_array,kernels,  this_dir+'kernels/ik/maven_swea.ti'  
               append_array,kernels,  this_dir+'kernels/ik/maven_swia.ti'  
               end
     'SPK':  begin     ; Spacecraft position   
               tr= timerange(trange)   ; + [-1,1] * 3600d*24
               ;   load if (tr[0] lt trf[1]) && (tr[1] gt trf[0])
               if (tr[1] ge time_double('2013-11-18')) && (tr[0] le time_double('2014-08-11'))  then append_array,kernels,  file_retrieve('MAVEN/kernels/spk/trj_c_131118-140811_rec_v?.bsp',_extra=source)  
               if keyword_set(reconstruct) then begin
                  append_array,kernels, file_retrieve('MAVEN/kernels/spk/maven_orb_rec.bsp',_extra=source)   
;                  if (tr[1] ge mvn_orbit_num(orbnum=1))   && (tr[0] le mvn_orbit_num(orbnum=83))   then append_array,kernels,  file_retrieve('MAVEN/kernels/spk/trj_orb_00001-00083_rec_v?.bsp',_extra=source)
;                  if (tr[1] ge mvn_orbit_num(orbnum=82))  && (tr[0] le mvn_orbit_num(orbnum=120))  then append_array,kernels,  file_retrieve('MAVEN/kernels/spk/trj_orb_00082-00120_rec_v?.bsp',_extra=source)
;                  if (tr[1] ge mvn_orbit_num(orbnum=119)) && (tr[0] le mvn_orbit_num(orbnum=183))  then append_array,kernels,  file_retrieve('MAVEN/kernels/spk/trj_orb_00119-00183_rec_v?.bsp',_extra=source)
               endif else begin
                  if (tr[1] ge time_double('2014-07-08')) && (tr[0] le time_double('2014-09-22'))  then append_array,kernels,  file_retrieve('MAVEN/kernels/spk/trj_orb_od030b_140708-140927_plm1-10.0_final_v1.bsp',_extra=source)
                  append_array,kernels, file_retrieve('MAVEN/kernels/spk/maven_orb.bsp',_extra=source)    
                  append_array,kernels, file_retrieve('MAVEN/kernels/spk/maven_orb_rec.bsp',_extra=source)   
               endelse
             end
     'CK':  begin      ; Spacecraft Attitude  (CK)
;               attkern =  file_retrieve('MAVEN/kernels/ck/mvn_sc_rec_??????_??????_v0?.bc' ,_extra=source)   ;SC Attitude ???  
;                attformat = 'MAVEN/kernels/ck/mvn_sc_rec_??????_??????_v0?.bc'  ; use this line to get all files

               attformat = 'MAVEN/kernels/ck/mvn_sc_rec_yyMMDD_*_v0?.bc'  ; use this line to get all files in time range
               tr= timerange(trange) + [-1,1] * 3600d*24
               attkern = mvn_pfp_file_retrieve(attformat ,source=source, trange=tr,/daily_names)  ;,last_version=1)   ;SC Attitude ???  
               append_array,kernels,  attkern  ;SC Attitude ???  

;               append_array,kernels, file_retrieve('MAVEN/misc/app/maven_app_home_v1.bc',_extra=source)
               append_array,kernels, file_retrieve('MAVEN/misc/app/mvn_app_nom_131118_141031_v1.bc',_extra=source)

               appformat = 'MAVEN/kernels/ck/mvn_app_rec_yyMMDD_*_v0?.bc'  ; use this line to get all files in time range
               appkern = mvn_pfp_file_retrieve(appformat ,source=source, trange=tr,/daily_names)  ;,last_version=1)   ;APP Attitude ???  
                append_array,kernels,  appkern  ;APP Attitude ???  

            end 
           
      endcase
    endfor
    retrievetime = ct
 ;   kernels = file_search(kernels)
endif
if keyword_set(clear) then cspice_kclear
if keyword_set(load) then    spice_kernel_load,kernels
return,kernels

end
