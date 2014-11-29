;+
;FUNCTION:
;   MVN_EPH_STRUCT
;PURPOSE:
;   Creates a MAVEN ephemeris structure template.  The
;   structure elements are as follows:
;
;     time    : spacecraft event time (seconds since 1970-01-01/00:00:00)
;     ;;orbit   : orbit numbers (TBD)
;     x_ss    : s/c location in ss coordinates (x)
;     y_ss    : s/c location in ss coordinates (y)
;     z_ss    : s/c location in ss coordinates (z)
;     vx_ss   : s/c velocity in ss coordinates (x)
;     vy_ss   : s/c velocity in ss coordinates (y)
;     vz_ss   : s/c velocity in ss coordinates (z)
;     x_pc    : s/c location in pc coordinates (x)
;     y_pc    : s/c location in pc coordinates (y)
;     z_pc    : s/c location in pc coordinates (z)
;     Elon    : east longitude of s/c [radians]
;     lat     : latitude of s/c [radians]
;     alt     : s/c altitude above Mars surface [km]
;     sza     : solar zenith angle of s/c [radians]
;     ;;lst     : local solar time of s/c (0 = midnight) [radians] (TBD)
;     ;;sun     : sunlight flag (0 = s/c in Mars' optical shadow
;                                1 = s/c illuminated by sun) (TBD)
;
;  The coordinate systems are:
;
;    SS = Mars-centered, sun-state coordinates: (MSO)
;             X -> Sun
;             Y -> opposite to Mars' orbital motion
;             Z -> X x Y
;
;    PC = Mars-centered, body-fixed coordinates: (IAU_MARS)
;              X -> 0 deg longitude, 0 deg latitude
;              Z -> +90 deg latitude (Mars' north pole)
;              Y -> Z x X (= +90 deg east longitude)
;
;USAGE:
;   mvn_eph = mvn_eph_struct(npts)
;INPUTS:
;     npts:     Number of ephemeris points.
;
;KEYWORDS:
;
;     INIT:     Initialize the structure with the specified float scalar.
;               Default = NaN.
;
;CREATED BY:	Takuya Hara  on  2014-10-06
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2014-11-26 11:42:32 -0800 (Wed, 26 Nov 2014) $
; $LastChangedRevision: 16310 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/eph/mvn_eph_struct.pro $
;
;MODIFICATION LOG:
;  (YYYY-MM-DD)
;   2014-10-06: Initial version. This function is based on the MGS
;               routine written by David L. Mitchell. The original
;               routine name is 'mgs_eph_struct' (created on 1999-08-16,
;               and the latest version is 1.4 on 2009-03-06).
;   2014-10-21: Added "vss" keyword. It can restore the spacecraft
;               velocity in the MSO coordinate system. But the data
;               format has not been confirmed yet. It's just TBD now.
;   2014-11-24: Removed "vss" keyword, because information of the
;               spacecraft velocity is included in default. 
;          
;-
FUNCTION mvn_eph_struct, npts, init=init
  IF keyword_set(init) THEN init = FLOAT(init) ELSE init = !values.f_nan
  mvn_eph = {  time  : 0D   , $
               ;; orbit : 0    , $
               x_ss  : init , $
               y_ss  : init , $
               z_ss  : init , $
               vx_ss : init , $
               vy_ss : init , $
               vz_ss : init , $
               x_pc  : init , $
               y_pc  : init , $
               z_pc  : init , $
               Elon  : init , $
               lat   : init , $
               alt   : init , $
               sza   : init };; , $
               ;; lst   : init , $
               ;; sun   : 0B      }
  IF (npts GT 1) THEN mvn_eph = REPLICATE(mvn_eph, npts)
  RETURN, mvn_eph
END 
