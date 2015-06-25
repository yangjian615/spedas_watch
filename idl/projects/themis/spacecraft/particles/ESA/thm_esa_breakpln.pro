;+
; NAME:
;	lfit
; CALLING SEQUENCE:
;	Lfit,y,s2,x,ax
; PURPOSE:
;	This should do a linear least squares fit, see 
;	Numerical recipies, eqs. 14.2.15 to 14.2.18, 
; INPUT:
;	y=obs data, 
;	s2=unc. squared
;	x=energies, 
; OUTPUT:
;	ax, where f=a(0)+a(1)*x is fit to y
; HISTORY:
;	Writtrn Spring '92 by JMCT
;-
PRO Lfit, y, s2, x, ax
   
   s1 = sqrt(s2)
   s = total(1/s2)                ;sum of weights
   sx = total(x/s2)               ;sum of x*weight	
   sy = total(y/s2)               ;sum of y*weight
   
   t = (x-sx/s)/s1
   stt = total(t^2)
   
   a2 = total(t*y/s1)/stt         ;slope
   a1 = (sy-sx*a2)/s		;intercept
   
   ax = [a1, a2]

   RETURN
END

;+
; NAME:
;	Break
; PURPOSE:
;	Obtains a P.L. with a break in it
; CALLING SEQUENCE:
;	Break,y,s2,x,nch,ax,fx
; INPUT:
;	y=obs data, 
;	s2=unc. squared
;	x=energies, 
;	nch=no. of channels
; OUTPUT:
;	fx=ax(0)+ax(1)*x Below ebr, 
;	fx=ax(2)+ax(3)*x above, 
; HISTORY:
;	Spring,' 92 JMcT
;       Changed to break_pl, 9-nov-2001
;-
PRO Break_pl, y, s2, x, nch, ax, fx, chmn = chmn
   
   chmn = 1.0e20
   nch1 = nch-1
  
   FOR n = 1, nch-3 DO BEGIN	;at least 2 points below or above ebr
      n1 = n+1
      y1 = y(0:n)                 ;below break energy
      x1 = x(0:n)
      s21 = s2(0:n)
      lfit, y1, s21, x1, ax1	;fit a power law
      
      y2 = y(n1:nch1)             ;above break energy
      x2 = x(n1:nch1)
      s22 = s2(n1:nch1)
      lfit, y2, s22, x2, ax2	;fit a power law
      
      dgamma = -ax2(1)+ax1(1)
      ebr = (ax2(0)-ax1(0))/dgamma ;the break energy
      ;will be restricted 
      ;to x(n)<ebr<x(n1)
      IF(ebr LT x(n)) THEN ebr = x(n) ELSE $ ;reset ebr
        IF(ebr GT x(n1)) THEN ebr = x(n1) 
      
      ax2(0) = ax1(0)+dgamma*ebr	;reset k2
      ys1 = ax1(0)+ax1(1)*x1      ;values of y from fit
      ys2 = ax2(0)+ax2(1)*x2
      
      ys = [ys1, ys2]		;get chi^2
      ch2 = total((ys-y)^2/s2)
      IF (ch2 LT chmn) THEN BEGIN
         chmn = ch2
         ax = [ax1, ax2]           ;[ax1(0),ax1(1),ax2(0),ax2(1)]
         ;[k1,gm1,k2,gm2]
         fx = ys
      ENDIF
   ENDFOR

   RETURN
END

;+
; NAME:
;	Break_pln
; PURPOSE:
;	Obtains a P.L. with a N breaks in it, calls itself
;	recursively, unti it hits break_pl, which is a PL with one
;	break
; CALLING SEQUENCE:
;	Break_pln,y,s2,x,nch,ax,fx,n
; INPUT:
;	y=obs data, 
;	s2=unc. squared
;	x=energies, 
;	nch=no. of channels
;       n-number of breaks
; OUTPUT:
;	fx=ax(0)+ax(1)*x, e<eb1
;	fx=ax(2)+ax(3)*x, eb1<e<eb2
;	fx=ax(4)+ax(5)*x, e>eb2, etc....
; HISTORY:
;	Spring,' 92 JMcT
;       Changed to break_pl2, 9-nov-2001
;       Generalized from break_pl2.pro, 6-Apr-2007, jmm
;-
Pro Break_pln, y, s2, x, nch, ax, fx, npl, chmn = chmn
   
   chmn = 1.0e20
   nch1 = nch-1
