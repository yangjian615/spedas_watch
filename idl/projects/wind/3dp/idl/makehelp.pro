;+
;BATCH FILE:	makehelp
;NAME:
;       makehelp
;PURPOSE:
;	Uses "mk_html_help2" to create an html help file
;       called  3dp_ref_man.html.  "help_3dp" will call
;       up a browser and open our on_line help facility, which
;       provides a link to the page generated by this procedure.
;INPUT:		none
;KEYWORDS:	N/A
;
;CREATED BY:	Jasper Halekas
;LAST MODIFICATION:	@(#)makehelp.pro	1.25   99/04/22
;-

mk_html_help2,title = 'Wind 3D Plasma Library'

;for i=0,n_elements(sourcedirs)-1 do $
;mk_html_help2,sourcedirs(i), '3dp_ref_man'+strcompress(i,/rem)+'.html', $
;title = 'Wind 3D Plasma Library',/crosslink,/print_purpose,clturbo='"', $
;/no_dirlist


exit
