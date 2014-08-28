;+
;NAME: MVN_SEP_SW_VERSION
;Function: mvn_spice_kernels(name)
;PURPOSE:
; Acts as a timestamp file to trigger the regeneration of SEP data products. Also provides Software Version info for the MAVEN SEP instrument.  
;Author: Davin Larson  - January 2014
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2014-04-25 08:18:14 -0700 (Fri, 25 Apr 2014) $
; $LastChangedRevision: 14949 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sep/mvn_sep_sw_version.pro $
;-
function mvn_sep_sw_version

tb = scope_traceback(/structure)
this_file = tb[n_elements(tb)-1].filename   
this_file_date = (file_info(this_file)).mtime

sw_structure = {  $
  sw_version : 'v01' , $
  sw_time_stamp_file : this_file , $
  sw_time_stamp : time_string(this_file_date) , $
  sw_runtime : time_string(systime(1))  , $
  svn_changedby : '$LastChangedBy: davin-mac $' , $
  svn_changedate: '$LastChangedDate: 2014-04-25 08:18:14 -0700 (Fri, 25 Apr 2014) $' , $
  svn_revision : '$LastChangedRevision: 14949 $' }



return,sw_structure
end




