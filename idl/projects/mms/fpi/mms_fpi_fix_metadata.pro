;+
; PROCEDURE:
;         mms_fpi_fix_metadata
;
; PURPOSE:
;         Helper routine for setting FPI metadata. Original metadata from L2 QL plots script
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-02-26 12:42:55 -0800 (Fri, 26 Feb 2016) $
;$LastChangedRevision: 20214 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/fpi/mms_fpi_fix_metadata.pro $
;-

pro mms_fpi_fix_metadata, tplotnames, prefix = prefix, instrument = instrument, data_rate = data_rate, suffix = suffix, level=level
    if undefined(prefix) then prefix = ''
    if undefined(suffix) then suffix = ''
    if undefined(level) then level = ''
    if undefined(data_rate) then data_rate = 'fast'


    for sc_idx = 0, n_elements(prefix)-1 do begin
      for name_idx = 0, n_elements(tplotnames)-1 do begin
        tplot_name = tplotnames[name_idx]
        case tplot_name of
          prefix[sc_idx] + '_des_numberdensity_dbcs_'+data_rate+suffix: begin
            options, /def, tplot_name, 'colors', 2
            options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!CDES'
            options, /def, tplot_name, 'labels', 'Ne, electrons'
          end
          prefix[sc_idx] + '_dis_numberdensity_dbcs_'+data_rate+suffix: begin
            options, /def, tplot_name, 'colors', 4
            options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!CDIS'
            options, /def, tplot_name, 'labels', 'Ni, ions'
          end
          prefix[sc_idx] + '_des_bulkx_dbcs_'+data_rate+suffix: begin
            options, /def, tplot_name, 'labels', 'Vx'
            options, /def, tplot_name, 'colors', 2
            options, /def, tplot_name, 'labflag', -1
            options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!CDES velocity'
          end
          prefix[sc_idx] + '_des_bulky_dbcs_'+data_rate+suffix: begin
            options, /def, tplot_name, 'labels', 'Vy'
            options, /def, tplot_name, 'colors', 4
            options, /def, tplot_name, 'labflag', -1
            options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!CDES velocity'
          end
          prefix[sc_idx] + '_des_bulkz_dbcs_'+data_rate+suffix: begin
            options, /def, tplot_name, 'labels', 'Vz'
            options, /def, tplot_name, 'colors', 6
            options, /def, tplot_name, 'labflag', -1
            options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!CDES velocity'
          end
          prefix[sc_idx] + '_dis_bulkx_dbcs_'+data_rate+suffix: begin
            options, /def, tplot_name, 'labels', 'Vx'
            options, /def, tplot_name, 'colors', 2
            options, /def, tplot_name, 'labflag', -1
            options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!CDIS velocity'
          end
          prefix[sc_idx] + '_dis_bulky_dbcs_'+data_rate+suffix: begin
            options, /def, tplot_name, 'labels', 'Vy'
            options, /def, tplot_name, 'colors', 4
            options, /def, tplot_name, 'labflag', -1
            options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!CDIS velocity'
          end
          prefix[sc_idx] + '_dis_bulkz_dbcs_'+data_rate+suffix: begin
            options, /def, tplot_name, 'labels', 'Vz'
            options, /def, tplot_name, 'colors', 6
            options, /def, tplot_name, 'labflag', -1
            options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!CDIS velocity'
          end
          prefix[sc_idx] + '_des_temppara_'+data_rate+suffix: begin
            options, /def, tplot_name, 'labels', 'Te, para'
            options, /def, tplot_name, 'colors', 2
            options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!CTemp'
          end
          prefix[sc_idx] + '_des_tempperp_'+data_rate+suffix: begin
            options, /def, tplot_name, 'labels', 'Te, perp'
            options, /def, tplot_name, 'colors', 4
            options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!CTemp'
          end
          prefix[sc_idx] + '_dis_temppara_'+data_rate+suffix: begin
            options, /def, tplot_name, 'labels', 'Ti, para'
            options, /def, tplot_name, 'colors', 6
            options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!CTemp'
          end
          prefix[sc_idx] + '_dis_tempperp_'+data_rate+suffix: begin
            options, /def, tplot_name, 'labels', 'Ti, perp'
            options, /def, tplot_name, 'colors', 8
            options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!CTemp'
          end
          else: ; not doing anything
        endcase
      endfor
    endfor
end