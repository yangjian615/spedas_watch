;+
;NAME:
; mvn_sta_cmn_d89a_l2gen.pro
;PURPOSE:
; turn a MAVEN STA RATES common block into a L2 CDF.
;CALLING SEQUENCE:
; mvn_sta_cmn_d89a_l2gen, cmn_dat
;INPUT:
; cmn_dat = a structrue with the data:
;   PROJECT_NAME    STRING    'MAVEN'
;   SPACECRAFT      STRING    '0'
;   DATA_NAME       STRING    'd9_12r64e'
;   APID            STRING    'd9'
;   VALID           INT       Array[675]
;   QUALITY_FLAG    INT       Array[675]
;   TIME            DOUBLE    Array[675]
;   END_TIME        DOUBLE    Array[675]
;   INTEG_T         DOUBLE    Array[675]
;   MD              INT       Array[675]
;   MODE            INT       Array[675]
;   RATE            INT       Array[675]
;   SWP_IND         INT       Array[675]
;   ENERGY          FLOAT     Array[9, 64]
;   NRATE           INT             12
;   RATE_LABELS     STRING    Array[12]
;   RATES           DOUBLE    Array[675, 12, 64]
; All of this has to go into the CDF, also Epoch, tt200, MET time
; variables; some of the names are changed to titles given in the SIS
; Data is changed from double to float prior to output
;KEYWORDS:
; otp_struct = this is the structure that is passed into
;              cdf_save_vars to creat the file
; directory = Set this keyword to direct the output into this
;             directory; the default is to populate the MAVEN STA
;             database. /disks/data/maven/pfp/sta/l2
; no_compression = if set, do not compress the CDF file
;HISTORY:
; 13-jun-2014, jmm, hacked from mvn_sta_cmn_l2gen.pro
; $LastChangedBy: jimm $
; $LastChangedDate: 2014-09-10 12:20:31 -0700 (Wed, 10 Sep 2014) $
; $LastChangedRevision: 15751 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/l2gen/mvn_sta_cmn_d89a_l2gen.pro $
;-
Pro mvn_sta_cmn_d89a_l2gen, cmn_dat, otp_struct = otp_struct, directory = directory, $
                       no_compression = no_compression, _extra = _extra

;Keep track of software versioning here
  common mvn_sta_software_version, sw_vsn
  sw_vsn_str = 'v'+string(sw_vsn, format='(i2.2)')

  If(~is_struct(cmn_dat)) Then Begin
     message,/info,'No Input Structure'
     Return
  Endif
;First, global attributes
  global_att = {Title:'MAVEN STATIC Ion Spectra', $
                Project:'MAVEN', $
                Source_name:'MAVEN>Mars Atmosphere and Volatile Evolution Mission', $
                Discipline:'Space Physics>Planetary Physics>Particles', $
                Data_type:'CAL>Calibration', $
                Descriptor:'STATIC> Supra-Thermal Thermal Ion Composition Particle Distributions', $
                Data_version:'0', $
                File_naming_convention: 'source_descriptor_datatype_yyyyMMdd', $
                PI_name:'J. P. McFadden', $
                PI_affiliation:'U.C. Berkeley Space Sciences Laboratory', $
                TEXT:'STATIC> Supra-Thermal And Thermal Ion Composition Particle Distributions', $
                Instrument_type:'Particles (space)' , $
                Mission_group:'MAVEN' , $
                Logical_source:'urn:nasa:pds:maven.static.c:data.c6_2e64m' , $
                Logical_file_id:'mvn_sta_l2_c6_00000000_v00_r00.cdf' , $
                Logical_source_description:'Supra-Thermal And Thermal Ion Composition Particle Distributions', $
                Rules_of_use:'Open Data for Scientific Use' , $
                Generated_by:'MAVEN SOC' , $
                Generation_date:'2014-04-28' , $
                MODS:'Rev-1 2014-04-28' , $
                LINK_TEXT:'General Information about the MAVEN mission' , $
                LINK_TITLE:'MAVEN home page' , $
                HTTP_LINK:'http://lasp.colorado.edu/home/maven/', $
                Acknowledgment:'None', $
                Time_resolution:'4 sec', $
                ADID_ref:'-'}

;Now variables and attributes
  cvars = strlowcase(tag_names(cmn_dat))

  apid = strlowcase(cmn_dat.apid)

