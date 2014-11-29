;+
; NAME: 
;   MVN_SWE_READCDF_SPEC
; SYNTAX:
;	MVN_SWE_READCDF_SPEC, INFILE, STRUCTURE
; PURPOSE:
;	Routine to read CDF file from mvn_swe_makecdf_spec.pro
; INPUTS:
;   INFILE: CDF file name to read
;           (nominally created by mvn_swe_makecdf_spec.pro)
; OUTPUT:
;   STRUCTURE: IDL data structure
; KEYWORDS:
;   OUTFILE: Output file name
; HISTORY:
;   Created by Matt Fillingim
; VERSION:
;   $LastChangedBy: mattf $
;   $LastChangedDate: 2014-11-25 10:16:02 -0800 (Tue, 25 Nov 2014) $
;   $LastChangedRevision: 16300 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_readcdf_spec.pro $
;
;-

pro mvn_swe_readcdf_spec, infile, structure

; common blocks
@mvn_swe_com

; get structure format ; use swe_engy_struct format
mvn_swe_struct

n_e = swe_engy_struct.nenergy ; 64

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
CDF_VARGET, id, 'num_spec', nrec

; create structure to fill
structure = replicate(swe_engy_struct, nrec) ; from mvn_swe_struct

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
           data_name = 'SWEA SPEC Survey'
           apid = 164B
         END
  'arc': BEGIN
           data_name = 'SWEA SPEC Archive'
           apid = 165B
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
;; there appears to be a glitch whenever delta_t changes
;; look for changes in delta_t
;delta_delta_t = delta_t - shift(delta_t, 1)
;delta_delta_t[0] = delta_delta_t[1]
;ndx = where(abs(delta_delta_t) gt gt 0.5, n_ndx) ; some small number
;; should come in pairs of two
;if (n_ndx gt 0) then for i = 0, n_ndx/2 - 1 do $
;  delta_t[ndx[2*i]:ndx[2*i+1]] = delta_t[ndx[2*i] + 2]
structure.delta_t = delta_t

; *** integ_t
; integ_t -- integration time per energy/angle bin -- fixed
; [From mvn_swe_get3d.pro]
; There are 7 deflection bins for each of 64 energy bins spanning 1.95 s
; (the first deflection bin is for settling and is discarded).

integ_t = 1.95D/64.D/7.D ; = 0.00435... sec
structure.integ_t = integ_t

; *** dt_arr
; dt_arr -- weighting array for summing bins ; [n_e]
; inlcude information from num_accum --> period
; multiply by dsf --> weight_factor
CDF_VARGET, id, 'num_accum', tmp_num_accum, /ZVAR, rec_count = nrec ; nrec]
CDF_VARGET, id, 'weight_factor', tmp_dsf, /ZVAR
dt_arr0 = 16.*6.*tmp_dsf ; sum over azimuth and elevation bins
dt_arr = replicate(dt_arr0, n_e) # tmp_num_accum ; [n_e, nrec]
structure.dt_arr = dt_arr

; *** nenergy
; nenergy -- number of energies = 64
structure.nenergy = n_e ; fixed

; *** energy
; energy -- energy sweep ; [n_e]
CDF_VARGET, id, 'energy', tmp_energy, /ZVAR ; [64]
structure.energy = tmp_energy

; *** denergy
; denergy - energy widths for each energy/angle bin ; [n_e]
CDF_VARGET, id, 'de_over_e', tmp_de_over_e, /ZVAR ; [64]
tmp_denergy = tmp_de_over_e*tmp_energy ; [64]
structure.denergy = tmp_denergy

; *** eff
; eff -- MCP efficiency ; [n_e]
; we will define structure.eff[*] = 1.
; the only place structure.eff is used is in mvn_swe_convert_units.pro
; --> gf = data.gf*data.eff
; therefore, we can fold all of the eff and gf information into
; structure.gf (below) and set structure.eff = 1.

structure.eff = replicate(1., n_e)

; *** gf
; gf -- geometric factor per energy/angle bin
; reconstruct gf*eff (eff = 1.)
CDF_VARGET, id, 'geom_factor', geom_factor, /ZVAR ; integer
CDF_VARGET, id, 'g_engy', g_engy, /ZVAR ; [64]

gfe = geom_factor*g_engy
structure.gf = gfe

; *** dtc
; dtc -- dead time correction
swe_dead = 2.8e-6 ; IRAP calibration
CDF_VARGET, id, 'counts', counts, /ZVAR, rec_count = nrec ; [64, nrec]
rate = counts/(integ_t*dt_arr) ; raw count rate ; [64, nrec]
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

; *** bkg
; bkg -- background
structure.bkg = 0.

; *** data
; data -- data in units of differential energy flux
CDF_VARGET, id, 'diff_en_fluxes', data, /ZVAR, rec_count = nrec
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
for i = 2, 15 do decom[i, *] = 2.*decom[(i-1), *]

d_floor = reform(transpose(decom), 256) ; FSW rounds down
d_ceil = shift(d_floor, -1) - 1.
d_ceil[255] = 2.^19. - 1. ; 19-bit counter max
d_mid = (d_ceil + d_floor)/2. ; mid-point
n_pts = d_ceil - d_floor + 1. ; number of values in range
d_var = d_mid + (n_pts^2. - 1.)/12. ; variance w/ dig. noise

decom = d_mid ; decompressed counts
devar = d_var ; variance w/ digitization noise

; this takes a while
;t = systime(1)
; for each element, find decom ndx from counts; use ndx to find devar
var = fltarr(n_e, nrec)
for k = 0, nrec-1 do begin
  for j = 0, n_e-1 do begin
;    variance[j, k] = devar[where(decom eq counts[j, k])]
    dx = min(abs(counts[j, k] - decom), ndx)
    var[j, k] = devar[ndx]
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
