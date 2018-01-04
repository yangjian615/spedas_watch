;+
; PROCEDURE:
;       kgy_spice_kernels
; PURPOSE:
;       
; CALLING SEQUENCE:
;       kk = kgy_spice_kernels(/load)
; INPUTS:
;       
; KEYWORDS:
;       
; CREATED BY:
;       Yuki Harada on 2016-03-04
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2017-11-21 12:02:46 -0800 (Tue, 21 Nov 2017) $
; $LastChangedRevision: 24333 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kaguya/general/spice/kgy_spice_kernels.pro $
;-

function kgy_spice_kernels, trange=trange, source=source, clear=clear, load=load, last_version=last_version

if spice_test() eq 0 then return,''
syst0 = systime(/sec)

if size(last_version,/type) eq 0 then last_version=1

tb = scope_traceback(/structure)
this_dir = file_dirname(tb[n_elements(tb)-1].filename)+'/' ; the directory this file resides in (determined at run time)

darts = spice_file_source(remote_data_dir='http://darts.jaxa.jp/pub/spice/',last_version=last_version)

names = ['STD','CK','FK','IK','PCK','SCLK','SPK']

kernels = ''
for in=0,n_elements(names)-1 do begin
   case strupcase(names[in]) of
      'STD': begin              ;- standard kernels
         append_array,kernels,spice_standard_kernels()
         ;;; incl. naif????.tls, pck?????.tpc, de???.bsp
      end
      'CK': begin               ;- S/C attitude
         tr = timerange(trange) ;- spd_download doesn't have trange capability yet...
;         append_array,kernels,file_retrieve('SELENE/kernels/ck/SEL_M_YYYYMM_D_V??.BC',_extra=darts,trange=tr,/monthly)
;;          The attitude is sampled at frequency of 2 seconds.
;;          The telemetry includes the attitude data as format of
;;          "IEEE Standard for Floating-Point Arithmetic"
;;          (IEEE 754) using 64 bits. 
        append_array,kernels,file_retrieve('SELENE/kernels/ck/SEL_M_YYYYMM_S_V??.BC',_extra=darts,trange=tr,/monthly)
;;         In this file, the attitude is sampled at frequency of
;;         8 seconds. The precision in the s/c telemetry uses
;;         a single-precision (32 bits). The number of time gaps
;;         is less than that of "SEL_M_ALL_D_V02.BC".
      end
      'FK': begin               ;- frame
         append_array,kernels,spd_download(remote_file='SELENE/kernels/fk/SEL_V??.TF',_extra=darts,/last_version)
         append_array,kernels,spd_download(remote_file='SELENE/kernels/fk/moon_??????.tf',_extra=darts)
         append_array,kernels,spd_download(remote_file='SELENE/kernels/fk/moon_assoc_me.tf',_extra=darts)
         append_array,kernels,this_dir+'kernels/fk/GSE_080125.tf'
         append_array,kernels,this_dir+'kernels/fk/SSE_080125.tf'
      end
      'IK': begin               ;- instrument FOV
         ;;; included in FK
      end
      'PCK': begin              ;- body size, shape, and orientation
         append_array,kernels,spd_download(remote_file='SELENE/kernels/pck/moon_pa_de421_1900-2050.bpc',_extra=darts)
         append_array,kernels,spd_download(remote_file='SELENE/kernels/pck/pck00010.tpc',_extra=darts)
      end
      'SCLK': begin             ;- S/C clock
         append_array,kernels,spd_download(remote_file='SELENE/kernels/sclk/SEL_M_V??.TSC',_extra=darts)
      end
      'SPK': begin              ;- S/C position
;         append_array,kernels,spd_download(remote_file='SELENE/kernels/spk/SEL_M_071020_081226_SGMI_05.BSP',_extra=darts)
         append_array,kernels,spd_download(remote_file='SELENE/kernels/spk/SEL_M_071020_090610_SGMH_02.BSP',_extra=darts) ;- incl. gaps
         append_array,kernels,spd_download(remote_file='SELENE/kernels/spk/de421.bsp',_extra=darts) ;- used for SEL_M_071020_090610_SGMH_02.BSP
      end
   endcase
endfor


if keyword_set(clear) then cspice_kclear
if keyword_set(load) then spice_kernel_load,kernels

dprint,dlevel=2,verbose=verbose,'Time to retrieve SPICE kernels: '+strtrim(systime(1)-syst0,2)+ ' seconds'
return,kernels


end