; Here are variable names, type, catdesc, and lablaxis, from the SIS
  rv_vt =  [['EPOCH', 'EPOCH', 'Spacecraft event time for this data record (UTC Epoch time from 01-Jan-0000 00:00:00.000 without leap seconds), one element per ion distribution (NUM_DISTS elements)', 'EPOCH'], $
            ['TIME_TT2000', 'TT2000', 'UTC time from 01-Jan-2000 12:00:00.000 including leap seconds), one element per ion distribution (NUM_DISTS elements)', 'TT2000'], $
            ['TIME_MET', 'DOUBLE', 'Mission elapsed time for this data record, one element per ion distribution (NUM_DISTS elements)', 'Mission Elapsed Time'], $
            ['TIME_EPHEMERIS', 'DOUBLE', 'Time used by SPICE program (NUM_DISTS elements)', 'SPICE Ephemeris Time'], $
            ['TIME_UNIX', 'DOUBLE', 'Unix time (elapsed seconds since 1970-01-01/00:00 without leap seconds) for this data record, one element per ion distribution. This time is the center time of data collection. (NUM_DISTS elements)', 'Unix Time'], $
            ['TIME_START', 'DOUBLE', 'Unix time at the start of data collection. (NUM_DISTS elements)', 'Interval start time (unix)'], $
            ['TIME_END', 'DOUBLE', 'Unix time at the end of data collection. (NUM_DISTS elements)', 'Interval end time (unix)'], $
            ['INTEG_TIME', 'DOUBLE', 'Integration time for rate in seconds. (NUM_DISTS elements).', 'Integration time'], $
            ['VALID', 'INTEGER', 'Validity flag codes valid data (bit 0), test pulser on (bit 1), diagnostic mode (bit 2), data compression type (bit 3-4), packet compression (bit 5) (NUM_DISTS elements)', ' Valid flag'], $
            ['MD', 'INTEGER', 'Mode byte in packet header. (NUM_DISTS elements)', 'Mode byte'], $
            ['MODE', 'INTEGER', 'Decoded mode number. (NUM_DISTS elements)', 'Mode number'], $
            ['RATE', 'INTEGER', 'Decoded telemetry rate number. (NUM_DISTS elements)', 'Telemetry rate number'], $
            ['SWP_IND', 'INTEGER', 'Index that identifies the energy and deflector sweep look up tables (LUT) for the sensor. SWP_IND is an index that selects the following support data arrays: ENERGY, DENERGY, THETA, DTHETA, PHI, DPHI, DOMEGA, GF and MASS_ARR. (NUM_DISTS elements), EN_IND ≤ NSWP', 'Sweep index'], $
            ['RATES', 'FLOAT', 'Rate data for the rate channels sorted by energy step with dimension (NUM_DISTS, NRATE, NENERGY) units=counts/s', 'Rates'], $
            ['RATE_CHANNEL', 'INTEGER', 'Rate Channel selected (0-11)', 'Channel'], $
            ['QUALITY_FLAG', 'INTEGER', 'Quality flag (NUM_DISTS elements)', 'Quality flag']]
;Use Lower case for variable names
  rv_vt[0, *] = strlowcase(rv_vt[0, *])

;No need for lablaxis values here, just use the name
  nv_vt = [['PROJECT_NAME', 'STRING', 'MAVEN'], $
           ['SPACECRAFT', 'STRING', '0'], $
           ['DATA_NAME', 'STRING', 'XX YYY where XX is the APID and YYY is the array abbreviation (64e2m, 32e32m,… etc.)'], $
           ['APID', 'STRING', 'XX, where XX is the APID'], $
           ['NUM_DISTS', 'INTEGER', 'Number of measurements or times in the file'], $
           ['NSWP', 'INTEGER', 'Number of sweep tables – will increase over mission as new sweep modes are added'], $
           ['ENERGY', 'FLOAT', 'Energy array with dimension (NSWP, 64)'], $
           ['NRATE', 'INTEGER', 'Number of rate channels - 12'], $
           ['RATE_LABELS', 'STRING', 'Rate label string array with dimension NRATE']]

;Use Lower case for variable names
  nv_vt[0, *] = strlowcase(nv_vt[0, *])

