function goes_check_config,goes_params,changed
old_lcl_dir=goes_params.local_data_dir
goes_params.local_data_dir=goes_fixpath(old_lcl_dir)
old_rmt_dir=goes_params.remote_data_dir
goes_params.remote_data_dir=goes_fixpath(old_rmt_dir)
changed=0
if (old_lcl_dir NE goes_params.local_data_dir) then changed=1
if (old_rmt_dir NE goes_params.remote_data_dir) then changed=1
return, goes_params
end
