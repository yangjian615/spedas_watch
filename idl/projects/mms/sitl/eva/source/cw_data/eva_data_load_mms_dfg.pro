PRO eva_data_load_mms_dfg, sc=sc
  
  mms_sitl_get_dfg, sc=sc
  
  eva_cap,sc+'_dfg_srvy_gsm_dmpa',max=150.
  options,sc+'_dfg_srvy_gsm_dmpa',$
    labels=['B!DX!N', 'B!DY!N', 'B!DZ!N'],ytitle=sc+'!CDFG!Cgsm',ysubtitle='[nT]',$
    colors=[2,4,6],labflag=-1,constant=0
  
  eva_cap,sc+'_dfg_srvy_dmpa',max=150.
  options,sc+'_dfg_srvy_dmpa',$
    labels=['B!DX!N', 'B!DY!N', 'B!DZ!N'],ytitle=sc+'!CDFG!Cdmpa',ysubtitle='[nT]',$
    colors=[2,4,6],labflag=-1,constant=0
END
