;+
;PROCEDURE:   mvn_lpw_load
;PURPOSE:
;  Decomutater of the LPW telemetry data
;  This call uses three different ways to get data: cdf, L0 and ground data (no sc header)
;  This reads one file and creates the requested data products
;  Presently cannot merge two files <--------
;  
;
;USAGE:
;  mvn_lpw_load,filename,tplot_var,filetype=filetype,packet=packet,strip_pad = strip_pad, wrapper = wrapper, compressed=compressed
;
;INPUTS:
;       filename:      The full filename (including path) of a binary file containing zero or more LPW APID's.  
;
;KEYWORDS:
;       filetype:   'cdf', 'l0' (sc header) , or a file from ground testing (no sc header)
;       packet:     Which packets to read into memeory, default all packets
;       
;       board:      board_names=['EM1','EM2','EM3','FM'] 
;       
;       tplot_var  'all' or 'sci' Which tplot variables to produce. 'sci' produces tplot variables which have physical unit 
;                                 associated with them, and is the default. 'all' produces all tplot variables and includes 
;                                 master cycle information etc.
;
;CREATED BY:   Laila Andersson  05-15-13
;FILE: mvn_lpw_load.pro
;VERSION:   1.0
;LAST MODIFICATION: 2013, July 11th, Chris Fowler - added keyword tplot_var=['all', 'sci']  
;                   05/15/13
;-

pro mvn_lpw_load,filename, tplot_var=tplot_var, filetype=filetype, packet=packet,board=board  

if keyword_set(filetype) then filetype=filetype else print,'mvn_lpw_load: No filetype was provided'

if keyword_set(packet) then packet=packet else packet=['HSK','EUV','AVG','SPEC','HSBM','WPK']   ;default all

if keyword_set(board) then board=board else board='FM'

if keyword_set(tplot_var) then tplot_var=tplot_var else tplot_var='sci'  ;default is science


