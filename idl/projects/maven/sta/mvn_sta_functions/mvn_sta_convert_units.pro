pro mvn_sta_convert_units, data, units, scale=scale

cc3d=findgen(256)

if n_params() eq 0 then return

if strupcase(units) eq strupcase(data.units_name) then return

n_m = data.nmass
n_e = data.nenergy						; number of energies
nbins=data.nbins						; number of bins
rate_corr = 1024/n_e/data.ndef
energy = data.energy          					; in eV                (n_e,nbins,n_m)
gf = data.geom_factor*data.gf*data.eff
dt = data.integ_t
mass = data.mass*data.mass_arr
;dead = data.dead		; dead time, (sec) 0.5 usec for STATIC

case strupcase(data.units_name) of 
;'COMPRESSED' :  scale = 1.d						
'COUNTS' :  scale = 1.d							; 1/sec			
'RATE'   :  scale = 1.d*dt*rate_corr					; 1/sec
'CRATE'  :  scale = 1.d*dt*rate_corr					; 1/sec, corrected for dead time rate
'EFLUX'  :  scale = 1.d*gf 						; eV/cm^2-sec-sr-eV
'FLUX'   :  scale = 1.d*gf * energy					; 1/cm^2-sec-sr-eV
'DF'     :  scale = 1.d*gf * energy^2 * 2./mass/mass*1e5		; 1/(cm^3-(km/s)^3)
else: begin
        print,'Unknown starting units: ',data.units_name
	return
      end
endcase

; convert to COUNTS
tmp=data.data
tmp = scale * tmp

; take out dead time correction
; ignore dead time for now
if strupcase(data.units_name) ne 'COUNTS' and strupcase(data.units_name) ne 'RATE' then $
	tmp = dt*tmp
;	tmp = round(dt*tmp/(1.+tmp*dead/dt_arr))
;	tmp = (dt*tmp/(1.+tmp*dead/dt_arr))

scale = 0
case strupcase(units) of
'COMPRESSED' :  scale = 1.
'COUNTS' :  scale = 1.d
'RATE'   :  scale = 1.d/(dt*rate_corr)
'CRATE'  :  scale = 1.d/(dt*rate_corr)
'EFLUX'  :  scale = 1.d/(dt * gf)
'FLUX'   :  scale = 1.d/(dt * gf * energy)
'DF'     :  scale = 1.d/(dt * gf * energy^2 * 2./mass/mass*1e5 )
else: begin
        message,'Undefined units: '+units
        return
      end
endcase

; dead time correct data if not counts or rate
; ignore dead time for now
if strupcase(units) ne 'COUNTS' and strupcase(units) ne 'RATE' then begin
	denom = 1.
;	denom = 1.- dead/dt_arr*tmp/dt
;	void = where(denom lt .1,count)
;	if count gt 0 then begin
;		dprint,dlevel=1,min(denom,ind)
;		denom = denom>.1 
;		dprint,dlevel=1,' Error: convert_peace_units dead time error.'
;		dprint,dlevel=1,' Dead time correction limited to x10 for ',count,' bins'
;		dprint,dlevel=1,' Time= ',time_string(data.time,/msec)
;	endif
	tmp2 = tmp/denom
endif else tmp2 = tmp

; scale to new units
data.units_name = units
if find_str_element(data,'ddata') ge 0 then data.ddata = scale * tmp2^.5
data.data = scale * tmp2

return
end



