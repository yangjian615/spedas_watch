;+
;pro thm_sst_crib
; This is an example crib sheet that will load Solid State Telescope data.
; Open this file in a text editor and then use copy and paste to copy
; selected lines into an idl window. Or alternatively compile and run
; using the command:
; .RUN THM_SST_CRIB
;Author: Davin Larson
;
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2013-12-05 17:37:51 -0800 (Thu, 05 Dec 2013) $
; $LastChangedRevision: 13648 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/basic/thm_crib_sst.pro $
;-
;

trange = ['2010-06-05','2010-06-06']

;set the date and duration (in days)
timespan,trange

;set the spacecraft
probe = 'c'

;set the datatype

datatype = 'psif' ;(psef for electrons, psib/pseb for burst mode, psir/pser for reduced mode)

;loads particle data for data type
thm_part_load,probe=probe,datatype=datatype 

;calculate derived products
thm_part_products,probe=probe,datatype=datatype,trange=trange,outputs =['energy','theta','phi','moments']

;view the loaded data names
tplot_names

;plot the energy spectrogram, and angular spectrograms(despun spacecraft coordinates (DSL))
tplot,['thc_psif_eflux_energy','thc_psif_eflux_theta','thc_psif_eflux_phi','thc_psif_density']



end
