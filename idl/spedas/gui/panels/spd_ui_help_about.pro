;+
;NAME:
;spd_gui_help_about
;PURPOSE:
; A widget to display About information (SPEDAS Version)
;
;$LastChangedBy: $
;$LastChangedDate:  $
;$LastChangedRevision: $
;$URL: $
;
;-
Pro spd_ui_help_about_event, ev

getresourcepath,rpath
fname = rpath+'UG_8.pdf'

  widget_control, ev.id, get_uvalue=uvalue
  CASE uvalue OF
    'SPEDASWEB' : begin
    spd_ui_open_url, 'http://spedas.ssl.berkeley.edu/'
  end
    'QUIT' : begin
      widget_control, ev.top, /destroy
    end    
  Endcase
  
end

Pro spd_ui_help_about, gui_id, historywin
  ;aboutlabel should show the SPEDAS version and some other info (perhaps build date, web site URL, etc)
  aboutString= ' SPEDAS 8.0 '  +  string(10B) + string(10B) + ' SPEDAS Data Analysis Software ' +  string(10B) + string(10B) + ' April 2013 ' + string(10B) + string(10B) +' http://spedas.ssl.berkeley.edu ' + string(10B) + string(10B) +' For support or bug reports, contact: SPEDAS_Science_Support@ssl.berkeley.edu '
  
  aboutBase = widget_base(/col, title = 'About', /modal, Group_Leader=gui_id)
  aboutLabel = widget_label(aboutBase, value=aboutString, /align_center, XSIZE=500, YSIZE=150, UNITS=0)
  spedasButton = widget_button(aboutBase, value = ' Go to http://spedas.ssl.berkeley.edu/ ', uvalue= 'SPEDASWEB', /align_center, scr_xsize = 300)
  
  aboutLabel = widget_label(aboutBase, value=' ', /align_center, XSIZE=500, YSIZE=20, UNITS=0)
  exitButton = widget_button(aboutBase, value = ' Close ', uvalue= 'QUIT', /align_center, scr_xsize = 150)
  
  widget_control, aboutBase, /realize
  xmanager, 'spd_ui_help_about', aboutBase, /no_block
end
