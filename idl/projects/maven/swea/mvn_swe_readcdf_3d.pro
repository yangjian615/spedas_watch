;+
; NAME: 
;   MVN_SWE_READCDF_3D
; SYNTAX:
;   MVN_SWE_READCDF_3D, INFILE, STRUCTURE
; PURPOSE:
;   Routine to read CDF file from mvn_swe_makecdf_3d.pro
; INPUTS:
;   INFILE: CDF file name to read
;           (nominally created by mvn_swe_makecdf_3d.pro)
; OUTPUT:
;   STRUCTURE: IDL data structure
; KEYWORDS:
;   OUTFILE: Output file name
; HISTORY:
;   Created by Matt Fillingim
; VERSION:
;   $LastChangedBy: mattf $
;   $LastChangedDate: 2015-01-16 15:41:56 -0800 (Fri, 16 Jan 2015) $
;   $LastChangedRevision: 16667 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_readcdf_3d.pro $
;
;-

pro mvn_swe_readcdf_3d, infile, structure

; common blocks
@mvn_swe_com

; get structure format ; use swe_3d_struct format
mvn_swe_struct

n_e = swe_3d_struct.nenergy ; 64
n_az = 16
n_el = 6
n_a = swe_3d_struct.nbins ; 96

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
structure = replicate(swe_3d_struct, nrec) ; from mvn_swe_struct

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
           data_name = 'SWEA 3D Survey'
           apid = 160B
         END
  'arc': BEGIN
           data_name = 'SWEA 3D Archive'
           apid = 161B
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
; currently, chksum = 0B and valid = 1B
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
; dt_arr -- weighting array for summing bins ; [n_e, n_a]
; [From mvn_swe_get3d.pro]
; There are 80 angular bins to span 16 anodes (az) X 6 deflections (el).
; Adjacent anodes are summed at the largest upward and downward elevations,
; so that the 16 x 6 = 96 bins are reduced to 80. However, I will maintain
; 96 bins and duplicate data at the highest deflections.
; Then dt_arr is used to renormalize and effectively divide the counts
; evenly between each pair of duplicated bins

;dt_arr = structure.dt_arr
dt_arr = fltarr(n_e, n_a, nrec)
dt_arr[*,  0:15, *] = 2. ; adjacent anode (azimuth) bins summed
dt_arr[*, 16:79, *] = 1. ; no summing for mid-elevations
dt_arr[*, 80:95, *] = 2. ; adjacent anode (azimuth) bins summed

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
; energy -- energy sweep ; [n_e, n_a, nrec]
CDF_VARGET, id, 'energy', tmp_energy, /ZVAR ; [64]
energy = fltarr(n_e, n_a, nrec)
for i = 0, nrec-1 do $
  energy[*, *, i] = tmp_energy # replicate(1., n_a)
structure.energy = energy

; *** denergy
; denergy - energy widths for each energy/angle bin ; [n_e, n_a]
CDF_VARGET, id, 'de_over_e', tmp_de_over_e, /ZVAR ; [64]
tmp_denergy = tmp_de_over_e*tmp_energy ; [64]
denergy = tmp_denergy # replicate(1., n_a) ; [64, 96]
structure.denergy = denergy

; *** eff
; eff -- MCP efficiency ; [n_e, n_a]
; we will define structure.eff[*, *] = 1.
; the only place structure.eff is used is in mvn_swe_convert_units.pro
; --> gf = data.gf*data.eff
; therefore, we can fold all of the eff and gf information into
; structure.gf (below) and set structure.eff = 1.

structure.eff = replicate(1., n_e, n_a)

; *** nbins
; nbins -- number of angle bins
structure.nbins = n_a

; *** theta
; theta -- elevation angle
CDF_VARGET, id, 'elev', elev, /ZVAR ; [64, 6]
; change dimensions [64, 6] --> [64, 96]
theta = fltarr(n_e, n_a)
for i = 0, n_a-1 do theta[*, i] = elev[*, i/16]
structure.theta = theta

; *** dtheta
; dtheta -- elevation angle width
; [following mvn_swe_calib.pro]
; for each energy step, just make the bins touch with no gaps
; assume this is not a function of angle; a function of energy only
; [this is what mvn_swe_calib.pro also assumes]