;Create variables for epoch, tt_2000, MET, hacked from mvn_pf_make_cdf.pro
  cdf_leap_second_init
  date_range = time_double(['2013-11-18/00:00','2040-12-31/23:59'])
  met_range = date_range-date_range[0]
  epoch_range = time_epoch(date_range)
  et_range = time_ephemeris(date_range)
  tt2000_range = long64((add_tt2000_offset(date_range)-time_double('2000-01-01/12:00'))*1e9)

;Use center time for time variables
  center_time = 0.5*(cmn_dat.time+cmn_dat.end_time)
  num_dists = n_elements(center_time)

;Initialize
  otp_struct = -1
  count = 0L
;FIrst handle RV variables
  lrv = n_elements(rv_vt[0, *])
  For j = 0L, lrv-1 Do Begin
;Either the name is in the common block or not, names not in the
;common block have to be dealt with as special cases. Vectors will
;need label and component variables
     is_tvar = 0b
     vj = rv_vt[0, j]
     Have_tag = where(cvars Eq vj, nhave_tag)
     have_dvar = 1b             ;Mostly all vars will be filled
     If(nhave_tag Gt 0) Then Begin
        dvar = cmn_dat.(have_tag)
     Endif Else Begin
;Case by case basis
        Case vj of
           'epoch': Begin
              dvar = time_epoch(center_time)
              is_tvar = 1b
           End
           'time_tt2000': Begin
              dvar = double(long64((add_tt2000_offset(center_time)-time_double('2000-01-01/12:00'))*1e9))
              is_tvar = 1b
           End
           'time_met': Begin
              dvar = mvn_spc_met_to_unixtime(center_time, /reverse)
              is_tvar = 1b
           End
           'time_ephemeris': Begin
              dvar = time_ephemeris(center_time)
              is_tvar = 1b
           End
           'time_unix': Begin
              dvar = center_time
              is_tvar = 1b
           End
           'time_start': Begin
              dvar = cmn_dat.time
              is_tvar = 1b
           End
           'time_end': Begin
              dvar = cmn_dat.end_time
              is_tvar = 1b
           End
           'integ_time': dvar = cmn_dat.integ_t
           Else: Begin
              message, /info, 'Variable '+vj+' Unaccounted for; Skipping'
              have_dvar = 0b
           End
        Endcase
     Endelse

     If(have_dvar Eq 0) Then Continue

;change data to float from double
     if(vj eq 'rates') then dvar = float(dvar) 

     cdf_type = idl2cdftype(dvar, format_out = fmt, fillval_out = fll, validmin_out = vmn, validmax_out = vmx)
;Change types for CDF time variables
     If(vj eq 'epoch') Then cdf_type = 'CDF_EPOCH' $
     Else If(vj eq 'time_tt2000') Then cdf_type = 'CDF_TIME_TT2000'

     dtype = size(dvar, /type)
;variable attributes here, but only the string attributes, the others
;depend on the data type
     vatt = {catdesc:'NA', display_type:'NA', fieldnam:'NA', $
             units:'None', depend_time:'NA', $
             depend_0:'NA', depend_1:'NA', depend_2:'NA', $
             depend_3:'NA', var_type:'NA', $
             coordinate_system:'sensor', $
             scaletyp:'NA', lablaxis:'NA',$
             labl_ptr_1:'NA',labl_ptr_2:'NA',labl_ptr_3:'NA', $
             form_ptr:'NA', monoton:'NA'}

;fix fill vals, valid mins and valid max's here
     If(vj Eq 'epoch') Then Begin
        xtime = time_double('9999-12-31/23:59:59.999')
        str_element, vatt, 'fillval', time_epoch(xtime), /add
        str_element, vatt, 'validmin', epoch_range[0], /add
        str_element, vatt, 'validmax', epoch_range[1], /add
     Endif Else If(vj Eq 'time_tt2000') Then Begin
        xtime = time_double('9999-12-31/23:59:59.999')
        xtime = long64((add_tt2000_offset(xtime)-time_double('2000-01-01/12:00'))*1e9)
        str_element, vatt, 'fillval', xtime, /add
        str_element, vatt, 'validmin', tt2000_range[0], /add
        str_element, vatt, 'validmax', tt2000_range[1], /add
     Endif Else If(vj Eq 'time_met') Then Begin
        xtime = time_double('9999-12-31/23:59:59.999')-time_double('2013-11-18/00:00')
        str_element, vatt, 'fillval', xtime, /add
        str_element, vatt, 'validmin', met_range[0], /add
        str_element, vatt, 'validmax', met_range[1], /add
     Endif Else If(vj Eq 'time_ephemeris') Then Begin
        xtime = time_double('9999-12-31/23:59:59.999')
        str_element, vatt, 'fillval', time_ephemeris(xtime), /add
        str_element, vatt, 'validmin', et_range[0], /add
        str_element, vatt, 'validmax', et_range[1], /add
     Endif Else If(vj Eq 'time_unix' Or vj Eq 'time_start' Or vj Eq 'time_end') Then Begin
        xtime = time_double('9999-12-31/23:59:59.999')
        str_element, vatt, 'fillval', xtime, /add
        str_element, vatt, 'validmin', date_range[0], /add
        str_element, vatt, 'validmax', date_range[1], /add
     Endif Else Begin
        str_element, vatt, 'fillval', fll, /add
        str_element, vatt, 'validmin', vmn, /add
        str_element, vatt, 'validmax', vmx, /add
        str_element, vatt, 'format', fmt, /add
