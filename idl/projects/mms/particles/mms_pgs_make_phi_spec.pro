;+
;Procedure:
;  mms_pgs_make_phi_spec
;
;Purpose:
;  Builds phi (longitudinal) spectrogram from simplified particle data structure.
;
;
;Input:
;  data: single sanitized data structure
;  
;
;Input/Output:
;  spec: The spectrogram (ny x ntimes)
;  yaxis: The y axis (ny OR ny x ntimes)
;  
;  -Each time this procedure runs it will concatenate the sample's data
;   to the SPEC variable.
;  -Both variables will be initialized if not set
;  -The y axis will remain a single dimension until a change is detected
;   in the data, at which point it will be expanded to two dimensions.
;
;
;Notes:
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-06-22 18:24:56 -0700 (Thu, 22 Jun 2017) $
;$LastChangedRevision: 23500 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/particles/mms_pgs_make_phi_spec.pro $
;-

pro mms_pgs_make_phi_spec, data, spec=spec, sigma=sigma, yaxis=yaxis, _extra=ex

  compile_opt idl2, hidden
  
  if ~is_struct(data) then return
  
  ;copy data and zero inactive bins to ensure
  ;areas with no data are represented as NaN
  d = data.data
  ;  scaling = data.scaling
  idx = where(~data.bins,nd)
  if nd gt 0 then begin
    d[idx] = 0.
  endif
  
  ave = dblarr(32)

  outbins = 360.*indgen(32+1)/32

  for tidx = 0, n_elements(data.phi[*, 0])-1 do begin
    for bin_idx = 0, n_elements(outbins)-2 do begin
      this_bin = where(data.phi[tidx, *] ge outbins[bin_idx] and data.phi[tidx, *] lt outbins[bin_idx+1], bcount)
      if bcount ne 0 then begin
        ave[bin_idx] += total(d[tidx, this_bin])/total(data.bins[tidx, this_bin])
      endif
    endfor
  endfor
  
  ;get y axis
  y = bin_centers(outbins)
  
  ;concatenate y axes
  if undefined(yaxis) then begin
    yaxis = y
  endif else begin
    spd_pgs_concat_yaxis, yaxis, y, ns=dimen2(spec)
  endelse

  ;concatenate spectra
  if undefined(spec) then begin
    spec = temporary(ave)
  endif else begin
    spd_pgs_concat_spec, spec, ave
  endelse

end