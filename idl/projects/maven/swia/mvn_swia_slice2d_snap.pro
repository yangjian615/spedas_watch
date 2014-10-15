;+
; PROCEDURE:
;       mvn_swia_slice2d_snap
; PURPOSE:
;       Plots 2D slice for the times and data types selected by cursor.
;       Hold down the left mouse button and slide for a movie effect.
; CALLING SEQUENCE:
;       mvn_swia_snap
; INPUTS:
;       
; KEYWORDS:
;       same as 'slice2d' except ARCHIVE: Returns archive distribution
;       instead of survey
; CREATED BY:
;       Yuki Harada on 2014-10-10
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2014-10-10 10:27:10 -0700 (Fri, 10 Oct 2014) $
; $LastChangedRevision: 15974 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_slice2d_snap.pro $
;-

pro mvn_swia_slice2d_snap, archive=archive, rotation=rotation, angle=angle, thirddirlim=thirddirlim, xrange=xrange, range=range, erange=erange, units=units, nozlog=nozlog, position=position, nofill=nofill, nlines=nlines, noolines=noolines, numolines=numolines, removezero=removezero, showdata=showdata, vel=vel, nogrid=nogrid, nosmooth=nosmooth, sundir=sundir, novelline=novelline, subtract=subtract, resolution=resolution, isotropic=isotropic

dsize = get_screen_size()

;- set up windows

;- tplot window (current window)
Twin = !d.window

;- slice2d window
window, /free, xsize=dsize[0]/2., ysize=dsize[1]*2./3., $
        xpos=0., ypos=0.
Dwin = !d.window

print, 'Use button 1 to select time; button 3 to quit.'

wset,Twin
tplot
ctime,t,npoints=1,/silent,vname=vname

ok = 1
while (ok) do begin

   get3d_func = ''
   if strmatch(vname,'*swif*') eq 1 then get3d_func = 'mvn_swia_get_3df'
   if strmatch(vname,'*swic*') eq 1 then get3d_func = 'mvn_swia_get_3dc'

   if get3d_func ne '' then begin
      d = call_function(get3d_func,t,archive=archive)

      wset,Dwin
      slice2d,d, rotation=rotation, angle=angle, thirddirlim=thirddirlim, xrange=xrange, range=range, erange=erange, units=units, nozlog=nozlog, position=position, nofill=nofill, nlines=nlines, noolines=noolines, numolines=numolines, removezero=removezero, showdata=showdata, vel=vel, nogrid=nogrid, nosmooth=nosmooth, sundir=sundir, novelline=novelline, subtract=subtract, resolution=resolution, isotropic=isotropic

   endif

   wset,0
   ctime,t,npoints=1,/silent,vname=vname
   if (data_type(t) eq 5) then ok = 1 else ok = 0
endwhile



end
