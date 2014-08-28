;
; PP2spectrogram is a helper function that takes a structure of the
; form
;   TIME            DOUBLE    Array[19686]
;   MASS            FLOAT     Array[19686]
;   SCRIPT          STRING    Array[19686]
;   COUNTS_PER_SECOND
;                   FLOAT     Array[19686]
;   MODE            STRING    Array[19686]
;   CS_FIL1_EMISSION
;                   FLOAT     Array[19686]
;   CS_FIL2_EMISSION
;                   FLOAT     Array[19686]
;   OS_FIL1_EMISSION
;                   FLOAT     Array[19686]
;   OS_FIL2_EMISSION
;                   FLOAT     Array[19686]
;   EM1_VOLTAGE     FLOAT     Array[19686]
;   EM2_VOLTAGE     FLOAT     Array[19686]
; and returns a structure of counts_per_second(nmass, ntimes), with
; one second time resolution that can be plotted easily. First,
; interpolate to 0.1 time resolution, then average over seconds.
Function pp2spectrogram, pp

;Get a mass array
  m0 = min(pp.mass, max = m1)
  mass_arr = m0+indgen(m1-m0+1)
  nmass = n_elements(mass_arr)
;Get a time array, start at one second boundaries, with 0.1 second
;time resolution, ntx is the number of time points per second
  ntx = 10
  dt = 1.0/float(ntx)
  t0 = double(long64(pp.time[0]))
  tsec = ceil(max(pp.time) - t0)
  nt = tsec*ntx+1
  time_array = t0+dt*dindgen(nt)
  tmid = 0.5*(time_array+time_array[1:*])
  ntmid = n_elements(tmid)
;Output array
  otp = fltarr(ntmid, nmass)
  For j = 0, nmass-1 Do Begin
;Here all you need is to interpolate for each mass
     this_mass = where(pp.mass Eq mass_arr[j], nj)
     If(nj Eq 0) Then Continue
     otp[*, j] = interpol(pp.counts_per_second[this_mass], pp.time[this_mass], tmid)
     otp[*, j] = otp[*, j] > 1.0e-6
;Apply attenuation here:
;     If(mass_arr[j] Le 150.0) Then att = 1.0 $
;     Else If(mass_arr[j] Gt 150.0 And mass_arr[j] Le 300.0) Then att = 10.0 $
;     Else att = 100.0
;     otp[*, j] = otp[*, j]*att
  Endfor
;Now contract into 1 second resolution; the way that tmid is
;calculated should ensure that all that is needed is a reforming and
;totaling, ntmid/ntx has to be an integer value
  y = reform(otp, ntx, ntmid/ntx, nmass)
  y = total(y, 1)/ntx

;Here's the time_array
  x = t0+dindgen(ntmid/ntx)
Return, {x:x, y:y, v:mass_arr}

End

;+
;NAME:
; mvn_read_ngims_csv
;PURPOSE:
; Reads an NGIMS csv file
;CALLING SEQUENCE:
; p = mvn_read_ngims_csv(filename)
;INPUT:
; filename = the input file name, full path.
;OUTPUT:
; p = a structure with tags corresponding to the columns in the file
; tplot_vars = an array of tplot var names, one for each column
; Currently:
;     TIME, MASS, SCRIPT, COUNTS_PER_SECOND, MODE, CS_FIL1_EMISSION,
;     CS_FIL2_EMISSION, OS_FIL1_EMISSION, OS_FIL2_EMISSION,
;     EM1_VOLTAGE, EM2_VOLTAGE
; The column names are encoded in the file.
; tplot_spec = the name of the tplot mass spectrogram variable
;NOTES:
;NGIMS CSV file notes (via Mehdi)
;
;four operation modes:
;     - csn = closed source neutrals
;     - osnt = open source neutrals thermal (grid at 0 V)
;     - osnb = open source neutrals beam (grid at ~1 V)
;         - osi = open source ion
;
;modes are typically combined on a periapsis pass:
;     csn/osnb, csn/osi
;
;masses are in amu, modulo 150:
;     -   0 < mass <= 150 --> attenuation factor = 1
;     - 150 < mass <= 300 --> attenuation factor = 10
;     - 300 < mass <= 450 --> attenuation factor = 100
;
;masses can come in any order
;a given mass can be present with multiple attenuation factors
;
;masses can come with 1-amu resolution or fractional (~0.1-amu) resolution
;     - for fractional resolution, take all masses within 0.5 amu of an
;           integer, and take the peak count rate in that range
;*** changed to 0.3 amu, for ovelap issues at m= 27, 28 boundary, jmm,
;    2014-08-20 ***
;
;Corrected Rate = Raw Rate * Attenuation Factor * Emission Gain
;
;Maybe 3 panels: CSN, OSN, OSI
;     - OSN and OSI can be combined, since they cannot be done
;       simultaneously, but this might be confusing
;
;Build up spectrograms one pixel at a time?
;HISTORY:
; 2014-07-28, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2014-08-26 14:34:10 -0700 (Tue, 26 Aug 2014) $
; $LastChangedRevision: 15706 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/quicklook/mvn_read_ngims_csv.pro $
;-
Function mvn_read_ngims_csv, filename, tplot_vars, tplot_spec

  filex = file_search(filename)
  If(~is_string(filex)) Then Begin
     dprint, 'File: '+filename+' Not found.'
     Return, -1
  Endif

  p0 = read_csv(filex)
  If(~is_struct(p0)) Then Begin
     dprint, 'Bad File: '+filex
     Return, -1
  Endif

