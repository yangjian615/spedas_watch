;
;  $LastChangedBy: spfuser $
;  $LastChangedDate: 2017-04-19 16:48:53 -0700 (Wed, 19 Apr 2017) $
;  $LastChangedRevision: 23200 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_mag_hk/spp_fld_mag_hk_convert.pro $
;

function spp_fld_mag_hk_snsrtmp_convert, counts

  temp_coeff = [8.146357214, 0.001459481, 6.877183e-9, -1.005099e-12,-5.851287e-19, 1.806212e-21]

  temp = poly(counts, temp_coeff)
  
  return, temp

end


pro spp_fld_mag_hk_convert, data, times, cdf_att

  dummy = spp_fld_mag_hk_snsrtmp_convert(0.)

end