;+
;COMMON BLOCK:   mvn_scpot_com
;PURPOSE:
;  Stores the spacecraft potential information.  Place this near the top
;  of any routine that needs access to the common block.
;
;     Espan       : energy search range for swe+ method
;     thresh      : minimum value of d(logF)/d(logE) for swe+ method
;     dEmax       : maximum width of d(logF)/d(logE) for swe+ method
;     minflux     : minimum 40-eV energy flux for swe+ method
;     badval      : fill value for potential when no method works
;     ee          : 4x oversampled energy array
;     dfs         : 4x oversampled d(logF)/d(logE)
;     d2fs        : 4x oversampled d2(logF)/d(logE)2
;     maxalt      : maximum altitude for replacing SWE/LPW and SWE+ potentials
;                   with SWE- or STA- potentials.
;     min_lpw_pot : minimum valid LPW potential
;     maxdt       : maximum time gap to interpolate over
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2017-07-31 15:24:51 -0700 (Mon, 31 Jul 2017) $
; $LastChangedRevision: 23738 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/mvn_scpot_com.pro $
;
;CREATED BY:	David L. Mitchell
;FILE:  mvn_scpot_com.pro
;-

common mvn_scpot_com, Espan, thresh, dEmax, minflux, obins, badval, ee, dfs, d2fs, $
                      maxalt, min_lpw_pot, maxdt
