;+
;PROCEDURE:	mvn_sta_get_kk2
;PURPOSE:	
;	Returns kk2 parameter for correcting ion suppression
;INPUT:		
;	time:		dbl		time of data to be returned
;
;KEYWORDS:
;
;CREATED BY:	J. McFadden
;VERSION:	1
;LAST MODIFICATION:  16/02/08
;MOD HISTORY:
;
;NOTES:	  
;	kk2 ion suppression correction may be limited to times after 20151101
;-
FUNCTION mvn_sta_get_kk2,time

kk2 = 3.5
if time_double(time) lt time_double('2016-01-13') then begin
	kk2= 3.5
endif
if time_double(time) lt time_double('2015-12-30') then begin				; this works for 
	t0 = time_double('2015-12-23')
	t1 = time_double('2015-12-30')
	kk2= 3.5
endif
if time_double(time) lt time_double('2015-12-16') then begin				; this works for 12-09,12-10
	t0 = time_double('2015-12-09')
	t1 = time_double('2015-12-16')
	kk2= 2.5 + (-4.0)*(time_double(time)-t0)/(t1-t0)	> 1.5				; works for 20151209-10 and 1.2*ngi_o2_cnts/(500.-45.*(pot<3.))
	kk2= 3.5
endif
if time_double(time) lt time_double('2015-12-02') then begin				; this works for 11-25,11-30
	t0 = time_double('2015-11-25')
	t1 = time_double('2015-12-02')
;	kk2= (3.5 + (-.8)*(time_double(time)-t0)/(t1-t0)) >3.0
	kk2= 3.8
endif
if time_double(time) lt time_double('2015-11-18') then begin				; this works for 11-11 to 11-18
	t0 = time_double('2015-11-11')
	t1 = time_double('2015-11-18')
	kk2= (3.8 + (-1.6)*(time_double(time)-t0)/(t1-t0)) >3.0
endif
if time_double(time) lt time_double('2015-11-04') then begin				; this works for 11-01 to 11-03
	t0 = time_double('2015-10-28')
	t1 = time_double('2015-11-04')
	kk2= (3.8 + (-1.6)*(time_double(time)-t0)/(t1-t0)) >3.3
;	kk2=3.3
;	if time_double(time) lt time_double('2015-11-01') then kk2=3.8
endif
if time_double(time) lt time_double('2015-10-21') then begin				; this works for 
	t0 = time_double('2015-10-14')
	t1 = time_double('2015-10-21')
	kk2= (4.0 + (-1.0)*(time_double(time)-t0)/(t1-t0)) >3.4
endif
if time_double(time) lt time_double('2015-10-07') then begin				; this works for 
	t0 = time_double('2015-09-30')
	t1 = time_double('2015-10-07')
	kk2= (3.8 + (-1.6)*(time_double(time)-t0)/(t1-t0)) >3.5
;	kk2=3.5
endif
if time_double(time) lt time_double('2015-09-23') then kk2=3.5
if time_double(time) lt time_double('2015-09-09') then kk2=3.8
if time_double(time) lt time_double('2015-08-26') then kk2=4.0
if time_double(time) lt time_double('2015-08-12') then kk2=4.5
if time_double(time) lt time_double('2015-07-29') then kk2=4.5


if time_double(time) lt time_double('2015-01-01') then kk2=1.5				; 


return,kk2

end
