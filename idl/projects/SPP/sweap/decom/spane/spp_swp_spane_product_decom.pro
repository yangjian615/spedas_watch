; $LastChangedBy: phyllisw $
; $LastChangedDate: 2016-03-04 08:47:44 -0800 (Fri, 04 Mar 2016) $
; $LastChangedRevision: 20325 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/decom/spane/spp_swp_spane_product_decom.pro $





function spp_swp_spane_product_decom, ccsds, ptp_header=ptp_header, apdat=apdat

  ;;-------------------------------------------
  ;; Parse data
  header    = ccsds.data[0:19]
  data      = ccsds.data[20:*]
  data_size = n_elements(data)
  apid_name = string(format='(z02)',ccsds.data[1])


  ;;---------------------------------------------
  ;; WORD 1 - 00001aaa aaaaaaaa   
  ;; a = APID bits 
  flag = ishft(ccsds.data[0],-3)
  ;apid = 

  ;;-------------------------------------------
  ;; WORD 6 - ssssssss ssssssxx  
  ;; s=MET subseconds, x=Cyclecnt LSBs
  MET = ishft(data[10],8) and ishft(data[11],-2)

  ;;-------------------------------------------
  ;; Use APID to determine packet size
  ;; '60' -> '360'x ...
  pkt_size_expected = [ 16,  4096,  16,   4096, 16, 4096, 16, 4096] 
  apid_loc = ['60', '61', '62', '63', '64', '65', '66', '67']
  ns = pkt_size_expected[(where(apid_loc eq apid_name))[0]]


  ;;-------------------------------------------
  ;; Check for compression
  compression = (ccsds.data[12] and 'a0'x) ne 0
  bps =  ([4,1])[ compression ]  
  nbytes_expected = ns * bps

  if n_elements(data) ne nbytes_expected then begin
     dprint,dlevel=3, 'Size error ',  n_elements(data),nbytes_expected,ccsds.size+7,ccsds.apid, format='(a,i5,i5,i5," ",z03)'
     return, 0
  endif

  ;print, apid_name, ns, compression, n_elements(data)

  ;;-------------------------------------------
  ;; Decompress if necessary
;  print, 'ccsds.data[12]', ccsds.data[12]
;  print, 'ccsds.apid', ccsds.apid
;  print, 'n_elements(data)', n_elements(data)
  if compression then $
     cnts = spp_swp_log_decomp(data[0:ns-1],0) $
  else $
     cnts = swap_endian(ulong(data,0,ns) ,/swap_if_little_endian ) 


  ;; WORD 1 - 00001aaa aaaaaaaa - ApID bits

  ;; WORD 7
  log_flag    = header[12]

  status_flag = header[18]

  f_counter = swap_endian(ulong(header,16,1), /swap_if_little_endian)

  ;;--------------
  ;; Peaks
  peak_bin = header[19]
  
  
  ; The Remap array is a hacked attempt at solving the test pulser mapping anomaly
  ;remap=[3, 2, 1, 0, 15, 14, 13, 12, 8, 7, 6, 5, 4, 9, 10, 11]
  ;remap=[2, 3, 0, 1, 14, 15, 12, 13, 7, 8, 5, 6, 9, 4, 11, 10]
  ;remap=[3, 2, 1, 0, 12, 11, 10, 9, 8, 13, 14, 15, 7, 6, 5, 4]
  ;remap=[2, 3, 0, 1, 11, 12, 9, 10, 13, 8, 15, 14, 6, 7, 4, 5]
  ;remap=[2, 3, 0, 1, 15, 14, 13, 12, 4, 5, 6, 7, 8, 9, 11, 10]
  ;remap=[2, 3, 0, 1, 15, 14, 4, 13, 5, 12, 7, 6, 9, 8, 11, 10]
  ;remap=[2, 3, 0, 1, 15, 14, 4, 12, 5, 6, 13, 7, 9, 8, 11, 10]
  ;remap=[3, 2, 1, 0, 15, 14, 13, 12, 8, 7, 6, 5, 4, 9, 10, 11]
  
  case 1 of

     ;;-----------------------------------------
     ;;Product Full Sweep - 16A - '360'x
