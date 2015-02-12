
;********************************************
; This is an exampel file for the LPW software
; ;********************************************
 
 
 
 
;********************************************
; Read The CDF-files (including Level 2)  data
;********************************************
 
;Not yet working
;this is how to read the CDF filed from the LPW-team 
;the defalue is to read L2-files
;trange not working on this call
 mvn_lpw_cdf_read,'2015-01-28', vars=['wspecact','wspecpas','we12burstlf','we12burstmf','we12bursthf','wn','lpiv','lpnt','mrgexb','mrgscpot','euv','e12']

;Lines 83-84 won’t work to get data from SSL. Mvn-lpw-cdf-read-file should work by specifying directory and  filenames.
;udir = getenv('ROOT_DATA_DIR')  ;at LASP this is usually /Volumes/spg/maven/data/ or /spg/maven/data
;fbase=udir+'maven'+sl+'data'+sl+'sci'+sl   ;Need some files to test this, so it may not work yet!



 
;Mean while this is how to read them now
;presently only 'wn' products exists    the 'euv' L2-cdf files can be read with this reader too
;the location of the files needs to be explicit called out
mvn_lpw_cdf_read, dir='/Users/files/', varlist=['mvn_lpw_l2_wn_20141023_v01_r01.cdf','mvn_lpw_l2_wn_20141024_v01_r01.cdf']
 
 
tplot,'*w_n*' 
 
;********************************************
 
  

 
 
 
 
;********************************************
; Read L0 data (gett the data based ont eh data packets)
;********************************************
 
;To read the LPW data from the L0-file presently  the path to the 'mvn_lpw_software' 
; needs to explisit be called out because we have calibrations files in a subdirectory called '/mvn_lpw_cal_files/' 
 
; where the the calibration files are located
setenv, 'mvn_lpw_software=/Users/andersson/Idl/2014_maven/SVN_controlled/LDS_MAVEN_LPW/master/'    ;new server

;********************************************
 


;read L0 file alternative 1, recomended defalut setting 
;trange not working on this call
mvn_lpw_load, '2014-12-01', tplot_var='all', packet='nohsbm', /notatlasp 
 
 
;if there is an issue with finding the L0 file then use the following  
mvn_lpw_load_file,filename, tplot_var='all', filetype='L0', packet='nohsbm',board='FM'
 
 
 
 ;To look at the IV sweep Log(abs(Current)) is recomented
 
 tplot,'*log'
 
 ;to look at the raw wave spectra
 
 tplot,['mvn_lpw_spec_lf_pas','mvn_lpw_spec_mf_pas','mvn_lpw_spec_hf_pas','mvn_lpw_spec_lf_act','mvn_lpw_spec_mf_act','mvn_lpw_spec_hf_act']
 
 ;to look at the raw V1/V2 data
 
 tplot,['*V1','*V2']
 
 ;to look at the raw e12 data
 
 tplot,['*e12']
 
 ;to look at the raw euv
 
 tplot,'*euv'
 
 
 
; ;********************************************
 
  