;scalemin and scalemax depend on the variable's values
        str_element, vatt, 'scalemin', vmn, /add
        str_element, vatt, 'scalemax', vmx, /add
        ok = where(finite(dvar), nok)
        If(nok Gt 0) Then Begin
           vatt.scalemin = min(dvar[ok])
           vatt.scalemax = max(dvar[ok])
        Endif
     Endelse

     vatt.catdesc = rv_vt[2, j]
;Rates are data, all else is support data
     IF(vj Eq 'rates') Then Begin
        vatt.scaletyp = 'log' 
        vatt.display_type = 'time_series'
        vatt.var_type = 'data'
     Endif Else Begin
        vatt.scaletyp = 'linear'
        vatt.display_type = 'time_series'
        vatt.var_type = 'support_data'
     Endelse

     vatt.fieldnam = rv_vt[3, j] ;shorter name
;Units
     If(is_tvar) Then Begin ;Time variables
        If(vj Eq 'time_tt2000') Then vatt.units = 'nanosec' Else vatt.units = 'sec'
     Endif Else Begin
        If(vj Eq 'rates') Then vatt.units = '1/sec'
     Endelse

;Depends and labels
     vatt.depend_time = 'time_unix'
     vatt.depend_0 = 'time_tt2000'
     vatt.lablaxis = rv_vt[3, j]

;Assign labels and components for vectors
     If(vj Eq 'rates') Then Begin
        Case apid Of
           'd8':Begin
              vatt.depend_1 = 'compno_'+strcompress(/remove_all, string(cmn_dat.nrate))              
              vatt.labl_ptr_1 = 'rate_labels'
           End
           'd9': Begin
              vatt.depend_1 = 'compno_'+strcompress(/remove_all, string(cmn_dat.nrate))              
              vatt.labl_ptr_1 = 'rate_labels'
              vatt.depend_2 = 'compno_64'
              vatt.labl_ptr_2 = 'rates_energy_labl_64'
           End
           'da':Begin
              vatt.depend_1 = 'compno_64'
              vatt.labl_ptr_1 = 'rates_energy_labl_64'
           End
        Endcase
     Endif
     
;Time variables are monotonically increasing:
     If(is_tvar) Then vatt.monoton = 'INCREASE' Else vatt.monoton = 'FALSE'

;delete all 'NA' tags
     vatt_tags = tag_names(vatt)
     nvatt_tags = n_elements(vatt_tags)
     rm_tag = bytarr(nvatt_tags)
     For k = 0, nvatt_tags-1 Do Begin
        If(is_string(vatt.(k)) && vatt.(k) Eq 'NA') Then rm_tag[k] = 1b
     Endfor
     xtag = where(rm_tag Eq 1, nxtag)
     If(nxtag Gt 0) Then Begin
        tags_to_remove = vatt_tags[xtag]
        For k = 0, nxtag-1 Do str_element, vatt, tags_to_remove[k], /delete
     Endif

;Create and fill the variable structure
     vsj = {name:'', num:0, is_zvar:1, datatype:'', $
            type:0, numattr: -1, numelem: 1, recvary: 1b, $
            numrec:0L, ndimen: 0, d:lonarr(6), dataptr:ptr_new(), $
            attrptr:ptr_new()}
     vsj.name = vj
     vsj.datatype = cdf_type
     vsj.type = dtype
     vsj.numrec = num_dists
