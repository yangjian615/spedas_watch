; This procedure only defines the mask
;so that 8 and 16 bit numbers can be 
;quickly decomutated

pro mvn_lpw_r_mask,mask16,mask8,bin_c,index_arr,flip_8


;mask(number , the 16 bit word where index 0 is the LS bit)    
 
 mask16=[[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0], $ 
         [0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,1]]   ;2 x 16
for i=1,15 do begin       
mask16=[mask16,mask16]  ;4 x 16
mask16(2L^i:2L^(i+1)-1,15-i)=1
endfor          


 mask8=[[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,1]]   ;2 x 8
for i=1,7 do begin       
mask8=[mask8,mask8]  ;4 x 16
mask8(2^i:2^(i+1)-1,7-i)=1
endfor          



bin_c=2.^indgen(32)

index_arr=indgen(32)

; to flip the 8 values

flip_8=[7-indgen(8)+8,7-indgen(8)]

;flip_8=15-indgen(16)


end


