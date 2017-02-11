;+
;This program takes a variable and sets zero values to the minimum
;nonzero value not NaN's though. Hacked from
;thm_spec_lim4overplot.pro, to account for problems in solar wind mode
;for probes B and C where there are short intervals with much larger
;energy ranges, which make for ugly plotting. In this case, if the
;value for ymin or ymax are present for less than 1 hour total,
;(actually 1/24 of the total number of time intervals) then ignore
;those values.
Pro thm_esa_lim4overplot, var, zmin = zmin, zmax = zmax, zlog = zlog, $
                          ymin = ymin, ymax = ymax, ylog = ylog, $
                          overwrite = overwrite, _extra = _extra
;Version:
; $LastChangedBy: jimm $
; $LastChangedDate: 2017-02-10 12:48:36 -0800 (Fri, 10 Feb 2017) $
; $LastChangedRevision: 22755 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/common/thm_esa_lim4overplot.pro $
;-
  If(keyword_set(zmin)) Then zmin0 = zmin Else zmin0 = 0
  If(keyword_set(zmax)) Then zmax0 = zmax Else zmax0 = 0
  If(keyword_set(zlog)) Then zlog0 = zlog Else zlog0 = 0
  If(keyword_set(ymin)) Then ymin0 = ymin Else ymin0 = 0
  If(keyword_set(ymax)) Then ymax0 = ymax Else ymax0 = 0
  If(keyword_set(ylog)) Then ylog0 = ylog Else ylog0 = 0

  zminv = zmin0 & zmaxv = zmax0
  yminv = ymin0 & ymaxv = ymax0
  get_data, var, data = d, dlim = dl, lim = al
  If(size(d, /type) Eq 8) Then Begin
    vlv = where(finite(d.y) And (d.y Ne 0), nvlv)
    If(nvlv Gt 0) Then Begin
       If(zminv Eq 0) Then zminv = min(d.y[vlv])
       If(zmaxv Eq 0) Then zmaxv = max(d.y[vlv])
       y0 = where(d.y Eq 0, ny0)
       If(ny0 Gt 0) Then Begin
          d.y[y0] = zminv
       Endif
    Endif
    If(tag_exist(d, 'v')) Then Begin
       If(yminv Eq 0) Then Begin
          yminv = min(d.v)
          ;test for not many times at these
          ;values, only do this once, but have
          ;some margin
          ntimes = float(n_elements(d.x))
          ymin_all = min(d.v, dimension =2)
          ss_yminv = where(ymin_all Le 2*yminv, nss_yminv)
          frac_ymin = float(nss_yminv)/ntimes
          If(frac_ymin Lt 1.0/24.0) Then Begin
             ss_not_yminv = where(ymin_all Gt 2.0*yminv)
             yminv = min(ymin_all[ss_not_yminv])
          Endif
       Endif
       If(ymaxv Eq 0) Then Begin
          ymaxv = max(d.v)
          ymax_all = max(d.v, dimension =2)
          ss_ymaxv = where(ymax_all Ge ymaxv/2.0, nss_ymaxv)
          frac_ymax = float(nss_ymaxv)/ntimes
          If(frac_ymax Lt 1.0/24.0) Then Begin
             ss_not_ymaxv = where(ymax_all Lt ymaxv/2.0)
             ymaxv = max(ymax_all[ss_not_ymaxv])
          Endif
       Endif
    Endif
  Endif

  If(keyword_set(overwrite)) Then varnew = var $
  Else varnew = var+'_limited'
  store_data, varnew, data = d, dlim = dl, lim = al
  zlim, varnew, zminv, zmaxv, zlog0
  ylim, varnew, yminv, ymaxv, ylog0
  options, varnew, 'ystyle', 1
  Return
End

