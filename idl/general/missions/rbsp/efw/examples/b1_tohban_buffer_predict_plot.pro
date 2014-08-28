;Overplot the predicted buffer location over the current buffer location plot
;This is a useful tool for visualizing the future location of the B1 memory pointer location. 
;You can implement B1 collection times, pointer jumps, and indicate regions that you'd
;rather not overwrite. 

;Written by Aaron W Breneman, University of Minnesota, December, 2013



;First need to run:  .run b1_status_crib

;In order to check out exact memory locations at specific times use
	;ctime, t, buffer_index, npoints=2, /exact
	;record_rate=(buffer_index[1] - buffer_index[0]) / (t[1] - t[0])
	;print, 'B1 record rate (blocks/sec):', record_rate


;-----------------------------------------------------------------------------------------

;Reference (memory) location of B1 pointer. All collection times are based on this location. 
;Probably need to update this from time-to-time b/c the prediction times may drift
;from actual collection times. 
;Update using ctime, t, buffer_index, npoints=2, /exact
;Only included predicted times AFTER the reference location
;A: 1.287d5 at 2014-01-31/23:40 (REFERENCE TIME)
;B: 1.220d5 at 2014-01-31/19:30 (REFERENCE TIME)
cloca = 1.287d5
clocb = 1.220d5

sz = 262144L	;size of memory buffer (blocks)



;-----------------------------------------------------------------------------------------
;Start times of jump (AFTER REFERENCE TIME ONLY)
jumpa_s = time_double(['2014-02-02/13:25','2014-02-05/19:00','2014-02-07/02:30'])
jumpb_s = time_double(['2014-02-06/23:55'])
;number of blocks to jump
nb_jumpa = [223394.,61800.,216744.]
nb_jumpb = [23700.]


;-----------------------------------------------------------------------------------------



;Times of requested data playback that we want to be sure to protect (black diamonds are changed to blue diamonds)
tpa0 = time_double('2014-01-' + ['09/19:50','09/17:10','09/18:40','31/19:00','09/16:20'])
tpa1 = time_double('2014-01-' + ['09/20:20','09/17:50','09/19:35','31/22:00','09/16:30'])
tpb0 = time_double('2014-01-' + ['31/17:30','31/12:30'])
tpb1 = time_double('2014-01-' + ['31/19:30','31/16:00'])

;-----------------------------------------------------------------------------------------


;Define date collection rate for each collection time
ratea = [4096,4096,4096,4096,4096,4096,4096,4096,4096,4096]
rateb = [4096,4096,4096,4096,4096,4096,4096,4096]




;Start times of collection on A (AFTER REFERENCE TIME ONLY)
timea_s = time_double(['2014-02-02/13:30','2014-02-05/13:15','2014-02-05/19:10',$
'2014-02-07/02:40','2014-02-07/21:30','2014-02-08/13:45','2014-02-08/23:45','2014-02-10/02:30','2014-02-10/21:15',$
'2014-02-11/13:00'])

;End times of collection on A (AFTER REFERENCE TIME ONLY)
timea_e = time_double(['2014-02-02/20:30','2014-02-05/18:59:50','2014-02-05/20:30',$
'2014-02-07/06:40','2014-02-08/00:30','2014-02-08/19:30','2014-02-09/03:30','2014-02-10/06:15','2014-02-10/24:00',$
'2014-02-11/20:00'])


;Start times of collection on B (AFTER REFERENCE TIME ONLY)
timeb_s = time_double(['2014-02-03/12:45','2014-02-07/00:00',$
		'2014-02-08/02:20','2014-02-08/21:30','2014-02-09/13:40','2014-02-10/00:00','2014-02-10/19:00',$
		'2014-02-12/13:30'])

;End times of collection on B (AFTER REFERENCE TIME ONLY)
timeb_e = time_double(['2014-02-03/19:45','2014-02-07/03:30',$
		'2014-02-08/06:30','2014-02-09/01:00','2014-02-09/19:40','2014-02-10/03:30','2014-02-10/20:30',$
		'2014-02-12/20:30'])

;-----------------------------------------------------------------------------------------