;It looks as if you do not include the time variation?
     ndim = size(dvar, /n_dimen)
     dims = size(dvar, /dimen)
     vsj.ndimen = ndim-1
     If(ndim Gt 1) Then vsj.d[0:ndim-2] = dims[1:*]
     vsj.dataptr = ptr_new(dvar)
     vsj.attrptr = ptr_new(vatt)
     
;Append the variables structure
     If(count Eq 0) Then vstr = vsj Else vstr = [vstr, vsj]
     count = count+1
  Endfor

;Now the non-record variables
  nrv = n_elements(nv_vt[0, *])
  For j = 0L, nrv-1 Do Begin
     vj = nv_vt[0, j]
     Have_tag = where(cvars Eq vj, nhave_tag)
     have_dvar = 1b
     If(nhave_tag Gt 0) Then Begin
        dvar = cmn_dat.(have_tag)
     Endif Else Begin
;Case by case basis
        Case vj of
           'num_dists': Begin
              dvar = num_dists
           End        
           'nswp': Begin
              dvar = fix(n_elements(uniq(cmn_dat.swp_ind)))
           End
           Else: Begin
              message, /info, 'Variable '+vj+' Unaccounted for. Skipping'
              have_dvar = 0b
           End
        Endcase
     Endelse
     If(have_dvar Eq 0) Then continue
     cdf_type = idl2cdftype(dvar, format_out = fmt, fillval_out = fll, validmin_out = vmn, validmax_out = vmx)
     dtype = size(dvar, /type)
;variable attributes here, but only the string attributes, the others
;depend on the data type
     vatt = {catdesc:'NA', fieldnam:'NA', $
             units:'NA', var_type:'support_data', $
             coordinate_system:'sensor'}
     str_element, vatt, 'format', fmt, /add
;Don't need mins and maxes for string variables
     If(~is_string(dvar)) Then Begin
        str_element, vatt, 'fillval', fll, /add
        str_element, vatt, 'validmin', vmn, /add
        str_element, vatt, 'validmax', vmx, /add
;scalemin and scalemax depend on the variable's values
        str_element, vatt, 'scalemin', vmn, /add
        str_element, vatt, 'scalemax', vmx, /add
        ok = where(finite(dvar), nok)
        If(nok Gt 0) Then Begin
           vatt.scalemin = min(dvar[ok])
           vatt.scalemax = max(dvar[ok])
        Endif
     Endif
     vatt.catdesc = nv_vt[2, j]
     vatt.fieldnam = nv_vt[0, j]
     If(vj Eq 'energy') Then vatt.units = 'eV'

;Create and fill the variable structure
     vsj = {name:'', num:0, is_zvar:1, datatype:'', $
            type:0, numattr: -1, numelem: 1, recvary: 0b, $
            numrec:-1L, ndimen: 0, d:lonarr(6), dataptr:ptr_new(), $
            attrptr:ptr_new()}
     vsj.name = vj
     vsj.datatype = cdf_type
     vsj.type = dtype
;Include all dimensions
     ndim = size(dvar, /n_dimen)
     dims = size(dvar, /dimen)
     vsj.ndimen = ndim
     If(ndim Gt 0) Then vsj.d[0:ndim-1] = dims
     vsj.dataptr = ptr_new(dvar)
     vsj.attrptr = ptr_new(vatt)
     
;Append the variables structure
     If(count Eq 0) Then vstr = vsj Else vstr = [vstr, vsj]
     count = count+1
  Endfor
     
;Now compnos, need 12, 64
  ext_compno = [12, 64]
  ss0 = sort(ext_compno)
  ext_compno = ext_compno(ss0)
  ss = uniq(ext_compno)
  ext_compno = ext_compno[ss]
  vcompno = 'compno_'+strcompress(/remove_all, string(ext_compno))

  For j = 0, n_elements(vcompno)-1 Do Begin
     vj = vcompno[j]
     xj = strsplit(vj, '_', /extract)
     nj = Fix(xj[1])
;Component attributes
     vatt =  {catdesc:vj, fieldnam:vj, $
              fillval:0, format:'I3', $
              validmin:0, dict_key:'number', $
              validmax:255, var_type:'metadata'}
;Also a data array
     dvar = 1+indgen(nj)
