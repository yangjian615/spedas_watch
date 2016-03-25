;+
;Procedure:
;  thm_crib_part_products_ncount
;
;Purpose:
;  Demonstrate removal of one count level from particle spectrograms.
;
;Notes:
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-03-24 10:39:15 -0700 (Thu, 24 Mar 2016) $
;$LastChangedRevision: 20581 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_part_products_ncount.pro $
;-

probe='a'
datatype='peif'
trange=['2008-02-23','2008-02-24']
timespan,trange

n_counts = 1.

;load data into structures
data = thm_part_dist_array(probe=probe,trange=trange,datatype=datatype)

;make a copy and set all samples to 1 count per bin (units are counts by default)
thm_part_copy, data, data_n
thm_part_set_counts, data_n, n_counts

;create eflux spectrograms with orignal data and one-count data
thm_part_products, dist_arr=data, suffix='_orig', units='eflux'
thm_part_products, dist_arr=data_n, suffix='_n', units='eflux'

;subtract one-count spectrogram from original data
;  -make sure data remains > 0 
name = 'th'+probe+'_'+datatype+'_eflux_energy'
calc, ' "'+name+'" = "'+name+'_orig" - "'+name+'_n" > 0' 

;plot original vs subtracted
tplot, name + ['_orig','']

end