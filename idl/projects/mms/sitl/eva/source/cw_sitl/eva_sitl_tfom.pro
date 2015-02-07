FUNCTION eva_sitl_tfom, unix_FOMstr
  tfom = [unix_FOMstr.timestamps[0], unix_FOMstr.timestamps[unix_FOMstr.NUMCYCLES-1]+10.d0]
  return, tfom
END