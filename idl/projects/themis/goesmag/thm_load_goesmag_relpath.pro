; goes-specific helper function
; to return relative path names to files in the data tree.
; this routine maps datatypes to file type.
function thm_load_goesmag_relpath, sname=probe, filetype=ft, $
                               level=lvl, trange=trange, $
                               addmaster=addmaster, _extra=_extra

  relpath = probe+'/'+lvl+'/'
  prefix = probe+'_'+lvl+'_'+ft+'_'
  dir = 'YYYY/MM/'

  ending = '_v00.cdf'

  return, file_dailynames(relpath, prefix, ending, dir=dir, $
                          trange = trange,addmaster=addmaster)
end
