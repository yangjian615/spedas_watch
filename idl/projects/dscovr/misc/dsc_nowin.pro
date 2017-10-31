;+
;NAME: DSC_NOWIN
;
;DESCRIPTION:
;	Closes all open direct graphics windows
;	
;KEYWORDS: (Optional)
; VERBOSE=:		Integer indicating the desired verbosity level.  Defaults to !dsc.verbose
;
;CREATED BY: Ayris Narock (ADNET/GSFC) 2017
;
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-

pro dsc_nowin, VERBOSE=verbose

COMPILE_OPT IDL2

dsc_init
rname = dsc_getrname()
if not isa(verbose,/int) then verbose=!dsc.verbose

i = 0
while (!d.window ne -1) do begin
	wdelete
	i++
endwhile

dprint,dlevel=4,verbose=verbose,rname+': Deleted '+i.toString()+' window(s)'
end