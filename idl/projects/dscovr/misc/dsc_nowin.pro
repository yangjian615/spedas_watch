;+
;NAME: DSC_NOWIN
;
;DESCRIPTION:
;	Closes all open direct graphics windows
;	
;KEYWORDS: (Optional)
; VERBOSE=: Integer indicating the desired verbosity level.  Defaults to !dsc.verbose
;
;CREATED BY: Ayris Narock (ADNET/GSFC) 2017
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2017-11-20 12:45:47 -0800 (Mon, 20 Nov 2017) $
; $LastChangedRevision: 24321 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/dscovr/misc/dsc_nowin.pro $
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