;     (apid_name eq '60') and () : begin
;        str = { $
;              title:'[16A]',$
;              time:ccsds.time, $
;              seq_cntr:ccsds.seq_cntr,  $
;              seq_group: ccsds.seq_group,  $
;              ndat: n_elements(cnts), $
;              peak_bin: peak_bin, $
;              log_flag: log_flag, $
;              status_flag: status_flag,$
;              f_counter: f_counter,$
;              cnts: float(cnts)}
;     end



     ;;------------------------------------------
     ;;Product Full Sweep: Archive - 08D - '360'x
     
     (apid_name eq '60') : begin
        str = { $
              time:        ccsds.time, $
              seq_cntr:    ccsds.seq_cntr,  $
              seq_group:   ccsds.seq_group,  $
              ndat:        n_elements(cnts), $
              peak_bin:    peak_bin, $
              log_flag:    log_flag, $
              status_flag: status_flag,$
              f_counter:   f_counter,$
              cnts:        float(cnts[*])};[remap])}
     end


     ;;----------------------------------------------
     ;;Product Full Sweep: Archive - 16Ax256S - '361'x
     (apid_name eq '61') : begin
        cnts = reform(cnts,16,256)
        str = { $
              time:      ccsds.time, $
              seq_cntr:  ccsds.seq_cntr,  $
              seq_group: ccsds.seq_group,  $
              ndat:      n_elements(cnts), $
              peak_bin:  peak_bin, $
              log_flag:  log_flag, $
              status_flag: status_flag,$
              f_counter: f_counter,$
              cnts_a00:  float(reform(cnts[ 0,*])), $
              cnts_a01:  float(reform(cnts[ 1,*])), $
              cnts_a02:  float(reform(cnts[ 2,*])), $
              cnts_a03:  float(reform(cnts[ 3,*])), $
              cnts_a04:  float(reform(cnts[ 4,*])), $
              cnts_a05:  float(reform(cnts[ 5,*])), $
              cnts_a06:  float(reform(cnts[ 6,*])), $
              cnts_a07:  float(reform(cnts[ 7,*])), $
              cnts_a08:  float(reform(cnts[ 8,*])), $
              cnts_a09:  float(reform(cnts[ 9,*])), $
              cnts_a10:  float(reform(cnts[10,*])), $
              cnts_a11:  float(reform(cnts[11,*])), $
              cnts_a12:  float(reform(cnts[12,*])), $
              cnts_a13:  float(reform(cnts[13,*])), $
              cnts_a14:  float(reform(cnts[14,*])), $
              cnts_a15:  float(reform(cnts[15,*])), $
              cnts:      float(cnts[*])}
     end