;Do some quick array size checks
if n_elements(ratea) ne n_elements(timea_s) then stop
if n_elements(ratea) ne n_elements(timea_e) then stop
if n_elements(rateb) ne n_elements(timeb_s) then stop
if n_elements(rateb) ne n_elements(timeb_e) then stop
if n_elements(timea_s) ne n_elements(timea_e) then stop
if n_elements(timeb_s) ne n_elements(timeb_e) then stop
if n_elements(jumpa_s) ne n_elements(nb_jumpa) then stop
if n_elements(jumpb_s) ne n_elements(nb_jumpb) then stop
if n_elements(tpa0) ne n_elements(tpa1) then stop
if n_elements(tpb0) ne n_elements(tpb1) then stop



;Blocks per second
ratea2 = ratea/(16000./3.)
rateb2 = rateb/(16000./3.)


;Number of blocks to record for each collection time (3 blocks/sec for 16K)
hopva = (timea_e - timea_s)*ratea2
hopvb = (timeb_e - timeb_s)*rateb2

jumpva = nb_jumpa
jumpvb = nb_jumpb

jump_or_collect_a = [replicate(1,n_elements(timea_s)),replicate(2,n_elements(jumpa_s))]
jump_or_collect_b = [replicate(1,n_elements(timeb_s)),replicate(2,n_elements(jumpb_s))]


;combine collection times and jump times
timea_s = [timea_s,jumpa_s]
timeb_s = [timeb_s,jumpb_s]
timea_e = [timea_e,jumpa_s+0.1]
timeb_e = [timeb_e,jumpb_s+0.1]
skipva = [hopva,jumpva]
skipvb = [hopvb,jumpvb]


sta = sort(timea_s)
stb = sort(timeb_s)

joc_a = jump_or_collect_a[sta]
joc_b = jump_or_collect_b[stb]


;Final sorted start and end times for each collection and jump
timea_s = timea_s[sta]
timea_e = timea_e[sta]
timeb_s = timeb_s[stb]
timeb_e = timeb_e[stb]
;Final sorted values of the buffer hop and jump for each collection and jump
incrementva = skipva[sta]
incrementvb = skipvb[stb]


;-------------------------------------------------------------------------------
;Print out timeline of collection and jumps

rr=0
print,'-----------------------------------------------------------------------------------'
print,'RBSP-A'
for uu=0,n_elements(timea_s)-1 do begin

	output = time_string(timea_s[uu])+' to '+ time_string(timea_e[uu])
	if joc_a[uu] eq 2 then output = 'JUMP    ' + output
	if joc_a[uu] eq 1 then output = 'COLLECT ' + output+' rate='+strtrim(floor(ratea[rr]),2)+ ' S/s|'
	if joc_a[uu] eq 1 then output += ' ' + strtrim(floor((timea_e[uu] - timea_s[uu])/60.),2) + ' minutes|'
	if joc_a[uu] eq 1 then output += ' ' + strtrim(floor((timea_e[uu] - timea_s[uu])*ratea2[rr]),2) + ' blocks'
	if joc_a[uu] eq 1 then rr++
	print,output
endfor
print,'-----------------------------------------------------------------------------------'
rr=0
print,'RBSP-B'
for uu=0,n_elements(timeb_s)-1 do begin

	output = time_string(timeb_s[uu])+' to '+ time_string(timeb_e[uu])
	if joc_b[uu] eq 2 then output = 'JUMP    ' + output
	if joc_b[uu] eq 1 then output = 'COLLECT ' + output+' rate='+strtrim(floor(rateb[rr]),2)+ ' S/s|'
	if joc_b[uu] eq 1 then output += ' ' + strtrim(floor((timeb_e[uu] - timeb_s[uu])/60.),2) + ' minutes|'
	if joc_b[uu] eq 1 then output += ' ' + strtrim(floor((timeb_e[uu] - timeb_s[uu])*rateb2[rr]),2) + ' blocks'
	if joc_b[uu] eq 1 then rr++
	print,output
endfor
print,''
;-------------------------------------------------------------------------------


stop

;Future memory locations
mema = dblarr(n_elements(incrementva))
memb = dblarr(n_elements(incrementvb))

for i=0,n_elements(incrementva)-1 do mema[i] = total(incrementva[0:i]) + cloca
for i=0,n_elements(incrementvb)-1 do memb[i] = total(incrementvb[0:i]) + clocb

timea = [timea_s,timea_e]
timeb = [timeb_s,timeb_e]
sa = sort(timea)
sb = sort(timeb)
timea = timea[sa]
timeb = timeb[sb]

