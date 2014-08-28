function mvn_sep_lut2map,mapname=mapname,lut=lut ,mapnum=mapnum

if keyword_set(mapname) or not keyword_set(lut) then lut = mvn_sep_create_lut(mapname,mapnum=mapnum)

psym = [7,4]
adcm = [0,1,1,1,2,2,4,0]
colors = [0,2,4,6,3,1,5]
colors = [0,2,4,6,3,1,0]
bmap =  {sens:0, bin:0b, name:'', fto:0,det:0 , tid:0, ADC:[0,0],  num:0,  ok:0,color:0 ,psym:0 , x:0., y:0., dx:0. ,dy:0.}
bmaps = replicate(bmap,256)                                                                
remap = indgen(16)
remap[[0,1,10,11]] = 0
det = [0,1,2,4,3,0,5,6,0]
names = strsplit('X O T OT F FO FT FTO Mixed',/extract)
names = reform( transpose( [['A-'+names],['B-'+names]]))
realfto = remap[lindgen(2L^16) / 2L^12]
for b=0,255 do begin
   w = where((lut eq b) and (realfto ne 0),nw)
   if nw eq 0 then w = 0
   fto = minmax(remap[  w / 2L^12 ] )
   if fto[0] eq fto[1] then fto = fto[0] else fto = 8
   bmap.name = names[fto]
   bmap.fto = fto / 2
   bmap.bin = b
   bmap.det = det[fto / 2] 
   bmap.color = colors[bmap.det]
   bmap.tid = fto mod 2
   bmap.psym = psym[bmap.tid]
   adc = minmax( w mod 2L^12  )+ [0,1]
   bmap.adc = adc  
   bmap.num = adc[1] - adc[0]
   bmap.ok = (bmap.num eq nw) and bmap.fto ne 8
   bmap.adc *= adcm[bmap.det]    ; OT and FT are doubled,  FTO is quadrupled
   bmap.num = bmap.adc[1] - bmap.adc[0]
   bmaps[b] = bmap
endfor
bmaps.x = (bmaps.adc[1] + bmaps.adc[0])/2.
bmaps.dx = bmaps.adc[1] - bmaps.adc[0]
return,bmaps
end