;Create and fill the variable structure
     vsj = {name:'', num:0, is_zvar:1, datatype:'', $
            type:0, numattr: -1, numelem: 1, recvary: 0b, $
            numrec:-1L, ndimen: 0, d:lonarr(6), dataptr:ptr_new(), $
            attrptr:ptr_new()}
     vsj.name = vj
     vsj.datatype = 'CDF_INT2'
     vsj.type = 2
;Include all dimensions
     ndim = size(dvar, /n_dimen)
     dims = size(dvar, /dimen)
     vsj.ndimen = ndim
     If(ndim Gt 0) Then vsj.d[0:ndim-1] = dims
     vsj.dataptr = ptr_new(dvar)
     vsj.attrptr = ptr_new(vatt)
     
;Append the variables structure
     If(count Eq 0) Then vstr = vsj Else vstr = [vstr, vsj]
     count = count+1
  Endfor
     
;Labels now, only energy neede, since rate labels have their own variables
  lablvars = 'rates_energy_labl_64'

  For j = 0, n_elements(lablvars)-1 Do Begin
     vj = lablvars[j]
     xj = strsplit(vj, '_', /extract)
     nj = Fix(xj[3])
     aj = xj[0]+'@'+strupcase(xj[1])
     dvar = aj+strcompress(/remove_all, string(indgen(nj)))

     ndv = n_elements(dvar)
     numelem = strlen(dvar[ndv-1]) ;needed for numrec
     fmt = 'A'+strcompress(/remove_all, string(numelem))

;Label attributes
     vatt =  {catdesc:vj, fieldnam:vj, $
              format:fmt, dict_key:'label', $
              var_type:'metadata'}
;Create and fill the variable structure
     vsj = {name:'', num:0, is_zvar:1, datatype:'', $
            type:0, numattr: -1, numelem: 1, recvary: 0b, $
            numrec:-1L, ndimen: 0, d:lonarr(6), dataptr:ptr_new(), $
            attrptr:ptr_new()}
     vsj.name = vj
     vsj.datatype = 'CDF_CHAR'
     vsj.type = 1
     vsj.numelem = numelem
;Include all dimensions
     ndim = size(dvar, /n_dimen)
     dims = size(dvar, /dimen)
     vsj.ndimen = ndim
     If(ndim Gt 0) Then vsj.d[0:ndim-1] = dims
     vsj.dataptr = ptr_new(dvar)
     vsj.attrptr = ptr_new(vatt)
     
;Append the variables structure
     If(count Eq 0) Then vstr = vsj Else vstr = [vstr, vsj]
     count = count+1
  Endfor
     
  nvars = n_elements(vstr)
  natts = n_tags(global_att)+n_tags(vstr[0])

  inq = {ndims:0l, decoding:'HOST_DECODING', $
         encoding:'IBMPC_ENCODING', $
         majority:'ROW_MAJOR', maxrec:-1,$
         nvars:0, nzvars:nvars, natts:natts, dim:lonarr(1)}

  If(num_dists Gt 0) Then Begin
     tres = 86400.0/num_dists
     tres = strcompress(string(tres, format = '(f8.1)'))+' sec'
  Endif Else tres = '   0.0 sec'
  global_att.time_resolution = tres

  otp_struct = {filename:'', g_attributes:global_att, inq:inq, nv:nvars, vars:vstr}

;Create filename and call cdf_save_vars.
  If(keyword_set(directory)) Then Begin
     dir = directory
     If(~is_string(file_search(dir))) Then file_mkdir, dir
     temp_string = strtrim(dir, 2)
     ll = strmid(temp_string, strlen(temp_string)-1, 1)
     If(ll Ne '/' And ll Ne '\') Then temp_string = temp_string+'/'
     dir = temporary(temp_string)
  Endif Else dir = './'


  Case apid Of
     'd8': ext = strcompress(strlowcase(cmn_dat.apid), /remove_all)+'-12r1e'
     'd9': ext = strcompress(strlowcase(cmn_dat.apid), /remove_all)+'-12r64e'
     'da': ext = strcompress(strlowcase(cmn_dat.apid), /remove_all)+'-1r64e'
  Endcase

;date can be complicated, I'm guessing that the median center
;time will work best
  date = time_string(median(center_time), precision=-3, format=6)

  file0 = 'mvn_sta_l2_'+ext+'_'+date+'_'+sw_vsn_str+'.cdf'
  fullfile0 = dir+file0

;save the file -- full database management
  mvn_sta_cmn_l2file_save, otp_struct, fullfile0, no_compression = no_compression

  Return
End