;Assume that the first column is 'TIME', and get the columns
;definitions
  xstart = where(strupcase(p0.field01) Eq 'TIME')
;Just build up the output structure using str_element
  tags0 = tag_names(p0)
  ntags = n_elements(tags0)
  varcount = 0
  For j = 0, ntags-1 Do Begin
     tagj = p0.(j)
     tj_name = strupcase(tagj[xstart])
     tj_val = tagj[xstart+1:*]
     If(tj_name Eq 'TIME') Then Begin
        tj_val = mvn_spc_met_to_unixtime(double(tj_val))
     Endif Else If(tj_name Ne 'SCRIPT' And tj_name Ne 'MODE') Then Begin
        tj_val = float(tj_val)
     Endif

     If(j Eq 0) Then Begin
        p = create_struct(tj_name, tj_val)
     Endif Else str_element, p, tj_name, tj_val, /add_replace

;create tplot variables here too
     If(j Eq 0) Then Begin
        time = tj_val
     Endif Else Begin
        tj_vname = 'mvn_ngims_'+strlowcase(tj_name[0])
        nj = n_elements(tj_val)
        If(tj_name Eq 'SCRIPT' Or tj_name Eq 'MODE') Then Begin
           ss = bsort(tj_val)
           x2 = tj_val[ss]
           ssu = uniq(x2)
           uvals = x2[ssu]
           all_flag = bytarr(nj)
           For k = 0, n_elements(uvals)-1 Do Begin
              one_flag = bytarr(nj)
              okk = where(tj_val Eq uvals[k])
              one_flag[okk] = 1b
              all_flag = all_flag+(2b^k)*one_flag
           Endfor
           store_data, tj_vname, data = {x:time, y:all_flag}
           options, tj_vname, 'tplot_routine', 'bitplot'
           options, tj_vname, 'labels', uvals
        Endif Else Begin
           store_data, tj_vname, data = {x:time, y:tj_val}
        Endelse
        If(varcount eq 0) Then tplot_vars = tj_vname $
        Else tplot_vars = [tplot_vars, tj_vname]
        varcount = varcount+1
     Endelse
  Endfor

;Here create the spectrogram tplot variable
;First get rid of fractional masses:
;  xxx = where(p.mass Gt 0 and p.mass mod long(p.mass) Ne 0)
  yyy = where(p.mass Gt 0 and p.mass mod long(p.mass) Eq 0, nyyy)
  tags = tag_names(p)
  ntags = n_elements(tags)
;pnew only has integer mass values
  pnew = p
  For i = 0, ntags-1 Do Begin
     tagi = p.(i)
     str_element, pnew, tags[i], tagi[yyy], /add_replace
  Endfor
     
  ntimes = n_elements(p.time)
  For j = 0, nyyy-1 Do Begin
;If there are fractional masses above and below, then assign a value
     jj = yyy[j]
     jm1 = (jj-1) > 0
     jp1 = (jj+1) < (ntimes-1)
     If((p.mass[jj]-p.mass[jm1]) Lt 0.5 And $
        (p.mass[jp1]-p.mass[jm1]) Lt 0.5) Then Begin
        jm3 = (jj-3) > 0
        jp3 = (jj+3) < (ntimes+1)
        counts_temp = max(p.counts_per_second[jm3:jp3])
        pnew.counts_per_second[j] = counts_temp
     Endif
  Endfor
;split into modes, and create a tplot spectrogram for each mode
  modes = ['csn', 'osnt', 'osnb', 'osi']
  pcsn = -1 & posnt = -1 & posnb = -1 & posi = -1
  dl = {units:'CPS', ztitle:'CPS', ytitle:'Mass (amu)', spec:1, log:1, ylog:0, zlog:1}
  For j = 0, n_elements(modes)-1 Do Begin
     this_mode = where(pnew.mode Eq modes[j], nj)
     If(nj Eq 0) Then continue
     pp = pnew
     For i = 0, ntags-1 Do Begin
        tagi = pnew.(i)
        str_element, pp, tags[i], tagi[this_mode], /add_replace
     Endfor
     Case modes[j] Of
        'csn': Begin
           pcsn = pp2spectrogram(temporary(pp))
           store_data, 'mvn_ngims_csn', data = pcsn, dlimits = dl
        End
        'osnt': Begin
           posnt = pp2spectrogram(temporary(pp))
           store_data, 'mvn_ngims_osnt', data = posnt, dlimits = dl
        End
        'osnb': Begin
           posnb = pp2spectrogram(temporary(pp))
           store_data, 'mvn_ngims_osnb', data = posnb, dlimits = dl
        End
        'osi': Begin
           posi = pp2spectrogram(temporary(pp))
           store_data, 'mvn_ngims_osi', data = posi, dlimits = dl
        End

     Endcase
  Endfor
  
  Return, pnew

End

        

