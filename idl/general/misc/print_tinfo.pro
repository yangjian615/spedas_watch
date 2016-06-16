;+
;
; Procedure:  print_tinfo
; 
; Purpose:
;             prints info on a tplot variable, including dimensions 
;             and what each dimension represents
; 
; Input:
;             tplot_name: name of the tplot variable to print info on; also
;             accepts tplot variable #
; 
; Keywords:
;             time:   show the first and last times in the variable
;             help:   show the output of help, /structure, data 
;                     and help, /structure, dlimits for the variable
;                     
; Example:  
;             MMS> print_tinfo, 'mms1_hpca_hplus_phase_space_density'
;             *** Variable: mms1_hpca_hplus_phase_space_density
;             <Expression>    DOUBLE    = Array[20456, 63, 16]
;             Data format: [Epoch, mms1_hpca_ion_energy, mms1_hpca_polar_anode_number]
;  
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-06-15 13:10:57 -0700 (Wed, 15 Jun 2016) $
; $LastChangedRevision: 21328 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/print_tinfo.pro $
;-


; takes name of a tplot variable as a string, prints out information on the variable
pro print_tinfo, tplot_name, time = time, help = help
    if tnames(tplot_name) eq '' then begin
        dprint, dlevel = 1, 'Error, no tplot variable named ' + tplot_name + ' found.'
        return
    endif
    
    ; allow for tvariable # instead of name
    if is_num(tplot_name) then tplot_name = tnames(tplot_name)
    
    print, '*** Variable: ' + tplot_name
    get_data, tplot_name, data=d, dlimits=dl
    if is_struct(d) && ~undefined(help) then help, /st, d
    if ~undefined(time) then begin
      print, 'Start time: ' + time_string(d.X[0])
      print, 'End time: ' + time_string(d.X[n_elements(d.X)-1])
    endif 
    if is_struct(d) && ~undefined(help) then help, /st, dl
    if is_struct(dl.cdf) && ~undefined(help) then help, /st, dl.cdf
    

    if is_struct(dl.cdf.vatt) then begin
      ndimens = ndimen(d.Y)
      metadata = (dl.cdf.vatt)[0]
      help, d.Y ; show the dimensions before showing what data they represent
      if ndimens eq 4 then print, 'Data format: ['+metadata.depend_0+', '+metadata.depend_3+', '+metadata.depend_2+', '+metadata.depend_1+']'
      if ndimens eq 3 then print, 'Data format: ['+metadata.depend_0+', '+metadata.depend_2+', '+metadata.depend_1+']'
      if ndimens eq 2 then begin
        str_element, metadata, 'depend_1', dep1, success=s
        ; not all have depend_1; if not, use fieldnam
        if s then $
          print, 'Data format: ['+metadata.depend_0+', '+metadata.depend_1+']' $
        else $
          print, 'Data format: ['+metadata.depend_0+', '+metadata.fieldnam+']'
      endif
    endif

end