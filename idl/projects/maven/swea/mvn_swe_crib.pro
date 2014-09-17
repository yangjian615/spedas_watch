;--------------------------------------------------------------------
; MAVEN SWEA Crib
;
; Additional information for all procedures and functions can be
; displayed using doc_library.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2014-09-15 11:34:36 -0700 (Mon, 15 Sep 2014) $
; $LastChangedRevision: 15793 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_crib.pro $
;--------------------------------------------------------------------
;

;
; Load L0 data by unix time range into a common block
;   See the cruise catalog for some interesting times.

trange = ['2014-05-02','2014-05-03']
mvn_swe_load_l0, trange, /sumplot

;
; Summary plot for all data in the common block
;   Many optional keywords for plotting additional panels.
;   Use doc_library for details.

mvn_swe_sumplot

;
; Load MAG data, rotate to SWEA coordinates, and smooth to SWEA PAD 
; resolution (1-sec averages).  Set keyword DAVIN to use his MAG loader.
; It is fast, but uses only nominal calibrations and the timing might be 
; a few seconds off.  Otherwise use the MAG quicklook software provided 
; by the MAG team.  The current version is quite slow and has a known 
; timing error.

swe_getmag_ql, trange, both=1, smo=1, /davin

; Calculate the electron distribution symmetry direction.  Return new
; tplot variables in keyword pans.

swe_3d_strahl_dir, pans=pans

; Calculate the spacecraft potential from SPEC data

mvn_swe_sc_pot, /overlay, erange=[3,15], psmo=11, fudge=0.90

; Calculate the spacecraft potential from 3D data
;   Allows bin masking, but has a lower cadence and can be less 
;   accurate because of energy bin summing.

mvn_swe_sc_pot, /overlay, erange=[3,15], psmo=3, fudge=0.90, $
                /ddd, dbins=[0,0,0,1,1,1]

; Determine the direction of the Sun in SWEA coordinates
; (Requires SPICE.)

mvn_swe_sundir, pans=pans

; Estimate electron density from 3D moment (allows bin masking).
; This method does not account for spacecraft photoelectron scattering
; into the SWEA aperture, or for photoelectrons created inside the 
; aperture (primarily from the top cap).  This overestimates the
; density.

ebins = replicate(1B, 64)
; indx = where(swe_swp[*,0] lt 20.)
; ebins[indx] = 0B         ; turn off energies < 20 eV

abins = replicate(1B, 16)  ; all anodes on
abins[6:13] = 0B           ; anti-solar wind direction

abins = replicate(0B, 16)  ; all anodes off
abins[6:13] = 1B           ; solar wind direction

dbins = [0,0,0,1,1,1]      ; turn off lower 3 deflector bins

mvn_swe_n3d, ebins=ebins, abins=abins, dbins=dbins

; Estimate electron density and temperature from fitting the core to
; a Maxwell-Boltzmann distribution and taking a moment to estimate the
; contribution from the halo.  Corrects for scattered electrons.

mvn_swe_n1d, pans=pans

;
; Snapshots selected by the cursor in the tplot window
;   Return data by keyword (ddd, pad, spec) at the last place clicked
;   Use keyword SUM to sum data between two clicks.  (Careful with
;   changing magnetic field.)  The structure element "var" keeps
;   track of counting statistics, including digitization noise.

swe_engy_snap,units='eflux',/mb,spec=spec,/sum
swe_pad_snap,units='eflux',energy=130,pad=pad
swe_3d_snap,spec=1,ddd=ddd,energy=130,/symdir

;
; Get 3D, PAD, or SPEC data at a specified time or array of times.
;   Use keyword ALL to get all 3D/PAD distributions bounded by
;   the input time array.  Use keyword SUM to average all
;   distributions bounded by the input time array.

ddd = mvn_swe_get3d(time, units='eflux')
pad = mvn_swe_getpad(time)
spec = mvn_swe_getspec(time)
