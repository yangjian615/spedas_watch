; 
; PURPOSE 
;    READ MMS/FPI 3D DISTRIBUTION DATA AND RETURN A STRUCTURE. 
; 
; INPUT: 
;    TRANGE: Time range 
; 
; OUTPUT: 
;    THIS FUNCTION RETURNS A STRUCTURE THAT CONTAIN 3D DISTRIBUTION DATA 
;    AND RELATED NECESSARY INFORMAITON SUCH AS ENERGY AND SECTOR ANGLES. 
; 
; AUTHOR: 
;    Kunihiro Keika, ISEE, Nagoya Univ. 
; 
; HISTORY: 
;    Created on Dec. 25, 2015 
;    
; 
; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; 
function get3d_mms_fpi_dist, trange=trange 
;
;--- TIME SETTING --- 
;
if not keyword_set(trange) then trange=['2015-09-01/12:00:00','2015-09-01/12:15:00']
;
; 
;--- LOAD MMS FPI 3D-DIST DATA --- 
;
mms_load_fpi, probe=1, level='l1b',trange=trange,data_rate='brst',datatype=['dis-dist'], /no_update
;
tvar_dist = 'mms1_dis_brstSkyMap_dist'
;
;--- TIMESTAMP ---
;
get_data, tvar_dist, data=data 
tdouble = data.x 
tstring = time_string(data.x) 
;
;
;--- 3D DISTRIBUTION ---
;
data = mms_get_fpi_dist(tvar_dist) 
;
; EXTRACT NECESSARY INFORMATION TO VISUALIZE 3D DISTRIBUTION 
; ADD TIMESTAMP INFORMATION 
; 
mass = 1.67D*10^(-27.); kg
emu = 1. 
;velo = sqrt(2.*eV2J(energy*10^3.)/mass/emu)
;velo = sqrt(2.*(energy*10^3.*1.6*10^(-19.))/mass/emu)
; 
ntime = n_elements(*data) 
for i = 0, ntime-1 do begin 
   dist = ((*data)[i].data)  
   bins = ((*data)[i].bins) 
   energy = ((*data)[i].energy) 
   denergy = ((*data)[i].denergy) 
   phi = ((*data)[i].phi) 
   dphi = ((*data)[i].dphi) 
   theta = ((*data)[i].theta) 
   dtheta = ((*data)[i].dtheta) 
   j = where(dist ge 0) 
   dist = dist[j] * 10^(12.) ; s3/m6 
   bins = bins[j] 
   energy = energy[j]/1000.; in keV 
   denergy = denergy[j]/1000.; in keV 
   velocity = sqrt(2.*(energy*10^3.*1.6*10^(-19.))/mass/emu)/10^3. ; km/s 
   phi = phi[j] 
   dphi = dphi[j] 
   theta = 90.-theta[j]; in co-latitude in S/C coordinates.  
   dtheta = dtheta[j] 
   pdf_tmp = {tdouble:tdouble[i],tstring:tstring[i],dist:dist,bins:bins,energy:energy,denergy:denergy,velocity:velocity, phi:phi,dphi:dphi,theta:theta,dtheta:dtheta} 
   if i eq 0 then pdf = replicate(pdf_tmp,ntime) 
   pdf[i] = pdf_tmp 
   ;pdf: particle distribution function 
endfor 


help, pdf 
help, pdf, /st 
return, pdf 
end 
