

;+
;Purpose:
;  Helper function to return structure describing 
;  the available data types for AFG or DFG
;-
function mms_load_options_fgm

    compile_opt idl2, hidden
    
s = { $
      brst: { $
              l1a: [ '' ], $
              l1b: [ '' ] $
            }, $
      fast: { $
              l1a: [ '' ] $
            }, $
      slow: { $
              l1a: [ '' ] $
            }, $
      srvy: { $
              l1a: [ '' ], $
              ql:  [ '' ] $
            } $
    }

return, s

end


;+
;Purpose:
;  Helper function to return structure describing 
;  the available data types for EIS
;-
function mms_load_options_eis

    compile_opt idl2, hidden
    
s = { $
      brst: { $
              l1a: [ $
                     'extof', $
                     'phxtof' $
                   ], $
              l1b: [ $
                     'extof', $
                     'phxtof' $
                   ] $
            }, $
      srvy: { $
              l1a: [ $
                     'electronenergy', $
                     'extof', $
                     'partenergy', $
                     'phxtof' $
                   ], $
              l1b: [ $
                     'electronenergy', $
                     'extof', $
                     'partenergy', $
                     'phxtof' $
                   ] $
            } $
    }

return, s

end


;+
;Purpose:
;  Helper function to return structure describing 
;  the available data types for FEEPS
;-
function mms_load_options_feeps

    compile_opt idl2, hidden
    
s = { $
      brst: { $
              l1a: [ $
                     'electron-bottom', $
                     'electron-top', $
                     'ion-bottom', $
                     'ion-top' $
                   ] $
            }, $
      srvy: { $
              l1a: [ $
                     'electron-bottom', $
                     'electron-top', $
                     'ion-bottom', $
                     'ion-top' $
                   ], $
              l1b: [ $
                     'electron', $
                     'ion' $
                   ] $
            } $
    }

return, s

end


;+
;Purpose:
;  Helper function to return structure describing 
;  the available data types for FPI
;-
function mms_load_options_fpi

    compile_opt idl2, hidden
    
s = { $
      fast: { $
              sitl: [ '' ] $
            } $
    }

return, s

end


;+
;Purpose:
;  Helper function to return structure describing 
;  the available data types for HPCA
;-
function mms_load_options_hpca

    compile_opt idl2, hidden
    
s = { $
      brst: { $
              l1b: [ $
                     'ion', $
                     'logicals', $
                     'moments' $
                   ] $
            }, $
      srvy: { $
              l1b: [ $
                     'ion', $
                     'logicals', $
                     'moments' $
                   ], $
              sitl:[ $
                     'ion', $
                     'moments' $
                   ] $
            } $
    }

return, s

end


;+
;Purpose:
;  Helper function to return structure describing 
;  the available data types for SCM
;-
function mms_load_options_scm

    compile_opt idl2, hidden
    
;use placeholder where datatype will go
s = { $
      brst: { $
              l1a: [ $
                     'scb', $
                     'schb' $
                   ] $
            }, $
      fast: { $
              l1a: [ $
                     'scf' $
                   ], $
              l1b: [ $
                     'scf' $
                   ] $
            }, $
      slow: { $
              l1a: [ $
                     'scs' $
                   ] $
            }, $
      srvy: { $
              l1a: [ $
                     'cal', $
                     'scm' $
                   ] $
            } $
    }

return, s

end



;+
;Purpose:
;  Extracts valid rate/level/datatype based on input.
;  If an input is specified then only subsets of that input are checked.
;  If an input is not specified then all possible matches are used.
;  
;    e.g.  -If rate is specified then only levels and datatypes for 
;           that rate are retuned.
;          -If nothing is specified then all rates/levels/datatypes
;           are returned.
;          -If all three are specified then then the output will
;           be identical to the input (if the input is valid).
;-
pro mms_load_options_getvalid, $
             s, $ 
    
             rate_in=rate, $
             level_in=level, $
             datatype_in=datatype, $

             rates_out=rates_out, $
             levels_out=levels_out, $
             datatypes_out=datatypes_out

    compile_opt idl2, hidden


;get all rates for this instrument
valid_rates = tag_names(s)

