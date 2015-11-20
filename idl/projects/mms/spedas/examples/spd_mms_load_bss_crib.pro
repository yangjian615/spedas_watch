;+
; spd_mms_load_bss_crib  
;
; do you have suggestions for this crib sheet?
;   please send them to egrimes@igpp.ucla.edu
;
; See also "spd_mms_load_bss", "mms_load_bss", and "mms_load_bss_crib".
;

; set time range 
timespan, '2015-10-01', 1d

; get data availability for burst and survey data (note that the labels flag
; is set so that the display bars will be labeled)
spd_mms_load_bss, datatype='burst', /include_labels
spd_mms_load_bss, datatype='fast', /include_labels

; plot bars only
tplot, ['mms_bss_burst','mms_bss_fast']
stop

; now plot bars with some data 
sc='mms3'
mms_sitl_get_dfg,sc=sc
options,sc+'_dfg_srvy_gsm_dmpa',constant=0,colors=[2,4,6],ystyle=1,yrange=[-100,100]
mms_sitl_get_fpi_basic, sc=sc
options,sc+'_fpi_iEnergySpectr_omni',spec=1,ylog=1,zlog=1,yrange=[10,26000],ystyle=1
tplot,[sc+'_dfg_srvy_gsm_dmpa','mms_bss_fast','mms_bss_burst',sc+'_fpi_iEnergySpectr_omni']
stop

; Get all BSS data types (Fast, Burst, Status, and FOM)
; if no data type is provided all data types will be returned
spd_mms_load_bss, /include_labels
; plot bss bars and fom at top of plot
tplot,['mms_bss_fast','mms_bss_burst','mms_bss_status', 'mms_bss_fom', $
       sc+'_dfg_srvy_gsm_dmpa',sc+'_fpi_iEnergySpectr_omni']
stop

end
