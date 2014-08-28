;+
;pro thm_crib_gmag
; This is an example crib sheet that will load ground mag data.
; Open this file in a text editor and then use copy and paste to copy
; selected lines into an idl window. Or alternatively compile and run
; using the command:
; .RUN THM_CRIB_GMAG
;-

print, "--- Start of crib sheet ---"
!quiet=1                             ;  Turn off annoying screen messages.
wset,0
pos=ptrace(option=1)                 ;  Set program trace to display line numbers.
del_data,'*'                         ;  Delete all TPLOT variables.
erase                                ;  Clear the screen.
timespan,'6-10-2',2,/days            ;  Define the time span of interest.

thm_load_gmag,site='bmls ccnv fykn',/subtract_average  ;Loads data from three sites and subtracts average from loaded variables  

; Use 'site' to load data from specfic site. If no sites are specified all sites will be loaded. 
; To load sites from specific networks use keywords /thm_sites (THEMIS GBO network), /tgo_sites (TGO network), /dtu_sites (DTU network),
;  /ua_sites (University of Alaska sites), /maccs_sites (MACCS network).
;  e.g. thm_load_gmag, /thm_sites, /subtract_average
;  will load all sites in THEMIS GBO network with data for chosen dates and subtract averages from loaded variables.
;  See thm_load_gmag for details of sites in each network and cribs thm_crib_greenland_gmag, thm_crib_maccs_gmag .
; /subtract_average subtracts the average from the loaded variables.
; Use keyword /subtract_median to subtract the median instead.

options,'thg_mag_????',labels=['Bx','By','Bz']
tplot_options, 'title', 'GMAG Examples'
print
print,'Defined TPLOT Variables;'
tplot_names ,/time                   ;  Display all stored variables
print
print,ptrace(),'             Deleted old data, (down)loaded GMAG Data, and Displayed tplot names'
print,ptrace(),'             Note that 3 sites were loaded each with 2 days of data.'
print,ptrace(),'             All files are downloaded automatically if not found.' ;to use only local files, use the keyword /no_download with thm_load_gmag
stop


wshow,0                                ; Raise window
tplot,"thg_mag_????"                   ; tplot accepts wildcard characters
print,ptrace(),'             Plotted all TPLOT variables that match "thg_mag_????" '
stop


split_vec,'thg_mag_ccnv'               ; Split one of the 3 vectors into components
options,'*_[xyz]' ,/ynozero
tplot,'thg_mag_ccnv*'
print,ptrace(),'             Split the 3 vector into its components.  Plot them'
stop


wshow,0
tr = ['2006-10-2/16:00','2006-10-3/05']  ; Define a time range
timebar,tr                               ; Display it
print,ptrace(),'             Define and Display a time range'
stop



tlimit,tr                               ; Zoom into the time range
print,ptrace(),'             Zoom into the defined time range'
stop



                                   ; Compute the wavelet transform of x component
print,ptrace(),'             Computing wavelet transform. Please wait.....'
wav_data,'thg_mag_ccnv_x',/kol  ,trange=tr   ,maxpoints=24l*3600*2
zlim,'*pow', .0001,.01,1           ; Set color limits (log scale)
wshow,0,icon=0
tplot,'*ccnv_x*',trange=tr         ; PLOT the wavelet transform
print,ptrace(),'             Computed wavelet transform of one component and plot it.'
stop



tr2 = ['2006-10-03/02:13:30', '2006-10-03/03:46:00']
timebar,tr2                        ;  Display region with Pi2 waves
wshow,0
print,ptrace(),'             Identify region with Pi2 waves'
stop



tlimit,tr2              ;
print,ptrace(),'             Zoom of region with Pi2 waves'
stop



tlimit,tr
tr1   =  ['2006-10-02/18:23:00', '2006-10-02/18:49:30']
timebar,tr1
print,ptrace(),'             Zoomed out again and displayed region with PC1(?) waves'
stop



