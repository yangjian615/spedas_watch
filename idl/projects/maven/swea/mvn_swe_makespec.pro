;+
;PROCEDURE:   mvn_swe_makespec
;PURPOSE:
;  Constructs ENGY data structure from raw data.
;
;USAGE:
;  mvn_swe_makespec
;
;INPUTS:
;
;KEYWORDS:
;
;       SUM:      Force sum mode for A4 and A5.  Not needed for EM or for FM post ATLO.
;                 Default = get mode from packet.
;
;       UNITS:    Convert data to these units.  Default = 'eflux'.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2015-05-18 14:43:14 -0700 (Mon, 18 May 2015) $
; $LastChangedRevision: 17641 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_makespec.pro $
;
;CREATED BY:    David L. Mitchell  03-29-14
;FILE: mvn_swe_makespec.pro
;-
pro mvn_swe_makespec, sum=sum, units=units

  @mvn_swe_com
  
  if not keyword_set(sum) then smode = 0 else smode = 1
  if (size(units,/type) ne 7) then units = 'eflux'

; Initialize the deflection scale factors, geometric factor, and MCP efficiency

  dsf = total(swe_hsk.dsf,1)/6.          ; unity when all the DSF's are unity
  gf = total(swe_gf[*,*,0],2)/16.        ; average over 16 anodes
  eff = total(swe_mcp_eff[*,*,0],2)/16.  ; average over 16 anodes

; SWEA SPEC survey data

  if (size(a4,/type) ne 8) then begin
    print,"No SPEC survey data."
  endif else begin
    npkt = n_elements(a4)         ; number of packets
    npts = 16L*npkt               ; 16 spectra per packet
    ones = replicate(1.,16)

    mvn_swe_engy = replicate(swe_engy_struct,npts)

    for i=0L,(npkt-1L) do begin
      delta_t = swe_dt[a4[i].period]*dindgen(16) + (1.95D/2D)  ; center time offset (sample mode)
      dt_arr0 = 16.*6.                                         ; 16 anode X 6 defl. (sample mode)
      if (a4[i].smode or smode) then begin
        delta_t = delta_t + (2D^a4[i].period - 1D)             ; center time offset (sum mode)
        dt_arr0 = dt_arr0*swe_dt[a4[i].period]/2.              ; # samples averaged (sum mode)
      endif

      j0 = i*16L
      for j=0,15 do begin
        tspec = a4[i].time + delta_t[j]

        dt = min(abs(tspec - swe_hsk.time),k)                       ; look for config. changes
        if (swe_active_chksum ne swe_chksum[k]) then begin
          mvn_swe_calib, chksum=swe_chksum[k]
          gf = total(swe_gf[*,*,0],2)/16.
          eff = total(swe_mcp_eff[*,*,0],2)/16.
        endif

        mvn_swe_engy[j0+j].chksum = swe_active_chksum                       ; sweep table
        mvn_swe_engy[j0+j].time = a4[i].time + delta_t[j]                   ; center time
        mvn_swe_engy[j0+j].met  = a4[i].met  + delta_t[j]                   ; center met
        mvn_swe_engy[j0+j].end_time = a4[i].time + delta_t[j] + delta_t[0]  ; end time
        mvn_swe_engy[j0+j].delta_t = swe_dt[a4[i].period]                   ; cadence
        mvn_swe_engy[j0+j].integ_t = swe_integ_t                            ; integration time
        mvn_swe_engy[j0+j].dt_arr = dt_arr0*dsf[k]                          ; # bins averaged

        mvn_swe_engy[j0+j].energy = swe_energy                      ; avg. over 6 deflections
        mvn_swe_engy[j0+j].denergy = swe_denergy                    ; avg. over 6 deflections

        mvn_swe_engy[j0+j].gf = gf                                  ; avg. over 16 anodes
        mvn_swe_engy[j0+j].eff = eff                                ; avg. over 16 anodes

        mvn_swe_engy[j0+j].data = a4[i].data[*,j]                   ; raw counts
        mvn_swe_engy[j0+j].var = a4[i].var[*,j]                     ; variance
      endfor
    endfor

; Correct for deadtime

    rate = mvn_swe_engy.data / (swe_integ_t * mvn_swe_engy.dt_arr)  ; raw count rate per anode
    dtc = 1. - rate*swe_dead
    
    indx = where(dtc lt swe_min_dtc, count)   ; maximum deadtime correction
    if (count gt 0L) then dtc[indx] = !values.f_nan
    
    mvn_swe_engy.dtc = dtc                    ; corrected count rate = rate/dtc

