;+
;NAME:
; fa_create_esa_l2
;PURPOSE:
; Creates an L2 data structure from l1 data
;INPUT:
; none explicit, all via keyword
;OUTPUT:
; none explicit, all via keyword
;KEYWORDS:
; input keywords:
;       type = the data type, one of ['ees','ies','eeb','ieb']
;       orbit = orbit range
; output keywords:
;       datavary = the L2 data structure
;       datanovary = a structure with L1 data?
;HISTORY:
; Dillon, 2009
; $LastChangedBy: jimm $
; $LastChangedDate: 2015-07-21 13:57:13 -0700 (Tue, 21 Jul 2015) $
; $LastChangedRevision: 18193 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/fast/fa_esa/l2gen/fa_create_esa_l2.pro $
;-
pro fa_create_esa_l2,type=type, $
        orbit=orbit, $
        datavary=datavary, $
        datanovary=datanovary

  fa_init

  common fa_information,info_struct

;first input the data

;Add an option for times, jmm, 2015-07-21
  If(~keyword_set(orbit)) Then Begin
     dprint, 'No orbit range set, using timerange()'
     tr = timerange()
     orbit = fa_time_to_orbit(tr)
  Endif

  fa_orbitrange,orbit
  fa_load_l1,datatype=type
  get_fa1_common,type,data=all_dat
  ntimes=n_elements(all_dat.time)

;data0,1, and 2 will be the eflux data for each mode, if there is no
;data for a given mode, then there is a single NaN value
  If(n_elements(all_dat.data0) Eq 1 && ~finite(all_dat.data0[0])) Then Begin
     data0 = all_dat.data0
     data0[*] = 0.0
  Endif Else data0 = float(all_dat.data0) 
  If(n_elements(all_dat.data1) Eq 1 && ~finite(all_dat.data1[0])) Then Begin
     data1 = all_dat.data1
     data1[*] = 0.0
  Endif Else data1 = float(all_dat.data1) 
  If(n_elements(all_dat.data2) Eq 1 && ~finite(all_dat.data2[0])) Then Begin
     data2 = all_dat.data2
     data2[*] = 0.0
  Endif Else data2 = float(all_dat.data2) 

  dead=all_dat.dead
  dt_arr=1.

  tmp_vary_struct = {time:0d, end_time:0d, integ_t:0d, delta_t:0d, $
                     valid:0b, data_quality:0b, nbins:0b, nenergy:0b, $
                     geom_factor:0., $
                     data_ind:0s, gf_ind:0s, bins_ind:0s, mode_ind:0b, $
                     theta_shift:0., theta_max:0., theta_min:0., $
                     sc_pot:0., bkg:0.}
  datavary=replicate(tmp_vary_struct,ntimes)

;ccvt is array for converting COMPRESSED to COUNT
  case type of
     'ees': ccvt=info_struct.byteto16_map
     'eeb': ccvt=info_struct.byteto14_map
     'ies': ccvt=info_struct.byteto16_map
     'ieb': ccvt=info_struct.byteto14_map
     else: begin
        dprint,'Error Converting Between Compressed and Counts: Invalid Type'
        return
     end
  endcase

  for i=0,ntimes-1 do begin
;Instead of using get_fa1 routines and fa_convert_esa_units.pro, it is
;faster to convert to EFLUX here.
;EFLUX=COUNTS(after dead time correction)/(GEOM_FACTOR*GF*EFF*DT)
     case all_dat.mode_ind[i] of
        0: begin
           data0_tmp=ccvt[all_dat.data0[*,*,all_dat.data_ind[i]]]
           gf_tmp=all_dat.geom_factor[i]*all_dat.gf[0:47,0:31,all_dat.gf_ind[i]]*all_dat.eff[0:47,0:31,0]
           dt=all_dat.integ_t[i]
           denom = 1.- dead/dt_arr*data0_tmp/dt
           void = where(denom lt .1,count)
           if count gt 0 then begin
              dprint,dlevel=1,min(denom,ind)
              denom = denom>.1 
              dprint,dlevel=1,' Error: convert_peace_units dead time error.'
           endif
           data0_tmp=data0_tmp/denom
           data0_tmp=data0_tmp/(gf_tmp*dt)
           data0[*,*,all_dat.data_ind[i]]=data0_tmp
        end
        1: begin
           data1_tmp=ccvt[all_dat.data1[*,*,all_dat.data_ind[i]]]
           gf_tmp=all_dat.geom_factor[i]*all_dat.gf[0:47,0:63,all_dat.gf_ind[i]]*all_dat.eff[0:47,0:63,1]
           dt=all_dat.integ_t[i]
           denom = 1.- dead/dt_arr*data1_tmp/dt
           void = where(denom lt .1,count)
           if count gt 0 then begin
              dprint,dlevel=1,min(denom,ind)
              denom = denom>.1 
              dprint, dlevel=1,' Error: convert_peace_units dead time error.'
           endif
           data1_tmp=data1_tmp/denom
           data1_tmp=data1_tmp/(gf_tmp*dt)
           data1[*,*,all_dat.data_ind[i]]=data1_tmp
        end
        2: begin
           data2_tmp=ccvt[all_dat.data2[*,*,all_dat.data_ind[i]]]
           gf_tmp=all_dat.geom_factor[i]*all_dat.gf[0:95,0:31,all_dat.gf_ind[i]]*all_dat.eff[0:95,0:31,2]
           dt=all_dat.integ_t[i]
           denom = 1.- dead/dt_arr*data2_tmp/dt
           void = where(denom lt .1,count)
           if count gt 0 then begin
              dprint,dlevel=1,min(denom,ind)
              denom = denom>.1 
              dprint,dlevel=1,' Error: convert_peace_units dead time error.'
           endif
           data2_tmp=data2_tmp/denom
           data2_tmp=data2_tmp/(gf_tmp*dt)
           data2[*,*,all_dat.data_ind[i]]=data2_tmp
        end
     endcase
  endfor
  datavary.time=all_dat.time
  datavary.end_time=all_dat.end_time
  datavary.integ_t=all_dat.integ_t
  datavary.delta_t=all_dat.delta_t
  datavary.valid=all_dat.valid
  datavary.data_quality=all_dat.data_quality
  datavary.nbins=all_dat.nbins
  datavary.nenergy=all_dat.nenergy
  datavary.geom_factor=all_dat.geom_factor
  datavary.data_ind=all_dat.data_ind
  datavary.gf_ind=all_dat.gf_ind
  datavary.bins_ind=all_dat.bins_ind
  datavary.mode_ind=all_dat.mode_ind
  datavary.theta_shift=all_dat.theta_shift
  datavary.theta_max=all_dat.theta_max
  datavary.theta_min=all_dat.theta_min
  datavary.sc_pot=all_dat.sc_pot
  datavary.bkg=all_dat.bkg

  datanovary={data0:data0, $
              data1:data1, $
              data2:data2, $
              energy:all_dat.energy, $
              bins:all_dat.bins, $
              theta:all_dat.theta, $
              gf:all_dat.gf, $
              denergy:all_dat.denergy, $
              dtheta:all_dat.dtheta, $
              eff:all_dat.eff, $
              dead:all_dat.dead, $
              mass:all_dat.mass, $
              charge:all_dat.charge, $
              bkg_arr:all_dat.bkg_arr, $
              header_bytes:all_dat.header_bytes}
  return

end