tlimit,tr1
print,ptrace(),'             Zoom of region with Pc1 waves: [',strjoin(time_string(tr1,tformat='hhmm:ss'),' to '),']'
stop





tlimit,tr
print,ptrace(),'             Select your own time range of interest:  '
print,ptrace(),'             (left click to select time, right click to end)
wshow,0,icon=0
ctime,my_tr,/silent
if n_elements(my_tr) eq 2 then begin
  tlimit,my_tr
endif else begin
  print,ptrace(),'             Invalid selection, must select two time to degine a time range.'
  print,ptrace(),'             Proceeding to next example.'
endelse
stop



; Produce a plot showing the location of all gmag stations
; Similar to the ones shown on the THEMIS website
thm_gmag_stations, label, location

loadct,0 ; change this to plot in colour

set_plot,'z'
device,set_resolution=[750,500]
chars=1.0

; edit lat/long and scale to display map as you'd like it
; below multiple maps are overlayed to draw country and us borders
map_set,58.5,-108,0.,/stereo,/conti,scale=2.8e7,$
   color=250,title='GMAG Stations'
borders=tvrd()
erase
map_set,58.5,-108,0.,/stereo,/conti,scale=2.8e7,$
   /usa,e_continents={COUNTRIES:1},color=100
usaborders=tvrd()
erase
map_set,58.5,-108,0.,/stereo,/conti,scale=2.8e7,$
   color=255,e_continents={FILL:1}
color_map=tvrd()
erase
color_map[where(usaborders eq 100)]=150
color_map[where(color_map eq 0)]=200
color_map[where(borders eq 250)]=1

tv,color_map
   
; plot the actual station locations. Edit settings to get the display the way you want it.
for i=0.1,0.7,0.1 do plots,location[1,*],location[0,*],color=0,psym=4,symsize=i
for i=0,n_elements(label)-1 do xyouts,location[1,i],location[0,i]+0.5,$
 label[i],charsize=chars,charthick=2,color=0,alignment=0.5
 
for i=5,85,5 do plots,findgen(361),fltarr(361)+i,line=1,color=1
for i=0,360,30 do plots,fltarr(91)+i,findgen(91),line=1,color=1

image=tvrd()
device,/close
case !version.os_family of
'Windows': os='win'
'unix': os='x'
endcase

set_plot,os
window,5,xsize=750,ysize=500
tv,image

print, ptrace(),'             Plot the locations of all gmag stations available through TDAS'
stop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; this section shows how to find when ground mag data is 
; available within a certain latitude/longitude range
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; set the time range
trange = ['2012-05-10/11:00:00', '2012-05-10/15:00:00']

; load data for all stations
thm_load_gmag, trange = trange 

; get a list of the ground mag tplot variables
tnames_list = tnames('thg_mag*')

; set the latitude range
latitude_range = [60, 65]
; set the longitude range
longitude_range = [0, 180]

; loop through the tplot variables
for tnum = 0, n_elements(tnames_list)-1 do begin
    get_data, tnames_list[tnum], dlimits=dl
    ; check that the 'cdf' tag exists
    if tag_exist(dl, 'cdf') then begin
        str_element, dl.cdf.vatt, 'station_latitude', latitude, SUCCESS=slat
        str_element, dl.cdf.vatt, 'station_longitude', longitude, SUCCESS=slong
        if (slat ne 0 and slong ne 0) then begin
            ; check the latitude range
            if (latitude ge latitude_range[0] and latitude le latitude_range[1]) then begin
                ; check the longitude range
                if (longitude ge longitude_range[0] and longitude le longitude_range[1]) then begin
                    print, tnames_list[tnum], ' is at: ', string(latitude), ' deg latitude, ', string(longitude), ' deg longitude'
                endif
            endif
        endif 
    endif 
endfor
stop
thm_init,/reset
; if you like the output you can save the variable image into a gif-file
; write_gif, 'filename.gif',tvrd()
print, "--- End of crib sheet ---"


end