;     
;     ;;----------------------------------------------
;     ;;Product Full Sweep: Archive - 32Ex16A - '361'x
;     (apid_name eq '61') : begin
;       cnts = reform(cnts,16,32)
;       str = { $
;         time:      ccsds.time, $
;         seq_cntr:  ccsds.seq_cntr,  $
;         seq_group: ccsds.seq_group,  $
;         ndat:      n_elements(cnts), $
;         peak_bin:  peak_bin, $
;         log_flag:  log_flag, $
;         status_flag: status_flag,$
;         f_counter: f_counter,$
;         cnts_a00:  float(reform(cnts[ 0,*])), $
;         cnts_a01:  float(reform(cnts[ 1,*])), $
;         cnts_a02:  float(reform(cnts[ 2,*])), $
;         cnts_a03:  float(reform(cnts[ 3,*])), $
;         cnts_a04:  float(reform(cnts[ 4,*])), $
;         cnts_a05:  float(reform(cnts[ 5,*])), $
;         cnts_a06:  float(reform(cnts[ 6,*])), $
;         cnts_a07:  float(reform(cnts[ 7,*])), $
;         cnts_a08:  float(reform(cnts[ 8,*])), $
;         cnts_a09:  float(reform(cnts[ 9,*])), $
;         cnts_a10:  float(reform(cnts[10,*])), $
;         cnts_a11:  float(reform(cnts[11,*])), $
;         cnts_a12:  float(reform(cnts[12,*])), $
;         cnts_a13:  float(reform(cnts[13,*])), $
;         cnts_a14:  float(reform(cnts[14,*])), $
;         cnts_a15:  float(reform(cnts[15,*])), $
;         cnts:      float(reform(cnts,16*32))}
;     end

     ;;----------------------------------------------
     ;;Product Targeted Sweep: Archive - 16A - '362'x
     (apid_name eq '62') : begin
        str = { $
              time:      ccsds.time, $
              seq_cntr:  ccsds.seq_cntr,  $
              seq_group: ccsds.seq_group,  $
              ndat:      n_elements(cnts), $
              peak_bin:  peak_bin, $
              log_flag:  log_flag, $
              status_flag: status_flag,$
              f_counter: f_counter,$
              cnts:      float(cnts[*])}
     end



;     ;;--------------------------------------------------
;     ;;Product Targeted Sweep: Archive - 32Ex16A - '363'x
;     (apid_name eq '63') : begin
;       cnts = reform(cnts,16,32)
;       str = { $
;         time:ccsds.time, $
;         seq_cntr:ccsds.seq_cntr,  $
;         seq_group: ccsds.seq_group,  $
;         ndat: n_elements(cnts), $
;         peak_bin: peak_bin, $
;         log_flag: log_flag, $
;         status_flag: status_flag,$
;         f_counter: f_counter,$
;         cnts:      float(reform(cnts,32*16)), $
;         cnts_a00:  float(reform(cnts[ 0,*])), $
;         cnts_a01:  float(reform(cnts[ 1,*])), $
;         cnts_a02:  float(reform(cnts[ 2,*])), $
;         cnts_a03:  float(reform(cnts[ 3,*])), $
;         cnts_a04:  float(reform(cnts[ 4,*])), $
;         cnts_a05:  float(reform(cnts[ 5,*])), $
;         cnts_a06:  float(reform(cnts[ 6,*])), $
;         cnts_a07:  float(reform(cnts[ 7,*])), $
;         cnts_a08:  float(reform(cnts[ 8,*])), $
;         cnts_a09:  float(reform(cnts[ 9,*])), $
;         cnts_a10:  float(reform(cnts[10,*])), $
;         cnts_a11:  float(reform(cnts[11,*])), $
;         cnts_a12:  float(reform(cnts[12,*])), $
;         cnts_a13:  float(reform(cnts[13,*])), $
;         cnts_a14:  float(reform(cnts[14,*])), $
;         cnts_a15:  float(reform(cnts[15,*]))}
;     end

     ;;--------------------------------------------------
     ;;Product Targeted Sweep: Archive - 16Ax256S - '363'x
     (apid_name eq '63') : begin
        cnts = reform(cnts,16,256)
        str = { $
              time:ccsds.time, $
              seq_cntr:ccsds.seq_cntr,  $
              seq_group: ccsds.seq_group,  $
              ndat: n_elements(cnts), $
              peak_bin: peak_bin, $
              log_flag: log_flag, $
              status_flag: status_flag,$
              f_counter: f_counter,$
             ; cnts:      float(reform(cnts,256*16)), $
              cnts:      float(cnts[*]), $
              cnts_a00:  float(reform(cnts[ 0,*])), $
              cnts_a01:  float(reform(cnts[ 1,*])), $
              cnts_a02:  float(reform(cnts[ 2,*])), $
              cnts_a03:  float(reform(cnts[ 3,*])), $
              cnts_a04:  float(reform(cnts[ 4,*])), $
              cnts_a05:  float(reform(cnts[ 5,*])), $
              cnts_a06:  float(reform(cnts[ 6,*])), $
              cnts_a07:  float(reform(cnts[ 7,*])), $
              cnts_a08:  float(reform(cnts[ 8,*])), $
              cnts_a09:  float(reform(cnts[ 9,*])), $
              cnts_a10:  float(reform(cnts[10,*])), $
              cnts_a11:  float(reform(cnts[11,*])), $
              cnts_a12:  float(reform(cnts[12,*])), $
              cnts_a13:  float(reform(cnts[13,*])), $
              cnts_a14:  float(reform(cnts[14,*])), $
              cnts_a15:  float(reform(cnts[15,*]))}
     end
     
     
     ;;-----------------------------------------
     ;;Product Full Sweep: Survey - 16A - '364'x
     (apid_name eq '64') : begin
     ;dprint, ccsds.data[12]
     ;dprint, ccsds.smples_sumd
        str = { $
              time:        ccsds.time, $
              seq_cntr:    ccsds.seq_cntr,  $
              seq_group:   ccsds.seq_group,  $
              ndat:        n_elements(cnts), $
              peak_bin:    peak_bin, $
              log_flag:    log_flag, $
              status_flag: status_flag,$
              f_counter:   f_counter,$
              cnts:        float(cnts[*]),$
              rates:       float(cnts[*]) / float(ccsds.smples_sumd)}
     end
     
