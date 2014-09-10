

pro mvn_sep_create_subarrays,data_str,trange=trange,tname=tname,bmaps=bmaps,mapids=mapids,yval=yval,zval=zval,smooth=smooth,smpar=smpar

   if not keyword_set(yval) then yval = 'Energy'
   if not keyword_set(zval) then zval = 'Rate'
;   smooth=1
   
   geoms = [!values.f_nan,.1,.001,!values.f_nan]        ; cm2-ster         ; temporary kludge
  ; geoms = [!values.f_nan,.1,.1,!values.f_nan]
   if keyword_set(smpar) then smooth=1
   if size(/type,data_str) eq 7 then begin                     ; input is a string
      mvn_sep_extract_data,data_str,rawdat,trange=trange,num=num
      if ~keyword_set(rawdat) then begin
         dprint,'No data'
         return
      endif
      sensnum = rawdat[1].sensor
      sepn = fix(strmid(data_str,7,1))     ; 1 or 2
   endif else begin                                            ; input is an array of structures
      rawdat = data_str
      num = n_elements(rawdat)
   endelse
printdat,sepn,sensnum
;   if num eq 0 then return  ; No data available
   if not keyword_set(rawdat) then return
   if not keyword_set(mapids) then begin
      mapnums = byte(median(rawdat.mapid))    ;  get most common mapnum
       mapids = where( histogram(rawdat.mapid) ne 0 ,n_mapids)   ; all mapids found
       dprint,/phelp,mapids
       mapids=mapnums   ; do only most common one  
   endif 
   for i = 0,n_elements(mapids)-1 do begin
     mapnum = mapids[i]
     if mapnum eq 0 then continue
     tname = 'mvn_sep'+strtrim(sepn,2)
 ;    tname=data_str+string(mapnum,format='(i03)')
     mapname = mvn_sep_mapnum_to_mapname(mapnum)
     wt = where(rawdat.mapid eq mapnum or finite(rawdat.time) eq 0,nt)   ; include gaps
     t = rawdat[wt].time
     dt = rawdat[wt].duration
     att_state = rawdat[wt].ATT
     geom = geoms[att_state]
     all_counts = transpose(rawdat[wt].data)
     value = findgen(256)
     bmaps = mvn_sep_lut2map(mapname=mapname)
mvn_sep_det_cal,bmaps,sepn,units=1    

     dprint,dlevel=3,/phelp,mapnum,mapname,sepn
     sidename = ['A','B']
     for s=0,1 do begin
       rdata = replicate(!values.f_nan,nt,6) 
       rnorm = rdata
       for d=5,0,-1 do begin
          w = where(bmaps.det eq (d+1) and bmaps.tid eq s,nw)
          if nw eq 0 then continue
          bmap = bmaps[w]
          cname = bmap[0].name     
          bins = bmap.bin               ;  might be an error when there is only 1 bin
          eff = bmap.y                  ; efficiency proxy
          cnts = all_counts[*,bins]
          dt2 = dt # replicate(1.,nw)
          if keyword_set(smooth)  then begin
             dprint,dlevel=2,'Smoothing count array ',cname
             cnts = dt2 * smooth_counts(cnts/dt2,dt2,smpar=smpar)
             dprint,dlevel=3,'Done'
          endif
          dim = size(cnts,/dimension)
          case strlowcase(yval) of 
           'bins' :  vals = findgen(nw) + .5
           'adc'  :  vals = average(bmap.adc,1)
           'energy': vals = bmap.x
          endcase
          zrange =[.1,1e4]
          yrange = zrange
          ylog = yval ne 'bins' ? 1 :0
          case strlowcase(zval) of
           'counts' : begin
                         znorm = replicate(1.,dim)
                         data = cnts
                         units = 'Counts'
                         tdata = total(data,2)
                      end
           'rate'   : begin
                         data = cnts/dt2
                         znorm = dt2
                         units = 'Counts/sec'
                         zrange = [.03,100]
                         tdata = total(data,2)
                      end
           'flux'   : begin
                         denergy = bmap.dx
                         znorm = (geom * dt) # (eff * denergy)
                         data = cnts / znorm
                         zrange = [.001,1e3]
                         yrange = [1,1e6]  ;zrange * 100
                         units = '#/s/ster/keV'
                         tdata = total(data * (replicate(1,nt) # denergy),2)
                     end
           'eflux'   : begin
                         denergy = bmap.dx
                         energy  = bmap.x
                         znorm = dt # (geom * eff * denergy/energy)
                         data = cnts / znorm
                         zrange = [1.,1e5]
                         yrange = zrange * 100
                         units = 'keV/sec/ster/keV'
                         tdata = total(data * (replicate(1,nt) # denergy),2)
                     end
          endcase
          rdata[*,d] = tdata 
;          rdata[*,d] = ((nw gt 1) ? total(data,2) : data)
;          rnorm[*,d] = ((nw gt 1) ? total(tdata,2) : tdata)
          tempdata = {x:ptr_new(t),y:ptr_new(data,/no_copy),v:ptr_new(vals,/no_copy),znorm:ptr_new(znorm,/no_copy),map:ptr_new(bmap)}
          store_data,tname+'_'+cname+'_'+zval+'_'+yval,data=tempdata, dlimit={spec:1,ystyle:1,zrange:zrange,ylog:ylog,zlog:1,panel_size:.5+nw/20.,ztitle:zval}
       endfor
;       tempdata = {x:ptr_new(t),y:ptr_new(rdata/rnorm,/no_copy),znorm:ptr_new(dt # replicate(1.,6),/no_copy),map:ptr_new(bmap)}
       tempdata = {x:ptr_new(t),y:ptr_new(rdata,/no_copy),map:ptr_new(bmap)}
       store_data,tname+'_'+sidename[s]+'_'+zval+'_tot',data=tempdata,dlimit ={colors:[2,4,6,1,3,5],yrange:yrange,ylog:1,ystyle:1,panel_size:2.,psym:-3,reverse_order:1}
     endfor
   endfor
end

