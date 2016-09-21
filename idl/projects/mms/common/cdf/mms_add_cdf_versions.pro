;+
; PROCEDURE:  
;       mms_add_cdf_versions
;       
; PURPOSE:
;       Adds MMS CDF version #s to plots (for version tracking)
;       
; INPUT:
;       instrument: name of the instrument that we're adding the version #s for
;       versions: [n, 3] array of CDF version #s - returned by 'versions' keyword 
;           in load routines; where n is the number of CDF files loaded
; 
; KEYWORDS:
;       data_rate: include a data rate on the plot
;       
; EXAMPLE:
;       MMS> mms_load_fpi, versions=fpi_versions
;       MMS> tplot, 'mms3_des_energyspectr_par_fast'
;       MMS> mms_add_cdf_versions, 'fpi', fpi_versions
;
; NOTES:
;       Requires IDL 8.0+ to work
;       
;       
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-09-20 13:51:54 -0700 (Tue, 20 Sep 2016) $
; $LastChangedRevision: 21886 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/cdf/mms_add_cdf_versions.pro $
;-

pro mms_add_cdf_versions, instrument, versions, data_rate = data_rate
    common versionnum, versionnum_loc ; so we don't overplot the version #s for different instruments
    chsize = 1

    ; we won't include duplicate version #s
    dupekill = hash()
    for version_idx = 0, n_elements(versions[*, 0])-1 do begin
        version_str = (strcompress(string(versions[version_idx, *]), /rem)).join('.', /single)
        dupekill[version_str] = 1
    endfor
    versions_nodupes = (dupekill.keys()).toArray()
    
    yp = !y.window[0] + 0.01

    ; x-location to start printing the version # at
    versionnum_loc = undefined(versionnum_loc) ? 0.01 : versionnum_loc + 0.01

    ; create an array of version strings for this instrument
    for version_idx = 0, n_elements(versions_nodupes)-1 do append_array, version_strs, 'v' + versions_nodupes[version_idx]
    
    version_strs = version_strs[sort(version_strs)]

    plot_str = version_strs.join(', ', /single)
    plot_str = undefined(data_rate) ? strupcase(instrument) + ' ' + plot_str : strupcase(instrument) + ' ' + data_rate + ' ' + plot_str
    
    xyouts,versionnum_loc,yp,plot_str,charsize=chsize,/norm
    
    len_in_px = strlen(plot_str)*!d.x_ch_size
    
    versionnum_loc += len_in_px/float(!d.x_size)
end