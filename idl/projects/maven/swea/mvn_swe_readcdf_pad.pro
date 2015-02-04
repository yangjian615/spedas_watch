;+
; NAME:
;   MVN_SWE_READCDF_PAD
; SYNTAX:
;   MVN_SWE_READCDF_PAD, INFILE, STRUCTURE
; PURPOSE:
;   Routine to read CDF file from mvn_swe_makecdf_pad.pro
; INPUTS:
;   INFILE: CDF file name to read
;           (nominally created by mvn_swe_makecdf_pad.pro)
; OUTPUT:
;   STRUCTURE: IDL data structure
; KEYWORDS:
;   OUTFILE: Output file name
; HISTORY:
;   Created by Matt Fillingim
; VERSION:
;   $LastChangedBy: mattf $
;   $LastChangedDate: 2015-01-30 17:48:56 -0800 (Fri, 30 Jan 2015) $
;   $LastChangedRevision: 16804 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_readcdf_pad.pro $
;
;-

pro mvn_swe_readcdf_pad, infile, structure

; common blocks
@mvn_swe_com

; get structure format ; use swe_pad_struct format
mvn_swe_struct

n_e = swe_pad_struct.nenergy ; 64
n_az = 16
n_el = 6
n_a = swe_pad_struct.nbins ; 16

; right now, only returns one (full) day of data at a time

; do we want a wrapper/call from here, e.g., mvn_swe_load_l2(?)
; to find the correct filename if not supplied?

; crib_l0_to_l2.pro describes how to find the correct filename

if (data_type(infile) eq 0) then begin
  print, 'You must specify a file name.'
;  stop
  return
endif

id = CDF_OPEN(infile)

; get length of data arrays (i.e., number of samples)
CDF_VARGET, id, 'num_dists', nrec

; create structure to fill
structure = replicate(swe_pad_struct, nrec) ; from mvn_swe_struct

; from the top
; *** project_name
project_name = 'MAVEN'
structure.project_name = project_name

; *** data_name and apid
; survey or archive data? get info from the filename
pos = strpos(infile, 'mvn_swe_l2_', /reverse_search)
if (pos eq -1) then begin
  print, 'Error: check filename convention'
  return
endif

tag = strmid(infile, pos+11 ,3) ; should be 'svy' or 'arc'
CASE tag OF
  'svy': BEGIN
           data_name = 'SWEA PAD Survey'
           apid = 162B
         END
  'arc': BEGIN
           data_name = 'SWEA PAD Archive'
           apid = 163B
         END
  ELSE: BEGIN
          print, 'Error: check filename convention'
          return
        END
ENDCASE
structure.data_name = data_name
structure.apid = apid

; *** units_name
units_name = 'eflux'
structure.units_name = units_name

; *** units_procedure
units_procedure = 'mvn_swe_convert_units'
structure.units_procedure = units_procedure

; *** chksum and valid
; currently, chksum and valid are just filled with 1B
; (for lack of anything better)
chksum = 0B
structure.chksum = chksum

valid = 1B
structure.valid = valid

; *** met
; met -- time_met: mission elapsed time -> center of measurement period
CDF_VARGET, id, 'time_met', met, /ZVAR, rec_count = nrec
met = REFORM(met) ; fix dimensions of array [1, nrec] --> [nrec]
structure.met = met

; *** time
; time -- time_unix: Unix time -> center of measurement period
CDF_VARGET, id, 'time_unix', time, /ZVAR, rec_count = nrec
time = REFORM(time) ; fix dimensions of array [1, nrec] --> [nrec]
structure.time = time

; *** end_time
; end_time -- center time (time) + measurement period/2
dt = 1.95D ; measurement span
end_time = time + dt/2.D
structure.end_time = end_time

; *** delta_t
; delta_t -- sample cadence; time between samples
;;; *** not quite correct -- some time jitter *** ;;;
;;; *** as good as it gets -- don't have access to the period *** ;;;
delta_t = time - shift(time, 1)
; replace first element (large negative number) with a copy of 2nd
; assumes time between 1st and 2nd sample = time between 2nd and 3rd
delta_t[0] = delta_t[1]
structure.delta_t = delta_t

