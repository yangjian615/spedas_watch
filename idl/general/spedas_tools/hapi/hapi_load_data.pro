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
;         capabilities: describes relevant capabilities for the HAPI server
;         catalog:      provides a list of datasets available from the HAPI server
;         info:         provides information on a given dataset
;
; EXAMPLE:
;
;
; NOTES:
;         - trange is required to load the data into tplot vars; the other keywords are informational
;         - Requires IDL 8.2 or later due to json_parse usage
;         
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-06-06 18:03:50 -0700 (Tue, 06 Jun 2017) $
;$LastChangedRevision: 23426 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spedas_tools/hapi/hapi_load_data.pro $
;-

pro hapi_load_data, trange=trange, capabilities=capabilities, catalog=catalog, info=info, server=server
  if undefined(server) then server = 'datashop.elasticbeanstalk.com'
  dataset_table = hash()
  info_dataset = ''
  neturl = obj_new('IDLnetURL')
  param_names = []
  spd_graphics_config

  neturl->SetProperty, URL_HOST = server
  neturl->SetProperty, URL_PORT = 80
  neturl->SetProperty, URL_SCHEME = 'http'
  
  if keyword_set(capabilities) then begin
    neturl->SetProperty, URL_PATH='/hapi/capabilities'
    capabilities = json_parse(string(neturl->get(/buffer)))
    print, 'HAPI v' + capabilities['HAPI']
    print, 'Output formats: ' + strjoin(capabilities['outputFormats'].toArray(), ', ')
  endif
  
  if keyword_set(catalog) or keyword_set(info) or keyword_set(trange) then begin
    neturl->SetProperty, URL_PATH='/hapi/catalog'
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
    neturl->SetProperty, URL_PATH='/hapi/info?id='+info_dataset
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
      neturl->SetProperty, URL_PATH='/hapi/data?id='+info_dataset+'&time.min='+time_min+'&time.max='+time_max 
    endif else begin
      dprint, dlevel=0, 'No data available for this trange; data availability for '+info_dataset+' is limited to: ' + info['startDate'] + ' - ' + info['stopDate']
      return
    endelse

    csv_data = neturl->get(filename='testdata')
    
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
    for var_idx = 0, n_elements(variables)-1 do begin
      if variables[var_idx].hasKey('name') and variables[var_idx].hasKey('epoch') and (variables[var_idx])['data'] ne !null then begin
        store_data, strlowcase((variables[var_idx])['name']), data={x: (variables[var_idx])['epoch'], y: (variables[var_idx])['data']}
      endif
    endfor
  endif
end