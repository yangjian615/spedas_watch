;+
;NAME:
; mvn_sta_cmn_l2file_save
;PURPOSE:
; saves an STA L2 cdf, managing the revision number and md5 sum. The
; file will have the latest revision number, there will be a hard
; link to the revisioned file with no revision number, andan md5 sum
; for the uncompressed file. Also deletes old versions.
;CALLING SEQUENCE:
; mvn_sta_cmn_l2file_save, otp_struct, fullfile0, no_compression = no_compression
;INPUT:
; otp_struct = the structure toy output in CDF_LOAD_VARS format.
; fullfile0 = the full-path filename for the revisionless cdf file
;OUTPUT:
; No explicit output, the revisioned file is written, an md5 sum file
; is written in the same directory, and the revisionless file is
; linked to the revsioned file 
;KEYWORDS:
; no_compression = if set, skip the compression step
;HISTORY:
; 22-jul-2014, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2014-09-10 12:20:31 -0700 (Wed, 10 Sep 2014) $
; $LastChangedRevision: 15751 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/l2gen/mvn_sta_cmn_l2file_save.pro $
;-
Pro mvn_sta_cmn_l2file_save, otp_struct, fullfile0, no_compression = no_compression

  If(~is_struct(otp_struct)) Then Begin
     dprint, 'Bad structure input '
     Return
  Endif

  If(~is_string(fullfile0)) Then Begin
     dprint, 'Bad filename input '
     Return
  Endif

;Ok, get the next revision, and any files to delete
  mvn_sta_l2_filerevision, fullfile0, fullfile, delfiles

  If(~is_string(fullfile)) Then Begin
     dprint, 'No filename for file: '+fullfile0
     Return
  Endif

  file = file_basename(fullfile)
  file_id = file_basename(file, '.cdf')
  otp_struct.filename = file
  otp_struct.g_attributes.logical_file_id = file_id
  ppp = strsplit(file_id, '_', /extract)
;only mvn_sta_l2_app_id_etc here, no date
  otp_struct.g_attributes.logical_source = strjoin(ppp[0:3], '_')
;Add compression, 2014-05-27, changed to touch all files with
;cdfconvert, 2014-06-10
;Creates an md5sum of the uncompressed file, and saves it in the same
;path, 2014-07-07
  dummy = cdf_save_vars2(otp_struct, fullfile)
  spawn, '/usr/local/pkg/cdf-3.5.0_CentOS-6.5/bin/cdfconvert '+fullfile+' '+fullfile+' -compression cdf:none -delete'

  md5file = ssw_str_replace(fullfile, '.cdf', '.md5')
  If(file_exist(md5file)) Then file_delete, md5file
  spawn, 'md5sum '+fullfile+' > '+md5file

;Extract the md5 sum, and replace the filename in the file, because
;you do not want the path name, yuck
  md5str = strarr(1)
  openr, unit, md5file, /get_lun 
  readf, unit, md5str
  free_lun, unit
  ppp = strsplit(md5str[0], /extract)
  openw, unit, md5file, /get_lun
  printf, unit, ppp[0], '  ', file
  free_lun, unit

  If(~keyword_set(no_compression)) Then Begin
     spawn, '/usr/local/pkg/cdf-3.5.0_CentOS-6.5/bin/cdfconvert '+fullfile+' '+fullfile+' -compression cdf:gzip.5 -delete'
  Endif

;Delete files, fullfile0 is a link if it exists, but must be re-linked
  If(is_string(file_search(fullfile0))) Then file_delete, fullfile0

;md5 files need deleting too
  If(is_string(delfiles)) Then Begin
     ndel = n_elements(delfiles)
     For j = 0, ndel-1 Do Begin
        file_delete, delfiles[j]
        del_md5filej = ssw_str_replace(delfiles[j], '.cdf', '.md5')
        If(file_exist(del_md5filej)) Then file_delete, del_md5filej
     Endfor
  Endif

;Link revisionless file:
  spawn, 'ln '+fullfile+' '+fullfile0

;chmod to g+w for the files
  spawn, 'chmod g+w '+fullfile
  spawn, 'chmod g+w '+fullfile0
  spawn, 'chmod g+w '+md5file

  Return
End
