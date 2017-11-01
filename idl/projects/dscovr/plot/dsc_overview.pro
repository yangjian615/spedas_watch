;+
;NAME: DSC_OVERVIEW
;
;DESCRIPTION:
; Multi-panel plot of DSCOVR data using TPLOT calls (direct graphics.)  Vector
; components are shown in GSE coordinates. 
;
;INPUTS:
; DATE: Date of interest. String, in the form 'YYYY-MM-DD/HH:MM:SS' (as accepted by 'timespan')  
;         Will plot 1 full day.  
;         If this argument is not passed it will look for the TRANGE keyword.
;
;KEYWORDS: (Optional)
; SAVE:    Set to save a .png copy of the generated plot(s) in the !dsc.save_plots_dir/gen/ directory
; SPLITS:  Set to split the time range into quarters and create 4 consecutive
;            plots in addition to the overview of the whole time range.
; TRANGE=: Set this to the time range of interest.  This keyword will be ignored if
;            DATE argument is passed.  The routine will return without plotting if neither
;            DATE nor TRANGE is set. (2-element array of	doubles (as output by timerange()) 
;            or strings (as accepted by timerange()))
; VERBOSE=: Integer indicating the desired verbosity level.  Defaults to !dsc.verbose
; 					
;KEYWORD OUTPUTS:
; WREF=:	Array of integer id(s) of direct graphics window(s) created with this call. (long)
; 
;EXAMPLES:
;		dsc_overview,'2017-02-13',/splits,wref=wr
;		dsc_overview,trange=timerange(),/save
;
;		trg = timerange(['2017-05-21/13:00:00','2017-05-21/18:30:00'])
;		dsc_overview,trange=trg,/splits,/save
;		dsc_overview,trange=['2017-01-01','2017-01-02/06:00:00']
;
;CREATED BY: Ayris Narock (ADNET/GSFC) 2017
;
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-
PRO DSC_OVERVIEW,DATE,TRANGE=trg,SPLITS=splits,SAVE=save,VERBOSE=verbose,WREF=wr

COMPILE_OPT IDL2

dsc_init
rname = dsc_getrname()
if not isa(verbose,/int) then verbose=!dsc.verbose

catch,err
if err ne 0 then begin
	dprint,dlevel=1,verbose=verbose,rname+': You must supply a date or timerange: ('+rname.toLower()+',''YYYY-MM-DD'') or ('+rname.toLower()+',trange=[t1,t2])'
	return
endif

date_err_msg = 'Date Input Error'
if isa(date,'undefined') then begin
	if (~isa(trg,/float,/array) and ~isa(trg,/string,/array))  then mesage,date_err_msg 
	trg = timerange(trg)
endif else begin
	if (~isa(date,/string,/scalar)) then mesage,date_err_msg
	timespan,date,1,/day
	trg = timerange()
endelse
catch,/cancel

mindate = timerange('2015-02-11')
foreach time,trg do begin
	if time lt mindate[0] then begin
		dprint,dlevel=1,verbose=verbose,rname+': Please supply a date after launch (2015-02-11)'
		return
	endif
endforeach
wr = []

dsc_load_mag,trange=trg
dsc_load_fc,trange=trg

var = ['b','btheta','bphi','v','np','vth']
tn = dsc_ezname(var)

dsc_clearopts,tn
options,tn,title=''
options,tn[0],colors=250
options,tn[1:2],colors=208
options,tn[3],colors='b'
options,tn[4:5],colors=40,dsc_dycolor=3

dm = GET_SCREEN_SIZE()
xsize=0.7*dm[0]
ysize=0.8*dm[1]

spd_graphics_config
tstr = time_string(trg)

wtitle = 'DSCOVR: ('+tstr[0]+' - '+tstr[1]+')'
window,/free,title=wtitle,xsize=xsize,ysize=ysize
w = !d.window
foreach n,tn do begin
	dsc_get_ylimits,n,limstr,trg,/include_err,/buff
	options,n,yrange=limstr.yrange,ystyle=1
endforeach
tplot,tn,trange=trg,title='DSCOVR Overview',window=w 
dsc_dyplot

if keyword_set(splits) then begin
	trgs = dindgen(5,start=trg[0],increment=.25*(trg[1]-trg[0]))
	tstrs = time_string(trgs)

	wtitle = 'DSCOVR 1/4: ('+tstrs[0]+' - '+tstrs[1]+')'
	window,/free,title=wtitle,xsize=xsize,ysize=ysize
	w1 = !d.window

	wtitle = 'DSCOVR 2/4: ('+tstrs[1]+' - '+tstrs[2]+')'
	window,/free,title=wtitle,xsize=xsize,ysize=ysize
	w2 = !d.window

	wtitle = 'DSCOVR 3/4: ('+tstrs[2]+' - '+tstrs[3]+')'
	window,/free,title=wtitle,xsize=xsize,ysize=ysize
	w3 = !d.window

	wtitle = 'DSCOVR 4/4: ('+tstrs[3]+' - '+tstrs[4]+')'
	window,/free,title=wtitle,xsize=xsize,ysize=ysize
	w4 = !d.window

	foreach n,tn do begin
		dsc_get_ylimits,n,limstr,trgs[0:1],/include_err,/buff
		options,n,yrange=limstr.yrange,ystyle=1
	endforeach
	tplot,tn,trange=trgs[0:1],title='DSCOVR Overview - Split 1 of 4',window=w1 
	dsc_dyplot

	foreach n,tn do begin
		dsc_get_ylimits,n,limstr,trgs[1:2],/include_err,/buff
		options,n,yrange=limstr.yrange,ystyle=1
	endforeach	
	tplot,tn,trange=trgs[1:2],title='DSCOVR Overview - Split 2 of 4',window=w2 
	dsc_dyplot
	
	foreach n,tn do begin
		dsc_get_ylimits,n,limstr,trgs[2:3],/include_err,/buff
		options,n,yrange=limstr.yrange,ystyle=1
	endforeach
	tplot,tn,trange=trgs[2:3],title='DSCOVR Overview - Split 3 of 4',window=w3 
	dsc_dyplot
	
	foreach n,tn do begin
		dsc_get_ylimits,n,limstr,trgs[3:4],/include_err,/buff
		options,n,yrange=limstr.yrange,ystyle=1
	endforeach
	tplot,tn,trange=trgs[3:4],title='DSCOVR Overview - Split 4 of 4',window=w4 
	dsc_dyplot
	wr = [w1,w2,w3,w4]
endif

if keyword_set(save) then begin
	dprint,dlevel=2,verbose=verbose,rname+': Saving DSCOVR Overview Plots'
	
	; full overview
	tstr = time_string(trg,format=6)
	dir = !dsc.save_plots_dir+'gen/'
	prefix = 'dsc_tplotoverview_'
	makepng,dir+prefix+tstr[0]+'_'+tstr[1],/mkdir,window=w
	
	; 1/4 time splits
	if keyword_set(splits) then begin
		tstr = time_string(trgs,format=6)
		foreach wndw,wr,i do makepng,dir+prefix+tstr[i]+'_'+tstr[i+1]
	endif
endif

; clear options
dsc_clearopts,tn

wr = [w,wr]
END