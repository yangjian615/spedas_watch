;+
;NAME:
; dproc_status_update
; 
;PURPOSE:
; Outputs messages to history window, status bar, or IDL console
;
;CALLING SEQUENCE:
; dproc_status_update, 'There was an error', sbar, hwin
; dproc_status_update, 'There was an error', hwin
; dproc_status_update, 'There was an error', sbar
;
;INPUT:
; msg: string or string array containing message
; sbar: obj reference for status bar
; hwin: obj reference for history window
; 
;NOTES:
; Messages will be printed to the IDL console if the history window
; reference is missing or invalid. The order in which the history 
; window and status bar refernces are passed in should be irrelevant. 
;
;-
pro dproc_status_update, msg, sbar, hwin, _extra=_extra

    compile_opt idl2, hidden

  h = arg_present(hwin) && obj_valid(hwin) 
  s = arg_present(sbar) && obj_valid(sbar)
  c = (h && obj_isa(hwin,'SPD_UI_HISTORY')) or (s && obj_isa(sbar,'SPD_UI_HISTORY')) 

  for i=0, n_elements(msg)-1 do begin
  
    if h then hwin -> update, msg[i]
    if s then sbar -> update, msg[i]
    if ~c then dprint, msg[i], _extra=_extra
  
  endfor

end


;+
;NAME:
; spd_ui_loaded_data::dproc
;
;PURPOSE:
; extracts tplot variables from active data, performs data processing
; tasks, creates new variables, optionally sets those variables to
; active variables
;
;CALLING SEQUENCE:
; success = loaded_data_obj -> dproc(dp_task, dp_pars,callSequence, names_out=names_out, no_setactive=no_setactive)
;
;INPUT:
; dp_task = a string variable specifying the task to be carried
;           out. The options are ['subavg', 'submed', 'smooth',
;           'blkavg','clip','deflag','degap','spike','deriv',
;           'pwrspc','wave','hpfilt']
; dp_pars = an anonymous structure containing the input parameters for
; the task, this will be unpacked in this routine and the parameters
; are passed through. Note that, since this is only called from the
; thm_GUI_new routine, there is no error checking for
; content, it is expected that the calling routine passes through the
; proper parameters in each case.
;
; callSequence = Object to store previous dproc operations for replay
;
;OUTPUT:
; success = a byte, 0b if the process was unsuccessful or cancelled,
;           1b if the process was completed
;
;KEYWORDS:
; names_out = the tplot names of the created data variables
; no_setactive = if set, the new variables will no be set to active at
;                the end of the process.
; hwin, sbar = history window and status bar objects for updates
; gui_id = the id of the calling widget - to pass into warning pop-ups
;
;HISTORY:
; 16-oct-2008, jmm, jimm@ssl.berkeley.edu
; switched output from message to byte, 29-oct-2008,jmm
; 12-Dec-2008,prc Fixed bug where dproc was not reading data stored in
; loaded data,but instead was reading non-gui-data.
; Fixed bug where data produced by dproc was not inheriting any meta-data.
; 23-jan-2009, jmm, deletes any tplot variables that are created
;                   during processing, added catch, so that deletion
;                   of tplot variables is done if an error bonks a
;                   process.
; 10-Feb-2009, jmm, Added hwin, sbar keywords
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2015-01-20 13:27:39 -0800 (Tue, 20 Jan 2015) $
;$LastChangedRevision: 16693 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas/gui/objects/spd_ui_loaded_data__dproc.pro $
Function spd_ui_loaded_data::dproc, dp_task, dp_pars,callSequence=callSequence,replay=replay,in_vars=in_vars, names_out = names_out, $
                           no_setactive = no_setactive, hwin = hwin, sbar = sbar, gui_id = gui_id, $
;when replaying data, need to remember user interaction responses if we're gonna get it right
                           overwrite_selections=overwrite_selections,degap_selections=degap_selections,blkavg_selections=blkavg_selections,$
                           smooth_selections=smooth_selections, hpf_selections=hpf_selections,$
                           _extra = _extra

