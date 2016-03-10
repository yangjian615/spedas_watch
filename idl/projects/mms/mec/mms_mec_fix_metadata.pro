;+
; PROCEDURE:
;         mms_mec_fix_metadata
;
; PURPOSE:
;         Helper routine for setting metadata of MEC variables
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-03-08 18:54:35 -0800 (Tue, 08 Mar 2016) $
;$LastChangedRevision: 20361 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/mec/mms_mec_fix_metadata.pro $
;-

pro mms_mec_fix_metadata, probe
    probe = strcompress(string(probe), /rem)
    position_vars = tnames('mms'+probe+'_mec_r_*')
    velocity_vars = tnames('mms'+probe+'_mec_v_*')

    for pos_idx = 0, n_elements(position_vars)-1 do begin
        options, position_vars[pos_idx], colors=[2, 4, 6]
    endfor
    for vel_idx = 0, n_elements(velocity_vars)-1 do begin
        options, velocity_vars[vel_idx], colors=[2, 4, 6]
    endfor
end