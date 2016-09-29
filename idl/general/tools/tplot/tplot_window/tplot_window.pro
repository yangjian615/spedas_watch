;+
;NAME:
; tplot_window
;PURPOSE:
; to allow various widget-like features in a tplot window, this is
; accomplished by setting up the window as a draw object.
;CALLING SEQUENCE:
; tplot_window, tplot_vars
;INPUT:
; tplot_vars = tplot variable names or numbers
;OUTPUT:
; no explicit output, just plots
;KEYWORDS:
; Same as tplot.pro:
;   TITLE:    A string to be used for the title. Remembered for future plots.
;   ADD_VAR:  Set this variable to add datanames to the previous plot.  If set
;         to 1, the new panels will appear at the top (position 1) of the
;         plot.  If set to 2, they will be inserted directly after the
;         first panel and so on.  Set this to a value greater than the
;         existing number of panels in your tplot window to add panels to
;             the bottom of the plot.
;   LASTVAR:  Set this variable to plot the previous variables plotted in a
;         TPLOT window.
;   PICK:     Set this keyword to choose new order of plot panels
;             using the mouse.
;   WINDOW:   Window to be used for all time plots.  If set to -1, then the
;             current window is used.
;   VAR_LABEL:  String [array]; Variable(s) used for putting labels along
;     the bottom. This allows quantities such as altitude to be labeled.
;   VERSION:  Must be 1,2,3, or 4 (3 is default)  Uses a different labeling
;   scheme.  Version 4 is for rocket-type time scales.
;   OVERPLOT: Will not erase the previous screen if set.
;   NAMES:    The names of the tplot variables that are plotted.
;   NOCOLOR:  Set this to produce plot without color.
;   TRANGE:   Time range for tplot.
;   NEW_TVARS:  Returns the tplot_vars structure for the plot created. Set
;         aside the structure so that it may be restored using the
;             OLD_TVARS keyword later. This structure includes information
;             about various TPLOT options and settings and can be used to
;             recreates a plot.
;   OLD_TVARS:  Use this to pass an existing tplot_vars structure to
;     override the one in the tplot_com common block.
;   GET_PLOT_POSITION: Returns an array containing the corners of each
;     panel in the plot, to make it easier to overplot and annotate plots
;   HELP:     Set this to print the contents of the tplot_vars.options
;         (user-defined options) structure.
;HISTORY:
; 2016-09-23, jmm, jimm@ssilberkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2016-09-28 10:22:45 -0700 (Wed, 28 Sep 2016) $
; $LastChangedRevision: 21956 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tools/tplot/tplot_window/tplot_window.pro $
;-
Pro tplot_window_event, event

@tplot_com
;Insert catch here so that state remains defined
  err0 = 0
  catch, err0
  If(err0 Ne 0) Then Begin
     catch, /cancel
     help, /last_message, output = err_msg
     For j = 0, n_elements(err_msg)-1 Do print, err_msg[j]
     If(is_struct(state)) Then Begin
        widget_control, event.top, set_uval = state, /no_copy
     Endif
     Return
  Endif
  
  ;kill request block, note this is the only way to exit
  If(TAG_NAMES(event, /STRUCTURE_NAME) EQ 'WIDGET_KILL_REQUEST') Then Begin
  exit_sequence:
    widget_control, event.top, /destroy
    Return
  Endif

;what sort of events, only keystrokes to start
  If(tag_exist(event, 'type') && (event.type Eq 5 || event.type Eq 6)) Then Begin
     If(event.release Eq 1) Then Begin
        If(~is_struct(tplot_vars) || ~is_struct(tplot_vars.options)) Then Return
;Figure out where we are in non-device coordinates
        widget_control, event.top, get_uval = state, /no_copy
        tplot, verbose=0, get_plot_pos = ppp
;Now some xtplot hacks
        geo = widget_info(state.draw_widget, /geo) ;widget geometry
        trange = timerange(/current)
        x = event.x
        time = ((event.x/geo.xsize)-ppp[0, 0])*$
               ((trange[1]-trange[0])/(ppp[2, 0]-ppp[0, 0]))+$
               trange[0]
        time = (time < trange[1]) > trange[0]
;        dprint, dlevel=4, print, time_string(time)
;        dprint, dlevel=4, event.x, event.y
        widget_control, event.top, set_uval = state, /no_copy
