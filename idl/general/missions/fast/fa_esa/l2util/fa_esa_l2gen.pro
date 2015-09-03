;+
;NAME:
; fa_esa_l2gen
;PURPOSE:
; Generates FAST ESA L2 files
;CALLING SEQUENCE:
; fa_esa_l2gen, orbit
;KEYWORDS:
; local_data_dir = if set, then write files in orbit directories under
;                  local_data_dir/fast/l2 , the default is to
;                  use ROOT_DATA_DIR, /disks/data
;INPUT:
; Either the date or input L0 file, via keyword:
;HISTORY:
; 2015-09-02, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2015-09-02 13:24:36 -0700 (Wed, 02 Sep 2015) $
; $LastChangedRevision: 18694 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/fast/fa_esa/l2util/fa_esa_l2gen.pro $
;-
Pro fa_esa_l2gen, orbit, local_data_dir = local_data_dir, _extra = _extra


;Run in Z buffer
  set_plot,'z'

  load_position = 'init'
  catch, error_status
  
  if error_status ne 0 then begin
     print, '%FA_ESA_L2GEN: Got Error Message'
     help, /last_message, output = err_msg
     For ll = 0, n_elements(err_msg)-1 Do print, err_msg[ll]
     case load_position of
        'init':begin
           print, 'Problem with initialization'
           goto, skip_eeb
        end
        'ies':begin
           print, 'Problem in '+load_position
           goto, skip_ies
        end
        'ees':begin
           print, 'Problem in '+load_position
           goto, skip_ees
        end
        'ieb':begin
           print, 'Problem in '+load_position
           goto, skip_ieb
        end
        'eeb':begin
           print, 'Problem in '+load_position
           goto, skip_eeb
        end
        else: goto, skip_eeb
     endcase
  endif
  
  If(keyword_set(local_data_dir)) Then ldir = local_data-dir $
  Else Begin
     If(~is_string(getenv('ROOT_DATA_DIR'))) Then Begin
        ldir = root_data_dir()
     Endif Else ldir = getenv('ROOT_DATA_DIR')
  Endelse

  sw_vsn = fa_esa_current_sw_version()
  vxx = 'v'+string(sw_vsn, format='(i2.2)')

;handle orbit string
  orbit = long(orbit[0])
  orbit_str = strcompress(string(orbit,format='(i05)'), /remove_all)
  orbit_dir = strmid(orbit_str,0,2)+'000'
;Unlike L1 files, we put the date in L2 files
  dtemp = fa_orbit_to_time(orbit)
  date = time_string(dtemp[1], tformat='YYYYMMDD')
;For each type, create and output the L2 structure, not in a loop
;because of the way the catch is implemented
  type = 'ies'
  fa_create_l2, type = type, orbit = orbit, data_struct = dat
  If(is_struct(dat)) Then Begin
     fa_esa_cmn_l2gen, dat, esa_type = type, otp_struct = otp_struct, fullfile_out =  fullfile
     If(~is_struct(otp_struct)) Then message, type+' Write to CDF failed: orbit'+strcompress(/remove_all, string(orbit))
  Endif Else Begin
     message, type+' L2 generation failed: orbit'+strcompress(/remove_all, string(orbit))
  Endelse
;move the file into the correct database directory
  relpathname='l2/'+type+'/'+orbit_dir+'/fa_l2_'+type+'_'+date+'_'+orbit_str+'_'+vxx+'.cdf'
  final_resting_place = ldir+relpathname
  file_move, fullfile, final_resting_place
  skip_ies:

  type = 'ees'
  fa_create_l2, type = type, orbit = orbit, data_struct = dat
  If(is_struct(dat)) Then Begin
     fa_esa_cmn_l2gen, dat, esa_type = type, otp_struct = otp_struct
     If(~is_struct(otp_struct)) Then message, type+' Write to CDF failed: orbit'+strcompress(/remove_all, string(orbit))
  Endif Else Begin
     message, type+' L2 generation failed: orbit'+strcompress(/remove_all, string(orbit))
  Endelse
;move the file into the correct database directory
  relpathname='l2/'+type+'/'+orbit_dir+'/fa_l2_'+type+'_'+date+'_'+orbit_str+'_'+vxx+'.cdf'
  final_resting_place = ldir+relpathname
  file_move, fullfile, final_resting_place
  skip_ees:

  type = 'ieb'
  fa_create_l2, type = type, orbit = orbit, data_struct = dat
  If(is_struct(dat)) Then Begin
     fa_esa_cmn_l2gen, dat, esa_type = type, otp_struct = otp_struct
     If(~is_struct(otp_struct)) Then message, type+' Write to CDF failed: orbit'+strcompress(/remove_all, string(orbit))
  Endif Else Begin
     message, type+' L2 generation failed: orbit'+strcompress(/remove_all, string(orbit))
  Endelse
;move the file into the correct database directory
  relpathname='l2/'+type+'/'+orbit_dir+'/fa_l2_'+type+'_'+date+'_'+orbit_str+'_'+vxx+'.cdf'
  final_resting_place = ldir+relpathname
  file_move, fullfile, final_resting_place
  skip_ieb:

  type = 'eeb'
  fa_create_l2, type = type, orbit = orbit, data_struct = dat
  If(is_struct(dat)) Then Begin
     fa_esa_cmn_l2gen, dat, esa_type = type, otp_struct = otp_struct
     If(~is_struct(otp_struct)) Then message, type+' Write to CDF failed: orbit'+strcompress(/remove_all, string(orbit))
  Endif Else Begin
     message, type+' L2 generation failed: orbit'+strcompress(/remove_all, string(orbit))
  Endelse
;move the file into the correct database directory
  relpathname='l2/'+type+'/'+orbit_dir+'/fa_l2_'+type+'_'+date+'_'+orbit_str+'_'+vxx+'.cdf'
  final_resting_place = ldir+relpathname
  file_move, fullfile, final_resting_place
  skip_eeb:
  message, /info, 'All ESA datatypes finished'
  Return

End

