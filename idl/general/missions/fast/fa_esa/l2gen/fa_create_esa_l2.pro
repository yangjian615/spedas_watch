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
;       data_struct = the L2 data structure
;HISTORY:
; Dillon, 2009
; $LastChangedBy: jimm $
; $LastChangedDate: 2015-07-23 16:44:54 -0700 (Thu, 23 Jul 2015) $
; $LastChangedRevision: 18237 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/fast/fa_esa/l2gen/fa_create_esa_l2.pro $
;-
pro fa_create_esa_l2,type=type, $
                     orbit=orbit, $
                     data_struct=data_struct

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

  data_struct = all_dat
  str_element, data_struct, 'eflux0', data0, /add_replace
  str_element, data_struct, 'eflux1', data1, /add_replace
  str_element, data_struct, 'eflux2', data2, /add_replace

  return

end

