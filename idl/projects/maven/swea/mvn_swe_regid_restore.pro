;+
;PROCEDURE:   mvn_swe_regid_restore
;PURPOSE:
;  Reads in save files mvn_swia_regid
;
;USAGE:
;  mvn_swe_regid_restore, trange
;
;INPUTS:
;       trange:        Restore data over this time range.  If not
;                      specified, then uses the current tplot range
;                      or timerange() will be called
;
;KEYWORDS:
;       ORBIT:         Restore mvn_swia_regid data by orbit number.
;
;       RESULTS:       Hold the full structure of region id
;
;       TPLOT:         Create tplot varible for region id "reg_id"
;       
; $LastChangedBy: xussui $
; $LastChangedDate: 2017-11-17 15:17:53 -0800 (Fri, 17 Nov 2017) $
; $LastChangedRevision: 24307 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_regid_restore.pro $
;
;CREATED BY:    Shaosui Xu  11-17-17
;FILE: mvn_swe_regid_restore
;-

Pro mvn_swe_regid_restore,trange,results=results,tplot=tplot,orbit=orbit

    ;   Process keywords
    rootdir='maven/data/sci/swe/l3/swia_regid/YYYY/MM/'
    fname = 'mvn_swia_regid_YYYYMMDD_v??_r??.sav'

    if keyword_set(orbit) then begin
        imin = min(orbit, max=imax)
        trange = mvn_orbit_num(orbnum=[imin-0.5,imax+0.5])
     endif

    tplot_options,get_opt=topt
    tspan_exists = (max(topt.trange_full) gt time_double('2014-12-01'))
    if((size(trange,/type) eq 0) and tspan_exists) then $
        trange=topt.trange_full

    if(size(trange,/type) eq 0) then trange=timerange()

    tmin = min(time_double(trange),max=tmax)
    file = mvn_pfp_file_retrieve(rootdir+fname,trange=[tmin,tmax],/daily_names)
    nfiles = n_elements(file)

    finfo = file_info(file)
    indx = where(finfo.exists,nfiles,comp=jndx,ncomp=n)

    for j=0,n-1 do print,'File not found:',file[jndx[j]]
    if (nfiles eq 0) then begin
       results=0
       return
    endif
    file = file[indx]

    for j=0,nfiles-1 do begin
        restore,filename=file[j]
        id=[temporary(id),regid]
     endfor
    intx=where(id.time ge tmin and id.time le tmax,count)
    if (count eq 0) then begin
       results=0
       return
    endif
    id=id[intx]
    results=id

    if (keyword_set(tplot)) then begin
       store_data,'reg_id',data={x:id.time,y:id.id}
       options,'reg_id','psym',4
       options,'reg_id','symsize',0.35
       ylim,'reg_id',-1,6
    endif

end
