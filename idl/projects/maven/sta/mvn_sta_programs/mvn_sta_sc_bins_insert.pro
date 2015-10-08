;+
; FUNCTION:        MVN_STA_SC_BINS_INSERT
;
; PURPOSE:         Insert s/c blockage into new data structure
;
; INPUT:           orig_dat - data structure containing spacecraft
;                             blockage
;                  new_dat  - new data structure containig data with
;                             spacecraft blockage removed
;
; OUTPUT:          None.
;
; KEYWORDS:        None.
;
; CREATED BY:      Roberto Livi on 2015-10-07.
;
; VERSION:


pro mvn_sta_sc_bins_insert, orig_dat, new_dat

  ;;-------------------------------------------
  ;; Copy over old structure into new structure
  new_dat = orig_dat

  ;;-------------------------------------------
  ;; Fill in new structure with blockage
  ss = size(orig_dat)
  if ss[2] eq 8 then begin
     ss   = size(orig_dat.data)
     bins = orig.bins_sc
     bins = transpose(rebin(bins, ss[1],ss[3],ss[2]),[0,2,1])
     new_dat.data = orig_dat.data * bins
  endif

end




