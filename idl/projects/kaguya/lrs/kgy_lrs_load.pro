;+
; PROCEDURE:
;       kgy_lrs_load
; PURPOSE:
;       loads Kaguya LRS natural wave data
; CALLING SEQUENCE:
;       timespan,'2008-01-01',2
;       kgy_lrs_load
; KEYWORDS:
;       types: 'NPW', 'WFC', or ['NPW','WFC'] (Def: ['NPW','WFC'])
;       version: data version (Def: '010')
;       append: if set, append to pre-loaded tplot variables (Def: clear old data)
;       files: local files to read
;              if set, does not download files from the data archive site
; CREATED BY:
;       Yuki Harada on 2016-09-02
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2017-11-21 12:02:46 -0800 (Tue, 21 Nov 2017) $
; $LastChangedRevision: 24333 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kaguya/lrs/kgy_lrs_load.pro $
;-

pro kgy_lrs_load, files=files, version=version, trange=trange, append=append, types=types


if ~keyword_set(version) then version = '010' ;- incapable of automatic version search
version2 = strmid(version,1,1)+'.'+strmid(version,2,1)
if ~keyword_set(append) then store_data,'kgy_lrs_*',/delete
if ~keyword_set(types) then types = ['NPW','WFC'] else types = strupcase(types)

;;; retrieve files
if ~keyword_set(files) then begin
   files = ''

   ;;; NPW
   if total(strmatch(types,'NPW')) then begin
      pf = 'sln-l-lrs-5-npw-spectrum-v'+version2+'/YYYYMMDD/data/LRS_NPW_V'+version+'_YYYYMMDD.cdf'
;      pf = 'LRS_NPW_V'+version+'_YYYYMMDD' ;- obsolete
      f = kgy_file_retrieve(pf,trange=trange,/public,/valid)
      if total(strlen(f)) gt 0 then files = [files,f]
   endif

   ;;; WFC, skip odd hours
   if total(strmatch(types,'WFC')) then begin
      pf = 'sln-l-lrs-4-wfc-spectrum-v'+version2+'/YYYYMMDD/data/LRS_WFC_V'+version+'_YYYYMMDDhhmmss.cdf'
;      pf = 'LRS_WFC_V'+version+'_YYYYMMDDhhmmss' ;- obsolete
      f = kgy_file_retrieve(pf,trange=trange,/public,/hourly,/valid,/skipodd)
      if total(strlen(f)) gt 0 then files = [files,f]
   endif
endif


;;; select files to read
w = where(file_test(files),nw)
if nw eq 0 then begin
   dprint,'No valid files'
   return
endif
files = files[w]


