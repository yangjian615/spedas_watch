;+
;PROCEDURE:   mvn_swe_topo
;
;PURPOSE: This routine provides topology based on the combination of
;         shape parameters, and PAD info. 
;         8 topology results are provided:
;                    0 Unknown
;                    1 Dayside Closed
;                    2 Day-Night Closed
;                    3 Night Closed -- Trapped/two-sided loss cone
;                    4 Night CLosed -- Void
;                    5 Day Open
;                    6 Night Open
;                    7 Draped
;
;USAGE:
;  mvn_swe_topo,trange = trange, result=result, storeTplot = storeTplot, $
;                    tbl = tbl, orbit = orbit, thrd_shp=thrd_shp,fthrd=fthrd, $
;                    lcThreshold = lcThreshold, parng=parng, filter_reg=filter_reg
;
;INPUTS:
;       None
;
;KEYWORDS:
;
;       trange:      Time range. If not given, it will automatically look
;                    for current tplot time range
;
;       result:      A structure that contains time and topology results.
;
;       storeTplot:  If set, it will create two tplot variables for topology,
;                    'topo1' and 'topo_alt'. 'topo_alt' shows altitudes 
;                    colored by topology   
;
;       tbl:         A color table for topology. The default is set to be 
;                    [0,1,2,3,4,5,6,7] 
;       
;       orbit:       Use orbit number(s) to define the time range
;
;       thrd_shp:    The threshold for shape parameter to define
;                    photoelectrons. If shape < thrd_shp, it's identified
;                    as photoelectrons. The default value is 1.
;
;       fthrd:       Eflux (@ 40 eV) threshold to define electron voids. 
;                    If Eflux(40 eV) < fthrd, defined as a void. The default
;                    value is 1.e5.
;
;       lcThreshold: Threshold for loss cone. The default is set as 2.0.
;
;       parng:       Index for which PA range to choose for shape
;                    parameters. 1: 0-30 deg, 2: 0-45 deg, 3: 0-60 deg.
;                    The default is 0-30 deg.
;
;       filter_reg:  Using SWIA data to identify solar wind/sheath regions,
;                    by restoring save files created with 'mvn_swia_regid'. 
;                    ID=1, solar wind; ID=2, sheath. The topology for these 
;                    two regions will be overwritten with draped.
;
;       quality:     A 3-element array with quality flags:
;                        quality[0] : LPW potentials available (1=yes, 0=no)
;                        quality[1] : Shape parameter available (1=yes, 0=no)
;                        quality[2] : Padscore available (1=yes, 0=no)
;
;       success:     Returns 1 if topology information available (at whatever
;                    quality), 0 otherwise.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2018-01-25 16:15:32 -0800 (Thu, 25 Jan 2018) $
; $LastChangedRevision: 24593 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_topo.pro $
;
;CREATED BY:    Shaosui Xu, 11/03/2017
;FILE: mvn_swe_topo.pro

Pro mvn_swe_topo,trange = trange, result=result, storeTplot = storeTplot, $
                 tbl = tbl, orbit = orbit, thrd_shp=thrd_shp,fthrd=fthrd, $
                 lcThreshold = lcThreshold, parng=parng, filter_reg=filter_reg, $
                 thrd_frat = thrd_frat, quality=quality, success=success

    success = 0
    quality = [0,0,0]

    if keyword_set(orbit) then begin
        imin = min(orbit, max=imax)
        trange = mvn_orbit_num(orbnum=[imin-0.5,imax+0.5])
    endif
    if ~keyword_set(trange) then begin
        tplot_options, get_opt=topt
        tspan_exists = (max(topt.trange) gt time_double('2013-11-18'))
        if tspan_exists then trange = topt.trange else begin
            print, 'Must provide either a time range, orbit numbers, ' $
            +'or have a current tplot timerange to use'
            return
        endelse
    endif
    if (size(parng,/type) eq 0) then parng=1 ;PA=30
    mvn_swe_shape_restore,trange,results=data,tplot=1,parng=parng

    if (size(data,/type) eq 8) then begin
      quality[0:1] = 1

      ;now convert to index to be used directly
      parng = parng - 1

      ;create indices for shape parameter
      if (size(thrd_shp,/type) eq 0) then thrd_shp=1. ;default threshold for shape par
      if (size(fthrd,/type) eq 0) then fthrd=1.e5 ;default threshold for e- voids
      if (size(lcThreshold,/type) eq 0) then lcThreshold = 2.0
      if (size(tbl,/type) eq 0) then tbl=[0,1,2,3,4,5,6,7]
      if (size(thrd_frat,/type) eq 0) then thrd_frat = 0.75

      shp_away=reform(data.shape[0,parng]) ;away shape parameter
      shp_twd=reform(data.shape[1,parng]) ;twd shape parameter
      f40 = reform(data.f40) ;eflux at 40 eV, used to determine e- voids
      npts = n_elements(shp_away)

      jshp_away=bytarr(npts)
      inna = where(shp_away ne shp_away,nac,com=ina,ncom=ac)
      ;if not NAN, below threshold, j=0, else j=1
      if ac gt 0 then jshp_away[ina] =[floor(shp_away[ina]/thrd_shp)] < 1
      ;if ac gt 0 then jshp_away[ina] = min([floor(shp_away[ina]/thrd_shp),1])
      ;set NANs to j=2
      if nac gt 0 then jshp_away[inna] = 2

      jshp_twd=bytarr(npts)
      innt = where(shp_twd ne shp_twd,ntc,com=ints,ncom=tc)
      ;if not NAN, below threshold, j=0, else j=1
      if tc gt 0 then jshp_twd[ints] = [floor(shp_twd[ints]/thrd_shp)] < 1
      ;if tc gt 0 then jshp_twd[ints] = min([floor(shp_twd[ints]/thrd_shp),1])
      ;set NANs to j=2
      if ntc gt 0 then jshp_twd[innt] = 2

      jf=bytarr(npts)
