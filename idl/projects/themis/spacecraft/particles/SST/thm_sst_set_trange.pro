;+
;Procedure:
;  thm_sst_set_trange
;
;Purpose:
;  Helper function for thm_load_sst.
;  Sets the common block time ranges for applicable data types.
;
;Input:
;  cache: SST data pointer structure from thm_load_sst
;  trange: two element time range
;
;Output:
;  none
;
;Notes:
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2014-02-24 18:01:17 -0800 (Mon, 24 Feb 2014) $
;$LastChangedRevision: 14422 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/SST/thm_sst_set_trange.pro $
;
;-
pro thm_sst_set_trange, cache, trange=trange

    compile_opt idl2, hidden

  
  probe = cache.sc_name

  ;use same default as file_dailynames if not explicitly set
  if undefined(trange) then trange = timerange()

  ;psif
  if ptr_valid(cache.sif_064_time) then begin
    thm_part_trange, probe, 'psif', set=trange
  endif
  
  ;psir
  if ptr_valid(cache.sir_001_time) or ptr_valid(cache.sir_006_time) then begin
    thm_part_trange, probe, 'psir', set=trange
  endif
  
  ;psef
  if ptr_valid(cache.sef_064_time) then begin
    thm_part_trange, probe, 'psef', set=trange
  endif
  
  ;pser
  if ptr_valid(cache.ser_001_time) or ptr_valid(cache.ser_006_time) then begin
    thm_part_trange, probe, 'pser', set=trange
  endif
  
  ;pseb
  if ptr_valid(cache.seb_064_time) then begin
    thm_part_trange, probe, 'pseb', set=trange
  endif

  

end