;     ;;---------------------------------------------
;     ;;Product Full Sweep: Survey - 32Ex16A - '365'x
;     (apid_name eq '65') : begin
;       cnts = reform(cnts,16,32)
;       str = { $
;              time:      ccsds.time, $
;              seq_cntr:  ccsds.seq_cntr,  $
;              seq_group: ccsds.seq_group,  $
;              ndat:      n_elements(cnts), $
;              peak_bin:  peak_bin, $
;              log_flag:  log_flag, $
;              status_flag: status_flag,$
;              f_counter: f_counter,$
;              cnts_a00:  float(reform(cnts[ 0,*])), $
;              cnts_a01:  float(reform(cnts[ 1,*])), $
;              cnts_a02:  float(reform(cnts[ 2,*])), $
;              cnts_a03:  float(reform(cnts[ 3,*])), $
;              cnts_a04:  float(reform(cnts[ 4,*])), $
;              cnts_a05:  float(reform(cnts[ 5,*])), $
;              cnts_a06:  float(reform(cnts[ 6,*])), $
;              cnts_a07:  float(reform(cnts[ 7,*])), $
;              cnts_a08:  float(reform(cnts[ 8,*])), $
;              cnts_a09:  float(reform(cnts[ 9,*])), $
;              cnts_a10:  float(reform(cnts[10,*])), $
;              cnts_a11:  float(reform(cnts[11,*])), $
;              cnts_a12:  float(reform(cnts[12,*])), $
;              cnts_a13:  float(reform(cnts[13,*])), $
;              cnts_a14:  float(reform(cnts[14,*])), $
;              cnts_a15:  float(reform(cnts[15,*])), $
;              cnts:      float(reform(cnts,16*32)), $
;              rates_a00: float(reform(cnts[ 0,*])) / float(ccsds.smples_sumd), $
;              rates_a01: float(reform(cnts[ 1,*])) / float(ccsds.smples_sumd), $
;              rates_a02: float(reform(cnts[ 2,*])) / float(ccsds.smples_sumd), $
;              rates_a03: float(reform(cnts[ 3,*])) / float(ccsds.smples_sumd), $
;              rates_a04: float(reform(cnts[ 4,*])) / float(ccsds.smples_sumd), $
;              rates_a05: float(reform(cnts[ 5,*])) / float(ccsds.smples_sumd), $
;              rates_a06: float(reform(cnts[ 6,*])) / float(ccsds.smples_sumd), $
;              rates_a07: float(reform(cnts[ 7,*])) / float(ccsds.smples_sumd), $
;              rates_a08: float(reform(cnts[ 8,*])) / float(ccsds.smples_sumd), $
;              rates_a09: float(reform(cnts[ 9,*])) / float(ccsds.smples_sumd), $
;              rates_a10: float(reform(cnts[10,*])) / float(ccsds.smples_sumd), $
;              rates_a11: float(reform(cnts[11,*])) / float(ccsds.smples_sumd), $
;              rates_a12: float(reform(cnts[12,*])) / float(ccsds.smples_sumd), $
;              rates_a13: float(reform(cnts[13,*])) / float(ccsds.smples_sumd), $
;              rates_a14: float(reform(cnts[14,*])) / float(ccsds.smples_sumd), $
;              rates_a15: float(reform(cnts[15,*])) / float(ccsds.smples_sumd), $
;              rates:     float(cnts) / float(ccsds.smples_sumd)}
;     end


     ;;---------------------------------------------
     ;;Product Full Sweep: Survey - 16Ax256S - '365'x
     (apid_name eq '65') : begin
       cnts = reform(cnts,16,256)
       str = { $
              time:      ccsds.time, $
              seq_cntr:  ccsds.seq_cntr,  $
              seq_group: ccsds.seq_group,  $
              ndat:      n_elements(cnts), $
              peak_bin:  peak_bin, $
              log_flag:  log_flag, $
              status_flag: status_flag,$
              f_counter: f_counter,$
              cnts_a00:  float(reform(cnts[ 0,*])), $
              cnts_a01:  float(reform(cnts[ 1,*])), $
              cnts_a02:  float(reform(cnts[ 2,*])), $
              cnts_a03:  float(reform(cnts[ 3,*])), $
              cnts_a04:  float(reform(cnts[ 4,*])), $
              cnts_a05:  float(reform(cnts[ 5,*])), $
              cnts_a06:  float(reform(cnts[ 6,*])), $
              cnts_a07:  float(reform(cnts[ 7,*])), $
              cnts_a08:  float(reform(cnts[ 8,*])), $
              cnts_a09:  float(reform(cnts[ 9,*])), $
              cnts_a10:  float(reform(cnts[10,*])), $
              cnts_a11:  float(reform(cnts[11,*])), $
              cnts_a12:  float(reform(cnts[12,*])), $
              cnts_a13:  float(reform(cnts[13,*])), $
              cnts_a14:  float(reform(cnts[14,*])), $
              cnts_a15:  float(reform(cnts[15,*])), $
              cnts:      float(cnts[*]), $
              rates_a00: float(reform(cnts[ 0,*])) / float(ccsds.smples_sumd), $
              rates_a01: float(reform(cnts[ 1,*])) / float(ccsds.smples_sumd), $
              rates_a02: float(reform(cnts[ 2,*])) / float(ccsds.smples_sumd), $
              rates_a03: float(reform(cnts[ 3,*])) / float(ccsds.smples_sumd), $
              rates_a04: float(reform(cnts[ 4,*])) / float(ccsds.smples_sumd), $
              rates_a05: float(reform(cnts[ 5,*])) / float(ccsds.smples_sumd), $
              rates_a06: float(reform(cnts[ 6,*])) / float(ccsds.smples_sumd), $
              rates_a07: float(reform(cnts[ 7,*])) / float(ccsds.smples_sumd), $
              rates_a08: float(reform(cnts[ 8,*])) / float(ccsds.smples_sumd), $
              rates_a09: float(reform(cnts[ 9,*])) / float(ccsds.smples_sumd), $
              rates_a10: float(reform(cnts[10,*])) / float(ccsds.smples_sumd), $
              rates_a11: float(reform(cnts[11,*])) / float(ccsds.smples_sumd), $
              rates_a12: float(reform(cnts[12,*])) / float(ccsds.smples_sumd), $
              rates_a13: float(reform(cnts[13,*])) / float(ccsds.smples_sumd), $
              rates_a14: float(reform(cnts[14,*])) / float(ccsds.smples_sumd), $
              rates_a15: float(reform(cnts[15,*])) / float(ccsds.smples_sumd), $
              rates:     float(cnts[*]) / float(ccsds.smples_sumd)}
     end

     ;;---------------------------------------------
     ;;Product Targeted Sweep: Survey - 16A - '366'x
     (apid_name eq '66') : begin
       str = { $
         time:      ccsds.time, $
         seq_cntr:  ccsds.seq_cntr,  $
         seq_group: ccsds.seq_group,  $
         ndat:      n_elements(cnts), $
         peak_bin:  peak_bin, $
         log_flag:  log_flag, $
         status_flag: status_flag,$
         f_counter: f_counter,$
         cnts:      float(cnts[*]),$
         rates:     float(cnts[*]) / float(ccsds.smples_sumd)}
     end


     ;-------------------------------------------------
     ;Product Targeted Sweep: Survey - 16Ax256S - '367'x
          (apid_name eq '67') : begin
            cnts = reform(cnts,16,256)
            str = { $
              time:ccsds.time, $
              seq_cntr:ccsds.seq_cntr,  $
              seq_group: ccsds.seq_group,  $
              ndat: n_elements(cnts), $
              peak_bin: peak_bin, $
              log_flag: log_flag, $
              status_flag: status_flag,$
              f_counter: f_counter,$
              cnts_a00:  float(reform(cnts[ 0,*])), $
              cnts_a01:  float(reform(cnts[ 1,*])), $
              cnts_a02:  float(reform(cnts[ 2,*])), $
              cnts_a03:  float(reform(cnts[ 3,*])), $
              cnts_a04:  float(reform(cnts[ 4,*])), $
              cnts_a05:  float(reform(cnts[ 5,*])), $
              cnts_a06:  float(reform(cnts[ 6,*])), $
              cnts_a07:  float(reform(cnts[ 7,*])), $
              cnts_a08:  float(reform(cnts[ 8,*])), $
              cnts_a09:  float(reform(cnts[ 9,*])), $
              cnts_a10:  float(reform(cnts[10,*])), $
              cnts_a11:  float(reform(cnts[11,*])), $
              cnts_a12:  float(reform(cnts[12,*])), $
              cnts_a13:  float(reform(cnts[13,*])), $
              cnts_a14:  float(reform(cnts[14,*])), $
              cnts_a15:  float(reform(cnts[15,*])), $
              cnts:      float(cnts[*]),$
              rates_a00: float(reform(cnts[ 0,*])) / float(ccsds.smples_sumd), $
              rates_a01: float(reform(cnts[ 1,*])) / float(ccsds.smples_sumd), $
              rates_a02: float(reform(cnts[ 2,*])) / float(ccsds.smples_sumd), $
              rates_a03: float(reform(cnts[ 3,*])) / float(ccsds.smples_sumd), $
              rates_a04: float(reform(cnts[ 4,*])) / float(ccsds.smples_sumd), $
              rates_a05: float(reform(cnts[ 5,*])) / float(ccsds.smples_sumd), $
              rates_a06: float(reform(cnts[ 6,*])) / float(ccsds.smples_sumd), $
              rates_a07: float(reform(cnts[ 7,*])) / float(ccsds.smples_sumd), $
              rates_a08: float(reform(cnts[ 8,*])) / float(ccsds.smples_sumd), $
              rates_a09: float(reform(cnts[ 9,*])) / float(ccsds.smples_sumd), $
              rates_a10: float(reform(cnts[10,*])) / float(ccsds.smples_sumd), $
              rates_a11: float(reform(cnts[11,*])) / float(ccsds.smples_sumd), $
              rates_a12: float(reform(cnts[12,*])) / float(ccsds.smples_sumd), $
              rates_a13: float(reform(cnts[13,*])) / float(ccsds.smples_sumd), $
              rates_a14: float(reform(cnts[14,*])) / float(ccsds.smples_sumd), $
              rates_a15: float(reform(cnts[15,*])) / float(ccsds.smples_sumd), $
              rates:     float(cnts[*]) / float(ccsds.smples_sumd)}
          end
     ;;-------------------------------------------------
     ;;Product Targeted Sweep: Survey - 32Ex16A - '367'x
