;;+
;PROCEDURE:   mvn_lpw_pkt_plus_sym
;PURPOSE:
;  Make a resizeble dot/circle/square.
;  Originally created by Bob Ergun for the FAST mission
;
;USAGE:
;  mvn_lpw_pkt_plus_sym,output,lpw_const
;
;INPUTS:
;       z:         radious of the dot/cirvle/square
;
;KEYWORDS:
;      square:
;      fill:    
;
;CREATED BY:   Bob Ergun 
;FILE: mvn_lpw_pkt_plus_sym.pro
;VERSION:   1.0
;LAST MODIFICATION:   2000?
;-
 
 pro mvn_lpw_pkt_plus_sym, z, square=square, fill=fill

if not keyword_set(z) then z=1
IF keyword_set(square) then BEGIN
    x=[-z,z,z,-z,-z]
    y=[z, z,-z,-z,z]
    usersym, x, y, fill=fill
ENDIF ELSE BEGIN
    x1 = findgen(21)*!dpi/10
    y1 = z*sin(x1)
    x1 = z*cos(x1)
    usersym, x1, y1, fill=fill
ENDELSE

end
 ;*******************************************************************
 
 