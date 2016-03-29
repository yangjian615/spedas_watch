PRO eva_data_load_mms_sw, sc=sc
  compile_opt idl2

  ; B
  ;------------
  tn = tnames(sc+'_dfg_srvy_dmpa',ct)
  if ct ne 1 then begin
    mms_sitl_get_dfg, sc_id=sc
    options,sc+'_dfg_srvy_gsm_dmpa',$
      labels=['B!DX!N', 'B!DY!N', 'B!DZ!N','|B|'],ytitle=sc+'!CDFG!Csrvy',ysubtitle='GSM [nT]',$
      colors=[2,4,6],labflag=-1,constant=0, cap=1
    options,sc+'_dfg_srvy_dmpa',$
      labels=['B!DX!N', 'B!DY!N', 'B!DZ!N','|B|'],ytitle=sc+'!CDFG!Csrvy',ysubtitle='DMPA [nT]',$
      colors=[2,4,6],labflag=-1,constant=0, cap=1
  endif

  ; V
  ;------------
  tn1 = tnames(sc+'_fpi_iBulkV_DSC',ct1)
  tn2 = tnames(sc+'_fpi_DISnumberDensity',ct2)
  if ct1*ct2 ne 1 then begin
    eva_data_load_mms_fpi, sc=sc
  endif

  ; Mach number
  ;------------
  tpN = sc+'_fpi_DISnumberDensity'
  tpB = sc+'_dfg_srvy_gsm_dmpa'
  tpV = sc+'_fpi_iBulkV_DSC
  tinterpol_mxn,tpB,tpN,newname=tpB+'_interp'; ....... interpolate
  get_data,tpB+'_interp',data=dataB,lim=limB, dl=dlB;........ geta data
  get_data,tpN,data=dataN,lim=limN,dl=dlN
  get_data,tpV,data=dataV,lim=limV,dl=dlV
  Ni = dataN.Y; cm^-3 ........................................ calculation
  Babs = sqrt(dataB.y[*,0]^2+dataB.y[*,1]^2+dataB.y[*,2]^2); nT
  Va = 22.0*Babs/sqrt(Ni)
  Vsw = sqrt(dataV.y[*,0]^2+dataV.y[*,1]^2+dataV.y[*,2]^2); km/s
  Ma = Vsw/Va
  store_data,sc+'_sw_Va',data={x:dataN.X, y:Va};............. output
  store_data,sc+'_sw_Vsw',data={x:dataN.X, y:Vsw}
  store_data,sc+'_sw_Ma',data={x:dataN.X, y:Ma}
  options,sc+'_sw_Ma',constant=1.,ytitle=sc+'!CMa'
  options,sc+'_sw_Va',ytitle=sc+'!CVa',ysubtitle='[km/s]'
  options,sc+'_sw_Vsw',ytitle=sc+'!CVsw',ysubtitle='[km/s]'
END