err = 0
catch, err
If(err Ne 0) Then Begin
    catch, /cancel
    Help, /Last_Message, Output=error
    if obj_valid(hwin) then hwin->update, error
    out_msg = 'Warning: An error occured during processing.  Check the history window for details.'
    ok = error_message(traceback = 1, /noname, title = 'Error in Data Processing: ',/center)
    Goto, return_sequence
Endif

;Initialize output
names_out = ''
otp = 0b

overwrite_selection =''
degap_selection=''
blkavg_selection=''
smooth_selection=''
hpf_selection=''

overwrite_count = 0
degap_count = 0
blkavg_count = 0
smooth_count = 0
hpf_count = 0
  
if ~keyword_set(replay) then begin
  overwrite_selections=''
  degap_selections=''
  blkavg_selections=''
  smooth_selections=''
  hpf_selections=''
endif

;Other
addmessage = 0b

if ~is_string(in_vars) then begin
  return,0
endif else begin
  active_v = in_vars
endelse

nav = n_elements(active_v)
dpt = strtrim(strlowcase(dp_task), 2)
;keep track of tnames created in process
tnames_in = tnames()

;Create a display object to house the status bar and history windows.
;This object will be passed to the underlying analysis routines
;to allow them to report messages to the gui via dprint.
display_object = obj_new('spd_ui_dprint_display', statusbar=sbar, historywin=hwin)

For j = 0, nav-1 Do Begin
    canceled = 0b  ; set/reset canceled flag
    skipped = 0b  ; set/reset skipped flag
   
    
    varname = active_v[j]
;Get the data -- first check to see if there are more than 2D. Most of
;                these routines will not work for more than 2d data.

    ;This call to getTvarObject is important for proper function of
    ;the gui. Do not remove.
    ;#1 It reads data from loadedData, not from tplot variables that may be deleted.
    ;#2 It stores all the associated metadata with the object, which is needed to properly classify data.
    tvarObject = self->getTvarObject(varname)
    get_data, varname, data = d
    If(is_struct(d)) Then Begin
        sy = size(d.y, /n_dim)
        If(sy Gt 2) And (dpt Ne 'subavg') And (dpt Ne 'submed') Then Begin
            dproc_status_update, varname+' data has too many dimensions', sbar, hwin
            yes_data = 0b
        Endif Else yes_data = 1b
    Endif Else Begin
        dproc_status_update,varname+' has no data', sbar, hwin
        yes_data = 0b
    Endelse

    If(yes_data) Then Begin
        nn0 = varname
