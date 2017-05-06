;
;  $LastChangedBy: spfuser $
;  $LastChangedDate: 2017-05-05 17:53:47 -0700 (Fri, 05 May 2017) $
;  $LastChangedRevision: 23274 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/common/spp_fld_load_tmlib_data.pro $
;

function spp_fld_load_tmlib_data, l1_data_type,  $
  varformat = varformat, cdf_att = cdf_att, times = times, idl_att = idl_att, $
  success = success

  success = 0

  ;
  ; Find directory of XML configuration file.
  ;

  if n_elements(varformat) EQ 0 then varformat = '.*'

  cdf_xml_dir = getenv('SPP_FLD_CDF_XML_DIR')

  cdf_xml_l0_to_l1_dir = cdf_xml_dir + 'l0_to_l1/'

  cdf_xml = cdf_xml_l0_to_l1_dir + 'l1_' + l1_data_type + '.xml'

  ;
  ; Prepare data structure for storing the data
  ;

  ; Read XML table from APID definition file.  The output is a list
  ; (xml_extract) of ordered hashes, with each ordered hash containing an
  ; item from the definition file.

  print, cdf_xml

  xml_data = read_xml8(cdf_xml)

  ; Return global CDF attributes from XML file.
  ; If no CDF attributes are found, there will be no CDF file created.

  tmlib_event = ((xml_data['items'])['tmlib'])['tmlib_event']

  if (xml_data['items']).HasKey('cdf_global') then begin

    cdf_att = (xml_data['items'])['cdf_global']

  endif else begin

    dprint, 'No CDF global metadata information found in XML file', dlevel = 2

    return, 0

  endelse

  if (xml_data['items']).HasKey('cdf_var') then begin

    xml_cdf_vars = (xml_data['items'])['cdf_var']

  endif else begin

    dprint, 'No CDF variable information found in XML file', dlevel = 2

    return, 0

  endelse

  if (xml_data['items']).HasKey('idl_att') then begin

    idl_att = (xml_data['items'])['idl_att']

  endif else begin

    idl_att = ORDEREDHASH()

  endelse


  ; From the list, make a hash object (data_hash).  We make the hash so that
  ; we can index by the item name.  Also make a list of the hash keys (item
  ; names (var_names).
  ;
  ; Note that the 'xml_cdf_vars' returns a different variable type if only one
  ; cdf_var is specified in the XML file (the typename conditional below captures
  ; this special case.

  data_hash = ORDEREDHASH()

  if typename(xml_cdf_vars) EQ 'LIST' then begin

    foreach cdf_var, xml_cdf_vars do begin

      data_hash[cdf_var['name']] = cdf_var

    endforeach

  endif else begin

    data_hash[xml_cdf_vars['name']] = xml_cdf_vars

  endelse

  var_names = data_hash.Keys()

  ; Find indices of the data_hash for which the name matches the input
  ; string (varformat).  Varformat is a scalar or vector of regular expressions
  ; (not globbing expressions).  Each element of varformat is compared to
  ; the list of names and the union of all matching names is returned in
  ; the match_ind array.
  ;
  ; Note that the 'xml_cdf_vars' returns a different variable type if only one
  ; cdf_var is specified in the XML file (the typename conditional below captures
  ; this special case.

  name_match = var_names.Map(Lambda(x:0))

  if typename(xml_cdf_vars) EQ 'LIST' then begin

    for i = 0, n_elements(varformat) - 1 do begin

      name_match_i = var_names.Map(Lambda(x, y: x.Matches(y)), varformat[i])

      name_match = name_match.Map(Lambda(x, y: max([x,y])), name_match_i)

    endfor

  endif else begin

    for i = 0, n_elements(varformat) - 1 do begin

      if name_match[0] EQ 0 then begin
        name_match = var_names.Map(Lambda(x, y: x.Matches(y)), varformat[i])
      endif

    endfor

  endelse

  match_ind = where(name_match.ToArray(), match_count)

  ; Select only the elements of data_hash which match one of the varformat
  ; specifications.  Each element itself is a hash, which contains the
  ; parameters from the XML file.  A 'data' field is added to each element,
  ; which will be used to contain the data obtained from TMlib.

  if match_count GT 0 then begin

    dprint, var_names[match_ind], dlevel = 2

    var_names = var_names[match_ind]
    data_hash = data_hash[var_names]

    for i = 0, n_elements(match_ind) - 1 do begin

      (data_hash[var_names[i]])['data'] = LIST()

    endfor

  endif else begin

    dprint, 'No items which match VARFORMAT', dlevel = 1

    return, 0

  endelse

  ;
  ; Set up parameters for TMlib
  ;

  get_timespan, trange

  t0 = sunseconds_to_ur8(time_double(trange[0]))
  t1 = sunseconds_to_ur8(time_double(trange[1]))

  ; Select TMlib server

  defsysv, '!TMLIB', exists = exists

  if exists then begin

    server = !tmlib.server

  endif else begin

    print, 'No SPP FIELDS TMlib server selected, use SPP_FLD_TMLIB_INIT'

    return, 0

  endelse

  err = tm_select_server(server)
  dprint, 'Select Server status: ', dlevel = 3

  ; Select MSIE (Mission, Spacecraft, Instrument, Event)
  err = tm_select_domain(sid, "SPP", "SPP", "Fields", tmlib_event)
  dprint, 'Select MSIE status: ', dlevel = 3
  dprint, 'Stream ID: ', dlevel = 3
  if err NE 0 then spp_fld_print_error_stack, err, sid

  ; Select a time range
  err = tm_select_stream_timerange(sid, t0, t1)
  dprint, 'Select timerange status: ', dlevel = 3
  if err NE 0 then spp_fld_print_error_stack, err, sid

  ; Find an event
  serr = tm_find_event(sid)
  dprint, 'First event status', dlevel = 3
  if serr NE 0 then begin

    spp_fld_print_error_stack, serr, sid
    return, 0

  end

  times = LIST()

  tprint = 0.

  while (serr GE 0) do begin

    err = tm_get_position(sid, ur8)
    err = tm_get_item_r8(sid, "ccsds_scet_ur8", ur8_ccsds, 1, size)

    err = tm_get_item_i4(sid, "ccsds_total_packet_length", $
      ccsds_pkt_len, 1, size)

    ;err = tm_get_item_i4(sid, "ccsds_met_sec", met_ccsds, 1, size)

    time = ur8_to_sunseconds(ur8_ccsds)

    dprint, n_elements(times), ' / ', ur8_ccsds, ' / ', $
      time_string(time), dlevel = 4

    dprint, ccsds_pkt_len, dlevel = 4

    t0 = systime(1)

    if t0 - tprint GT 5 then begin

      print, time_string(time)
      tprint = t0

    end

    serr = tm_find_event(sid)

    dprint, 'serr', serr, dlevel = 4

    if serr EQ 0 then begin

      times.Add, time

      ; For certain APIDs, some data items only exist in some packets
      ; but not others.  Requesting the items when they do not exist can cause
      ; errors.  null_items returns a list of items NOT to ask for in the
      ; following loop.

      null_items = LIST()
      if idl_att.HasKey('null_routine') then begin

        null_items = CALL_FUNCTION(idl_att['null_routine'], sid)

      end

      for i = 0, n_elements(var_names) - 1 do begin

        var_name = var_names[i]

        ; Check whether the request should be suppressed

        !NULL = null_items.Where(var_name, count = data_null_count)

        if data_null_count EQ 0 then begin

          ; Get the number of elements in the data item

          nelem = spp_fld_tmlib_item_nelem(data_hash[var_name], sid)

          returned_item = !NULL

          var_type = strlowcase((data_hash[var_name])['type'])

          case var_type of
            'double': err = tm_get_item_r8(sid, var_name, returned_item, nelem, n_returned)
            'integer': err = tm_get_item_i4(sid, var_name, returned_item, nelem, n_returned)
            ELSE: err = tm_get_item_i4(sid, var_name, returned_item, nelem, n_returned)
          endcase

        endif else begin

          returned_item = !NULL

        endelse

        (data_hash[var_name])['data'].Add, returned_item

        ;dprint, getdebug = dprint_debug

        ;      if dprint_debug GE 4 then begin
        ;        ;dprint, '    ', var_name, item_str, dlevel = 4
        ;
        ;        item_str = n_elements(returned_item) GT 1 ? string(returned_item[0]) + $
        ;          ', ...' : string(returned_item)
        ;
        ;      endif

      endfor

    endif

  endwhile

  ; Return (optional) IDL attributes from XML file.
  ; IDL attributes are used in processing of data (e.g. manipulation of
  ; the MAG survey APIDs to change from ~512 vectors per a single packet time to
  ; 1 vector per time tag.

  if idl_att.HasKey('convert_routine') then begin

    old_data_hash = data_hash

    convert_routine = idl_att['convert_routine']

    call_procedure, convert_routine, data_hash, times, cdf_att

  endif

  if n_elements(times) EQ 0 then begin
    
    success = -1
    
    return, data_hash
    
  endif

  success = 1

  return, data_hash

end