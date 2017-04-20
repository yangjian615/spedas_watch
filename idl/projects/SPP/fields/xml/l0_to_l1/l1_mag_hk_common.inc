  <cdf_var
      name   = "message_id"
      type   = "integer"
      base   = "event_data_start"
      offset = "0"
      width  = "16"
      />

  <cdf_var
      name   = "mag_sync_1"
      type   = "integer"
      base   = "event_data_start"
      offset = "2 * 8"
      width  = "16"
      />

  <cdf_var
      name   = "mag_sync_2"
      type   = "integer"
      base   = "event_data_start"
      offset = "4 * 8"
      width  = "16"
      />

  <cdf_var
      name   = "cmd_ctr"
      type   = "integer"
      base   = "event_data_start"
      offset = "6 * 8"
      width  = "16"
      />

  <cdf_var
      name   = "mag_frm_ctr"
      type   = "integer"
      base   = "event_data_start"
      offset = "8 * 8"
      width  = "16"
      />

  <cdf_var
      name   = "mag_cycle_f0"
      type   = "integer"
      base   = "event_data_start"
      offset = "10 * 8"
      width  = "16"
      />

  <cdf_var
      name   = "mag_time_f1"
      type   = "integer"
      base   = "event_data_start"
      offset = "12 * 8"
      width  = "16"
      />

  <cdf_var
      name   = "mag_time_f2"
      type   = "integer"
      base   = "event_data_start"
      offset = "14 * 8"
      width  = "16"
      />

  <cdf_var
      name   = "mag_time_f3"
      type   = "integer"
      base   = "event_data_start"
      offset = "16 * 8"
      width  = "16"
      />

  <cdf_var
      name   = "mag_status"
      type   = "integer"
      base   = "event_data_start"
      offset = "18 * 8"
      width  = "16"
      />

  <cdf_var
      name   = "mag_spp"
      type   = "integer"
      base   = "event_data_start"
      offset = "18 * 8"
      width  = "1"
      />

  <cdf_var
      name   = "mag_fpga_ver"
      type   = "integer"
      base   = "event_data_start"
      offset = "18 * 8 + 1"
      width  = "5"
      />

  <cdf_var
      name   = "mag_pcbnum"
      type   = "integer"
      base   = "event_data_start"
      offset = "18 * 8 + 6"
      width  = "4"
      />

  <cdf_var
      name   = "mag_drive"
      type   = "integer"
      base   = "event_data_start"
      offset = "18 * 8 + 10"
      width  = "2"
      />

  <cdf_var
      name   = "mag_cal"
      type   = "integer"
      base   = "event_data_start"
      offset = "18 * 8 + 12"
      width  = "1"
      />

  <cdf_var
      name   = "mag_manual"
      type   = "integer"
      base   = "event_data_start"
      offset = "18 * 8 + 13"
      width  = "1"
      />

  <cdf_var
      name   = "mag_range"
      type   = "integer"
      base   = "event_data_start"
      offset = "18 * 8 + 14"
      width  = "2"
      />

  <cdf_var
      name   = "mag_xtest"
      type   = "integer"
      base   = "event_data_start"
      offset = "20 * 8"
      width  = "16"
      signed = "1"
      />

  <cdf_var
      name   = "mag_ytest"
      type   = "integer"
      base   = "event_data_start"
      offset = "22 * 8"
      width  = "16"
      signed = "1"
      />

  <cdf_var
      name   = "mag_ztest"
      type   = "integer"
      base   = "event_data_start"
      offset = "24 * 8"
      width  = "16"
      signed = "1"
      />

  <cdf_var
      name   = "mag_htrvmon"
      type   = "integer"
      base   = "event_data_start"
      offset = "26 * 8"
      width  = "16"
      signed = "1"
      />

  <cdf_var
      name   = "mag_htrcurr"
      type   = "integer"
      base   = "event_data_start"
      offset = "28 * 8"
      width  = "16"
      signed = "1"
      />

  <cdf_var
      name   = "mag_snsrtemp"
      type   = "integer"
      base   = "event_data_start"
      offset = "30 * 8"
      width  = "16"
      signed = "1"      
      convert_routine = "spp_fld_mag_hk_snsrtmp_convert">
    <cdf_att
        FIELDNAM = "mag_snsrtemp"
        FORMAT = "F15.3"
        LABLAXIS = "mag_snsrtemp"
        VAR_TYPE = "data"
        FILLVAL = "-1.0E31"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-100"
        VALIDMAX = "100"
        SCALEMIN = "-100"
        SCALEMAX = "100"
        UNITS = "C"
        CATDESC = "MAG Sensor Temperature, in C"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "mag_pcbtemp"
      type   = "integer"
      base   = "event_data_start"
      offset = "32 * 8"
      width  = "16"
      signed = "1"
      />

  <cdf_var
      name   = "mag_p12curr"
      type   = "integer"
      base   = "event_data_start"
      offset = "34 * 8"
      width  = "16"
      signed = "1"
      />

  <cdf_var
      name   = "mag_m12curr"
      type   = "integer"
      base   = "event_data_start"
      offset = "36 * 8"
      width  = "16"
      signed = "1"
      />

  <cdf_var
      name   = "mag_p12vmon"
      type   = "integer"
      base   = "event_data_start"
      offset = "38 * 8"
      width  = "16"
      signed = "1"
      />

  <cdf_var
      name   = "mag_m12vmon"
      type   = "integer"
      base   = "event_data_start"
      offset = "40 * 8"
      width  = "16"
      signed = "1"
      />

  <cdf_var
      name   = "mag_p10vref"
      type   = "integer"
      base   = "event_data_start"
      offset = "42 * 8"
      width  = "16"
      signed = "1"
      />

  <cdf_var
      name   = "mag_p25dmon"
      type   = "integer"
      base   = "event_data_start"
      offset = "44 * 8"
      width  = "16"
      signed = "1"
      />

  <cdf_var
      name   = "mag_p33dmon"
      type   = "integer"
      base   = "event_data_start"
      offset = "46 * 8"
      width  = "16"
      signed = "1"
      />

  <cdf_var
      name   = "mag_p5vmon"
      type   = "integer"
      base   = "event_data_start"
      offset = "48 * 8"
      width  = "16"
      signed = "1"
      />

  <cdf_var
      name   = "mag_m5vmon"
      type   = "integer"
      base   = "event_data_start"
      offset = "50 * 8"
      width  = "16"
      signed = "1"
      />

  <cdf_var
      name   = "mag_dig_hk_00"
      type   = "integer"
      base   = "event_data_start"
      offset = "52 * 8"
      width  = "16"
      />

  <cdf_var
      name   = "mag_testbus"
      type   = "integer"
      base   = "event_data_start"
      offset = "52 * 8"
      width  = "4"
      />

  <cdf_var
      name   = "mag_digxtra"
      type   = "integer"
      base   = "event_data_start"
      offset = "52 * 8 + 4"
      width  = "4"
      />

  <cdf_var
      name   = "mag_rgupdat"
      type   = "integer"
      base   = "event_data_start"
      offset = "53 * 8"
      width  = "1"
      />

  <cdf_var
      name   = "mag_digpps"
      type   = "integer"
      base   = "event_data_start"
      offset = "53 * 8 + 1"
      width  = "1"
      />

  <cdf_var
      name   = "mag_timehi"
      type   = "integer"
      base   = "event_data_start"
      offset = "53 * 8 + 2"
      width  = "1"
      />

  <cdf_var
      name   = "mag_timemid"
      type   = "integer"
      base   = "event_data_start"
      offset = "53 * 8 + 3"
      width  = "1"
      />

  <cdf_var
      name   = "mag_timelow"
      type   = "integer"
      base   = "event_data_start"
      offset = "53 * 8 + 4"
      width  = "1"
      />

  <cdf_var
      name   = "mag_cmdrcd"
      type   = "integer"
      base   = "event_data_start"
      offset = "53 * 8 + 5"
      width  = "1"
      />

  <cdf_var
      name   = "mag_parerr"
      type   = "integer"
      base   = "event_data_start"
      offset = "53 * 8 + 6"
      width  = "1"
      />

  <cdf_var
      name   = "mag_stoperr"
      type   = "integer"
      base   = "event_data_start"
      offset = "53 * 8 + 7"
      width  = "1"
      />

  <cdf_var
      name   = "mag_dig_hk_01"
      type   = "integer"
      base   = "event_data_start"
      offset = "54 * 8"
      width  = "16"
      signed = "1"
      />

  <cdf_var
      name   = "mag_dig_hk_02"
      type   = "integer"
      base   = "event_data_start"
      offset = "56 * 8"
      width  = "16"
      />

  <cdf_var
      name   = "mag_cmdrjct"
      type   = "integer"
      base   = "event_data_start"
      offset = "56 * 8"
      width  = "8"
      signed = "1"
      />

  <cdf_var
      name   = "mag_lstrjct"
      type   = "integer"
      base   = "event_data_start"
      offset = "57 * 8"
      width  = "8"
      signed = "1"
      />

  <cdf_var
      name   = "mag_dig_hk_03"
      type   = "integer"
      base   = "event_data_start"
      offset = "58 * 8"
      width  = "16"
      />

  <cdf_var
      name   = "mag_r0_hi"
      type   = "integer"
      base   = "event_data_start"
      offset = "58 * 8"
      width  = "8"
      signed = "1"
      />

  <cdf_var
      name   = "mag_r1_lo"
      type   = "integer"
      base   = "event_data_start"
      offset = "59 * 8"
      width  = "8"
      signed = "1"
      />

  <cdf_var
      name   = "mag_dig_hk_04"
      type   = "integer"
      base   = "event_data_start"
      offset = "60 * 8"
      width  = "16"
      />

  <cdf_var
      name   = "mag_r1_hi"
      type   = "integer"
      base   = "event_data_start"
      offset = "60 * 8"
      width  = "8"
      signed = "1"
      />

  <cdf_var
      name   = "mag_r2_lo"
      type   = "integer"
      base   = "event_data_start"
      offset = "61 * 8"
      width  = "8"
      signed = "1"
      />

  <cdf_var
      name   = "mag_dig_hk_05"
      type   = "integer"
      base   = "event_data_start"
      offset = "62 * 8"
      width  = "16"
      />

  <cdf_var
      name   = "mag_r2_hi"
      type   = "integer"
      base   = "event_data_start"
      offset = "62 * 8"
      width  = "8"
      signed = "1"
      />

  <cdf_var
      name   = "mag_r3_lo"
      type   = "integer"
      base   = "event_data_start"
      offset = "63 * 8"
      width  = "8"
      signed = "1"
      />

  <cdf_var
      name   = "mag_dig_hk_06"
      type   = "integer"
      base   = "event_data_start"
      offset = "64 * 8"
      width  = "16"
      />

  <cdf_var
      name   = "mag_lle"
      type   = "integer"
      base   = "event_data_start"
      offset = "64 * 8"
      width  = "8"
      signed = "1"
      />

  <cdf_var
      name   = "mag_ule"
      type   = "integer"
      base   = "event_data_start"
      offset = "65 * 8"
      width  = "8"
      signed = "1"
      />

  <cdf_var
      name   = "mag_dig_hk_07"
      type   = "integer"
      base   = "event_data_start"
      offset = "66 * 8"
      width  = "16"
      />

  <cdf_var
      name   = "mag_numpkt"
      type   = "integer"
      base   = "event_data_start"
      offset = "66 * 8"
      width  = "8"
      signed = "1"
      />

  <cdf_var
      name   = "mag_cnt_pkt"
      type   = "integer"
      base   = "event_data_start"
      offset = "67 * 8"
      width  = "8"
      signed = "1"
      />

  <cdf_var
      name   = "mag_dig_hk_08"
      type   = "integer"
      base   = "event_data_start"
      offset = "68 * 8"
      width  = "16"
      />

  <cdf_var
      name   = "mag_cnt_ule"
      type   = "integer"
      base   = "event_data_start"
      offset = "68 * 8"
      width  = "8"
      signed = "1"
      />

  <cdf_var
      name   = "mag_cnt_lle"
      type   = "integer"
      base   = "event_data_start"
      offset = "69 * 8"
      width  = "8"
      signed = "1"
      />

  <cdf_var
      name   = "mag_rate"
      type   = "integer"
      base   = "event_data_start"
      offset = "70 * 8"
      width  = "8"
      signed = "1"
      />

  <cdf_var
      name   = "mag_opt"
      type   = "integer"
      base   = "event_data_start"
      offset = "71 * 8"
      width  = "8"
      signed = "1"
      />

  <cdf_var
      name   = "mag_rstlmt"
      type   = "integer"
      base   = "event_data_start"
      offset = "72 * 8"
      width  = "8"
      signed = "1"
      />

  <cdf_var
      name   = "mag_rstsec"
      type   = "integer"
      base   = "event_data_start"
      offset = "73 * 8"
      width  = "8"
      signed = "1"
      />

  <cdf_var
      name   = "mag_xoff0"
      type   = "integer"
      base   = "event_data_start"
      offset = "74 * 8"
      width  = "16"
      signed = "1"
      />

  <cdf_var
      name   = "mag_yoff0"
      type   = "integer"
      base   = "event_data_start"
      offset = "76 * 8"
      width  = "16"
      signed = "1"
      />

  <cdf_var
      name   = "mag_zoff0"
      type   = "integer"
      base   = "event_data_start"
      offset = "78 * 8"
      width  = "16"
      signed = "1"
      />

  <cdf_var
      name   = "mag_xoff1"
      type   = "integer"
      base   = "event_data_start"
      offset = "80 * 8"
      width  = "16"
      signed = "1"
      />

  <cdf_var
      name   = "mag_yoff1"
      type   = "integer"
      base   = "event_data_start"
      offset = "82 * 8"
      width  = "16"
      signed = "1"
      />

  <cdf_var
      name   = "mag_zoff1"
      type   = "integer"
      base   = "event_data_start"
      offset = "84 * 8"
      width  = "16"
      signed = "1"
      />

  <cdf_var
      name   = "mag_xoff2"
      type   = "integer"
      base   = "event_data_start"
      offset = "86 * 8"
      width  = "16"
      signed = "1"
      />

  <cdf_var
      name   = "mag_yoff2"
      type   = "integer"
      base   = "event_data_start"
      offset = "88 * 8"
      width  = "16"
      signed = "1"
      />

  <cdf_var
      name   = "mag_zoff2"
      type   = "integer"
      base   = "event_data_start"
      offset = "90 * 8"
      width  = "16"
      signed = "1"
      />

  <cdf_var
      name   = "mag_xoff3"
      type   = "integer"
      base   = "event_data_start"
      offset = "92 * 8"
      width  = "16"
      signed = "1"
      />

  <cdf_var
      name   = "mag_yoff3"
      type   = "integer"
      base   = "event_data_start"
      offset = "94 * 8"
      width  = "16"
      signed = "1"
      />

  <cdf_var
      name   = "mag_zoff3"
      type   = "integer"
      base   = "event_data_start"
      offset = "96 * 8"
      width  = "16"
      signed = "1"
      />
