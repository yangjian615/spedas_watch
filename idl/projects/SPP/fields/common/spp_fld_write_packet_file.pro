pro spp_fld_write_packet_file, file, packets

  openw, unit, file, /get_lun

  foreach packet, packets do begin

    writeu, unit, byte(packet)

  end

  free_lun, unit

end