;      innf = where(f40 ne f40 or f40 eq 0.0,nfc,com=inf,ncom=fc)
      innf = where(f40 ne f40,nfc,com=inf,ncom=fc);some voids have f40=0 as well, need another fix
      ;if not NAN, below threshold, j=0, else j=1
      if fc gt 0 then jf[inf]=[floor(f40[inf]/fthrd)] < 1
      ;if fc gt 0 then jf[inf]=min([floor(f40/fthrd),1])
      ;set NANs to j=2
      if nfc gt 0 then jf[innf]=2

      numShp = n_elements(jshp_away)
    endif else begin
      print,"Warning: PAD Shape not available!"
      return
    endelse

    ;-----from PAD--------
    ;jupz, assuming 1 being lc, 0 being non lc
    ;jdnz, assuming 1 being lc, 0 being non lc
    mvn_swe_pad_lc_restore, trange = trange, result = padLC

    if (n_elements(padLC) gt 0L) then begin
      quality[2] = 1

      ;coAddNum = 4

      jupz = bytarr(numShp)
      LCUpProcessed = bytarr(n_elements(padLC))
      badUp = where(~finite(padLC[*].zScoreUp), numBadUp, $
                    complement = goodUp, ncomplement = numGoodUp)
      if numGoodUp gt 0 then LCUpProcessed[goodUp] = $
         (padLC[goodUp].zScoreUp lt (-1 * lcThreshold))
      if numBadUp gt 0 then LCUpProcessed[badUp] = 2

      jdnz = bytarr(numShp)
      LCDownProcessed = bytarr(n_elements(padLC))
      badDown = where(~finite(padLC[*].zScoreDown), numBadDown, $
                      complement = goodDown, ncomplement = numGoodDown)
      if numGoodDown gt 0 then LCDownProcessed[goodDown] = $
         (padLC[goodDown].zScoreDown lt (-1 * lcThreshold))
      if numBadDown gt 0 then LCDownProcessed[badDown] = 2

      index = nn(padLC.time,data.t)
      jupz = LCUpProcessed[index]
      jdnz = LCDownProcessed[index]
      gap = where(abs(data.t-padLC[index].time) ge 16,count) ;>16s
      if count gt 0L then begin
        jupz[gap] = 2
        jdnz[gap] = 2
      endif
    endif else begin
      print,"Warning: PAD Score not available!"
      jupz = replicate(2B, numShp)  ; fill with unknowns
      jdnz = replicate(2B, numShp)  ; fill with unknowns
    endelse

  ;------Previous interpolation... Ignore this for now------
  ;    time_interp = value_locate(padLC[*].time, data[*].t)
  ;    time_interp[where(time_interp eq -1)] = 0
  ;
  ;    jupz = time_interp[LCUpProcessed]
  ;    jdnz = time_interp[LCDownProcessed]

  ;----Interpolate... without using nn.pro
  ;    for i = 0, numshp-1 do begin
  ;        dummy = min(abs(data[i].t - padLC[*].time), index)
  ;        jupz[i] = LCUpProcessed[index]
  ;        jdnz[i] = LCDownProcessed[index]
  ;    endfor

    ;-----for day/night---
    ;this index is place holder, will not change topo results regardless
    ;if it's on dayside or night. it's set to be 1 here.
    jdn = bytarr(npts)
    ;jdn[*] = 1

    ;-----enlisting this index for field-aligned flux ratio---
    ;this is a proxy to find loss cone to distinguish draped and open to night
    fratio=reform(data.fratio_a2t[0,parng]) ;0--low energy, 1--high energy
    inna = where(fratio ne fratio,nac,com=ina,ncom=ac)
    ;thrd_frat = 0.75 ;could be converted to a nob 
    ;if not NAN, below threshold, j=0, else j=1               
    if ac gt 0L then jdn[ina] =[floor(fratio[ina]/thrd_frat)] < 1
    if nac gt 0L then jdn[inna] = 2

    topo_mtrx = topomtrx();(tbl = tbl)
    topo=topo_mtrx[jshp_away,jshp_twd,jf,jupz,jdnz,jdn]
    toponame=['0-?','1-CD','2-CX','3-CT','4-CV','5-OD','6-ON','7-D']

    if keyword_set(filter_reg) then begin
       mvn_swe_regid_restore,res=regid,/tplot
       if (size(regid,/type) eq 8) then begin
          id = round(interp(regid.id, regid.time, data.t, interp_thresh=60D, /no_extrap))
          infilter = where(id eq 1 or id eq 2,count) ; 1--solar wind, 2--sheath
          if (count gt 0L) then topo[infilter] = 7 ; overwrite these regions to draped
       endif
       get_data,'reg_id',data=reg_id,index=i
       if (i gt 0) then begin
         indx = where(reg_id.y gt 3, count)
         if (count gt 0) then reg_id.y[indx] -= 1
         store_data,'reg_id',data=reg_id
         idname = ['?','SW','Sheath','Iono','Lobe']
         store_data,'reg_id_lab',data={x:timerange(), y:replicate(!values.f_nan,2,5), v:indgen(5)}
         options,'reg_id_lab','labels',idname
         options,'reg_id_lab','labflag',1
         options,'reg_id_lab','colors',replicate(!p.color,5)
         options,'reg_id','colors',4
         store_data,'reg_ids',data=['reg_id_lab','reg_id']
         ylim,'reg_ids',-0.5,4.5,0
         options,'reg_ids','ytitle','Region'
         options,'reg_ids','yminor',1
       endif
    endif

    result = {time:data.t, topo:topo, toponame:toponame}

    if keyword_set(storeTplot) then begin
        store_data, 'topo', data = {x:data[*].t, y:topo}
        options, 'topo', 'psym', 4
        options, 'topo', 'symsize', 0.5
        ylim, 'topo', 0, 8, 0

        alttopo = replicate(!values.f_nan,n_elements(data),8)
        ;ft=['unknown','cls-day','cls-d2n','cls-trp','void','opn2d','opn2n','drp']
        ft=['0-unkn','1-cls-day','2-cls-d2n','3-cls-trp','4-void',$
            '5-opn2d','6-opn2n','7-drp']
        ; Create a tplot variable for all topology
        labs=ft
        clr=[!p.background,tbl[1:7]]
        psym=[3,1,1,3,3,1,3,3]
        sysz=[1,0.5,0.5,1,1,0.5,1,1]
        store_data,'topo_lab',data={x:minmax(data.t),y:replicate(!values.f_nan,2,8)}
        options,'topo_lab','labels',labs
        options,'topo_lab','colors',clr
        options,'topo_lab','labflag',1

        store_data,'topo1',data=['topo','topo_lab']
        options,'topo1','ytitle','Topology'
        ylim, 'topo1', -0.5, 7.5, 0

        for i=1,7 do begin
            inj=where(topo eq i,count)
            if count gt 0L then begin
                alttopo[inj,i] = data[inj].alt
            endif            
            ename='alt_'+ft[i]
            store_data,ename,data={x:data.t,y:alttopo[*,i]}
            options,ename,'color',clr[i]
            options,ename,'psym',psym[i]
            options,ename,'symsize',sysz[i]
        endfor
        store_data,'topo_alt',data=['topo_lab','alt_'+ft[1:7]]
        
    endif
    success = 1

    return
end
