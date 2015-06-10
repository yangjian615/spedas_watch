;+
;
;NAME: getresourcepath
;
;PURPOSE:
;  gets the path of the resource directory in a cross platform way
;
;CALLING SEQUENCE:
;   getresourcepath,path
;
;OUTPUT:
;   path:  the path to the resource directory
;
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/getresourcepath.pro $
;----------

pro getresourcepath,path

  ;get path of routine
 rt_info = routine_info('getresourcepath',/source)
 path = file_dirname(rt_info.path) + '/../Resources/'

end
