pro mvn_sta_qf14_load

  
  ;;--------------------------------------------------------
  ;;STATIC APIDs
  apid=['2a','c0','c2','c4','c8','c6',$
        'ca','cc','cd','ce','cf','d0',$
        'd1','d2','d3','d4','d6','d7',$
        'd8','d9','da','db']

  ;;--------------------------------------------------------
  ;;Declare all the common block arrays
  common mvn_2a,mvn_2a_ind,mvn_2a_dat
  common mvn_c0,mvn_c0_ind,mvn_c0_dat
  common mvn_c2,mvn_c2_ind,mvn_c2_dat
  common mvn_c4,mvn_c4_ind,mvn_c4_dat
  common mvn_c6,mvn_c6_ind,mvn_c6_dat
  common mvn_c8,mvn_c8_ind,mvn_c8_dat
  common mvn_ca,mvn_ca_ind,mvn_ca_dat
  common mvn_cc,mvn_cc_ind,mvn_cc_dat
  common mvn_cd,mvn_cd_ind,mvn_cd_dat
  common mvn_ce,mvn_ce_ind,mvn_ce_dat
  common mvn_cf,mvn_cf_ind,mvn_cf_dat
  common mvn_d0,mvn_d0_ind,mvn_d0_dat
  common mvn_d1,mvn_d1_ind,mvn_d1_dat
  common mvn_d2,mvn_d2_ind,mvn_d2_dat
  common mvn_d3,mvn_d3_ind,mvn_d3_dat
  common mvn_d4,mvn_d4_ind,mvn_d4_dat
  common mvn_d6,mvn_d6_ind,mvn_d6_dat
  common mvn_d7,mvn_d7_ind,mvn_d7_dat
  common mvn_d8,mvn_d8_ind,mvn_d8_dat
  common mvn_d9,mvn_d9_ind,mvn_d9_dat
  common mvn_da,mvn_da_ind,mvn_da_dat
  common mvn_db,mvn_db_ind,mvn_db_dat


  ;;------------------------
  ;;Define bit
  bit14mask=2^14  

  ;;------------------------
  ;;Orbit selection 
  ;;All orbits: 713-753
  all_orbits = findgen(753-713)+713 
  ;;Odd orbits: 754-1e5
  ;;(except 755,759,823,841)
  ;;Use 1e5 as maximum orbit number.
  temp       = (findgen(1e5)+756.) * round(findgen(1e5) mod 2)
  pp=where(temp ne 0 and $
           temp ne 759 and $
           temp ne 823 and $
           temp ne 841)
  odd_orbits=temp[pp]
  orbits=[all_orbits,odd_orbits]


  ;;------------------------
  ;;Loop through all APIDs
  nn_apid=n_elements(apid)
  for api=0, nn_apid-1 do begin
     temp=execute('nn7=size(mvn_'+apid[api]+'_dat,/type)')
     if nn7 eq 8 then begin
        temp=execute('qf_new=mvn_'+apid[api]+'_dat.quality_flag')
        temp=execute('time_new=mvn_'+apid[api]+'_dat.time')
        ;;------------------------
        ;;Find orbit numbers
        tt=timerange()
        orb_num = round(mvn_orbit_num(time=time_new))
        nn=n_elements(time)
        ;;---------------------------------------
        ;;Loop through orbit numbers and pick out
        ;;flagged orbits from 'orbits' array
        cc_end=1
        while n_elements(orb_num) gt 1 and $
           cc_end ge 1 do begin
           pp_orbs=where(orb_num eq min(orb_num))           
           pp_not_orbs=where(orb_num ne min(orb_num),cc_end)           
           current_orbit=min(orb_num)
           pp_check=where(current_orbit eq orbits,cc)
           if cc ne 0 then begin
              ;;-------------------------------------------
              ;;Apply quality flag to all matching orbits
              temp=execute('temp_qf=mvn_'+apid[api]+'_dat.quality_flag')
              temp_qf[pp_orbs] = temp_qf[pp_orbs] or bit14mask
              temp=execute('mvn_'+apid[api]+'_dat.quality_flag[pp_orbs]=temp_qf[pp_orbs]')             
           endif
           orb_num=orb_num[pp_not_orbs]
        endwhile           
     endif
  endfor


end
