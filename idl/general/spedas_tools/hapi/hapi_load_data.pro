;+
; PROCEDURE:
;         hapi_load_data
;
; PURPOSE:
;         Load data and query information from a Heliophysics API server
;
; KEYWORDS:
;         trange:       time range of interest [starttime, endtime] with the format
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         capabilities: describes relevant capabilities for the HAPI server (optional)
;         catalog:      provides a list of datasets available from the HAPI server (optional)
;         info:         provides information on a given dataset (optional)
;         dataset:      dataset to load (optional)
;         
;         server:       HAPI server to connect to (e.g, 'http://datashop.elasticbeanstalk.com/hapi')
;
; EXAMPLES:
;  List server capabilities:
;    IDL> hapi_load_data, /capabilities, server='http://datashop.elasticbeanstalk.com/hapi'
;    HAPI v1.1
;    Output formats: csv, binary, json
;  
;  List the datasets available on this server:
;    IDL> hapi_load_data, /catalog, server='http://datashop.elasticbeanstalk.com/hapi'
;    HAPI v1.1
;    1: CASSINI_LEMMS_PHA_CHANNEL_1_SEC
;    2: CASSINI_LEMMS_REG_CHANNEL_PITCH_ANGLE_10_MIN_AVG
;    ....
;  
;  Get info on a dataset:
;    IDL> hapi_load_data, /info, dataset='spase://VEPO/NumericalData/Voyager1/LECP/Flux.Proton.PT1H', server='http://datashop.elasticbeanstalk.com/hapi'
;    HAPI v1.1
;    Dataset: spase://VEPO/NumericalData/Voyager1/LECP/Flux.Proton.PT1H
;    Start: 1977-09-07T00:00:00.000
;    End: 2017-05-02T21:38:00.000
;    Parameters: Epoch, year, doy, hr, dec_year, dec_doy, flux, flux_uncert
;  
;  Load and plot the Voyager flux data:
;    IDL> hapi_load_data, trange=['77-09-27', '78-01-20'], dataset='spase://VEPO/NumericalData/Voyager1/LECP/Flux.Proton.PT1H', server='http://datashop.elasticbeanstalk.com/hapi'
;    IDL> tplot, 'flux'
;  
; NOTES:
;         - capabilities, catalog, info keywords are informational
;         - Requires IDL 8.3 or later due to json_parse + orderedhash usage
;         
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2018-01-19 12:00:52 -0800 (Fri, 19 Jan 2018) $
;$LastChangedRevision: 24543 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spedas_tools/hapi/hapi_load_data.pro $
;-

