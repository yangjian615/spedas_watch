;+
;PROCEDURE:   mvn_swe_config
;PURPOSE:
;  Maintains SWEA configuration changes in a common block (mvn_swe_com).
;  Sweep table updates are handled by checksums (see mvn_swe_sweep) - times
;  are recorded here as documentation.
;
;USAGE:
;  mvn_swe_config
;
;INPUTS:
;
;KEYWORDS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2014-07-10 18:19:07 -0700 (Thu, 10 Jul 2014) $
; $LastChangedRevision: 15567 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_config.pro $
;
;CREATED BY:    David L. Mitchell  03-29-13
;FILE: mvn_swe_config.pro
;-
pro mvn_swe_config

  @mvn_swe_com

; Sweep table update.  Replace tables 1 and 2 with tables 3 and 4, respectively.
; Tables 3 and 4 are used for all cruise data from March 19 to the MOI moratorium.
; See mvn_swe_sweep for definitions of all sweep tables.

  t_swp1 = time_double('2014-03-19/14:00:00')  ; sweep table 3 and 4 upload

; Stowed MAG1-to-SWE rotation matrix.  SWEA was launched with a MAG1-to-SWEA rotation
; matrix for a deployed boom.  This matrix is used by FSW to create optimal cuts 
; through the 3D distributions to create PADs.  This update loads the rotation matrix
; for a stowed boom (135-deg rotation about the spacecraft Y axis).
;
; Because of an undetected error in the MICD, this matrix and the previous one are 
; incorrect by a 90-degree rotation in SWEA azimuth.

  t_mtx1 = time_double('2014-04-02/14:26:02')  ; stowed boom matrix upload #1

; Stowed MAG1-to-SWE rotation matrix update.  This compensates for error in the MICD.
; From this time until the MOI moratorium, the MAG1-to-SWE rotation matrix is correct.

  t_mtx2 = time_double('2014-06-30/17:09:19')  ; stowed boom matrix upload #2

; Deployed MAG1-to-SWE rotation matrix, with corrected MICD.
; Scheduled for transition (Oct 2014).

  t_mtx3 = time_double('2014-10-09/12:00:00')  ; deployed boom matrix upload (TBD)

; Sweep table update.  Replace tables 3 and 4 with tables 5 and 6, respectively.
; Tables 5 and 6 are used for all data from transition onward.
; Scheduled for transition (Oct 2014).

  t_swp2 = time_double('2014-10-09/12:00:00')  ; sweep table 5 and 6 upload (TBD)

; Gather all the configuration change times into one variable (for timebar).

  t_cfg = [t_swp1, t_mtx1, t_mtx2, t_mtx3, t_swp2]

  return

end