memas = shift(mema,1)
memas[0] = cloca
membs = shift(memb,1)
membs[0] = clocb

mema = floor(mema)
memas = floor(memas)
memb = floor(memb)
membs = floor(membs)

;Take into account circular nature of buffer
mema = mema mod sz
memas = memas mod sz
memb = memb mod sz
membs = membs mod sz

;combine start and end times of each collection interval
memaf = [memas,mema]
membf = [membs,memb]

;Sort chronologically
memaf = memaf[sa]
membf = membf[sb]



;Create a tplot variable with the future memory locations
store_data,'future_a',data={x:timea,y:memaf}
store_data,'future_b',data={x:timeb,y:membf}
options,['future_a','future_b'],'colors',250
options,['future_a','future_b'],'thick',3


;Create a tplot variable with horizontal lines to represent the jumped memory locations


;Find value at jump location
get_data,'future_a',data=bia
get_data,'future_b',data=bib


;use last element of the jump array
gooa = where(bia.x ge jumpa_s[n_elements(jumpa_s)-1])
goob = where(bib.x ge jumpb_s[n_elements(jumpb_s)-1])


v0a = bia.y[gooa[0]]
v1a = v0a + nb_jumpa[n_elements(jumpa_s)-1]
v1a = v1a mod sz

v0b = bib.y[goob[0]]
v1b = v0b + nb_jumpb[n_elements(jumpb_s)-1]
v1b = v1b mod sz

t0 = time_double('2012-01-01/00:00')
t1 = time_double('2050-01-01/00:00')

store_data,'jump_a1',data={x:[t0,t1],y:[v0a,v0a]}
store_data,'jump_a2',data={x:[t0,t1],y:[v1a,v1a]}
store_data,'jump_b1',data={x:[t0,t1],y:[v0b,v0b]}
store_data,'jump_b2',data={x:[t0,t1],y:[v1b,v1b]}

get_data,'rbspa_efw_b1_fmt_block_index2',data=gootmpa
get_data,'rbspb_efw_b1_fmt_block_index2',data=gootmpb
gootmpa2 = gootmpa
gootmpb2 = gootmpb

gootmpa2.y = !values.f_nan
gootmpb2.y = !values.f_nan



for vv=0,n_elements(tpa0)-1 do begin
	boob = where((gootmpa.x ge tpa0[vv]) and (gootmpa.x le tpa1[vv]))
	if boob[0] ne -1 then gootmpa2.y[boob] = gootmpa.y[boob]
endfor
for vv=0,n_elements(tpb0)-1 do begin
	boob = where((gootmpb.x ge tpb0[vv]) and (gootmpb.x le tpb1[vv]))
	if boob[0] ne -1 then gootmpb2.y[boob] = gootmpb.y[boob]
endfor



store_data,'rbspa_efw_b1_fmt_block_index3',data=gootmpa2
store_data,'rbspb_efw_b1_fmt_block_index3',data=gootmpb2
options,'rbsp?_efw_b1_fmt_block_index3','colors',100
options,'rbsp?_efw_b1_fmt_block_index3','psym',4


store_data,'comba',data=['rbspa_efw_b1_fmt_block_index_cutoff','rbspa_efw_b1_fmt_block_index','rbspa_efw_b1_fmt_block_index2','rbspa_efw_b1_fmt_block_index3','future_a','jump_a1','jump_a2']
store_data,'combb',data=['rbspb_efw_b1_fmt_block_index_cutoff','rbspb_efw_b1_fmt_block_index','rbspb_efw_b1_fmt_block_index2','rbspb_efw_b1_fmt_block_index3','future_b','jump_b1','jump_b2']



ylim,['comba','combb'],0,sz

options,'rbsp?_b1_status','panel_size',0.5
tplot,['comba','rbspa_b1_status','combb','rbspb_b1_status']
timebar,jumpa_s,color=50,varname=['comba','rbspa_b1_status']
timebar,jumpb_s,color=50,varname=['combb','rbspb_b1_status']

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

; write a png
write_png,output_dir+'b1_status_predict.png',snapshot3

set_plot,'X'
rbsp_efw_init,/reset
!p.charsize=pcharsize_saved
!p.font=pfont_saved
!p.charthick=pcharthick_saved
!p.thick=pthick_saved


end
