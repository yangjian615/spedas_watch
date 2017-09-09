;+
; Function:
;     mms_feeps_active_eyes
;
; Purpose:
;    this function returns the FEEPS active eyes,
;    based on date/probe/species/rate
;
; Notes:
; 
; From Drew Turner, 9/7/2017, srvy mode:
; 
; - before 16 August 2017:
;   electron sensors = ['3', '4', '5', '11', '12'] 
;   ion sensors = ['6', '7', '8']
; 
; - after 16 August 2017:
;   MMS1
;   Top Eyes: 3, 5, 6, 7, 8, 9, 10, 12
;   Bot Eyes: 2, 4, 5, 6, 7, 8, 9, 10
;
;   MMS2
;   Top Eyes: 1, 2, 3, 5, 6, 8, 10, 11
;   Bot Eyes: 1, 4, 5, 6, 7, 8, 9, 11
;
;   MMS3
;   Top Eyes: 3, 5, 6, 7, 8, 9, 10, 12
;   Bot Eyes: 1, 2, 3, 6, 7, 8, 9, 10
;
;   MMS4
;   Top Eyes: 3, 4, 5, 6, 8, 9, 10, 11
;   Bot Eyes: 3, 5, 6, 7, 8, 9, 10, 12
;   
;   
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-09-08 14:59:38 -0700 (Fri, 08 Sep 2017) $
;$LastChangedRevision: 23939 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/feeps/mms_feeps_active_eyes.pro $
;-

function mms_feeps_active_eyes, trange, probe, data_rate, species, level
  if level eq 'sitl' && species eq 'electron' then return, hash('top', [5, 11, 12], 'bottom', [])
  
  ; handle burst mode first
  if data_rate eq 'brst' and species eq 'electron' then return, hash('top', [1, 2, 3, 4, 5, 9, 10, 11, 12], 'bottom', [1, 2, 3, 4, 5, 9, 10, 11, 12])
  if data_rate eq 'brst' and species eq 'ion' then return, hash('top', [6, 7, 8], 'bottom', [6, 7, 8])
  
  ; old eyes, srvy mode, prior to 16 August 2017
  if species eq 'electron' then sensors = hash('top', [3, 4, 5, 11, 12], 'bottom', [3, 4, 5, 11, 12]) else sensors = hash('top', [6, 7, 8], 'bottom', [6, 7, 8])
  
  ; srvy mode, after 16 August 2017
  if time_double(trange[0]) ge time_double('2017-08-16') and data_rate eq 'srvy' then begin
    active_table = hash()
    active_table['1-electron'] = hash('top', [3, 5, 9, 10, 12], 'bottom', [2, 4, 5, 9, 10])
    active_table['1-ion'] = hash('top', [6, 7, 8], 'bottom', [6, 7, 8])
    
    active_table['2-electron'] = hash('top', [1, 2, 3, 5, 10, 11], 'bottom', [1, 4, 5, 9, 11])
    active_table['2-ion'] = hash('top', [6, 8], 'bottom', [6, 7, 8])
    
    active_table['3-electron'] = hash('top', [3, 5, 9, 10, 12], 'bottom', [1, 2, 3, 9, 10])
    active_table['3-ion'] = hash('top', [6, 7, 8], 'bottom', [6, 7, 8])
    
    active_table['4-electron'] = hash('top', [3, 4, 5, 9, 10, 11], 'bottom', [3, 5, 9, 10, 12])
    active_table['4-ion'] = hash('top', [6, 8], 'bottom', [6, 7, 8])
    sensors = active_table[strcompress(string(probe), /rem)+'-'+species]
  endif
  return, sensors
end