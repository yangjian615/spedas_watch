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
;OUTPUT:
; fully qualified kernel filename(s)
;Author: Davin Larson  - January 2014
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2014-01-21 17:01:02 -0800 (Tue, 21 Jan 2014) $
; $LastChangedRevision: 13960 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu:36867/repos/idl_socware/trunk/projects/maven/general/mvn_file_source.pro $
;-
function mvn_spice_kernels,names,trange=trange,all=all,load=load,reset=reset,verbose=verbose,source=source,valid_only=valid_only

common mvn_spice_kernels_com,   kernels,retrievetime,tranges
    if spice_test() eq 0 then return,''
    tb = scope_traceback(/structure)
    this_dir = file_dirname(tb[n_elements(tb)-1].filename)+'/'   ; the directory this file resides in (determined at run time)

    naif = spice_file_source(preserve_mtime=1,valid_only=valid_only)
 ;   sprg = mvn_file_source()
all=1
if keyword_set(sck) then names = ['STD','SCK']
if keyword_set(all) then names=['STD','SCK','FRM','IK','POS','ATT']
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
               append_array,kernels,  file_retrieve('generic_kernels/spk/comets/siding_spring_v?.bsp',_extra=source,/last_version)
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
     'POS':  begin     ; Spacecraft position
;               append_array,kernels,  file_retrieve('MAVEN/kernels/spk/trj_c_od003a_131118-131219_v1.bsp',_extra=source)
;               append_array,kernels,  file_retrieve('MAVEN/kernels/spk/trj_c_od006a_131121-140301_v1.bsp',_extra=source)    ; spacecraft position
;               append_array,kernels,  file_retrieve('MAVEN/kernels/spk/trj_c_od008b_131220-141002_v2.bsp',_extra=source)
;               append_array,kernels,  file_retrieve('MAVEN/kernels/spk/trj_c_od013a_140125-141002_tcm2final_v1.bsp',_extra=source)  
;               append_array,kernels,  file_retrieve('MAVEN/kernels/spk/trj_c_od015a_140215-141012_moiprelim_v1.bsp',_extra=source)  
               append_array,kernels,  file_retrieve('MAVEN/kernels/spk/trj_c_131118-140811_rec_v1.bsp',_extra=source)  
               append_array,kernels,  file_retrieve('MAVEN/kernels/spk/trj_orb_od030b_140708-140927_plm1-10.0_final_v1.bsp',_extra=source)
               if 0 then begin
               append_array,kernels,  file_retrieve('MAVEN/kernels/spk/trj_orb_00001-00002_00032_v1.bsp',_extra=source)
               append_array,kernels,  file_retrieve('MAVEN/kernels/spk/trj_orb_00004-00004_00026_v1.bsp',_extra=source)
               append_array,kernels,  file_retrieve('MAVEN/kernels/spk/trj_orb_?????-?????_?????_v?.bsp',_extra=source,/last_version)
               endif else begin
               append_array,kernels,  file_retrieve('MAVEN/kernels/spk/maven_orb.bsp',_extra=source,/last_version)
               endelse
 ;              append_array,kernels,  file_retrieve('MAVEN/kernels/spk/trj_c_od????_??????-??????_*.bsp',_extra=source,/last_version)  
;               append_array,kernels,  file_retrieve('MAVEN/kernels/spk/de430s.bsp',_extra=source)                      ;  Like de430 but over limited time range (1995-2035)  
             end
     'ATT':  begin      ; Spacecraft Attitude  (CK)
;               attkern =  file_retrieve('MAVEN/kernels/ck/mvn_sc_rec_??????_??????_v0?.bc' ,_extra=source)   ;SC Attitude ???  
;                attformat = 'MAVEN/kernels/ck/mvn_sc_rec_??????_??????_v0?.bc'  ; use this line to get all files
               attformat = 'MAVEN/kernels/ck/mvn_sc_rec_yyMMDD_*_v0?.bc'  ; use this line to get all files in time range
               tr= timerange(trange) + [-3,1] * 3600d*24
               attkern = mvn_pfp_file_retrieve(attformat ,source=source, trange=tr,/daily_names)  ;,last_version=1)   ;SC Attitude ???  
               append_array,kernels,  attkern  ;SC Attitude ???  
;               append_array,kernels, file_retrieve('MAVEN/misc/app/maven_app_home_v1.bc',_extra=source)
               append_array,kernels, file_retrieve('MAVEN/misc/app/mvn_app_nom_131118_141031_v1.bc',_extra=source)
            end 
           
      endcase
    endfor
    retrievetime = ct
 ;   kernels = file_search(kernels)
endif
if keyword_set(load) then    spice_kernel_load,kernels
return,kernels

end
