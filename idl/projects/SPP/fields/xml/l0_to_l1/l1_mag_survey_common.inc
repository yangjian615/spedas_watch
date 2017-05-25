  <cdf_var
      name   = "compressed"
      type   = "integer">
    <xlate value="0" string="No"/>
    <xlate value="1" string="Yes"/>
  </cdf_var>

  <cdf_var
      name   = "algorithm"
      type   = "integer"
      />

  <!-- unused 5 bits -->

  <cdf_var
      name   = "avg_period_raw"
      type   = "integer">
  <cdf_att
        FIELDNAM = "avg_period_raw"
        FORMAT = "F15.3"
        LABLAXIS = "avg_period_raw"
        VAR_TYPE = "data"
        FILLVAL = "-1.0E31"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-99999999"
        VALIDMAX = "99999999"
        SCALEMIN = "-99999999"
        SCALEMAX = "99999999"
        UNITS = "None"
        CATDESC = "avg period raw"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "config2"
      type   = "integer"
      />

  <cdf_var
      name   = "config3"
      type   = "integer"
      />

  <cdf_var
      name   = "range_bits"
      type   = "integer">
    <cdf_att
        FIELDNAM = "range_bits"
        FORMAT = "F15.3"
        LABLAXIS = "range"
        VAR_TYPE = "data"
        FILLVAL = "4294967295"
        DATA_TYPE = "CDF_UINT4"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "0"
        VALIDMAX = "4294967295"
        SCALEMIN = "0"
        SCALEMAX = "4294967295"
        UNITS = "None"
        CATDESC = "Range"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "mag_data_raw"
      type   = "integer"
      nelem  = "1536"
      signed = "1"
      />

  <cdf_var
      name   = "mag_bx"
      type   = "integer"
      nelem  = "512">
    <cdf_att
        FIELDNAM = "mag_bx"
        FORMAT = "F15.3"
        LABLAXIS = "mag_bx"
        VAR_TYPE = "data"
        FILLVAL = "-1.0E31"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-99999999"
        VALIDMAX = "99999999"
        SCALEMIN = "-99999999"
        SCALEMAX = "99999999"
        UNITS = "Counts"
        CATDESC = "MAG BX: X component of the magnetic field"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "mag_by"
      type   = "integer"
      nelem  = "512">
    <cdf_att
        FIELDNAM = "mag_by"
        FORMAT = "F15.3"
        LABLAXIS = "mag_by"
        VAR_TYPE = "data"
        FILLVAL = "-1.0E31"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-99999999"
        VALIDMAX = "99999999"
        SCALEMIN = "-99999999"
        SCALEMAX = "99999999"
        UNITS = "Counts"
        CATDESC = "MAG BY: Y component of the magnetic field"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "mag_bz"
      type   = "integer"
      nelem  = "512">
    <cdf_att
        FIELDNAM = "mag_bz"
        FORMAT = "F15.3"
        LABLAXIS = "mag_bz"
        VAR_TYPE = "data"
        FILLVAL = "-1.0E31"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-99999999"
        VALIDMAX = "99999999"
        SCALEMIN = "-99999999"
        SCALEMAX = "99999999"
        UNITS = "Counts"
        CATDESC = "MAG BZ: Z component of the magnetic field"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>
