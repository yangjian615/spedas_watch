;+
;NAME: DSC_GETRNAME
;
;DESCRIPTION
;	Returns the routine name of the calling function.
;	
;CREATED BY: Ayris Narock (ADNET/GSFC) 2017
;
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-

function dsc_getrname
	COMPILE_OPT IDL2

	info = scope_traceback(/structure)
	return,info[-2].routine
end