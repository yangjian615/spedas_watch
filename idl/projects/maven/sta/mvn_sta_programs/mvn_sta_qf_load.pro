
;;Quality Flag Legend
;;
;;Location   Definition                                            - Determined from                                                             
;;---------------------------------------------------------------------------------------------------------------------------------                       
;;bit 0      Test pulser on                                        - testpulser header bit set
;;bit 1      Diagnostic mode                                       - diagnostic header bit set                                                  
;;bit 2      Dead time correction > factor of 2                    - deadtime correction > 2                                                    
;;bit 3      Dead time correction not at event time                - missing data quantity for deadtime                                         
;;bit 4      MCP detector gain droop flag- deadtime and beam width - tbd algorithm                                    
;;bit 5      Electrostatic attenuator failing at <2 eV             - attE on and eprom_ver<2                                                    
;;bit 6      Attenuator change during accumulation                 - att 1->2 or 2->1 transition (one measurement)                              
;;bit 7      Mode change during accumulation                       - only needed for packets that average data during mode transition           
;;bit 8      LPW sweeps interfering with data                      - LPW mode not dust mode                                                     
;;bit 9      High background                                       - minimum value in DA > 1000                                                 
;;bit 10     Missing background                                    - dat.bkg = 0           - may not be needed                                  
;;bit 11     Missing spacecraft potential                          - dat.sc_pot = 0        - may not be needed                                  
  

;;Bit Value Definition
;;----------------------------------------------------------
;;bit = 0 -> No Flag.
;;bit = 1 -> Flag set (see legend above). 
;;
;;Example:
;;
;;     IDL> print, format='(B)',quality_flag
;;     IDL> 0000100101100
;;
;;     Flags are set for:
;;     bit 2 = 1
;;     bit 3 = 1
;;     bit 5 = 1
;;     bit 8 = 1