;;; read files
for ifile=0,n_elements(files)-1 do begin
   fname = files[ifile]
   cdfi = cdf_load_vars(fname,varformat='*',/convert_int1_to_int2)
   id = cdf_open(fname)
   dprint,'reading '+fname

   ;;; rename old tplot variable
   tn = tnames('kgy_lrs_*',ntn)
   for itn=0,ntn-1 do tplot_rename,tn[itn],tn[itn]+'_oldload'

   ;;; NPW
   if total(strmatch(fname,'*NPW*')) then begin
      ;;; varnames: Epoch Mode Frequency RX1 RX2

      ;;; get times
      idx = where( cdfi.vars.name eq 'Epoch' , nw )
      if nw ne 1 then continue
      v = cdfi.vars[idx]
      attr = *v.attrptr
      if v.numrec eq 0 then continue ;- no data
      data = *v.dataptr
      cdf_epoch,reform(data),yr,mo,dy,hr,mn,sc,ml,/BREAK
      times = time_double( string(yr,format='(i4.4)')+'-' $
                           +string(mo,format='(i2.2)')+'-' $
                           +string(dy,format='(i2.2)')+'/' $
                           +string(hr,format='(i2.2)')+':' $
                           +string(mn,format='(i2.2)')+':' $
                           +string(sc,format='(i2.2)')+'.' $
                           +string(ml,format='(i3.3)')+'.'  )

      ;;; get freq
      idx = where( cdfi.vars.name eq 'Frequency' , nw )
      if nw ne 1 then continue
      v = cdfi.vars[idx]
      data = *v.dataptr
      attr = *v.attrptr
      freq = data
      frequnits = attr.units

      ;;; get RX1
      idx = where( cdfi.vars.name eq 'RX1' , nw )
      if nw eq 1 then begin
         v = cdfi.vars[idx]
         attr = *v.attrptr
         if v.numrec gt 0 then begin
            data = float( *v.dataptr )
            if tag_exist(attr,'fillval') then begin
               wnan = where( data eq attr.fillval , nwnan )
               if nwnan gt 0 then data[wnan] = !values.f_nan
            endif
            store_data,'kgy_lrs_npw_rx1', $
                       data={x:times,y:data,v:freq}, $
                       dlim={ytitle:'LRS NPW!cE-field RX1!cFrequency!c['+frequnits+']',$
                             ylog:1,yticklen:-.01, $
                             yrange:minmax(freq),ystyle:1, $
                             spec:1,zlog:0,ztitle:attr.units, $
                             zrange:[-200,-120]}
         endif
      endif

      ;;; get RX2
      idx = where( cdfi.vars.name eq 'RX2' , nw )
      if nw eq 1 then begin
         v = cdfi.vars[idx]
         attr = *v.attrptr
         if v.numrec gt 0 then begin
            data = float( *v.dataptr )
            if tag_exist(attr,'fillval') then begin
               wnan = where( data eq attr.fillval , nwnan )
               if nwnan gt 0 then data[wnan] = !values.f_nan
            endif
            store_data,'kgy_lrs_npw_rx2', $
                       data={x:times,y:data,v:freq}, $
                       dlim={ytitle:'LRS NPW!cE-field RX2!cFrequency!c['+frequnits+']',$
                             ylog:1,yticklen:-.01, $
                             yrange:minmax(freq),ystyle:1, $
                             spec:1,zlog:0,ztitle:attr.units, $
                             zrange:[-200,-120]}
         endif
      endif

      ;;; get modes
      idx = where( cdfi.vars.name eq 'Mode' , nw )
      if nw eq 1 then begin
         v = cdfi.vars[idx]
         attr = *v.attrptr
         if v.numrec gt 0 then begin
            data = *v.dataptr
            store_data,'kgy_lrs_npw_mode',data={x:times,y:data}, $
                       dlim={ytitle:'LRS NPW!cMode',psym:1}
         endif
      endif

   endif                        ;- NPW


   ;;; WFC
   if total(strmatch(fname,'*WFC*')) then begin
      ;;; varnames: Ex Ey Frequency Epoch PDC-TI Mode Gain PostGap

      ;;; get times
      idx = where( cdfi.vars.name eq 'Epoch' , nw )
      if nw ne 1 then continue
      v = cdfi.vars[idx]
      attr = *v.attrptr
      if v.numrec eq 0 then continue ;- no data
      data = *v.dataptr
      cdf_epoch,reform(data),yr,mo,dy,hr,mn,sc,ml,/BREAK
      times = time_double( string(yr,format='(i4.4)')+'-' $
                           +string(mo,format='(i2.2)')+'-' $
                           +string(dy,format='(i2.2)')+'/' $
                           +string(hr,format='(i2.2)')+':' $
                           +string(mn,format='(i2.2)')+':' $
                           +string(sc,format='(i2.2)')+'.' $
                           +string(ml,format='(i3.3)')+'.'  )

      ;;; get freq
      idx = where( cdfi.vars.name eq 'Frequency' , nw )
      if nw ne 1 then continue
      v = cdfi.vars[idx]
      data = *v.dataptr
      attr = *v.attrptr
      freq = data
      frequnits = attr.units

      ;;; get Ex
      idx = where( cdfi.vars.name eq 'Ex' , nw )
      if nw eq 1 then begin
         v = cdfi.vars[idx]
         attr = *v.attrptr
         if v.numrec gt 0 then begin
            if v.numrec eq n_elements(times) then data = float( *v.dataptr ) $
            else begin
               cdf_varget,id,'Ex',data,rec_count=n_elements(times)
               data = float(transpose(data))
            endelse
            if tag_exist(attr,'fillval') then begin
               wnan = where( data eq attr.fillval , nwnan )
               if nwnan gt 0 then data[wnan] = !values.f_nan
            endif
            store_data,'kgy_lrs_wfc_Ex', $
                       data={x:times,y:data,v:freq}, $
                       dlim={ytitle:'Ex!cFrequency!c['+frequnits+']', $
                             ylog:1,yticklen:-.01, $
                             yrange:minmax(freq)>.1,ystyle:1, $
                             spec:1,zlog:0,ztitle:attr.units, $
                             zrange:[-20,60]}
         endif
      endif

      ;;; get Ey
      idx = where( cdfi.vars.name eq 'Ey' , nw )
      if nw eq 1 then begin
         v = cdfi.vars[idx]
         attr = *v.attrptr
         if v.numrec gt 0 then begin
            if v.numrec eq n_elements(times) then data = float( *v.dataptr ) $
            else begin
               cdf_varget,id,'Ey',data,rec_count=n_elements(times)
               data = float(transpose(data))
            endelse
            if tag_exist(attr,'fillval') then begin
               wnan = where( data eq attr.fillval , nwnan )
               if nwnan gt 0 then data[wnan] = !values.f_nan
            endif
            store_data,'kgy_lrs_wfc_Ey', $
                       data={x:times,y:data,v:freq}, $
                       dlim={ytitle:'Ey!cFrequency!c['+frequnits+']', $
                             ylog:1,yticklen:-.01, $
                             yrange:minmax(freq)>.1,ystyle:1, $
                             spec:1,zlog:0,ztitle:attr.units, $
                             zrange:[-20,60]}
         endif
      endif

      ;;; get Mode
      idx = where( cdfi.vars.name eq 'Mode' , nw )
      if nw eq 1 then begin
         v = cdfi.vars[idx]
         attr = *v.attrptr
         if v.numrec gt 0 then begin
            if v.numrec eq n_elements(times) then data = float( *v.dataptr ) $
            else begin
               cdf_varget,id,'Mode',data,rec_count=n_elements(times)
               data = float(reform(data))
            endelse
            if tag_exist(attr,'fillval') then begin
               wnan = where( data eq attr.fillval , nwnan )
               if nwnan gt 0 then data[wnan] = !values.f_nan
            endif
            store_data,'kgy_lrs_wfc_mode', $
                       data={x:times,y:data}, $
                       dlim={ytitle:'LRS WFC!cMode',psym:1}
         endif
      endif

      ;;; get Gain
      idx = where( cdfi.vars.name eq 'Gain' , nw )
      if nw eq 1 then begin
         v = cdfi.vars[idx]
         attr = *v.attrptr
         if v.numrec gt 0 then begin
            if v.numrec eq n_elements(times) then data = float( *v.dataptr ) $
            else begin
               cdf_varget,id,'Gain',data,rec_count=n_elements(times)
               data = float(reform(data))
            endelse
            if tag_exist(attr,'fillval') then begin
               wnan = where( data eq attr.fillval , nwnan )
               if nwnan gt 0 then data[wnan] = !values.f_nan
            endif
            store_data,'kgy_lrs_wfc_gain', $
                       data={x:times,y:data}, $
                       dlim={ytitle:'LRS WFC!cgain',psym:1}
         endif
      endif

      ;;; get PDC-TI
      idx = where( cdfi.vars.name eq 'PDC-TI' , nw )
      if nw eq 1 then begin
         v = cdfi.vars[idx]
         attr = *v.attrptr
         if v.numrec gt 0 then begin
            if v.numrec eq n_elements(times) then data = float( *v.dataptr ) $
            else begin
               cdf_varget,id,'PDC-TI',data,rec_count=n_elements(times)
               data = float(transpose(data))
            endelse
            if tag_exist(attr,'fillval') then begin
               wnan = where( data eq attr.fillval , nwnan )
               if nwnan gt 0 then data[wnan] = !values.f_nan
            endif
            store_data,'kgy_lrs_wfc_pdc-ti', $
                       data={x:times,y:data}, $
                       dlim={ytitle:'LRS WFC!cPDC-TI',psym:1}
         endif
      endif

      ;;; get PostGap
      idx = where( cdfi.vars.name eq 'PostGap' , nw )
      if nw eq 1 then begin
         v = cdfi.vars[idx]
         attr = *v.attrptr
         if v.numrec gt 0 then begin
            if v.numrec eq n_elements(times) then data = float( *v.dataptr ) $
            else begin
               cdf_varget,id,'Gain',data,rec_count=n_elements(times)
               data = float(reform(data))
            endelse
            if tag_exist(attr,'fillval') then begin
               wnan = where( data eq attr.fillval , nwnan )
               if nwnan gt 0 then data[wnan] = !values.f_nan
            endif
            store_data,'kgy_lrs_wfc_qflag', $
                       data={x:times,y:data}, $
                       dlim={ytitle:'LRS WFC!cQuality Flag',psym:1}
         endif
      endif

   endif                        ;- WFC


   ;;; concat tplot variable
   tn = tnames('kgy_lrs_*_oldload',ntn)
   for itn=0,ntn-1 do begin
      get_data,tn[itn],data=dold,dlim=dlold
      newtn = strmid(tn[itn],0,strlen(tn[itn])-8)
      get_data,newtn,data=dnew,dlim=dlnew,dtype=dtype
      if dtype eq 0 then tplot_rename,tn[itn],newtn else begin
         newx = [ dold.x, dnew.x ]
         newy = [ dold.y, dnew.y ]
         if tag_exist(dold,'v') and tag_exist(dnew,'v') then begin
            if size(dold.v,/n_dim) ne size(dnew.v,/n_dim) then begin
               dprint,'v tag dims do not match: ',tn[itn],' ',newtn
               continue
            endif
            if size(dold.v,/n_dim) eq 1 then begin
               if total(abs(dold.v-dnew.v)) eq 0 then newv = dold.v else begin
                  newv = [ transpose(rebin(dold.v,n_elements(dold.v),n_elements(dold.x))), transpose(rebin(dnew.v,n_elements(dnew.v),n_elements(dnew.x))) ]
               endelse
            endif else newv = [ dold.v, dnew.v ]
            store_data,newtn,data={x:newx,y:newy,v:newv},dlim=dlnew
         endif else begin ;- no v tag
            store_data,newtn,data={x:newx,y:newy},dlim=dlnew
         endelse
      endelse
   endfor
   tn = tnames('kgy_lrs_*_oldload',ntn)
   if ntn gt 0 then store_data,tn,/delete


endfor                          ;- ifile


end

