function func,x,y,z,parameter=p
;on_error,2
;common func_com,func_parameter
;ptype = size(p,/type)
;valid = (ptype eq 8 or ptype eq 7)
;if not valid then p=func_parameter
;if not keyword_set(x) then x=dgen()
if ~keyword_set(p) then begin
   dprint,'No function or parameter defined'
   return,0
endif
if n_params() eq 0 then f = (size(/type,p) eq 8) ? call_function(p.func,param=p) : call_function(p)
if n_params() eq 1 then f = (size(/type,p) eq 8) ? call_function(p.func,x,param=p) : call_function(p,x)
if n_params() eq 2 then f = (size(/type,p) eq 8) ? call_function(p.func,x,y,param=p) : call_function(p,x,y)
if n_params() eq 3 then f = (size(/type,p) eq 8) ? call_function(p.func,x,y,z,param=p) : call_function(p,x,y,z)
;if valid then func_parameter=p
return,f
end
