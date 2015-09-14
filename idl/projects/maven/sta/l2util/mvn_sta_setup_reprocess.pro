nproc = 2
time_range = dblarr(2, nproc)
time_range[*, 0] = time_double(['2014-09-22', '2015-03-01'])
time_range[*, 1] = time_double(['2015-03-01', '2015-07-27'])
file_copy, '/home/muser/export_socware/idl_socware/projects/maven/sta/l2util/mvn_sta_l2gen_1day.pro', '/mydisks/home/maven/mvn_sta_l2gen_1day.pro', /overwrite
mvn_l2gen_multiprocess_a, 'mvn_sta_l2gen_1day', nproc, 0, time_range, '/mydisks/home/maven/'

End

