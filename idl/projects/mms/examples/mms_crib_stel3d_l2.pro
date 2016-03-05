; 
; PURPOSE: 
;     A crib sheet for visualizing MMS 3D distribution function data (L2) by stel3d. 
; 
; NOTES: 
;     Please use the latest version of SPEDAS bleeding edges. 
; 
; HISTORY: 
;     Preparedy by Kunihiro Keika, ISEE, Nagoya Univ., Mar. 2016. 
; 
; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; 
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-03-04 13:54:29 -0800 (Fri, 04 Mar 2016) $
;$LastChangedRevision: 20326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/mms_crib_stel3d_l2.pro $


; - - - FOR L2 DATA - - - 

trange='2015-11-18/02:'+['09:00','14:00']
trange='2015-11-18/02:10:'+['00','10']
probe='1'
species='i' 
datatype='d'+species+'s-dist'
data_rate='brst'
level='l2'

; load data 
mms_load_fpi,trange=trange,probe=probe,data_rate=data_rate,level=level,datatype=datatype 

; load data into standard structures 
name = 'mms'+probe+'_d'+species+'s_dist_'+data_rate 
dist = mms_get_fpi_dist(name, trange=trange, level=level, data_rate=data_rate, species=species, probe=probe)

;convert structures to stel3d data model
data = spd_dist_to_hash(dist)

;once GUI is open select PSD from Units menu
stel3d, data=data, trange=trange



end 
