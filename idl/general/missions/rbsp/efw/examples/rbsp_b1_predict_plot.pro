; 0, To use, edit jumpa/jumpb, prota/protb, colla/collb. They corresponds to
;    jumps, protected time, collection time.
; 1, First location is the first element in jump, so # of jump is always >1.
; 2, Use last location, or known jump to update "first location".
; 3, The predict curve should be very accurate.
; 4, Don't put jump in between collections. Add 1min pad time between 
;    jump and collection. Don't let collection time overlap.
; 5, To ensure accuracy, if update "first location" using last location, then 
;   set 1st collection start from last time, set earlier.


; **** combine jump & collection, sort, convert to abs memory id, print info,
; treat wrap, generate time & memory id for tplot.
pro rbsp_b1_predict_plot_process, probe, jumps, colls, $
    lun = lun, time = t0, memf = memf, mems = mems

    ; constants.
    sz = 262144D            ; memory size, in block.
    s2b = sz/84900D/16834D  ; sec to block.

    if n_elements(lun) eq 0 then lun = -1
    ; combine jump and collection.
    njump = n_elements(jumps)/2 & ncoll = n_elements(colls)/3
    nmem = njump+ncoll
    mems = dblarr(nmem, 5)      ; [tsta, tend, memsta, memend, rate].
    mems[0:njump-1,0:1] = [[jumps[*,0]], [jumps[*,0]]]
    mems[0:njump-1,2:3] = [[jumps[*,1]], [jumps[*,1]]]
    mems[0:njump-1,4] = 0
    mems[njump:*,0:1] = colls[*,0:1]
    mems[njump:*,2:3] = 0
    mems[njump:*,4] = colls[*,2]
    idx = sort(mems[*,0])
    mems = mems[idx,*]

    ; convert to absolute memory id.
    for i = 0, nmem-1 do begin
        if mems[i,0] eq mems[i,1] then continue     ; jump.
        mems[i,2] = mems[i-1,3]
        mems[i,3] = mems[i,2]+(mems[i,1]-mems[i,0])*mems[i,4]*s2b
        mems[i,2:3] = long(mems[i,2:3]) mod sz      ; wrap absolute memory id.
    endfor

    ; print result.
    printf, lun, ''
    printf, lun, 'RBSP-'+strupcase(probe)
    fmt = '(I6)'
    for i = 0, nmem-1 do begin
        if mems[i,4] eq 0 then begin
            printf, lun, 'jump:          '+time_string(mems[i,0])+' to '+$
                string(mems[i,3],format=fmt)
        endif else if mems[i,4] eq -1 then begin
            printf, lun, 'wrap:          '+time_string(mems[i,0])
        endif else begin
            printf, lun, 'collection:    '+time_string(mems[i,0])+' to '+$
                time_string(mems[i,1])+'    '+string(mems[i,2],format=fmt)+$
                ' to '+string(mems[i,3],format=fmt)+' at '+$
                string(mems[i,4],format='(I5)')+' sample/s'
        endelse
    endfor

    ; treat memory overflow.
    i = 1 & dt = 0.1
    while i lt nmem do begin
        if mems[i,2] le mems[i,3] then begin        ; jump, or normal.
            if mems[i,0] eq mems[i,1] then begin    ; jump
                mems[i,1] = mems[i,0]+dt
                if i gt 1 then mems[i,2] = mems[i-1,3]
            endif
            i+=1 & continue
        endif
        twrap = mems[i,0]+(mems[i,1]-mems[i,0])*$
            (sz-1-mems[i,2])/(sz-1-mems[i,2]+mems[i,3])
        tmem = [twrap,twrap,!values.d_nan,!values.d_nan,-1]
        mems = [mems[0:i,*],transpose(tmem),mems[i:*,*]]
        mems[i,1] = twrap-dt & mems[i,3] = sz-1
        i+=2
        mems[i,0] = twrap+dt & mems[i,2] = 0
        i+=1
        nmem = n_elements(mems)/5
    endwhile

    ; convert to array.
    t0 = dblarr(nmem*2) & memf = dblarr(nmem*2)
    for i = 0, nmem-1 do begin
        t0[i*2:i*2+1] = mems[i,0:1]
        memf[i*2:i*2+1] = mems[i,2:3]
    endfor
end

timespan, systime(1)-10D*86400, 20

; jumps: [n,2], each record in [tsta, absolute memory id].
; The 1st record is always the start location.
jumpa = [$
    [time_double('2014-03-15/19:52'), 158286D],$
    [time_double('2014-03-16/02:43'),      0D],$
    [time_double('2014-03-17/08:06'),      0D],$
    [time_double('2014-03-18/17:29'),      0D],$
    [time_double('2014-03-19/23:24'),      0D]]
