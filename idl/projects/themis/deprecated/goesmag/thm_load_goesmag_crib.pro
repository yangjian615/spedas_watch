pro thm_load_goesmag_crib
;
; Examples of loading GOES data at command line
;
; The GOES routines have their own configuration routines,
; since the data products are in a different location than the
; THEMIS products.  goes_init will create a reasonable default
; configuration and save it in a file. goes_read_config and
; goes_write_config let you customize !goes in case you 
; are at SSL and don't need HTTP downloads, or if you have
; an alternate source for GOES products (e.g. a local mirror)
; 
; thm_load_goesmag calls the init routine internally, but
; respects any existing !goes variable that you've already set up.
;

goes_init

; Load a few days' worth of data
;
; We currently have data for Sept 2007 through June 2008

timespan,'2007-09-23',2,/days

; Probe names to use for GOES are g10, g11, and g12.
;
; The available data quantities are:
; Calibrated fluxgate magnetometer data in various coordinate systems: 
;   b_gei, b_gsm, b_enp  (enp being the native GOES coordinate system)
;   b_total (scalar, total field strength) 
;
; Satellite position
;   pos_gei pos_gsm
;   
; Satellite velocity (GEI only)
;   vel_gei
; 
; West geographic longitude and magnetic local time
;   longitude mlt
;
; Data quality flags
;   dataqual
;
; T1 and T2 magnetotorquer counts
;   t1_counts, t2_counts

thm_load_goesmag,probe='g10 g11 g12',datatype='pos_gsm longitude mlt b_gsm dataqual b_enp'

tplot,['*pos_gsm','*b_gsm']

stop
; The magnetometer data sometimes shows large spikes if the magnetotorquers
; are operating, so you might want to get rid of those periods.  Here,
; we'll just clip the B values to the range (-200, 200) nT.

tclip,'*b_*',-200.0,200.0

tplot,'*clip'
end
