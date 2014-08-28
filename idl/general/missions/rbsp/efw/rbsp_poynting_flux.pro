;+
;*****************************************************************************************
;
;  PROCEDURE :  rbsp_poynting_flux
;
;  PURPOSE  : calculates Poynting flux. Separates into field-aligned and perp components
;			  Returns results as tplot variables
;
;
;  REQUIRES:  tplot library
;               
;               
;
;  EXAMPLES:    
;               
;
;  KEYWORDS:  Bw -> tplot name of the [n,3] magnetic field waveform
;			  Ew -> tplot name of the [n,3] electric field waveform
;			  Tshort, Tlong -> short and long period of waveform to use. 
;			  Bo -> (optional keyword) array of DC magnetic field directions.
;					Use, for example, if Bw is from AC-coupled data.
;  
;
;   NOTES:     
;
;			 Poynting flux coord system
;   		 	P1mgse = Bmgse x xhat_mgse  (xhat_mgse is spin axis component)
;				P2mgse = Bmgse x P1mgse
;  		   		P3mgse = Bmgse
;
;
;			 The waveform data are first downsampled to 1/Tshort to avoid the wasted
;			 computation of having to run program with data at unnecessarily high 
;			 sample rate.
;
;			 The waveform is then bandpassed to the frequency range flow=1/Tlong...fhigh=1/Tshort
;
;
;			 The output tplot variables are:
;
;			 	These three output variables contain a mix of spin axis and spin plane components:
;			 		pflux_p1  -> Poynting flux in perp1 direction
;			 		pflux_p2  -> Poynting flux in perp2 direction
; 			 		pflux_Bo  -> Poynting flux along Bo
;
;			 	These partial Poynting flux calculations contain only spin plane Ew.
;			 		pflux_nospinaxis_perp 
;			 		pflux_nospinaxis_para
;
;               
;
;   CREATED:  11/28/2012
;   CREATED BY:  Aaron W. Breneman
;    LAST MODIFIED:  MM/DD/YYYY   v1.0.0
;    MODIFIED BY: 
;
;*****************************************************************************************
;-
;**************************************************************************		


pro rbsp_poynting_flux,Bw,Ew,Tshort,Tlong,Bo=Bo


get_data,Bw,data=Bw_test


