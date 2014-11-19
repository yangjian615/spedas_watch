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
;       UNITS:    Convert data to these units.  (See mvn_swe_convert_units)
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2014-11-17 16:50:13 -0800 (Mon, 17 Nov 2014) $
; $LastChangedRevision: 16207 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_makespec.pro $
;
;CREATED BY:    David L. Mitchell  03-29-14
;FILE: mvn_swe_makespec.pro
;-
pro mvn_swe_makespec, sum=sum, units=units

  @mvn_swe_com
  
  if not keyword_set(sum) then smode = 0 else smode = 1

; Define the 3D, PAD, and SPEC data structures

  if (size(mvn_swe_engy,/type) ne 8) then mvn_swe_struct

; Get the deflection scale factors from the housekeeping (APID 28)

  dsf = total(swe_hsk.dsf,1)/6.   ; unity when all the DSF's are unity

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
        if (swe_active_chksum ne swe_chksum[k]) then mvn_swe_calib, chksum=swe_chksum[k]
        mvn_swe_engy[j0+j].chksum = swe_active_chksum
        dt_arr = dt_arr0*dsf[k]

        mvn_swe_engy[j0+j].time = tspec                                       ; center time
        mvn_swe_engy[j0+j].met  = a4[i].met  + delta_t[j]                     ; center met
        mvn_swe_engy[j0+j].end_time = a4[i].time + delta_t[j] + delta_t[0]    ; end time
        mvn_swe_engy[j0+j].delta_t = swe_dt[a4[i].period]                     ; cadence
        mvn_swe_engy[j0+j].integ_t = swe_integ_t                              ; integration time
        mvn_swe_engy[j0+j].dt_arr = dt_arr                                    ; # bins averaged

        mvn_swe_engy[j0+j].energy = swe_swp[*,0]
        mvn_swe_engy[j0+j].denergy = (total(swe_de[*,*,0],1)/6.)    ; avg. over 6 deflections

        mvn_swe_engy[j0+j].eff = (total(swe_mcp_eff[*,*,0],2)/16.)  ; avg. over 16 anodes
        mvn_swe_engy[j0+j].gf = (total(swe_gf[*,*,0],2)/16.)        ; avg. over 16 anodes

        mvn_swe_engy[j0+j].data = a4[i].data[*,j]                             ; raw counts
        mvn_swe_engy[j0+j].var = a4[i].var[*,j]                               ; variance
      endfor
    endfor

; Correct for deadtime

    rate = mvn_swe_engy.data / (swe_integ_t * mvn_swe_engy.dt_arr)          ; raw count rate per anode
    dtc = 1. - rate*swe_dead
    
    indx = where(dtc lt swe_min_dtc, count)   ; maximum deadtime correction
    if (count gt 0L) then dtc[indx] = !values.f_nan
    
    mvn_swe_engy.dtc = dtc                    ; corrected count rate = rate/dtc

; Adjust MCP efficiency for bias increases

  indx = where(mvn_swe_engy.time gt t_mcp[0], count)
  if (count gt 0L) then mvn_swe_engy[indx].eff = mvn_swe_engy[indx].eff * 1.5

; Electron rest mass [eV/(km/s)^2]

    mvn_swe_engy.mass = mass_e

; Validate the data
    
    mvn_swe_engy.valid = 1B               ; Yep, it's valid.
  
    if (size(units,/type) eq 7) then mvn_swe_convert_units, mvn_swe_engy, units

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

        dt = min(abs(tspec - swe_hsk.time),k)                           ; look for config. changes
        if (swe_active_chksum ne swe_chksum[k]) then mvn_swe_calib, chksum=swe_chksum[k]
        dt_arr = dt_arr0*dsf[k]

        mvn_swe_engy_arc[j0+j].chksum = swe_active_chksum
        mvn_swe_engy_arc[j0+j].time = a5[i].time + delta_t[j]                   ; center time
        mvn_swe_engy_arc[j0+j].met  = a5[i].met  + delta_t[j]                   ; center met
        mvn_swe_engy_arc[j0+j].end_time = a5[i].time + delta_t[j] + delta_t[0]  ; end time
        mvn_swe_engy_arc[j0+j].delta_t = swe_dt[a5[i].period]                   ; cadence
        mvn_swe_engy_arc[j0+j].integ_t = swe_integ_t                            ; integration time
        mvn_swe_engy_arc[j0+j].dt_arr = dt_arr                                  ; # bins averaged

        mvn_swe_engy_arc[j0+j].energy = swe_swp[*,0]
        mvn_swe_engy_arc[j0+j].denergy = (total(swe_de[*,*,0],1)/6.)    ; avg. over 6 deflections

        mvn_swe_engy_arc[j0+j].eff = (total(swe_mcp_eff[*,*,0],2)/16.)  ; avg. over 16 anodes
        mvn_swe_engy_arc[j0+j].gf = (total(swe_gf[*,*,0],2)/16.)        ; avg. over 16 anodes

        mvn_swe_engy_arc[j0+j].data = a5[i].data[*,j]                             ; raw counts
        mvn_swe_engy_arc[j0+j].var = a5[i].var[*,j]                               ; variance
      endfor
    endfor

; Correct for deadtime

    rate = mvn_swe_engy_arc.data / (swe_integ_t * mvn_swe_engy_arc.dt_arr)      ; raw count rate per anode
    dtc = 1. - rate*swe_dead
    
    indx = where(dtc lt swe_min_dtc, count)   ; maximum deadtime correction
    if (count gt 0L) then dtc[indx] = !values.f_nan
    
    mvn_swe_engy_arc.dtc = dtc                ; corrected count rate = rate/dtc

; Adjust MCP efficiency for bias increases

  indx = where(mvn_swe_engy_arc.time gt t_mcp[0], count)
  if (count gt 0L) then mvn_swe_engy_arc[indx].eff = mvn_swe_engy_arc[indx].eff * 1.5

; Electron rest mass [eV/(km/s)^2]

    mvn_swe_engy_arc.mass = mass_e

; Validate the data
    
    mvn_swe_engy_arc.valid = 1B               ; Yep, it's valid.
  
    if (size(units,/type) eq 7) then mvn_swe_convert_units, mvn_swe_engy_arc, units

  endelse

  return

end
