;+
;PROCEDURE:   mvn_swe_package
;PURPOSE:
;  Constructs 3D, PAD, and ENGY data structures from raw data.
;
;USAGE:
;  mvn_swe_package
;
;INPUTS:
;
;KEYWORDS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2014-03-25 11:27:57 -0700 (Tue, 25 Mar 2014) $
; $LastChangedRevision: 14671 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_package.pro $
;
;CREATED BY:    David L. Mitchell  07-24-12
;FILE: mvn_swe_package.pro
;-
pro mvn_swe_package

  @mvn_swe_com
  
  mvn_swe_struct

; SWEA 3D data

  if (data_type(swe_3d) ne 8) then begin
    print,"No 3D data."
  endif else begin
    npts = n_elements(swe_3d)
    mvn_swe_3d = replicate(swe_3d_struct,npts)
    
    dt = 1.95D                                  ; sample time
    mvn_swe_3d.time = swe_3d.time               ; start time
    mvn_swe_3d.met = swe_3d.met                 ; start time
    mvn_swe_3d.end_time = swe_3d.time + dt      ; end time
    mvn_swe_3d.delta_t = swe_dt[swe_3d.period]  ; sample interval

; Integration time per energy/angle bin prior to summing bins
; There are 7 deflection bins for each of 64 energy bins spanning
; 1.95 sec.  The first deflection bin is for settling and is
; discarded.

    mvn_swe_3d.integ_t = swe_integ_t

; There are 80 angular bins to span 16 anodes (az) X 6 deflections (el).
; Adjacent anodes are summed at the largest upward and downward elevations,
; so that the 16 x 6 = 96 bins are reduced to 80.  However, I will maintain
; 96 bins and duplicate data at the highest deflections.  Then dt_arr is
; used to renormalize and effectively divide the counts evenly between each 
; pair of duplicated bins.

    mvn_swe_3d.dt_arr[*, 0:15] = 2.     ; adjacent anode (azimuth) bins summed
    mvn_swe_3d.dt_arr[*,16:79] = 1.     ; no summing for mid-elevations
    mvn_swe_3d.dt_arr[*,80:95] = 2.     ; adjacent anode (azimuth) bins summed
    
    indx = where(swe_3d.group eq 1, count)
    if (count gt 0L) then mvn_swe_3d[indx].dt_arr = 2.*mvn_swe_3d[indx].dt_arr
    
    indx = where(swe_3d.group eq 2, count)
    if (count gt 0L) then mvn_swe_3d[indx].dt_arr = 4.*mvn_swe_3d[indx].dt_arr

; Energy bins are summed according to the group parameter.
; Energy resolution in the standard 3D structure allows for the possibility of
; variation with elevation angle.  SWEA calibrations show that this variation
; is modest (< 1% from +55 to -30 deg, increasing to ~4% at -45 deg).  For
; now, I will not include elevation variation.

    mvn_swe_3d.group = swe_3d.group
    
    for j=0,2 do begin
      indx = where(swe_3d.group eq j, count)
      if (count gt 0) then begin
        ones = replicate(1.,count)

        energy = ones ## swe_swp[*,j]
        denergy = transpose(swe_de[*,*,j])
        for i=0,95 do begin
          mvn_swe_3d[indx].energy[*,i] = energy
          mvn_swe_3d[indx].denergy[*,i] = ones ## denergy[*,i/16]
        endfor

; Geometric factor.  When using V0, the geometric factor is a function of
; energy.  There is also variation in azimuth and elevation.

        gf_arr = ones ## swe_gf[*,j]
        for i=0,95 do mvn_swe_3d[indx].gf[*,i] = gf_arr

; Relative MCP efficiency.  Depends only on energy for now.

        eff_arr = ones ## swe_mcp_eff[*,j]
        for i=0,95 do mvn_swe_3d[indx].eff[*,i] = eff_arr

; Fill in the elevation array (units = deg)

        elev = transpose(swe_el[*,*,j])
        delev = transpose(swe_del[*,*,j])

        for i=0,95 do begin
          k = i/16
          mvn_swe_3d[indx].theta[*,i] = ones ## elev[*,k]
          mvn_swe_3d[indx].dtheta[*,i] = ones ## delev[*,k]
        endfor

      endif
    endfor

; Fill in the azimuth array - no energy dependance (units = deg)
;   I am duplicating azimuth bins at the highest and lowest deflections.

    for i=0,95 do begin
      k = i mod 16
      mvn_swe_3d.phi[*,i] = swe_az[k]
      mvn_swe_3d.dphi[*,i] = swe_daz[k]
    endfor

; Calculate solid angles from elevation and azimuth

    mvn_swe_3d.domega = (2.*!dtor)*mvn_swe_3d.dphi *     $
                        cos(mvn_swe_3d.theta*!dtor) *    $
                        sin(mvn_swe_3d.dtheta*!dtor/2.)

; Fill in the data array, duplicating values as needed  (I have to swap the
; first two dimensions of swe_3d.data.)

    data = transpose(swe_3d.data,[1,0,2])  ; 80 angles, [64,32,16] energies
    counts = mvn_swe_3d.data               ; 96 angles, 64 energies

    for i=0,15 do begin                    ; duplicate azimuth bins
      k = i/2
      counts[*,i,*] = data[*,k,*]
      counts[*,(i+80),*] = data[*,(k+72),*]
    endfor
    counts[*,16:79,*] = data[*,8:71,*]     ; copy mid-elevations straight over

    data = counts                          ; get ready to duplicate energy bins

    indx = where(swe_3d.group eq 1, count)
    if (count gt 0L) then for i=0,63 do counts[i,*,indx] = data[i/2,*,indx]
    
    indx = where(swe_3d.group eq 2, count)
    if (count gt 0L) then for i=0,63 do counts[i,*,indx] = data[i/4,*,indx]

; Calculate the deadtime correction, since the units are conveniently COUNTS.
; This makes it possible to convert back and forth between RATE, COUNTS and 
; other units.

    rate = counts/(swe_integ_t*mvn_swe_3d.dt_arr)  ; raw count rate
    dtc = 1. - rate*swe_dead
    
    indx = where(dtc lt 0.2, count)     ; maximum 5x deadtime correction
    if (count gt 0L) then dtc[indx] = !values.f_nan
    
    mvn_swe_3d.dtc = dtc                ; corrected count rate = rate/dtc

; And last, but not least, the data

    mvn_swe_3d.data = counts            ; raw counts

; Validate the data
    
    mvn_swe_3d.valid = 1B

  endelse

  return

end
