
;+
; Purpose: A crib showing plotting options for 2D particle slices.
;         
;         Run "thm_ui_slice2d" on the IDL console to use for the GUI version.
;         (Also part of the Analysis menu on the main THEMIS GUI) 
;
; Notes:
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2013-12-18 15:17:19 -0800 (Wed, 18 Dec 2013) $
;$LastChangedRevision: 13704 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_part_slice2d_plot.pro $
;-

;===========================================================
; Load Data and create example slice
;===========================================================

; Set probe and time range
probe = 'b'
trange = time_double( '2008-02-26/' + ['04:52:30','04:53:00'])

; Get array of ESA particle distributions
;  - use GET_SUN_DIRECTION keyword to load sun direction vector (used in example below)
peib_arr = thm_part_dist_array(probe=probe, type='peib', trange=trange, /get_sun_direction)

; Get a basic x-y plane ESA slice in DSL 
thm_part_slice2d, peib_arr, slice_time=trange[0], timewin=30, $
                  /three_d_interp, part_slice=part_slice


; Plot the slice
thm_part_slice2d_plot, part_slice


stop


;===========================================================
; Ploting Options
;===========================================================


; Limit the x and y axes
; -----------------
thm_part_slice2d_plot, part_slice, xrange = [1500.,-1500], yrange = [1500.,-1500]


stop


; Change the range of the color contours,  increase the number of 
; levels for smoother gradients (default is 60 levels), and remove
; the contour lines
; -----------------
thm_part_slice2d_plot, part_slice, range = [1.E-14,1.E-8], levels = 120, $
                   olines = 0


stop


; Add contour lines with annotations to the previous plot
; -----------------
thm_part_slice2d_plot, part_slice, range = [1.E-14,1.E-8], levels = 120, $
                   olines = 8, /clabels


stop


; Change other options
;  -x/y = 0 is shown with dashed lines by default
;  -instrument or current energy limits are plotted by default
;  -bulk velocity projection plotted by default with red line 
;  -sun direction denoted by solid black line, the length is 
;   proportional to the projection's magnitude (if the vector is
;   in the slice plane it will be drawn to the instrument's limit)
;  **sun direction requires keyword to thm_part_dist_array
;    (called above) to load state data
; -----------------
thm_part_slice2d_plot, part_slice, $
;                   plotbulk = 0, $ ;turn off bulk velocity projection
                   plotaxes = 0, $ ;turn off x/y=0
                   ecircle = 0,  $ ;turn off E limit circles
                   sundir = 1      ;plot sun direction
                   


stop


; Increase font size
;  -CHARSIZE is treated as a multiplier for font size, 1 being the default
; -----------------
thm_part_slice2d_plot, part_slice, charsize = 1.6


stop


; Set custom main title, x-axis title, and y-axis titles
; -----------------
thm_part_slice2d_plot, part_slice,  $
                   title = 'This is the title!', $
                   xtitle='I''m the x-axis!', ytitle='I''m the y-axis!' 


stop


; Set custom number of ticks for each axis
;  -set major ticks with [XYZ]TICKS
;  -set minor ticks with [XY]MINOR
; -----------------
thm_part_slice2d_plot, part_slice, $
                   xticks=7, yticks=15, zticks=22, $
                   xminor=4, yminor=2  


stop


; Increase the size of the plot
;  -plot size is taken in pixels, default is 500
; -----------------
thm_part_slice2d_plot, part_slice, plotsize = 750


stop


; Set custom annotation options
;  -set [XYZ]STYLE to 0,1,2 for auto/decimal/scientific notation respectively
;  - use[XYZ]PRECISION to controls how many significant figures 
;    to display. For auto-format the precision determins when
;    scientific notation will be used instead of decimal
;   
;  -this example demonstrates decimal format for the x axis
; -----------------
thm_part_slice2d_plot, part_slice, $
                   xticks = 4, $     ;custom ticks for non-round #s
                   xprecision = 8, $ ;8 sig figs
                   xstyle = 1        ;use decimal format
                   

stop


; Set custom annotation options (cont.)
;  -use scientific notation for the x/y axes
; -----------------
thm_part_slice2d_plot, part_slice, $
                   xprecision = 2, $ ;2 sig figs
                   yprecision = 2, $ ;2 sig figs
                   xstyle=2, $    ;use scientific notation
                   ystyle=2       ;use scientific notation


stop


; Set custom annotation options (cont.)
;  This example demonstrates adding precision to z axis, 
;  and supressing minor ticks on the x/y axes
; -----------------
thm_part_slice2d_plot, part_slice, $
                   xminor = 0, $    ;supress minor ticks
                   yminor = 0, $    ;supress minor ticks
                   zprecision = 6   ;6 sig figs for z annotations


stop


;===========================================================
; Plotting Options overview: 
;   The following is a list of all plotting keywords available
;   for use with thm_part_slice2d_plot.
;===========================================================
;
;levels = 120 ; change the number color contours, default is 60 
;olines = 8 ; change the number of contour lines

;zrange = [1.E-14,1.E-8]  ; limit data range for plotting
;xrange = [1500.,-1500]  ; specify x-range to plot
;yrange = [1500.,-1500]  ; specify y-range to plot

;logplot = 1 ; use log scaling on z axis (defalt=1)

;[xyz]ticks = 8  ; change # of tick marks
;[xyz]minor = 2  ; change # of minor tick marks
;[xyz]style = 0  ; change numerical format
                 ; (0=automatic, 1=decimal, 2=scientific)
;[xyz]precision  ; specify number of siginificant digits to display

;charsize = 1.20 ; set text to 120% size (default=1.00)

;sundir = 1    ; plot projection of sun direction (default=0)
;plotaxes = 1  ; plot dashed lines along x=0 and y=0 (default=1)
;ecircle = 1   ; plot energy limits (default=0)
;plotbulk = 1  ; plot projection of bulk velocity (default=1) 

;title = 'New Title'            ;Set custom title for plot
;[xyz]title = 'New Axis Title'  ;Set custom title for specified axis

;clabels = 1 ; annotate contour lines (default=0)

;plotsize = 700 ; change size of plot of screen (default=500) 

;window = 2 ; change which IDL window the plot is drawn in

;export = '/home/my_dir/filename' ; automatically export plot, png used by default
;eps = 1  ; export to postscript instead of png

END