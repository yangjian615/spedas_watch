  <item
      name   = "dfb_wav_sample_rate"
      type   = "double"
      value  = "18750. / (2. ** dfb_wav_tap)"
      />
      
  <item
      name   = "dfb_wav_time_step"
      type   = "double"
      value  = "1. / dfb_wav_sample_rate"
      />

  <item
      name   = "dfb_wav_time_series_times"
      type   = "double"
      value  = "r8gen(0, dfb_wav_time_step, wf_pkt_data_elements, 1, 1, 1, 0)"
      />

  <!-- DFB Tertiary Header  (2 bytes)-->
    
  <!-- Bit 15 = compression bit -->
  <cdf_var
      name   = "dfb_compression"
      type   = "integer">
  <cdf_att
        FIELDNAM = "dfb_compression"
        FORMAT = "I08"
        LABLAXIS = "dfb_compression"
        VAR_TYPE = "data"
        FILLVAL = "-1.0E31"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-99999999"
        VALIDMAX = "99999999"
        SCALEMIN = "-99999999"
        SCALEMAX = "99999999"
        UNITS = "None"
        CATDESC = "dfb_compression"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <!-- 3 unused bits (14:12) -->

  <!-- 4 bits specify which filter tap (11:8) -->
  <cdf_var
      name   = "dfb_wav_tap"
      type   = "integer">
  <cdf_att
        FIELDNAM = "dfb_wav_tap"
        FORMAT = "I08"
        LABLAXIS = "dfb_wav_tap"
        VAR_TYPE = "data"
        FILLVAL = "-1.0E31"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-99999999"
        VALIDMAX = "99999999"
        SCALEMIN = "-99999999"
        SCALEMAX = "99999999"
        UNITS = "None"
        CATDESC = "dfb_wav_tap"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <!-- 3 unused bits (7:5) -->

  <!-- 1 bit specifies if data product is enabled (bit 4) -->
  <cdf_var
      name   = "dfb_wav_en"
      type   = "integer">
  <cdf_att
        FIELDNAM = "dfb_wav_en"
        FORMAT = "I08"
        LABLAXIS = "dfb_wav_en"
        VAR_TYPE = "data"
        FILLVAL = "-1.0E31"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-99999999"
        VALIDMAX = "99999999"
        SCALEMIN = "-99999999"
        SCALEMAX = "99999999"
        UNITS = "None"
        CATDESC = "dfb_wav_en"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <!-- Channel select: bits 3:0 -->
  <cdf_var
      name   = "dfb_wav_sel"
      type   = "integer">
  <cdf_att
        FIELDNAM = "dfb_wav_sel"
        FORMAT = "I08"
        LABLAXIS = "dfb_wav_sel"
        VAR_TYPE = "data"
        FILLVAL = "-1.0E31"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-99999999"
        VALIDMAX = "99999999"
        SCALEMIN = "-99999999"
        SCALEMAX = "99999999"
        UNITS = "None"
        CATDESC = "dfb_wav_sel"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>


  <!-- The packet payload length excluding the subseconds -->
  <item
      name   = "wf_pkt_payload_length"
      type   = "integer"
      value  = "ccsds_meat_length - fields_tertiary_header_length"
      />

  <!-- Two byte checksum at the end of the packet -->
  <item
      name   = "wf_pkt_chksum_start"
      type   = "integer"
      value  = "(wf_pkt_payload_length - 2)*8"
      />
  <cdf_var
      name   = "wf_pkt_chksum"
      type   = "integer"
      base   = "event_data_start"
      offset = "wf_pkt_chksum_start"
      width  = "16"
      />
      
   <item
      name   = "wf_pkt_data_elements"
      type   = "integer"
      value  = "(wf_pkt_payload_length - 4) / 2"
      />
    
    <cdf_var
      name   = "wf_pkt_data"
      type   = "integer"
      convert_routine = "wf_pkt_convert"
      nelem  = "wf_pkt_data_elements">
  <cdf_att
        FIELDNAM = "wf_pkt_data"
        FORMAT = "I08"
        LABLAXIS = "wf_pkt_data"
        VAR_TYPE = "data"
        FILLVAL = "-1.0E31"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-99999999"
        VALIDMAX = "99999999"
        SCALEMIN = "-99999999"
        SCALEMAX = "99999999"
        UNITS = "None"
        CATDESC = "wf_pkt_data"
        DEPEND_0 = "epoch">
    </cdf_att>
      </cdf_var>

