;This routine is used by the main routine below to deal with one spacecraft at a time.
function get_mms_burst_metadata_for_one_spacecraft, start_time, end_time, sc_id, struct
  ;TODO: sanity check start_time and end_time, should be seconds since 1958 (TAI epoch).
  ;TODO: sanity check valid sc_id
  
  ;Define the dataset name.
  dataset = sc_id + "_burst_metadata"
  ;Define the URL path.
  ;path = "latis-mms/dap/" + dataset + ".csv"
  path = "mms/sdc/sitl/latis/dap/" + dataset + ".csv"

  ;Construct the LaTiS query string.
  ;Add the list of desired parameters.
  ;Note, order will not be respected. 
  ;  LaTiS must be configured to serve parameters in this order.
  ;TODO: get from struct?
  query = "TAITIMESTAMP,DATASEGMENTID,CDQ,MDQ"
  ;Add the time selections. Inclusive on low end, exclusive on high end.
  query = query + "&TAITIMESTAMP>=" + strtrim(start_time,2)
  query = query + "&TAITIMESTAMP<"  + strtrim(end_time,2)
  
  ;Get IDLnetUrl object. May prompt for login.
  ;connection = get_mms_sitl_connection()
  connection = get_mms_sitl_connection()
  
  ;Make the request. Get an array of comma separated value strings.
  data = execute_mms_sitl_query(connection, path, query)
  
  ;Return -1 if no data was found. Only 1 header row.
  ;This should also handle the case where a LONG error code is returned.
  if n_elements(data) le 1 then begin
    printf, -2, "WARN: No burst metadata found for " + sc_id + " with query: " + query
    return, -1
  endif
  
  ;Drop one line header
  data = data[1:*]
  
  ;Convert the data from a array of records  with comma separated values
  ;to an array of structures containing the data with the appropriate types.
  result = parse_samples(data, struct)
  
  return, result
  
end

;=============================================================================

function get_mms_burst_metadata, start_time, end_time, sc_id=sc_id 

  ;Deal with one s/c at a time, then stitch the results together.
  ;Treat the sc_id parameter as an array. If not defined, default to all spacecraft.
  ;Make sure sc_ids are lower case.
  if (n_elements(sc_id) gt 0) then ids = strlowcase(sc_id) else ids = ['mms1', 'mms2', 'mms3', 'mms4']
  
  ;Define number of spacecraft.
  nsc = n_elements(ids)
  
  ;Define the structure template for each record.
  struct = {record, time: 0UL, dataSegmentId: 0L, cdq: 0S, mdq: 0S}
  
  ;Request data for each spacecraft. Build up a 'data' array of results.
  for isc = 0, nsc-1 do begin 
    scdata = get_mms_burst_metadata_for_one_spacecraft(start_time, end_time, ids[isc], struct) 
    ;If there is no data for one, there shouldn't be data for any, return -1, error message already printed
    if size(scdata, /type) ne 8 then return, -1
    ;Append results to a 'data' array
    if (isc eq 0) then data = scdata else data = [temporary(data), scdata]
  endfor
 
  ;Define number of samples.
  ;Assumes we got the same count for each spacecraft, which we should.
  nsamp = n_elements(data) / nsc
  
  ;Define result structure.
  ;Deal with up to 4 spacecraft, there must be a better way
  ;Note, using "name" in the structure complicates reuse.
  if (nsc eq 1) then result_struct = create_struct(ids, struct)
  if (nsc eq 2) then result_struct = create_struct(ids, struct, struct)
  if (nsc eq 3) then result_struct = create_struct(ids, struct, struct, struct)
  if (nsc eq 4) then result_struct = create_struct(ids, struct, struct, struct, struct)

  ;Create the resulting data structure: array of structures
  result = replicate(result_struct, nsamp)
  ;Fill up the result. Effectively need to transpose data.
  for i = 0, nsamp-1 do begin
    ;iterate over spacecraft
    for isc = 0, nsc-1 do begin
      index = isc * nsamp + i
      result[i].(isc) = data[index]
    endfor
  endfor
  
  return, result
  
end
