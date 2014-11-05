;+
;FUNCTION:   mvn_swe_getpad
;PURPOSE:
;  Constructs PAD data structure from raw data.
;
;USAGE:
;  pad = mvn_swe_getpad(time)
;
;INPUTS:
;       time:          An array of times for extracting one or more PAD data structure(s)
;                      from survey data (APID A2).  Can be in any format accepted by
;                      time_double.
;
;KEYWORDS:
;       ARCHIVE:       Get PAD data from archive instead (APID A3).
;
;       ALL:           Get all PAD spectra bounded by the earliest and latest times in
;                      the input time array.
;
;       SUM:           If set, then sum all PAD's selected.
;
;       UNITS:         Convert data to these units.  (See mvn_swe_convert_units)
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2014-10-31 14:15:03 -0700 (Fri, 31 Oct 2014) $
; $LastChangedRevision: 16106 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_getpad.pro $
;
;CREATED BY:    David L. Mitchell  03-29-14
;FILE: mvn_swe_getpad.pro
;-
function mvn_swe_getpad, time, archive=archive, all=all, sum=sum, units=units

  @mvn_swe_com

  if (size(time,/type) eq 0) then begin
    print,"You must specify a time."
    return, 0
  endif
  
  time = time_double(time)
  
  if keyword_set(archive) then begin
    if (size(a3,/type) ne 8) then begin
      print,"No PAD archive data."
      return, 0
    endif
    
    if keyword_set(all) then begin
      tmin = min(time, max=tmax, /nan)
      indx = where((a3.time ge tmin) and (a3.time le tmax), npts)
      if (npts eq 0L) then begin
        print,"No PAD archive data at specified time(s)."
        return, 0
      endif
      time = a3[indx].time
    endif

    npts = n_elements(time)
    pad = replicate(swe_pad_struct, npts)
    pad.data_name = "SWEA PAD Archive"
    pad.apid = 'A3'XB
    
    aflg = 1
  endif else begin
    if (size(a2,/type) ne 8) then begin
      print,"No PAD survey data."
      return, 0
    endif
    
    if keyword_set(all) then begin
      tmin = min(time, max=tmax, /nan)
      indx = where((a2.time ge tmin) and (a2.time le tmax), npts)
      if (npts eq 0L) then begin
        print,"No PAD survey data at specified time(s)."
        return, 0
      endif
      time = a2[indx].time
    endif

    npts = n_elements(time)
    pad = replicate(swe_pad_struct, npts)
    pad.data_name = "SWEA PAD Survey"
    pad.apid = 'A2'XB

    aflg = 0
  endelse
  
  if (size(swe_mag1,/type) eq 8) then addmag = 1 else addmag = 0
  if (size(swe_sc_pot,/type) eq 8) then addpot = 1 else addpot = 0

; Locate the PAD data closest to the desired time

  for n=0L,(npts-1L) do begin

    if (aflg) then begin
      tgap = min(abs(a3.time - time[n]), i)
      pkt = a3[i]

      thsk = min(abs(swe_hsk.time - a3[i].time), j)
      if (swe_active_chksum ne swe_chksum[j]) then mvn_swe_calib, chksum=swe_chksum[j]
    endif else begin
      tgap = min(abs(a2.time - time[n]), i)
      pkt = a2[i]

      thsk = min(abs(swe_hsk.time - a2[i].time), j)
      if (swe_active_chksum ne swe_chksum[j]) then mvn_swe_calib, chksum=swe_chksum[j]
    endelse

    pad[n].chksum = swe_active_chksum
 
    dt = 1.95D                         ; measurement span
    pad[n].time = pkt.time + (dt/2D)      ; center time (unix)
    pad[n].met = pkt.met + (dt/2D)        ; center time (met)
    pad[n].end_time = pkt.time + dt       ; end time (unix)
    pad[n].delta_t = swe_dt[pkt.period]   ; cadence

; Integration time per energy/angle bin prior to summing bins
; There are 7 deflection bins for each of 64 energy bins spanning
; 1.95 sec.  The first deflection bin is for settling and is
; discarded.

    pad[n].integ_t = swe_integ_t

