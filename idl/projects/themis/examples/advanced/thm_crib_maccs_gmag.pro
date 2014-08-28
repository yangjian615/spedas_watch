;+
; This crib sheet gives examples of how to plot magnetometer data from
; the Magnetometer Array for Cusp and Cleft Studies (MACCS), an array of
; magnetometers in Arctic Canada run by Augsburg College and Boston
; University. Further details of the MACCS array can be found in:
; "W. J. Hughes and M. J. Engebretson, MACCS: Magnetometer Array for Cusp
; and Cleft Studies, in Satellite-Ground Based Coordination Sourcebook,
; (eds. M. Lockwood, M.N. Wild H. J. Opgenoorth), ESA-SP-1198, pp. 119-130, 1997."
;
; If these data are used in a publication, you must acknowledge the source:
; "Acknowledgement: MACCS magnetometer data were provided by Mark Engebretson,
; Augsburg College"

; To access these data, simply use the program thm_load_gmag.
;
; Copy and paste selected lines from this crib to an IDL window.
; 
; For example,

thm_load_gmag, trange = ['2009-01-01', '2009-01-02']
;tplot, 'thg_mag_*'

; loads all sites for 1-jan-2009, including the MACCS stations. The
; MACCS sites are handled in the same way as the other GMAG sites.
; The valid site names for the MACCS data are:
;
;        ['cdrt','crvr','gjoa','rbay','pang','nain','iglo']
;
; corresponding to:
;
;        ['Cape Dorset', 'Clyde River', 'Gjoa Haven', 'Repulse Bay',$
;         'Pangnirtung', 'Nain', 'Igloolik']
;
; To load only MACCS stations, use the keyword, /maccs_sites e.g.
thm_load_gmag, trange = ['2010-12-01', '2010-12-02'], /maccs_sites
;This will load all the MACCS stations that have data available on 1-dec-2010
tplot, 'thg_mag_*'
;
;
; To get data for individual sites, use the site keyword.
;
; For example,

thm_load_gmag, trange = ['2009-01-01', '2009-01-02'], site = ['cdrt','gjoa']
split_vec, 'thg_mag_cdrt'
split_vec, 'thg_mag_gjoa'
tplot,'thg_mag_cdrt* thg_mag_gjoa*'


; The other keyword inputs for thm_load_gmag,
; (/subtract_average, /subtract_median, /valid_names, etc...) still
; work. See THM_CRIB_GMAG in this directory for examples.


End


