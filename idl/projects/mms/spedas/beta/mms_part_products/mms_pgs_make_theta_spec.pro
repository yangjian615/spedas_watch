;+
;Procedure:
;  mms_pgs_make_theta_spec
;
;Purpose:
;  Builds theta (latitudinal) spectrogram from simplified particle data structure.
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
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/beta/mms_part_products/mms_pgs_make_theta_spec.pro $
;-


pro mms_pgs_make_theta_spec, data, spec=spec, yaxis=yaxis, _extra=ex

    compile_opt idl2, hidden
  
  
  if ~is_struct(data) then return
  
  
  dr = !dpi/180.
  rd = 1/dr
  
  enum = dimen1(data.energy)
  anum = dimen2(data.energy)
  ;energies = data.energy

  ;copy data and zero inactive bins to ensure
  ;areas with no data are represented as NaN
  d = data.data
  idx = where(~data.bins,nd)
  if nd gt 0 then begin
    d[idx] = 0.
  endif

  ;get start and end indices of each group of theta bins
  ; -assumes thetas already grouped together 
  ;  (but not necessarily sorted)
  ; -assumes thetas do not change with energy
  if anum gt 1 then begin
    end_idx = uniq(data.theta[0,*])
    start_idx = [0,(end_idx[0:n_elements(end_idx)-2] + 1)]
  endif else begin
    end_idx = 0
    start_idx = 0
  endelse

  ;init this sample's piece of the spectrogram
  ave = replicate(!values.f_nan, n_elements(start_idx))
  nbins = fltarr(n_elements(start_idx))
  
  ;loop over each theta to sum all active data 
  ;and bin flags for that value
  for i=0, n_elements(end_idx)-1 do begin
   ; ave[i] = total( energies*energies*d[*,start_idx[i]:end_idx[i]] )
    ave[i] = total(d[*,start_idx[i]:end_idx[i]] )
    nbins[i] = total( data.bins[*,start_idx[i]:end_idx[i]] )
  endfor

  ;divide by total active bins to get average
  ave = ave / nbins
  
  ;get values for the y axis
  y = (data.theta[0,*])[end_idx]
  
  ;sort y axis and data
  s = sort(y)
  ave = ave[s]
  y = y[s]
  

  ;set the y axis
  if undefined(yaxis) then begin
    yaxis = y
  endif else begin
    mms_pgs_concat_yaxis, yaxis, y, ns=dimen2(spec)
  endelse
  
  ;print,total(data.data),total(ave)
  
  ;concatenate spectra
  if undefined(spec) then begin
    spec = ave
  endif else begin
    mms_pgs_concat_spec, spec, ave
  endelse 
  
  
end