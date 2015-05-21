;+
; PROCEDURE:
;       mvn_ngi_load
; PURPOSE:
;       Loads NGIMS L2 data
;       Time-series densities for each mass will be storead in tplot variables:
;       'mvn_ngi_(filetype)_(focusmode)_abundance_mass???'
;       Each column in csv files will be stored in 'mvn_ngi_(filetype)_(focusmode)_(tagname)'
; CALLING SEQUENCE:
;       mvn_ngi_load
; INPUTS:
;       None
; OPTIONAL KEYWORDS:
;       trange: time range (if not present then timerange() is called)
;       filetype: (Def. ['csn','cso','ion'])
;       files: paths to local files to read in
;              if set, does not retreive files from server
;              if multiple versions are found, the latest version file will be loaded
;       cps_dt: generates cps_dt tplot variables for each unique mass
;       other keywords are passed to 'mvn_pfp_file_retrieve'
; CREATED BY:
;       Yuki Harada on 2015-01-29
; NOTES:
;       Requires IDL 7.1 or later to read in .csv files
;       Use 'mvn_ngi_read_csv' to load ql data
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2015-05-19 14:14:18 -0700 (Tue, 19 May 2015) $
; $LastChangedRevision: 17649 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/ngi/mvn_ngi_load.pro $
;-

pro mvn_ngi_load, trange=trange, filetype=filetype, verbose=verbose, _extra=_extra, files=files, cps_dt=cps_dt

  if ~keyword_set(filetype) then filetype = ['csn','cso','ion']


  for i_filetype=0,n_elements(filetype)-1 do begin

;- retrieve files
     if ~keyword_set(files) then begin
        pformat = 'maven/data/sci/ngi/l2/YYYY/MM/mvn_ngi_l2_'+filetype[i_filetype]+'-abund-*_YYYYMMDDThh????_v??_r??.csv'
        f = mvn_pfp_file_retrieve(pformat,/hourly_names,/last_version,/valid_only,trange=trange,verbose=verbose, _extra=_extra)
     endif else begin ;- local files
        w = where( strmatch(files,'*'+filetype[i_filetype]+'*',/fold_case) eq 1, nw )
        if nw gt 0 then begin
           ftmp = files[w]                     ;- input files that possibly have mixed, case-sensitive names
           ftmp = ftmp[sort(strlowcase(ftmp))] ;- case-insensitively sort in alphabetical order
           prefnames = strmid(ftmp,0,strpos(ftmp[0],'_v')) ;- assuming all files have the same case-insensitive format
           lastidx = uniq(strlowcase(prefnames)) ;- case-insensitively select the latest version
           f = ftmp[lastidx]
        endif else f = ''
     endelse

;- check files
     if total(strlen(f)) eq 0 then begin
        dprint,dlevel=2,verbose=verbose,filetype[i_filetype]+' files not found'
        continue
     endif

;- read in files and store data into structures
     for i_file=0,n_elements(f)-1 do begin
        dprint,dlevel=1,verbose=verbose,'reading in '+f[i_file]
        if i_file eq 0 then d = read_csv(f[i_file],header=dh) else begin
           dold = d
           dnew = read_csv(f[i_file],header=dh)
           tagnames = tag_names(d)
           for i_c = 0,n_elements(dh)-1 do str_element, d, tagnames[i_c], [dold.(i_c),dnew.(i_c)],/add
        endelse
     endfor

;- check time
     idx = where(strmatch(dh,'t_unix'),idx_cnt)
     if idx_cnt ne 1 then begin
        dprint,dlevel=1,verbose=verbose,'No unique t_unix column in csv files: ',f
        continue
     endif
     t_unix = double(d.(idx))

;- check mode
     idx = where(strmatch(dh,'focusmode'),idx_cnt)
     if idx_cnt ne 1 then begin
        dprint,dlevel=1,verbose=verbose,'No unique focusmode column in csv files: ',f
        continue
     endif
     focusmode = d.(idx)

;- check mass
     idx = where(strmatch(dh,'*mass'),idx_cnt)
     if idx_cnt ne 1 then begin
        dprint,dlevel=1,verbose=verbose,'No unique mass column in csv files: ',f
        continue
     endif
     mass = double(d.(idx))

;- check abundance
     idx = where(strmatch(dh,'abundance'),idx_cnt)
     if idx_cnt ne 1 then begin
        dprint,dlevel=1,verbose=verbose,'No unique abundance column in csv files: ',f
        continue
     endif
     abundance = double(d.(idx))

;- check cps_dt if /cps_dt is set
     if keyword_set(cps_dt) then begin
        idx = where(strmatch(dh,'cps_dt'),idx_cnt)
        if idx_cnt ne 1 then begin
           dprint,dlevel=1,verbose=verbose,'No unique cps_dt column in csv files: ',f
           qcps_dt = !values.f_nan
        endif else qcps_dt = double(d.(idx))
     endif

     modes = ['csn', 'osnt', 'osnb', 'osion']

;- store tplot variables
     for i_mode=0,n_elements(modes)-1 do begin
        idx = where(focusmode eq modes[i_mode], idx_cnt)
        if idx_cnt eq 0 then continue

;- store all columns (not necessarily monotonic)
        for i_c=0,n_elements(dh)-1 do $
           store_data,verbose=verbose,'mvn_ngi_'+filetype[i_filetype]+'_'+modes[i_mode]+'_'+dh[i_c],data={x:t_unix,y:d.(i_c)}

;- store abundance and cps_dt for each unique mass
        uniqmass = mass[uniq(mass,sort(mass))]
        for i_mass=0,n_elements(uniqmass)-1 do begin
           idx = where( mass eq uniqmass[i_mass] and focusmode eq modes[i_mode],idx_cnt )
           if idx_cnt eq 0 then continue
           if long(uniqmass[i_mass]) eq uniqmass[i_mass] then massstr = string(uniqmass[i_mass],f='(i3.3)') else massstr = string(uniqmass[i_mass],f='(i3.3)')+'_'+string((uniqmass[i_mass]-long(uniqmass[i_mass]))*1000,f='(i3.3)')
           store_data,verbose=verbose,'mvn_ngi_'+filetype[i_filetype]+'_'+modes[i_mode]+'_abundance_mass'+massstr,data={x:t_unix[idx],y:abundance[idx]}
           if keyword_set(cps_dt) then if total(finite(qcps_dt)) gt 0 then store_data,verbose=verbose,'mvn_ngi_'+filetype[i_filetype]+'_'+modes[i_mode]+'_cps_dt_mass'+massstr,data={x:t_unix[idx],y:qcps_dt[idx]}
        endfor                  ;- i_mass
     endfor                     ;- i_mode

  endfor                        ;- i_filetype

end
