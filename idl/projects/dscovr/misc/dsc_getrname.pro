;+
;NAME: DSC_GETRNAME
;
;DESCRIPTION
;	Returns the routine name of the calling function.
;	
;CREATED BY: Ayris Narock (ADNET/GSFC) 2017
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2017-11-20 12:45:47 -0800 (Mon, 20 Nov 2017) $
; $LastChangedRevision: 24321 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/dscovr/misc/dsc_getrname.pro $
;-

function dsc_getrname
	COMPILE_OPT IDL2

	info = scope_traceback(/structure)
	return,info[-2].routine
end