;Now process the data
        Case dpt Of
            'split': Begin
                split_vec, varname, names_out = nn, inset='_split', display_object=display_object
            End
            'join': Begin
                if j eq nav-1 then begin
                  joinflag = 0b
                  join_vec, active_v, dp_pars.new_name[0], $
                            display_object=display_object, fail = jfail
                  if keyword_set(jfail) then begin
                    dproc_status_update,'Could not join selected variables.', sbar, hwin
                    nn=''
                  endif else begin
                    nn = dp_pars.new_name
                  endelse
                endif else begin
                  joinflag = 1b
                endelse
            End
            'subavg': Begin
                tsub_average, varname, nn, new_name = (nn0+'-d')[0], display_object=display_object
                nn = tnames(nn0+'-d')
            End
            'submed': Begin
                tsub_average, varname, nn, new_name = (nn0+'-m')[0], /median
                nn = tnames(nn0+'-m')
            End
            'deriv': Begin
                get_data, varname, ttt
                If(n_elements(temporary(ttt)) Gt 3) Then Begin
                   deriv_data, varname, newname = nn0+dp_pars.suffix[0], display_object=display_object, $
                               _extra={nsmooth:( dp_pars.setswidth ? dp_pars.swidth:0b)}
                   nn = tnames(nn0+dp_pars.suffix)
                Endif Else Begin
                   dproc_status_update,'Unable to get time derivative for '+varname+'; not enough time elements.',sbar, hwin
                   canceled = 1b
                Endelse
            End
            'spike': Begin
                clean_spikes, varname, new_name = nn0+dp_pars.suffix[0], display_object=display_object, $
                              nsmooth = dp_pars.swidth[0], $
                              thresh = dp_pars.thresh[0]
                nn = tnames(nn0+dp_pars.suffix)
            End
            'smooth': Begin
                get_data, nn0, t
                noktimes =  n_elements(t)
                if noktimes gt 1 then begin ; operation not valid on single time element
                    av_dt = median(t[1:*]-t)
                    If(av_dt Gt dp_pars.dt) then begin
                        if smooth_selection ne 'yestoall' && smooth_selection ne 'notoall' Then Begin
                            smooth_selection=''
                            if ~keyword_set(replay) then begin
                                lbl = ['Note that the median value of the time resolution for '+nn0+' is:'+strcompress(string(av_dt))+' sec.', $
                                       'The value that you have chosen for the averaging time resolution is smaller: '+$
                                       strcompress(string(dp_pars.dt))+' sec.', $
                                       'This will have non-intuitive and possibly non-plottable results. Do you want to continue?']
                                                            
                                smooth_selection = spd_ui_prompt_widget(gui_id,sbar,hwin,prompt=strjoin(lbl,ssl_newline()),title='SPEDAS GUI SMOOTH TEST',/yes,/no,/allyes,/allno, frame_attr=8)
                                smooth_selections = array_concat_wrapper(smooth_selection,smooth_selections)
                            endif else begin
                                if smooth_count ge n_elements(smooth_selections) then begin
                                    hwin->update,"ERROR:Discrepancy in spedas document, may have lead to a document load error"
                                    sbar->update,"ERROR:Discrepancy in spedas document, may have lead to a document load error"
                                    smooth_selection = "yestoall"
                                endif else begin
                                    smooth_selection = smooth_selections[smooth_count]
                                endelse
                            endelse
                        endif
                        smooth_count++
                    Endif
                    If (av_dt le dp_pars.dt[0] || (smooth_selection ne 'notoall' && smooth_selection ne 'no')) Then Begin
                        dt = dp_pars.dt[0]
                        _extra = {forward:dp_pars.dttype[1], $
                                  backward:dp_pars.dttype[2], $
                                  no_time_interp:dp_pars.opts[0], $
                                  true_t_integration:dp_pars.opts[1], $
                                  smooth_nans:dp_pars.opts[2]}
                        if dp_pars.setICad then str_element, _extra, 'interp_resolution', dp_pars.icad, /add_replace
                        If(dt Lt 1.0) Then dtchar = strcompress(/remove_all, dt) $
                        Else dtchar = strcompress(/remove_all, fix(dt))
                        tsmooth_in_time, varname, dt, newname = nn0+dp_pars.suffix[0], display_object=display_object, _extra=_extra, $
                          interactive_varname=varname,/interactive_warning,warning_result=warning_result
                        if n_elements(warning_result) gt 0 && warning_result eq 1 then begin
                            nn = tnames(nn0+dp_pars.suffix)
                        endif
                    Endif Else Begin
                        dproc_status_update,'Smooth process for: '+nn0+' cancelled.', sbar, hwin
                        canceled = 1b ;prevent variable from being added later
                    Endelse
                endif else begin
                    dproc_status_update,'Unable to smooth '+nn0+' not enough elements in time range.', sbar, hwin
                    canceled = 1b
                endelse
            End
            'blkavg': Begin
;need another sanity test
              get_data, nn0, t
