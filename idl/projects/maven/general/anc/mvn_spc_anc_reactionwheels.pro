





;

;+
;FUNCTION: MVN_SPC_ANC_REACTIONWHEELS
;Purpose:
;  returns and array of structures that contain data from reactionwheel files
;USAGE:
;  data = mvn_spc_anc_reactionwheels()
;  printdat,data         ; display contents
;  store_data,'GNC',data=data   ; store for tplot
;
; KEYWORDS:
;   TRANGE=TRANGE  ; Optional 2 element time range vector
; $LastChangedBy:  $
; $LastChangedDate:  $
; $LastChangedRevision:  $
; $URL:  $
;-
function  mvn_spc_anc_reactionwheels,pformat,trange=trange  ,files=files         ;,var_name,thruster_time= time_x

; Get filenames
trange=timerange(trange)
if ~keyword_set(pformat) then begin
   pformat = 'maven/data/anc/eng/gnc/sci_anc_gncyy_DOY_???.drf'
   daily_names=1
   last_version=1
endif
tr = timerange(trange) + 86400L * [-3,1]
src = mvn_file_source(source,last_version=last_version,no_update=0,/valid_only)
files = mvn_pfp_file_retrieve(pformat,files=files,trange=tr,daily_names=daily_names,source=src)
nfiles = n_elements(files) * keyword_set(files)
dprint,dlevel=2,nfiles,' files found'
  
; Create output structure template
names=strsplit(/extract,'ATT_QU_I2B_1 ATT_QU_I2B_2 ATT_QU_I2B_3 ATT_QU_I2B_4 ATT_QU_I2B_T ATT_RAT_BF_X ATT_RAT_BF_Y ATT_RAT_BF_Z APIG_ANGLE   APOG_ANGLE   APIG_APP_RAT APOG_APP_RAT RW1_SPD_DGTL RW2_SPD_DGTL RW3_SPD_DGTL RW4_SPD_DGTL')
nc = n_elements(names)
output_str = {time:0d}
for i=0,nc-1 do output_str=create_struct(output_str,names[i],0.)

fpos = indgen(nc)*13+19  ; starting location of columns
nrec=0                   ; Number of records
  
for i=0,nfiles-1 do begin
   file = files[i]
   dprint,dlevel=2,'Reading :',file
   file_open,'r',file,unit=fp,dlevel=3
   l=0L
   def = ''
   def = !values.f_nan
   blank = string(replicate(byte(' '),13))
   while ~eof(fp) do begin
      s=''
      readf,fp,s
      timestr = strmid(s,0,fpos[0])
      if strmid(timestr,0,1) eq ' ' then continue
      time = time_double(timestr,tformat='yy/DOY-hh:mm:ss.fff')
      output_str.time =time
      for j=0,nc-1 do begin
        ss = strmid(s,fpos[j],13)
;        v = is_numeric(ss) ?  float(ss) : !values.f_nan
        v = (ss ne blank) ?  float(ss) : !values.f_nan          ; twice as fast as line above
        output_str.(j+1) = v
      endfor
      append_array,output,output_str,index=nrec
   endwhile
   free_lun,fp
endfor
append_array,output,index=nrec
dprint,dlevel=3,'Done'
return,output
end

