function get_mms_burst_segment_status, start_time=start_time, end_time=end_time, $
  is_pending=is_pending, data_segment_id=data_segment_id

  ;Define the structure template for the data segment record.
  struct = { data_segment,  $
             dataSegmentId  :0L,  $
             taiStartTime   :0UL,  $
             taiEndTime     :0UL,  $
             parameterSetId :"",  $
             fom            :0.0,  $
             isPending      :0,  $
             inPlayList     :0,  $
             status         :"",  $
             numEvalCycles  :0,  $
             sourceId       :"",  $
             createTime     :"",  $
             finishTime     :""  $
           }

  ;Define the dataset name.
  dataset = "mms_burst_data_segment"
  ;Define the URL path.
  path = "mms/sdc/sitl/latis/dap/" + dataset + ".csv"
  
  ;Construct the LaTiS query.
  query = ""
  ;Add parameters, use tag names from struct.
  tags = tag_names(struct) ;Note, these will be all caps
  ntags = n_elements(tags)
  for itag = 0, ntags-2 do query = query + tags[itag] + ','
  query = query + tags[ntags-1]  ;last element without ","
  ;Add constraints
  if n_elements(data_segment_id) gt 0 then query = query + "&DATASEGMENTID=" + strtrim(data_segment_id,2)
  ;Time range: include segment if it is partially in the requested range
  if n_elements(start_time)      gt 0 then query = query + "&TAIENDTIME>"    + strtrim(start_time,2)
  if n_elements(end_time)        gt 0 then query = query + "&TAISTARTTIME<"  + strtrim(end_time,2)
  ;is_pending is effectively a boolean
  if n_elements(is_pending)      gt 0 then begin
    if (is_pending) then query = query + "&ISPENDING=1"  $
    else query = query + "&ISPENDING=0" 
  endif
    
  ;Get IDLnetUrl object. May prompt for login.
  ;connection = get_mms_sitl_connection(host="sdc-web1", port="8080")
  connection = get_mms_sitl_connection()
  
  ;Make the request. Get an array of comma separated value strings.
  data = execute_mms_sitl_query(connection, path, query)
  
  ;Return -1 if no data was found. Only 1 header row.
  ;This should also handle the case where a LONG error code is returned.
  if n_elements(data) le 1 then begin
    printf, -2, "WARN: No burst segment found for query: " + query
    return, -1
  endif

  ;Drop one line header
  data = data[1:*]
  
  ;Convert the data from a array of records  with comma separated values
  ;to an array of structures containing the data with the appropriate types.
  result = parse_samples(data, struct)
  
  ;Return the resulting structure.
  return, result
  
end
