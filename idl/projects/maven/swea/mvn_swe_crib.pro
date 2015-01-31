;--------------------------------------------------------------------
; MAVEN SWEA Crib
;
; Additional information for all procedures and functions can be
; displayed using doc_library.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2015-01-27 12:23:35 -0800 (Tue, 27 Jan 2015) $
; $LastChangedRevision: 16754 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_crib.pro $
;--------------------------------------------------------------------
;

;
; Load L0 data by unix time range into a common block
;   See the cruise catalog for some interesting times.
;   Note: trange can be in any format accepted by time_double(), and
;   it can have multiple dimensions, as long as it has at least two
;   elements.  You can also request data by orbit number using the
;   ORBIT keyword.

trange = ['2014-05-02','2014-05-03']
mvn_swe_load_l0, trange

mvn_swe_load_l0, orbit=[357,360]

;
; Summary plot.  Loads ephemeris data and includes a panel for 
; spacecraft altitude (aerocentric).  Orbit numbers appear along
; the time axis.
;
;   Many optional keywords for plotting additional panels.
;   Use doc_library for details.

mvn_swe_sumplot, /eph, /orb

;
; Load MAG data, rotate to SWEA coordinates, and smooth to SWEA PAD 
; resolution (1-sec averages over second half of sweep).  These data 
; are stored in a common block for quick access by mvn_swe_getpad and 
; mvn_swe_get3d.

mvn_swe_addmag

; Calculate the electron distribution symmetry direction.  Return new
; tplot variables in keyword pans.

swe_3d_strahl_dir, pans=pans

; Calculate the spacecraft potential from SPEC data
;   This is a semi-empirical method with a fudge factor based on 
;   experience in previous missions.  This will be refined as we
;   get cross calibrations with LPW, SWIA, and STATIC.

mvn_swe_sc_pot, /overlay

; Calculate the spacecraft potential from 3D data
;   Allows bin masking, but has a lower cadence and can be less 
;   accurate because of energy bin summing.

mvn_swe_sc_pot, /overlay, /ddd, /mask_sc

; Determine the direction of the Sun in SWEA coordinates
;   Requires SPICE.  There are several instances when the S/C
;   Z axis is not pointing at the Sun (some periapsis modes,
;   comm passes, MAG rolls).  When the sensor head is illuminated,
;   increased photoelectron background can occur.  This routine
;   also calculates the direction of the Sun in spacecraft
;   coordinates -- useful to identify pointing modes and times
;   when the spacecraft is communicating with Earth.

mvn_swe_sundir, pans=pans

; Estimate electron density from 3D moment (allows bin masking).
; This method does not account for spacecraft photoelectron scattering
; into the SWEA aperture, or for photoelectrons created inside the 
; aperture (primarily from the top cap).  This overestimates the
; density.

mvn_swe_n3d, /mask_sc

; Estimate electron density and temperature from fitting the core to
; a Maxwell-Boltzmann distribution and taking a moment over energies
; above the core to estimate the contribution from the halo.  This 
; corrects for scattered electrons.

mvn_swe_n1d, /mb, pans=pans

; Estimate electron density and temperature from 1D moments.  Works in
; the post-shock region, where the distribution is not Maxwellian.  
; No correction for scattered electrons.

mvn_swe_n1d, /mom, pans=pans

;
; Resample the pitch angle distributions for a nicer plot

mvn_swe_pad_resample, nbins=128., erange=[100., 150.], /norm, /mask

;
; Calculate pitch angle distributions from 3D distributions

mvn_swe_pad_resample, nbins=128., erange=[100., 150.], /norm, /mask, $
                     /ddd, /map3d

;
; Snapshots selected by the cursor in the tplot window
;   Return data by keyword (ddd, pad, spec) at the last place clicked
;   Use keyword SUM to sum data between two clicks.  (Careful with
;   changing magnetic field.)  The structure element "var" keeps
;   track of counting statistics, including digitization noise.

swe_engy_snap,units='crate',mb=0,pot=1,mom=1,spec=spec
swe_pad_snap,units='eflux',energy=130,pad=pad
swe_3d_snap,/spec,/symdir,energy=130,ddd=ddd,smo=[5,1,1]

;
; Get 3D, PAD, or SPEC data at a specified time or array of times.
;   Use keyword ALL to get all 3D/PAD distributions bounded by
;   the input time array.  Use keyword SUM to average all
;   distributions bounded by the input time array.

ddd = mvn_swe_get3d(time, units='eflux')
pad = mvn_swe_getpad(time)
spec = mvn_swe_getspec(time)