;test trange here
              if dp_pars.limit Eq 1 then begin
                 oktimes =  where(t Gt dp_pars.trange[0] And t Le dp_pars.trange[1],  noktimes)
               endif else noktimes =  n_elements(t)
              
              if noktimes gt 1 then begin ; operation not valid on single time element
                av_dt = median(t[1:*]-t)
   
                If(av_dt Gt dp_pars.dt) then begin
                  if blkavg_selection ne 'yestoall' && blkavg_selection ne 'notoall' Then Begin
                    blkavg_selection=''
                    if ~keyword_set(replay) then begin
                      lbl = ['Note that the median value of the time resolution for '+nn0+' is:'+strcompress(string(av_dt))+' sec.', $
                             'The value that you have chosen for the averaging time resolution is smaller: '+$
                             strcompress(string(dp_pars.dt))+' sec.', $
                             'This will have non-intuitive and possibly non-plottable results. Do you want to continue?']
                  
                      blkavg_selection = spd_ui_prompt_widget(gui_id,sbar,hwin,prompt=strjoin(lbl,ssl_newline()),title='SPEDAS GUI BLK_AVG TEST',/yes,/no,/allyes,/allno, frame_attr=8)
                      blkavg_selections = array_concat_wrapper(blkavg_selection,blkavg_selections)
                    endif else begin
                      if blkavg_count ge n_elements(blkavg_selections) then begin
                        hwin->update,"ERROR:Discrepancy in spedas document, may have lead to a document load error"
                        sbar->update,"ERROR:Discrepancy in spedas document, may have lead to a document load error"
                        blkavg_selection = "yestoall"
                      endif else begin
                        blkavg_selection = blkavg_selections[blkavg_count]
                      endelse
                    endelse
                  endif
                  
                  blkavg_count++
                Endif
                If  (av_dt le dp_pars.dt || (blkavg_selection ne 'notoall' && blkavg_selection ne 'no')) Then Begin
                    dt = dp_pars.dt[0]
                    avg_data, varname, dt, newname = nn0+dp_pars.suffix[0], display_object=display_object, $
                              _extra = {trange:( dp_pars.limit ? dp_pars.trange:0b)}
                    nn = tnames(nn0+dp_pars.suffix)
                Endif Else Begin
                    dproc_status_update,'Block Average process for: '+nn0+' cancelled.', sbar, hwin
                    canceled = 1b ;prevent variable from being added later
                Endelse
              endif else begin
                dproc_status_update,'Unable to block average '+nn0+' not enough elements in time range.', sbar, hwin
                canceled = 1b
              endelse
            End
            'clip': Begin
                tclip, varname, dp_pars.minc[0], dp_pars.maxc[0], newname = nn0+dp_pars.suffix[0], display_object=display_object, $
                       _extra = {clip_adjacent: dp_pars.opts[0], $
                                 flag: (dp_pars.opts[1] ? dp_pars.flag:0b)}
                nn = tnames(nn0+dp_pars.suffix)
            End
            'deflag': Begin
                tdeflag, varname, (dp_pars.method[0] ? 'repeat':'linear'), $
                         newname = nn0+dp_pars.suffix[0], display_object=display_object, $
                         _extra = {flag: (dp_pars.opts[0] ? dp_pars.flag:0b), $
                                   maxgap: (dp_pars.opts[1] ? dp_pars.maxgap:0b)}
                nn = tnames(nn0+dp_pars.suffix)
            End
            'degap': Begin
