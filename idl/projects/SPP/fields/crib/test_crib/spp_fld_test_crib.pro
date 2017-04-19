pro spp_fld_test_crib

  @b_on_w

  store_data, '*', /del

  cdf_dir = getenv('SPP_FLD_CDF_DIR')

  dprint, setdebug = 3

  ;spp_fld_tmlib_init, server = 'rflab.ssl.berkeley.edu'
  spp_fld_tmlib_init, server = 'spffmdb.ssl.berkeley.edu'

  ; Some data from COLD 2

  timespan, '2017-03-21/02:35:00', 3./24./60./5.

  spp_fld_make_cdf_l1, 'dcb_analog_hk', filename = dcb_analog_hk_fi

  spp_fld_dcb_analog_hk_load_l1, dcb_analog_hk_fi

  stop

end