Case filetype of 
      'L0' or 'l0':   begin                            
                     mvn_lpw_r_header_l0, filename,output,packet=packet                                         
                     mvn_lpw_pkt_instrument_constants,board,lpw_const2=lpw_const                        ; set up the constants used in the below routines 
                     if output.p1+output.p2 +output.p3 +output.p4 +output.p5 GT 0 THEN mvn_lpw_wpkt,output,lpw_const             
                     mvn_lpw_pkt_atr,output,lpw_const,tplot_var=tplot_var
                     mvn_lpw_pkt_euv,output,lpw_const,tplot_var=tplot_var  
                     mvn_lpw_pkt_adr,output,lpw_const, tplot_var=tplot_var
                     mvn_lpw_pkt_hsk,output ,lpw_const, tplot_var=tplot_var
                     mvn_lpw_pkt_swp,output,lpw_const,1,tplot_var=tplot_var   ;need the sweep to be read in before
                     mvn_lpw_pkt_swp,output,lpw_const,2,tplot_var=tplot_var   ;need the sweep to be read in before
                     mvn_lpw_pkt_e12_dc, output, lpw_const,'act', tplot_var=tplot_var
                     mvn_lpw_pkt_e12_dc, output, lpw_const,'pas', tplot_var=tplot_var       
                     mvn_lpw_pkt_spectra,output,lpw_const,'act','lf',tplot_var=tplot_var
                     mvn_lpw_pkt_spectra,output,lpw_const,'act','mf',tplot_var=tplot_var
                     mvn_lpw_pkt_spectra,output,lpw_const,'act','hf',tplot_var=tplot_var
                     mvn_lpw_pkt_spectra,output,lpw_const,'pas','lf',tplot_var=tplot_var
                     mvn_lpw_pkt_spectra,output,lpw_const,'pas','mf',tplot_var=tplot_var
                     mvn_lpw_pkt_spectra,output,lpw_const,'pas','hf',tplot_var=tplot_var
                     mvn_lpw_pkt_hsbm, output,lpw_const,'lf',tplot_var=tplot_var
                     mvn_lpw_pkt_hsbm, output,lpw_const,'mf',tplot_var=tplot_var
                     mvn_lpw_pkt_hsbm, output,lpw_const,'hf',tplot_var=tplot_var
                     mvn_lpw_pkt_htime, output,lpw_const,tplot_var=tplot_var                                                                                                

                      end
      'CDF' or 'cdf': begin
                             print,'mvn_lpw_load: Not yet written the CDF loader, sorry'
                             stop
                           end
      'ground' or 'GROUND': begin                            
                     ;keywords that can be called on
                     ;       wrapper:    For ground data only (when sc header not included)
                     ;       compressed: For ground data only (when sc header not included). Default compressed. For test purpuses the data stream can be uncompressed by the FPGA.
                     ;       strip_pad:  For ground data only (when sc header not included)
                      ;these are options not used   in mvn_lpw_r_header any more, keept in case of debugging needs
                     ;if keyword_set(strip_pad) then strip_pad = strip_pad              ; this is 0 or 1 bit shift depending if the call is using this keyword,  do not use
                     ;if keyword_set(wrapper) then wrapper = wrapper else place  = 0    ; in the mvn_lpw_r_header this is not an option anymore, place  = 0  
                     ;if keyword_set(compressed) then compressed=compressed ;default compression = 'on' 
                     ;
                                                       
                    ; mvn_lpw_pkt_r_header, filename,output,packet=packet,compressed=compression
                      mvn_lpw_pkt_r_header, filename,output,compressed=1
                 
                     mvn_lpw_pkt_instrument_constants,board,lpw_const2=lpw_const                 ; set up the constants used in the below routines 
                     if output.p1+output.p2 +output.p3 +output.p4 +output.p5 GT 0 THEN mvn_lpw_wpkt,output,lpw_const             
                     mvn_lpw_pkt_atr,output,lpw_const,tplot_var=tplot_var
                     mvn_lpw_pkt_euv,output,lpw_const,tplot_var=tplot_var                
                     mvn_lpw_pkt_adr,output,lpw_const,tplot_var=tplot_var
                     mvn_lpw_pkt_hsk,output ,lpw_const,tplot_var=tplot_var
                     mvn_lpw_pkt_swp,output,lpw_const,1,tplot_var=tplot_var   ;need the sweep to be read in before
                     mvn_lpw_pkt_swp,output,lpw_const,2,tplot_var=tplot_var   ;need the sweep to be read in before
                     mvn_lpw_pkt_e12_dc,output,lpw_const,tplot_var=tplot_var,'pas'
                     mvn_lpw_pkt_e12_dc,output,lpw_const,tplot_var=tplot_var,'act'
                     mvn_lpw_pkt_spectra,output,lpw_const,'act','lf',tplot_var=tplot_var
                     mvn_lpw_pkt_spectra,output,lpw_const,'act','mf',tplot_var=tplot_var
                     mvn_lpw_pkt_spectra,output,lpw_const,'act','hf',tplot_var=tplot_var
                     mvn_lpw_pkt_spectra,output,lpw_const,'pas','lf',tplot_var=tplot_var
                     mvn_lpw_pkt_spectra,output,lpw_const,'pas','mf',tplot_var=tplot_var
                     mvn_lpw_pkt_spectra,output,lpw_const,'pas','hf',tplot_var=tplot_var
                     mvn_lpw_pkt_hsbm, output,lpw_const,'lf',tplot_var=tplot_var
                     mvn_lpw_pkt_hsbm, output,lpw_const,'mf',tplot_var=tplot_var
                     mvn_lpw_pkt_hsbm, output,lpw_const,'hf',tplot_var=tplot_var
                     mvn_lpw_pkt_htime, output,lpw_const,tplot_var=tplot_var                                                                                        
                     end
ELSE:                BEGIN 
                         print,' mvn_lpw_loader: no file mach was found ',filename,' ',filetype
                     END                    
ENDCASE                         



  ;###############################################################