;need another sanity test
              get_data, nn0, t
              
              if n_elements(t) gt 1 then begin ; operation not valid on single time element
                dt = t[1:*]-t[0:n_elements(t)-2]
                av_dt = median(dt)
                max_dt = max(dt)
                
                ;filter variables who no dt larger than threshold+margin (seems to be how xdegap works)
                if (dp_pars.dt[0] + dp_pars.margin[0]) gt max_dt then begin
                  dproc_status_update,'No gaps below threshold in '+nn0+'.', sbar, hwin
                  canceled = 1b ;prevent variable from being added later
                  break
                endif
                
                If(av_dt Gt dp_pars.dt) then begin
                  if degap_selection ne 'yestoall' && degap_selection ne 'notoall' Then Begin
                    degap_selection=''
                    if ~keyword_set(replay) then begin
                      lbl = ['Note that the median value of the time resolution for '+nn0+' is:'+strcompress(string(av_dt))+' sec.', $
                             'The value that you have chosen for the degap time resolution is smaller: '+$
                             strcompress(string(dp_pars.dt))+' sec.', $
                             'This will have non-intuitive and possibly non-plottable results. Do you want to continue?']
 
                      degap_selection = spd_ui_prompt_widget(gui_id,sbar,hwin,prompt=strjoin(lbl,ssl_newline()),title='SPEDAS GUI DEGAP TEST',/yes,/no,/allyes,/allno, frame_attr=8) 
                      degap_selections = array_concat_wrapper(degap_selection,degap_selections)
                    endif else begin
                      if degap_count ge n_elements(degap_selections) then begin
                        hwin->update,"ERROR:Discrepancy in spedas document, may have lead to a document load error"
                        sbar->update,"ERROR:Discrepancy in spedas document, may have lead to a document load error"
                        degap_selection = "yestoall"
                      endif else begin
                        degap_selection = degap_selections[degap_count]
                      endelse
                    endelse
                  endif
                  
                  degap_count++
                Endif
                
                If (av_dt le dp_pars.dt || (degap_selection ne 'notoall' && degap_selection ne 'no')) Then Begin
                    if dp_pars.opts[0] then str_element,_extra,'flag',dp_pars.flag, /add_replace
                    if dp_pars.opts[1] then str_element,_extra,'maxgap',dp_pars.maxgap, /add_replace
                    tdegap, varname, dt = dp_pars.dt[0], $
                            margin = dp_pars.margin[0], $
;                            maxgap = dp_pars.maxgap[0], $
                            newname = nn0+dp_pars.suffix[0], $
                            display_object=display_object, $
                            _extra = _extra
                    nn = tnames(nn0+dp_pars.suffix)

                Endif Else Begin
                    dproc_status_update,'Degap process for: '+nn0+' cancelled.', sbar, hwin
                    canceled = 1b ;prevent variable from being added later
                Endelse
              endif else begin
                dproc_status_update,'Unable to process '+nn0+' not enough elements', sbar, hwin
                canceled = 1b
              endelse
                
            End
            'pwrspc': Begin
;                popt = spd_ui_pwrspc_options(!spd_gui.guiid, hwin)
;                if popt.success eq 0 then return,''

;                spd_ui_pwrspc, nn0, nn, popt.trange, dynamic=popt.dynamic, $
;                               nboxpoints=popt.nboxpoints, $
;                               nshiftpoints=popt.nshiftpoints, $ 
;                               ;tbegin=popt.tbegin, tend=popt.tend, $
;                               bins=popt.bins, noline=popt.noline, $
;                               nohanning=popt.nohanning, notperhz=popt.notperhz
;                nn = tnames(nn0+'_?_dpwrspc')
;                store_data, tnames(nn0), /delete
;                store_data, tnames(nn0+'_?'), /delete
            End
            'wave': Begin
;              copy_data, varname, nn0  ;nn0 set equivalent to varname before case statement
;Test for memory
              get_data, varname, t
              sstx = where(t Ge dp_pars.trange[0] And $
                           t Lt dp_pars.trange[1], nsstx)
              If(nsstx Eq 0) Then Begin
                dproc_status_update,'No Data In Time Range. Processing next variable', sbar, hwin
                canceled =  1b ;prevent variable from being added later
              endif else if nsstx gt dp_pars.maxpoints then begin
                  dproc_status_update,'Too many time samples ('+strtrim(nsstx,2)+' > ' $
                                +strtrim(dp_pars.maxpoints,2)+'); Please set a higher max # of samples or a smaller time range.', sbar, hwin
                  canceled = 1b ;prevent variable from being added later
              Endif Else Begin
                t = t[sstx]
                memtest = spd_ui_wv_memory_test(temporary(t), jv)/1.0e6
