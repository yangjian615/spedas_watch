PRO eva_data_load_mms_fpi_ql, sc=sc

  mms_sitl_fpi_moments, sc = sc, /clean
  
  options,sc+'_fpi_density',ytitle=sc+'!CFPI!Cdns',ysubtitle='[cm!U-3!N]',labels=['Ni','Ne'],labflag=-1,ylog=0
  options,sc+'_fpi_temp',ytitle=sc+'!CFPI!Ctemp',ysubtitle='[eV]',ylog=0
  options,sc+'_fpi_ion_vel_dbcs',ytitle=sc+'!CFPIi!Cvel',constant=0
  options,sc+'_fpi_elec_vel_dbcs',ytitle=sc+'!CFPIe!Cvel',constant=0
  options,sc+'_fpi_ions',ytitle=sc+'!CFPIi';,ysubtitle='[Hz]',ztitle='[(V/m)!U2!N/Hz]'
  options,sc+'_fpi_electrons',ytitle=sc+'!CFPIe'
  options,sc+'_fpi_epad_lowen_fast',ytitle=sc+'!CFPIe!Clow'
  options,sc+'_fpi_epad_miden_fast',ytitle=sc+'!CFPIe!Cmid'
  options,sc+'_fpi_epad_highen_fast',ytitle=sc+'!CFPIe!Chigh'

END
