

;+
;Purpose:
;  Helper function to return structure describing 
;  the available data types for AFG or DFG
;-
function mms_load_options_fgm

    compile_opt idl2, hidden
    
;use placeholder where datatype will go
s = { $
      brst: { $
              l1a: { $
                     placeholder: 0 $
                   }, $
              l1b: { $
                     placeholder: 0 $
                   } $
            }, $
      fast: { $
              l1a: { $
                     placeholder: 0 $
                   } $
            }, $
      slow: { $
              l1a: { $
                     placeholder: 0 $
                   } $
            }, $
      srvy: { $
              l1a: { $
                     placeholder: 0 $
                   }, $
              ql: { $
                     placeholder: 0 $
                   } $
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
      srvy: { $
              l1a: { $
                     electronenergy: 1, $
                     extof: 1, $
                     partenergy: 1, $
                     phxtof: 1 $
                   }, $
              l1b: { $
                     electronenergy: 1, $
                     extof: 1, $
                     partenergy: 1, $
                     phxtof: 1 $
                   } $
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
              l1a: { $
                     electron_bottom: 1, $
                     electron_top: 1, $
                     ion_bottom: 1, $
                     ion_top: 1 $
                   } $
            }, $
      srvy: { $
              l1a: { $
                     electron_bottom: 1, $
                     electron_top: 1, $
                     ion_bottom: 1, $
                     ion_top: 1 $
                   }, $
              l1b: { $
                     electron: 1, $
                     ion: 1 $
                   } $
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
              sitl: { $
                      placeholder: 0 $
                    } $
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
              l1b: { $
                     ion: 1, $
                     logicals: 1, $
                     moments: 1 $
                   } $
            }, $
      srvy: { $
              l1b: { $
                     ion: 1, $
                     logicals: 1, $
                     moments: 1 $
                   }, $
              sitl:{ $
                     ion: 1, $
                     moments: 1 $
                   } $
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
              l1a: { $
                     scb: 1, $
                     schb: 1 $
                   } $
            }, $
      fast: { $
              l1a: { $
                     scf: 1 $
                   }, $
              l1b: { $
                     scf: 1 $
                   } $
            }, $
      slow: { $
              l1a: { $
                     scs: 1 $
                   } $
            }, $
      srvy: { $
              l1a: { $
                     cal: 1, $
                     scm: 1 $
                   } $
            } $
    }

return, s

end


;+
;Purpose:
;  Replace underscores used to represent dashes in structure tags.
;  This is neccessary because dashes cannot be used for structure tag names.
;-
pro mms_load_options_fixunderscores, sa

    compile_opt idl2, hidden

if ~is_string(sa) then return

pos = strpos(sa,'_')

for i=0, n_elements(sa)-1 do begin

  if pos[i] gt 0 then begin
    temp = sa[i] ;strput needs named var
    strput, temp, '-', pos[i]
    sa[i] = temp
  endif

endfor

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

    ;if the input is specified and doesn't match then ignore
    if is_string(level) then begin
      if valid_levels[j] ne strupcase(level) then continue
    endif
    
    ;if input matched or wasn't specified then add this to the output list
    levels_out = array_concat(valid_levels[j], levels_out)

    ;get datatypes for this rate/level
    valid_datatypes = tag_names(s.(i).(j))

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
;$LastChangedDate: 2015-08-07 16:25:53 -0700 (Fri, 07 Aug 2015) $
;$LastChangedRevision: 18440 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/mms_load_options.pro $
;-
pro mms_load_options, $
             instrument, $
             
             rate=rate, $
             level=level, $
             datatype=datatype, $
             
             valid=valid

             
    compile_opt idl2, hidden


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
if undefined(datatype) then begin
  datatype = strlowcase(spd_uniq(datatypes_out))
  mms_load_options_fixunderscores, datatype
endif

end