;added error check for jv, wavelet, wave_data crash on too few data
;points if jv LT 2, jmm, 10-jun-2009
                If(jv LT 2) Then Begin
                  dproc_status_update,'Only'+strcompress(string(nsstx))+' Data Points. '+$
                    'Not Enough Data In Time Range. Processing next variable', sbar, hwin
                  canceled =  1b ;prevent variable from being added later
                Endif Else Begin 
                  mem_av = get_max_memblock2()
                  if double(memtest)/mem_av gt .01 then begin       
                    lbl = ['Estimated Memory usage for Wavelet for '+varname+' is: '+string(memtest, '(f10.2)')+' Mbytes, ', $
                           'You have an estimated '+string(mem_av, '(f10.2)')+' Mbytes, Continue?']
    
                    out = spd_ui_prompt_widget(gui_id, sbar, hwin, prompt = strjoin(lbl, ssl_newline()), title = 'SPEDAS GUI WAVELET MEMORY CHECK', /yes, /no) 
                    ok = out eq 'yes'?1:0 
                  endif else begin
                    ok = 1
                  endelse
                  If(ok) Then Begin
                    dproc_status_update,'Processing Wavelet for: '+varname, sbar, hwin
                    spd_ui_wavelet, varname, nn, dp_pars.trange, maxpoints=dp_pars.maxpoints, temp_names = temp_names, display_object=display_object
                   ;globs removed, not identifying all quantities accurately
                   ;  nn = tnames(nn0+'_?_wv_pow')
                   ;   nn = tnames(nn0+'?_wv_pow')
                    if is_string(temp_names) then begin
                      store_data, temp_names, /delete
                    endif
                  Endif Else Begin
                    dproc_status_update, 'Wavelet process for: '+varname+' cancelled.', sbar, hwin
                    canceled = 1b ;prevent variable from being added later
                  Endelse
;                  store_data, tnames(varname), /delete ;unnecessary as data isn't copied
                Endelse
              Endelse
            End
            'hpfilt': Begin
                get_data, nn0, t
                noktimes =  n_elements(t)
                if noktimes gt 1 then begin ; operation not valid on single time element
                    av_dt = median(t[1:*]-t)
                    If(av_dt Gt dp_pars.dt) then begin
                        if hpf_selection ne 'yestoall' && hpf_selection ne 'notoall' Then Begin
                            hpf_selection=''
                            if ~keyword_set(replay) then begin
                                lbl = ['Note that the median value of the time resolution for '+nn0+' is:'+strcompress(string(av_dt))+' sec.', $
                                       'The value that you have chosen for the averaging time resolution is smaller: '+$
                                       strcompress(string(dp_pars.dt))+' sec.', $
                                       'This will have non-intuitive and possibly non-plottable results. Do you want to continue?']
                                
                                hpf_selection = spd_ui_prompt_widget(gui_id,sbar,hwin,prompt=strjoin(lbl,ssl_newline()),title='SPEDAS GUI HPFILTER TEST',/yes,/no,/allyes,/allno, frame_attr=8)
                                hpf_selections = array_concat_wrapper(hpf_selection,hpf_selections)
                            endif else begin
                                if hpf_count ge n_elements(hpf_selections) then begin
                                    hwin->update,"ERROR:Discrepancy in spedas document, may have lead to a document load error"
                                    sbar->update,"ERROR:Discrepancy in spedas document, may have lead to a document load error"
                                    hpf_selection = "yestoall"
                                endif else begin
                                    hpf_selection = hpf_selections[hpf_count]
                                endelse
                            endelse
                        endif
                        hpf_count++
                    Endif
                    If (av_dt le dp_pars.dt[0] || (hpf_selection ne 'notoall' && hpf_selection ne 'no')) Then Begin
                        dt = dp_pars.dt[0]
                        thigh_pass_filter, varname, dt, newname = nn0+dp_pars.suffix[0], display_object=display_object, $
                          /interactive_warning,warning_result=warning_result, $
                          _extra = {interp_resolution: (dp_pars.seticad ? dp_pars.icad:0b)}
                        if n_elements(warning_result) gt 0 && warning_result eq 0 then break
                        nn = tnames(nn0+dp_pars.suffix)
                    Endif Else Begin
                        dproc_status_update,'High Pass Filter process for: '+nn0+' cancelled.', sbar, hwin
                        canceled = 1b ;prevent variable from being added later
                    Endelse
                endif else begin
                    dproc_status_update,'Unable to High Pass filter '+nn0+' not enough elements in time range.', sbar, hwin
                    canceled = 1b
                endelse
            End
        Endcase
        
        if keyword_set(joinflag) then continue
        
    Endif Else nn = ''
