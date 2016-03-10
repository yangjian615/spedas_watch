;+
;Procedure:
;  mms_cotrans_crib
;
;Purpose:
;  Demonstrate usage of mms_cotrans.
;
;Notes:
;  
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-03-09 13:10:32 -0800 (Wed, 09 Mar 2016) $
;$LastChangedRevision: 20374 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/mms_cotrans_crib.pro $
;-


;------------------------------------------------------
;  Supported coordinate systems:
;    -DMPA
;    -DSL  (currently treated as identical to DMPA)
;    -GSE
;    -GSM
;    -AGSM
;    -SM
;    -GEI
;    -J2000
;    -GEO
;    -MAG
;----------------------------------------------------

;setup
probe = '1'
level = 'l2'

timespan, '2015-12-01/01', 2, /hour
trange = timerange()

; load data
mms_load_fgm, probe=probe, trange=trange, level=level
mms_load_fpi, probe=probe, trange=trange, level=level, datatype=['dis-moms']

; load support data for transformations
mms_load_mec, probe=probe, trange=trange

; example variables to be transformed
v_name = 'mms'+probe+'_dis_bulk'
b_name = 'mms'+probe+'_fgm_b_dmpa_srvy_l2_bvec'

; join components of velocity into single 3-vector
join_vec, v_name+['x','y','z']+'_dbcs_fast', v_name

; fix labels
options, b_name, labels='B'+['x','y','z']
options, v_name, labels='V'+['x','y','z']

; transform to GSE
;   -in_coord and ignore_dlimits keywords will be necessary until 
;    the metadata's coordinates are populated from the CDF
mms_cotrans, [v_name,b_name], out_coord='gse', out_suffix='_gse', $
             in_coord='dmpa', /ignore_dlimits

; set metadata for GSE data
options, b_name+'_gse', ytitle='MMS'+probe+'!CFGM'
options, b_name+'_gse', labels='B'+['x','y','z']+' GSE'
options, v_name+'_gse', labels='V'+['x','y','z']+' GSE'

window, xs=900, ys=900

tplot, [v_name, v_name, b_name, b_name] + ['','_gse','','_gse']

stop ;------------------------------------------------------------

; transform to SM
;   -in_coord and ignore_dlimits keywords will be necessary until 
;    the metadata's coordinates are populated from the CDF
mms_cotrans, [v_name,b_name], out_coord='sm', out_suffix='_sm', $
             in_coord='dmpa', /ignore_dlimits

; set metadata for SM data
options, b_name+'_sm', labels='B'+['x','y','z']+' SM'
options, v_name+'_sm', labels='V'+['x','y','z']+' SM'
           
tplot, [v_name, v_name, b_name, b_name] + ['','_sm','','_sm']

stop ;------------------------------------------------------------

; use IN_SUFFIX keyword to replace the current suffix
;   -transformed variables will have correct metadata
mms_cotrans, b_name, out_coord='gsm', in_suffix='_sm', out_suffix='_gsm'

; set metadata for SM data
options, b_name+'_gsm', labels='B'+['x','y','z']+' GSM'

tplot, b_name + ['','_sm','_gsm']

stop ;------------------------------------------------------------

; in/out coordinates can be set implicitly with suffix keywords
mms_cotrans, v_name, in_suffix='_sm', out_suffix='_gsm'

tplot, v_name + ['','_sm','_gsm']

end