;     (apid_name eq '67') : begin
;       cnts = reform(cnts,16,32)
;       str = { $
;         time:ccsds.time, $
;         seq_cntr:ccsds.seq_cntr,  $
;         seq_group: ccsds.seq_group,  $
;         ndat: n_elements(cnts), $
;         peak_bin: peak_bin, $
;         log_flag: log_flag, $
;         status_flag: status_flag,$
;         f_counter: f_counter,$
;         cnts_a00:  float(reform(cnts[ 0,*])), $
;         cnts_a01:  float(reform(cnts[ 1,*])), $
;         cnts_a02:  float(reform(cnts[ 2,*])), $
;         cnts_a03:  float(reform(cnts[ 3,*])), $
;         cnts_a04:  float(reform(cnts[ 4,*])), $
;         cnts_a05:  float(reform(cnts[ 5,*])), $
;         cnts_a06:  float(reform(cnts[ 6,*])), $
;         cnts_a07:  float(reform(cnts[ 7,*])), $
;         cnts_a08:  float(reform(cnts[ 8,*])), $
;         cnts_a09:  float(reform(cnts[ 9,*])), $
;         cnts_a10:  float(reform(cnts[10,*])), $
;         cnts_a11:  float(reform(cnts[11,*])), $
;         cnts_a12:  float(reform(cnts[12,*])), $
;         cnts_a13:  float(reform(cnts[13,*])), $
;         cnts_a14:  float(reform(cnts[14,*])), $
;         cnts_a15:  float(reform(cnts[15,*])), $
;         cnts:      float(cnts[*]),$
;         rates_a00: float(reform(cnts[ 0,*])) / float(ccsds.smples_sumd), $
;         rates_a01: float(reform(cnts[ 1,*])) / float(ccsds.smples_sumd), $
;         rates_a02: float(reform(cnts[ 2,*])) / float(ccsds.smples_sumd), $
;         rates_a03: float(reform(cnts[ 3,*])) / float(ccsds.smples_sumd), $
;         rates_a04: float(reform(cnts[ 4,*])) / float(ccsds.smples_sumd), $
;         rates_a05: float(reform(cnts[ 5,*])) / float(ccsds.smples_sumd), $
;         rates_a06: float(reform(cnts[ 6,*])) / float(ccsds.smples_sumd), $
;         rates_a07: float(reform(cnts[ 7,*])) / float(ccsds.smples_sumd), $
;         rates_a08: float(reform(cnts[ 8,*])) / float(ccsds.smples_sumd), $
;         rates_a09: float(reform(cnts[ 9,*])) / float(ccsds.smples_sumd), $
;         rates_a10: float(reform(cnts[10,*])) / float(ccsds.smples_sumd), $
;         rates_a11: float(reform(cnts[11,*])) / float(ccsds.smples_sumd), $
;         rates_a12: float(reform(cnts[12,*])) / float(ccsds.smples_sumd), $
;         rates_a13: float(reform(cnts[13,*])) / float(ccsds.smples_sumd), $
;         rates_a14: float(reform(cnts[14,*])) / float(ccsds.smples_sumd), $
;         rates_a15: float(reform(cnts[15,*])) / float(ccsds.smples_sumd), $
;         rates:     float(cnts) / float(ccsds.smples_sumd)}
;     end
     
     else: print, data_size, ' ', apid_name
  endcase


  return, str


end