;loop over rates
for i=0, n_elements(valid_rates)-1 do begin

  ;if the input is specified and doesn't match then ignore
  if is_string(rate) then begin
    if valid_rates[i] ne strupcase(rate) then continue
  endif

  ;if input matched or wasn't specified then add this to the output list
  rates_out = array_concat(valid_rates[i], rates_out)

  ;get all levels for this rate
  valid_levels = tag_names(s.(i)) 

  ;loop over levels
  for j=0, n_elements(valid_levels)-1 do begin

    ;if the input is specified but doesn't match then ignore
    if is_string(level) then begin
      if valid_levels[j] ne strupcase(level) then continue
    endif
    
    ;if input matched or wasn't specified then add this to the output list
    levels_out = array_concat(valid_levels[j], levels_out)

    ;get datatypes for this rate/level
    valid_datatypes = s.(i).(j)

    ;if input is specified and matches then add that entry
    ;otherwise add all entries
    if is_string(datatype) then begin
      idx = where(valid_datatypes eq strupcase(datatype), n)
      if n ne 0 then begin
        datatypes_out = array_concat(valid_datatypes[idx], datatypes_out)
      endif
    endif else begin
      datatypes_out = array_concat(valid_datatypes, datatypes_out)
    endelse

  endfor

endfor


end



;+
;Procedure:
;  mms_load_options
;
;Purpose:
;  Provides information on valid data rates, levels, and datatypes
;  for MMS science instruments.
;
;  Valid load options for a specified instrument will be returned 
;  via a corresponding keyword.

;  Each output keyword may be used as an input to narrow the results
;  the the contingent options.
;
;Calling Sequence:
;  mms_load_options, instrument=instrument
;                    [,rate=rate] [,level=level], [,datatype=datatype]
;                    [valid=valid]
;
;Example Usage:
;
;
;Input:
;  instrument:  (string) Instrument designation, e.g. 'afg'
;  rate:  (string) Data rate, e.g. 'fast', 'srvy'
;  level:  (string) Data processing level, e.g. 'l1b', 'ql' 
;  datatype:  (string) Data type, e.g. 'moments'
;
;Output:
;  rate:  If not used as an input this will contain all valid 
;         rates for the instrument.
;  level:  If not used as an input this will contain all valid
;          levels, given any specified rate.
;  datatype:  If not used as an input this will contain all valid
;             datatypes, given any specified rate and level. 
;  valid:  1 if valid outputs were found, 0 otherwise
;
;Notes:
;  -
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-08-10 16:58:14 -0700 (Mon, 10 Aug 2015) $
;$LastChangedRevision: 18449 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/mms_load_options.pro $
;-
pro mms_load_options, $
             instrument, $
             
             rate=rate, $
             level=level, $
             datatype=datatype, $
             
             valid=valid

             
    compile_opt idl2, hidden


valid = 0

if ~is_string(instrument) then begin
  dprint, dlevel=1, 'No instrument provided'
  return
endif


;TODO:  Verify inputs aren't arrays (or allow?)


;Get structure specifying availability of data types
;---------------------------------------------------
case strupcase(instrument) of 
  'AFG': s = mms_load_options_fgm()
  'DFG': s = mms_load_options_fgm()
  'EIS': s = mms_load_options_eis()
  'FEEPS': s = mms_load_options_feeps()
  'FPI': s = mms_load_options_fpi()
  'HPCA': s = mms_load_options_hpca()
  'SCM': s = mms_load_options_scm()
  else: begin
    dprint, dlevel=1, 'Instrument "'+instrument+'" not recognized'
    return
  endelse
endcase


;Extract information from structure
;---------------------------------------------------
mms_load_options_getvalid, s, rate_in=rate, level_in=level, datatype_in=datatype, $
       rates_out=rates_out, levels_out=levels_out, datatypes_out=datatypes_out

valid = ~undefined(rates_out) && ~undefined(levels_out) && ~undefined(datatypes_out)

if ~valid then begin
  return
endif

if undefined(rate) then rate = strlowcase(spd_uniq(rates_out))
if undefined(level) then level = strlowcase(spd_uniq(levels_out))
if undefined(datatype) then datatype = strlowcase(spd_uniq(datatypes_out))


end