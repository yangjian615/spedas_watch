;+
;NAME:
; mvn_spd_init
;PURPOSE:
; Initialization for MAVEN 
;CALLING SEQUENCE:
; mvn_spd_init, device = device
;INPUT:
; none
;OUTPUT:
; none
;KEYWORDS:
; def_file_source = A default structure for the file_source; tags:
;   INIT            INT              0
;   LOCAL_DATA_DIR  STRING    '/disks/data/'
;   REMOTE_DATA_DIR STRING    ''
;   PROGRESS        INT              1
;   USER_AGENT      STRING    'FILE_RETRIEVE: IDL8.4 linux/x86_64 (jimm)'
;   FILE_MODE       INT            438
;   DIR_MODE        INT            511
;   PRESERVE_MTIME  INT              1
;   PROGOBJ         OBJREF    <NullObject>
;   MIN_AGE_LIMIT   LONG                30
;   NO_SERVER       INT              1
;   NO_DOWNLOAD     INT              0
;   NO_UPDATE       INT              0
;   NO_CLOBBER      INT              0
;   ARCHIVE_EXT     STRING    '.arc'
;   ARCHIVE_DIR     STRING    ''
;   IGNORE_FILESIZE INT              0
;   IGNORE_FILEDATE INT              0
;   DOWNLOADONLY    INT              0
;   USE_WGET        INT              0
;   NOWAIT          INT              0
;   VERBOSE         INT              2
;   FORCE_DOWNLOAD  INT              0
;   LAST_VERSION    INT              1
; no_color_setup = if set, don't touch the colors setup
; MVN_FILE_SOURCE keywords:
; user_pass = a user pasword combination, example:
;             "jimm:not_really_my Password"
;HISTORY:
; 2013-05-13, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2015-09-28 12:36:26 -0700 (Mon, 28 Sep 2015) $
; $LastChangedRevision: 18949 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/spedas_plugin/mvn_spd_init.pro $
;-
Pro mvn_spd_init, def_file_source = def_file_source, no_color_setup = no_color_setup, _extra = _extra

  common mvn_spd_init_private, init_done

  setenv, 'ROOT_DATA_DIR='+root_data_dir()

  If(n_elements(init_done) Eq 0) Then Begin
     init_done = 1
;Color setup
     If(~keyword_set(no_color_setup)) Then Begin
        if n_elements(colortable) eq 0 then colortable = 43 ; default color table
        loadct2,colortable
;Make black on white background
        !p.background = !d.table_size-1 ; White background   (color table 34)
        !p.color=0                      ; Black Pen
        if !d.name eq 'WIN' then begin
           device,decompose = 0
        endif
        if !d.name eq 'X' then begin
           device,decompose = 0
           if !version.os_family eq 'unix' then device,retain=2 ; Unix family does not provide backing store by default
        endif
     Endif
  Endif

;Call mvn_file_source for the file setup, carefully
  If(is_struct(def_file_source)) Then Begin
     psource = mvn_file_source(def_file_source)
  Endif Else Begin
     psource = mvn_file_source(_extra=_extra)
  Endelse

  Return
End
