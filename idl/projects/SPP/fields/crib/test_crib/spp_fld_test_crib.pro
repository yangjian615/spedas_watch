pro spp_fld_test_crib

  @b_on_w

  store_data, '*', /del

  cdf_dir = getenv('SPP_FLD_CDF_DIR')

  cdf_subdir = cdf_dir + '/test/example_mag_test_tvac_hot2'

  dprint, setdebug = 3

  ; Load data from COLD 2

  spp_fld_tmlib_init, server = '192.168.0.203'
  ;spp_fld_tmlib_init, server = 'spffmdb.ssl.berkeley.edu'

  timespan, '2017-03-21/19:24:00', (1./24.)*(10./60.) ; HOT2 CPT

;  timespan, '2017-03-19', 9 ; All TVAC data

;  timespan, '2017-03-23/18:30:00', 4./24 ; All data

;  timespan, '2017-03-23/18:33:30', 1./24/60 ; All data

  spp_fld_make_cdf_l1, 'dcb_analog_hk', filename = dcb_analog_hk_fi

  spp_fld_make_cdf_l1, 'aeb1_hk', filename = aeb1_hk_fi

  spp_fld_make_cdf_l1, 'aeb2_hk', filename = aeb2_hk_fi

  spp_fld_make_cdf_l1, 'mago_hk', filename = mago_hk_fi

  spp_fld_make_cdf_l1, 'magi_hk', filename = magi_hk_fi

  spp_fld_make_cdf_l1, 'mago_survey', varformat = ["mag_by", $
    "mag_bz", "avg_period_raw", "mag_bx", "range_bits"], filename = mago_fi

  spp_fld_make_cdf_l1, 'magi_survey', varformat = ["mag_by", $
    "mag_bz", "avg_period_raw", "mag_bx", "range_bits"], filename = magi_fi

  spp_fld_dcb_analog_hk_load_l1, dcb_analog_hk_fi

  spp_fld_aeb1_hk_load_l1, aeb1_hk_fi

  spp_fld_aeb2_hk_load_l1, aeb2_hk_fi

  spp_fld_mago_hk_load_l1, mago_hk_fi

  spp_fld_magi_hk_load_l1, magi_hk_fi

  spp_fld_mago_survey_load_l1, mago_fi

  spp_fld_magi_survey_load_l1, magi_fi

  if keyword_set(cdf_subdir) then begin
    
    file_mkdir, cdf_subdir
    
    file_copy, dcb_analog_hk_fi, cdf_subdir, /over
    file_copy, aeb1_hk_fi, cdf_subdir, /over
    file_copy, aeb2_hk_fi, cdf_subdir, /over
    file_copy, mago_hk_fi, cdf_subdir, /over
    file_copy, magi_hk_fi, cdf_subdir, /over
    file_copy, mago_fi, cdf_subdir, /over
    file_copy, magi_fi, cdf_subdir, /over
    
  endif

 stop

end