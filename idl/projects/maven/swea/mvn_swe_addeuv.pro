;+
;PROCEDURE:   mvn_swe_addeuv
;PURPOSE:
;  Loads EUV data and creates tplot variable using EUV code.  EUV is
;  measured in three bandpasses:
;
;                   Photon      Photoelectron
;    Wavelength		Energy		Energy (*)		Notes
;   ----------------------------------------------------------------------
;    121 nm			10.2 eV     N/A				Lyman-alpha
;    17-22 nm		56-73 eV    42-59 eV (#)
;    0.1-7 nm	    >177 eV     >163 eV			includes soft X-rays
;   ----------------------------------------------------------------------
;     * first ionization potential of CO2 is 13.77 eV
;     # "Al edge" is near 60 eV
;
;USAGE:
;  mvn_swe_addeuv
;
;INPUTS:
;    None:          Data are loaded based on timespan.
;
;KEYWORDS:
;
;    PANS:          Named variable to hold a space delimited string containing
;                   the tplot variable(s) created.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2016-03-06 15:08:29 -0800 (Sun, 06 Mar 2016) $
; $LastChangedRevision: 20338 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_addeuv.pro $
;
;CREATED BY:    David L. Mitchell  03/18/14
;-
pro mvn_swe_addeuv, pans=pans

  pans = ''
  mvn_lpw_load_l2, ['euv'], tplotvars=euv_pan, /notplot
  
  if (euv_pan[0] ne '') then begin
    for i=0,(n_elements(euv_pan)-1) do pans += euv_pan[i] + ' '
    pans = strtrim(strcompress(pans),2)

; Fix plotting options and change units (W/m2 --> mW/m2)

    epan = 'mvn_euv_calib_bands'
    get_data,epan,data=euv,index=i
    if (i gt 0) then begin
      euv.y *= 1000.
      store_data,epan,data=euv
      options,epan,'ytitle','EUV (mW/m!u2!n)'
      options,epan,'ysubtitle',''
      options,epan,'labels',['0.1-7 nm','17-22 nm','121 nm']
      options,epan,'labflag',1
      options,epan,'colors',[1,4,6]
      options,epan,'psym',0
      ylim,epan,0,0,1
    endif

  endif
  
  return
  
end
