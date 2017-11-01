;+
;NAME: DSC_DYPLOT
;
;DESCRIPTION:
; Plot a shaded area showing confidence range where avaialable.
; Will look for tplot variable options tags 
;   dsc_dy: 0 - do not show dy interval
;           1 - show dy interval if available
;   dsc_dycolor: (int) Colortable reference for dy fill color
;
;INPUT:
;
;KEYWORDS: (Optional)   
; COLOR=:   Set to desired fill color. (int or int array)  Will override any options set in the dlimits/limits
;             structures.  If not set will reference the 'dsc_dycolor' variable option or
;             choose a reasonable default.
; FORCE:    Set to ignore the 'dsc_dy' tag setting and show the DY for all requested panels if DY available				 
; PANEL=:   Array of indices describing which panels for which to draw confidence. (1 indexed like TPLOT)
;             If this is not set the routine will attempt to draw confidence for all panels.
; POS=:     4xn array describing the positions of each of the n panels in the plot of interest.
;             Defaults to the positions found in the 'tplot_vars' structure.										
; TVINFO=:  Structure containing TPLOT variables information - as returned
;             from the 'new_tvar' keyword to tplot. 
;             If not set uses that found in common 'tplot_vars'
; VERBOSE=: Integer indicating the desired verbosity level.  Defaults to !dsc.verbose
; WINDOW=:  Which direct graphics window to target for this polyfill. (int)
;             This is gererally not needed if plotting on an existing tplot window. Will default
;             to whatever is set by the TVINFO structure being used.
;					
;CREATED BY: Ayris Narock (ADNET/GSFC) 2017
;
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-

PRO DSC_DYPLOT,TVINFO=tvinfo,POS=pos,PANEL=panel,WINDOW=w,COLOR=cf,FORCE=force,VERBOSE=verbose

	COMPILE_OPT IDL2
	
	@tplot_com.pro
	
	dsc_init
	rname = dsc_getrname()
	if not isa(verbose,/int) then verbose=!dsc.verbose

	catch, err
	if err ne 0 then begin
		if err eq -539 then begin
			dprint,dlevel=1,verbose=verbose,rname+': Invalid TPLOT Window reference. A TPLOT window must be open before calling this procedure.'
		endif else dprint,dlevel=1,verbose=verbose,rname+': Error. Exiting.'
		catch,/cancel
		return
	endif
	
	if ~keyword_set(tvinfo) then tvinfo=tplot_vars
	np = n_elements(tvinfo.options.varnames)

	if (w ne !null) then wset,w $
		else if tag_exist(tvinfo.options,'window') then wset,tvinfo.options.window
	if ~keyword_set(pos) then begin
		pos = fltarr(4,np)
		xw = tvinfo.settings.x.window
		yw = tvinfo.settings.y.window
		pos[0,*] = tvinfo.settings.x.window[0]
		pos[1,*] = tvinfo.settings.y.window[0,*]
		pos[2,*] = tvinfo.settings.x.window[1]
		pos[3,*] = tvinfo.settings.y.window[1,*]
	endif

	if (panel eq !null) then panel=indgen(np) else panel = panel-1
	if max(panel) ge np then begin
		dprint,dlevel=1,verbose=verbose,rname+': bad panel number'
		return
	endif

	if (cf ne !null) then begin
		color=cf 
		cf = 1
	endif else cf=0
	
	for i=0,n_elements(panel)-1 do begin
		meta = {init: 0} 
		get_data,tvinfo.options.varnames[panel[i]],data=d,limit=limit0,dlimit=dlim
		extract_tags,meta,dlim,tags=['dsc_dy','dsc_dycolor']
		extract_tags,meta,limit0,tags=['dsc_dy','dsc_dycolor']

		; TODO - Ability to delete the dy fill: consider polyfill in the background color for no-draw.. to allow "delete-ing 
		; without needing to call tplot again first.  how would this play with multi-calls for diff colored panels?
		drawpanel = keyword_set(force) ? 1 : (tag_exist(meta,'dsc_dy')) ? meta.dsc_dy : 0

		if drawpanel then begin
			if ~cf then color = (tag_exist(meta,'dsc_dycolor')) ? meta.dsc_dycolor : 3
			if size(d,/type) eq 7 then begin	; string => DY combo variable of 2 or 3 elements
				if d[0].Matches('\+DY') then begin
					get_data,d[0],data=d1
					get_data,d[-1],data=d2
					xrange = tvinfo.settings.x.crange + tvinfo.settings.time_offset
					idx = where(d1.x ge xrange[0] and d1.x le xrange[1], count)
					if count gt 1 then begin
						dims = size(d1.y,/dim)
						t_scale = ([d1.x[idx],reverse(d2.x[idx])]-tvinfo.settings.time_offset)/tvinfo.settings.time_scale
						nx = data_to_normal(t_scale,tvinfo.settings.x)
						ny = data_to_normal([d1.y[idx,0],reverse(d2.y[idx,0])],tvinfo.settings.y[panel[i]])
						polyfill,nx,ny,color=color[0],/normal,clip=pos[*,panel[i]],noclip=0
						
						if (dims.length gt 1) then begin
							ncolors = color.length
							for j=1,dims[1]-1 do begin
								ny = data_to_normal([d1.y[idx,j],reverse(d2.y[idx,j])],tvinfo.settings.y[panel[i]])
								polyfill,nx,ny,color=color[(j mod ncolors)],/normal,clip=pos[*,panel[i]],noclip=0

							endfor
						endif
					endif
				endif
	
			endif else if size(d,/type) eq 8 then begin
				if tag_exist(d,'dy') then begin
					xrange = tvinfo.settings.x.crange + tvinfo.settings.time_offset
					idx = where(d.x ge xrange[0] and d.x le xrange[1], count)
					if count gt 1 then begin
						dims = size(d.y,/dim)
						t_scale = ([d.x[idx],reverse(d.x[idx])]-tvinfo.settings.time_offset)/tvinfo.settings.time_scale
						nx = data_to_normal(t_scale,tvinfo.settings.x)
						ny = data_to_normal([d.y[idx,0]+d.dy[idx,0],reverse(d.y[idx,0]-d.dy[idx,0])],tvinfo.settings.y[panel[i]])
						polyfill,nx,ny,color=color[0],/normal,clip=pos[*,panel[i]],noclip=0
						
						if (dims.length gt 1) then begin
							ncolors = color.length
							for j=1,dims[1]-1 do begin
								ny = data_to_normal([d.y[idx,j]+d.dy[idx,j],reverse(d.y[idx,j]-d.dy[idx,j])],tvinfo.settings.y[panel[i]])
								polyfill,nx,ny,color=color[(j mod ncolors)],/normal,clip=pos[*,panel[i]],noclip=0
							endfor
						endif

					endif
				endif
			endif
		endif else dprint, dlevel=2, verbose=verbose, format='((A),": Not drawing panel:",(I3),". Check the ''dsc_dy'' option flag.")',rname,panel[i]+1

	endfor
	tplot,/oplot,old_tvars=tvinfo
END