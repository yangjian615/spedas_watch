;20170126 Ali
;Pickup ion code common blocks
;pui:  model-data structure
;pui0: instrument constants
;pui1: energy tables
;pui2: temporary variables
; 
common mvn_pui_com,pui,pui0,pui1,pui2

;instrument constants >>> now in pui0,pui1
;common mvn_pui_com0,srmd,sopeb,swieb,staeb,sweeb,toteb,euvwb,swina,swine,$
;                   swiatsa,swidee,stadee,swedee,totdee,totet,swiet,staet,sweet

;temporary common block >>> now in pui2
;common mvn_pui_com1,r3x,r3y,r3z,v3x,v3y,v3z,vxyz,rxyz,drxyz,ke,de,mv

;SWIA common block
common mvn_swia_data,info_str,swihsk,swics,swica,swifs,swifa,swim,swis

;SWEA common block
@mvn_swe_com 
                
;STATIC common block
common mvn_c0,mvn_c0_ind,mvn_c0_dat
common mvn_d0,mvn_d0_ind,mvn_d0_dat
common mvn_d1,mvn_d1_ind,mvn_d1_dat