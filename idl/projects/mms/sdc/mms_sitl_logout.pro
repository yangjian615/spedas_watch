pro mms_sitl_logout
  common mms_sitl_connection, netUrl, connection_time
  
  obj_destroy, netUrl
  netURL = 0
  dummy = temporary(netURL)
  dummy = temporary(connection_time)
end
