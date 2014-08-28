;+ 
;NAME:
; spd_ui_dproc_par::choose
;PURPOSE:
; Simple widget that allows user to input and/or choose parameter values
;CALLING SEQUENCE:
; new_value = spd_ui_dproc_par_choose(pars_object, label_xsize = label_xsize, $
;                                     button_xsize = button_xsize, $
;                                     title = title, buttons_on_top=buttons_on_top)
;INPUT:
; pars_object = an object of the type spd_ui_dproc_par the widget and
; values are set up using the parameters in the dp_struct structure
; for the object. While there are no constraints on what is contained
; in the structure when defining the object -- here the following tags
; are used in the structure:
;          plabel: parameter names (for widget labels), for N parameters
;          pvalue: string values of parameters, for N parameters, all
;                  of the i/o here returns string values
;          radio_array: an array of button values, can be 2d,
;                       row of values corresponds to a row of
;                       buttons on the widget, one choice is possible
;                       for each row. No buttons are shown for null
;                       values.
;          radio_value: A valid value for a choice for each row of
;                       radio buttons (n_elements(radio_array[*,0]))
;          radio_label: A valid value for a choice for each row of
;                       radio buttons (n_elements(radio_array[*,0]))
;OUTPUT:
; new_value = the output value of the parameters, a string array of values,
;             e.g., ['4.67', '3.0', ...n]
;             radio buttons were used the last elements of  the array
;             will contain the radio button selection,
;             e.g., ['4.67', '3.0', ..., 'inches', 'p']
;KEYWORDS:
; label_xsize = an xsize value for labels, allows for consistent
;               alignment, the default is 0
; button_xsize = an xsize value for buttons, allows for consistent
;                alignment
; title = a title for the widget
; buttons_on_top = If set, put the buttons on top
;METHODS:
; spd_ui_dproc_par_choose_event - event handler for the window
;                                 (handles parameter input, cancel/
;                                 accept buttons, and window close 'X'
; spd_ui_dproc_par_rad_event - event handler for the radio buttons;
; spd_ui_dproc_par__choose - creates the window, widgets, and calls
;                            the  xmanager
;HISTORY:
; 22-oct-2008, Hacked from spd_ui_npar_new, jmm, jimm@ssl.berkeley.edu
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas/gui/panels/spd_ui_dproc_par_choose.pro $
;-

Pro spd_ui_dproc_par_choose_event, event

;If the 'X' is hit...
  If(TAG_NAMES(event, /STRUCTURE_NAME) EQ 'WIDGET_KILL_REQUEST') Then Begin
    widget_control, event.top, get_uval = state, /no_copy
    state.pobj -> setproperty, dp_struct = {pvalue:'Cancelled'}
    widget_control, event.top, /destroy
    Return
  Endif
  widget_control, event.id, get_uval = uval
  If(uval Eq 'YES') Then Begin
    widget_control, event.top, /destroy
  Endif Else If(uval Eq 'NO') Then Begin
    widget_control, event.top, get_uval = state, /no_copy
    state.pobj -> setproperty, dp_struct = {pvalue:'Cancelled'}
    widget_control, event.top, /destroy
  Endif Else Begin
    widget_control, event.top, get_uval = state, /no_copy
    dp_struct = state.pobj -> getproperty(/dp_struct)
;No error check you can't be here if dp_struct.pvalue doesn't exist...
    j = fix(strmid(uval, 4))
    widget_control, event.id, get_val = temp_string
    dp_struct.pvalue[j] = temp_string
    state.pobj -> setproperty, dp_struct = dp_struct
    widget_control, event.top, set_uval = state, /no_copy
  Endelse
Return
End

Pro spd_ui_dproc_par_rad_event, event
; retrieve the radio button selection and save it
  widget_control, event.id, get_value = value
  widget_control, event.id, get_uval = uval
  widget_control, event.top, get_uval = state, /no_copy
  dp_struct = state.pobj -> getproperty(/dp_struct)
  j = fix(strmid(uval, 6))
  dp_struct.radio_value[j] = value
  state.pobj -> setproperty, dp_struct = dp_struct
  widget_control, event.top, set_uval = state, /no_copy
  Return
End

Function spd_ui_dproc_par_choose, pobj, title = title, $
                                  toplabel = toplabel, $
                                  bottomlabel = bottomlabel, $
                                  label_xsize = label_xsize, $
                                  button_xsize = button_xsize, $
                                  buttons_on_top = buttons_on_top, $
                                  par_pad = par_pad, $
                                  gui_id = gui_id, $
                                  _extra = _extra

  If(keyword_set(par_pad)) Then pp = par_pad Else pp = 10
  If(keyword_set(label_xsize)) Then xsz = label_xsize Else xsz = 0
  If(keyword_set(button_xsize)) Then bxsz = button_xsize Else bxsz = 0
;Unpack the object
  dp_struct = pobj -> getproperty(/dp_struct)
  If(is_struct(dp_struct) Eq 0) Then Begin
    otp = 'Cancelled due to lack of data.'
    Return, otp
  Endif
  dp_string = pobj -> getproperty(/dp_string)
  If(is_string(title)) Then ttl = title Else Begin
    If(is_string(dp_string)) Then ttl = 'Input Parameters for: '+dp_string[0] $
    Else ttl = 'Input Parameters: '
  Endelse
;set up the widget
  If(widget_valid(gui_id)) Then Begin
    master = widget_base(/col, title = ttl, /tlb_kill_request_events, $
                         group_leader = gui_id, /modal, /floating, tab_mode=1)
  Endif Else Begin
    master = widget_base(/col, title = ttl, /tlb_kill_request_events, tab_mode=1)
  Endelse
  If(keyword_set(toplabel)) Then Begin
    flabel = widget_label(master, value = toplabel, /align_center)
  Endif
;what are the names and parameters? At least 1 name and value input should
;exist, but if not we'll get by
  If(tag_exist(dp_struct, 'pvalue')) Then value = dp_struct.pvalue $
  Else value = ''

  n = n_elements(value)
  If(tag_exist(dp_struct, 'plabel')) Then Begin
    name = dp_struct.plabel
    If(n_elements(name) Ne n) Then $ ;this will never happen...
      name = 'Choose_par: '+strcompress(indgen(n))
  Endif Else name = 'Choose_par: '+strcompress(indgen(n))

;First use typed parameters, unless buttons_on_top is set
  If(Not keyword_set(buttons_on_top)) Then Begin
    typed_pars: n = n_elements(name)
    listw = lonarr(n)
    For j = 0, n-1 Do Begin
      uvalj = 'LIST'+strcompress(/remove_all, j)
      listid = widget_base(master, /row, /align_left)
      If(name[j] ne '') Then $
        flabel = widget_label(listid, value = name[j], xsize = xsz, /align_left)
      If(value[j] ne '') Then Begin ;This requires that the value be initialized
        listw[j] = widget_text(listid, value = value[j], $
                               xsiz = max(strlen(value[j]))+pp, $
                               ysiz = 1, uval = uvalj, $
                               /editable, /all_events)
      Endif
    Endfor
    If(keyword_set(buttons_on_top)) Then Goto, realize_widget
  Endif
;if the radio button option was used...
  If(tag_exist(dp_struct, 'radio_array')) Then Begin
    radio_array = dp_struct.radio_array
    nsel = n_elements(radio_array[0, *])
;Are there labels?
    button_label = 0b
    If(tag_exist(dp_struct, 'radio_label')) Then Begin
      radio_label = dp_struct.radio_label
      If(n_elements(radio_label) Eq nsel) Then button_label = 1b
    Endif
;Are there values?
    button_value = 0b
    If(tag_exist(dp_struct, 'radio_value')) Then Begin
      radio_value = dp_struct.radio_value
      If(n_elements(radio_value) Eq nsel) Then button_value = 1b
    Endif
;Set up button widget
    For j = 0, nsel-1 Do Begin
      uvalj = 'BUTTON'+strcompress(/remove_all, j)
      units_basej0 = widget_base(master, /row, /align_left)      
      If(button_label) Then $
        lbl = widget_label(units_basej0, value = radio_label[j], xsize = xsz, /align_left)
      units_basej = widget_base(units_basej0, /exclusive, /row, /align_left)
      temp = is_string(radio_array[*, j], rdarr)
      radio_buttonj = lindgen(n_elements(rdarr))
      For i = 0, n_elements(rdarr)-1 Do Begin
        radio_buttonj[i] = widget_button(units_basej, uval = uvalj, $
                                         val = rdarr[i], $
                                         event_pro = 'spd_ui_dproc_par_rad_event', $
                                         xsize = bxsz)
      Endfor
      loc = 0
      If(button_value) Then Begin
        loc = where(rdarr Eq radio_value[j])
        If(loc[0] Eq -1) Then loc = 0
      Endif
      widget_control, radio_buttonj[loc], /set_button
    Endfor
  Endif

  If(keyword_set(buttons_on_top)) Then Goto, typed_pars
  If(keyword_set(bottomlabel)) Then Begin
    flabel = widget_label(master, value = bottomlabel, /align_center)
  Endif

  realize_widget:
  xbuttons = widget_base(master, /row, /align_center)
  yes_button = widget_button(xbuttons, val = 'OK', $
                             uval = 'YES', /align_center)
  no_button = widget_button(xbuttons, val = 'Cancel', $
                            uval = 'NO', /align_center)
  
  state = {pobj:pobj}

  widget_control, master, set_uval = state, /no_copy
  widget_control, master, /realize
  xmanager, 'spd_ui_dproc_par_choose', master

;return everything in a string
  dp_struct = pobj -> getproperty(/dp_struct)
  If(tag_exist(dp_struct, 'pvalue')) Then value = dp_struct.pvalue $
  Else value = ''
  If(tag_exist(dp_struct, 'radio_value')) Then rvalue = dp_struct.radio_value $
  Else rvalue = ''

  otp = [value, rvalue]
  If(is_string(otp, otp_ok)) Then Return, otp_ok Else Return, ''

End
