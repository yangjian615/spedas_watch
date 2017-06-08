;20170424 Ali
;takes care of 3d tplots and plots

pro mvn_pui_tplot_3d,store=store,tplot=tplot,swia3d=swia3d,stah3d=stah3d,stao3d=stao3d,datimage=datimage,modimage=modimage,d2mimage=d2mimage,nowin=nowin,denprof=denprof

  @mvn_pui_commonblock.pro ;common mvn_pui_common
  centertime=pui.centertime

  if ~pui0.do3d then begin
    dprint,'For 3D analysis, please run mvn_pui_model/do3d first. returning...'
    return
  endif
  if keyword_set(swia3d) || keyword_set(stah3d) || keyword_set(stao3d) then switch3d=1 else switch3d=0
  if keyword_set (datimage) or keyword_set (modimage) or keyword_set (d2mimage) then img=1 else img=0

  if keyword_set(store) or img then begin

    ;    minswia=4e4 ;swia open att min eflux thresh: below this, can't detect (approximate noise level)
    ;    minstao=8e4 ;swia closed att (4 non-sun-ward azimuths) and static O min eflux threshold
    ;    minstah=5e5 ;swia closed att (4 sun-ward azimuths) and static H min eflux threshold
    minpara=1.9 ;discard eflux below this factor times min eflux
    maxthre=7e7 ;above this eflux, we're probably looking at solar wind protons
    rmars=3400. ;Rm (km)

    if keyword_set(swics) then begin
      ;swap swia dimentions to match the model (time-energy-az-el)
      ;also, reverse the order of elevation (deflection) angles to start from positive theta (like static)
      swiaef3d=reverse(transpose(pui.data.swi.swica.data,[3,0,2,1]),4)
      swicaen=transpose(info_str[pui.data.swi.swica.info_index].energy_coarse)
      swind=where(finite(swiaef3d[*,0,0,0]),/null,swcount) ;no archive available index

