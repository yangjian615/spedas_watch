;+
;PROCEDURE:   mvn_swe_stat
;PURPOSE:
;  Reports the status of SWEA data loaded into the common block.
;
;USAGE:
;  mvn_swe_stat
;
;INPUTS:
;
;KEYWORDS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2014-05-13 20:40:10 -0700 (Tue, 13 May 2014) $
; $LastChangedRevision: 15118 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_stat.pro $
;
;CREATED BY:    David L. Mitchell  07-24-12
;-
pro mvn_swe_stat

  @mvn_swe_com
  
  if (data_type(swe_hsk) eq 8) then n_hsk = n_elements(swe_hsk) else n_hsk = 0L
  if (data_type(swe_3d) eq 8) then n_a0 = n_elements(swe_3d) else n_a0 = 0L
  if (data_type(swe_3d_arc) eq 8) then n_a1 = n_elements(swe_3d_arc) else n_a1 = 0L
  if (data_type(a2) eq 8) then n_a2 = n_elements(a2) else n_a2 = 0L
  if (data_type(a3) eq 8) then n_a3 = n_elements(a3) else n_a3 = 0L
  if (data_type(a4) eq 8) then n_a4 = n_elements(a4) else n_a4 = 0L
  if (data_type(a5) eq 8) then n_a5 = n_elements(a5) else n_a5 = 0L
  if (data_type(a6) eq 8) then n_a6 = n_elements(a6) else n_a6 = 0L

  print,""
  print,"SWEA Common Block:"
  print,n_hsk," Housekeeping packets (normal)"
  print,n_a6," Housekeeping packets (fast)"
  print,n_a0," 3D distributions (survey)"
  print,n_a1," 3D distributions (archive)"
  print,n_a2," PAD distributions (survey)"
  print,n_a3," PAD distributions (archive)"
  print,n_a4*16," ENGY Spectra (survey)"
  print,n_a5*16," ENGY Spectra (archive)"
  print,mvn_swe_tabnum(swe_active_chksum),format='("Sweep Table: ",i2)'
  print,""

  return

end