; There are 16 anodes (az) X 6 deflections (el).  PAD data use the magnetic
; field to calculate the optimal deflection bin for each of the 16 anode
; bins in order to provide the best pitch angle coverage.  There is no
; summing of angle bins, even at the highest deflections (as in the 3D's).
; So for each energy bin, there is a 16x1 (az, el) array.  The final array
; dimensions are then 64 energies X 16 anodes X 1 deflector bin per anode,
; or 64x16, for short.

    pad[n].dt_arr = 2.^(pkt.group)        ; energy bin summing only

; Pitch angle map

    pam = mvn_swe_padmap(pkt)
    pad[n].pa = transpose(pam.pa)
    pad[n].dpa = transpose(pam.dpa)
    pad[n].pa_min = transpose(pam.pa_min)
    pad[n].pa_max = transpose(pam.pa_max)

; Energy bins are summed according to the group parameter.
; Energy resolution in the standard PAD structure allows for the possibility of
; variation with elevation angle.  SWEA calibrations show that this variation
; is modest (< 1% from +55 to -30 deg, increasing to ~4% at -45 deg).  For
; now, I will not include elevation variation.

    pad[n].group = pkt.group
    pad[n].energy = swe_swp[*,pkt.group] # replicate(1.,16)
    pad[n].denergy = transpose(swe_de[pam.jel,*,pkt.group])

; Geometric factor.  When using V0, the geometric factor is a function of
; energy.  There is also variation in azimuth and elevation.

    pad[n].gf = swe_gf[*,pam.iaz,pkt.group] * swe_dgf[*,pam.jel,pkt.group]

; Relative MCP efficiency.

    pad[n].eff = swe_mcp_eff[*,pam.iaz,pkt.group]

; Fill in the elevation array (units = deg)

    pad[n].theta = transpose(swe_el[pam.jel,*,pkt.group])
    pad[n].dtheta = transpose(swe_del[pam.jel,*,pkt.group])

; Fill in the azimuth array - no energy dependance (units = deg)

    pad[n].phi = replicate(1.,64) # swe_az[pam.iaz]
    pad[n].dphi = replicate(1.,64) # swe_daz[pam.iaz]

; Calculate solid angles from elevation and azimuth

    pad[n].domega = (2.*!dtor)*pad[n].dphi *    $
                    cos(pad[n].theta*!dtor) *   $
                    sin(pad[n].dtheta*!dtor/2.)

; Fill in the data array, duplicating values as needed  (I have to swap the
; first two dimensions of pkt.data.)
  
    counts = transpose(pkt.data[*,indgen(64)/(2^pkt.group)])
    var = transpose(pkt.var[*,indgen(64)/(2^pkt.group)])

; Calculate the deadtime correction, since the units are conveniently COUNTS.
; This makes it possible to convert back and forth between RATE, COUNTS and 
; other units.

    rate = counts/(swe_integ_t*pad[n].dt_arr)  ; raw count rate
    dtc = 1. - rate*swe_dead

    indx = where(dtc lt 0.2, count)            ; maximum 5x deadtime correction
    if (count gt 0L) then dtc[indx] = !values.f_nan
    
    pad[n].dtc = dtc                           ; corrected count rate = rate/dtc

; Fill in the magnetic field direction

    pad[n].Baz = pam.Baz
    pad[n].Bel = pam.Bel

; Fill in bin numbers (useful for comparing PAD and 3D data)

    pad[n].iaz = pam.iaz
    pad[n].jel = pam.jel
    pad[n].k3d = pam.k3d

; Insert MAG1 data, if available.  This is distinct from the MAG angles
; included in the PAD packets (A2, A3), which are calculated by flight
; software using a basic calibration.

    if (addmag) then begin
      dt = min(abs(pad[n].time - swe_mag1.time),i)
      if (dt lt 1D) then pad[n].magf = swe_mag1[i].magf
    endif

; Insert spacecraft potential, if available

    if (addpot) then begin
      dt = min(abs(pad[n].time - swe_sc_pot.time),i)
      if (dt lt pad[n].delta_t) then pad[n].sc_pot = swe_sc_pot[i].potential $
                                else pad[n].sc_pot = !values.f_nan
    endif

; Electron rest mass [eV/(km/s)^2]

    pad[n].mass = mass_e

; And last, but not least, the data

    pad[n].data = counts                       ; raw counts
    pad[n].var = var                           ; variance

; Validate the data

    if (tgap gt 1.1D*pad[n].delta_t) then begin
      msg = strtrim(string(round(tgap)),2)
      print,"data gap: ",msg," sec"
    endif

    pad[n].valid = 1B                          ; Yep, it's valid.

  endfor

; Adjust MCP efficiency for bias increases

  indx = where(pad.time gt t_mcp[0], count)
  if (count gt 0L) then pad[indx].eff = pad[indx].eff * 1.5

; Sum the data.  This is done by summing raw counts corrected by deadtime
; and then setting dtc to unity.  Also, note that summed PAD's can be 
; "blurred" by a changing magnetic field direction, so summing only makes 
; sense for short intervals.  The theta, phi, and omega tags can be 
; hopelessly confused if the MAG direction changes much.

  if (keyword_set(sum) and (npts gt 1)) then begin
    padsum = pad[0]

    padsum.met = mean(pad.met)
    padsum.time = mean(pad.time)
    padsum.end_time = max(pad.end_time)
    tmin = min(pad.time, max=tmax)
    padsum.delta_t = (tmax - tmin) > pad[0].delta_t
    padsum.dt_arr = total(pad.dt_arr,3)      ; normalization for the sum
    
    pa = total(pad.pa,3)/float(npts)         ; pitch angles can be blurred
    dpa = total(pad.dpa,3)/float(npts)
    
    sc_pot = mean(pad.sc_pot)
    Baz = mean(pad.Baz)
    Bel = mean(pad.Bel)
    
    padsum.magf = total(pad.magf,2)/float(npts)
    padsum.v_flow = total(pad.v_flow,2)/float(npts)
    padsum.bkg = mean(pad.bkg)
    
    padsum.data = total(pad.data/pad.dtc,3)  ; corrected counts
    padsum.var = total(pad.var/pad.dtc,3)    ; variance
    padsum.dtc = 1.         ; summing corrected counts is not reversible
    
    pad = padsum
  endif
  
  if (size(units,/type) eq 7) then mvn_swe_convert_units, pad, units

  return, pad

end