;      minswiatt=rebin([minswia],[pui0.nt,pui0.swieb,pui0.swina,pui0.swine])
;      minswiatt[where(pui.data.swi.swim.atten_state eq 2.,/null),*,[0,13,14,15],*]=minstah ;higher threshold when swia attenuator is closed, only applied to the 4 sun-ward azimuth (anode) bins
;      minswiatt[where(pui.data.swi.swim.atten_state eq 2.,/null),*,[1,2 ,11,12],*]=minstao ;only applied to the 4 non-sun-ward azimuth (anode) bins
      minswiatt2=minpara*mvn_pui_min_eflux(swiaef3d) ;min over energy and elevation dimensions
    endif

    d1eflux=transpose(pui.data.sta.d1.eflux[*,*,*,[0,4]],[4,0,1,2,3]) ;mass channel 0:Hydrogen, 4:Oxygen
    d1energy=transpose(pui.data.sta.d1.energy)
    d1ind=where(finite(d1energy[*,0]),/null,d1count) ;no archive available index

    kefswi=transpose(pui.model.fluxes.swi3d.eflux,[4,0,1,2,3]) ;pickup energy flux
    kefsta=transpose(pui.model.fluxes.sta3d.eflux,[4,0,1,2,3])
    krvswi=transpose(pui.model.fluxes.swi3d.rv,[5,1,2,3,4,0]) ;pickup position,velocity
    krvsta=transpose(pui.model.fluxes.sta3d.rv,[5,1,2,3,4,0])
    krrswi=sqrt(total(krvswi[*,*,*,*,*,0:3]^2,6))/1e3 ;pickup radial distance (km)
    krrsta=sqrt(total(krvsta[*,*,*,*,*,0:3]^2,6))/1e3

    mstr=['H','O'] ;mass string
    frmtstr=['b.','r.'] ;plot format string
    get_data,'mvn_alt_sw_(km)',data=alt_sw
    if keyword_set(alt_sw) then swindex=where(finite(alt_sw.y),/null) else swindex=!null ;only solar wind
    ebinlim=[30,20] ;energy bin limit for [H,O]
    dim3d=pui0.swina*pui0.swine*(ebinlim+1) ;used to create tplots of all energy/anode/elevation d2m's

    minsta2=minpara*mvn_pui_min_eflux(d1eflux) ;min over energy and elevation dimensions
    ;get rid of too low model and data flux (below detection threshold) and too high data flux (solar wind)
    kefsta[where((kefsta lt minsta2) or (d1eflux lt minsta2) or (d1eflux gt maxthre),/null)]=0.
    knnsta=d1eflux/kefsta

    for im=0,1 do begin ;loop over mass 0:H, 1:O
      knnsta2=knnsta[*,0:ebinlim[im],*,*,im]
      logsta=alog(reform(knnsta2,[pui0.nt,dim3d[im]]))
      avgsta=exp(average(logsta,2,stdev=ssta,nsamples=nsta,/nan))
      pui.d2m[im].sta[0]=avgsta
      pui.d2m[im].sta[1]=exp(ssta)
      pui.d2m[im].sta[2]=nsta

      if d1count gt 0 then store_data,'mvn_d2m_ratio_avg_stat_'+mstr[im],data={x:centertime[d1ind],y:avgsta[d1ind]},limits={ylog:1,colors:'r'}
      time3d=dgen(pui0.nt*dim3d[im],range=timerange(pui0.trange))
      store_data,'mvn_d2m_ratio_all_stat_'+mstr[im],data={x:time3d,y:reform(transpose(knnsta2),pui0.nt*dim3d[im])},limits={ylog:1,psym:3}
      store_data,'mvn_d2m_ratio_stat_'+mstr[im],data=['mvn_d2m_ratio_all_stat_'+mstr[im],'mvn_d2m_ratio_avg_stat_'+mstr[im],'mvn_pui_line_1'],limits={ylog:1,yrange:[1e-2,1e2],ytickunits:'scientific'}

      if keyword_set(swics) then begin
        kefswim=kefswi[*,*,*,*,im]
        kefswim[where((kefswim lt minswiatt2) or (swiaef3d lt minswiatt2) or (swiaef3d gt maxthre),/null)]=0.
        knnswi=swiaef3d/kefswim/(~kefswi[*,*,*,*,~im]) ;exospheric neutral density (cm-3) data/model ratio
        knnswi2=knnswi[*,0:ebinlim[im],*,*]
        logswi=alog(reform(knnswi2,[pui0.nt,dim3d[im]]))
        avgswi=exp(average(logswi,2,stdev=sswi,nsamples=nswi,/nan))
        pui.d2m[im].swi[0]=avgswi
        pui.d2m[im].swi[1]=exp(sswi)
        pui.d2m[im].swi[2]=nswi
        if keyword_set(denprof) then p=plot(knnswi2[swindex,*,*,*],krrswi[swindex,0:ebinlim[im],*,*,im]-rmars,/o,/xlog,/ylog,frmtstr[im])
        if swcount gt 0 then store_data,'mvn_d2m_ratio_avg_swia_'+mstr[im],data={x:centertime[swind],y:avgswi[swind]},limits={ylog:1,colors:'r'}
        time3d=dgen(pui0.nt*dim3d[im],range=timerange(pui0.trange))
        store_data,'mvn_d2m_ratio_all_swia_'+mstr[im],data={x:time3d,y:reform(transpose(knnswi2),pui0.nt*dim3d[im])},limits={ylog:1,psym:3}
        store_data,'mvn_d2m_ratio_swia_'+mstr[im],data=['mvn_d2m_ratio_all_swia_'+mstr[im],'mvn_d2m_ratio_avg_swia_'+mstr[im],'mvn_pui_line_1'],limits={ylog:1,yrange:[1e-2,1e2],ytickunits:'scientific'}
      endif
    endfor

    if keyword_set(denprof) then begin
      p=plot(knnsta[swindex,0:ebinlim[0],*,*,0],krrsta[swindex,0:ebinlim[0],*,*,0]-rmars,/xlog,/ylog,frmtstr[0])
      p=plot(knnsta[swindex,0:ebinlim[1],*,*,1],krrsta[swindex,0:ebinlim[1],*,*,1]-rmars,/o,frmtstr[1])
    endif    

    if keyword_set(store) and switch3d then begin
      store_data,'mvn_s*_model*_A*D*',/delete
      store_data,'mvn_s*_data*_A*D*',/delete
      dprint,dlevel=2,'Creating 3D tplots. This will take a few seconds to complete...'
      verbose=0
    endif

    if img and ~keyword_set(nowin) then p=window(background_color='k',dim=[400,200])
    mrgn=.01
    rgbt=33

    for j=0,pui0.swina-1 do begin ;loop over azimuth bins (phi)
      for k=0,pui0.swine-1 do begin ;loop over elevation bins (theta): + to - theta goes left to right on the screen
        jj=15-((j+9) mod 16) ;to sort vertical placement of tplot panels: center is sunward for swia
        lojk=[4,16,1+k+j*4]

        if keyword_set(swia3d) then begin
          kefswimo=total(kefswi,5) ;swia model all masses
          swimjk=kefswimo[*,*,jj,k]
          swidjk=swiaef3d[*,*,jj,k]
          if keyword_set(modimage) then p=image(alog10(swimjk),layout=lojk,/current,margin=mrgn,rgb_table=rgbt,aspect=0,min=4,max=8,axis_style=0,background_color='b',/order)
          if keyword_set(datimage) and keyword_set(swics) then p=image(alog10(swidjk),layout=lojk,/current,margin=mrgn,rgb_table=rgbt,aspect=0,min=4,max=8,axis_style=0,background_color='b',/order)
          if keyword_set(d2mimage) and keyword_set(swics) then p=image(alog10(swidjk/swimjk),layout=lojk,/current,margin=mrgn,rgb_table=rgbt,aspect=0,min=-1,max=1,axis_style=0,background_color='w',/order)
          if keyword_set(store) then begin
            store_data,'mvn_swia_model_A'+strtrim(jj,2)+'D'+strtrim(k,2),centertime,swimjk,pui1.swiet,verbose=verbose
            if keyword_set(swics) then store_data,'mvn_swia_data_A'+strtrim(jj,2)+'D'+strtrim(k,2),centertime,swidjk,swicaen,verbose=verbose
            options,'mvn_swia*_A*D*','spec',1
            options,'mvn_swia*_A*D*','ytickunits','scientific'
            ylim,'mvn_swia*_A*D*',25,25e3,1
            zlim,'mvn_swia*_A*D*',1e4,1e8,1
          endif
        endif

        if keyword_set(stao3d) then begin
          statjk=kefsta[*,*,jj,k,1]
          d1efjk=d1eflux[*,*,jj,k,1]
          if keyword_set(modimage) then p=image(alog10(statjk),layout=lojk,/current,margin=mrgn,rgb_table=rgbt,aspect=0,min=4,max=8,axis_style=0,background_color='b',/order)
          if keyword_set(datimage) then p=image(alog10(d1efjk),layout=lojk,/current,margin=mrgn,rgb_table=rgbt,aspect=0,min=4,max=8,axis_style=0,background_color='b',/order)
          if keyword_set(d2mimage) then p=image(alog10(d1efjk/statjk),layout=lojk,/current,margin=mrgn,rgb_table=rgbt,aspect=0,min=-1,max=1,axis_style=0,background_color='w',/order)
          if keyword_set(store) then begin
            store_data,'mvn_stat_model_puo_A'+strtrim(jj,2)+'D'+strtrim(k,2),centertime,statjk,d1energy,verbose=verbose
            store_data,'mvn_stat_data_HImass_A'+strtrim(jj,2)+'D'+strtrim(k,2),centertime,d1efjk,d1energy,verbose=verbose
          endif
        endif

        if keyword_set(stah3d) then begin
          statjk=kefsta[*,*,jj,k,0]
          d1efjk=d1eflux[*,*,jj,k,0]
          if keyword_set(modimage) then p=image(alog10(statjk),layout=lojk,/current,margin=mrgn,rgb_table=rgbt,aspect=0,min=4,max=8,axis_style=0,background_color='b',/order)
          if keyword_set(datimage) then p=image(alog10(d1efjk),layout=lojk,/current,margin=mrgn,rgb_table=rgbt,aspect=0,min=4,max=8,axis_style=0,background_color='b',/order)
          if keyword_set(d2mimage) then p=image(alog10(d1efjk/statjk),layout=lojk,/current,margin=mrgn,rgb_table=rgbt,aspect=0,min=-1,max=1,axis_style=0,background_color='w',/order)
          if keyword_set(store) then begin
            store_data,'mvn_stat_model_puh_A'+strtrim(jj,2)+'D'+strtrim(k,2),centertime,statjk,d1energy,verbose=verbose
            store_data,'mvn_stat_data_LOmass_A'+strtrim(jj,2)+'D'+strtrim(k,2),centertime,d1efjk,d1energy,verbose=verbose
          endif
        endif
      endfor
    endfor

    if keyword_set(store) and switch3d then begin
      options,'mvn_stat*_A*D*','spec',1
      options,'mvn_stat*_A*D*','ytickunits','scientific'
      ylim,'mvn_stat*_A*D*',10,35e3,1
      zlim,'mvn_stat*_A*D*',1e4,1e8,1
    endif

  endif

  if keyword_set(swia3d) then begin
    swiastat='swia'
    modelmass=''
    datamass=''
  endif

  if keyword_set(stah3d) then begin
    swiastat='stat'
    modelmass='_puh'
    datamass='_LOmass'
  endif

  if keyword_set(stao3d) then begin
    swiastat='stat'
    modelmass='_puo'
    datamass='_HImass'
  endif

  if switch3d and keyword_set(tplot) then begin
    !p.background=2
    !p.color=-1
    xsize=480
    ysize=1000
    for iw=0,3 do begin
      wi,iw+1,wsize=[xsize,ysize],wposition=[iw*xsize,0]
      wi,iw+5,wsize=[xsize,ysize],wposition=[iw*xsize,0]
      tplot,'mvn_'+swiastat+'_data'+datamass+'_A*D'+strtrim(iw,2),window=iw+1
      tplot,'mvn_'+swiastat+'_model'+modelmass+'_A*D'+strtrim(iw,2),window=iw+5
    endfor
    !p.background=-1
    !p.color=0
  endif

end