pro mvn_sta_qf_load



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


  ;;----------------------------------------------------
  ;;NOTE: There are no housekeeping quality flags yet.
  apid=[$;'2a',$
        'c0','c2','c4','c6','c8',$
        'ca','cc','cd','ce','cf','d0',$
        'd1','d2','d3','d4']
        ;,'d6','d7',$
        ;'d8','d9'];,$
        ;'da','db']
  nn_apid=n_elements(apid)




  ;;----------------------------------------------------
  ;;Load Standard Variabls
  ;;
  ;;   Make sure da is loaded to obtain quality flags
  ;;   for the the background (bit 9).
  temp=execute("temp1=mvn_da_dat")
  if temp eq 0 then mvn_sta_l2_load, apid=['da']
  temp=execute("temp1=mvn_da_dat")
  if temp eq 0 then stop, 'mvn_da_dat needs to be loaded for.'
  _da_counts  = execute("da_counts = mvn_da_dat.data")
  _da_time    = execute("da_time   = mvn_da_dat.time")




  ;;-----------------------
  ;;Find orbits and altitude
  tt=timerange()
  orb_time = tt[0]+360.*findgen(240)*(tt[1]-tt[0])/(24.*3600.)
  orb_num = mvn_orbit_num(time=orb_time)
  maven_orbit_tplot,result=result,/loadonly
  R_m = 3389.9D
  npts=n_elements(result.x)
  ss = dblarr(npts, 4)
  ss[*,0] = result.x
  ss[*,1] = result.y
  ss[*,2] = result.z
  ss[*,3] = result.r
  alt = (ss[*,3] - 1D)*R_m




  ;;;********************************************************
  ;;;Cycle through all loaded APIDs
  for api=0, nn_apid-1 do begin
     temp=execute('nn1=size(mvn_'+apid[api]+'_dat,/type)')
     if nn1 ne 0 then begin
        
        print, 'Loading '+apid[api]
        ;;Change structure name to dat
        temp=execute("dat=mvn_"+apid[api]+"_dat")
        ;;Load structure values
        npts    = n_elements(dat.data[*,0,0])
        nmass   = dat.nmass
        nenergy = dat.nenergy
        nbins   = dat.nbins
        time    = dat.time
        mode    = dat.mode
        att     = dat.att_ind
        header  = dat.header
        eprom   = dat.eprom_ver
        swp_ind = dat.swp_ind
        counts  = reform(dat.data,npts,nenergy,nbins,nmass)
        energy  = reform(dat.energy,dimen1(dat.energy),nenergy,nbins,nmass) 
        


        ;;*******************************************************
        ;;Bit 0 - Test pulser
        ;;Check to see if test pulser is on/off (1/0)
        ;;QF bit 0    test pulser on   (header and 128)        
        bit0mask=2^0
        head=(header and 128L)/128L
        pp=where(head eq 1L,cc)
        if cc ne 0 then dat.quality_flag[pp] = dat.quality_flag[pp] or bit0mask


        
        ;;*******************************************************
        ;;Bit 1 - Diagnostic Mode
        ;;QF bit 1    diagnostic mode  (header and 64)        
        bit1mask=2^1
        head=(header and 64L)/64L
        pp=where(head eq 1L,cc)
        if cc ne 0 then dat.quality_flag[pp] = dat.quality_flag[pp] or bit1mask



        ;;*******************************************************
        ;;Bit 2 - Dead time correction
        bit2mask=2^2


        
        ;;*******************************************************
        ;;Bit 3 - Dead time correction
        bit3mask=2^3


        
        ;;*******************************************************
        ;;Bit 4 - MCP Gain Droop
        bit4mask=2^4



        ;;*******************************************************
        ;;Bit 5 - Electrostatic Attenuator Irregularity
        ;;
        ;;NOTES:
        ;;      Electrostatic attenuator flag should be set if
        ;;      ((att_ind eq 1) or (att_ind eq 3)) and
        ;;      (((eprom eq 2) and (c1 gt 10.)) or ((eprom eq 1) and (c2 gt 10.)))
        ;;      where c1 is the total counts in apid c0 less than .75 eV
        ;;      where c2 is the total counts in apid c0 less than 2.5 eV 
        ;;
        ;;      Do c1 and c2 always have equal indexes??? 
        bit5mask=2^5
        energies=energy[swp_ind,*,*,*]
        p1_energies=where(energies[*,nenergy-1,0,0] lt 0.75,c1_energies)
        p2_energies=where(energies[*,nenergy-1,0,0] lt 2.50,c2_energies)
        if c1_energies gt 0 and $
           c2_energies gt 0 then begin
           
           att_e1=att[p1_energies]
           att_e2=att[p2_energies]
           e1_temp=counts[p1_energies,*,*]
           e2_temp=counts[p2_energies,*,*]
           c1=fltarr(c1_energies)
           c2=fltarr(c2_energies)
           for i=0., c1_energies-1 do c1[i]=total(e1_temp[i,where(e1_temp[i,*,0] lt 0.75),0],2)
           for i=0., c2_energies-1 do c2[i]=total(e2_temp[i,where(e2_temp[i,*,0] lt 2.50),0],2)
           ppp=where($
               ((att_e1 eq 1)  or  $
                (att_e1 eq 3)) and $
               ((eprom[p1_energies] eq 2)    and $
                (c1 lt 10.)        or  $
                (eprom[p2_energies] eq 1)    and $
                (c2 lt 10.)),ccc)
           if ccc ne 0 then pp=p1_energies[ppp]
           if ccc ne 0 then dat.quality_flag[pp] = dat.quality_flag[pp] or bit5mask
        endif



        ;;*******************************************************
        ;;Bit 6 - Attenuator Change During Accumulation
        bit6mask=2^6
        pp=[0,findgen(n_elements(att)-1)]        
        temp=att-att[pp]
        pp=where(temp gt 0)
        if cc ne 0 then dat.quality_flag[pp] = dat.quality_flag[pp] or bit6mask
        


        ;;*******************************************************
        ;;Bit 7  - Mode Change During Accumulation
        bit7mask=2^7
        pp=[0,findgen(n_elements(mode)-1)]        
        temp=mode-mode[pp]
        pp=where(temp gt 0)
        if cc ne 0 then dat.quality_flag[pp] = dat.quality_flag[pp] or bit7mask



        ;;*******************************************************
        ;;Bit 8  - LPW Sweep Interference
        ;;
        ;;NOTES:
        ;;    - LPW sweeps interfering with data:
        ;;      - Date lt 2014-11-20 for all orbits
        ;;      - Date gt 2014-11-20 and date lt 2015-01-07 for odd orbits
        ;;    - The LPW interference should only apply to 'conic' (2)
        ;;      and 'ram' (1) modes on the identified orbits,
        ;;      i.e. mode less than 3 
        bit8mask=2^8

        orb_num_new=fix(interpol(orb_num,orb_time,time))
        stop
        date1=time_double('2014-11-20')
        date2=time_double('2015-01-07')
        pp1=where(time lt date1 and $
                  mode lt 3,cc1)
        pp2=where(time ge date1 and $
                  time lt date2 and $
                  orb_num_new mod 12 eq 1 and $ ;odd orbits 
                  mode lt 3,cc2)
        if cc1 ne 0 then dat.quality_flag[pp1] = dat.quality_flag[pp1] or bit8mask


        ;;*******************************************************
        ;;Bit 9  - High Background - INTERPOL!!!!
        bit9mask=2^9
        if apid[api] eq 'da' then begin
           pp=where(dat.rates le 1000.,cc)
           if cc ne 0 then begin
              dat.quality_flag[pp] = dat.quality_flag[pp] or bit9mask
           endif
        endif



        ;;*******************************************************
        ;;Bit 10 - Missing Background
        ;;
        ;; !!! Default is set to 1 until these values are calculated !!!
        bit10mask=2^10
        dat.quality_flag = dat.quality_flag or bit10mask



        ;;*******************************************************
        ;;Bit 11 - Missing Spacecraft Potential
        ;;
        ;; !!! Default is set to 1 until these values are calculated !!!
        bit11mask=2^11
        dat.quality_flag = dat.quality_flag or bit11mask



        ;;*******************************************************
        ;;Bit 12 - Extra
        ;;
        ;; !!! Default is set to 1 until these values are calculated !!!
        bit12mask=2^12
        dat.quality_flag = dat.quality_flag or bit12mask


        ;-----------------------------------------------
        ;Replace original structure with updated verison
        temp=execute("mvn_"+apid[api]+"_dat.quality_flag=dat.quality_flag")

     endif
  endfor


end
