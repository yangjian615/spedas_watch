;+
;PROCEDURE:   mvn_swe_struct
;PURPOSE:
;  Defines data structures for 3D, PAD, and ENGY products.  These work for both survey
;  and archive.
;
;  All times are for the center of the sample.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2014-08-08 12:43:26 -0700 (Fri, 08 Aug 2014) $
; $LastChangedRevision: 15669 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_struct.pro $
;
;CREATED BY:	David L. Mitchell  2013-07-26
;FILE:  mvn_swe_struct.pro
;-
pro mvn_swe_struct

  @mvn_swe_com

  n_e =  64                       ; number of energy bins
  n_az = 16                       ; number of azimuth bins
  n_el =  6                       ; number of elevation bins
  n_a  = n_az*n_el                ; number of solid angle bins

; Define 3D data structure

  swe_3d_struct = {project_name    : 'MAVEN'                 , $
                   data_name       : 'SWEA 3D Survey'        , $
                   apid            : 'A0'XB                  , $
                   units_name      : 'counts'                , $
                   units_procedure : 'mvn_swe_convert_units' , $
                   chksum          : 0B                      , $  ; LUT checksum
                   valid           : 0B                      , $
                   met             : 0D                      , $  ; mission elapsed time
                   time            : 0D                      , $  ; unix time
                   end_time        : 0D                      , $
                   delta_t         : 0D                      , $  ; sample cadence
                   integ_t         : 0D                      , $  ; integration time
		           dt_arr          : fltarr(n_e,n_a)         , $  ; weighting array for summing bins
		           group           : 0                       , $  ; energy grouping parameter
                   nenergy         : n_e                     , $  ; number of energies
                   energy          : fltarr(n_e,n_a)         , $  ; energy sweep
		           denergy         : fltarr(n_e,n_a)         , $  ; energy widths for each energy/angle bin
		           eff             : fltarr(n_e,n_a)         , $  ; MCP efficiency
                   nbins           : n_a                     , $  ; number of angle bins
                   theta           : fltarr(n_e,n_a)         , $  ; elevation angle
                   dtheta          : fltarr(n_e,n_a)         , $  ; elevation angle width
                   phi             : fltarr(n_e,n_a)         , $  ; azimuth angle
                   dphi            : fltarr(n_e,n_a)         , $  ; azimuth angle width
                   domega          : fltarr(n_e,n_a)         , $  ; solid angle
                   gf              : fltarr(n_e,n_a)         , $  ; geometric factor per energy/angle bin
                   dtc             : fltarr(n_e,n_a)         , $  ; dead time correction
                   sc_pot          : 0.                      , $  ; spacecract potential
                   magf            : fltarr(3)               , $  ; magnetic field
                   v_flow          : fltarr(3)               , $  ; bulk flow velocity
                   bkg             : 0.                      , $  ; background
                   data            : fltarr(n_e,n_a)            }