if is_struct(Bw_test) then begin

	;-----------------------------------------------------------
	;Get DC magnetic field and use to define P1,P2,P3 directions
	;-----------------------------------------------------------

	if ~keyword_set(Bo) then begin		
		rbsp_downsample,Bw,suffix='_DC',1/40.
		Bdc = Bw + '_DC'
	endif else begin
		tinterpol_mxn,Bo,Bw,newname='Mag_mgse_DC'
		Bdc = 'Mag_mgse_DC'
	endelse
	
	;----------------------------------------------------
	;Downsample both the Bw and Ew based on Tshort. 
	;No need to have the cadence at a higher rate than 1/Tshort
	;----------------------------------------------------
	
	
	sr = 2/Tshort
	nyquist = sr/2.
	rbsp_downsample,[Bw,Ew],suffix='_DS_tmp',sr
	
	Bw = Bw +  '_DS_tmp'
	Ew = Ew +  '_DS_tmp'
	
	get_data,Bw,data=goo
	times = goo.x
	
	;------------------------------------------------------------------------------
	;Interpolate to get MagDC and Esvy data to be on the same times as the Bw data
	;------------------------------------------------------------------------------
	
	
	tinterpol_mxn,Ew,times
	Ew = Ew + '_interp'
	
	tinterpol_mxn,Bdc,times
	Bdc = Bdc + '_interp'
	
	
	
	;----------------------------
	;Define new coordinate system
	;----------------------------
	
	nelem = n_elements(times)
	
	;P1 unit vector
	p1mgse = double([[replicate(0,nelem)],$
					 [replicate(0,nelem)],$
					 [replicate(0,nelem)]])
	
	
	get_data,Bdc,data=Bmgse_dc
	
	
	
	
	
	for i=0L,nelem-1 do p1mgse[i,*] = crossp(Bmgse_dc.y[i,*],[1.,0.,0.])
	
	;normalize p1gse
	p1mag = fltarr(nelem)
	for i=0L,nelem-1 do p1mag[i] = sqrt(p1mgse[i,0]^2 + p1mgse[i,1]^2 + p1mgse[i,2]^2)
	for i=0L,nelem-1 do p1mgse[i,*] = p1mgse[i,*]/p1mag[i]
	
	
	
	
	;P2 unit vector
	p2mgse = p1mgse
	for i=0L,nelem-1 do p2mgse[i,*] = crossp(Bmgse_dc.y[i,*],p1mgse[i,*])
	
	;normalize p2mgse
	p2mag = fltarr(nelem)
	for i=0L,nelem-1 do p2mag[i] = sqrt(p2mgse[i,0]^2 + p2mgse[i,1]^2 + p2mgse[i,2]^2)
	for i=0L,nelem-1 do p2mgse[i,*] = p2mgse[i,*]/p2mag[i]
	
	
	
	
	Bmag_dc = sqrt(Bmgse_dc.y[*,0]^2 + Bmgse_dc.y[*,1]^2 + Bmgse_dc.y[*,2]^2)
	Bmgse_dc_uvec = Bmgse_dc.y
	Bmgse_dc_uvec[*,0] = Bmgse_dc.y[*,0]/Bmag_dc
	Bmgse_dc_uvec[*,1] = Bmgse_dc.y[*,1]/Bmag_dc
	Bmgse_dc_uvec[*,2] = Bmgse_dc.y[*,2]/Bmag_dc
	
	
				;*********************************************
				;Test to make sure unit vectors are orthogonal
				;*********************************************
				
				;for i=0,3000 do print,acos(total(p1mgse[i,*]*p2mgse[i,*])/(p1mag[i]*p2mag[i]))/!dtor   ;perp!
				;for i=0,3000 do print,acos(total(p1mgse[i,*]*Bmgse.y[i,*])/(p1mag[i]*Bmag[i]))/!dtor   ;perp!
				;for i=0,3000 do print,acos(total(p2mgse[i,*]*Bmgse.y[i,*])/(p2mag[i]*Bmag[i]))/!dtor   ;perp!
	
	
	
	;-----------------------------------------------------------------------------------
	;Now we've defined our Poynting flux unit vectors as P1mgse,P2mgse,P3mgse=Bmgse_uvec.
	;Project the Esvy and Bsvy data into these three directions. 
	;-----------------------------------------------------------------------------------
	
	
	get_data,Ew,data=Emgse
	get_data,Bw,data=Bmgse
	 	 
	Emgse = Emgse.y  
	Bmgse = Bmgse.y  
	
	 
	
	Ep1 = fltarr(nelem)
	Ep2 = Ep1
	Ep3 = Ep1
	
	for i=0L,nelem-1 do Ep1[i] = total(reform(Emgse[i,*])*reform(P1mgse[i,*]))
	for i=0L,nelem-1 do Ep2[i] = total(reform(Emgse[i,*])*reform(P2mgse[i,*]))
	for i=0L,nelem-1 do Ep3[i] = total(reform(Emgse[i,*])*reform(Bmgse_dc_uvec[i,*]))
	  
	Ep = [[Ep1],[Ep2],[Ep3]]
	
	
	
	Bp1 = fltarr(nelem)
	Bp2 = Bp1
	Bp3 = Bp1
	
	for i=0L,nelem-1 do Bp1[i] = total(reform(Bmgse[i,*])*reform(P1mgse[i,*]))
	for i=0L,nelem-1 do Bp2[i] = total(reform(Bmgse[i,*])*reform(P2mgse[i,*]))
	for i=0L,nelem-1 do Bp3[i] = total(reform(Bmgse[i,*])*reform(Bmgse_dc_uvec[i,*]))
	  
	Bp = [[Bp1],[Bp2],[Bp3]]
	
	
	;-----------------------------------------------------------------------------------------
	;At this point Ep, Bp and Bdc have a sample rate of 2/Tshort and are sampled at the same times. 
	;We want to bandpass so that the lowest possible frequency is 1/Tlong Samples/sec  
	;-----------------------------------------------------------------------------------------


	;Define frequencies as a fraction of Nyquist
	flow = (1/Tlong)/nyquist		
	fhigh = (1/Tshort)/nyquist

				
	
	Epf = BANDPASS_FILTER(Ep,flow,fhigh);,/gaussian)
	Bpf = BANDPASS_FILTER(Bp,flow,fhigh);,/gaussian)



	Epf = Epf/1000.  ;V/m
	Bpf = Bpf/1d9    ;Tesla


	store_data,'Epft',data={x:times,y:Epf}
	store_data,'Bpft',data={x:times,y:Bpf}
	ylim,'Epft',-0.1,0.1
	ylim,'Bpft',-1d-9,1d-9
	tplot,['Epft','Bpft','Mag_mgse_r_DC_interp']
	
	
	
	;----------------------------------
	;Calculate Poynting flux
	;----------------------------------
	
	
	;P1, P2, P3 = full Poynting flux components
	;pure2, pure3 = partial components (no spin axis contamination)
	
	
	muo = 4d0*!DPI*1d-7     ; -Permeability of free space (N/A^2)
	
	;E*B/muo = J/m^2/s  (E in V/m, B in T)
	;To put in ergs:  1 erg = 1d-7 J
	
	
	
	;J/m^2/s
	P1 = (Epf[*,1]*Bpf[*,2] - Epf[*,2]*Bpf[*,1])/muo
	P2 = (Epf[*,2]*Bpf[*,0] - Epf[*,0]*Bpf[*,2])/muo
	P3 = (Epf[*,0]*Bpf[*,1] - Epf[*,1]*Bpf[*,0])/muo
	pure2 = (Epf[*,0]*Bpf[*,2])/muo ;P2-hat
	pure3 = (Epf[*,0]*Bpf[*,1])/muo ;P3-hat (Bo)
	
	
	
	;erg/cm^2/s
	P1 = P1*1d7/1d4
	P2 = P2*1d7/1d4
	P3 = P3*1d7/1d4
	pure2 = pure2*1d7/1d4
	pure3 = pure3*1d7/1d4
	
	
	;------------------------------------
	;Estimate mapped Poynting flux
	;------------------------------------
	
	;From flux tube conservation B1*A1 = B2*A2  (A=cross sectional area of flux tube)
	
	;B2/B1 = A1/A2
	
	;P = EB/A ~ 1/A
	
	;P2/P1 = A1/A2 = B2/B1
	
	;Assume an ionospheric magnetic field of 45000 nT at 100km. This value shouldn't change too much
	;and is good enough for a rough mapping estimate.
	
	 
	P1_ion = 45000d * P1/Bmag_dc
	P2_ion = 45000d * P2/Bmag_dc
	P3_ion = 45000d * P3/Bmag_dc
	pure2_ion = 45000d * pure2/Bmag_dc
	pure3_ion = 45000d * pure3/Bmag_dc
		
	
	
	
	;----------------------------------
	;Create tplot variables
	;----------------------------------
	
	
	store_data,'Ew_pftst',data={x:times,y:Epf}
	store_data,'Bw_pftst',data={x:times,y:Bpf}
	store_data,'pftst_nospinaxis_perp',data={x:times,y:pure2}
	store_data,'pftst_nospinaxis_para',data={x:times,y:pure3}
	store_data,'pftst',data={x:times,y:[[P1],[P2],[P3]]}
	store_data,'pftst_nospinaxis_perp_iono',data={x:times,y:pure2_ion}
	store_data,'pftst_nospinaxis_para_iono',data={x:times,y:pure3_ion}
	store_data,'pftst_iono',data={x:times,y:[[P1_ion],[P2_ion],[P3_ion]]}
	
	split_vec,'Ew_pftst',suffix='_'+['p1','p2','p3']
	split_vec,'Bw_pftst',suffix='_'+['p1','p2','p3']
	split_vec,'pftst', suffix='_'+['p1','p2','Bo']
	split_vec,'pftst_iono', suffix='_'+['p1','p2','Bo']
	
	
	options,'Ew_pftst','ytitle','Ew!Cpftst coord!C[mV/m]'
	options,'Bw_pftst','ytitle','Bw!Cpftst coord!C[nT]'
	options,'Ew_pftst_p1','ytitle','Ew!Cpftst p1 dir!C[mV/m]'
	options,'Ew_pftst_p2','ytitle','Ew!Cpftst p2 dir!C[mV/m]'
	options,'Ew_pftst_p3','ytitle','Ew!Cpftst Bo dir!C[mV/m]'
	options,'Bw_pftst_p1','ytitle','Bw!Cpftst p1 dir!C[nT]'
	options,'Bw_pftst_p2','ytitle','Bw!Cpftst p2 dir!C[nT]'
	options,'Bw_pftst_p3','ytitle','Bw!Cpftst Bo dir!C[nT]'
	
	
	options,'pftst_nospinaxis_perp','ytitle','pftst!Ccomponent!Cperp to Bo!C[erg/cm^2/s]'
	options,'pftst_nospinaxis_para','ytitle','pftst!Ccomponent!Cpara to Bo!C[erg/cm^2/s]'
	options,'pftst_nospinaxis_perp','labels','No spin axis!C comp'
	options,'pftst_nospinaxis_para','labels','No spin axis!C comp!C+ along Bo'
	options,'pftst','ytitle','pftst!C[erg/cm^2/s]'
	;options,'pftst','labels','1-40 sec!Cperiod BP'
	options,'pftst_p1','ytitle','pftst!Cperp1 to Bo!C[erg/cm^2/s]'
	options,'pftst_p2','ytitle','pftst!Cperp2 to Bo!C[erg/cm^2/s]'
	options,'pftst_Bo','ytitle','pftst!Cparallel to Bo!C[erg/cm^2/s]'
	options,'pftst_nospinaxis_perp_iono','ytitle','pftst!Cmapped!Cto ionosphere!Cperp to Bo!C[erg/cm^2/s]'
	options,'pftst_nospinaxis_para_iono','ytitle','pftst!Cmapped!Cto ionosphere!Cpara to Bo!C[erg/cm^2/s]'
	options,'pftst_nospinaxis_perp_iono','labels','No spin axis!C comp'
	options,'pftst_nospinaxis_para_iono','labels','No spin axis!C comp!C+ along Bo'
	options,'pftst_iono','ytitle','pftst!Cmapped!C[erg/cm^2/s]'
	;options,'pftst_iono','labels','1-40 sec!Cperiod BP'
	options,'pftst_iono_p1','ytitle','pftst!Cmapped!Cperp1 to Bo!C[erg/cm^2/s]'
	options,'pftst_iono_p2','ytitle','pftst!Cmapped!Cperp2 to Bo!C[erg/cm^2/s]'
	options,'pftst_iono_Bo','ytitle','pftst!Cmapped!Cparallel to Bo!C[erg/cm^2/s]'
	
	
	;ylim,['pftst_nospinaxis_perp','pflux_nospinaxis_para'],0,0
	ylim,['pftst_p1','pftst_p2','pftst_Bo'],-0.2,0.2
	ylim,['pftst_nospinaxis_perp','pftst_nospinaxis_para'],-0.2,0.2
	ylim,['pftst_nospinaxis_perp_iono','pftst_nospinaxis_para_iono'],-10,10
	
	;ylim,['pftst_nospinaxis_perp_iono','pftst_nospinaxis_para_iono'],0,0
	ylim,['pftst_iono_p1','pftst_iono_p2','pftst_iono_Bo'],0,0
	
	
	options,'pftst_nospinaxis_para','colors',2		
	options,'pftst_nospinaxis_perp','colors',1
	options,'pftst_nospinaxis_para_iono','colors',2		
	options,'pftst_nospinaxis_perp_iono','colors',1
			
			
endif
			

end



