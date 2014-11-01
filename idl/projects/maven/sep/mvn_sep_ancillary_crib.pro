
; choose a time range
tr = ['2014-10-06','2014-10-06:00:30']
time_valid = spice_valid_times (tr)

; load the kernels
maven_kernels = mvn_spice_kernels(trange = tr,/load,/valid) 

; create the ancillary data structure
sep_ancillary = mvn_sep_anc_data(tr=tr,maven_kernels=maven_kernels)

; optionally save it in IDL save-restore format
save, sep_ancillary, file = '~/work/maven/data_analysis/SEP_ancillary_data_20140922_20141028.sav'

plot,sep_ancillary[*].look_direction_MSO_SEP1_forward[0]

file = '~/work/maven/data_analysis/SEP_ancillary_test_file_a.cdf'

; make the CDF file
mvn_sep_anc_make_cdf, sep_ancillary,dependencies=dependencies, file = file, data_version = data_version


; read the CDF file back into an IDL data structure
mvn_sep_anc_read_cdf, file, SEP_ancillary = SEP_ancillarya

