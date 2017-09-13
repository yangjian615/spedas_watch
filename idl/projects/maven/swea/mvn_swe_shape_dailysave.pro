;+
;PROCEDURE:   mvn_swe_shape_dailysave
;PURPOSE:
;
;USAGE:
;  mvn_swe_shape_dailysave,start_day=start_day,end_day=end_day,ndays=ndays
;
;INPUTS:
;       None
;
;KEYWORDS:
;       start_day:     Save data over this time range.  If not
;                      specified, then timerange() will be called
;
;       end_day:       The end day of intented time range
;
;       ndays:         Number of dates to process. Will be overwritten
;                      if start_day & end_day are given. If both
;                      end_day and ndays are not specified, ndays=7
;
;
; $LastChangedBy:  $
; $LastChangedDate:  $
; $LastChangedRevision:  $
; $URL:  $
;
;CREATED BY:    Shaosui Xu, 08/01/2017
;FILE: mvn_swe_shape_dailysave.pro
;-

Pro mvn_swe_shape_dailysave,start_day=start_day,end_day=end_day,ndays=ndays

    @mvn_swe_com

    dpath=root_data_dir()+'maven/data/sci/swe/l3/shape/'
    froot='mvn_swe_l3_shape_'
    vr='_v00_r01'
    oneday=86400.D

    if (size(ndays,/type) eq 0 and size(end_day,/type) eq 0) then ndays = 7
    dt = oneday

    if (size(start_day,/type) eq 0) then begin
        tr = timerange()
        start_day = tr[0]
        ndays = floor( (tr[1]-tr[0])/oneday )
    endif

    start_day2 = time_double(time_string(start_day,prec=-3))
    if (size(end_day,/type) ne 0 ) then $
        end_day2 = time_double(time_string(end_day,prec=-3)) $
    else end_day2 = time_double(time_string(start_day2+ndays*oneday,prec=-3))

    dt = end_day2 - start_day2
    nday = floor(dt/oneday)

    print,start_day2,end_day2,nday

    for j=0L,nday-1L do begin
        tst = start_day2+j*oneday
        print,j,' ',time_string(tst)
        tnd = tst+oneday
        opath = dpath + time_string(tst,tf='YYYY/MM/')
        file_mkdir2, opath, mode='0775'o ;create directory structure, if needed
        ofile = opath+froot+time_string(tst+1000.,tf='YYYYMMDD')+vr+'.sav'

        timespan,tst,1
        
        mvn_swe_spice_init,/force
        mvn_swe_load_l2
        mvn_swe_load_l2,/pad,/burst,/noerase
        
        if (size(mvn_swe_pad,/type) eq 8) then begin
            
            mvn_swe_addmag
            mvn_swe_sumplot,/eph,/orb,/burst,/loadonly

            mvn_mag_load, spice='iau_mars'
            options,'mvn_B_1sec_iau_mars','ytitle','B!dGEO!n (nT)'
            options,'mvn_B_1sec_iau_mars','labels',['Bx','By','Bz']
            options,'mvn_B_1sec_iau_mars','labflag',1
            options,'mvn_B_1sec_iau_mars','constant',0.
            mvn_mag_geom            

            mvn_scpot
            swe_shape_par_pad_l2_3pa,spec=30,erange=[20,80],mag_geo=mag,pot=1,tsmo=16

            str_element, mvn_swe_pad, 'time', ptime, success=ok
            get_mvn_eph,ptime,eph
            store_data,'ephall',data={x:eph.time, xmso:eph.x_ss, ymso:eph.y_ss, zmso:eph.z_ss,$
                xgeo:eph.x_pc, ygeo:eph.y_pc, zgeo:eph.z_pc,$
                lon:eph.elon, lat:eph.lat, alt:eph.alt, sza:eph.sza, lst:eph.lst}

            get_data,'Shape_PAD',data=shp
            tsh=shp.x
            shape=shp.shape
            f3pa=shp.f3pa
            mid = shp.mid
            pots = shp.pots
            parange = shp.parange

            Nt=n_elements(tsh)
            amp=dblarr(Nt) & az=amp & elev=az & clk=az

            get_data,'mvn_B_1sec_iau_mars',data=mage
            tmag=mage.x
            amp_ori=mage.amp
            azim_ori=mage.azim
            elev_ori=mage.elev
            clk_ori=mage.clock
            ;now interpolate data
            amp=interpol(amp_ori,tmag,tsh,/spline)
            elev=interpol(elev_ori,tmag,tsh,/spline)

            ;get mag level
            mag_level = fltarr(Nt)
            if size(swe_mag1,/type) eq 8 then begin
                bdx = nn(swe_mag1.time, tsh)
                mag_level = swe_mag1[bdx].level
            endif

            xi=cos(azim_ori)
            yi=sin(azim_ori)
            xx=interpol(xi,tmag,tsh,/spline)
            yy=interpol(yi,tmag,tsh,/spline)
            azim=atan(yy,xx)*!radeg
            indx=where(azim lt 0)
            azim[indx]=360.+azim[indx]

            xi=cos(clk_ori)
            yi=sin(clk_ori)
            xx=interpol(xi,tmag,tsh,/spline)
            yy=interpol(yi,tmag,tsh,/spline)
            clk=atan(yy,xx)*!radeg
            indx=where(clk lt 0)
            clk[indx]=360.+clk[indx]

            get_data,'ephall',data=eph
            lon=eph.lon
            lat=eph.lat
            alt=eph.alt
            sza=eph.sza
            lst=eph.lst

            str =  {t:0.D,shape:fltarr(3,3),parange:[0.,0.],f3pa:fltarr(64,3,3),$
                alt:0.,sza:0.,lst:0., lat:0.,lon:0.,$
                xmso:0., ymso:0.,zmso:0., xgeo:0.,$
                ygeo:0., zgeo:0., mid:0., f40:0., $
                Bmag:0.,Belev:0.,Baz:0.,Bclk:0.,pot:0.,mag_level:0}
            strday =  replicate(str,n_elements(tsh))
            strday.t =  tsh
            strday.shape =  transpose(shape,[1,2,0])
            strday.parange =  transpose(parange)
            strday.f3pa =  transpose(f3pa,[0,2,1,3])
            strday.alt =  alt
            strday.sza =  sza
            strday.lst =  lst
            strday.lat =  lat
            strday.lon =  lon
            strday.xmso =  eph.xmso
            strday.ymso =  eph.ymso
            strday.zmso =  eph.zmso
            strday.xgeo =  eph.xgeo
            strday.ygeo =  eph.ygeo
            strday.zgeo =  eph.zgeo
            strday.bmag =  amp
            strday.belev =  elev
            strday.Baz =  azim
            strday.Bclk =  clk
            strday.mid =  mid
            strday.pot =  pots
            strday.mag_level=mag_level
            
;            mvn_shape={t:tsh,shape:shape,parange:parange,$ ;tbar:tbar,;bst:bst
;                alt:alt,sza:sza,lst:lst, lat:lat,lon:lon,f3pa:f3pa,$
;                xmso:eph.xmso, ymso:eph.ymso,zmso:eph.zmso, xgeo:eph.xgeo,$
;                ygeo:eph.ygeo, zgeo:eph.zgeo, mag_level:mag_level, $
;                Bmag:amp,Belev:elev,Baz:azim,Bclk:clk,mid:mid,pot:pots}

            f40 = mvn_swe_engy.data[40]
            t1 = mvn_swe_engy.time
            strday.f40 = interpol(f40,t1,tsh)

            save,strday,file=ofile,/compress

        endif
        
    endfor

end