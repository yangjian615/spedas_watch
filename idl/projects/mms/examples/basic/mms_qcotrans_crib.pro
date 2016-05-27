;+
;Procedure:
;  mms_cotrans_crib
;
;Purpose:
;  Demonstrate usage of mms_cotrans and mms_qcotrans.
;
;Notes:
;  See also: mms_cotrans_crib
;  
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-05-25 18:22:33 -0700 (Wed, 25 May 2016) $
;$LastChangedRevision: 21214 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_qcotrans_crib.pro $
;-


;------------------------------------------------------
;  MMS_QCOTRANS Supported coordinate systems:
;    -BCS
;    -DBCS
;    -DMPA
;    -SMPA
;    -DSL
;    -SSL
;    -GSE
;    -GSE2000
;    -GSM
;    -SM
;    -GEO
;    -ECI
;    -J2000 (identical to ECI)
;
;;  MMS_COTRANS Supported coordinate systems:
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
;  
;  Aside from the differences in supported coordinate systems, 
;  usage of the two routines is interchangeable.
;
;------------------------------------------------------



;------------------------------------------------------
; Load data & setup tplot variables 
;------------------------------------------------------
probe = '1'
level = 'l2'

timespan, '2015-10-16/12', 2, /hour
trange = timerange()

; load quaternions
mms_load_mec, probe=probe, trange=trange, varformat='*_quat_*'

; load data to be transformed
mms_load_fgm, probe=probe, trange=trange, level=level, varformat='*_b_*'
mms_load_fpi, probe=probe, trange=trange, level=level, datatype=['dis-moms'], varformat='*_bulk?_*'

; example variables to be transformed
v_name = 'mms'+probe+'_dis_bulk'
b_name = 'mms'+probe+'_fgm_b_dmpa_srvy_l2_bvec'

; join components of velocity into single 3-vector
join_vec, v_name+['x','y','z']+'_dbcs_fast', v_name

; add coordinates to labels
; the labels will be automatically updated when transformed
options, v_name, labels='V'+['x','y','z']+' dbcs'
options, b_name, labels='B'+['x','y','z']+' dmpa'

;taller plot window
window, xs=900, ys=900

;------------------------------------------------------
; Implicit transformations
;  -Input/output coordinates can be specified with IN/OUT_SUFFIX keywords
;  -Input coordinates can be omitted when metadata is present
;------------------------------------------------------

; transform to GSE
mms_qcotrans, [v_name, b_name], out_suffix='_gse'

tplot, [v_name, v_name, b_name, b_name] + ['','_gse','','_gse']

stop


;------------------------------------------------------
; Specify input suffix
;  -Replaces current suffix with that of new coordinates
;  -If any inputs' metadata do not match explicit input coordinates
;   then the transformation will be skipped
;------------------------------------------------------

; transform both _GSE variables to _SM
; note that input names do not include the _gse suffix
mms_qcotrans, [v_name, b_name], in_suffix='_gse', out_suffix='_sm'

tplot, [v_name, v_name, b_name, b_name] + ['_gse','_sm','_gse','_sm']

stop


;------------------------------------------------------
; Explicit transformations
;  -input/output coordinates can be specified independent of suffixes
;  -if metadata is incorrect or not present then use /IGNORE_DLIMITS to ignore
;------------------------------------------------------

; transform both original variables as though they are both in DMPA coordinates
; use /ignore_dlimits to ignore metadata for dbcs velocity
mms_qcotrans, [v_name,b_name], in_coord='dmpa', out_coord='gse', $
              out_suffix='_pseudo_gse', /ignore_dlimits

;labels will not be automatically updated when /ignore_dlimits is set
options, b_name+'_pseudo_gse', labels='B'+['x','y','z']+' "GSE"'
options, v_name+'_pseudo_gse', labels='V'+['x','y','z']+' "GSE"'      

; plot against real gse
; b field will be identical, velocity should be nearly identical
tplot, [v_name, v_name, b_name, b_name] + ['_gse','_pseudo_gse','_gse','_pseudo_gse']

stop


;------------------------------------------------------
; Specify full output name
;  -a second argument can be used to specify a full name for the output variable
;------------------------------------------------------

mms_qcotrans, v_name, 'v_gse2k', out_coord='gse2000'
mms_qcotrans, b_name, 'b_gse2k', out_coord='gse2000'

tplot, [v_name,'v_gse2k',b_name,'b_gse2k']




end