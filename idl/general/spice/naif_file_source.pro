function naif_file_source

source = file_retrieve(/struct)
source.remote_data_dir = 'http://naif.jpl.nasa.gov/pub/naif/'
source.local_data_dir  += 'misc/spice/naif/'
source.archive_ext = '.arc'
source.archive_dir = 'archive/'
source.min_age_limit=2d*3600   ; age in seconds.
;ascii mode not set
source.verbose=2

return,source
end
