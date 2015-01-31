;+
; PROCEDURE:
;       mvn_ngi_load
; PURPOSE:
;       Simple load procedure for NGIMS L2 data
; CALLING SEQUENCE:
;       mvn_ngi_load
; INPUTS:
;       None
; OPTIONAL KEYWORDS:
;       trange: time range
;       filetype: (Def. ['csn','cso','ion'])
; CREATED BY:
;       Yuki Harada on 2015-01-29
; NOTES:
;       Requires IDL 7.1 or later to read in .csv files
;       Currently only for abundance data files
;       Use 'mvn_ngi_read_csv' to load ql data
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2015-01-29 20:00:45 -0800 (Thu, 29 Jan 2015) $
; $LastChangedRevision: 16790 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/ngi/mvn_ngi_load.pro $
;-

pro mvn_ngi_load, trange=trange, filetype=filetype, verbose=verbose, _extra=_extra

  if ~keyword_set(filetype) then filetype = ['csn','cso','ion']


  for i_filetype=0,n_elements(filetype)-1 do begin

;- retrieve files
     pformat = 'maven/data/sci/ngi/l2/YYYY/MM/mvn_ngi_l2_'+filetype[i_filetype]+'-abund-*_YYYYMMDDThh????_v??_r??.csv'
     f = mvn_pfp_file_retrieve(pformat,/hourly_names,/last_version,/valid_only,trange=trange,verbose=verbose, _extra=_extra)

;- check files
     if total(strlen(f)) eq 0 then begin
        dprint,dlevel=2,verbose=verbose,filetype[i_filetype]+' files not found'
        continue
     endif

;- read in files and store data into structures
     for i_file=0,n_elements(f)-1 do begin
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
        dprint,dlevel=1,verbose=verbose,'No unique t_unix column in csv file: ',f[i_file]
        continue
     endif
     t_unix = double(d.(idx))

;- check mode
     idx = where(strmatch(dh,'focusmode'),idx_cnt)
     if idx_cnt ne 1 then begin
        dprint,dlevel=1,verbose=verbose,'No unique focusmode column in csv file: ',f[i_file]
        continue
     endif
     focusmode = d.(idx)

;- check mass
     idx = where(strmatch(dh,'*mass'),idx_cnt)
     if idx_cnt ne 1 then begin
        dprint,dlevel=1,verbose=verbose,'No unique mass column in csv file: ',f[i_file]
        continue
     endif
     mass = double(d.(idx))

;- check abundance
     idx = where(strmatch(dh,'abundance'),idx_cnt)
     if idx_cnt ne 1 then begin
        dprint,dlevel=1,verbose=verbose,'No unique abundance column in csv file: ',f[i_file]
        continue
     endif
     abundance = double(d.(idx))


     modes = ['csn', 'osnt', 'osnb', 'osion']

;- store tplot variables
     for i_mode=0,n_elements(modes)-1 do begin
        idx = where(focusmode eq modes[i_mode], idx_cnt)
        if idx_cnt eq 0 then continue

;- store all columns (not necessarily monotonic)
        for i_c=0,n_elements(dh)-1 do $
           store_data,verbose=verbose,'mvn_ngi_'+filetype[i_filetype]+'_'+modes[i_mode]+'_'+dh[i_c],data={x:t_unix,y:d.(i_c)}

;- store abundance for each unique mass
        uniqmass = mass[uniq(mass,sort(mass))]
        for i_mass=0,n_elements(uniqmass)-1 do begin
           idx = where( mass eq uniqmass[i_mass] and focusmode eq modes[i_mode],idx_cnt )
           if idx_cnt eq 0 then continue
           store_data,verbose=verbose,'mvn_ngi_'+filetype[i_filetype]+'_'+modes[i_mode]+'_abundance_mass'+string(uniqmass[i_mass],f='(i3.3)'), $
                      data={x:t_unix[idx],y:abundance[idx]}
        endfor                  ;- i_mass
     endfor                     ;- i_mode

  endfor                        ;- i_filetype

end