pro hapi_load_data, trange=trange, capabilities=capabilities, catalog=catalog, info=info, server=server, dataset=dataset, path=path, port=port, scheme=scheme, prefix=prefix, tplotvars=tplotvars

  catch, error_status
  if error_status ne 0 then begin
    catch, /cancel
    dprint, dlevel=0, 'Error: ' + !error_state.msg
    return
  endif
  if undefined(server) then begin
    dprint, dlevel = 0, 'Error, no server specified; example servers include:'
    dprint, dlevel = 0, '1) http://datashop.elasticbeanstalk.com/hapi'
    dprint, dlevel = 0, '2) http://tsds.org/get/SSCWeb/hapi'
    dprint, dlevel = 0, '3) http://mag.gmu.edu/TestData/hapi'
    dprint, dlevel = 0, '4) https://voyager.gsfc.nasa.gov/hapiproto'
    dprint, dlevel = 0, '5) http://jfaden.net/HapiServerDemo/hapi'
    return
  endif else begin
    url_parts = parse_url(server)
    ; just in case the user specified a server without the scheme
    if url_parts.scheme eq '' then url_parts = parse_url('http://'+server)
    url_host = url_parts.host
    url_port = url_parts.port
    url_path = url_parts.path
    url_scheme = url_parts.scheme
  endelse
  
  if undefined(capabilities) and undefined(catalog) and undefined(info) and undefined(trange) then begin
    trange = timerange()
  endif
  
  if !version.release lt '8.3' then begin
    dprint, dlevel = 0, 'Error, this routine only supports IDL 8.3 and later due to  json_parse + orderedhash usage'
    return
  endif
  
  if undefined(path) then path = url_path
  if undefined(port) then port = url_port
  if undefined(scheme) then scheme = url_scheme

  dataset_table = hash()
  if keyword_set(dataset) then info_dataset = dataset else info_dataset = ''
  neturl = obj_new('IDLnetURL')
  param_names = []
  spd_graphics_config

  neturl->SetProperty, URL_HOST = url_host
  neturl->SetProperty, URL_PORT = port
  neturl->SetProperty, URL_SCHEME = scheme
  
  if keyword_set(capabilities) then begin
    neturl->SetProperty, URL_PATH=path+'/capabilities'
    capabilities = json_parse(string(neturl->get(/buffer)))
    print, 'HAPI v' + capabilities['HAPI']
    print, 'Output formats: ' + strjoin(capabilities['outputFormats'].toArray(), ', ')
  endif
  
  if keyword_set(catalog) or keyword_set(info) or keyword_set(trange) and info_dataset eq '' then begin
    neturl->SetProperty, URL_PATH=path+'/catalog'
    catalog = json_parse(string(neturl->get(/buffer)))
    available_datasets = catalog['catalog']
    print, 'HAPI v' + catalog['HAPI']
    for dataset_idx = 0, n_elements(available_datasets)-1 do begin
      print, strcompress(string(dataset_idx+1), /rem) + ': ' + (available_datasets[dataset_idx])['id']
      dataset_table[strcompress(string(dataset_idx+1), /rem)] = (available_datasets[dataset_idx])['id']
    endfor
  endif
  
  if keyword_set(info) or keyword_set(trange) then begin
    if info_dataset eq '' then begin
      read, info_dataset, prompt='Select a dataset: '
      if dataset_table.hasKey(info_dataset) then info_dataset = dataset_table[info_dataset]
    endif
    neturl->SetProperty, URL_PATH=path+'/info?id='+info_dataset
    info = json_parse(string(neturl->get(/buffer)))
    
    for param_idx = 0, n_elements(info['parameters'])-1 do begin
      append_array, param_names, ((info['parameters'])[param_idx])['name']
    endfor
    print, 'HAPI v' + info['HAPI']
    print, 'Dataset: ' + info_dataset
    print, 'Start: ' + info['startDate']
    print, 'End: ' + info['stopDate']
    print, 'Parameters: ' + strjoin(param_names, ', ')
  endif
  
  if keyword_set(trange) then begin
    time_min = time_string(trange[0], tformat='YYYY-MM-DDThh:mm:ss.fff')
    time_max = time_string(trange[1], tformat='YYYY-MM-DDThh:mm:ss.fff')
    
    if time_double(time_min) ge time_double(info['startDate']) and time_double(time_max) le time_double(info['stopDate']) then begin
      neturl->SetProperty, URL_PATH=path+'/data?id='+info_dataset+'&time.min='+time_min+'&time.max='+time_max 
    endif else begin
      dprint, dlevel=0, 'No data available for this trange; data availability for '+info_dataset+' is limited to: ' + info['startDate'] + ' - ' + info['stopDate']
      return
    endelse

    csv_data = neturl->get(filename='hapidata')
    
    csv = read_csv(csv_data)
    
    ; extract the data
    for param_idx = 0, n_elements(info['parameters'])-1 do begin
      variable = (info['parameters'])[param_idx]
      if strlowcase(((info['parameters'])[param_idx])['name']) eq 'epoch' or $
        strlowcase(((info['parameters'])[param_idx])['name']) eq 'time' then begin
        epoch = time_double(csv.(param_idx))
      endif else begin
        if ~undefined(epoch) then variable['epoch'] = epoch
      endelse

      if (info['parameters'])[param_idx].hasKey('size') then begin
        data = dblarr(n_elements(csv.(param_idx)), (((info['parameters'])[param_idx])['size'])[0])
        for data_idx = 0, (((info['parameters'])[param_idx])['size'])[0]-1 do begin
          thedata = csv.(param_idx+data_idx)
          if (info['parameters'])[param_idx].hasKey('fill') then begin
            datanofill = where(thedata le ((info['parameters'])[param_idx])['fill'], count)
            if count ne 0 then thedata[datanofill] = !values.d_nan
          endif
          data[*, data_idx] = thedata
        endfor
      endif else begin
        data = csv.(param_idx)
        if (info['parameters'])[param_idx].hasKey('fill') && ((info['parameters'])[param_idx])['fill'] ne !null then begin
          datanofill = where(data le ((info['parameters'])[param_idx])['fill'], count)
          if count ne 0 then data[datanofill] = !values.d_nan
        endif
      endelse
      variable['data'] = data
      
      append_array, variables, variable
    endfor
    
    ; turn the variable tables into proper tplot variables
    tplotvars = []
    for var_idx = 0, n_elements(variables)-1 do begin
      if variables[var_idx].hasKey('name') and variables[var_idx].hasKey('epoch') and (variables[var_idx])['data'] ne !null then begin
        if undefined(prefix) then prefix=''
        tname = prefix + strlowcase((variables[var_idx])['name'])        
        store_data, tname, data={x: (variables[var_idx])['epoch'], y: (variables[var_idx])['data']}
        append_array, tplotvars, tname
      endif
    endfor
  endif
end