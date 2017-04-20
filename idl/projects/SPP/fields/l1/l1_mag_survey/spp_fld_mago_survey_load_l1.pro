;
;  $LastChangedBy: spfuser $
;  $LastChangedDate: 2017-04-19 14:58:30 -0700 (Wed, 19 Apr 2017) $
;  $LastChangedRevision: 23197 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_mag_survey/spp_fld_mago_survey_load_l1.pro $
;

pro spp_fld_mago_survey_load_l1, file

  prefix = 'spp_fld_mago_survey_'

  spp_fld_mag_survey_load_l1, file, prefix = prefix

end