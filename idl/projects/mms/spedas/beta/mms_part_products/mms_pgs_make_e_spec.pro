
;+
;Procedure:
;  mms_pgs_make_e_spec
;
;Purpose:
;  Builds energy spectrogram from simplified particle data structure.
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
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2015-12-11 14:25:49 -0800 (Fri, 11 Dec 2015) $
;$LastChangedRevision: 19614 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/beta/mms_part_products/mms_pgs_make_e_spec.pro $
;-

pro mms_pgs_make_e_spec, data, spec=spec,  yaxis=yaxis, _extra=ex

    compile_opt idl2, hidden
  
  
  if ~is_struct(data) then return
  
  
  dr = !dpi/180.
  
  enum = dimen1(data.energy)
  anum = dimen2(data.energy)

  ;copy data and zero inactive bins to ensure
  ;areas with no data are represented as NaN
  d = data.data
  idx = where(~data.bins,nd)
  if nd gt 0 then begin
    d[idx] = 0.
  endif
  
  ;weighted average to create spectrogram piece
  ;energies with no valid data should come out as NaN
  if anum gt 1 then begin
    ave = total(d,2) / total(data.bins,2)
  endif else begin
    ave = d / data.bins
  endelse
  
  ;output the y-axis values
  ; *check for varying energy levels?
  y = data.energy[*,0]
  
  
  ;set y axis
  if undefined(yaxis) then begin
    yaxis = y
  endif else begin
    mms_pgs_concat_yaxis, yaxis, y, ns=dimen2(spec)
  endelse
  
  
  ;concatenate spectra
  if undefined(spec) then begin
    spec = temporary(ave)
  endif else begin
    mms_pgs_concat_spec, spec, ave
  endelse 
  
 
  
end