;varname is no longer needed ?
;    store_data, varname, /delete
    If(is_string(nn)) and (~canceled) Then Begin
;Add the new variables into the loaded_data object, this will create a
;new group

        For k = 0, n_elements(nn)-1 do begin
            spd_ui_check_overwrite_data,nn[k],self,gui_id,sbar,hwin,overwrite_selection,overwrite_count,$
                                 replay=replay,overwrite_selections=overwrite_selections
            if strmid(overwrite_selection, 0, 2) eq 'no' then continue   
            
            If(~otp) then begin ;only need 1 success for otp to be set to 1
                get_data, nn[k], data = dtest
                If(is_struct(temporary(dtest))) Then otp = 1b
            Endif
            ;The following 3 lines are important for ensuring that metadata
            ;associated with the old variables is also associated with the
            ;new variables.  Do not remove.

            if dpt eq 'wave' || dpt eq 'pwrspc' then begin
              isSpect = 1
            endif else begin
              tvarObject->getProperty,isSpect=isSpect
            endelse

            newObject = tvarObject->copy()
;            newObject->getProperty,dlimitptr=dlptr
;            str_element,*dlptr,'data_att.units','',/add
            ;newObject->setProperty,name=nn[k],isSpect=isSpect, coordsys='',dlimitptr=dlptr,units=''
            newObject->setProperty,name=nn[k],isSpect=isSpect, coordsys='',units=''  
            
            if self->addTvarObject(newObject,added_name=added_name) then begin
              dproc_status_update,'Added variable: '+nn[k], sbar, hwin
            endif else begin
              dproc_status_update,'Failed to add variable: '+nn[k], sbar, hwin
            endelse
        
            names_out = [names_out, nn[k]]
        endfor

    Endif Else Begin
        dproc_status_update,varname+' not processed.', sbar, hwin
        skipped = 1b
    Endelse
    if canceled or skipped then addmessage = 1b ; set flag to notify user later
    if double(!version.release) lt 8.0d then heap_gc                     ;clean-up memory
Endfor
;Reset active data to new variables, if there are any
If(otp) Then Begin
    If(is_string(names_out, names_out_ok)) Then Begin
        names_out = names_out_ok
        If(~keyword_set(no_setactive)) Then Begin
            self -> clearallactive
            For j = 0, n_elements(names_out)-1 Do Begin
                self -> setactive, names_out[j]
            Endfor
        Endif
    Endif
Endif

return_sequence:

;Notify user if quantities were dropped (this should be the last item added).
if addmessage then dproc_status_update, 'Finished.  Some quantities not processed. '+ $
                '  (Scroll back in status bar or check history window for details.)', sbar, hwin


;dump any tplot variables that you didn't start with
tnames_out = tnames()
If(is_string(tnames_out)) Then Begin
    If(is_string(tnames_in)) Then Begin
        For j = 0, n_elements(tnames_out)-1 Do Begin
            xx = where(tnames_in Eq tnames_out[j], nxx)
            If(nxx Eq 0) Then store_data, tnames_out[j], /delete
        Endfor
    Endif Else del_data, '*'    ;no variables when we started, so delete all
Endif

if otp && ~keyword_set(replay) then begin
  if n_elements(dp_pars) gt 0 then begin
    callSequence->addDprocOp,dp_task,in_vars,params=dp_pars,overwrite_selections,degap_selections,blkavg_selections
  endif else begin
    callSequence->addDprocOp,dp_task,in_vars,params=dp_pars,overwrite_selections,degap_selections,blkavg_selections
  endelse
endif

Return, otp
End

