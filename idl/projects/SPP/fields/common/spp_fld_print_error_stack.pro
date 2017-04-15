pro print_error_stack,err, stream_id

  ErrorBuffSize = 2500
  print, "Error = ", err
  err = TM_Error_Stack(stream_id, "name", ErrorDump, ErrorBuffSize, size)
  print, "Error Name = ", ErrorDump
  err = TM_Error_Stack(stream_id, "description", ErrorDump, ErrorBuffSize, size)
  print, "Error Description = ", ErrorDump
  err = TM_Error_Stack(stream_id, "message", ErrorDump, ErrorBuffSize, size)
  print, "Error Message = ", ErrorDump
  err = TM_Error_Stack(stream_id, "code", ErrorDump, ErrorBuffSize, size)
  print, "Error Code = ", ErrorDump

end