delev = median(elev - shift(elev, 0, 1), dimension = 2) ; [n_e]
dtheta = delev # replicate(1., n_a) ; [n_e, n_a]
structure.dtheta = dtheta

; *** phi and dphi
; phi -- azimuth angle
; dphi -- azimuth angle width
CDF_VARGET, id, 'azim', azim, /ZVAR
; change dimensions [16] --> [64, 96]
; phi and dphi are fixed w.r.t. energy

; [following mvn_swe_calib.pro]
dazim = (shift(azim, -1) - shift(azim, 1))/2.
dazim[[0, n_az-1]] = dazim[[0, n_az-1]] + 180.
;dazim = replicate(22.5, n_az) ; nominal value

; [following mvn_swe_get3d.pro]
phi = fltarr(n_e, n_a)
dphi = fltarr(n_e, n_a)
for i = 0, n_a-1 do begin
  k = i mod 16
  phi[*, i] = azim[k]
  dphi[*, i] = dazim[k]
endfor

structure.phi = phi
structure.dphi = dphi

; *** domega
; domega -- solid angle
domega = (2.*!dtor)*dphi*cos(theta*!dtor)*sin(dtheta*!dtor/2.)
structure.domega = domega

; *** gf
; gf -- geometric factor per energy/angle bin
; reconstruct gf*eff (eff = 1.)
CDF_VARGET, id, 'geom_factor', geom_factor, /ZVAR ; integer
CDF_VARGET, id, 'g_engy', g_engy, /ZVAR ; [64]
CDF_VARGET, id, 'g_elev', g_elev, /ZVAR ; [64, 6]
CDF_VARGET, id, 'g_azim', g_azim, /ZVAR ; [16]

gfe = fltarr(n_e, n_a)
for i = 0, n_a-1 do $
  gfe[*, i] = geom_factor*g_engy*g_elev[*, i/16]*g_azim[i mod 16]

; average the fist and last 16 bins (top and bottom elevation angles)
i = 2*indgen(8)
i = [i, i+80]
gfe[*, i] = (gfe[*, i] + gfe[*, i+1])/2.
gfe[*, i+1] = gfe[*, i]
structure.gf = gfe

; *** dtc
; dtc -- dead time correction
swe_dead = 2.8e-6 ; IRAP calibration
CDF_VARGET, id, 'counts', counts, /ZVAR, rec_count = nrec ; [64, 96, nrec]
counts = REFORM(counts, 64, 96, nrec)
rate = counts/(integ_t*dt_arr) ; raw count rate ; [64, 96, nrec]
dtc = 1. - rate*swe_dead
ndx = where(dtc lt 0.2, count) ; maximum 5x deadtime correction
if (count gt 0l) then dtc[ndx] = !values.f_nan
structure.dtc = dtc

; *** mass
; mass -- electron rest mass [3V/(km/s)^2]
c = 2.99792458D5               ; velocity of light [km/s]
mass_e = (5.10998910D5)/(c*c)  ; electron rest mass [eV/(km/s)^2]
structure.mass = mass_e

; *** sc_pot
; sc_pot -- spacecraft potential
structure.sc_pot = 0.

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
CDF_VARGET, id, 'diff_en_fluxes', data, /ZVAR, rec_count = nrec
; reform dimensions [64, 16, 6, nrec] --> [64, 96, nrec]
data = REFORM(data, 64, 96, nrec)
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

; this takes a while
;print, 'all but var'
;t = systime(1)
; for each element, find decom ndx from counts; use ndx to find devar
var = fltarr(n_e, n_a, nrec)
for k = 0, nrec-1 do begin
  for j = 0, n_a-1 do begin
    for i = 0, n_e-1 do begin
;      variance[i, j, k] = devar[where(decom eq counts[i, j, k])]
      dx = min(abs(counts[i,j,k] - decom), ndx)
      var[i, j, k] = devar[ndx]
    endfor
  endfor
endfor
;print, systime(1) - t

; in units of counts - want in units of energy flux (data)
; from mvn_swe_convert_units
; input: 'COUNTS' : scale = 1D
; output: 'EFLUX' : scale = scale * 1D/(dtc * dt * dt_arr * gf)
;                   where dt = integ_t ; gf = gf*eff ; eff = 1
scale = 1.D/(dtc*integ_t*dt_arr*gfe)
var = var*scale
structure.var = var

; finis!

end