; *** integ_t
; integ_t -- integration time per energy/angle bin -- fixed
; [From mvn_swe_get3d.pro]
; There are 7 deflection bins for each of 64 energy bins spanning 1.95 s
; (the first deflection bin is for settling and is discarded).

integ_t = 1.95D/64.D/7.D ; = 0.00435... sec
structure.integ_t = integ_t

; *** dt_arr and group
; dt_arr -- weighting array for summing bins ; [n_e, n_az]
; There are 16 anodes (az) X 6 deflections (el). PAD data use the magnetic
; field to calculate the optimal deflection bin for each of the 16 anode
; bins in order to provide the best pitch angle coverage.  There is no
; summing of angle bins, even at the highest deflections (as in the 3D's).
; So for each energy bin, there is a 16x1 (az, el) array. The final array
; dimensions are then 64 energies X 16 anodes X 1 deflector bin per anode,
; or 64x16, for short.

;dt_arr = fltarr(n_e, n_az, nrec)
dt_arr = replicate(1., n_e, n_az, nrec)

; Energy bins are summed according to the group parameter.
; first get group parameter
CDF_VARGET, id, 'binning', binning, /ZVAR, rec_count = nrec
binning = REFORM(binning) ; fix dimensions of array [1, nrec] --> [nrec]

; since binning = 2^group, group = log2(binning) = log(binning)/log(2)
group = alog(binning)/alog(2.)

for i = 0, nrec-1 do $
 dt_arr[*, *, i] = (2.^group[i])*dt_arr[*, *, i]  ; 2^g energy bins summed
structure.dt_arr = dt_arr
structure.group = group

; *** nenergy
; nenergy -- number of energies = 64
structure.nenergy = n_e ; fixed

; *** energy
; energy -- energy sweep ; [n_e, n_az, nrec]
CDF_VARGET, id, 'energy', tmp_energy, /ZVAR ; [64]
energy = fltarr(n_e, n_az, nrec)
for i = 0, nrec-1 do $
  energy[*, *, i] = tmp_energy # replicate(1., n_az)
structure.energy = energy

; *** denergy
; denergy - energy widths for each energy/angle bin ; [n_e, n_az]
CDF_VARGET, id, 'de_over_e', tmp_de_over_e, /ZVAR ; [64]
tmp_denergy = tmp_de_over_e*tmp_energy ; [64]
denergy = tmp_denergy # replicate(1., n_az) ; [64, 96]
structure.denergy = denergy

; *** eff
; eff -- MCP efficiency ; [n_e, n_az]
; we will define structure.eff[*, *] = 1.
; the only place structure.eff is used is in mvn_swe_convert_units.pro
; --> gf = data.gf*data.eff
; therefore, we can fold all of the eff and gf information into
; structure.gf (below) and set structure.eff = 1.

structure.eff = replicate(1., n_e, n_az)

; *** nbins
; nbins -- number of angle bins
structure.nbins = n_az ; 16

; *** pa
; pa -- pitch angle ; [n_e, n_az, nrec]
CDF_VARGET, id, 'pa', pa, /ZVAR, rec_count = nrec ; [64, 16, nrec]
structure.pa = pa*!DTOR

; *** dpa
; dpa -- pitch angle width ; [n_e, n_az, nrec]
CDF_VARGET, id, 'd_pa', dpa, /ZVAR, rec_count = nrec ; [64, 16, nrec]
structure.dpa = dpa*!DTOR

; to get pa_min, pa_max, theta, dtheta, phi, dpi, domega, (& gf?)
; we need to reconstruct pitch angle maps
; use b_azim and b_elev to pick the bins again (gives us iaz, jel, k3d)

; run mvn_swe_config to get configuration (no inputs) --> get t_mtx
; need t_mtx for next step - converting b_azim, b_elev to PAD packet bytes
mvn_swe_config

; convert b_azim back to PAD packet bytes
CDF_VARGET, id, 'b_azim', baz, /ZVAR, rec_count = nrec
baz = reform(baz) ; fix dimensions of array [1, nrec] --> [nrec]
baz = baz*!DTOR ; b_azim is in degrees --> baz in radians
aBaz = double(baz)*128D/!DPI - 0.5D
aBaz = byte(round(aBaz))
indx = where (time lt t_mtx[1], count)
if (count gt 0L) then aBaz[indx] = aBaz + 64B

CDF_VARGET, id, 'b_elev', bel, /ZVAR, rec_count = nrec
bel = reform(bel) ; fix dimensions of array [1, nrec] --> [nrec]
bel = bel*!DTOR ; b_elev is in degrees --> bel in radians
aBel = double(bel)*40D/!DPI + 19.5D
aBel = byte(round(aBel))

; calculate pitch angle sorting look up table --> returns swe_padlut
mvn_swe_padlut, lut = swe_padlut ; , dlat = 22.5 ; default

; let us assume a priori that the energy sweep table is either 5 or 6
; (according to DM)
; *** energy sweep constant over CDF file (energy --> NOVARY) ***
; need this to reconstruct deflection angle (theta) --> swp.theta
mvn_swe_sweep, result = swp5, tabnum = 5
mvn_swe_sweep, result = swp6, tabnum = 6
; which is it?
diff = 0.01
if (abs(total(tmp_energy - swp5.e)) lt diff) then begin
  tabnum = 5
  swp = swp5
endif else begin
  tabnum = 6
  swp = swp6
endelse
;endif else if (abs(total(tmp_energy - swp6.e)) lt diff) then begin
;  tabnum = 6
;  swp = swp6
;endif else begin
;  tabnum = ?
;  swp = ?
;endelse

; Energy Sweep ; do we need this swe_swp?
; [from mvn_swe_calib.pro]
swe_swp = fltarr(64, 3) ; energy for group = 0, 1, 2

swe_swp[*, 0] = swp.e
for i = 0, 31 do $
  swe_swp[(2*i):(2*i+1),1] = sqrt(swe_swp[(2*i),0] * swe_swp[(2*i+1),0])
for i=0,15 do $
  swe_swp[(4*i):(4*i+3),2] = sqrt(swe_swp[(4*i),1] * swe_swp[(4*i+3),1])

; Deflection Angle
; [from mvn_swe_calib.pro]
swe_el = fltarr(6, 64, 3) ; 6 el bins per energy step for group = 0, 1, 2

swe_el[*, *, 0] = swp.theta
for i= 0, 31 do begin
  swe_el[*, (2*i), 1] = (swe_el[*, (2*i), 0] + swe_el[*, (2*i+1), 0])/2.
  swe_el[*, (2*i+1), 1] = swe_el[*, (2*i), 1]
endfor

for i = 0, 15 do begin
  swe_el[*, (4*i), 2] = (swe_el[*, (4*i), 1] + swe_el[*, (4*i+3), 1])/2.
  for j = 1, 3 do swe_el[*, (4*i+j), 2] = swe_el[*, (4*i), 2]
endfor

; Deflection Angle Range
swe_del = fltarr(6, 64, 3) ; 6 del bins per energy step for group = 0, 1, 2

; SWEA calibrations (energy/angle response)
p = {a0 :  7.579357236d+00, $
     a1 : -1.735792405d-01, $
     a2 : -3.795756270d-04, $
     a3 :  4.389078897d-05, $
     a4 :  5.688218987d-07, $
     a5 :  0.0}

dtheta = abs(swp.th1 - swp.th2) ; elevations spanned over 4 deflector steps
fwhm = polycurve(swp.theta, par = p) ; instrumental resolution at center elevation
swe_del[*, *, 0] = dtheta + fwhm ; elevation resolution of the 4 bins combined

for i = 0, 31 do begin
  swe_del[*,(2*i), 1] = (swe_del[*, (2*i), 0] + swe_del[*, (2*i+1), 0])/2.
  swe_del[*, (2*i+1), 1] = swe_del[*, (2*i), 1]
endfor

for i = 0, 15 do begin
  swe_del[*, (4*i), 2] = (swe_del[*, (4*i), 1] + swe_del[*, (4*i+3), 1])/2.
  for j = 1, 3 do swe_del[*, (4*i+j), 2] = swe_del[*, (4*i), 2]
endfor

; Alternate method, just make the bins touch with no gaps
; This seems to be what plot3d is expecting.
; (could skip all the above definitions of swe_del)
for j = 0, 2 do $
  for i = 0, 63 do $
    swe_del[*, i, j] = median(swe_el[*, i, j] - shift(swe_el[*, i, j], 1))

; Azimuth Angle and Range
; From the rotation scan of 2013-02-27 at 1 keV.
; These are the centroids of the azimuth response function (F) of each
; anode: <az> = total(az*F(az))/total(F(az))

swe_az = [ 11.2470,  31.6462,  55.4238,  76.0096, 101.7052, 122.2142, $
          146.2746, 166.3412, 192.0000, 212.4004, 235.8170, 255.6995, $
          281.4268, 301.6986, 325.7882, 345.7588]

swe_daz = (shift(swe_az, -1) - shift(swe_az, 1))/2.
swe_daz[[0, 15]] = swe_daz[[0 ,15]] + 180.

; For now, override with nominal (don't need above)
swe_az = 11.25 + 22.5*findgen(16) ; azimuth bins in SWEA science coord.
swe_daz = replicate(22.5, 16) ; nominal widths

; do the following for each record -- can't use matrix operations
; set up array of quantities to keep
tmp_pa = fltarr(n_e, n_az, nrec)
tmp_dpa = fltarr(n_e, n_az, nrec)
tmp_pa_min = fltarr(n_e, n_az, nrec)
tmp_pa_max = fltarr(n_e, n_az, nrec)
tmp_theta = fltarr(n_e, n_az, nrec)
tmp_dtheta = fltarr(n_e, n_az, nrec)
tmp_phi = fltarr(n_e, n_az, nrec)
tmp_dphi = fltarr(n_e, n_az, nrec)
tmp_domega = fltarr(n_e, n_az, nrec)
tmp_gf = fltarr(n_e, n_az, nrec)
iaz = intarr(n_az, nrec)
jel = intarr(n_az, nrec)
k3d = intarr(n_az, nrec)

;print, 'begin loop' ; ***

FOR h = 0, nrec-1 DO BEGIN ; PAD quantities

  ; [from mvn_swe_padmap]
  ; Anode, deflector, and 3D bins for each PAD bin
  i = fix((indgen(16) + aBaz[h]/16) mod 16) ; 16 anode bins at each time
  j = swe_padlut[*, aBel[h]] ; 16 deflector bins at each time
  k = j*16 + i ; 16 3D angle bins at each time

  ; now get pa_min & pa_max
  ; nxn azimuth-elevation array for each of the 16 PAD bins
  ; Elevations are energy dependent above ~2 keV.
  ddtor = !dpi/180D
  ddtors = replicate(ddtor, 64)
  n = 17 ; patch size - odd integer

  daz = double((indgen(n*n) mod n) - (n-1)/2)/double(n-1) # double(swe_daz[i])
  Saz = reform(replicate(1D, n*n) # double(swe_az[i]) + daz, n*n*16) # ddtors

  Sel = dblarr(n*n*16, 64)
  for m = 0, 63 do begin
    del = reform(replicate(1D, n) # double(indgen(n) - (n-1)/2)/double(n-1), n*n) $
        # double(swe_del[j, m, group[h]])
    Sel[*, m] = reform(replicate(1D, n*n) # double(swe_el[j, m, group[h]]) + del, n*n*16)
  endfor
  Sel = Sel*ddtor

  Saz = reform(Saz, n*n, 16, 64) ; nxn az-el patch, 16 pitch angle bins, 64 energies
  Sel = reform(Sel, n*n, 16, 64) 

; Calculate the nominal (center) pitch angle for each bin
; This is a function of energy because the deflector high voltage supply
; tops out above ~2 keV, and it's function of time because the magnetic
; field varies: pam -> 16 angles X 64 energies.
  pam = acos(cos(Saz - Baz[h])*cos(Sel)*cos(Bel[h]) + sin(Sel)*sin(Bel[h]))

  pa = total(pam, 1)/float(n*n) ; mean pitch angle
  pa_min = min(pam, dim = 1) ; minimum pitch angle
  pa_max = max(pam, dim = 1) ; maximum pitch angle
  dpa = pa_max - pa_min ; pitch angle range

; save 'em
  iaz[*, h] = i
  jel[*, h] = j
  k3d[*, h] = k
  tmp_pa[*, *, h] = transpose(float(pa)) ; should equal pa
  tmp_dpa[*, *, h] = transpose(float(dpa)) ; should equal dpa
  tmp_pa_min[*, *, h] = transpose(float(pa_min))
  tmp_pa_max[*, *, h] = transpose(float(pa_max))

; [from mvn_swe_getpad.pro]
  tmp_theta[*, *, h] = transpose(swe_el[j, *, group[h]])
  tmp_dtheta[*, *, h] = transpose(swe_del[j, *, group[h]])
  tmp_phi[*, *, h] = replicate(1., n_e) # swe_az[i]
  tmp_dphi[*, *, h] = replicate(1., n_e) # swe_daz[i]

ENDFOR ; for h = 0, nrec - 1

;print, 'end loop' ; ***

; old way -- not quite the same (but close)
;; *** pa_min
;; pa_min -- pitch angle minimum ; [n_e, n_az, nrec]
;pa_min = pa - dpa/2.
;structure.pa_min = pa_min

; *** pa_min
; pa_min -- pitch angle minimum
structure.pa_min = tmp_pa_min

; old way - not quite the same (not close)
;; *** pa_max
;; pa_max -- pitch angle maximum ; [n_e, n_az, nrec]
;pa_max = pa + dpa/2.
;structure.pa_max = pa_max

; *** pa_max
; pa_max -- pitch angle maximum
structure.pa_max = tmp_pa_max

; *** theta
; theta -- elevation angle
structure.theta = tmp_theta

; *** dtheta
; dtheta -- elevation angle width
structure.dtheta = tmp_dtheta

; *** phi
; phi -- azimuth angle
structure.phi = tmp_phi

; *** dphi
; dphi -- azimuth angle width
structure.dphi = tmp_dphi

; *** domega
; domega -- solid angle
domega = (2.*!dtor)*tmp_dphi*cos(tmp_theta*!dtor)*sin(tmp_dtheta*!dtor/2.)
structure.domega = domega

; *** gf
; gf -- geometric factor per energy/angle bin
; reconstruct gf*eff (eff = 1.)
CDF_VARGET, id, 'geom_factor', geom_factor, /ZVAR ; integer
CDF_VARGET, id, 'g_engy', g_engy, /ZVAR ; [64]
CDF_VARGET, id, 'g_pa', g_pa, /ZVAR, rec_count = nrec ; [64, 16, nrec]

gf_engy = geom_factor*(g_engy # replicate(1., n_az))
gfe = fltarr(n_e, n_az, nrec)
for i = 0, nrec-1 do $
  gfe[*, *, i] = gf_engy*g_pa[*, *, i]
structure.gf = gfe

; *** dtc
; dtc -- dead time correction
swe_dead = 2.8e-6 ; IRAP calibration, one MCP-Anode-Preamp chain
swe_min_dtc = 0.25 ; max 4x deadtime correction
CDF_VARGET, id, 'counts', counts, /ZVAR, rec_count = nrec ; [64, 16, nrec]
rate = counts/(integ_t*dt_arr) ; raw count rate ; [64, 16, nrec]
dtc = 1. - rate*swe_dead
indx = where(dtc lt swe_min_dtc, count) ; maximum deadtime correction
if (count gt 0l) then dtc[indx] = !values.f_nan
structure.dtc = dtc

; *** mass
; mass -- electron rest mass [eV/(km/s)^2]
c = 2.99792458D5               ; velocity of light [km/s]
mass_e = (5.10998910D5)/(c*c)  ; electron rest mass [eV/(km/s)^2]
structure.mass = mass_e

; *** sc_pot
; sc_pot -- spacecraft potential
structure.sc_pot = 0.

; *** Baz
; baz is in radians
structure.Baz = baz

; *** Bel
; bel is in radians
structure.Bel = bel

; *** iaz
structure.iaz = iaz

; *** jel
structure.jel = jel

; *** k3d
structure.k3d = k3d

; *** magf
; magf -- magnetic field
structure.magf = [0., 0., 0.]

; *** v_flow
; v_flow -- bulk flow velocity
structure.v_flow = [0., 0., 0.]

; *** bkg
; bkg -- background
structure.bkg = 0.

; *** data
; data -- data in units of differential energy flux
CDF_VARGET, id, 'diff_en_fluxes', data, /ZVAR, rec_count = nrec ; [16, 16, nrec]
structure.data = data

; *** var
; var -- variance
; to get variance (not in CDF), use counts to back out decom index,
; use it to find variance from devar
; [from mvn_swe_load_l0.pro]
; Decompression: 19-to-8
; 16-bit instrument messages are summed into 19-bit counters
; in the PFDPU.  These 19-bit values are rounded down onboard
; to fit into the 8-bit compression scheme, so each compressed
; value corresponds to a range of possible counts.  I take the
; middle of each range for decompression, so there are half
; counts.  This is less than a ~3% (systematic) correction.
;
; Compression introduces digitization noise, which dominates
; the variance at high count rates.  I treat digitization noise
; as additive white noise.

decom = fltarr(16, 16)
decom[0, *] = findgen(16)
decom[1, *] = 16. + findgen(16)
for i=2, 15 do decom[i, *] = 2.*decom[(i-1), *]

d_floor = reform(transpose(decom), 256) ; FSW rounds down
d_ceil = shift(d_floor, -1) - 1.
d_ceil[255] = 2.^19. - 1. ; 19-bit counter max
d_mid = (d_ceil + d_floor)/2. ; mid-point
n_pts = d_ceil - d_floor + 1. ; number of values in range
d_var = d_mid + (n_pts^2. - 1.)/12. ; variance w/ dig. noise

decom = d_mid ; decompressed counts
devar = d_var ; variance w/ digitization noise

; to get var, increase counts (multiply by binning [2^group]), compute var,
; decrease var (divide by binning [2^group]) to match original pad structure

;print, 'all but var' ; ***
t = systime(1) ; ***
; for each element, find decom ndx from counts; use ndx to find devar
var = fltarr(n_e, n_az, nrec)
for k = 0, nrec-1 do begin
  for j = 0, n_az-1 do begin
    for i = 0, n_e-1 do begin
;      variance[i, j, k] = devar[where(decom eq counts[i, j, k])]
; binning (2^group) business
;      dx = min(abs(counts[i,j,k] - decom), ndx)
;      var[i, j, k] = devar[ndx]
      dx = min(abs(counts[i,j,k]*binning[k] - decom), ndx)
      var[i, j, k] = devar[ndx]/binning[k]
    endfor
  endfor
endfor
;print, systime(1) - t ; ***

; in units of counts - want in units of energy flux (data)
; from mvn_swe_convert_units
; input: 'COUNTS' : scale = 1D
; output: 'EFLUX' : scale = scale * 1D/(dtc * dt * dt_arr * gf)
;                   where dt = integ_t ; gf = gf*eff ; eff = 1
;scale = 1.D/(dtc*integ_t*dt_arr*gfe) ; gfe only [64, 16]
scale = 1.D/(dtc*integ_t*dt_arr*structure.gf) ; want [64, 16, nrec]
var = var*scale
structure.var = var

; finis!

end
