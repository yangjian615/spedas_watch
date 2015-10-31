mms_init

;timespan,'2015-09-19/09:05:00', 6, /min
;timespan,'2015-09-19/07:40:00', 5, /min
timespan,'2015-10-03/14:45', 5, /min

iread=1

i_tshift=1

probe_id=3
sc_id='mms'+string(probe_id,format='(I1)')


if iread eq 1 then begin

mms_load_data, instrument='fpi',probes=probe_id, datatype='dis-moms', level='l1b', data_rate='brst'
mms_load_data, instrument='fpi',probes=probe_id, datatype='des-moms', level='l1b', data_rate='brst'
mms_load_data, instrument='dfg',probes=probe_id, datatype='', level='l2pre', data_rate='brst'
mms_load_data, instrument='edp',probes=probe_id, level='ql', data_rate='fast', datatype='dce'
endif

;timespan,'2015-09-19/09:08:00', 3, /min

copy_data,sc_id+'_dis_numberDensity','Ni_orig'
copy_data,sc_id+'_dis_bulkSpeed','Vi_mag_orig'
copy_data,sc_id+'_dis_bulkX','Vix_orig'
copy_data,sc_id+'_dis_bulkY','Viy_orig'
copy_data,sc_id+'_dis_bulkZ','Viz_orig'

copy_data,sc_id+'_dis_numberDensity','Ni'
copy_data,sc_id+'_dis_bulkSpeed','Vi_mag'
copy_data,sc_id+'_dis_bulkX','Vix'
copy_data,sc_id+'_dis_bulkY','Viy'
copy_data,sc_id+'_dis_bulkZ','Viz'

get_data,'Vix',data=vx
get_data,'Viy',data=vy
get_data,'Viz',data=vz
v=fltarr(n_elements(vx.x),3)
v(*,0)=vx.y
v(*,1)=vy.y
v(*,2)=vz.y
store_data,'Vi',data={x:vx.x,y:v}

get_data,'Vix_orig',data=vx
get_data,'Viy_orig',data=vy
get_data,'Viz_orig',data=vz
v=fltarr(n_elements(vx.x),3)
v(*,0)=vx.y
v(*,1)=vy.y
v(*,2)=vz.y
store_data,'Vi_orig',data={x:vx.x,y:v}

copy_data,sc_id+'_des_numberDensity','Ne_orig'
copy_data,sc_id+'_des_bulkSpeed','Ve_mag_orig'
copy_data,sc_id+'_des_bulkX','Vex_orig'
copy_data,sc_id+'_des_bulkY','Vey_orig'
copy_data,sc_id+'_des_bulkZ','Vez_orig'

copy_data,sc_id+'_des_numberDensity','Ne'
copy_data,sc_id+'_des_bulkSpeed','Ve_mag'
copy_data,sc_id+'_des_bulkX','Vex'
copy_data,sc_id+'_des_bulkY','Vey'
copy_data,sc_id+'_des_bulkZ','Vez'

get_data,'Vex',data=vx
get_data,'Vey',data=vy
get_data,'Vez',data=vz
v=fltarr(n_elements(vx.x),3)
v(*,0)=vx.y
v(*,1)=vy.y
v(*,2)=vz.y
store_data,'Ve',data={x:vx.x,y:v}

get_data,'Vex_orig',data=vx
get_data,'Vey_orig',data=vy
get_data,'Vez_orig',data=vz
v=fltarr(n_elements(vx.x),3)
v(*,0)=vx.y
v(*,1)=vy.y
v(*,2)=vz.y
store_data,'Ve_orig',data={x:vx.x,y:v}

store_data,'V',data=['Vi','Ve']

copy_data,sc_id+'_edp_dce_xyz_dsl','E'
copy_data,sc_id+'_dfg_brst_l2pre_dmpa','B'

;extract B data from the 4 element vector
get_data,'B',data=d
store_data,'B',data={x:d.x,y:d.y(*,0:2)}
store_data,'Bmag',data={x:d.x,y:d.y(*,3)}

;This does not work when there are gaps between burst segments
;get_data,'Ni',data=d
;time_diff_array=d.x(1:n_elements(d.x)-1)-d.x(0:n_elements(d.x)-2)
;median, time_diff_array, n_elements(var), dt_dis

dt_dis=0.15d


var_dis=['Ni','Vi_mag','Vi']
for i=0, n_elements(var_dis)-1 do begin
get_data,var_dis(i),data=d
store_data,var_dis(i),data={x:d.x+double(dt_dis)/2.d,y:d.y}
endfor


