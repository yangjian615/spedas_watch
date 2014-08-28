;+
;Procedure: THM_LOAD_MOM
;
;Purpose:  Loads THEMIS moments data
;
;keywords:
;  probe = Probe name. The default is 'all', i.e., load all available probes.
;          This can be an array of strings, e.g., ['a', 'b'] or a
;          single string delimited by spaces, e.g., 'a b'
;  datatype = The type of data to be loaded, for this case, there is only
;          one option, the default value of 'mom', so this is a
;          placeholder should there be more that one data type. 'all'
;          can be passed in also, to get all variables.
;  TRANGE= (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded
;  level = the level of the data, the default is 'l1', or level-1
;          data. A string (e.g., 'l2') or an integer can be used. 'all'
;          can be passed in also, to get all levels.
;  coord = (optional) String denoting coordinates system to transform 
;          valid 3-vectors into (e.g. 'gsm').
;  CDF_DATA: named variable in which to return cdf data structure: only works
;          for a single spacecraft and datafile name.
;  VARNAMES: names of variables to load from cdf: default is all.
;  /GET_SUPPORT_DATA: load support_data variables as well as data variables
;                      into tplot variables.
;  /DOWNLOADONLY: download file but don't read it.
;  /valid_names, if set, then this routine will return the valid probe, datatype
;          and/or level options in named variables supplied as
;          arguments to the corresponding keywords.
;  files   named variable for output of pathnames of local files.
;          WARNING: performing operations on the file paths returned by this
;          keyword will break abstraction.  This can decrease the maintainability
;          of code based upon thm_load_mom.
;  /VERBOSE  set to output some useful info
;  raw     if set, then load raw data, without calibrating
;  type    added for compatibility with other THM_LOAD routines, if
;          set to 'raw', then load raw data with no calibration,
;          otherwise the default is to load calibrated data.
;  /NO_TIME_CLIP: Disables time clipping, which is the default
;  /dead_time_correct: If set, then calculate dead time correction
;                      based on ESA moments, this is the default
;                      for L2 input
;  /no_dead_time_correct: If set, do not calculate a dead time
;                         correction based on ESA ground-based
;                         moments, this is the default for L1
;                         data. If both the no_dead and dead
;                         keywords are set, then NO correction is
;                         applied.

;Example:
;   thm_load_mom,/get_suppport_data,probe=['a', 'b']
;Notes:
;  Written by Davin Larson Jan 2007.
;  Updated keywords KRB Feb 2007
;  If you aren't getting data and can't figure out why try
;  increasing your debug output level using:
;  'dprint,setdebug=3'
;  
;  New calibrations for ESA moments solar wind mode and non-solar wind
;  mode added Jul 23,2010 by pcruce (under Jim McFadden's direction.)
;  Detailed descriptions of methods in code.  These updated calibrations correct
;  most of the discrepancy between ground and on-board moments.
;  Some uncorrectable difference remains because on-board calculations
;  don't account for variation in energy sweep, different spacecraft
;  potential, and efficiency.
;
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2014-02-14 11:15:18 -0800 (Fri, 14 Feb 2014) $
; $LastChangedRevision: 14380 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/moments/thm_load_mom.pro $
;-

pro thm_clip_moment, trange, tn_pre_proc

; make sure tplot_vars created in post_procs get added to list
tn_post_proc = tnames()
if ~array_equal(tn_pre_proc, '') then begin

  ; make ssl_set_intersection doesn't get scalar inputs
  if n_elements(tn_pre_proc) eq 1 then tn_pre_proc=[tn_pre_proc]
  if n_elements(tn_post_proc) eq 1 then tn_post_proc=[tn_post_proc]

  post_proc_names = ssl_set_complement(tn_pre_proc, tn_post_proc)
endif

  if size(post_proc_names, /type) eq 7 then tplotnames = post_proc_names else tplotnames = tn_post_proc

; clip data to requested trange
If (keyword_set(trange) && n_elements(trange) Eq 2) $
  Then tr = timerange(trange) $
  else tr = timerange()
      
for i=0,n_elements(tplotnames)-1 do begin
  if tnames(tplotnames[i]) eq '' then continue
  time_clip, tplotnames[i], min(tr), max(tr), /replace, error=tr_err
  if tr_err then del_data, tplotnames[i]
endfor

end


;Helper function to perform coordinate transforms on valid moments data
pro thm_transform_moment, coord, quantity, trange=trange, probe=probe, $ 
                          prefix=prefix, suffix=suffix, $
                          state_loaded=state_loaded

    compile_opt idl2

  ;only transform valid 3-vectors
  q = quantity[0] eq '*' ? ['flux','eflux','velocity']:quantity
  types = where( stregex(q, '(flux|eflux|velocity)',/bool) eq 1, ct)

  if ct gt 0 then begin

    ;get tplot names
    tplotnames = tnames()

    ;search for applicaple variables 
    searchstring = '('+strjoin( prefix+q[types]+suffix,'|')+')'
    valid = where( stregex(tplotnames, searchstring,/bool) eq 1, ct)

    ;load state data now
    if ~keyword_set(state_loaded) then begin
      thm_load_state, probe=probe, /get_support_data, trange=trange
    endif

    cotrans_names = tplotnames[valid]
    thm_cotrans, cotrans_names, out_coord = coord, $
                 use_spinaxis_correction=1, use_spinphase_correction=1

  endif

end



pro thm_store_moment,time,dens,flux,mflux,eflux,mag,prefix = prefix, suffix=sfx,mass=mass, $
        raw=raw, quantity=quantity, $
        probe=probe,use_eclipse_corrections=use_eclipse_corrections

if use_eclipse_corrections GT 0 then begin
   ; Rotate vector quantities from pseudo-DSL (which drifts during eclipses) 
   ; to true DSL
                     
   ; Make sure spin model data is loaded.
   thm_autoload_spinmodel,probe=probe,trange=minmax(time)

   ; Retrieve eclipse delta_phi values
    smp=spinmodel_get_ptr(probe,use_eclipse_corrections=use_eclipse_corrections)
    spinmodel_interp_t,model=smp,time=time,eclipse_delta_phi=delta_phi

    edp_idx=where(delta_phi NE 0.0, edp_count)
    if (edp_count NE 0) then begin
       dprint,"Nonzero eclipse delta_phi corrections found."
       correct_delta_phi_vector,delta_phi=delta_phi,xyz_in=flux 
       correct_delta_phi_vector,delta_phi=delta_phi,xyz_in=eflux 
       correct_delta_phi_tensor,tens=mflux,delta_phi=delta_phi
    endif
endif

for j=0,n_elements(quantity)-1 do begin
  
  case quantity[j] of
    'density': store_data,prefix+'density'+sfx, data={x:time, y:dens}, dlim={ysubtitle:'[#/cm3]',data_att:{units:'#/cm3'}}
    'flux': store_data,prefix+'flux'+sfx, data={x:time, y:flux}, $
                     dlim={colors:'bgr',ysubtitle:'[#/cm2/s]',$
                     data_att:{units:'#/cm2/s',coord_sys:'dsl'}}
    'mftens': store_data,prefix+'mftens'+sfx, data={x:time, y:mflux},dlim={colors:'bgrmcy',ysubtitle:'[eV/cm3]',data_att:{units:'eV/cm3',coord_sys:'dsl'}}
    'eflux': store_data,prefix+'eflux'+sfx, data={x:time, y:eflux}  ,dlim={colors:'bgr',ysubtitle:'[eV/cm2/s]',data_att:{units:'eV/cm2/s',coord_sys:'dsl'}}
    '*': begin
      store_data,prefix+'density'+sfx, data={x:time, y:dens}, dlim={ysubtitle:'[#/cm3]',data_att:{units:'#/cm3'}}
      store_data,prefix+'flux'+sfx, data={x:time, y:flux}     ,dlim={colors:'bgr',ysubtitle:'[#/s/cm2]',data_att:{units:'#/s/cm2',coord_sys:'dsl'}}
      store_data,prefix+'mftens'+sfx, data={x:time, y:mflux},dlim={colors:'bgrmcy',ysubtitle:'[eV/cm3]',data_att:{units:'eV/cm3',coord_sys:'dsl'}}
      store_data,prefix+'eflux'+sfx, data={x:time, y:eflux}  ,dlim={colors:'bgr',ysubtitle:'[eV/cm2/s]',data_att:{units:'eV/cm2/s',coord_sys:'dsl'}}
    end
    else:
  endcase
  
  if not keyword_set(raw) then begin

    vel = flux/[dens,dens,dens]/1e5
    if quantity[j] eq 'velocity' || quantity[j] eq '*' then begin
      store_data,prefix+'velocity'+sfx, data={x:time,  y:vel }, $
        dlim={colors:'bgrmcy',labels:['Vx','Vy','Vz'],ysubtitle:'[km/s]',data_att:{coord_sys:'dsl'}}
    endif
    
    pressure = mflux
    pressure[*,0] -=  mass * flux[*,0]*flux[*,0]/dens/1e10
    pressure[*,1] -=  mass * flux[*,1]*flux[*,1]/dens/1e10
    pressure[*,2] -=  mass * flux[*,2]*flux[*,2]/dens/1e5/1e5
    pressure[*,3] -=  mass * flux[*,0]*flux[*,1]/dens/1e5/1e5
    pressure[*,4] -=  mass * flux[*,0]*flux[*,2]/dens/1e5/1e5
    pressure[*,5] -=  mass * flux[*,1]*flux[*,2]/dens/1e5/1e5

    if quantity[j] eq 'ptens' || quantity[j] eq '*' then begin
      press_labels=['Pxx','Pyy','Pzz','Pxy','Pxz','Pyz']
      store_data,prefix+'ptens'+sfx, data={x:time, y:pressure }, $
        dlim={colors:'bgrmcy',labels:press_labels,constant:0.,ysubtitle:'[eV/cc]'}
    endif

    ptot = total(pressure[*,0:2],2)/3
    if quantity[j] eq 'ptot' || quantity[j] eq '*' then $
      store_data,prefix+'ptot'+sfx, data={x:time, y:ptot } ;,dlim={colors:'bgrmcy',labels:press_labels}
  endif
  if keyword_set(mag) then begin
     map3x3 = [[0,3,4],[3,1,5],[4,5,2]]
     mapt   = [0,4,8,1,2,5]
     n = n_elements(time)
     ptens_mag = fltarr(n,6)
     vel_mag   = fltarr(n,3)
     vxz = [1,0,0.]
     for i=0L,n-1 do begin   ; this could easily be speeded up, but it's fast enough now.
  ;       vxz = reform(flux[i,*])
         rot = rot_mat(reform(mag[i,*]),vxz)
         pt = reform(pressure[i,map3x3],3,3)
         magpt3x3 = invert(rot) # (pt # rot)
         ptens_mag[i,*] = magpt3x3[mapt]
         vm = reform(vel[i,*]) # rot
         vel_mag[i,*] = vm
     endfor
     store_data,prefix+'velocity_mag',data={x:time,y:vel_mag} ,dlim={colors:'bgr',labels:['Vperp1','Vperp2','Vpar'],ysubtitle:'[km/s]',data_att:{units:'km/s',coord_sys:'mfa'}}
     store_data,prefix+'ptens_mag',data={x:time,y:ptens_mag},dlim={colors:'bgrmcy',labels:['Pperp1','Pperp2','Ppar','','',''],ysubtitle:'[eV/cc]',data_att:{units:'eV/cm3'}}
     store_data,prefix+'t3_mag',data={x:time,y:ptens_mag[*,0:2]/[dens,dens,dens]},dlim={colors:'bgrmcy',labels:['Tperp1','Tperp2','Tpar'],ysubtitle:'[eV]',data_att:{units:'eV'}}
     store_data,prefix+'mag',data={x:time,y:mag},dlim={colors:'bgr',ysubtitle:'[nT]'}
  endif

endfor ; loop over quantity

end





pro thm_load_mom_cal_array,time,momraw,scpotraw,qf,shft,$
  iesa_sweep, iesa_sweep_time, eesa_sweep, eesa_sweep_time, $ ;added sweep variables, 1-mar-2010, jmm
  iesa_solarwind_flag, eesa_solarwind_flag, $                 ;solarwind_flag variables don't have the same time array as sweep, 26-jul-2010
  iesa_config, iesa_config_time,eesa_config, eesa_config_time, $
  isst_config, isst_config_time,esst_config, esst_config_time, $
  iesa_solarwind_time, eesa_solarwind_time, $
  probe=probe,caldata=caldata, coord=coord, $
  verbose=verbose,raw=raw,comptest=comptest, datatype=datatype, $
  use_eclipse_corrections=use_eclipse_corrections, suffix = suffix

  ;each instrument has its own cal file,23-jul-2009
  ;reverted to pre-July 2009 version to avoid conflicts with
  ;thm_load_esa_pot routine, which also makes a correction, jmm,
  ;2010-02-08.
  ;2010-06-23 Now uses new file that contains updated corrections and solar wind mode corrections, pcruce
;Uses text calibration file instead of IDL save file,jmm,4-oct-2010
  caldata = thm_read_mom_cal_file(cal_file = cal_file,probe=probe)
  dprint,dlevel=2,verbose=!themis.verbose,'THEMIS moment calibration file: ',cal_file
  dprint,dlevel=4,verbose=!themis.verbose,caldata,phelp=3
  dprint,dlevel=3,phelp=3,qf
  dprint,dlevel=3,phelp=3,shft
  
  if keyword_set(raw) then begin
     sfx='_raw'
     caldata.mom_scale = 1.
     caldata.scpot_scale[*] = 1.
   endif else if(keyword_set(suffix)) then begin ;jmm, 9-aug-2011
    sfx = suffix
  endif else sfx = ''
  if keyword_set(comptest) then begin
     sfx+='_cmptest'
  ;   momraw = momraw / 2l^16
  ;   momraw = momraw * 2l^16
     momraw = momraw and 'ffff0000'xl
     momraw = momraw or  '00008000'xl
  endif
  
  one = replicate(1.d,n_elements(time))
  bad = where((qf and 'c'x) ne 0,nbad)
  if nbad gt 0 then one[bad] = !values.f_nan

    nt = n_elements(time)
    thx = 'th'+probe
    instrs= 'p'+['ei','ee','si','se'] +'m'
;    sh = shft
    me = 510998.918d/299792d^2
    mi = 1836*me
    mass=[mi,me,mi,me]
    s2_cluge = [3,0,3,0]
    totmom_flag = 1 &&  ~keyword_set(raw)
    if keyword_set(totmom_flag) then begin
         n_e_tot = 0
         nv_e_tot = 0
         nvv_e_tot = 0
         nvvv_e_tot = 0
         n_i_tot = 0
         nv_i_tot = 0
         nvv_i_tot = 0
         nvvv_i_tot = 0
    endif

     ; get mag data at same time steps
    mag = data_cut(thx+'_fgs',time)  ; Note:  'thx_fgs' must be in spacecraft coordinates!
    if(n_elements(mag) eq 1 && mag[0] eq 0) then mag = data_cut(thx+'_fgs_dsl',time) ;allow L2 fgs data

    ;reform calibration parameters so that it is easy to switch between solar-wind and non-solar wind mode using vectorized calculations.
    cal_params = dblarr([dimen(caldata.mom_scale),2])
    cal_params[*,*,0] = caldata.mom_scale
    cal_params[*,*,1] = caldata.mom_scale_sw1
     
    for i=0,3 do begin
;       s2 = sh and 7
;       sh = sh / 16
        
       ;truncation and shift based compression is used on-board.  Bitpacked values in the shft variable indicate how much
       ;shift needs to be applied to each moment type (iESA,eESA,iSST,eSST)
       ;each shift field is 3 bits, indicating a shift of 1-8 bits.  
       ;bits 2-0 = eSST shift
       ;bits 6-4 = iSST shift
       ;bits 10-8 = eESA shift
       ;bits 14-12 = iESA shift
       
       ;This unpacks the shift field.
       s2 = ishft(shft,(i-3)*4) and 7
              
       instr = instrs[i]     
       ion = (i and 1) eq 0

       if (i eq 2) || (i eq 3) then begin   ; Special treatment for SST attenuators
       
          geom = replicate(!values.f_nan,n_elements(time))
          geom[*] = 1.
          w_open = where( (qf and '0f00'x) eq '0A00'x , nw_open )       
          if nw_open gt 0 then geom[w_open] = 1.
          
          w_clsd = where( (qf and '0f00'x) eq '0500'x , nw_clsd )
          ;if nw_clsd gt 0 then geom[w_clsd] = 1/128. ;old code
          ;changing attenuator factor to 1/64.
          if nw_clsd gt 0 then geom[w_clsd] = 1./64 ;new code
;          printdat,instr,geom

          ;Note, one attenuator on themis D broke during early April and was in ambiguous state for ~3 months.  Data during this interval is treated as missing.
          if (nw_open + nw_clsd) ne n_elements(geom) then begin
            dprint,'Attenuator flags are ambiguous for ' + strtrim(n_elements(geom) - nw_open - nw_clsd,2) + ' samples.'
          endif

       endif else begin
          esa_cal = get_thm_esa_cal(time= time,sc=probe,ion=ion)
          geom= esa_cal.rel_gf * esa_cal.geom_factor / 0.00153000 * 1.5  ; 1.5 fudge factor
       endelse
;       s2=s2_cluge[i]
;       s2 = 0
       if keyword_set(raw) then s2=0
       dprint,dlevel=3,instrs[i],'  shift=',s2[0]
       
       ;caldata.mom_scale factors for ESA determined by comparing data to ground processed moments when not in solar wind mode.
       ;Note that efficiency, dead time, and energy sweep variation corrections are only performed on ground.
       ;Also a different spacecraft potential will be used.
       ;This means there will be some discrepancy between on-board and ground based moments that is unresolved with this model.
       ;To determine these factors, ground corrections that are not done on-board were turned off, and on-board sc_pot was used. 
       ;The dates were determined by comparing moments from plasma sheath with the following dates/probes:
       ;THB 2008-11-30/00:00:00 16 hours 
       ;THB 2008-12-02/04:00:00 20 hours 
       ;THB 2008-12-06/00:00:00 24 hours 
       ;THB 2008-12-10/08:00:00 16 hours 
       ;THB 2009-04-10/04:00:00 20 hours
       ;THB 2009-04-22/00:00:00 24 hours (Note that the peem component contains uncorrectable digitization on this day that make fit for this component invalid.) 
       ;THB 2009-04-25/00:00:00 24 hours 
       ;THC 2007-11-25/02:00:00 16 hours 
       ;THC 2008-11-26/08:00:00 16 hours (Note this date contains a few large glitches(spikes) that need to be removed before you can get a good fit)
       ;THC 2008-11-28/08:00:00 16 hours
       
       ;Efficiency corrections cause larger discrepancies in ions than electrons.  These can be as large as 5% at high ion velocities(400 km/s)
       
       ;caldata.mom_scale_sw1 factors for ESA determined by comparing data to ground processed moments when in solar wind mode.
       ;As above, ground-only corrections were turned off, and on-board scpot was used.
       ;Also,note that electron eflux results can be erratic because of intermittent digitization error.
       ;Dates used follow:
       ;THB 2008-08-11/00:00:00 24 hours   
       ;THB 2008-08-14/00:00:00 24 hours
       ;THB 2008-08-15/00:00:00 24 hours
       ;THB 2008-08-18/00:00:00 24 hours
       ;THB 2008-08-19/00:00:00 24 hours
      
       ;select appropriate parameters for solarwind/non-solar wind if correct inputs available, default is to use only non-solar wind parameters
       if i eq 0 && ptr_valid(iesa_solarwind_flag) && ptr_valid(iesa_solarwind_time) then begin 
         ;times don't always match exactly.  This interpolates to matching time grids.  Flag is boolean, so intermediate values are rounded.
         sw_flags = 0 > round(interpol(*iesa_solarwind_flag,*iesa_solarwind_time,time)) < 1
       endif else if i eq 1 && ptr_valid(eesa_solarwind_flag) && ptr_valid(eesa_solarwind_time) then begin
         ;same intepolation as above, but for electrons
         sw_flags = 0 > round(interpol(*eesa_solarwind_flag,*eesa_solarwind_time,time)) < 1
       endif else begin
         sw_flags = dblarr((dimen(momraw))[0])
       endelse

       dens  = ulong(momraw[*,0,i]) * cal_params[0,i,sw_flags] * one * 2.^s2 / geom
       flux = fltarr(nt,3)
       for m = 0,2 do flux[*,m] = momraw[*,1+m,i]  * cal_params[1+m,i,sw_flags] * one * 2.^s2 / geom ;* 1e5
       mflux = fltarr(nt,6)
       for m = 0,5 do mflux[*,m] = momraw[*,4+m,i]  * cal_params[4+m,i,sw_flags] * one * 2.^s2  /geom  ; * 1e2; * mass[i]
       eflux = fltarr(nt,3)
        
       ;1e5 is unit conversion from (eV/cm^2)*(km/sec) to eV/cm2/sec
       for m = 0,2 do eflux[*,m] = momraw[*,10+m,i]  * cal_params[10+m,i,sw_flags] * one * 2.^s2  /geom * 1e5; * 1e1 ; * mass[i]   
       
       if not keyword_set(raw) then begin
          if keyword_set(totmom_flag) then begin
             if i and 1 eq 1 then begin   ; electrons
                  n_e_tot     += dens
                  nv_e_tot    += flux
                  nvv_e_tot   += mflux
                  nvvv_e_tot  += eflux
             endif else begin             ; ions
                  n_i_tot     += dens
                  nv_i_tot    += flux
                  nvv_i_tot   += mflux
                  nvvv_i_tot  += eflux
             endelse
          endif
;          press_labels=['Pxx','Pyy','Pzz','Pxy','Pxz','Pyz']
;          store_data,thx+'_'+instr+'_velocity'+sfx, data={x:time,  y:flux/[dens,dens,dens]/1e5 } ,dlim={colors:'bgrmcy',labels:['Vx','Vy','Vz'],ysubtitle:'km/s'}
;               pressure = mflux
;               pressure[*,0] -=  mass[i] * flux[*,0]*flux[*,0]/dens/1e10
;               pressure[*,1] -=  mass[i] * flux[*,1]*flux[*,1]/dens/1e10
;               pressure[*,2] -=  mass[i] * flux[*,2]*flux[*,2]/dens/1e5/1e5
;               pressure[*,3] -=  mass[i] * flux[*,0]*flux[*,1]/dens/1e5/1e5
;               pressure[*,4] -=  mass[i] * flux[*,0]*flux[*,2]/dens/1e5/1e5
;               pressure[*,5] -=  mass[i] * flux[*,1]*flux[*,2]/dens/1e5 /1e5
;          store_data,thx+'_'+instr+'_press'+sfx, data =    {x:time,  y:pressure } ,dlim={colors:'bgrmcy',labels:press_labels}
       endif

       ;check if current instrument is requested, continue if not
       if keyword_set(datatype) then begin
         dt_ind = where(strmid(datatype,0,4) eq instr, n)
         if (n_elements(n) gt 0) &&((n eq 0)) then continue
       endif
       
       ;extract requested quantities
       if(n_elements(n) gt 0) then begin
       quantity = strarr(n)
         for j=0,n-1 do begin
           qu = (strsplit(datatype[dt_ind[j]], '_', /extract))
           if(n_elements(qu) gt 1) then quantity[j] = qu[1] else quantity[j] = '*';jmm,1-feb-2010
;           quantity[j] = (strsplit(datatype[dt_ind[j]], '_', /extract))[1]
         endfor
         star = where(quantity eq '*', nstar)
         if(nstar gt 0) then quantity = '*'
       endif else quantity = '*'

       thm_store_moment,time,dens,flux,mflux,eflux,mag,prefix = thx+'_'+instr+'_', $
           suffix=sfx,mass=mass[i],raw=raw, quantity=quantity, $
           probe=probe, use_eclipse_corrections=use_eclipse_corrections

       if keyword_set(coord) then begin
         thm_transform_moment, coord, quantity, probe=probe, trange=trange, $
                               prefix=thx+'_'+instr+'_',suffix=sfx, $
                               state_loaded=state_loaded
       endif

    endfor
    if 1 then begin
       if not keyword_set(raw) && totmom_flag then begin
          thm_store_moment,time,n_i_tot,nv_i_tot,nvv_i_tot,nvvv_i_tot,mag,$
            prefix = thx+'_'+'ptim_', suffix=sfx,mass=mass[0],raw=raw, quantity='*',$
            probe=probe, use_eclipse_corrections=use_eclipse_corrections
              
          thm_store_moment,time,n_e_tot,nv_e_tot,nvv_e_tot,nvvv_e_tot,mag,$
            prefix = thx+'_'+'ptem_', suffix=sfx,mass=mass[1],raw=raw, quantity='*',$
            probe=probe, use_eclipse_corrections=use_eclipse_corrections
       endif

    endif

;time-dependent scpot scaling, jmm, 23-jul-2009,was removed on 8-feb-2010, jmm

;now uses fixed scpot scaling
    scpot = scpotraw*caldata.scpot_scale

    if keyword_set(datatype) then begin
      if where(strmid(datatype,0,8) eq 'pxxm_pot') ne -1 then $
        store_data,thx+'_pxxm_pot'+sfx,data={x:time,  y:scpot },dlimit={ysubtitle:'[Volts]'}
      if where(strmid(datatype,0,7) eq 'pxxm_qf') ne -1 then $
        store_data,thx+'_pxxm_qf'+sfx,data={x:time, y:qf}, dlimit={tplot_routine:'bitplot'}
      if where(strmid(datatype,0,9) eq 'pxxm_shft') ne -1 then $
        store_data,thx+'_pxxm_shft'+sfx,data={x:time, y:shft}, dlimit={tplot_routine:'bitplot'}
    endif else begin
      store_data,thx+'_pxxm_pot'+sfx,data={x:time,  y:scpot },dlimit={ysubtitle:'[Volts]'}
      store_data,thx+'_pxxm_qf'+sfx,data={x:time, y:qf}, dlimit={tplot_routine:'bitplot'}
      store_data,thx+'_pxxm_shft'+sfx,data={x:time, y:shft}, dlimit={tplot_routine:'bitplot'}
    endelse

;ESA sweep mode variables, 1-mar-2010, jmm
    if(ptr_valid(iesa_sweep) && ptr_valid(iesa_sweep_time)) then $
      store_data, thx+'_iesa_sweep'+sfx, data = {x:*iesa_sweep_time, y:*iesa_sweep}, dlimit={tplot_routine:'bitplot'}
    if(ptr_valid(eesa_sweep) && ptr_valid(eesa_sweep_time)) then $
      store_data, thx+'_eesa_sweep'+sfx, data = {x:*eesa_sweep_time, y:*eesa_sweep}, dlimit={tplot_routine:'bitplot'}

;ESA solar wind mode variables, 1-mar-2010, jmm
    if(ptr_valid(iesa_solarwind_flag) && ptr_valid(iesa_solarwind_time)) then $
      store_data, thx+'_iesa_solarwind_flag'+sfx, data = {x:*iesa_solarwind_time, y:*iesa_solarwind_flag}
    if(ptr_valid(eesa_solarwind_flag) && ptr_valid(eesa_solarwind_time)) then $
      store_data, thx+'_eesa_solarwind_flag'+sfx, data = {x:*eesa_solarwind_time, y:*eesa_solarwind_flag}

;ESA configuration
    if(ptr_valid(iesa_config) && ptr_valid(iesa_config_time)) then $
      store_data, thx+'_iesa_config'+sfx, data = {x:*iesa_config_time, y:*iesa_config}
    if(ptr_valid(eesa_config) && ptr_valid(eesa_config_time)) then $
      store_data, thx+'_eesa_config'+sfx, data = {x:*eesa_config_time, y:*eesa_config}
    
;SST configuration
    if(ptr_valid(isst_config) && ptr_valid(isst_config_time)) then $
      store_data, thx+'_isst_config'+sfx, data = {x:*isst_config_time, y:*isst_config}
    if(ptr_valid(esst_config) && ptr_valid(esst_config_time)) then $
      store_data, thx+'_esst_config'+sfx, data = {x:*esst_config_time, y:*esst_config}
      
end


;+
; Themis moment calibration routine.
; Author: Davin Larson
;-
pro thm_load_mom_cal,probes=probes, create=create, verbose=verbose

if not keyword_set(probes) then probes = ['a','b','c','d','e']

for s=0,n_elements(probes)-1 do begin
  thx = 'th'+probes(s)
  get_data,thx+'_mom_raw',ptr=p
  get_data,thx+'_mom_pot_raw',ptr=pot
  get_data,thx+'_mom_qf_raw',ptr

  if keyword_set(p) then begin
    thm_load_mom_cal_array,*p.x,*p.y,0 ,probe=probe

    dprint,dlevel=4,'Finished with cal on '+thx
  endif


endfor


end


pro thm_load_mom, probe = probe, datatype = datatype, trange = trange, all = all, $
                  level = level, verbose = verbose, downloadonly = downloadonly, $
                  varnames = varnames, valid_names = valid_names, raw = raw, $
                  comptest = comptest, suffix = suffix, coord = coord, $
                  source_options = source, type = type, $
                  progobj = progobj, files = files, no_time_clip = no_time_clip, $
                  true_dsl = true_dsl, use_eclipse_corrections = use_eclipse_corrections, $
                  no_dead_time_correct = no_dead_time_correct, dead_time_correct = dead_time_correct

tn_pre_proc = tnames()

thm_init
thm_load_esa_cal
  
vprobes = ['a','b','c','d','e']
vlevels = ['l1','l2']
deflevel = 'l1'   ; leave at level 1 until level 2 is validated.

if n_elements(probe) eq 1 then if probe eq 'f' then vprobes=[vprobes,'f']


if not keyword_set(probe) then probe=vprobes
probes = thm_check_valid_name(strlowcase(probe), vprobes, /include_all)

lvl = thm_valid_input(level,'Level',vinputs=strjoin(vlevels, ' '), $
                      definput=deflevel, format="('l', I1)", verbose=0)
if lvl eq '' then return

if lvl eq 'l2' and keyword_set(type) then begin
   dprint,dlevel=0,"Type keyword not valid for level 2 data."
   return
endif

if keyword_set(type) && ~keyword_set(raw) then begin ;if type is set to 'raw' then set the raw keyword
  if strcompress(/remove_all, strlowcase(type)) Eq 'raw' then raw = 1b else raw = 0b
endif

if arg_present(files) then begin ;needed because files is a variable used internally
  file_list_flag = 1
endif else begin
  file_list_flag = 0
endelse

;Reads Level 2 data files
if (lvl eq 'l2') or (lvl eq 'l1' and keyword_set(valid_names)) then begin
  thm_load_mom_l2, probe = probe, datatype = datatype, $
    trange = trange, level = lvl, verbose = verbose, $
    downloadonly = downloadonly, valid_names = valid_names, $
    source_options = source_options, progobj = progobj, files = files, $
    suffix = suffix, no_time_clip = no_time_clip, $
    no_dead_time_correct = no_dead_time_correct, $
    dead_time_correct = dead_time_correct
;  If(~keyword_set(no_time_clip)) Then thm_clip_moment, trange, tn_pre_proc
  return
endif

if keyword_set(valid_names) then begin
   probe = vprobes
   dprint, string(strjoin(probe, ','), $
                          format = '( "Valid probes:",X,A,".")')
   datatype = vdatatypes
   dprint, string(strjoin(datatype, ','), $
                          format = '( "Valid '+lvl+' datatypes:",X,A,".")')

   level = vlevels
   dprint, string(strjoin(level, ','), format = '( "Valid levels:",X,A,".")')
   return
endif

if keyword_set(datatype) then begin
  datatype=strlowcase(datatype)   ; Otherwise upper case datatypes will fail.
endif

if keyword_set(datatype) && n_elements(datatype) eq 1 then begin
  dtest = strlowcase(strcompress(/remove_all, datatype))
  if(dtest eq '*' or dtest eq 'all' or dtest eq 'mom') then datatype = 0 ;insures backward compatibility,jmm,2-feb-2010
endif

if not keyword_set(source) then source = !themis
if not keyword_set(verbose) then verbose = source.verbose

; JWL 2012-08-01
; In TDAS 7.0, it was necessary to specify both true_dsl=1 and
; use_eclipse_corrections=1 to use the fully corrected eclipse
; spin model.

; true_dsl is no longer necessary, and now use_eclipse_corrections=2
; is the setting for full eclipse corrections.  If true_dsl is
; specified, warn the user, assume that full corrections are
; being requested, and set use_eclipse_corrections=2 here, overriding
; that keyword argument.

if (n_elements(true_dsl) GT 0) then begin
   dprint,dlevel=1,'true_dsl keyword no longer required.'
   dprint,dlevel=1,'Setting use_eclipse_corrections=2 to use fully corrected eclipse spin model.'
   use_eclipse_corrections=2
endif


; use_eclipse_corrections: use eclipse spin model as the reference spin phase
; Defaults to 0 for now.

if n_elements(use_eclipse_corrections) LT 1 then begin
   use_eclipse_corrections=0
   dprint,dlevel=2,'Defaulting to use_eclipse_corrections=0 (no eclipse spin model corrections).'
endif

; Warn user if partial eclipse corrections requested -- not recommended
; except for SOC processing.

if (use_eclipse_corrections EQ 1) then begin
   dprint,dlevel=1,'Caution: partial eclipse corrections requested. use_eclipse_corrections=2 for full corrections (when available).'
endif


addmaster=0

for s=0,n_elements(probes)-1 do begin
     thx = 'th'+ probes[s]

     pathformat = thx+'/'+lvl+'/mom/YYYY/'+thx+'_'+lvl+'_mom_YYYYMMDD_v01.cdf'
     dprint,dlevel=3,'pathformat: ',pathformat,verbose=verbose

     relpathnames = file_dailynames(file_format=pathformat,trange=trange,addmaster=addmaster)
     files = file_retrieve(relpathnames, _extra=source)
     
     if file_list_flag then begin ;concatenate the list
      if n_elements(file_list) eq 0 then begin
        file_list = [files]
      endif else begin
        file_list = [file_list,files]
      endelse
    endif

     if keyword_set(downloadonly) then continue

     suf=''
     suf='_raw'
     if 1 then begin
     cdfi = cdf_load_vars(files,varnames=varnames2,verbose=verbose,/all);,/no_attributes)
     if not keyword_set(cdfi) then continue
     vns = cdfi.vars.name
     time = cdfi.vars[where(vns eq thx+'_mom_time')].dataptr
     mom  = cdfi.vars[where(vns eq thx+'_mom')].dataptr
     qf   = cdfi.vars[where(vns eq thx+'_mom_qf')].dataptr
     pot  = cdfi.vars[where(vns eq thx+'_mom_pot')].dataptr
     hed      = cdfi.vars[where(vns eq thx+'_mom_hed')].dataptr
     hed_time = cdfi.vars[where(vns eq thx+'_mom_hed_time')].dataptr
     iesa_sweep = cdfi.vars[where(vns eq thx+'_mom_iesa_sweep')].dataptr
     iesa_sweep_time = cdfi.vars[where(vns eq thx+'_mom_iesa_sweep_time')].dataptr
     eesa_sweep = cdfi.vars[where(vns eq thx+'_mom_eesa_sweep')].dataptr
     eesa_sweep_time = cdfi.vars[where(vns eq thx+'_mom_eesa_sweep_time')].dataptr
     iesa_solarwind_flag = cdfi.vars[where(vns eq thx+'_mom_iesa_solarwind_flag')].dataptr
     eesa_solarwind_flag = cdfi.vars[where(vns eq thx+'_mom_eesa_solarwind_flag')].dataptr
     iesa_solarwind_time = cdfi.vars[where(vns eq thx+'_mom_iesa_solarwind_flag_time')].dataptr
     eesa_solarwind_time = cdfi.vars[where(vns eq thx+'_mom_eesa_solarwind_flag_time')].dataptr
     iesa_config = cdfi.vars[where(vns eq thx+'_mom_iesa_config')].dataptr
     iesa_config_time = cdfi.vars[where(vns eq thx+'_mom_iesa_config_time')].dataptr
     eesa_config = cdfi.vars[where(vns eq thx+'_mom_eesa_config')].dataptr
     eesa_config_time = cdfi.vars[where(vns eq thx+'_mom_eesa_config_time')].dataptr 
     isst_config = cdfi.vars[where(vns eq thx+'_mom_isst_config')].dataptr
     isst_config_time = cdfi.vars[where(vns eq thx+'_mom_isst_config_time')].dataptr
     esst_config = cdfi.vars[where(vns eq thx+'_mom_esst_config')].dataptr
     esst_config_time = cdfi.vars[where(vns eq thx+'_mom_esst_config_time')].dataptr 
     
;quick fix for mismatches in solarwind flag times and sweep times,
;jmm, 30-jul-2010
     If(ptr_valid(eesa_sweep_time) && ptr_valid(eesa_solarwind_time)) Then Begin
       If(n_elements(*eesa_sweep_time) Ne n_elements(*eesa_solarwind_time)) Then Begin
         tsw = *eesa_solarwind_time
         x = where(tsw[1:*] Eq tsw[0:n_elements(tsw)-2])
         If(x[0] Ne -1) Then Begin
           fsw = *eesa_solarwind_flag
           ntsw = n_elements(tsw)
           keep_flag = bytarr(ntsw)+1b
;The times tsw[x] and tsw[x+1] are the same -- you want to discard the
;times for which fsw is zero, or better yet, simply discard
;duplicates and set the flag to 1 for the leftovers
           keep_flag[x] = 0b
           fsw[x+1] = 1
           ok = where(keep_flag Eq 1)
           If(ok[0] Ne -1) Then Begin
             tsw = tsw[ok] & fsw = fsw[ok]
             ptr_free, eesa_solarwind_time
             eesa_solarwind_time = ptr_new(temporary(tsw))
             ptr_free, eesa_solarwind_flag
             eesa_solarwind_flag = ptr_new(temporary(fsw))
           Endif Else dprint, 'No non-duplicate OK times for EESA SWflag'
         Endif Else dprint, 'Sweep time and SWflag time mismatch, but no duplicate times'
       Endif
     Endif
;check for valid data, jmm, 25-mar-2008
     if(ptr_valid(time) eq 0 or ptr_valid(mom) eq 0 $
       or ptr_valid(qf) eq 0 or ptr_valid(pot) eq 0 $
       or ptr_valid(hed) eq 0 or ptr_valid(hed_time) eq 0) then begin
           dprint,dlevel=1,'Invalid data found in file(s): ' + files,verbose=verbose
           dprint,dlevel=1,'Skipping probe.'      ,verbose=verbose
           continue
      endif

     shft_index = round(interp(findgen(n_elements(*hed_time)) ,*hed_time, *time))
     shft = (*hed)[*,14 ]+  256u*  (*hed)[*,15]
     shft = shft[shft_index]

     thm_load_mom_cal_array,*time,*mom,*pot,*qf,shft,$
       iesa_sweep,iesa_sweep_time,eesa_sweep,eesa_sweep_time, $
       iesa_solarwind_flag, eesa_solarwind_flag, probe = probes[s], $
       iesa_config, iesa_config_time, eesa_config, eesa_config_time,$
       isst_config, isst_config_time, esst_config, esst_config_time,$
       iesa_solarwind_time, eesa_solarwind_time, coord=coord, $
       raw = raw, verbose = verbose, comptest = comptest, datatype = datatype, $
       use_eclipse_corrections=use_eclipse_corrections, suffix = suffix

     tplot_ptrs = ptr_extract(tnames(/dataquant))
     unused_ptrs = ptr_extract(cdfi,except=tplot_ptrs)
     ptr_free,unused_ptrs

     endif else begin
        message," Don't do this!"

;     cdf2tplot,file=files,all=all,suffix=suf,verbose=verbose ,get_support_data=1 ;get_support_data    ; load data into tplot variables
;
;     get_data,thx+'_mom'+suf,ptr=p
;     get_data,thx+'_mom_pot'+suf,ptr=p_pot
;
;     options,thx+'_mom_qf'+suf,tplot_routine='bitplot'
;
;     get_data,thx+'_mom_hed'+suf,ptr=phed
;     if keyword_set(phed) then begin
;        store_data,thx+'_mom_CompCfg',data={x:phed.x, y:(*phed.y)[*,12] }, dlim={tplot_routine:'bitplot'}
;        store_data,thx+'_mom_covers',data={x:phed.x, y:(*phed.y)[*,13] }, dlim={tplot_routine:'bitplot'}
;        shft = (*phed.y)[*,14] + (*phed.y)[*,15]*256u
;        store_data,thx+'_mom_shift',data={x:phed.x, y:shft }, dlim={tplot_routine:'bitplot',colors:'r'}
;     endif
;     thm_load_mom_cal,probe=probes[s]

     endelse
;Apply dead time correction, if asked for
     If(keyword_set(dead_time_correct)) Then Begin
         If(~keyword_set(no_dead_time_correct)) Then thm_apply_esa_mom_dtc, probe = probes[s], $
           trange = trange, in_suffix = suffix
     Endif
endfor

if file_list_flag && n_elements(file_list) ne 0 then begin
  files=file_list
endif

If(~keyword_set(no_time_clip)) Then Begin
  If(keyword_set(trange)) Then thm_clip_moment, trange, tn_pre_proc $
  Else thm_clip_moment, timerange(/current), tn_pre_proc
Endif

end
