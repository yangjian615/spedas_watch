function mav_file_source,def_source

if  keyword_set(def_source) then source = def_source else begin
  source = file_retrieve(/struc)
  source.remote_data_dir = 'http://sprg.ssl.berkeley.edu/data/'
  if file_test(source.local_data_dir+'maven/.master',/regular) then source.no_download =1
;  source.no_clobber = 1   ; safety net for now
  source.verbose=2
  source.min_age_limit=300
;  source.no_clobber=1
;  source.
endelse

return,source
end