if 'yes' EQ 'no' then begin
  ;############ Draft Quick look data LPW/EUV specific panels ################
    
  plus_sym,0.6
        
  get_data,'mvn_lpw_hsk',data=data,limit=limit 
  store_data,'Beb_temp',data={x:data.x,y:data.y(*,0:2)}
  options,'Beb_temp','ytitle','BEB+preamp temp (C)'
  ylim,'Beb_temp',min(data.y(*,0:2)),max(data.y(*,0:2))  
  store_data,'modes',data=['mvn_lpw_swp2_mode','mvn_lpw_atr_mode','mvn_lpw_adr_mode']
  options, 'mvn_lpw_adr_mode','color',2
  options, 'mvn_lpw_atr_mode','color',6
  ylim,'modes',0,16
  options,'modes','ytitle','Modes' 
  options,'*mode','psym',8
 
  store_data,'E12',data=['mvn_lpw_pas_E12_LF','mvn_lpw_act_E12_LF']
  options,'mvn_lpw_act_E12_LF','color',6
  options,'E12','ytitle','E12 [V]'
  options,'mvn_lpw_pas_E12_LF','psym',8
  options,'mvn_lpw_act_E12_LF','psym',8
 
   store_data,'SC_pot',data=['mvn_lpw_swp1_V2','mvn_lpw_act_V2','mvn_lpw_pas_V2', $
                             'mvn_lpw_swp2_V1','mvn_lpw_act_V1','mvn_lpw_pas_V1']
   options,'SC_pot','ytitle','SC_pot [V]'                           
   options,'mvn_lpw_act_V2','color',1
   options,'mvn_lpw_pas_V2', 'color',2
   options,'mvn_lpw_swp2_V1','color',3
   options,'mvn_lpw_act_V1','color',5
   options,'mvn_lpw_pas_V1','color',6
   options,'*V1','psym',8
   options,'*V2','psym',8
     
   store_data,'htime',data=['mvn_lpw_htime_cap_lf','mvn_lpw_htime_cap_mf','mvn_lpw_htime_cap_hf'] 
   options,'htime','ytitle','htime'    
   options,'mvn_lpw_htime_cap_mf','color',4   
   options,'mvn_lpw_htime_cap_hf','color',6   
   options,'*htime_cap*','psym',8   
   ylim,'htime',0,4   
  
  tplot,['mvn_lpw_euv','mvn_lpw_euv_temp_C','Beb_temp','modes','mvn_lpw_spec_hf_pas','mvn_lpw_spec_mf_pas','mvn_lpw_spec_lf_pas', $
         'E12','SC_pot','mvn_lpw_swp1_IV','mvn_lpw_swp2_IV','htime'] 
  
  tplot,['mvn_lpw_euv','mvn_lpw_euv_temp_C','Beb_temp','mvn_lpw_spec_hf_pas','mvn_lpw_spec_mf_pas','mvn_lpw_spec_lf_pas', $
         'E12','SC_pot','mvn_lpw_swp1_IV','mvn_lpw_swp2_IV']
  
  ;############################################################### 
  ; to create for PF-suit summary plot   draft
    plus_sym,0.4
    
    
  get_data,'mvn_lpw_euv',data=data0,limit=limit
  data0.y=(data0.y-min(data0.y) )*0.01    +20    ; need to be corrected for later on
  store_data,'mvn_lpw_euv_diodes_ql',data=data0,limit=limit
  options,'mvn_lpw_euv_temp_C','psym',8 
  options,'mvn_lpw_euv_temp_C','colors',3 
  store_data,'mvn_lpw_euv_ql',data=['mvn_lpw_euv_diodes_ql','mvn_lpw_euv_temp_C']
  options,'mvn_lpw_euv_ql','ytitle','EUV diodes + temp'
  ylim,'mvn_lpw_euv_ql',floor(min(data0.y*0.9)),floor(max(data0.y*1.1))
  
  store_data,'mvn_lpw_wave_spec_ql',data=['mvn_lpw_spec_hf_pas','mvn_lpw_spec_mf_pas','mvn_lpw_spec_lf_pas']
  options,'mvn_lpw_wave_spec_ql','ytitle','Spec PAS !C !C Hz'
  ylim,'mvn_lpw_wave_spec_ql',1e0,2e6
  get_data,'mvn_lpw_swp1_IV',limit=limit
  get_data,'mvn_lpw_htime_cap_lf',data=data
  data.y=(data.y+100) < (0.9*limit.yrange(1)) 
  store_data,'mvn_lpw_htime_cap2_lf',data=data
  options,'mvn_lpw_htime_cap2_lf','color',4   
  options,'mvn_lpw_htime_cap2_lf','psym',8 
  options,'mvn_lpw_pas_V2', 'color',2 
  options,'mvn_lpw_pas_V2','psym',8 
  store_data,'mvn_lpw_IV1_pasV2_ql',data=['mvn_lpw_swp1_IV','mvn_lpw_pas_V2','mvn_lpw_htime_cap2_lf'],limit=limit
  options,'mvn_lpw_IV1_pasV2_ql','ytitle','Potential !C!C [V]'
    
   tplot,['mvn_lpw_euv_ql','mvn_lpw_wave_spec_ql','mvn_lpw_IV1_pasV2_ql']
  
  ;###############################################################
 endif
  
  
  ;###############################################################

end

