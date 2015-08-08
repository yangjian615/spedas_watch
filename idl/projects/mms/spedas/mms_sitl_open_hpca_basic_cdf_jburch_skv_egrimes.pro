;; MMS_SITL_OPEN_HPCA_BASIC_CDF.PRO
;===========================================================
;    ****** NOTE by egrimes@igpp ******
;    
;    This is a temporary commit of mms_sitl_open_hpca_basic_cdf 
;    until the updated, procedure version is committed to the repo.
;    
;    This is mostly for testing. My only changes to this so far
;    have been to add the "tplotnames" keyword and a call to 
;    append_array after each call to store_data, to store the 
;    newly created tplot variables in the tplotnames array - this is
;    required by time clipping in the mms_load_data routine, as 
;    well as GUI import code
;    
;    I also added a timer for testing performance
;
;============================================================
;
;
; Read HPCA CDF and create TPLOT variables
; Called by MMS_SITL_GET_HPCA_BASIC
; 
; CALLING SEQUENCE:
;   mms_sitl_open_hpca_basic_cdf, filenames, sc_id=, measurement_id=, [species=, fov=, /support]
;
; INPUTS:
;   FILENAMES - String array of data files to be opened
;
;   SC_ID - String specifying the MMS observatory, 'mms1' (default)
;
;   MEASUREMENT_ID - [integer array]
;   1 - 'Counts' ==> 'mms1_hpca_'+species'                     (Normalized counts)
;   2 - 'Count_Rate' ==> 'mms1_hpca_'+species+'_count_rate'    (Counts per 625 ms)
;   3 - 'Flux' ==> 'mms1_hpca_'+species+'_flux'                (Energy flux?  Differential Flux? 
;                                                               Particle Flux? Not sure... For now, units are
;                                                               [cm^2 s sr eV]^-1)
;   4 - 'Vel_Distr' ==> 'mms1_hpca_'+species+'_vel_dist_fn'    (Velocity distribution function,
;                                                               not sure of units, going with m^-6 s^3 for now)
;   5 - 'RF_corr' ==> 'mms1_hpca_'+species+'_RF_corrected'     (Looks like counts, so that's what 
;                                                               we're going with)
;   6 - 'Bkgd_corr' ==> 'mms1_hpca_'+species+'_bkgd_corrected' (Also looks like counts)
;   
;
; OPTIONAL INPUTS:
;  SPECIES - [integer array] Species of ion for each measurement. Must
;            be same size as MEASUREMENT_ID array. If not set, then
;            defaults to all species for each measurement.
;  1 - H+ 
;  2 - He+ 
;  3 - He+2 (alphas)
;  4 - O+
;  5 - O+2 (O double-plus) (No background corrected measurements)
;  6 - Background  (only has Normalized Counts)
;  7 - All (all species for that measurement) 
;
;  FOV - [elevation_1, elevation_2]
;  If not set, then sums over all anodes. Will incorporate azimuth
;  when pitch angles are wanted. For now, allowed elevation angles
;  are 0 - 180 deg. To specify one angle (there will be at least 2 
;  anodes for each angle), elevation_1 = elevation_2  
;
; OPTIONAL KEYWORDS:
;  /SUPPORT -  When the keyword /support is set, datasets included in structure:
;    Data Quality Indicator ==> 'mms1_hpca_'+species+'_data_quality'  
;    Background Subtraction Value ==> 'mms1_hpca_bkgd_constant'
;    Science Mode ==> 'mms1_hpca_science_mode' 
;
;  DATA REQUIRED AND RETRIEVED FOR EVERY MEASUREMENT
;  Time ==> 'Epoch'
;  Energies ==> 'mms1_hpca_ion_energy'
;  Anodes ==> 'mms1_hpca_polar_anode_number', 'mms1_hpca_center_theta' (degrees)
;
; OUTPUT:
;   TPLOT Variables - Ex: 'MMS1_HPCA_H+_NORM_COUNTS_ELEV_0-180', which
;                     plots an energy-time spectrogram of H+ counts summed over all
;                     anodes with appropriate axes, titles, and color bar.
;
;
; Modified for HPCA by Sarah Vines
;
;  $LastChangedBy: egrimes $
;  $LastChangedDate: 2015-08-07 12:05:36 -0700 (Fri, 07 Aug 2015) $
;  $LastChangedRevision: 18426 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/mms_sitl_open_hpca_basic_cdf_jburch_skv_egrimes.pro $

;  HPCA ION STRUCTURE VARIABLES
      ;;  0  Epoch
      ;;  1  Epoch_MINUS
      ;;  2  Epoch_PLUS
      ;;  3  mms1_hpca_apid
      ;;  4  mms1_hpca_polar_anode_number
      ;;  5  mms1_hpca_azimuth_decimation_factor
      ;;  6  mms1_hpca_polar_decimation_factor
      ;;  7  mms1_hpca_energy_decimation_factor
      ;;  8  mms1_hpca_sweep_table_number
      ;;  9  mms1_hpca_start_azimuth
      ;; 10  mms1_hpca_start_energy
      ;; 11  mms1_hpca_science_mode
      ;; 12  mms1_hpca_ion_energy
      ;; 13  mms1_hpca_bkgd
      ;; 14  mms1_hpca_bkgd_data_quality
      ;; 15  mms1_hpca_hplus
      ;; 16  mms1_hpca_hplus_data_quality
      ;; 17  mms1_hpca_heplus
      ;; 18  mms1_hpca_heplus_data_quality
      ;; 19  mms1_hpca_heplusplus
      ;; 20  mms1_hpca_heplusplus_data_quality
      ;; 21  mms1_hpca_oplus
      ;; 22  mms1_hpca_oplus_data_quality
      ;; 23  mms1_hpca_bkgd_constant
      ;; 24  mms1_decimation_factor_index
      ;; 25  mms1_hpca_oplusplus
      ;; 26  mms1_hpca_oplusplus_RF_corrected
      ;; 27  mms1_hpca_oplusplus_count_rate
      ;; 28  mms1_hpca_oplusplus_flux
      ;; 29  mms1_hpca_oplusplus_vel_dist_fn
      ;; 30  mms1_hpca_oplusplus_data_quality
      ;; 31  mms1_hpca_hplus_RF_corrected
      ;; 32  mms1_hpca_hplus_count_rate
      ;; 33  mms1_hpca_hplus_flux
      ;; 34  mms1_hpca_hplus_vel_dist_fn
      ;; 35  mms1_hpca_hplus_bkgd_corrected
      ;; 36  mms1_hpca_heplus_RF_corrected
      ;; 37  mms1_hpca_heplus_count_rate
      ;; 38  mms1_hpca_heplus_flux
      ;; 39  mms1_hpca_heplus_vel_dist_fn
      ;; 40  mms1_hpca_heplus_bkgd_corrected
      ;; 41  mms1_hpca_heplusplus_RF_corrected
      ;; 42  mms1_hpca_heplusplus_count_rate
      ;; 43  mms1_hpca_heplusplus_flux
      ;; 44  mms1_hpca_heplusplus_vel_dist_fn
      ;; 45  mms1_hpca_heplusplus_bkgd_corrected
      ;; 46  mms1_hpca_oplus_RF_corrected
      ;; 47  mms1_hpca_oplus_count_rate
      ;; 48  mms1_hpca_oplus_flux
      ;; 49  mms1_hpca_oplus_vel_dist_fn
      ;; 50  mms1_hpca_oplus_bkgd_corrected
      ;; 51  mms1_hpca_center_theta




PRO mms_sitl_open_hpca_basic_cdf_jburch_skv_egrimes, filenames, sc_id = sc_id, measurement_id = measurement_id, $
   species = species, fov = fov, support = support, tplotnames = tplotnames

   ; what time is it? for quantifying time in this routine
   start_time = systime(/sec)
sp_name=['hplus','heplus', 'heplusplus', 'oplus','oplusplus','bkgd']
;stop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; OPENING CDFs AND RETRIEVING REQUESTED DATA

FOR hh = 0, n_elements(filenames)-1 DO BEGIN
   filename = filenames(hh)
  
; checking to make sure there is at least 1 measurement id or support
; data requested
  IF ~keyword_set(measurement_id) and ~keyword_set(support) THEN BEGIN
     MESSAGE, 'Please specify a measurement by HPCA or specify support data.', /INF

; If only support data is wanted
  ENDIF ELSE IF ~keyword_set(measurement_id) and keyword_set(support) THEN BEGIN

     id = CDF_open(filename)
     CDF_CONTROL, id, Var = 'Epoch', Get_VAR_INFO = CDFinfo
     
; Checking to make sure there is valid data in the requested time interval
     IF CDFinfo.MAXREC GT 0 THEN BEGIN
        CDF_VARGET, id, 'Epoch', times, REC_COUNT=CDFinfo.MAXREC-1
        CDF_VARGET, id, sc_id+'_hpca_science_mode', science_mode_tmp, REC_COUNT=CDFinfo.MAXREC-1
        CDF_VARGET, id, sc_id+'_hpca_bkgd_constant', bkgd_constant_tmp, REC_COUNT=CDFinfo.MAXREC-1
        CDF_VARGET, id, sc_id+'_hpca_bkgd_data_quality', bkgd_data_qual_tmp, REC_COUNT=CDFinfo.MAXREC-1
        CDF_VARGET, id, sc_id+'_hpca_hplus_data_quality', hplus_data_qual_tmp, REC_COUNT=CDFinfo.MAXREC-1
        CDF_VARGET, id, sc_id+'_hpca_heplus_data_quality', heplus_data_qual_tmp, REC_COUNT=CDFinfo.MAXREC-1
        CDF_VARGET, id, sc_id+'_hpca_heplusplus_data_quality', heplusplus_data_qual_tmp, REC_COUNT=CDFinfo.MAXREC-1
        CDF_VARGET, id, sc_id+'_hpca_oplus_data_quality', oplus_data_qual_tmp, REC_COUNT=CDFinfo.MAXREC-1
        CDF_VARGET, id, sc_id+'_hpca_oplusplus_data_quality', oplusplus_data_qual_tmp, REC_COUNT=CDFinfo.MAXREC-1 
        
        science_mode_tmp = REFORM(science_mode_tmp)
        bkgd_data_qual_tmp = REFORM(bkgd_data_qual_tmp)
        hplus_data_qual_tmp = REFORM(hplus_data_qual_tmp)
        heplus_data_qual_tmp = REFORM(heplus_data_qual_tmp)
        heplusplus_data_qual_tmp = REFORM(heplusplus_data_qual_tmp)
        oplus_data_qual_tmp = REFORM(oplus_data_qual_tmp)
        oplusplus_data_qual_tmp = REFORM(oplusplus_data_qual_tmp)
        
        IF hh eq 0 THEN BEGIN
           science_mode = science_mode_tmp
           bkgd_constant = bkgd_constant_tmp
           bkgd_data_qual = bkgd_data_qual_tmp
           heplus_data_qual = heplus_data_qual_tmp
           heplusplus_data_qual = heplusplus_data_qual_tmp
           oplus_data_qual = oplus_data_qual_tmp
           oplusplus_data_qual = oplusplus_data_qual_tmp
        ENDIF ELSE BEGIN
           science_mode = [science_mode, science_mode_tmp]
           bkgd_constant = [bkgd_constant, bkgd_constant_tmp]
           bkgd_data_qual = [bkgd_data_qual, bkgd_data_qual_tmp]
           heplus_data_qual = [heplus_data_qual, heplus_data_qual_tmp]
           heplusplus_data_qual = [heplusplus_data_qual, heplusplus_data_qual_tmp]
           oplus_data_qual = [oplus_data_qual, oplus_data_qual_tmp]
           oplusplus_data_qual = [oplusplus_data_qual, oplusplus_data_qual_tmp]
        ENDELSE
 
        ;stop
        cdf_close, id
     ENDIF 
  ENDIF ELSE BEGIN              ; For when measurement_id is set

; Checking if species keyword is set. If not, defaults to all species
; for each measurement requested
        IF ~keyword_set(species) THEN BEGIN
           species = replicate(6, n_elements(measurement_id))
        ENDIF ELSE BEGIN

; If the species keyword is set, making sure the measurement and
; species arrays are the same size
           IF n_elements(measurement_id) EQ n_elements(species) THEN BEGIN
;stop
              id = CDF_open(filename)
              CDF_CONTROL, id, Var = 'Epoch', Get_VAR_INFO = CDFinfo

; Checking to make sure there is valid data in the requested time interval
              IF CDFinfo.MAXREC GT 0 THEN BEGIN
               
                 CDF_VARGET, id, 'Epoch', times_tmp, REC_COUNT=CDFinfo.MAXREC-1
                 CDF_VARGET, id, sc_id+'_hpca_ion_energy', energies_tmp;, REC_COUNT=CDFinfo.MAXREC-1
                 CDF_VARGET, id, sc_id+'_hpca_center_theta', anode_elevation_tmp;, REC_COUNT=CDFinfo.MAXREC-1
                 CDF_VARGET, id, sc_id+'_hpca_polar_anode_number', anode_number_tmp
    
                 IF hh eq 0 THEN BEGIN
                    times = reform(times_tmp)
                    energies = energies_tmp
                    anode_elevation = anode_elevation_tmp
                    anode_number = anode_number_tmp
                 ENDIF ELSE BEGIN
                    times = [times, reform(times_tmp)]
                 ENDELSE
                

                                ; CASES for different measurements and for support data   
                 IF KEYWORD_SET(support) THEN BEGIN
                    CDF_VARGET, id, sc_id+'_hpca_science_mode', science_mode_tmp, REC_COUNT=CDFinfo.MAXREC-1
                    CDF_VARGET, id, sc_id+'_hpca_bkgd_constant', bkgd_constant_tmp, REC_COUNT=CDFinfo.MAXREC-1
                    CDF_VARGET, id, sc_id+'_hpca_bkgd_data_quality', bkgd_data_qual_tmp, REC_COUNT=CDFinfo.MAXREC-1
                    CDF_VARGET, id, sc_id+'_hpca_hplus_data_quality', hplus_data_qual_tmp, REC_COUNT=CDFinfo.MAXREC-1
                    CDF_VARGET, id, sc_id+'_hpca_heplus_data_quality', heplus_data_qual_tmp, REC_COUNT=CDFinfo.MAXREC-1
                    CDF_VARGET, id, sc_id+'_hpca_heplusplus_data_quality', heplusplus_data_qual_tmp, REC_COUNT=CDFinfo.MAXREC-1
                    CDF_VARGET, id, sc_id+'_hpca_oplus_data_quality', oplus_data_qual_tmp, REC_COUNT=CDFinfo.MAXREC-1
                    CDF_VARGET, id, sc_id+'_hpca_oplusplus_data_quality', oplusplus_data_qual_tmp, REC_COUNT=CDFinfo.MAXREC-1 

                    science_mode_tmp = REFORM(science_mode_tmp)
                    bkgd_data_qual_tmp = REFORM(bkgd_data_qual_tmp)
                    hplus_data_qual_tmp = REFORM(hplus_data_qual_tmp)
                    heplus_data_qual_tmp = REFORM(heplus_data_qual_tmp)
                    heplusplus_data_qual_tmp = REFORM(heplusplus_data_qual_tmp)
                    oplus_data_qual_tmp = REFORM(oplus_data_qual_tmp)
                    oplusplus_data_qual_tmp = REFORM(oplusplus_data_qual_tmp)

                    IF hh eq 0 THEN BEGIN
                       science_mode = science_mode_tmp
                       bkgd_constant = bkgd_constant_tmp
                       bkgd_data_qual = bkgd_data_qual_tmp
                       heplus_data_qual = heplus_data_qual_tmp
                       heplusplus_data_qual = heplusplus_data_qual_tmp
                       oplus_data_qual = oplus_data_qual_tmp
                       oplusplus_data_qual = oplusplus_data_qual_tmp
                    ENDIF ELSE BEGIN
                       science_mode = [science_mode, science_mode_tmp]
                       bkgd_constant = [bkgd_constant, bkgd_constant_tmp]
                       bkgd_data_qual = [bkgd_data_qual, bkgd_data_qual_tmp]
                       heplus_data_qual = [heplus_data_qual, heplus_data_qual_tmp]
                       heplusplus_data_qual = [heplusplus_data_qual, heplusplus_data_qual_tmp]
                       oplus_data_qual = [oplus_data_qual, oplus_data_qual_tmp]
                       oplusplus_data_qual = [oplusplus_data_qual, oplusplus_data_qual_tmp]
                    ENDELSE

                 ENDIF
              
             ; stop 
                 FOR ii = 0, n_elements(measurement_id)-1 DO BEGIN
                    measurement = measurement_id(ii)
                    ion = species(ii)-1 
                  
                    CASE measurement OF
                       
                       1: BEGIN ; Normalized counts
                          var_name = '_norm_counts'

                          IF Ion ne 6 THEN BEGIN
                             CDF_VARGET, id, sc_id+'_hpca_'+sp_name(ion), counts_tmp, REC_COUNT=CDFinfo.MAXREC-1

                             IF ion eq 0 then begin
                                hplus_counts_tmp = counts_tmp 
                                IF hh eq 0 THEN hplus_counts = hplus_counts_tmp ELSE $
                                   hplus_counts = [[[hplus_counts]], [[hplus_counts_tmp]]]
                             ENDIF ELSE IF ion eq 1 then BEGIN
                                heplus_counts_tmp = counts_tmp 
                                IF hh eq 0 THEN heplus_counts = heplus_counts_tmp ELSE $
                                   heplus_counts = [[[heplus_counts]], [[heplus_counts_tmp]]]
                             ENDIF ELSE IF ion eq 2 THEN BEGIN
                                heplusplus_counts_tmp = counts_tmp 
                                IF hh eq 0 THEN heplusplus_counts = heplusplus_counts_tmp ELSE $
                                   heplusplus_counts = [[[heplusplus_counts]], [[heplusplus_counts_tmp]]]
                             ENDIF ELSE IF ion eq 3 THEN BEGIN
                                oplus_counts_tmp = counts_tmp
                                IF hh eq 0 THEN oplus_counts = oplus_counts_tmp ELSE $
                                   oplus_counts = [[[oplus_counts]], [[oplus_counts_tmp]]]
                             ENDIF ELSE IF ion eq 4 THEN BEGIN
                                oplusplus_counts_tmp = counts_tmp
                                IF hh eq 0 THEN oplusplus_counts = oplusplus_counts_tmp ELSE $
                                   oplusplus_counts = [[[oplusplus_counts]], [[oplusplus_counts_tmp]]]
                             ENDIF ELSE IF ion eq 5 THEN BEGIN 
                                bkgd_counts_tmp = counts_tmp  
                                IF hh eq 0 THEN bkgd_counts = bkgd_counts_tmp ELSE $
                                   bkgd_counts = [[[bkgd_counts]], [[bkgd_counts_tmp]]]
                             ENDIF    
                    
                          ENDIF ELSE BEGIN
                             CDF_VARGET, id, sc_id+'_hpca_'+sp_name(0), hplus_counts_tmp, REC_COUNT=CDFinfo.MAXREC-1
                             CDF_VARGET, id, sc_id+'_hpca_'+sp_name(1), heplus_counts_tmp, REC_COUNT=CDFinfo.MAXREC-1
                             CDF_VARGET, id, sc_id+'_hpca_'+sp_name(2), heplusplus_counts_tmp, REC_COUNT=CDFinfo.MAXREC-1
                             CDF_VARGET, id, sc_id+'_hpca_'+sp_name(3), oplus_counts_tmp, REC_COUNT=CDFinfo.MAXREC-1
                             CDF_VARGET, id, sc_id+'_hpca_'+sp_name(4), oplusplus_counts_tmp, REC_COUNT=CDFinfo.MAXREC-1
                             CDF_VARGET, id, sc_id+'_hpca_'+sp_name(5), bkgd_counts_tmp, REC_COUNT=CDFinfo.MAXREC-1 
                            
                             IF hh eq 0 THEN BEGIN
                                hplus_counts = hplus_counts_tmp
                                heplus_counts = heplus_counts_tmp
                                heplusplus_counts = heplusplus_counts_tmp
                                oplus_counts = oplus_counts_tmp
                                oplusplus_counts = oplusplus_counts_tmp
                                bkgd_counts = bkgd_counts_tmp
                             ENDIF ELSE BEGIN
                                hplus_counts = [[[hplus_counts]], [[hplus_counts_tmp]]]
                                heplus_counts = [[[heplus_counts]], [[heplus_counts_tmp]]]
                                heplusplus_counts = [[[heplusplus_counts]], [[heplusplus_counts_tmp]]]
                                oplus_counts = [[[oplus_counts]], [[oplus_counts_tmp]]]
                                oplusplus_counts = [[[oplusplus_counts]], [[oplusplus_counts_tmp]]]
                                bkgd_counts = [[[bkgd_counts]], [[bkgd_counts_tmp]]]
                             ENDELSE 
                          ENDELSE
                       END
                    
                    2: BEGIN  ; Count Rate
                       var_name = '_count_rate'

                       IF Ion ne 6 THEN BEGIN
                          IF Ion lt 5 THEN BEGIN ; No count rate for background
                             CDF_VARGET, id, sc_id+'_hpca_'+sp_name(ion)+var_name, count_rate_tmp, REC_COUNT=CDFinfo.MAXREC-1
                        
                             IF ion eq 0 then begin
                                hplus_count_rate_tmp = count_rate_tmp 
                                IF hh eq 0 THEN hplus_count_rate = hplus_count_rate_tmp ELSE $
                                   hplus_count_rate = [[[hplus_count_rate]], [[hplus_count_rate_tmp]]]
                             ENDIF ELSE IF ion eq 1 then BEGIN
                                heplus_count_rate_tmp = count_rate_tmp 
                                IF hh eq 0 THEN heplus_count_rate = heplus_count_rate_tmp ELSE $
                                   heplus_count_rate = [[[heplus_count_rate]], [[heplus_count_rate_tmp]]]
                             ENDIF ELSE IF ion eq 2 THEN BEGIN
                                heplusplus_count_rate_tmp = count_rate_tmp 
                                IF hh eq 0 THEN heplusplus_count_rate = heplusplus_count_rate_tmp ELSE $
                                   heplusplus_count_rate = [[[heplusplus_count_rate]], [[heplusplus_count_rate_tmp]]]
                             ENDIF ELSE IF ion eq 3 THEN BEGIN
                                oplus_count_rate_tmp = count_rate_tmp
                                IF hh eq 0 THEN oplus_count_rate = oplus_count_rate_tmp ELSE $
                                   oplus_count_rate = [[[oplus_count_rate]], [[oplus_count_rate_tmp]]]
                             ENDIF ELSE IF ion eq 4 THEN BEGIN
                                oplusplus_count_rate_tmp = count_rate_tmp
                                IF hh eq 0 THEN oplusplus_count_rate = oplusplus_count_rate_tmp ELSE $
                                   oplusplus_count_rate = [[[oplusplus_count_rate]], [[oplusplus_count_rate_tmp]]]
                             ENDIF 
 
                          ENDIF
                       ENDIF ELSE BEGIN
                          CDF_VARGET, id, sc_id+'_hpca_'+sp_name(0)+var_name, hplus_count_rate_tmp, REC_COUNT=CDFinfo.MAXREC-1
                          CDF_VARGET, id, sc_id+'_hpca_'+sp_name(1)+var_name, heplus_count_rate_tmp, REC_COUNT=CDFinfo.MAXREC-1
                          CDF_VARGET, id, sc_id+'_hpca_'+sp_name(2)+var_name, heplusplus_count_rate_tmp, REC_COUNT=CDFinfo.MAXREC-1
                          CDF_VARGET, id, sc_id+'_hpca_'+sp_name(3)+var_name, oplus_count_rate_tmp, REC_COUNT=CDFinfo.MAXREC-1
                          CDF_VARGET, id, sc_id+'_hpca_'+sp_name(4)+var_name, oplusplus_count_rate_tmp, REC_COUNT=CDFinfo.MAXREC-1
                          
                          IF hh eq 0 THEN BEGIN
                                hplus_count_rate = hplus_count_rate_tmp
                                heplus_count_rate = heplus_count_rate_tmp
                                heplusplus_count_rate = heplusplus_count_rate_tmp
                                oplus_count_rate = oplus_count_rate_tmp
                                oplusplus_count_rate = oplusplus_count_rate_tmp
                             ENDIF ELSE BEGIN
                                hplus_count_rate = [[[hplus_count_rate]], [[hplus_count_rate_tmp]]]
                                heplus_count_rate = [[[heplus_count_rate]], [[heplus_count_rate_tmp]]]
                                heplusplus_count_rate = [[[heplusplus_count_rate]], [[heplusplus_count_rate_tmp]]]
                                oplus_count_rate = [[[oplus_count_rate]], [[oplus_count_rate_tmp]]]
                                oplusplus_count_rate = [[[oplusplus_count_rate]], [[oplusplus_count_rate_tmp]]]
                             ENDELSE 

                       ENDELSE
                    END
                    
                    3: BEGIN  ; Flux (not sure yet if differential, omni-directional, uni-directional, or particle)
                       var_name = '_flux'
                       
                       IF Ion ne 6 THEN BEGIN
                          IF Ion ne 5 THEN BEGIN ; No fluxes for background
                             CDF_VARGET, id, sc_id+'_hpca_'+sp_name(ion)+var_name, flux_tmp, REC_COUNT=CDFinfo.MAXREC-1

                             IF ion eq 0 then begin
                                hplus_flux_tmp = flux_tmp 
                                IF hh eq 0 THEN hplus_flux = hplus_flux_tmp ELSE $
                                   hplus_flux = [[[hplus_flux]], [[hplus_flux_tmp]]]
                             ENDIF ELSE IF ion eq 1 then BEGIN
                                heplus_flux_tmp = flux_tmp 
                                IF hh eq 0 THEN heplus_flux = heplus_flux_tmp ELSE $
                                   heplus_flux = [[[heplus_flux]], [[heplus_flux_tmp]]]
                             ENDIF ELSE IF ion eq 2 THEN BEGIN
                                heplusplus_flux_tmp = flux_tmp 
                                IF hh eq 0 THEN heplusplus_flux = heplusplus_flux_tmp ELSE $
                                   heplusplus_flux = [[[heplusplus_flux]], [[heplusplus_flux_tmp]]]
                             ENDIF ELSE IF ion eq 3 THEN BEGIN
                                oplus_flux_tmp = flux_tmp
                                IF hh eq 0 THEN oplus_flux = oplus_flux_tmp ELSE $
                                   oplus_flux = [[[oplus_flux]], [[oplus_flux_tmp]]]
                             ENDIF ELSE IF ion eq 4 THEN BEGIN
                                oplusplus_flux_tmp = flux_tmp
                                IF hh eq 0 THEN oplusplus_flux = oplusplus_flux_tmp ELSE $
                                   oplusplus_flux = [[[oplusplus_flux]], [[oplusplus_flux_tmp]]]
                             ENDIF  
                            
                          ENDIF
                       ENDIF ELSE BEGIN
                          CDF_VARGET, id, sc_id+'_hpca_'+sp_name(0)+var_name, hplus_flux_tmp, REC_COUNT=CDFinfo.MAXREC-1
                          CDF_VARGET, id, sc_id+'_hpca_'+sp_name(1)+var_name, heplus_flux_tmp, REC_COUNT=CDFinfo.MAXREC-1
                          CDF_VARGET, id, sc_id+'_hpca_'+sp_name(2)+var_name, heplusplus_flux_tmp, REC_COUNT=CDFinfo.MAXREC-1
                          CDF_VARGET, id, sc_id+'_hpca_'+sp_name(3)+var_name, oplus_flux_tmp, REC_COUNT=CDFinfo.MAXREC-1
                          CDF_VARGET, id, sc_id+'_hpca_'+sp_name(4)+var_name, oplusplus_flux_tmp, REC_COUNT=CDFinfo.MAXREC-1

                          IF hh eq 0 THEN BEGIN
                                hplus_flux = hplus_flux_tmp
                                heplus_flux = heplus_flux_tmp
                                heplusplus_flux = heplusplus_flux_tmp
                                oplus_flux = oplus_flux_tmp
                                oplusplus_flux = oplusplus_flux_tmp
                             ENDIF ELSE BEGIN
                                hplus_flux = [[[hplus_flux]], [[hplus_flux_tmp]]]
                                heplus_flux = [[[heplus_flux]], [[heplus_flux_tmp]]]
                                heplusplus_flux = [[[heplusplus_flux]], [[heplusplus_flux_tmp]]]
                                oplus_flux = [[[oplus_flux]], [[oplus_flux_tmp]]]
                                oplusplus_flux = [[[oplusplus_flux]], [[oplusplus_flux_tmp]]]
                             ENDELSE 

                       ENDELSE

                    END
                    
                    4: BEGIN   ; Velocity distribution functions
                       var_name = '_vel_dist_fn'
                       
                       IF Ion ne 6 THEN BEGIN
                          IF Ion ne 5 THEN BEGIN ; No velocity distributions for background
                             CDF_VARGET, id, sc_id+'_hpca_'+sp_name(ion)+var_name, vel_distr_tmp, REC_COUNT=CDFinfo.MAXREC-1
                             
                             IF ion eq 0 then begin
                                hplus_vel_distr_tmp = vel_distr_tmp 
                                IF hh eq 0 THEN hplus_vel_distr = hplus_vel_distr_tmp ELSE $
                                   hplus_vel_distr = [[[hplus_vel_distr]], [[hplus_vel_distr_tmp]]]
                             ENDIF ELSE IF ion eq 1 then BEGIN
                                heplus_vel_distr_tmp = vel_distr_tmp 
                                IF hh eq 0 THEN heplus_vel_distr = heplus_vel_distr_tmp ELSE $
                                   heplus_vel_distr = [[[heplus_vel_distr]], [[heplus_vel_distr_tmp]]]
                             ENDIF ELSE IF ion eq 2 THEN BEGIN
                                heplusplus_vel_distr_tmp = vel_distr_tmp 
                                IF hh eq 0 THEN heplusplus_vel_distr = heplusplus_vel_distr_tmp ELSE $
                                   heplusplus_vel_distr = [[[heplusplus_vel_distr]], [[heplusplus_vel_distr_tmp]]]
                             ENDIF ELSE IF ion eq 3 THEN BEGIN
                                oplus_vel_distr_tmp = vel_distr_tmp
                                IF hh eq 0 THEN oplus_vel_distr = oplus_vel_distr_tmp ELSE $
                                   oplus_vel_distr = [[[oplus_vel_distr]], [[oplus_vel_distr_tmp]]]
                             ENDIF ELSE IF ion eq 4 THEN BEGIN
                                oplusplus_vel_distr_tmp = vel_distr_tmp
                                IF hh eq 0 THEN oplusplus_vel_distr = oplusplus_vel_distr_tmp ELSE $
                                   oplusplus_vel_distr = [[[oplusplus_vel_distr]], [[oplusplus_vel_distr_tmp]]]
                             ENDIF                               

                          ENDIF
                       ENDIF ELSE BEGIN
                          CDF_VARGET, id, sc_id+'_hpca_'+sp_name(0)+var_name, hplus_vel_distr_tmp, REC_COUNT=CDFinfo.MAXREC-1
                          CDF_VARGET, id, sc_id+'_hpca_'+sp_name(1)+var_name, heplus_vel_distr_tmp, REC_COUNT=CDFinfo.MAXREC-1
                          CDF_VARGET, id, sc_id+'_hpca_'+sp_name(2)+var_name, heplusplus_vel_distr_tmp, REC_COUNT=CDFinfo.MAXREC-1
                          CDF_VARGET, id, sc_id+'_hpca_'+sp_name(3)+var_name, oplus_vel_distr_tmp, REC_COUNT=CDFinfo.MAXREC-1
                          CDF_VARGET, id, sc_id+'_hpca_'+sp_name(4)+var_name, oplusplus_vel_distr_tmp, REC_COUNT=CDFinfo.MAXREC-1

                          IF hh eq 0 THEN BEGIN
                                hplus_vel_distr = hplus_vel_distr_tmp
                                heplus_vel_distr = heplus_vel_distr_tmp
                                heplusplus_vel_distr = heplusplus_vel_distr_tmp
                                oplus_vel_distr = oplus_vel_distr_tmp
                                oplusplus_vel_distr = oplusplus_vel_distr_tmp
                             ENDIF ELSE BEGIN
                                hplus_vel_distr = [[[hplus_vel_distr]], [[hplus_vel_distr_tmp]]]
                                heplus_vel_distr = [[[heplus_vel_distr]], [[heplus_vel_distr_tmp]]]
                                heplusplus_vel_distr = [[[heplusplus_vel_distr]], [[heplusplus_vel_distr_tmp]]]
                                oplus_vel_distr = [[[oplus_vel_distr]], [[oplus_vel_distr_tmp]]]
                                oplusplus_vel_distr = [[[oplusplus_vel_distr]], [[oplusplus_vel_distr_tmp]]]
                             ENDELSE 

                       ENDELSE
                    END
                    
                    5: BEGIN   ; RF corrected counts
                       var_name = '_RF_corrected'
                       
                       IF Ion ne 6 THEN BEGIN
                          IF Ion ne 5 THEN BEGIN ; No RF corrections for background
                             CDF_VARGET, id, sc_id+'_hpca_'+sp_name(ion)+var_name, rf_corr_tmp, REC_COUNT=CDFinfo.MAXREC-1
                             
                             IF ion eq 0 then begin
                                hplus_rf_corr_tmp = rf_corr_tmp 
                                IF hh eq 0 THEN hplus_rf_corr = hplus_rf_corr_tmp ELSE $
                                   hplus_rf_corr = [[[hplus_rf_corr]], [[hplus_rf_corr_tmp]]]
                             ENDIF ELSE IF ion eq 1 then BEGIN
                                heplus_rf_corr_tmp = rf_corr_tmp 
                                IF hh eq 0 THEN heplus_rf_corr = heplus_rf_corr_tmp ELSE $
                                   heplus_rf_corr = [[[heplus_rf_corr]], [[heplus_rf_corr_tmp]]]
                             ENDIF ELSE IF ion eq 2 THEN BEGIN
                                heplusplus_rf_corr_tmp = rf_corr_tmp 
                                IF hh eq 0 THEN heplusplus_rf_corr = heplusplus_rf_corr_tmp ELSE $
                                   heplusplus_rf_corr = [[[heplusplus_rf_corr]], [[heplusplus_rf_corr_tmp]]]
                             ENDIF ELSE IF ion eq 3 THEN BEGIN
                                oplus_rf_corr_tmp = rf_corr_tmp
                                IF hh eq 0 THEN oplus_rf_corr = oplus_rf_corr_tmp ELSE $
                                   oplus_rf_corr = [[[oplus_rf_corr]], [[oplus_rf_corr_tmp]]]
                             ENDIF ELSE IF ion eq 4 THEN BEGIN
                                oplusplus_rf_corr_tmp = rf_corr_tmp
                                IF hh eq 0 THEN oplusplus_rf_corr = oplusplus_rf_corr_tmp ELSE $
                                   oplusplus_rf_corr = [[[oplusplus_rf_corr]], [[oplusplus_rf_corr_tmp]]]
                             ENDIF  

                          ENDIF
                       ENDIF ELSE BEGIN
                         CDF_VARGET, id, sc_id+'_hpca_'+sp_name(0)+var_name, hplus_rf_corr_tmp, REC_COUNT=CDFinfo.MAXREC-1
                          CDF_VARGET, id, sc_id+'_hpca_'+sp_name(1)+var_name, heplus_rf_corr_tmp, REC_COUNT=CDFinfo.MAXREC-1
                          CDF_VARGET, id, sc_id+'_hpca_'+sp_name(2)+var_name, heplusplus_rf_corr_tmp, REC_COUNT=CDFinfo.MAXREC-1
                          CDF_VARGET, id, sc_id+'_hpca_'+sp_name(3)+var_name, oplus_rf_corr_tmp, REC_COUNT=CDFinfo.MAXREC-1
                          CDF_VARGET, id, sc_id+'_hpca_'+sp_name(4)+var_name, oplusplus_rf_corr_tmp, REC_COUNT=CDFinfo.MAXREC-1

                          IF hh eq 0 THEN BEGIN
                                hplus_rf_corr = hplus_rf_corr_tmp
                                heplus_rf_corr = heplus_rf_corr_tmp
                                heplusplus_rf_corr = heplusplus_rf_corr_tmp
                                oplus_rf_corr = oplus_rf_corr_tmp
                                oplusplus_rf_corr = oplusplus_rf_corr_tmp
                             ENDIF ELSE BEGIN
                                hplus_rf_corr = [[[hplus_rf_corr]], [[hplus_rf_corr_tmp]]]
                                heplus_rf_corr = [[[heplus_rf_corr]], [[heplus_rf_corr_tmp]]]
                                heplusplus_rf_corr = [[[heplusplus_rf_corr]], [[heplusplus_rf_corr_tmp]]]
                                oplus_rf_corr = [[[oplus_rf_corr]], [[oplus_rf_corr_tmp]]]
                                oplusplus_rf_corr = [[[oplusplus_rf_corr]], [[oplusplus_rf_corr_tmp]]]
                             ENDELSE 

                       ENDELSE
                    END
                    
                    6: BEGIN   ; Background corrected counts
                       var_name = '_bkgd_corrected'
                       
                       IF Ion ne 6 THEN BEGIN
                          IF Ion lt 4 THEN BEGIN ; No BKGD corrections for O++ or background
                             CDF_VARGET, id, sc_id+'_hpca_'+sp_name(ion)+var_name, bkgd_corr_tmp, REC_COUNT=CDFinfo.MAXREC-1

                             IF ion eq 0 then begin
                                hplus_bkgd_corr_tmp = bkgd_corr_tmp 
                                IF hh eq 0 THEN hplus_bkgd_corr = hplus_bkgd_corr_tmp ELSE $
                                   hplus_bkgd_corr = [[[hplus_bkgd_corr]], [[hplus_bkgd_corr_tmp]]]
                             ENDIF ELSE IF ion eq 1 then BEGIN
                                heplus_bkgd_corr_tmp = bkgd_corr_tmp 
                                IF hh eq 0 THEN heplus_bkgd_corr = heplus_bkgd_corr_tmp ELSE $
                                   heplus_bkgd_corr = [[[heplus_bkgd_corr]], [[heplus_bkgd_corr_tmp]]]
                             ENDIF ELSE IF ion eq 2 THEN BEGIN
                                heplusplus_bkgd_corr_tmp = bkgd_corr_tmp 
                                IF hh eq 0 THEN heplusplus_bkgd_corr = heplusplus_bkgd_corr_tmp ELSE $
                                   heplusplus_bkgd_corr = [[[heplusplus_bkgd_corr]], [[heplusplus_bkgd_corr_tmp]]]
                             ENDIF ELSE IF ion eq 3 THEN BEGIN
                                oplus_bkgd_corr_tmp = bkgd_corr_tmp
                                IF hh eq 0 THEN oplus_bkgd_corr = oplus_bkgd_corr_tmp ELSE $
                                   oplus_bkgd_corr = [[[oplus_bkgd_corr]], [[oplus_bkgd_corr_tmp]]]
                             ENDIF                              

                          ENDIF
                       ENDIF ELSE BEGIN
                          CDF_VARGET, id, sc_id+'_hpca_'+sp_name(0)+var_name, hplus_bkgd_corr_tmp, REC_COUNT=CDFinfo.MAXREC-1
                          CDF_VARGET, id, sc_id+'_hpca_'+sp_name(1)+var_name, heplus_bkgd_corr_tmp, REC_COUNT=CDFinfo.MAXREC-1
                          CDF_VARGET, id, sc_id+'_hpca_'+sp_name(2)+var_name, heplusplus_bkgd_corr_tmp, REC_COUNT=CDFinfo.MAXREC-1
                          CDF_VARGET, id, sc_id+'_hpca_'+sp_name(3)+var_name, oplus_bkgd_corr_tmp, REC_COUNT=CDFinfo.MAXREC-1

                          IF hh eq 0 THEN BEGIN
                             hplus_bkgd_corr = hplus_bkgd_corr_tmp
                             heplus_bkgd_corr = heplus_bkgd_corr_tmp
                             heplusplus_bkgd_corr = heplusplus_bkgd_corr_tmp
                             oplus_bkgd_corr = oplus_bkgd_corr_tmp
                          ENDIF ELSE BEGIN
                             hplus_bkgd_corr = [[[hplus_bkgd_corr]], [[hplus_bkgd_corr_tmp]]]
                             heplus_bkgd_corr = [[[heplus_bkgd_corr]], [[heplus_bkgd_corr_tmp]]]
                             heplusplus_bkgd_corr = [[[heplusplus_bkgd_corr]], [[heplusplus_bkgd_corr_tmp]]]
                             oplus_bkgd_corr = [[[oplus_bkgd_corr]], [[oplus_bkgd_corr_tmp]]]
                          ENDELSE 

                       ENDELSE 
                    END
                    
                 ENDCASE
;stop
                 ENDFOR 
                 
                 cdf_close, id
                 
                 
              ENDIF ELSE BEGIN
                 MESSAGE, 'No valid data for this time interval!', /INF
              ENDELSE
           ENDIF ELSE BEGIN
              MESSAGE, 'The array sizes of species and measurements must be equal.', /INF
           ENDELSE
        ENDELSE 
     ENDELSE  
;stop
ENDFOR 
 times = time_double(times, /TT2000)
;stop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; BUILDING TPLOT VARIABLES

sp_name_tvar=['H+','He+','He++','O+','O++','BKGD']
sp_plot_str = ['H!U+!N','He!U+!N','He!U++!N','O!U+!N','O!U++!N','Background']
ztitle_mid=['Counts', 'Count Rate (0.625 s)!U-1!N','Flux (cm!U2!N s sr eV)!U-1!N', $
            'Velocity Distribution (s!U3!N cm!U-6!N)','RF Corrected Counts',$
            'Background Corrected Counts']  
;sat_str = strmid(sc_id, 3, 1)

FOR tt = 0, n_elements(measurement_id)-1 DO BEGIN
   measurement = measurement_id(tt)
   ion = species(tt)-1 
   time_stamp, /off
  
   ;; if ~keyword_set(fov) then begin
   ;;    anode_index = indgen(16)
   ;;    elevation_str = '_ELEV_0-180'
   ;; endif else begin
      elevation_str = '_ELEV_'+strtrim(fov(0),2)+'-'+strtrim(fov(1),2)
      fov_tmp = float(fov)
      anode_index = where(anode_elevation ge fov_tmp(0) and anode_elevation le fov_tmp(1), bin_cnt)
      if bin_cnt eq 0 then begin
         fov_tmp(0) = fov(0)-11.25
         fov_tmp(1) = fov(1)+11.25
         anode_index = where(anode_elevation ge fov_tmp(0) and anode_elevation le fov_tmp(1), bin_cnt2)
         if bin_cnt2 eq 0 then begin
            print, 'No data found within specified elevation range'
            stop
         endif 
      endif
   ;; endelse
 
   IF ion ne 6 then begin
      yt = strupcase(sc_id)+' !C'+sp_plot_str(ion)+' Energy (eV) !CELEV '+strtrim(fov(0),2)+'-'+strtrim(fov(1),2)
      zt = sp_plot_str(ion)+' '+ztitle_mid(measurement-1)
   ENDIF ELSE BEGIN
      yt = strarr(6)
      zt = strarr(6)
      for ll = 0, 5 do begin
         yt(ll) = strupcase(sc_id)+' !C'+sp_plot_str(ll)+' Energy (eV) !CELEV '+strtrim(fov(0),2)+'-'+strtrim(fov(1),2)
         zt(ll) = sp_plot_str(ll)+' '+ztitle_mid(measurement-1)
      endfor
   ENDELSE

   CASE measurement OF
      1: BEGIN  ; Normalized Counts -- Sum over anodes for counts
         IF ion ne 6 then begin
            tvar_name = strupcase(sc_id)+'_HPCA_'+sp_name_tvar(ion)+'_NORM_COUNTS'+elevation_str
         endif else begin
            ion_full = [indgen(6)]
            tvar_name = strarr(6)
            for ll = 0, 5 do tvar_name(ll) = strupcase(sc_id)+'_HPCA_'+sp_name_tvar(ion_full(ll))+'_NORM_COUNTS'+elevation_str
         endelse

         IF ion eq 0 THEN BEGIN
            hplus_counts_sub = hplus_counts[*,anode_index,*]
            hplus_counts_tot = dblarr(n_elements(energies),n_elements(times)) 
            if n_elements(anode_index) eq 1 then begin
               hplus_counts_tot = reform(hplus_counts_sub)
            endif else begin
               for ii=0,n_elements(energies)-1 do begin                                                          
                  for jj=0, n_elements(times)-1 do begin                                
                        hplus_counts_tot[ii,jj]=total(hplus_counts_sub[ii,*,jj], /nan)
                  endfor
               endfor
            endelse
            hplus_counts = transpose(hplus_counts_tot)
            hplus_counts(where(hplus_counts eq 0.)) = !VALUES.F_NAN
            store_data, tvar_name, data = {x:times, y:hplus_counts, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt,ztitle:zt}
            append_array, tplotnames, tvar_name
            ylim, tvar_name, 1., 40000.
            zlim, tvar_name, 0, 0, 1
         ENDIF ELSE IF ion eq 1 THEN BEGIN
            heplus_counts_sub = heplus_counts[*,anode_index,*]
            heplus_counts_tot = dblarr(n_elements(energies),n_elements(times)) 
            if n_elements(anode_index) eq 1 then begin
               heplus_counts_tot = reform(heplus_counts_sub)
            endif else begin
               for ii=0,n_elements(energies)-1 do begin                                                          
                  for jj=0, n_elements(times)-1 do begin                                
                        heplus_counts_tot[ii,jj]=total(heplus_counts_sub[ii,*,jj], /nan)
                  endfor
               endfor
            endelse
            heplus_counts = transpose(heplus_counts_tot)
            heplus_counts(where(heplus_counts eq 0.)) = !VALUES.F_NAN
            store_data, tvar_name, data = {x:times, y:heplus_counts, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt,ztitle:zt}
            append_array, tplotnames, tvar_name
            ylim, tvar_name, 1., 40000.
            zlim, tvar_name, 0, 0, 1
         ENDIF ELSE IF ion eq 2 THEN BEGIN
            heplusplus_counts_sub = heplusplus_counts[*,anode_index,*]
            heplusplus_counts_tot = dblarr(n_elements(energies),n_elements(times)) 
            if n_elements(anode_index) eq 1 then begin
               heplusplus_counts_tot = reform(heplusplus_counts_sub)
            endif else begin
               for ii=0,n_elements(energies)-1 do begin                                                          
                  for jj=0, n_elements(times)-1 do begin                                
                        heplusplus_counts_tot[ii,jj]=total(heplusplus_counts_sub[ii,*,jj], /nan)
                  endfor
               endfor
            endelse
            heplusplus_counts = transpose(heplusplus_counts_tot)
            heplusplus_counts(where(heplusplus_counts eq 0.)) = !VALUES.F_NAN
            store_data, tvar_name, data = {x:times, y:heplusplus_counts, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt,ztitle:zt}
            append_array, tplotnames, tvar_name
            ylim, tvar_name, 1., 40000.
            zlim, tvar_name, 0, 0, 1
         ENDIF ELSE IF ion eq 3 THEN BEGIN
            oplus_counts_sub = oplus_counts[*,anode_index,*]
            oplus_counts_tot = dblarr(n_elements(energies),n_elements(times)) 
            if n_elements(anode_index) eq 1 then begin
               oplus_counts_tot = reform(oplus_counts_sub)
            endif else begin
               for ii=0,n_elements(energies)-1 do begin                                                          
                  for jj=0, n_elements(times)-1 do begin                                
                        oplus_counts_tot[ii,jj]=total(oplus_counts_sub[ii,*,jj], /nan)
                  endfor
               endfor
            endelse

            oplus_counts = transpose(oplus_counts_tot)
            oplus_counts(where(oplus_counts eq 0.)) = !VALUES.F_NAN
            store_data, tvar_name, data = {x:times, y:oplus_counts, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt,ztitle:zt}
            append_array, tplotnames, tvar_name
            ylim, tvar_name, 1., 40000.
            zlim, tvar_name, 0, 0, 1
         ENDIF ELSE IF ion eq 4 THEN BEGIN
            oplusplus_counts_sub = oplusplus_counts[*,anode_index,*]
            oplusplus_counts_tot = dblarr(n_elements(energies),n_elements(times)) 
            if n_elements(anode_index) eq 1 then begin
               oplusplus_counts_tot = reform(oplusplus_counts_sub)
            endif else begin
               for ii=0,n_elements(energies)-1 do begin                                                          
                  for jj=0, n_elements(times)-1 do begin                                
                        oplusplus_counts_tot[ii,jj]=total(oplusplus_counts_sub[ii,*,jj], /nan)
                  endfor
               endfor
            endelse

            oplusplus_counts = transpose(oplusplus_counts_tot)
            oplusplus_counts(where(oplusplus_counts eq 0.)) = !VALUES.F_NAN
            store_data, tvar_name, data = {x:times, y:oplusplus_counts, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt,ztitle:zt}
            append_array, tplotnames, tvar_name
            ylim, tvar_name, 1., 40000.
            zlim, tvar_name, 0, 0, 1
         ENDIF ELSE IF ion eq 5 THEN BEGIN
            bkgd_counts_sub = bkgd_counts[*,anode_index,*]
            bkgd_counts_tot = dblarr(n_elements(energies),n_elements(times)) 
            if n_elements(anode_index) eq 1 then begin
               bkgd_counts_tot = reform(bkgd_counts_sub)
            endif else begin
               for ii=0,n_elements(energies)-1 do begin                                                          
                  for jj=0, n_elements(times)-1 do begin                                
                        bkgd_counts_tot[ii,jj]=total(bkgd_counts_sub[ii,*,jj], /nan)
                  endfor
               endfor
            endelse

            bkgd_counts = transpose(bkgd_counts_tot)
            bkgd_counts(where(bkgd_counts eq 0.)) = !VALUES.F_NAN
            store_data, tvar_name, data = {x:times, y:bkgd_counts, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt,ztitle:zt}
            append_array, tplotnames, tvar_name
            ylim, tvar_name, 1., 40000.
            zlim, tvar_name, 0, 0, 1
         ENDIF ELSE IF ion eq 6 THEN BEGIN
            hplus_counts_sub = hplus_counts[*,anode_index,*]
            hplus_counts_tot = dblarr(n_elements(energies),n_elements(times)) 
            heplus_counts_sub = heplus_counts[*,anode_index,*]
            heplus_counts_tot = dblarr(n_elements(energies),n_elements(times)) 
            heplusplus_counts_sub = heplusplus_counts[*,anode_index,*]
            heplusplus_counts_tot = dblarr(n_elements(energies),n_elements(times)) 
            oplus_counts_sub = oplus_counts[*,anode_index,*]
            oplus_counts_tot = dblarr(n_elements(energies),n_elements(times)) 
            oplusplus_counts_sub = oplusplus_counts[*,anode_index,*]
            oplusplus_counts_tot = dblarr(n_elements(energies),n_elements(times)) 
            bkgd_counts_sub = bkgd_counts[*,anode_index,*]
            bkgd_counts_tot = dblarr(n_elements(energies),n_elements(times)) 
            
            if n_elements(anode_index) eq 1 then begin
               hplus_counts_tot = reform(hplus_counts_sub)
               heplus_counts_tot = reform(heplus_counts_sub)
               heplusplus_counts_tot = reform(heplusplus_counts_sub)
               oplus_counts_tot = reform(oplus_counts_sub)
               oplusplus_counts_tot = reform(oplusplus_counts_sub)
               bkgd_counts_tot = reform(bkgd_counts_sub)
            endif else begin
               for ii=0,n_elements(energies)-1 do begin                                                          
                  for jj=0, n_elements(times)-1 do begin                          
                     hplus_counts_tot[ii,jj]=total(hplus_counts_sub[ii,*,jj], /nan)      
                     heplus_counts_tot[ii,jj]=total(heplus_counts_sub[ii,*,jj], /nan)
                     heplusplus_counts_tot[ii,jj]=total(heplusplus_counts_sub[ii,*,jj], /nan)
                     oplus_counts_tot[ii,jj]=total(oplus_counts_sub[ii,*,jj], /nan)
                     oplusplus_counts_tot[ii,jj]=total(oplusplus_counts_sub[ii,*,jj], /nan)
                     bkgd_counts_tot[ii,jj]=total(bkgd_counts_sub[ii,*,jj], /nan)
                  endfor
               endfor
            endelse

            hplus_counts = transpose(hplus_counts_tot)
            hplus_counts(where(hplus_counts eq 0.)) = !VALUES.F_NAN
            heplus_counts = transpose(heplus_counts_tot)
            heplus_counts(where(heplus_counts eq 0.)) = !VALUES.F_NAN
            heplusplus_counts = transpose(heplusplus_counts_tot)
            heplusplus_counts(where(heplusplus_counts eq 0.)) = !VALUES.F_NAN
            oplus_counts = transpose(oplus_counts_tot)
            oplus_counts(where(oplus_counts eq 0.)) = !VALUES.F_NAN
            oplusplus_counts = transpose(oplusplus_counts_tot)
            oplusplus_counts(where(oplusplus_counts eq 0.)) = !VALUES.F_NAN
            bkgd_counts = transpose(bkgd_counts_tot)
            bkgd_counts(where(bkgd_counts eq 0.)) = !VALUES.F_NAN

            store_data, tvar_name(0), data = {x:times, y:hplus_counts, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt(0),ztitle:zt(0)}
            store_data, tvar_name(1), data = {x:times, y:heplus_counts, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt(1),ztitle:zt(1)}
            store_data, tvar_name(2), data = {x:times, y:heplusplus_counts, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt(2),ztitle:zt(2)}
            store_data, tvar_name(3), data = {x:times, y:oplus_counts, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt(3),ztitle:zt(3)}
            store_data, tvar_name(4), data = {x:times, y:oplusplus_counts, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt(4),ztitle:zt(4)}
            store_data, tvar_name(5), data = {x:times, y:bkgd_counts, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt(5),ztitle:zt(5)}
            append_array, tplotnames, tvar_name
            for ll = 0, 5 do begin
            ylim, tvar_name(ll), 1., 40000.
            zlim, tvar_name(ll), 0, 0, 1
            endfor
         ENDIF 
      END

      2: BEGIN  ; Count Rate, Summing over anodes
         IF ion lt 5 then begin 
            tvar_name = strupcase(sc_id)+'_HPCA_'+sp_name_tvar(ion)+'_COUNT_RATE'+elevation_str
         endif else if ion eq 6 THEN begin
            ion_full = [indgen(5)]
            tvar_name = strarr(5)
            for ll = 0, 4 do tvar_name(ll) = strupcase(sc_id)+'_HPCA_'+sp_name_tvar(ion_full(ll))+'_COUNT_RATE'+elevation_str
         endif else begin
            print, 'Data for BKGD not available'
         endelse

         IF ion eq 0 THEN BEGIN
            hplus_count_rate_sub = hplus_count_rate[*,anode_index,*]
            hplus_count_rate_tot = dblarr(n_elements(energies),n_elements(times)) 
            if n_elements(anode_index) eq 1 then begin
               hplus_count_rate_tot = reform(hplus_count_rate_sub)
            endif else begin
               for ii=0,n_elements(energies)-1 do begin                                                          
                  for jj=0, n_elements(times)-1 do begin                                
                        hplus_count_rate_tot[ii,jj]=total(hplus_count_rate_sub[ii,*,jj], /nan)
                  endfor
               endfor
            endelse
            hplus_count_rate = transpose(hplus_count_rate_tot)
            hplus_count_rate(where(hplus_count_rate eq 0.)) = !VALUES.F_NAN
            store_data, tvar_name, data = {x:times, y:hplus_count_rate, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt,ztitle:zt}
            append_array, tplotnames, tvar_name
            ;; options, tvar_name, 'spec', 1
            ;; options, tvar_name, 'ylog', 1
            ;; options, tvar_name, 'zlog', 1
            ;; options, tvar_name, 'nointerp', 1
            ;; options, tvar_name, 'ytitle', yt
            ;; options, tvar_name, 'ztitle', zt
            ylim, tvar_name, 1., 40000.
            zlim, tvar_name, 0, 0, 1
         ENDIF ELSE IF ion eq 1 THEN BEGIN
            heplus_count_rate_sub = heplus_count_rate[*,anode_index,*]
            heplus_count_rate_tot = dblarr(n_elements(energies),n_elements(times)) 
            if n_elements(anode_index) eq 1 then begin
               heplus_count_rate_tot = reform(heplus_count_rate_sub)
            endif else begin
               for ii=0,n_elements(energies)-1 do begin                                                          
                  for jj=0, n_elements(times)-1 do begin                                
                        heplus_count_rate_tot[ii,jj]=total(heplus_count_rate_sub[ii,*,jj], /nan)
                  endfor
               endfor
            endelse
            heplus_count_rate = transpose(heplus_count_rate_tot)
            heplus_count_rate(where(heplus_count_rate eq 0.)) = !VALUES.F_NAN
            store_data, tvar_name, data = {x:times, y:heplus_count_rate, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt,ztitle:zt}
            append_array, tplotnames, tvar_name
            ylim, tvar_name, 1., 40000.
            zlim, tvar_name, 0, 0, 1
         ENDIF ELSE IF ion eq 2 THEN BEGIN
            heplusplus_count_rate_sub = heplusplus_count_rate[*,anode_index,*]
            heplusplus_count_rate_tot = dblarr(n_elements(energies),n_elements(times)) 
            if n_elements(anode_index) eq 1 then begin
               heplusplus_count_rate_tot = reform(heplusplus_count_rate_sub)
            endif else begin
               for ii=0,n_elements(energies)-1 do begin                                                          
                  for jj=0, n_elements(times)-1 do begin                                
                        heplusplus_count_rate_tot[ii,jj]=total(heplusplus_count_rate_sub[ii,*,jj], /nan)
                  endfor
               endfor
            endelse
            heplusplus_count_rate = transpose(heplusplus_count_rate_tot)
            heplusplus_count_rate(where(heplusplus_count_rate eq 0.)) = !VALUES.F_NAN
            store_data, tvar_name, data = {x:times, y:heplusplus_count_rate, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt,ztitle:zt}
            append_array, tplotnames, tvar_name
            ylim, tvar_name, 1., 40000.
            zlim, tvar_name, 0, 0, 1
         ENDIF ELSE IF ion eq 3 THEN BEGIN
            oplus_count_rate_sub = oplus_count_rate[*,anode_index,*]
            oplus_count_rate_tot = dblarr(n_elements(energies),n_elements(times)) 
            if n_elements(anode_index) eq 1 then begin
               oplus_count_rate_tot = reform(oplus_count_rate_sub)
            endif else begin
               for ii=0,n_elements(energies)-1 do begin                                                          
                  for jj=0, n_elements(times)-1 do begin                                
                        oplus_count_rate_tot[ii,jj]=total(oplus_count_rate_sub[ii,*,jj], /nan)
                  endfor
               endfor
            endelse
            oplus_count_rate = transpose(oplus_count_rate_tot)
            oplus_count_rate(where(oplus_count_rate eq 0.)) = !VALUES.F_NAN
            store_data, tvar_name, data = {x:times, y:oplus_count_rate, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt,ztitle:zt}
            append_array, tplotnames, tvar_name
            ylim, tvar_name, 1., 40000.
            zlim, tvar_name, 0, 0, 1
         ENDIF ELSE IF ion eq 4 THEN BEGIN
            oplusplus_count_rate_sub = oplusplus_count_rate[*,anode_index,*]
            oplusplus_count_rate_tot = dblarr(n_elements(energies),n_elements(times)) 
            if n_elements(anode_index) eq 1 then begin
               oplusplus_count_rate_tot = reform(oplusplus_count_rate_sub)
            endif else begin
               for ii=0,n_elements(energies)-1 do begin                                                          
                  for jj=0, n_elements(times)-1 do begin                                
                        oplusplus_count_rate_tot[ii,jj]=total(oplusplus_count_rate_sub[ii,*,jj], /nan)
                  endfor
               endfor
            endelse
            oplusplus_count_rate = transpose(oplusplus_count_rate_tot)
            oplusplus_count_rate = reform(oplusplus_count_rate[*,0,*])
            oplusplus_count_rate = transpose(oplusplus_count_rate)
            oplusplus_count_rate(where(oplusplus_count_rate eq 0.)) = !VALUES.F_NAN
            store_data, tvar_name, data = {x:times, y:oplusplus_count_rate, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt,ztitle:zt}
            append_array, tplotnames, tvar_name
            ylim, tvar_name, 1., 40000.
            zlim, tvar_name, 0, 0, 1
         ENDIF ELSE IF ion eq 6 THEN BEGIN
            hplus_count_rate_sub = hplus_count_rate[*,anode_index,*]
            hplus_count_rate_tot = dblarr(n_elements(energies),n_elements(times)) 
            heplus_count_rate_sub = heplus_count_rate[*,anode_index,*]
            heplus_count_rate_tot = dblarr(n_elements(energies),n_elements(times)) 
            heplusplus_count_rate_sub = heplusplus_count_rate[*,anode_index,*]
            heplusplus_count_rate_tot = dblarr(n_elements(energies),n_elements(times)) 
            oplus_count_rate_sub = oplus_count_rate[*,anode_index,*]
            oplus_count_rate_tot = dblarr(n_elements(energies),n_elements(times)) 
            oplusplus_count_rate_sub = oplusplus_count_rate[*,anode_index,*]
            oplusplus_count_rate_tot = dblarr(n_elements(energies),n_elements(times))           
            
            if n_elements(anode_index) eq 1 then begin
               hplus_count_rate_tot = reform(hplus_count_rate_sub)
               heplus_count_rate_tot = reform(heplus_count_rate_sub)
               heplusplus_count_rate_tot = reform(heplusplus_count_rate_sub)
               oplus_count_rate_tot = reform(oplus_count_rate_sub)
               oplusplus_count_rate_tot = reform(oplusplus_count_rate_sub)
            endif else begin
               for ii=0,n_elements(energies)-1 do begin                                                          
                  for jj=0, n_elements(times)-1 do begin                          
                     hplus_count_rate_tot[ii,jj]=total(hplus_count_rate_sub[ii,*,jj], /nan)      
                     heplus_count_rate_tot[ii,jj]=total(heplus_count_rate_sub[ii,*,jj], /nan)
                     heplusplus_count_rate_tot[ii,jj]=total(heplusplus_count_rate_sub[ii,*,jj], /nan)
                     oplus_count_rate_tot[ii,jj]=total(oplus_count_rate_sub[ii,*,jj], /nan)
                     oplusplus_count_rate_tot[ii,jj]=total(oplusplus_count_rate_sub[ii,*,jj], /nan)
                  endfor
               endfor
            endelse

            hplus_count_rate = transpose(hplus_count_rate_tot)
            hplus_count_rate(where(hplus_count_rate eq 0.)) = !VALUES.F_NAN
            heplus_count_rate = transpose(heplus_count_rate_tot)
            heplus_count_rate(where(heplus_count_rate eq 0.)) = !VALUES.F_NAN
            heplusplus_count_rate = transpose(heplusplus_count_rate_tot)
            heplusplus_count_rate(where(heplusplus_count_rate eq 0.)) = !VALUES.F_NAN
            oplus_count_rate = transpose(oplus_count_rate_tot)
            oplus_count_rate(where(oplus_count_rate eq 0.)) = !VALUES.F_NAN
            oplusplus_count_rate = transpose(oplusplus_count_rate_tot)
            oplusplus_count_rate(where(oplusplus_count_rate eq 0.)) = !VALUES.F_NAN

            store_data, tvar_name(0), data = {x:times, y:hplus_count_rate, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt(0),ztitle:zt(0)}
            store_data, tvar_name(1), data = {x:times, y:heplus_count_rate, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt(1),ztitle:zt(1)}
            store_data, tvar_name(2), data = {x:times, y:heplusplus_count_rate, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt(2),ztitle:zt(2)}
            store_data, tvar_name(3), data = {x:times, y:oplus_count_rate, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt(3),ztitle:zt(3)}
            store_data, tvar_name(4), data = {x:times, y:oplusplus_count_rate, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt(4),ztitle:zt(4)}

            append_array, tplotnames, tvar_name
            for ll = 0, 4 do begin
            ylim, tvar_name(ll), 1., 40000.
            zlim, tvar_name(ll), 0, 0, 1
            endfor
         ENDIF 
      END

      3: BEGIN     ; Flux, fill value for plotting on log scale is 0.01, averaging over anodes
         IF ion lt 5 then begin 
            tvar_name = strupcase(sc_id)+'_HPCA_'+sp_name_tvar(ion)+'_FLUX'+elevation_str
         endif else if ion eq 6 then begin
            ion_full = [indgen(5)]
            tvar_name = strarr(5)
            for ll = 0, 4 do tvar_name(ll) = strupcase(sc_id)+'_HPCA_'+sp_name_tvar(ion_full(ll))+'_FLUX'+elevation_str
         endif else begin
            print, 'Data for BKGD not available'
         endelse

         IF ion eq 0 THEN BEGIN
            hplus_flux_sub = hplus_flux[*,anode_index,*]
            hplus_flux_tot = dblarr(n_elements(energies),n_elements(times)) 
            if n_elements(anode_index) eq 1 then begin
               hplus_flux_tot = reform(hplus_flux_sub)
            endif else begin
               for ii=0,n_elements(energies)-1 do begin                                                          
                  for jj=0, n_elements(times)-1 do begin                                
                        hplus_flux_tot[ii,jj]=mean(hplus_flux_sub[ii,*,jj], /nan)
                  endfor
               endfor
            endelse
            hplus_flux = transpose(hplus_flux_tot)
            hplus_flux(where(hplus_flux eq 0.)) = !VALUES.F_NAN
            store_data, tvar_name, data = {x:times, y:hplus_flux, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt,ztitle:zt}
            append_array, tplotnames, tvar_name
            ylim, tvar_name, 1., 40000.
            zlim, tvar_name, 0, 0, 1
         ENDIF ELSE IF ion eq 1 THEN BEGIN
            heplus_flux_sub = heplus_flux[*,anode_index,*]
            heplus_flux_tot = dblarr(n_elements(energies),n_elements(times)) 
            if n_elements(anode_index) eq 1 then begin
               heplus_flux_tot = reform(heplus_flux_sub)
            endif else begin
               for ii=0,n_elements(energies)-1 do begin                                                          
                  for jj=0, n_elements(times)-1 do begin                                
                        heplus_flux_tot[ii,jj]=mean(heplus_flux_sub[ii,*,jj], /nan)
                  endfor
               endfor
            endelse
            heplus_flux = transpose(heplus_flux_tot)
            heplus_flux = reform(heplus_flux[*,0,*])
            heplus_flux = transpose(heplus_flux)
            heplus_flux(where(heplus_flux eq 0.)) = !VALUES.F_NAN
            store_data, tvar_name, data = {x:times, y:heplus_flux, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt,ztitle:zt}
            append_array, tplotnames, tvar_name
            ylim, tvar_name, 1., 40000.
            zlim, tvar_name, 0, 0, 1
         ENDIF ELSE IF ion eq 2 THEN BEGIN
            heplusplus_flux_sub = heplusplus_flux[*,anode_index,*]
            heplusplus_flux_tot = dblarr(n_elements(energies),n_elements(times)) 
            if n_elements(anode_index) eq 1 then begin
               heplusplus_flux_tot = reform(heplusplus_flux_sub)
            endif else begin
               for ii=0,n_elements(energies)-1 do begin                                                          
                  for jj=0, n_elements(times)-1 do begin                                
                        heplusplus_flux_tot[ii,jj]=mean(heplusplus_flux_sub[ii,*,jj], /nan)
                  endfor
               endfor
            endelse
            heplusplus_flux = transpose(heplusplus_flux_tot)
            heplusplus_flux(where(heplusplus_flux eq 0.)) = !VALUES.F_NAN
            store_data, tvar_name, data = {x:times, y:heplusplus_flux, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt,ztitle:zt}
            append_array, tplotnames, tvar_name
            ylim, tvar_name, 1., 40000.
            zlim, tvar_name, 0, 0, 1
         ENDIF ELSE IF ion eq 3 THEN BEGIN
            oplus_flux_sub = oplus_flux[*,anode_index,*]
            oplus_flux_tot = dblarr(n_elements(energies),n_elements(times)) 
            if n_elements(anode_index) eq 1 then begin
               oplus_flux_tot = reform(oplus_flux_sub)
            endif else begin
               for ii=0,n_elements(energies)-1 do begin                                                          
                  for jj=0, n_elements(times)-1 do begin                                
                        oplus_flux_tot[ii,jj]=mean(oplus_flux_sub[ii,*,jj], /nan)
                  endfor
               endfor
            endelse
            oplus_flux = transpose(oplus_flux_tot)
            oplus_flux(where(oplus_flux eq 0.)) = !VALUES.F_NAN
            store_data, tvar_name, data = {x:times, y:oplus_flux, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt,ztitle:zt}
            append_array, tplotnames, tvar_name
            ylim, tvar_name, 1., 40000.
            zlim, tvar_name, 0, 0, 1
         ENDIF ELSE IF ion eq 4 THEN BEGIN
            oplusplus_flux_sub = oplusplus_flux[*,anode_index,*]
            oplusplus_flux_tot = dblarr(n_elements(energies),n_elements(times)) 
            if n_elements(anode_index) eq 1 then begin
               oplusplus_flux_tot = reform(oplusplus_flux_sub)
            endif else begin
               for ii=0,n_elements(energies)-1 do begin                                                          
                  for jj=0, n_elements(times)-1 do begin                                
                        oplusplus_flux_tot[ii,jj]=mean(oplusplus_flux_sub[ii,*,jj], /nan)
                  endfor
               endfor
            endelse
            oplusplus_flux = transpose(oplusplus_flux_tot)
            oplusplus_flux(where(oplusplus_flux eq 0.)) = !VALUES.F_NAN
            store_data, tvar_name, data = {x:times, y:oplusplus_flux, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt,ztitle:zt}
            append_array, tplotnames, tvar_name
            ylim, tvar_name, 1., 40000.
            zlim, tvar_name, 0, 0, 1
         ENDIF ELSE IF ion eq 6 THEN BEGIN
            hplus_flux_sub = hplus_flux[*,anode_index,*]
            hplus_flux_tot = dblarr(n_elements(energies),n_elements(times)) 
            heplus_flux_sub = heplus_flux[*,anode_index,*]
            heplus_flux_tot = dblarr(n_elements(energies),n_elements(times)) 
            heplusplus_flux_sub = heplusplus_flux[*,anode_index,*]
            heplusplus_flux_tot = dblarr(n_elements(energies),n_elements(times)) 
            oplus_flux_sub = oplus_flux[*,anode_index,*]
            oplus_flux_tot = dblarr(n_elements(energies),n_elements(times)) 
            oplusplus_flux_sub = oplusplus_flux[*,anode_index,*]
            oplusplus_flux_tot = dblarr(n_elements(energies),n_elements(times)) 
            
            if n_elements(anode_index) eq 1 then begin
               hplus_flux_tot = reform(hplus_flux_sub)
               heplus_flux_tot = reform(heplus_flux_sub)
               heplusplus_flux_tot = reform(heplusplus_flux_sub)
               oplus_flux_tot = reform(oplus_flux_sub)
               oplusplus_flux_tot = reform(oplusplus_flux_sub)
            endif else begin
               for ii=0,n_elements(energies)-1 do begin                                                          
                  for jj=0, n_elements(times)-1 do begin                          
                     hplus_flux_tot[ii,jj]=mean(hplus_flux_sub[ii,*,jj], /nan)      
                     heplus_flux_tot[ii,jj]=mean(heplus_flux_sub[ii,*,jj], /nan)
                     heplusplus_flux_tot[ii,jj]=mean(heplusplus_flux_sub[ii,*,jj], /nan)
                     oplus_flux_tot[ii,jj]=mean(oplus_flux_sub[ii,*,jj], /nan)
                     oplusplus_flux_tot[ii,jj]=mean(oplusplus_flux_sub[ii,*,jj], /nan)
                  endfor
               endfor
            endelse

            hplus_flux = transpose(hplus_flux_tot)
            hplus_flux(where(hplus_flux eq 0.)) = !VALUES.F_NAN
            heplus_flux = transpose(heplus_flux_tot)
            heplus_flux(where(heplus_flux eq 0.)) = !VALUES.F_NAN
            heplusplus_flux = transpose(heplusplus_flux_tot)
            heplusplus_flux(where(heplusplus_flux eq 0.)) = !VALUES.F_NAN
            oplus_flux = transpose(oplus_flux_tot)
            oplus_flux(where(oplus_flux eq 0.)) = !VALUES.F_NAN
            oplusplus_flux = transpose(oplusplus_flux_tot)
            oplusplus_flux(where(oplusplus_flux eq 0.)) = !VALUES.F_NAN

            store_data, tvar_name(0), data = {x:times, y:hplus_flux, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt(0),ztitle:zt(0)}
            store_data, tvar_name(1), data = {x:times, y:heplus_flux, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt(1),ztitle:zt(1)}
            store_data, tvar_name(2), data = {x:times, y:heplusplus_flux, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt(2),ztitle:zt(2)}
            store_data, tvar_name(3), data = {x:times, y:oplus_flux, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt(3),ztitle:zt(3)}
            store_data, tvar_name(4), data = {x:times, y:oplusplus_flux, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt(4),ztitle:zt(4)}

            append_array, tplotnames, tvar_name
            for ll = 0, 4 do begin
            ylim, tvar_name(ll), 1., 40000.
            zlim, tvar_name(ll), 0, 0, 1
            endfor
         ENDIF 
      END

      4: BEGIN    ; Velocity distribution functions, fill value is 10^-32, Averaging over anodes
         IF ion lt 5 then begin 
            tvar_name = strupcase(sc_id)+'_HPCA_'+sp_name_tvar(ion)+'_VEL_DISTR'+elevation_str
         endif else if ion eq 6 then begin
            ion_full = [indgen(5)]
            tvar_name = strarr(5)
            for ll = 0, 4 do tvar_name(ll) = strupcase(sc_id)+'_HPCA_'+sp_name_tvar(ion_full(ll))+'_VEL_DISTR'+elevation_str
         endif else begin
            print, 'Data for BKGD not available'
         endelse

         IF ion eq 0 THEN BEGIN
            hplus_vel_distr_sub = hplus_vel_distr[*,anode_index,*]
            hplus_vel_distr_tot = dblarr(n_elements(energies),n_elements(times)) 
            if n_elements(anode_index) eq 1 then begin
               hplus_vel_distr_tot = reform(hplus_vel_distr_sub)
            endif else begin
               for ii=0,n_elements(energies)-1 do begin                                                          
                  for jj=0, n_elements(times)-1 do begin                                
                        hplus_vel_distr_tot[ii,jj]=mean(hplus_vel_distr_sub[ii,*,jj], /nan)
                  endfor
               endfor
            endelse
            hplus_vel_distr = transpose(hplus_vel_distr_tot)
            hplus_vel_distr(where(hplus_vel_distr eq 0.)) = !VALUES.F_NAN
            store_data, tvar_name, data = {x:times, y:hplus_vel_distr, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt,ztitle:zt}
            append_array, tplotnames, tvar_name
            ylim, tvar_name, 1., 40000.
            zlim, tvar_name, 0, 0, 1
         ENDIF ELSE IF ion eq 1 THEN BEGIN
            heplus_vel_distr_sub = heplus_vel_distr[*,anode_index,*]
            heplus_vel_distr_tot = dblarr(n_elements(energies),n_elements(times)) 
            if n_elements(anode_index) eq 1 then begin
               heplus_vel_distr_tot = reform(heplus_vel_distr_sub)
            endif else begin
               for ii=0,n_elements(energies)-1 do begin                                                          
                  for jj=0, n_elements(times)-1 do begin                                
                        heplus_vel_distr_tot[ii,jj]=mean(heplus_vel_distr_sub[ii,*,jj], /nan)
                  endfor
               endfor
            endelse
            heplus_vel_distr = transpose(heplus_vel_distr_tot)
            heplus_vel_distr(where(heplus_vel_distr eq 0.)) = !VALUES.F_NAN
            store_data, tvar_name, data = {x:times, y:heplus_vel_distr, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt,ztitle:zt}
            append_array, tplotnames, tvar_name
            ylim, tvar_name, 1., 40000.
            zlim, tvar_name, 0, 0, 1
         ENDIF ELSE IF ion eq 2 THEN BEGIN
            heplusplus_vel_distr_sub = heplusplus_vel_distr[*,anode_index,*]
            heplusplus_vel_distr_tot = dblarr(n_elements(energies),n_elements(times)) 
            if n_elements(anode_index) eq 1 then begin
               heplusplus_vel_distr_tot = reform(heplusplus_vel_distr_sub)
            endif else begin
               for ii=0,n_elements(energies)-1 do begin                                                          
                  for jj=0, n_elements(times)-1 do begin                                
                        heplusplus_vel_distr_tot[ii,jj]=mean(heplusplus_vel_distr_sub[ii,*,jj], /nan)
                  endfor
               endfor
            endelse
            heplusplus_vel_distr = transpose(heplusplus_vel_distr_tot)
            heplusplus_vel_distr(where(heplusplus_vel_distr eq 0.)) = !VALUES.F_NAN
            store_data, tvar_name, data = {x:times, y:heplusplus_vel_distr, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt,ztitle:zt}
            append_array, tplotnames, tvar_name
            ylim, tvar_name, 1., 40000.
            zlim, tvar_name, 0, 0, 1
         ENDIF ELSE IF ion eq 3 THEN BEGIN
            oplus_vel_distr_sub = oplus_vel_distr[*,anode_index,*]
            oplus_vel_distr_tot = dblarr(n_elements(energies),n_elements(times)) 
            if n_elements(anode_index) eq 1 then begin
               oplus_vel_distr_tot = reform(oplus_vel_distr_sub)
            endif else begin
               for ii=0,n_elements(energies)-1 do begin                                                          
                  for jj=0, n_elements(times)-1 do begin                                
                        oplus_vel_distr_tot[ii,jj]=mean(oplus_vel_distr_sub[ii,*,jj], /nan)
                  endfor
               endfor
            endelse
            oplus_vel_distr = transpose(oplus_vel_distr_tot)
            oplus_vel_distr(where(oplus_vel_distr eq 0.)) = !VALUES.F_NAN
            store_data, tvar_name, data = {x:times, y:oplus_vel_distr, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt,ztitle:zt}
            append_array, tplotnames, tvar_name
            ylim, tvar_name, 1., 40000.
            zlim, tvar_name, 0, 0, 1
         ENDIF ELSE IF ion eq 4 THEN BEGIN
            oplusplus_vel_distr_sub = oplusplus_vel_distr[*,anode_index,*]
            oplusplus_vel_distr_tot = dblarr(n_elements(energies),n_elements(times)) 
            if n_elements(anode_index) eq 1 then begin
               oplusplus_vel_distr_tot = reform(oplusplus_vel_distr_sub)
            endif else begin
               for ii=0,n_elements(energies)-1 do begin                                                          
                  for jj=0, n_elements(times)-1 do begin                                
                        oplusplus_vel_distr_tot[ii,jj]=mean(oplusplus_vel_distr_sub[ii,*,jj], /nan)
                  endfor
               endfor
            endelse
            oplusplus_vel_distr = transpose(oplusplus_vel_distr_tot)
            oplusplus_vel_distr(where(oplusplus_vel_distr eq 0.)) = !VALUES.F_NAN
            store_data, tvar_name, data = {x:times, y:oplusplus_vel_distr, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt,ztitle:zt}
            append_array, tplotnames, tvar_name
            ylim, tvar_name, 1., 40000.
            zlim, tvar_name, 0, 0, 1
         ENDIF ELSE IF ion eq 6 THEN BEGIN
            hplus_vel_distr_sub = hplus_vel_distr[*,anode_index,*]
            hplus_vel_distr_tot = dblarr(n_elements(energies),n_elements(times)) 
            heplus_vel_distr_sub = heplus_vel_distr[*,anode_index,*]
            heplus_vel_distr_tot = dblarr(n_elements(energies),n_elements(times)) 
            heplusplus_vel_distr_sub = heplusplus_vel_distr[*,anode_index,*]
            heplusplus_vel_distr_tot = dblarr(n_elements(energies),n_elements(times)) 
            oplus_vel_distr_sub = oplus_vel_distr[*,anode_index,*]
            oplus_vel_distr_tot = dblarr(n_elements(energies),n_elements(times)) 
            oplusplus_vel_distr_sub = oplusplus_vel_distr[*,anode_index,*]
            oplusplus_vel_distr_tot = dblarr(n_elements(energies),n_elements(times)) 
            
            if n_elements(anode_index) eq 1 then begin
               hplus_vel_distr_tot = reform(hplus_vel_distr_sub)
               heplus_vel_distr_tot = reform(heplus_vel_distr_sub)
               heplusplus_vel_distr_tot = reform(heplusplus_vel_distr_sub)
               oplus_vel_distr_tot = reform(oplus_vel_distr_sub)
               oplusplus_vel_distr_tot = reform(oplusplus_vel_distr_sub)
            endif else begin
               for ii=0,n_elements(energies)-1 do begin                                                          
                  for jj=0, n_elements(times)-1 do begin                          
                     hplus_vel_distr_tot[ii,jj]=mean(hplus_vel_distr_sub[ii,*,jj], /nan)      
                     heplus_vel_distr_tot[ii,jj]=mean(heplus_vel_distr_sub[ii,*,jj], /nan)
                     heplusplus_vel_distr_tot[ii,jj]=mean(heplusplus_vel_distr_sub[ii,*,jj], /nan)
                     oplus_vel_distr_tot[ii,jj]=mean(oplus_vel_distr_sub[ii,*,jj], /nan)
                     oplusplus_vel_distr_tot[ii,jj]=mean(oplusplus_vel_distr_sub[ii,*,jj], /nan)
                  endfor
               endfor
            endelse

            hplus_vel_distr = transpose(hplus_vel_distr_tot)
            hplus_vel_distr(where(hplus_vel_distr eq 0.)) = !VALUES.F_NAN
            heplus_vel_distr = transpose(heplus_vel_distr_tot)
            heplus_vel_distr(where(heplus_vel_distr eq 0.)) = !VALUES.F_NAN
            heplusplus_vel_distr = transpose(heplusplus_vel_distr_tot)
            heplusplus_vel_distr(where(heplusplus_vel_distr eq 0.)) = !VALUES.F_NAN
            oplus_vel_distr = transpose(oplus_vel_distr_tot)
            oplus_vel_distr(where(oplus_vel_distr eq 0.)) = !VALUES.F_NAN
            oplusplus_vel_distr = transpose(oplusplus_vel_distr_tot)
            oplusplus_vel_distr(where(oplusplus_vel_distr eq 0.)) = !VALUES.F_NAN

            store_data, tvar_name(0), data = {x:times, y:hplus_vel_distr, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt(0),ztitle:zt(0)}
            store_data, tvar_name(1), data = {x:times, y:heplus_vel_distr, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt(1),ztitle:zt(1)}
            store_data, tvar_name(2), data = {x:times, y:heplusplus_vel_distr, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt(2),ztitle:zt(2)}
            store_data, tvar_name(3), data = {x:times, y:oplus_vel_distr, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt(3),ztitle:zt(3)}
            store_data, tvar_name(4), data = {x:times, y:oplusplus_vel_distr, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt(4),ztitle:zt(4)}
            append_array, tplotnames, tvar_name

            for ll = 0, 4 do begin
            ylim, tvar_name(ll), 1., 40000.
            zlim, tvar_name(ll), 0, 0, 1
            endfor
         ENDIF 
      END

      5: BEGIN                  ; RF corrected counts, fill value for 0 counts is 0.01
         IF ion lt 5 then begin
            tvar_name = strupcase(sc_id)+'_HPCA_'+sp_name_tvar(ion)+'_RF_CORR_COUNTS'+elevation_str
         endif else if ion eq 6 then begin
            ion_full = [indgen(5)]
            tvar_name = strarr(5)
            for ll = 0, 4 do tvar_name(ll) = strupcase(sc_id)+'_HPCA_'+sp_name_tvar(ion_full(ll))+'_RF_CORR_COUNTS'+elevation_str
         endif else begin
            print, 'Data for BKGD not available.'
         endelse

         IF ion eq 0 THEN BEGIN 
            hplus_rf_corr_sub = hplus_rf_corr[*,anode_index,*]
            hplus_rf_corr_tot = dblarr(n_elements(energies),n_elements(times)) 
            if n_elements(anode_index) eq 1 then begin
               hplus_rf_corr_tot = reform(hplus_rf_corr_sub)
            endif else begin
               for ii=0,n_elements(energies)-1 do begin                                                          
                  for jj=0, n_elements(times)-1 do begin                                
                        hplus_rf_corr_tot[ii,jj]=total(hplus_rf_corr_sub[ii,*,jj], /nan)
                  endfor
               endfor
            endelse
            hplus_rf_corr = transpose(hplus_rf_corr_tot)
            hplus_rf_corr(where(hplus_rf_corr eq 0.)) = !VALUES.F_NAN
            store_data, tvar_name, data = {x:times, y:hplus_rf_corr, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt,ztitle:zt}
            append_array, tplotnames, tvar_name
            ylim, tvar_name, 1., 40000.
            zlim, tvar_name, 0, 0, 1
         ENDIF ELSE IF ion eq 1 THEN BEGIN
            heplus_rf_corr_sub = heplus_rf_corr[*,anode_index,*]
            heplus_rf_corr_tot = dblarr(n_elements(energies),n_elements(times)) 
            if n_elements(anode_index) eq 1 then begin
               heplus_rf_corr_tot = reform(heplus_rf_corr_sub)
            endif else begin
               for ii=0,n_elements(energies)-1 do begin                                                          
                  for jj=0, n_elements(times)-1 do begin                                
                        heplus_rf_corr_tot[ii,jj]=total(heplus_rf_corr_sub[ii,*,jj], /nan)
                  endfor
               endfor
            endelse
            heplus_rf_corr = transpose(heplus_rf_corr_tot)
            heplus_rf_corr(where(heplus_rf_corr eq 0.)) = !VALUES.F_NAN
            store_data, tvar_name, data = {x:times, y:heplus_rf_corr, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt,ztitle:zt}
            append_array, tplotnames, tvar_name
            ylim, tvar_name, 1., 40000.
            zlim, tvar_name, 0, 0, 1
         ENDIF ELSE IF ion eq 2 THEN BEGIN
            heplusplus_rf_corr_sub = heplusplus_rf_corr[*,anode_index,*]
            heplusplus_rf_corr_tot = dblarr(n_elements(energies),n_elements(times)) 
            if n_elements(anode_index) eq 1 then begin
               heplusplus_rf_corr_tot = reform(heplusplus_rf_corr_sub)
            endif else begin
               for ii=0,n_elements(energies)-1 do begin                                                          
                  for jj=0, n_elements(times)-1 do begin                                
                        heplusplus_rf_corr_tot[ii,jj]=total(heplusplus_rf_corr_sub[ii,*,jj], /nan)
                  endfor
               endfor
            endelse
            heplusplus_rf_corr = transpose(heplusplus_rf_corr_tot)
            heplusplus_rf_corr(where(heplusplus_rf_corr eq 0.)) = !VALUES.F_NAN
            store_data, tvar_name, data = {x:times, y:heplusplus_rf_corr, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt,ztitle:zt}
            append_array, tplotnames, tvar_name
            ylim, tvar_name, 1., 40000.
            zlim, tvar_name, 0, 0, 1
         ENDIF ELSE IF ion eq 3 THEN BEGIN
            oplus_rf_corr_sub = oplus_rf_corr[*,anode_index,*]
            oplus_rf_corr_tot = dblarr(n_elements(energies),n_elements(times)) 
            if n_elements(anode_index) eq 1 then begin
               oplus_rf_corr_tot = reform(oplus_rf_corr_sub)
            endif else begin
               for ii=0,n_elements(energies)-1 do begin                                                          
                  for jj=0, n_elements(times)-1 do begin                                
                        oplus_rf_corr_tot[ii,jj]=total(oplus_rf_corr_sub[ii,*,jj], /nan)
                  endfor
               endfor
            endelse
            oplus_rf_corr = transpose(oplus_rf_corr_tot)
            oplus_rf_corr(where(oplus_rf_corr eq 0.)) = !VALUES.F_NAN
            store_data, tvar_name, data = {x:times, y:oplus_rf_corr, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt,ztitle:zt}
            append_array, tplotnames, tvar_name
            ylim, tvar_name, 1., 40000.
            zlim, tvar_name, 0, 0, 1
         ENDIF ELSE IF ion eq 4 THEN BEGIN
            oplusplus_rf_corr_sub = oplusplus_rf_corr[*,anode_index,*]
            oplusplus_rf_corr_tot = dblarr(n_elements(energies),n_elements(times)) 
            if n_elements(anode_index) eq 1 then begin
               oplusplus_rf_corr_tot = reform(oplusplus_rf_corr_sub)
            endif else begin
               for ii=0,n_elements(energies)-1 do begin                                                          
                  for jj=0, n_elements(times)-1 do begin                                
                        oplusplus_rf_corr_tot[ii,jj]=total(oplusplus_rf_corr_sub[ii,*,jj], /nan)
                  endfor
               endfor
            endelse
            oplusplus_rf_corr = transpose(oplusplus_rf_corr_tot)
            oplusplus_rf_corr(where(oplusplus_rf_corr eq 0.)) = !VALUES.F_NAN
            store_data, tvar_name, data = {x:times, y:oplusplus_rf_corr, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt,ztitle:zt}
            append_array, tplotnames, tvar_name
            ylim, tvar_name, 1., 40000.
            zlim, tvar_name, 0, 0, 1
         ENDIF ELSE IF ion eq 6 THEN BEGIN
            hplus_rf_corr_sub = hplus_rf_corr[*,anode_index,*]
            hplus_rf_corr_tot = dblarr(n_elements(energies),n_elements(times)) 
            heplus_rf_corr_sub = heplus_rf_corr[*,anode_index,*]
            heplus_rf_corr_tot = dblarr(n_elements(energies),n_elements(times)) 
            heplusplus_rf_corr_sub = heplusplus_rf_corr[*,anode_index,*]
            heplusplus_rf_corr_tot = dblarr(n_elements(energies),n_elements(times)) 
            oplus_rf_corr_sub = oplus_rf_corr[*,anode_index,*]
            oplus_rf_corr_tot = dblarr(n_elements(energies),n_elements(times)) 
            oplusplus_rf_corr_sub = oplusplus_rf_corr[*,anode_index,*]
            oplusplus_rf_corr_tot = dblarr(n_elements(energies),n_elements(times)) 
            
            if n_elements(anode_index) eq 1 then begin
               hplus_rf_corr_tot = reform(hplus_rf_corr_sub)
               heplus_rf_corr_tot = reform(heplus_rf_corr_sub)
               heplusplus_rf_corr_tot = reform(heplusplus_rf_corr_sub)
               oplus_rf_corr_tot = reform(oplus_rf_corr_sub)
               oplusplus_rf_corr_tot = reform(oplusplus_rf_corr_sub)
            endif else begin
               for ii=0,n_elements(energies)-1 do begin                                                          
                  for jj=0, n_elements(times)-1 do begin                          
                     hplus_rf_corr_tot[ii,jj]=total(hplus_rf_corr_sub[ii,*,jj], /nan)      
                     heplus_rf_corr_tot[ii,jj]=total(heplus_rf_corr_sub[ii,*,jj], /nan)
                     heplusplus_rf_corr_tot[ii,jj]=total(heplusplus_rf_corr_sub[ii,*,jj], /nan)
                     oplus_rf_corr_tot[ii,jj]=total(oplus_rf_corr_sub[ii,*,jj], /nan)
                     oplusplus_rf_corr_tot[ii,jj]=total(oplusplus_rf_corr_sub[ii,*,jj], /nan)
                  endfor
               endfor
            endelse

            hplus_rf_corr = transpose(hplus_rf_corr_tot)
            hplus_rf_corr(where(hplus_rf_corr eq 0.)) = !VALUES.F_NAN
            heplus_rf_corr = transpose(heplus_rf_corr_tot)
            heplus_rf_corr(where(heplus_rf_corr eq 0.)) = !VALUES.F_NAN
            heplusplus_rf_corr = transpose(heplusplus_rf_corr_tot)
            heplusplus_rf_corr(where(heplusplus_rf_corr eq 0.)) = !VALUES.F_NAN
            oplus_rf_corr = transpose(oplus_rf_corr_tot)
            oplus_rf_corr(where(oplus_rf_corr eq 0.)) = !VALUES.F_NAN
            oplusplus_rf_corr = transpose(oplusplus_rf_corr_tot)
            oplusplus_rf_corr(where(oplusplus_rf_corr eq 0.)) = !VALUES.F_NAN

            store_data, tvar_name(0), data = {x:times, y:hplus_rf_corr, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt(0),ztitle:zt(0)}
            store_data, tvar_name(1), data = {x:times, y:heplus_rf_corr, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt(1),ztitle:zt(1)}
            store_data, tvar_name(2), data = {x:times, y:heplusplus_rf_corr, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt(2),ztitle:zt(2)}
            store_data, tvar_name(3), data = {x:times, y:oplus_rf_corr, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt(3),ztitle:zt(3)}
            store_data, tvar_name(4), data = {x:times, y:oplusplus_rf_corr, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt(4),ztitle:zt(4)}

            append_array, tplotnames, tvar_name
            for ll = 0, 4 do begin
            ylim, tvar_name(ll), 1., 40000.
            zlim, tvar_name(ll), 0, 0, 1
            endfor
         ENDIF 
      END

      6: BEGIN     ; Background corrected counts, fill value for 0 counts is 0.01
         IF ion lt 4 then begin
            tvar_name = strupcase(sc_id)+'_HPCA_'+sp_name_tvar(ion)+'_BKGD_CORR_COUNTS'+elevation_str
         endif else if ion eq 6 then begin
            ion_full = [indgen(4)]
            tvar_name = strarr(4)
            for ll = 0, 3 do tvar_name(ll) = strupcase(sc_id)+'_HPCA_'+sp_name_tvar(ion_full(ll))+'_BKGD_CORR_COUNTS'+elevation_str
         endif else begin
            print, 'Data for O++ and BKGD not available'
         endelse

         IF ion eq 0 THEN BEGIN 
            hplus_bkgd_corr_sub = hplus_bkgd_corr[*,anode_index,*]
            hplus_bkgd_corr_tot = dblarr(n_elements(energies),n_elements(times)) 
            if n_elements(anode_index) eq 1 then begin
               hplus_bkgd_corr_tot = reform(hplus_bkgd_corr_sub)
            endif else begin
               for ii=0,n_elements(energies)-1 do begin                                                          
                  for jj=0, n_elements(times)-1 do begin                                
                        hplus_bkgd_corr_tot[ii,jj]=total(hplus_bkgd_corr_sub[ii,*,jj], /nan)
                  endfor
               endfor
            endelse
            hplus_bkgd_corr = transpose(hplus_bkgd_corr_tot)
            hplus_bkgd_corr(where(hplus_bkgd_corr eq 0.)) = !VALUES.F_NAN
            store_data, tvar_name, data = {x:times, y:hplus_bkgd_corr, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt,ztitle:zt}
            append_array, tplotnames, tvar_name
            ylim, tvar_name, 1., 40000.
            zlim, tvar_name, 0, 0, 1
         ENDIF ELSE IF ion eq 1 THEN BEGIN
            heplus_bkgd_corr_sub = heplus_bkgd_corr[*,anode_index,*]
            heplus_bkgd_corr_tot = dblarr(n_elements(energies),n_elements(times)) 
            if n_elements(anode_index) eq 1 then begin
               heplus_bkgd_corr_tot = reform(heplus_bkgd_corr_sub)
            endif else begin
               for ii=0,n_elements(energies)-1 do begin                                                          
                  for jj=0, n_elements(times)-1 do begin                                
                        heplus_bkgd_corr_tot[ii,jj]=total(heplus_bkgd_corr_sub[ii,*,jj], /nan)
                  endfor
               endfor
            endelse
            heplus_bkgd_corr = transpose(heplus_bkgd_corr_tot)
            heplus_bkgd_corr(where(heplus_bkgd_corr eq 0.)) = !VALUES.F_NAN
            store_data, tvar_name, data = {x:times, y:heplus_bkgd_corr, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt,ztitle:zt}
            append_array, tplotnames, tvar_name
            ylim, tvar_name, 1., 40000.
            zlim, tvar_name, 0, 0, 1
         ENDIF ELSE IF ion eq 2 THEN BEGIN
            heplusplus_bkgd_corr_sub = heplusplus_bkgd_corr[*,anode_index,*]
            heplusplus_bkgd_corr_tot = dblarr(n_elements(energies),n_elements(times)) 
            if n_elements(anode_index) eq 1 then begin
               heplusplus_bkgd_corr_tot = reform(heplusplus_bkgd_corr_sub)
            endif else begin
               for ii=0,n_elements(energies)-1 do begin                                                          
                  for jj=0, n_elements(times)-1 do begin                                
                        heplusplus_bkgd_corr_tot[ii,jj]=total(heplusplus_bkgd_corr_sub[ii,*,jj], /nan)
                  endfor
               endfor
            endelse
            heplusplus_bkgd_corr = transpose(heplusplus_bkgd_corr_tot)
            heplusplus_bkgd_corr(where(heplusplus_bkgd_corr eq 0.)) = !VALUES.F_NAN
            store_data, tvar_name, data = {x:times, y:heplusplus_bkgd_corr, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt,ztitle:zt}
            append_array, tplotnames, tvar_name
            ylim, tvar_name, 1., 40000.
            zlim, tvar_name, 0, 0, 1
         ENDIF ELSE IF ion eq 3 THEN BEGIN
            oplus_bkgd_corr_sub = oplus_bkgd_corr[*,anode_index,*]
            oplus_bkgd_corr_tot = dblarr(n_elements(energies),n_elements(times)) 
            if n_elements(anode_index) eq 1 then begin
               oplus_bkgd_corr_tot = reform(oplus_bkgd_corr_sub)
            endif else begin
               for ii=0,n_elements(energies)-1 do begin                                                          
                  for jj=0, n_elements(times)-1 do begin                                
                        oplus_bkgd_corr_tot[ii,jj]=total(oplus_bkgd_corr_sub[ii,*,jj], /nan)
                  endfor
               endfor
            endelse
            oplus_bkgd_corr = transpose(oplus_bkgd_corr_tot)
            oplus_bkgd_corr(where(oplus_bkgd_corr eq 0.)) = !VALUES.F_NAN
            store_data, tvar_name, data = {x:times, y:oplus_bkgd_corr, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt,ztitle:zt}
            append_array, tplotnames, tvar_name
            ylim, tvar_name, 1., 40000.
            zlim, tvar_name, 0, 0, 1
         ENDIF ELSE IF ion eq 6 THEN BEGIN
            hplus_bkgd_corr_sub = hplus_bkgd_corr[*,anode_index,*]
            hplus_bkgd_corr_tot = dblarr(n_elements(energies),n_elements(times)) 
            heplus_bkgd_corr_sub = heplus_bkgd_corr[*,anode_index,*]
            heplus_bkgd_corr_tot = dblarr(n_elements(energies),n_elements(times)) 
            heplusplus_bkgd_corr_sub = heplusplus_bkgd_corr[*,anode_index,*]
            heplusplus_bkgd_corr_tot = dblarr(n_elements(energies),n_elements(times)) 
            oplus_bkgd_corr_sub = oplus_bkgd_corr[*,anode_index,*]
            oplus_bkgd_corr_tot = dblarr(n_elements(energies),n_elements(times))  
            
            if n_elements(anode_index) eq 1 then begin
               hplus_bkgd_corr_tot = reform(hplus_bkgd_corr_sub)
               heplus_bkgd_corr_tot = reform(heplus_bkgd_corr_sub)
               heplusplus_bkgd_corr_tot = reform(heplusplus_bkgd_corr_sub)
               oplus_bkgd_corr_tot = reform(oplus_bkgd_corr_sub)
            endif else begin
               for ii=0,n_elements(energies)-1 do begin                                                          
                  for jj=0, n_elements(times)-1 do begin                          
                     hplus_bkgd_corr_tot[ii,jj]=total(hplus_bkgd_corr_sub[ii,*,jj], /nan)      
                     heplus_bkgd_corr_tot[ii,jj]=total(heplus_bkgd_corr_sub[ii,*,jj], /nan)
                     heplusplus_bkgd_corr_tot[ii,jj]=total(heplusplus_bkgd_corr_sub[ii,*,jj], /nan)
                     oplus_bkgd_corr_tot[ii,jj]=total(oplus_bkgd_corr_sub[ii,*,jj], /nan)
                  endfor
               endfor
            endelse

            hplus_bkgd_corr = transpose(hplus_bkgd_corr_tot)
            hplus_bkgd_corr(where(hplus_bkgd_corr eq 0.)) = !VALUES.F_NAN
            heplus_bkgd_corr = transpose(heplus_bkgd_corr_tot)
            heplus_bkgd_corr(where(heplus_bkgd_corr eq 0.)) = !VALUES.F_NAN
            heplusplus_bkgd_corr = transpose(heplusplus_bkgd_corr_tot)
            heplusplus_bkgd_corr(where(heplusplus_bkgd_corr eq 0.)) = !VALUES.F_NAN
            oplus_bkgd_corr = transpose(oplus_bkgd_corr_tot)
            oplus_bkgd_corr(where(oplus_bkgd_corr eq 0.)) = !VALUES.F_NAN

            store_data, tvar_name(0), data = {x:times, y:hplus_bkgd_corr, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt(0),ztitle:zt(0)}
            store_data, tvar_name(1), data = {x:times, y:heplus_bkgd_corr, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt(1),ztitle:zt(1)}
            store_data, tvar_name(2), data = {x:times, y:heplusplus_bkgd_corr, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt(2),ztitle:zt(2)}
            store_data, tvar_name(3), data = {x:times, y:oplus_bkgd_corr, v:energies}, $
                        dlim = {spec:1,ylog:1,zlog:1,nointerp:1,ytitle:yt(3),ztitle:zt(3)}
            append_array, tplotnames, tvar_name
                        
            for ll = 0, 3 do begin
            ylim, tvar_name(ll), 1., 40000.
            zlim, tvar_name(ll), 0, 0, 1
            endfor
         ENDIF 
      END 
   ENDCASE 
;stop
ENDFOR
dprint, dlevel = 0, '*** procedure mms_sitl_open_hpca_basic_cdf took: ' + string(systime(/sec)-start_time) + ' seconds to run'

;stop

END