;What key did i press? 
        If(event.type Eq 5) Then Begin
           keyval = strlowcase(string(event.ch))
           Case keyval of
              'z': Begin        ;If 'z', then zoom in by 50%
                 dt0 = trange[1]-trange[0]
                 dt1 = dt0/4.0  ;25% on either side of the point
                 tlimit, time-dt1, time+dt1
              End
              'o':Begin         ;zoom out by 200%
                 dt1 = trange[1]-trange[0]
                 tmid = 0.5*(trange[1]+trange[0])
                 tlimit, tmid-dt1, tmid+dt1
              End
              'r': Begin        ;If 'r' go back to initial time range
                 tlimit, tplot_vars.options.trange_full[0], $
                         tplot_vars.options.trange_full[1]
              End
              't':Begin         ;If t, just call tlimit
                 tlimit
              End
              'b':Begin         ;If 'b' shift back by 25%
                 dt0 = trange[1]-trange[0]
                 dt1 = dt0/4.0  ;25% on either side of the point
                 tlimit, trange[0]-dt1, trange[1]-dt1
              End
              'f':Begin         ;If 'f' shift forward by 25%
                 dt0 = trange[1]-trange[0]
                 dt1 = dt0/4.0  ;25% on either side of the point
                 tlimit, trange[0]+dt1, trange[1]+dt1
              End
              Else:Begin
              End
           Endcase
        Endif Else If(event.type Eq 6) Then Begin ;arrow keys
           keyval = event.key
           Case keyval of
              5:Begin           ;left arrow If 'b' shift back by 25%
                 dt0 = trange[1]-trange[0]
                 dt1 = dt0/4.0  ;25% on either side of the point
                 tlimit, trange[0]-dt1, trange[1]-dt1
              End
              6:Begin           ;right arrow shift forward by 25%
                 dt0 = trange[1]-trange[0]
                 dt1 = dt0/4.0  ;25% on either side of the point
                 tlimit, trange[0]+dt1, trange[1]+dt1
              End
              7: Begin          ;up arrow then zoom in by 50%
                 dt0 = trange[1]-trange[0]
                 dt1 = dt0/4.0  ;25% on either side of the point
                 tlimit, time-dt1, time+dt1
              End
              8:Begin           ;down arrow zoom out by 200%
                 dt1 = trange[1]-trange[0]
                 tmid = 0.5*(trange[1]+trange[0])
                 tlimit, tmid-dt1, tmid+dt1
              End
              Else:Begin
              End
           Endcase
        Endif
     Endif
  Endif
  
  If(is_struct(state)) Then widget_control, event.top, $
                                            set_uval = state, /no_copy
Return
End

Pro tplot_window, datanames, $
   NOCOLOR = nocolor,     $
   VERBOSE = verbose,     $
   wshow = wshow,         $
   OPLOT = oplot,         $
   OVERPLOT = overplot,   $
   VERSION = version , $
   TITLE = title,         $
   LASTVAR = lastvar,     $
   ADD_VAR = add_var,     $
   LOCAL_TIME= local_time,$
   REFDATE = refdate,     $
   VAR_LABEL = var_label, $
   OPTIONS = opts,        $
   T_OFFSET = t_offset,   $
   TRANGE = trng,         $
   NAMES = names,         $
   PICK = pick,           $
   new_tvars = new_tvars, $
   old_tvars = old_tvars, $
   datagap = datagap,     $
   get_plot_position=pos, $
   xsize = xsize, $
   ysize = ysize, $
   help = help

  common tplot_window_private, state

;create a widget
  master = widget_base(/row, title = 'tplot window ', $
                       /align_top, /tlb_kill_request_events)
;Define a state structure
  state = {master:master, $
           window_id:-1L, $
           ww0:'', $
           draw_widget:-1L}

;add a draw widget
  If(keyword_set(xsize)) Then xsz0 = xsize Else xsz0 = 960
  If(keyword_set(ysize)) Then ysz0 = ysize Else ysz0 = 600
  id0 = widget_draw(master, xsize = xsz0, ysize = ysz0, $
;                    /button_events, /motion_events, /tracking_events, $
                   /keyboard_events)
  state.draw_widget = id0

  widget_control, master, set_uval = state;, /no_copy
  widget_control, master, /realize
  xmanager, 'tplot_window', master, /no_block
  state.window_id = !d.window
  state.ww0 = strcompress(string(!d.window))
  widget_control, master, tlb_set_title = 'tplot window '+state.ww0

  tplot, datanames, $
         WINDOW = -1, $
         NOCOLOR = nocolor,     $
         VERBOSE = verbose,     $
         OPLOT = oplot,         $
         OVERPLOT = overplot,   $
         VERSION = version , $
         TITLE = title,         $
         LASTVAR = lastvar,     $
         ADD_VAR = add_var,     $
         LOCAL_TIME= local_time,$
         REFDATE = refdate,     $
         VAR_LABEL = var_label, $
         OPTIONS = opts,        $
         T_OFFSET = t_offset,   $
         TRANGE = trng,         $
         NAMES = names,         $
         PICK = pick,           $
         new_tvars = new_tvars, $
         old_tvars = old_tvars, $
         get_plot_position=pos,$
         help = help
;GO ahead an apply any time and databars
  tplot_apply_timebar
  tplot_apply_databar

Return
End