;This does not work when there are gaps between burst segments
;get_data,'Ne',data=d
;time_diff_array=d.x(1:n_elements(d.x)-1)-d.x(0:n_elements(d.x)-2)
;median, time_diff_array, n_elements(var), dt_des

dt_des=0.03d



var_dis=['Ne','Ve_mag','Ve']
for i=0, n_elements(var_dis)-1 do begin
get_data,var_dis(i),data=d
store_data,var_dis(i),data={x:d.x+double(dt_des)/2.d,y:d.y}
endfor

;store_data,'VVi',data=['Vi','Vi_orig']
;options,'Vi_orig','psym',-2

;store_data,'VVe',data=['Ve','Ve_orig']
;options,'Ve_orig','psym',-2


if i_tshift eq 1 then begin
copy_data,'Vi','VVi'
copy_data,'Ve','VVe'
endif else begin
copy_data,'Vi_orig','VVi'
copy_data,'Ve_orig','VVe'
endelse



box_ave_mms, variable1='VVi', variable2='B', var2ave='B_dis';, start_time= '2015-09-19/09:08:40',end_time='2015-09-19/09:11'

box_ave_mms, variable1='VVe', variable2='B', var2ave='B_des';,start_time= '2015-09-19/09:08:40',end_time='2015-09-19/09:11'

store_data,'B_i',data=['B','B_dis']
store_data,'B_e',data=['B','B_des']
options,'B_dis','colors',[2,4,6]
options,'B_dis','psym',10
options,'B_des','colors',[2,4,6]
options,'B_des','psym',10

get_data,'E',data=d
store_data,'Ex',data={x:d.x,y:d.y(*,0)}
store_data,'Ey',data={x:d.x,y:d.y(*,1)}
store_data,'Ez',data={x:d.x,y:d.y(*,2)}


get_data,'VVi',data=v
get_data,'B_dis',data=b

cross_prod=-crossn3(v.y, b.y)
num=float(n_elements(b.x))
v_cross_b=fltarr(num,3)

for i=0.,num-1 do begin
	v_cross_b(i,0)=1e-3*cross_prod(i,0)
	v_cross_b(i,1)=1e-3*cross_prod(i,1)
	v_cross_b(i,2)=1e-3*cross_prod(i,2)
endfor

store_data,'vixB_efield',data={x:v.x,y:v_cross_b}
store_data,'vixB_Ex',data={x:b.x,y:v_cross_b(*,0)}
store_data,'vixB_Ey',data={x:b.x,y:v_cross_b(*,1)}
store_data,'vixB_Ez',data={x:b.x,y:v_cross_b(*,2)}

options,'vixB_Ex','colors',6
options,'vixB_Ey','colors',6
options,'vixB_Ez','colors',6

store_data,'Exi',data=['Ex','vixB_Ex']
store_data,'Eyi',data=['Ey','vixB_Ey']
store_data,'Ezi',data=['Ez','vixB_Ez']

;electrons

get_data,'VVe',data=v
get_data,'B_des',data=b

cross_prod=-crossn3(v.y, b.y)
num=float(n_elements(b.x))
v_cross_b=fltarr(num,3)

for i=0.,num-1 do begin
	v_cross_b(i,0)=1e-3*cross_prod(i,0)
	v_cross_b(i,1)=1e-3*cross_prod(i,1)
	v_cross_b(i,2)=1e-3*cross_prod(i,2)
endfor

store_data,'vexB_efield',data={x:v.x,y:v_cross_b}
store_data,'vexB_Ex',data={x:b.x,y:v_cross_b(*,0)}
store_data,'vexB_Ey',data={x:b.x,y:v_cross_b(*,1)}
store_data,'vexB_Ez',data={x:b.x,y:v_cross_b(*,2)}

options,'vexB_Ex','colors',6
options,'vexB_Ey','colors',6
options,'vexB_Ez','colors',6

store_data,'Exe',data=['Ex','vexB_Ex']
store_data,'Eye',data=['Ey','vexB_Ey']
store_data,'Eze',data=['Ez','vexB_Ez']

tplot_options,'ygap',0.3

!p.charsize=0.7

ylim,'V',-300,300,0

tplot,['B','Ni','V','VVi','VVe','Exi','Eyi','Ezi','Exe','Eye','Eze'],title=sc_id

;tplot,['B','Ni','V','VVi','Vi_orig','VVe','Ve_orig','Exi','Eyi','Ezi','Exe','Eye','Eze'],title=sc_id

print,'dt DIS= ',dt_dis
print,'dt DES= ',dt_des

stop

end



