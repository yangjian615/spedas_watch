nproc = 2
time_range = dblarr(1, nproc)
time_range[*, 0] = time_double(['2013-12-04', '2014-05-01'])
time_range[*, 1] = time_double(['2014-05-01', '2014-07-18'])
file_copy, '/home/jimm/themis_sw/projects/maven/sta/l2util/mvn_sta_l2gen_1day.pro', '/mydisks/home/maven/mvn_sta_l2gen_1day.pro', /overwrite
mvn_l2gen_multiprocess_a, 'mvn_sta_l2gen_1day', nproc, 0, time_range, '/mydisks/home/maven/'

End