; Define PAD data structure
;  The magnetic field appears twice.  Baz and Bel are the magnetic field angles in SWEA coordinates
;  that are calculated in FSW and used to sort pitch angles for the PAD data product.  Magf is the
;  magnetic field calculated on the ground from MAG packets.

  swe_pad_struct = {project_name    : 'MAVEN'                 , $
                    data_name       : 'SWEA PAD Survey'       , $
                    apid            : 'A2'XB                  , $
                    units_name      : 'counts'                , $
                    units_procedure : 'mvn_swe_convert_units' , $
                    chksum          : 0B                      , $  ; LUT checksum
                    valid           : 0B                      , $
                    met             : 0D                      , $  ; mission elapsed time
                    time            : 0D                      , $  ; unix time
                    end_time        : 0D                      , $
                    delta_t         : 0D                      , $  ; sample cadence
                    integ_t         : 0D                      , $  ; integration time
	 	            dt_arr          : fltarr(n_e,n_az)        , $  ; weighting array for summing bins
		            group           : 0                       , $  ; energy grouping parameter
                    nenergy         : n_e                     , $  ; number of energies
                    energy          : fltarr(n_e,n_az)        , $  ; energy sweep
		            denergy         : fltarr(n_e,n_az)        , $  ; energy widths for each energy/angle bin
		            eff             : fltarr(n_e,n_az)        , $  ; MCP efficiency
                    nbins           : n_az                    , $  ; number of angle bins
                    pa              : fltarr(n_e,n_az)        , $  ; pitch angle
                    dpa             : fltarr(n_e,n_az)        , $  ; pitch angle width
                    pa_min          : fltarr(n_e,n_az)        , $  ; pitch angle minimum
                    pa_max          : fltarr(n_e,n_az)        , $  ; pitch angle maximum
                    theta           : fltarr(n_e,n_az)        , $  ; elevation angle
                    dtheta          : fltarr(n_e,n_az)        , $  ; elevation angle width
                    phi             : fltarr(n_e,n_az)        , $  ; azimuth angle
                    dphi            : fltarr(n_e,n_az)        , $  ; azimuth angle width
                    domega          : fltarr(n_e,n_az)        , $  ; solid angle
                    gf              : fltarr(n_e,n_az)        , $  ; geometric factor
                    dtc             : fltarr(n_e,n_az)        , $  ; dead time correction
                    sc_pot          : 0.                      , $  ; spacecract potential
                    Baz             : 0.                      , $  ; magnetic field azimuth in SWEA coord.
                    Bel             : 0.                      , $  ; magnetic field elevation in SWEA coord.
                    iaz             : intarr(16)              , $  ; anode bin numbers (0-15)
                    jel             : intarr(16)              , $  ; deflection bin numbers (0-5)
                    k3d             : intarr(16)              , $  ; 3D bin numbers (0-95)
                    magf            : fltarr(3)               , $  ; magnetic field
                    v_flow          : fltarr(3)               , $  ; bulk flow velocity
                    bkg             : 0.                      , $  ; background
                    data            : fltarr(n_e,n_az)           }

; Define Energy Spectrum data structure

  swe_engy_struct = {project_name    : 'MAVEN'                 , $
                     data_name       : 'SWEA SPEC Survey'      , $
                     apid            : 'A4'XB                  , $
                     units_name      : 'counts'                , $
                     units_procedure : 'mvn_swe_convert_units' , $
                     chksum          : 0B                      , $  ; LUT checksum
                     valid           : 0B                      , $
                     met             : 0D                      , $  ; mission elapsed time
                     time            : 0D                      , $  ; unix time
                     end_time        : 0D                      , $
                     delta_t         : 0D                      , $  ; sample cadence
                     integ_t         : 0D                      , $  ; integration time
	 	             dt_arr          : fltarr(n_e)             , $  ; weighting array for summing bins
                     nenergy         : n_e                     , $  ; number of energies
                     energy          : fltarr(n_e)             , $  ; energy sweep
		             denergy         : fltarr(n_e)             , $  ; energy widths for each energy/angle bin
		             eff             : fltarr(n_e)             , $  ; MCP efficiency
                     gf              : fltarr(n_e)             , $  ; geometric factor
                     dtc             : fltarr(n_e)             , $  ; dead time correction
                     sc_pot          : 0.                      , $  ; spacecract potential
                     magf            : fltarr(3)               , $  ; magnetic field
                     bkg             : 0.                      , $  ; background
                     data            : fltarr(n_e)                }

; Define Magnetic Field data structure

  swe_mag_struct = {project_name    : 'MAVEN'                 , $
                    data_name       : 'SWEA PAD MAG'          , $
                    units_name      : 'nT'                    , $
                    frame           : 'swea'                  , $
                    valid           : 0B                      , $
                    time            : 0D                      , $  ; unix time
                    Bamp            : 0.                      , $  ; amplitude (nT)
                    Bphi            : 0.                      , $  ; SWEA azimuth (radians)
                    Bthe            : 0.                      , $  ; SWEA elevation (radians)
                    magf            : fltarr(3)                  } ; vector in SWEA coord. (nT)

; Define Spacecraft Potential data structure

  swe_pot_struct = {project_name    : 'MAVEN'                 , $
                    data_name       : 'SWEA SC POT'           , $
                    units_name      : 'V'                     , $
                    valid           : 0B                      , $
                    time            : 0D                      , $  ; unix time
                    potential       : 0.                         } ; spacecraft potential (V)

  return

end
