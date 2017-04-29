;20170424 Ali
;takes care of 3d tplots and plots

pro mvn_pui_tplot_3d,store=store,tplot=tplot,swia3d=swia3d,stah3d=stah3d,stao3d=stao3d,datimage=datimage,modimage=modimage,d2mimage=d2mimage,nowin=nowin

  @mvn_pui_commonblock.pro ;common mvn_pui_common
  centertime=pui.centertime

  if keyword_set(swia3d) || keyword_set(stah3d) || keyword_set(stao3d) then switch3d=1 else switch3d=0
  if keyword_set (datimage) or keyword_set (modimage) or keyword_set (d2mimage) then img=1 else img=0

  if switch3d and (keyword_set(store) or img) then begin

    if keyword_set(swica) then begin
      ;swap swia dimentions to match the model (time-energy-az-el)
      ;also, reverse the order of elevation (deflection) angles to start from positive theta (like static)
      swiaef3d=reverse(transpose(pui.data.swi.swica.data,[3,0,2,1]),4)
      swicaen=transpose(info_str[pui.data.swi.swica.info_index].energy_coarse)
    endif

    if pui0.do3d then begin
      kefswih3d=transpose(pui.model[0].fluxes.swi3d.eflux,[3,0,1,2])
      kefswio3d=transpose(pui.model[1].fluxes.swi3d.eflux,[3,0,1,2])
      kefstah3d=transpose(pui.model[0].fluxes.sta3d.eflux,[3,0,1,2])
      kefstao3d=transpose(pui.model[1].fluxes.sta3d.eflux,[3,0,1,2])

      d1eflux=transpose(pui.data.sta.d1.eflux,[4,0,1,2,3])
      d1energy=transpose(pui.data.sta.d1.energy)
    endif

    store_data,'mvn_s*_model*_A*D*',/delete
    store_data,'mvn_s*_data*_A*D*',/delete
    dprint,dlevel=2,'Creating 3D tplots. This will take a few seconds to complete...'
    if img and ~keyword_set(nowin) then p=window(background_color='k',dim=[400,200])
    verbose=0

    for j=0,pui0.swina-1 do begin ;loop over azimuth bins (phi)
      for k=0,pui0.swine-1 do begin ;loop over elevation bins (theta): + to - theta goes left to right on the screen
        jj=15-((j+9) mod 16) ;to sort vertical placement of tplot panels: center is sunward for swia

        if keyword_set(swia3d) then begin
          kefswi3d=kefswih3d[*,*,jj,k]+kefswio3d[*,*,jj,k]
          if keyword_set(modimage) then p=image(alog10(kefswi3d),layout=[4,16,1+k+j*4],/current,margin=0.01,rgb_table=33,aspect=0,min=4,max=8,axis_style=0,background_color='b',/order)
          if keyword_set(datimage) then p=image(alog10(swiaef3d[*,*,jj,k]),layout=[4,16,1+k+j*4],/current,margin=.01,rgb_table=33,aspect=0,min=4,max=8,axis_style=0,background_color='b',/order)
          if keyword_set(d2mimage) then p=image(alog10(swiaef3d[*,*,jj,k]/kefswi3d),layout=[4,16,1+k+j*4],/current,margin=.01,rgb_table=33,aspect=0,min=-1,max=1,axis_style=0,background_color='w',/order)
          if keyword_set(store) then begin
            store_data,'mvn_swia_model_A'+strtrim(jj,2)+'D'+strtrim(k,2),centertime,kefswi3d,pui1.swiet,verbose=verbose
            if keyword_set(swica) then store_data,'mvn_swia_data_A'+strtrim(jj,2)+'D'+strtrim(k,2),centertime,swiaef3d[*,*,jj,k],swicaen,verbose=verbose
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
            ;        if keyword_set(mvn_d1_dat) then store_data,'mvn_stat_data_HImass_A'+strtrim(jj,2)+'D'+strtrim(k,2),centertime,total(d1eflux[*,*,jj,k,3:5],5),d1energy,verbose=verbose
            if keyword_set(mvn_d1_dat) then store_data,'mvn_stat_data_HImass_A'+strtrim(jj,2)+'D'+strtrim(k,2),centertime,d1eflux[*,*,jj,k,4],d1energy,verbose=verbose
          endif
        endif

        if keyword_set(stah3d) then begin
          if keyword_set(modimage) then p=image(alog10(kefstah3d[*,*,jj,k]),layout=[4,16,1+k+j*4],/current,margin=.01,rgb_table=33,aspect=0,min=4,max=8,axis_style=0,background_color='b',/order)
          if keyword_set(datimage) then p=image(alog10(d1eflux[*,*,jj,k,0]),layout=[4,16,1+k+j*4],/current,margin=.01,rgb_table=33,aspect=0,min=4,max=8,axis_style=0,background_color='b',/order)
          if keyword_set(d2mimage) then p=image(alog10(d1eflux[*,*,jj,k,0]/kefstah3d[*,*,jj,k]),layout=[4,16,1+k+j*4],/current,margin=.01,rgb_table=33,aspect=0,min=-1,max=1,axis_style=0,background_color='w',/order)
          if keyword_set(store) then begin
            store_data,'mvn_stat_model_puh_A'+strtrim(jj,2)+'D'+strtrim(k,2),centertime,kefstah3d[*,*,jj,k],d1energy,verbose=verbose
            ;        if keyword_set(mvn_d1_dat) then store_data,'mvn_stat_data_LOmass_A'+strtrim(jj,2)+'D'+strtrim(k,2),centertime,total(d1eflux[*,*,jj,k,0:2],5),d1energy,verbose=verbose
            if keyword_set(mvn_d1_dat) then store_data,'mvn_stat_data_LOmass_A'+strtrim(jj,2)+'D'+strtrim(k,2),centertime,d1eflux[*,*,jj,k,0],d1energy,verbose=verbose
          endif
        endif
        ;      store_data,'mvn_stat_data_3d_A'+strtrim(jj,2)+'_D'+strtrim(k,2),mvn_ca_dat.time,mvn_ca_dat.eflux[*,*,k+4*jj],mvn_ca_dat.energy[mvn_ca_dat.swp_ind,*,0]
      endfor
    endfor

    options,'mvn_stat*_A*D*','spec',1
    options,'mvn_stat*_A*D*','ytickunits','scientific'
    ylim,'mvn_stat*_A*D*',10,35e3,1
    zlim,'mvn_stat*_A*D*',1e4,1e8,1
  endif

  if keyword_set(store) then begin
    onesnt=replicate(1.,pui0.nt)
    ebinlimo=12 ;energy bin limit for oxygen
    ebinlimh=24 ;energy bin limit for hydrogen
    maxthresh=1e8 ;above this, and we're probably looking at solar wind protons
    minthresh=1e5 ;below this, can't detect
    minswiatt=minthresh*onesnt
    minswiatt[where(pui.data.swi.swim.atten_state eq 2.,/null)]=1e6 ;higher threshold when swia attenuator is closed
    minswiatt=rebin(minswiatt,[pui0.nt,pui0.swieb,pui0.swina,pui0.swine])
    kefswih3d[where((kefswih3d lt minswiatt) or (swiaef3d gt maxthresh),/null)]=0. ;get rid of too low model flux (below detection threshold) or too high data flux (solar wind)
    kefswio3d[where((kefswio3d lt minswiatt) or (swiaef3d gt maxthresh),/null)]=0.
    kefstah3d[where((kefstah3d lt minthresh) or (d1eflux[*,*,*,*,0] gt maxthresh),/null)]=0.
    kefstao3d[where((kefstao3d lt minthresh) or (d1eflux[*,*,*,*,4] gt maxthresh),/null)]=0.

    dimo3d=pui0.swina*pui0.swine*(ebinlimo+1.)
    dimh3d=pui0.swina*pui0.swine*(ebinlimh+1.)
    timeo3d=dgen(pui0.nt*dimo3d,range=timerange(pui0.trange))
    timeh3d=dgen(pui0.nt*dimh3d,range=timerange(pui0.trange))

    knnstao3d=d1eflux[*,*,*,*,4]/kefstao3d
    knnstah3d=d1eflux[*,*,*,*,0]/kefstah3d
    knnstao3dtot=exp(mean(alog(reform(knnstao3d[*,0:ebinlimo,*,*],[pui0.nt,dimo3d])),dim=2,/nan))
    knnstah3dtot=exp(mean(alog(reform(knnstah3d[*,0:ebinlimh,*,*],[pui0.nt,dimh3d])),dim=2,/nan))
    pui.d2m[0].sta=knnstah3dtot
    pui.d2m[1].sta=knnstao3dtot
    store_data,'mvn_d2m_ratio_avg_stat_O',data={x:centertime,y:[[knnstao3dtot],[onesnt]]},limits={ylog:1,colors:'rg'}
    store_data,'mvn_d2m_ratio_avg_stat_H',data={x:centertime,y:[[knnstah3dtot],[onesnt]]},limits={ylog:1,colors:'rg'}
    store_data,'mvn_d2m_ratio_all_stat_O',data={x:timeo3d,y:reform(transpose(knnstao3d[*,0:ebinlimo,*,*]),pui0.nt*dimo3d)},limits={ylog:1,psym:3}
    store_data,'mvn_d2m_ratio_all_stat_H',data={x:timeh3d,y:reform(transpose(knnstah3d[*,0:ebinlimh,*,*]),pui0.nt*dimh3d)},limits={ylog:1,psym:3}
    store_data,'mvn_d2m_ratio_stat_O',data='mvn_d2m_ratio_all_stat_O mvn_d2m_ratio_avg_stat_O',limits={ylog:1,yrange:[1e-2,1e2],ytickunits:'scientific'}
    store_data,'mvn_d2m_ratio_stat_H',data='mvn_d2m_ratio_all_stat_H mvn_d2m_ratio_avg_stat_H',limits={ylog:1,yrange:[1e-2,1e2],ytickunits:'scientific'}

    if keyword_set(swica) then begin
      knnswio3d=swiaef3d/kefswio3d/(~kefswih3d) ;exospheric neutral density (cm-3) data/model ratio
      knnswih3d=swiaef3d/kefswih3d/(~kefswio3d)
      knnswio3dtot=exp(mean(alog(reform(knnswio3d[*,0:ebinlimo,*,*],[pui0.nt,dimo3d])),dim=2,/nan))
      knnswih3dtot=exp(mean(alog(reform(knnswih3d[*,0:ebinlimh,*,*],[pui0.nt,dimh3d])),dim=2,/nan))
      pui.d2m[0].swi=knnswih3dtot
      pui.d2m[1].swi=knnswio3dtot
      store_data,'mvn_d2m_ratio_avg_swia_O',data={x:centertime,y:[[knnswio3dtot],[onesnt]]},limits={ylog:1,colors:'rg'}
      store_data,'mvn_d2m_ratio_avg_swia_H',data={x:centertime,y:[[knnswih3dtot],[onesnt]]},limits={ylog:1,colors:'rg'}
      store_data,'mvn_d2m_ratio_all_swia_O',data={x:timeo3d,y:reform(transpose(knnswio3d[*,0:ebinlimo,*,*]),pui0.nt*dimo3d)},limits={ylog:1,psym:3}
      store_data,'mvn_d2m_ratio_all_swia_H',data={x:timeh3d,y:reform(transpose(knnswih3d[*,0:ebinlimh,*,*]),pui0.nt*dimh3d)},limits={ylog:1,psym:3}
      store_data,'mvn_d2m_ratio_swia_O',data='mvn_d2m_ratio_all_swia_O mvn_d2m_ratio_avg_swia_O',limits={ylog:1,yrange:[1e-2,1e2],ytickunits:'scientific'}
      store_data,'mvn_d2m_ratio_swia_H',data='mvn_d2m_ratio_all_swia_H mvn_d2m_ratio_avg_swia_H',limits={ylog:1,yrange:[1e-2,1e2],ytickunits:'scientific'}
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