jumpb = [$
    [time_double('2014-03-15/14:36'), 12464D],$
    [time_double('2014-03-18/09:12'), 205200D],$
    [time_double('2014-03-18/19:26'), 242200D]]
jumpa = transpose(jumpa)
jumpb = transpose(jumpb)

; protected memory, [n,2], each record in [tsta, tend].
prota = [$
    [time_double(['2014-03-12/22:00', '2014-03-13/08:00'])]]
protb = [$
    [time_double(['2014-03-13/14:07', '2014-03-14/20:38'])]]
prota = transpose(prota)
protb = transpose(protb)

; collection, [n,3], each record in [tsta, tend, rate].
colla = [$
    [time_double(['2014-03-15/19:52:41', '2014-03-15/22:46']), 16384],$
    [time_double(['2014-03-16/02:44', '2014-03-16/07:44']), 16384],$
    [time_double(['2014-03-16/11:42', '2014-03-16/16:42']), 16384],$
    [time_double(['2014-03-16/20:40', '2014-03-17/01:40']), 16384],$
    [time_double(['2014-03-17/05:38', '2014-03-17/08:05']), 16384],$
    [time_double(['2014-03-17/08:07', '2014-03-17/10:38']), 16384],$
    [time_double(['2014-03-17/14:36', '2014-03-17/19:36']), 16384],$
    [time_double(['2014-03-17/23:34', '2014-03-18/04:34']), 16384],$
    [time_double(['2014-03-18/08:32', '2014-03-18/13:32']), 16384],$

    [time_double(['2014-03-18/17:58', '2014-03-18/22:58']), 16384],$ 
    [time_double(['2014-03-19/02:57', '2014-03-19/07:57']), 16384],$
    [time_double(['2014-03-19/11:56', '2014-03-19/16:56']), 16384],$
    [time_double(['2014-03-19/20:54', '2014-03-19/23:23']), 16384],$

    [time_double(['2014-03-19/23:25', '2014-03-20/01:54']), 16384],$
    [time_double(['2014-03-20/05:53', '2014-03-20/10:53']), 16384],$
    [time_double(['2014-03-20/14:52', '2014-03-20/19:52']), 16384],$
    [time_double(['2014-03-20/23:50', '2014-03-21/04:50']), 16384]]
collb = [$
    [time_double(['2014-03-15/17:35', '2014-03-15/23:35']), 4096],$
    [time_double(['2014-03-16/02:28', '2014-03-16/02:38']),16384],$
    [time_double(['2014-03-17/23:24', '2014-03-17/23:34']),16384],$
    [time_double(['2014-03-18/09:13', '2014-03-18/09:23']),16384],$
    [time_double(['2014-03-19/12:35', '2014-03-19/12:45']),16384],$
    [time_double(['2014-03-20/23:41', '2014-03-20/23:51']),16384],$
    [time_double(['2014-03-16/04:16', '2014-03-16/10:16']), 4096],$
    [time_double(['2014-03-16/13:17', '2014-03-16/19:17']), 4096],$
    [time_double(['2014-03-16/22:19', '2014-03-17/04:19']), 4096],$
    [time_double(['2014-03-17/07:21', '2014-03-17/13:21']), 4096],$
    [time_double(['2014-03-17/16:22', '2014-03-17/22:22']), 4096],$
    [time_double(['2014-03-18/01:24', '2014-03-18/07:24']), 4096],$
    [time_double(['2014-03-18/10:26', '2014-03-18/16:26']), 4096],$
    [time_double(['2014-03-18/19:27', '2014-03-19/01:27']), 4096],$
    [time_double(['2014-03-19/04:29', '2014-03-19/10:29']), 4096],$
    [time_double(['2014-03-19/13:31', '2014-03-19/19:31']), 4096],$
    [time_double(['2014-03-19/22:32', '2014-03-20/04:32']), 4096],$
    [time_double(['2014-03-20/07:34', '2014-03-20/13:34']), 4096],$
    [time_double(['2014-03-20/16:36', '2014-03-20/22:36']), 4096]]
colla = transpose(colla)
collb = transpose(collb)


rbsp_b1_predict_plot_process, 'a', jumpa, colla, $
    time = timea, memf = memaf, mems = mema
rbsp_b1_predict_plot_process, 'b', jumpb, collb, $
    time = timeb, memf = membf, mems = memb

