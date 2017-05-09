  <cdf_var
      name   = "dfb_acdc"
      type   = "integer">
    <cdf_att
        FIELDNAM = "acdc"
        FORMAT = "I08"
        LABLAXIS = "acdc"
        VAR_TYPE = "data"
        DATA_TYPE = "CDF_INT2"
        FILLVAL = "-32767"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "0"
        VALIDMAX = "1"
        SCALEMIN = "0"
        SCALEMAX = "1"
        UNITS = "None"
        CATDESC = "acdc"
        DEPEND_0 = "epoch">
		</cdf_att>
  </cdf_var>
  
  <cdf_var
      name   = "dfb_ftap"
      type   = "integer">
    <cdf_att
        FIELDNAM = "ftap"
        FORMAT = "I08"
        LABLAXIS = "ftap"
        VAR_TYPE = "data"
        DATA_TYPE = "CDF_INT2"
        FILLVAL = "-32767"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "0"
        VALIDMAX = "6"
        SCALEMIN = "0"
        SCALEMAX = "6"
        UNITS = "None"
        CATDESC = "ftap"
        DEPEND_0 = "epoch">
		</cdf_att>
  </cdf_var>

  <cdf_var
      name   = "dbm_data"
      type   = "integer"
      convert_routine = "none"
      nelem  = "dbm_nsamples">
  	<cdf_att
        FIELDNAM = "dbm_data"
        FORMAT = "I12"
        LABLAXIS = "dbm_data"
        VAR_TYPE = "data"
        DATA_TYPE = "CDF_INT4"
        FILLVAL = "-2147483647"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-2147483647"
        VALIDMAX = "2147483647"
        SCALEMIN = "-2147483647"
        SCALEMAX = "2147483647"
        UNITS = "None"
        CATDESC = "dbm_data"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

