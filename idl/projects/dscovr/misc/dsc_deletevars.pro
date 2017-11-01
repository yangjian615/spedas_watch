;+
;NAME: DSC_DELETEVARS
;
;DESCRIPTION:
; Deletes all DSCOVR data variables from TPLOT
;
;KEYWORDS: (Optional)
; VERBOSE=: Integer indicating the desired verbosity level.  Defaults to !dsc.verbose
;
;EXAMPLE:
;		dsc_deletevars
;
;CREATED BY: Ayris Narock (ADNET/GSFC) 2017
;
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-

PRO DSC_DELETEVARS,VERBOSE=verbose

	COMPILE_OPT IDL2
	
	dsc_init
	rname = dsc_getrname()
	if not isa(verbose,/int) then verbose=!dsc.verbose
	
	dprint,dlevel=4,verbose=verbose,rname+': Deleting tplot variables- '
	foreach name,tnames('dsc_*') do begin
		dprint,dlevel=4,verbose=verbose,"   "+name
	endforeach
	
	store_data,delete='dsc_*'
END
