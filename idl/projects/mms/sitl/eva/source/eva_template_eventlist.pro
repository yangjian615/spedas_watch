; read_ascii template for eventlist files
Function eva_template_eventlist
  anan = fltarr(1) & anan[0] = 'NaN'
  ppp = {COMMENTSYMBOL:';', $
         DATASTART:0, $
         DELIMITER:',', $
         FIELDCOUNT:4, $
         FIELDGROUPS:[0L,1L,2L,3L], $
         FIELDLOCATIONS:[0L,20L,43L,50L], $
         FIELDNAMES:['start_time','end_time','flag','type'], $
         FIELDTYPES:[7L,7L,3L,7L], $
         MISSINGVALUE:anan[0], $
         VERSION:1.00000 $
        }
  return, ppp
End