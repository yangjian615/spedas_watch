; read ascii template for configure file
Function eva_template_config

;  anan = fltarr(1) & anan[0] = 'NaN'
;  ppp = {VERSION:1.00000, $
;         DATASTART:1, $
;         DELIMITER:'=', $
;         MISSINGVALUE:anan[0], $
;         COMMENTSYMBOL:'', $
;         FIELDCOUNT:2, $
;         FIELDTYPES:[7l, 7l], $
;         FIELDNAMES:['FIELD1','FIELD2'], $
;         FIELDLOCATIONS:[0l, 16l], $
;         FIELDGROUPS:[0l,1l]$
;        }

  anan = fltarr(1) & anan[0] = 'NaN'
  ppp = {VERSION:1.00000, $
    DATASTART:3L, $
    DELIMITER:61b, $
    MISSINGVALUE:anan[0], $
    COMMENTSYMBOL:';', $
    FIELDCOUNT:2, $
    FIELDTYPES:[7L, 7L], $
    FIELDNAMES:['FIELD1', 'FIELD2'], $
    FIELDLOCATIONS:[0L, 15L], $
    FIELDGROUPS:[0L, 1L]}
  return, ppp
End
