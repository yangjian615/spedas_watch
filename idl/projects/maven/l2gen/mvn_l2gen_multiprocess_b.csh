#!/bin/csh
# mvn_l2gen_multiprocess_b function_in nproc offset proc_workdir comment
# added offset, 2013-10-06, jmm
# get arguments
set function_in=$1
set nproc=$2
set offset=$3
set proc_workdir=$4
set comment=$5

# Set up IDL path
unsetenv IDL_PATH
source /usr/local/setup/setup_idl8.3		# IDL
setenv BASE_DATA_DIR /disks/data/
setenv THEMIS_DATA_DIR /disks/themisdata/
setenv IDL_STARTUP /home/jimm/temp_idl_startup.pro
source /home/jimm/setup_themis

setenv IDL_PATH $IDL_PATH':'+/home/jimm/idlpro/themis

# create a date to append to batch output
setenv datestr `date +%Y%m%d%H%M%S`
set line="$datestr"
# Now start a process in each directory
set i=$offset
set endproc=0
@ endproc = ( $nproc + $offset ) 
while ($i < $endproc) 
    echo $i
    cd $proc_workdir/$function_in$i
    if (-e $function_in'_lock') then
	echo $proc_workdir/$function_in$i/$function_in'_lock' Exists
    else
        rm -rf $function_in.out
        idl $function_in.pro > $function_in.out &
    endif
    @ i = ($i + 1)
end
cd $proc_workdir
