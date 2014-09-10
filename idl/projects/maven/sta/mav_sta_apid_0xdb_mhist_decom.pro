function mav_sta_apid_0xdb_MHist_decom,ccsds,lastpkt=lastpkt

;dprint,dlevel=2,'APID ',ccsds.apid,ccsds.seq_cntr,ccsds.size ,format='(a,z03," ",i,i)'
data = ccsds.data
if not keyword_set(lastpkt) then lastpkt = ccsds

decomp19=dblarr(256)
decomp19[0:127]=$
[0.0,1.0,2.0,3.0,4.0,5.0,6.0,7.0,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0,$
16.0,17.0,18.0,19.0,20.0,21.0,22.0,23.0,24.0,25.0,26.0,27.0,28.0,29.0,30.0,31.0,$
32.5,34.5,36.5,38.5,40.5,42.5,44.5,46.5,48.5,50.5,52.5,54.5,56.5,58.5,60.5,62.5,$
65.5,69.5,73.5,77.5,81.5,85.5,89.5,93.5,97.5,101.5,105.5,109.5,113.5,117.5,121.5,125.5,$
131.5,139.5,147.5,155.5,163.5,171.5,179.5,187.5,195.5,203.5,211.5,219.5,227.5,235.5,243.5,251.5,$
263.5,279.5,295.5,311.5,327.5,343.5,359.5,375.5,391.5,407.5,423.5,439.5,455.5,471.5,487.5,503.5,$
527.5,559.5,591.5,623.5,655.5,687.5,719.5,751.5,783.5,815.5,847.5,879.5,911.5,943.5,975.5,1007.5,$
1055.5,1119.5,1183.5,1247.5,1311.5,1375.5,1439.5,1503.5,1567.5,1631.5,1695.5,1759.5,1823.5,1887.5,1951.5,2015.5]
decomp19[128:255]=$
[2111.5,2239.5,2367.5,2495.5,2623.5,2751.5,2879.5,3007.5,3135.5,3263.5,3391.5,3519.5,3647.5,3775.5,3903.5,4031.5,$
4223.5,4479.5,4735.5,4991.5,5247.5,5503.5,5759.5,6015.5,6271.5,6527.5,6783.5,7039.5,7295.5,7551.5,7807.5,8063.5,$
8447.5,8959.5,9471.5,9983.5,10495.5,11007.5,11519.5,12031.5,12543.5,13055.5,13567.5,14079.5,14591.5,15103.5,15615.5,16127.5,$
16895.5,17919.5,18943.5,19967.5,20991.5,22015.5,23039.5,24063.5,25087.5,26111.5,27135.5,28159.5,29183.5,30207.5,31231.5,32255.5,$
33791.5,35839.5,37887.5,39935.5,41983.5,44031.5,46079.5,48127.5,50175.5,52223.5,54271.5,56319.5,58367.5,60415.5,62463.5,64511.5,$
67583.5,71679.5,75775.5,79871.5,83967.5,88063.5,92159.5,96255.5,100351.5,104447.5,108543.5,112639.5,116735.5,120831.5,124927.5,129023.5,$
135167.5,143359.5,151551.5,159743.5,167935.5,176127.5,184319.5,192511.5,200703.5,208895.5,217087.5,225279.5,233471.5,241663.5,249855.5,258047.5,$
270335.5,286719.5,303103.5,319487.5,335871.5,352255.5,368639.5,385023.5,401407.5,417791.5,434175.5,450559.5,466943.5,483327.5,499711.5,516095.5]

subsec1 = data[0]/256.d 
subsec2 = data[1]/(256.d)^2

; lstsub = lastpkt.data[0]data[0]/256.d + data[1]/(256.d)^2

; printdat,ccsds

str = {time:ccsds.time ,$
       subsec1:  subsec1,$
       subsec2:  subsec2,$
       subsec1b:  data[0],$
       subsec2b:  data[1],$
;       dtime:  ccsds.time + subsec - lastpkt.time - lstsub ,$
       seq_cntr:  ccsds.seq_cntr   ,$
;       seq_dcntr:  fix( ccsds.seq_cntr - lastpkt.seq_cntr )   ,$
       valid: 1  ,$
       mode: data[2]  ,$
       comp: data[3]  ,$
       data : decomp19[data[6:1029]] }
return, str
end