; **** below are from Aaron.
; create a tplot variable with the future memory locations.
store_data,'future_a',data={x:timea,y:memaf}
store_data,'future_b',data={x:timeb,y:membf}
options,['future_a','future_b'],'colors',250
options,['future_a','future_b'],'thick',2

; treat protect memory.
get_data,'rbspa_efw_b1_fmt_block_index2',data=gootmpa
get_data,'rbspb_efw_b1_fmt_block_index2',data=gootmpb
gootmpa2 = gootmpa
gootmpb2 = gootmpb

gootmpa2.y = !values.f_nan
gootmpb2.y = !values.f_nan

tpa0 = reform(prota[*,0]) & tpa1 = reform(prota[*,1])
for vv=0,n_elements(tpa0)-1 do begin
    boob = where((gootmpa.x ge tpa0[vv]) and (gootmpa.x le tpa1[vv]))
    if boob[0] ne -1 then gootmpa2.y[boob] = gootmpa.y[boob]
endfor
tpb0 = reform(protb[*,0]) & tpb1 = reform(protb[*,1])
for vv=0,n_elements(tpb0)-1 do begin
    boob = where((gootmpb.x ge tpb0[vv]) and (gootmpb.x le tpb1[vv]))
    if boob[0] ne -1 then gootmpb2.y[boob] = gootmpb.y[boob]
endfor
store_data,'rbspa_efw_b1_fmt_block_index3',data=gootmpa2
store_data,'rbspb_efw_b1_fmt_block_index3',data=gootmpb2
options,'rbsp?_efw_b1_fmt_block_index3','colors',100
options,'rbsp?_efw_b1_fmt_block_index3','psym',4

; prepare tplot.
store_data,'comba',data=['rbspa_efw_b1_fmt_block_index_cutoff',$
    'rbspa_efw_b1_fmt_block_index','rbspa_efw_b1_fmt_block_index2',$
    'rbspa_efw_b1_fmt_block_index3','future_a']
store_data,'combb',data=['rbspb_efw_b1_fmt_block_index_cutoff',$
    'rbspb_efw_b1_fmt_block_index','rbspb_efw_b1_fmt_block_index2',$
    'rbspb_efw_b1_fmt_block_index3','future_b']

sz = 262144D            ; memory size, in block.
ylim,['comba','combb'],0,sz
options,'rbsp?_b1_status','panel_size',0.5
tplot,['comba','rbspa_b1_status','combb','rbspb_b1_status']


; print last position: time and memory id.
get_data, 'rbspa_efw_b1_fmt_block_index_cutoff', data = tmp
print, 'RBSP-A last pos:    '+time_string(tmp.x[1])+'    at    '+$
    string(tmp.y[1],format='(I6)')
get_data, 'rbspb_efw_b1_fmt_block_index_cutoff', data = tmp
print, 'RBSP-B last pos:    '+time_string(tmp.x[1])+'    at    '+$
    string(tmp.y[1],format='(I6)')


print,'type .c to print the plot to the desktop'
stop

pcharsize_saved=!p.charsize
pfont_saved=!p.font
pcharthick_saved=!p.charthick
pthick_saved=!p.thick

set_plot,'Z'
rbsp_efw_init,/reset ; try to get decent colors in the Z buffer

device,set_resolution=[3200,2400],set_font='helvetica',/tt_font,set_character_size=[28,35]

!p.thick=4.
!p.charthick=4.

options,['comba','combb'],'ytickformat','(I6.6)'

tplot_options,'xmargin',[14,12]
tplot
timebar,jumpa_s,color=50,varname=['comba','rbspa_b1_status']
timebar,jumpb_s,color=50,varname=['combb','rbspb_b1_status']


; take snapshot of z buffer
snapshot=tvrd()
device,/close

; convert snapshot from index colors to true colors
tvlct,r,g,b,/get

sz=size(snapshot,/dimensions)
snapshot3=bytarr(3,sz[0],sz[1])
snapshot3[0,*,*]=r[snapshot]
snapshot3[1,*,*]=g[snapshot]
snapshot3[2,*,*]=b[snapshot]

; shrink snapshot
xsize=800
ysize=600
snapshot3=rebin(snapshot3,3,xsize,ysize)

print, 'saving png ...'
; write a png
write_png,'~/Desktop/b1_status_predict.png',snapshot3

set_plot,'X'
rbsp_efw_init,/reset
!p.charsize=pcharsize_saved
!p.font=pfont_saved
!p.charthick=pcharthick_saved
!p.thick=pthick_saved

end