; Apply cross calibration factor.  A new factor is calculated after each 
; MCP bias adjustment. See mvn_swe_config for these times.  See 
; mvn_swe_calib for the cross calibration factors.

    scale = replicate(swe_crosscal[0], 64, npts)

    for i=1,(n_elements(t_mcp)-1) do begin
      indx = where(mvn_swe_engy.time gt t_mcp[i], count)
      if (count gt 0L) then scale[*,indx] = swe_crosscal[i]
    endfor

    mvn_swe_engy.eff /= scale

; Electron rest mass [eV/(km/s)^2]

    mvn_swe_engy.mass = mass_e

; Validate the data
    
    mvn_swe_engy.valid = 1B               ; Yep, it's valid.
  
    mvn_swe_convert_units, mvn_swe_engy, units

  endelse

; SWEA SPEC archive data

  if (size(a5,/type) ne 8) then begin
    print,"No SPEC archive data."
  endif else begin
    npkt = n_elements(a5)                 ; number of packets
    npts = 16L*npkt                       ; 16 spectra per packet
    ones = replicate(1.,npts)

    mvn_swe_engy_arc = replicate(swe_engy_struct,npts)
    mvn_swe_engy_arc.apid = 'A5'XB

    for i=0L,(npkt-1L) do begin
      delta_t = swe_dt[a5[i].period]*dindgen(16) + (1.95D/2D)    ; center time offset (sample mode)
      dt_arr0 = 16.*6.                                           ; 16 anode X 6 defl. (sample mode)
      if (a5[i].smode or smode) then begin
        delta_t = delta_t + (2D^a5[i].period - 1D)               ; center time offset (sum mode)
        dt_arr0 = dt_arr0*swe_dt[a5[i].period]/2.                ; # samples averaged (sum mode)
      endif

      j0 = i*16L
      for j=0,15 do begin
        tspec = a5[i].time + delta_t[j]

        dt = min(abs(tspec - swe_hsk.time),k)                       ; look for config. changes
        if (swe_active_chksum ne swe_chksum[k]) then begin
          mvn_swe_calib, chksum=swe_chksum[k]
          gf = total(swe_gf[*,*,0],2)/16.
          eff = total(swe_mcp_eff[*,*,0],2)/16.
        endif

        mvn_swe_engy_arc[j0+j].chksum = swe_active_chksum                       ; sweep table
        mvn_swe_engy_arc[j0+j].time = a5[i].time + delta_t[j]                   ; center time
        mvn_swe_engy_arc[j0+j].met  = a5[i].met  + delta_t[j]                   ; center met
        mvn_swe_engy_arc[j0+j].end_time = a5[i].time + delta_t[j] + delta_t[0]  ; end time
        mvn_swe_engy_arc[j0+j].delta_t = swe_dt[a5[i].period]                   ; cadence
        mvn_swe_engy_arc[j0+j].integ_t = swe_integ_t                            ; integration time
        mvn_swe_engy_arc[j0+j].dt_arr = dt_arr0*dsf[k]                          ; # bins averaged

        mvn_swe_engy_arc[j0+j].energy = swe_energy                      ; avg. over 6 deflections
        mvn_swe_engy_arc[j0+j].denergy = swe_denergy                    ; avg. over 6 deflections

        mvn_swe_engy_arc[j0+j].gf = gf                                  ; avg. over 16 anodes
        mvn_swe_engy_arc[j0+j].eff = eff                                ; avg. over 16 anodes

        mvn_swe_engy_arc[j0+j].data = a5[i].data[*,j]                   ; raw counts
        mvn_swe_engy_arc[j0+j].var = a5[i].var[*,j]                     ; variance
      endfor
    endfor

; Correct for deadtime

    rate = mvn_swe_engy_arc.data / (swe_integ_t * mvn_swe_engy_arc.dt_arr)      ; raw count rate per anode
    dtc = 1. - rate*swe_dead
    
    indx = where(dtc lt swe_min_dtc, count)   ; maximum deadtime correction
    if (count gt 0L) then dtc[indx] = !values.f_nan
    
    mvn_swe_engy_arc.dtc = dtc                ; corrected count rate = rate/dtc

; Apply cross calibration factor.  A new factor is calculated after each 
; MCP bias adjustment. See mvn_swe_config for these times.  See 
; mvn_swe_calib for the cross calibration factors.

    scale = replicate(swe_crosscal[0], 64, npts)

    for i=1,(n_elements(t_mcp)-1) do begin
      indx = where(mvn_swe_engy_arc.time gt t_mcp[i], count)
      if (count gt 0L) then scale[*,indx] = swe_crosscal[i]
    endfor
  
    mvn_swe_engy_arc.eff /= scale

; Electron rest mass [eV/(km/s)^2]

    mvn_swe_engy_arc.mass = mass_e

; Validate the data
    
    mvn_swe_engy_arc.valid = 1B               ; Yep, it's valid.
  
    if (size(units,/type) eq 7) then mvn_swe_convert_units, mvn_swe_engy_arc, units

  endelse

  return

end