;fit a single pl. and a pl with n_breaks in it
   
   For n = 1, nch-(npl+1)*2 Do Begin ;at least 2 pts below eb1, and enough above
     n1 = n+1
     y1 = y[0:n]                ;below break energy
     x1 = x[0:n]
     s21 = s2[0:n]
     lfit, y1, s21, x1, ax1	;fit a power law
      
     y2 = y[n1:nch1]            ;above break energy
     x2 = x[n1:nch1]
     s22 = s2[n1:nch1]
     nc2 = n_elements(y2)
     If(npl Eq 2) Then Begin
       break_pl, y2, s22, x2, nc2, ax2, fx2
     Endif Else Begin
       break_pln, y2, s22, x2, nc2, ax2, fx2, npl-1
     Endelse

     dg1 = -ax2[1]+ax1[1]
     eb1 = (ax2[0]-ax1[0])/dg1
;the break energy will be restricted to x(n)<ebr<x(n1)
     If(eb1 Lt x[n]) Then eb1 = x[n] $
     Else If(eb1 Gt x[n1]) Then eb1 = x[n1] ;reset ebr
      
     ax2o = ax2[0]
     ax2[0] = ax1[0]+dg1*eb1    ;reset k2
     ax2[2] = ax2[2]+(ax2[0]-ax2o) ;reset k3, then
      
     ys1 = ax1[0]+ax1[1]*x1     ;values of y from fit
     ys2 = fx2
      
     ys = [ys1, ys2]		;get chi^2
     ch2 = total((ys-y)^2/s2)
     If (ch2 Lt chmn) Then Begin
       chmn = ch2
       ax = [ax1, ax2]    ;[ax1(0),ax1(1),ax2(0),ax2(1),ax2(2),ax2(3)...]
                                ;[k1,-gm1,k2,-gm2,k3,-gm3...]
       fx = ys
     Endif
   Endfor
   
   Return
End

;+
;NAME:
; thm_esa_breakpln
;PURPOSE:
; Uses break_pln to test for multiple breaks, peaks, etc...
;CALLING SEQUENCE:
; otp = thm_esa_test4breaks(dist, energy)
;INPUT:
; dist = energy distribution
; energy = energy
;OUTPUT:
; otp = Undetermined, but will include an n_elements PL fit
;-
Function thm_esa_breakpln, dist, energy

  otp = -1
  If(keyword_set(nfactor)) Then nf = nfactor Else nf = 3

  ok = where(finite(dist) And (dist Gt 0), nok)
  If(nok Eq 0) Then Return, otp

  sy2 = (sqrt(dist[ok])/dist[ok])^2
  y0 = alog(dist[ok])
  x0 = alog(energy[ok])

  If(nok Le 6) Then Begin       ;need enough data points
     nbr = 0
     fx = y0
     ax = 0
  Endif Else Begin
     nbr = 2
     break_pln, y0, sy2, x0, nok, ax, fx, nbr, chmn = chmn
     dof = nok-n_elements(ax)
;     If(nok Gt 8) Then Begin    ;try 3 breaks
;        break_pln, y0, sy2, x0, nok, ax3, fx3, 3, chmn = chmn3
;        dof3 = nok-n_elements(ax3)
;        If(chmn3/dof3 Lt chmn/dof) Then Begin
;           fx = fx3
;           ax = ax3
;           nbr = 3
;        Endif
;     Endif
  Endelse

  otp = {fx:exp(fx), nbr:nbr, x:exp(x0)}
  Return, otp
End


  


  
