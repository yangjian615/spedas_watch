;20170424 Ali
;takes care of 3d tplots and plots

pro mvn_pui_tplot_3d,store=store,tplot=tplot,swia3d=swia3d,stah3d=stah3d,stao3d=stao3d,datimage=datimage,modimage=modimage,d2mimage=d2mimage,nowin=nowin

  @mvn_pui_commonblock.pro ;common mvn_pui_common
  centertime=pui.centertime

  if ~pui0.do3d then begin
    dprint,'For 3D analysis, please run mvn_pui_model/do3d first. returning...'
    return
  endif
  if keyword_set(swia3d) || keyword_set(stah3d) || keyword_set(stao3d) then switch3d=1 else switch3d=0
  if keyword_set (datimage) or keyword_set (modimage) or keyword_set (d2mimage) then img=1 else img=0

  if keyword_set(store) or img then begin

    if keyword_set(swics) then begin
      ;swap swia dimentions to match the model (time-energy-az-el)
      ;also, reverse the order of elevation (deflection) angles to start from positive theta (like static)
      swiaef3d=reverse(transpose(pui.data.swi.swica.data,[3,0,2,1]),4)
      swicaen=transpose(info_str[pui.data.swi.swica.info_index].energy_coarse)
      swind=where(finite(swiaef3d[*,0,0,0]),/null,swcount) ;no archive available index
    endif

    kefswih3d=transpose(pui.model[0].fluxes.swi3d.eflux,[3,0,1,2])
    kefswio3d=transpose(pui.model[1].fluxes.swi3d.eflux,[3,0,1,2])
    kefstah3d=transpose(pui.model[0].fluxes.sta3d.eflux,[3,0,1,2])
    kefstao3d=transpose(pui.model[1].fluxes.sta3d.eflux,[3,0,1,2])

    d1eflux=transpose(pui.data.sta.d1.eflux,[4,0,1,2,3])
    d1energy=transpose(pui.data.sta.d1.energy)
    d1ind=where(finite(d1energy[*,0]),/null,d1count) ;no archive available index

    if keyword_set(store) and switch3d then begin
      store_data,'mvn_s*_model*_A*D*',/delete
      store_data,'mvn_s*_data*_A*D*',/delete
      dprint,dlevel=2,'Creating 3D tplots. This will take a few seconds to complete...'
      verbose=0
    endif

    if img and ~keyword_set(nowin) then p=window(background_color='k',dim=[400,200])

    for j=0,pui0.swina-1 do begin ;loop over azimuth bins (phi)
      for k=0,pui0.swine-1 do begin ;loop over elevation bins (theta): + to - theta goes left to right on the screen
        jj=15-((j+9) mod 16) ;to sort vertical placement of tplot panels: center is sunward for swia

        if keyword_set(swia3d) then begin
          kefswi3d=kefswih3d[*,*,jj,k]+kefswio3d[*,*,jj,k]
          if keyword_set(modimage) then p=image(alog10(kefswi3d),layout=[4,16,1+k+j*4],/current,margin=0.01,rgb_table=33,aspect=0,min=4,max=8,axis_style=0,background_color='b',/order)
          if keyword_set(datimage) and keyword_set(swics) then p=image(alog10(swiaef3d[*,*,jj,k]),layout=[4,16,1+k+j*4],/current,margin=.01,rgb_table=33,aspect=0,min=4,max=8,axis_style=0,background_color='b',/order)
          if keyword_set(d2mimage) and keyword_set(swics) then p=image(alog10(swiaef3d[*,*,jj,k]/kefswi3d),layout=[4,16,1+k+j*4],/current,margin=.01,rgb_table=33,aspect=0,min=-1,max=1,axis_style=0,background_color='w',/order)
          if keyword_set(store) then begin
            store_data,'mvn_swia_model_A'+strtrim(jj,2)+'D'+strtrim(k,2),centertime,kefswi3d,pui1.swiet,verbose=verbose
            if keyword_set(swics) then store_data,'mvn_swia_data_A'+strtrim(jj,2)+'D'+strtrim(k,2),centertime,swiaef3d[*,*,jj,k],swicaen,verbose=verbose
            options,'mvn_swia*_A*D*','spec',1
            options,'mvn_swia*_A*D*','ytickunits','scientific'
            ylim,'mvn_swia*_A*D*',25,25e3,1
            zlim,'mvn_swia*_A*D*',1e4,1e8,1
          endif
        endif

        if keyword_set(stao3d) then begin
          if keyword_set(modimage) then p=image(alog10(kefstao3d[*,*,jj,k]),layout=[4,16,1+k+j*4],/current,margin=.01,rgb_table=33,aspect=0,min=4,max=8,axis_style=0,background_color='b',/order)
          if keyword_set(datimage) then p=image(alog10(d1eflux[*,*,jj,k,4]),layout=[4,16,1+k+j*4],/current,margin=.01,rgb_table=33,aspect=0,min=4,max=8,axis_style=0,background_color='b',/order)
          if keyword_set(d2mimage) then p=image(alog10(d1eflux[*,*,jj,k,4]/kefstao3d[*,*,jj,k]),layout=[4,16,1+k+j*4],/current,margin=.01,rgb_table=33,aspect=0,min=-1,max=1,axis_style=0,background_color='w',/order)
          if keyword_set(store) then begin
            store_data,'mvn_stat_model_puo_A'+strtrim(jj,2)+'D'+strtrim(k,2),centertime,kefstao3d[*,*,jj,k],d1energy,verbose=verbose
            store_data,'mvn_stat_data_HImass_A'+strtrim(jj,2)+'D'+strtrim(k,2),centertime,d1eflux[*,*,jj,k,4],d1energy,verbose=verbose
          endif
        endif

        if keyword_set(stah3d) then begin
          if keyword_set(modimage) then p=image(alog10(kefstah3d[*,*,jj,k]),layout=[4,16,1+k+j*4],/current,margin=.01,rgb_table=33,aspect=0,min=4,max=8,axis_style=0,background_color='b',/order)
          if keyword_set(datimage) then p=image(alog10(d1eflux[*,*,jj,k,0]),layout=[4,16,1+k+j*4],/current,margin=.01,rgb_table=33,aspect=0,min=4,max=8,axis_style=0,background_color='b',/order)
          if keyword_set(d2mimage) then p=image(alog10(d1eflux[*,*,jj,k,0]/kefstah3d[*,*,jj,k]),layout=[4,16,1+k+j*4],/current,margin=.01,rgb_table=33,aspect=0,min=-1,max=1,axis_style=0,background_color='w',/order)
          if keyword_set(store) then begin
            store_data,'mvn_stat_model_puh_A'+strtrim(jj,2)+'D'+strtrim(k,2),centertime,kefstah3d[*,*,jj,k],d1energy,verbose=verbose
            store_data,'mvn_stat_data_LOmass_A'+strtrim(jj,2)+'D'+strtrim(k,2),centertime,d1eflux[*,*,jj,k,0],d1energy,verbose=verbose
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

  if keyword_set(store) then begin
    ebinlimo=20 ;energy bin limit for oxygen
    ebinlimh=30 ;energy bin limit for hydrogen
    minswia=4e4 ;swia open att min eflux thresh: below this, can't detect (approximate noise level)
    minstao=8e4 ;swia closed att (4 non-sun-ward azimuths) and static O min eflux threshold
    minstah=5e5 ;swia closed att (4 sun-ward azimuths) and static H min eflux threshold
    maxthre=7e7 ;above this, and we're probably looking at solar wind protons
    kefstah3d[where((kefstah3d lt minstah) or (d1eflux[*,*,*,*,0] gt maxthre),/null)]=0.
    kefstao3d[where((kefstao3d lt minstao) or (d1eflux[*,*,*,*,4] gt maxthre),/null)]=0.

    dimo3d=pui0.swina*pui0.swine*(ebinlimo+1.)
    dimh3d=pui0.swina*pui0.swine*(ebinlimh+1.)
    timeo3d=dgen(pui0.nt*dimo3d,range=timerange(pui0.trange))
    timeh3d=dgen(pui0.nt*dimh3d,range=timerange(pui0.trange))

    knnstao3d=d1eflux[*,*,*,*,4]/kefstao3d
    knnstah3d=d1eflux[*,*,*,*,0]/kefstah3d
    logstao=alog(reform(knnstao3d[*,0:ebinlimo,*,*],[pui0.nt,dimo3d]))
    logstah=alog(reform(knnstah3d[*,0:ebinlimh,*,*],[pui0.nt,dimh3d]))
    mstao=exp(average(logstao,2,stdev=sstao,nsamples=nstao,/nan))
    mstah=exp(average(logstah,2,stdev=sstah,nsamples=nstah,/nan))
    pui.d2m[0].sta[0]=mstah
    pui.d2m[1].sta[0]=mstao
    pui.d2m[0].sta[1]=exp(sstah)
    pui.d2m[1].sta[1]=exp(sstao)
    pui.d2m[0].sta[2]=nstah
    pui.d2m[1].sta[2]=nstao
    
    if d1count gt 0 then store_data,'mvn_d2m_ratio_avg_stat_O',data={x:centertime[d1ind],y:mstao[d1ind]},limits={ylog:1,colors:'r'}
    if d1count gt 0 then store_data,'mvn_d2m_ratio_avg_stat_H',data={x:centertime[d1ind],y:mstah[d1ind]},limits={ylog:1,colors:'r'}
    store_data,'mvn_d2m_ratio_all_stat_O',data={x:timeo3d,y:reform(transpose(knnstao3d[*,0:ebinlimo,*,*]),pui0.nt*dimo3d)},limits={ylog:1,psym:3}
    store_data,'mvn_d2m_ratio_all_stat_H',data={x:timeh3d,y:reform(transpose(knnstah3d[*,0:ebinlimh,*,*]),pui0.nt*dimh3d)},limits={ylog:1,psym:3}
    store_data,'mvn_d2m_ratio_stat_O',data='mvn_d2m_ratio_all_stat_O mvn_d2m_ratio_avg_stat_O mvn_pui_line_1',limits={ylog:1,yrange:[1e-2,1e2],ytickunits:'scientific'}
    store_data,'mvn_d2m_ratio_stat_H',data='mvn_d2m_ratio_all_stat_H mvn_d2m_ratio_avg_stat_H mvn_pui_line_1',limits={ylog:1,yrange:[1e-2,1e2],ytickunits:'scientific'}

    if keyword_set(swics) then begin
      minswiatt=rebin([minswia],[pui0.nt,pui0.swieb,pui0.swina,pui0.swine])
      minswiatt[where(pui.data.swi.swim.atten_state eq 2.,/null),*,[0,13,14,15],*]=minstah ;higher threshold when swia attenuator is closed, only applied to the 4 sun-ward azimuth (anode) bins
      minswiatt[where(pui.data.swi.swim.atten_state eq 2.,/null),*,[1,2 ,11,12],*]=minstao ;only applied to the 4 non-sun-ward azimuth (anode) bins
      kefswih3d[where((kefswih3d lt minswiatt) or (swiaef3d gt maxthre),/null)]=0. ;get rid of too low model flux (below detection threshold) or too high data flux (solar wind)
      kefswio3d[where((kefswio3d lt minswiatt) or (swiaef3d gt maxthre),/null)]=0.

      knnswio3d=swiaef3d/kefswio3d/(~kefswih3d) ;exospheric neutral density (cm-3) data/model ratio
      knnswih3d=swiaef3d/kefswih3d/(~kefswio3d)
      logswio=alog(reform(knnswio3d[*,0:ebinlimo,*,*],[pui0.nt,dimo3d]))
      logswih=alog(reform(knnswih3d[*,0:ebinlimh,*,*],[pui0.nt,dimh3d]))
      mswio=exp(average(logswio,2,stdev=sswio,nsamples=nswio,/nan))
      mswih=exp(average(logswih,2,stdev=sswih,nsamples=nswih,/nan))
      pui.d2m[0].swi[0]=mswih
      pui.d2m[1].swi[0]=mswio
      pui.d2m[0].swi[1]=exp(sswih)
      pui.d2m[1].swi[1]=exp(sswio)
      pui.d2m[0].swi[2]=nswih
      pui.d2m[1].swi[2]=nswio

      if swcount gt 0 then store_data,'mvn_d2m_ratio_avg_swia_O',data={x:centertime[swind],y:mswio[swind]},limits={ylog:1,colors:'r'}
      if swcount gt 0 then store_data,'mvn_d2m_ratio_avg_swia_H',data={x:centertime[swind],y:mswih[swind]},limits={ylog:1,colors:'r'}
      store_data,'mvn_d2m_ratio_all_swia_O',data={x:timeo3d,y:reform(transpose(knnswio3d[*,0:ebinlimo,*,*]),pui0.nt*dimo3d)},limits={ylog:1,psym:3}
      store_data,'mvn_d2m_ratio_all_swia_H',data={x:timeh3d,y:reform(transpose(knnswih3d[*,0:ebinlimh,*,*]),pui0.nt*dimh3d)},limits={ylog:1,psym:3}
      store_data,'mvn_d2m_ratio_swia_O',data='mvn_d2m_ratio_all_swia_O mvn_d2m_ratio_avg_swia_O mvn_pui_line_1',limits={ylog:1,yrange:[1e-2,1e2],ytickunits:'scientific'}
      store_data,'mvn_d2m_ratio_swia_H',data='mvn_d2m_ratio_all_swia_H mvn_d2m_ratio_avg_swia_H mvn_pui_line_1',limits={ylog:1,yrange:[1e-2,1e2],ytickunits:'scientific'}
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
    wi,1,wsize=[xsize,ysize],wposition=[0*xsize,0]
    wi,5,wsize=[xsize,ysize],wposition=[0*xsize,0]
    wi,2,wsize=[xsize,ysize],wposition=[1*xsize,0]
    wi,6,wsize=[xsize,ysize],wposition=[1*xsize,0]
    wi,3,wsize=[xsize,ysize],wposition=[2*xsize,0]
    wi,7,wsize=[xsize,ysize],wposition=[2*xsize,0]
    wi,4,wsize=[xsize,ysize],wposition=[3*xsize,0]
    wi,8,wsize=[xsize,ysize],wposition=[3*xsize,0]
    tplot,'mvn_'+swiastat+'_data'+datamass+'_A*D0',window=1
    tplot,'mvn_'+swiastat+'_data'+datamass+'_A*D1',window=2
    tplot,'mvn_'+swiastat+'_data'+datamass+'_A*D2',window=3
    tplot,'mvn_'+swiastat+'_data'+datamass+'_A*D3',window=4
    tplot,'mvn_'+swiastat+'_model'+modelmass+'_A*D0',window=5
    tplot,'mvn_'+swiastat+'_model'+modelmass+'_A*D1',window=6
    tplot,'mvn_'+swiastat+'_model'+modelmass+'_A*D2',window=7
    tplot,'mvn_'+swiastat+'_model'+modelmass+'_A*D3',window=8
    !p.background=-1
    !p.color=0
  endif

end
