;*****************************************************************
;Subroutines
;*****************************************************************

;define IIR4 filter
;------------------
function IIR4, X, F
  result=long(3.*long(F/4) + long(X/4))
  return,result
end

function IIR2, X, F
  result=long(long(F/2) + long(X/2))
  return,result
end

function top12, X
  bitarray=bytarr(32)
  for i=0,31 do begin
    if 2.^(31-i) le X then begin
      bitarray(i)=1
      X=X mod 2.^(31-i)
    endif else bitarray(i)=0
  endfor
  array=bitarray*reverse(findgen(32))
  index=where(array eq max(array))
  if index(0) ge 20 then begin
    a1=bitarray(index(0):*)
    a2=array(index(0):*)
  endif else begin
    a1=bitarray(index(0):index(0)+11)
    a2=array(index(0):index(0)+11)
  endelse
  ;delibrate error
  index=where(a1 ne 0)
  a3=reverse(findgen(n_elements(a1)))
  if index(0) ne -1 then top12num=long(total(2.^(a3(index)))) else top12num=long(0)

  return,top12num
end

function top8, X
  bitarray=bytarr(32)
  for i=0,31 do begin
    if 2.^(31-i) le X then begin
      bitarray(i)=1
      X=X mod 2.^(31-i)
    endif else bitarray(i)=0
  endfor
  clippedarray=bitarray(20:27)
  index=where(clippedarray ne 0)
  a1=reverse(findgen(8))
  if index(0) eq -1 then top8num=0 else top8num=total(2.^(a1(index)))

  return,top8num
end

PRO mms_load_socs_magcap, sname; sname can be, for example, 'thb_fgs_gsm'
  get_data,  sname,data=D,limit=limit,dlimit=dlimit
  index = where(D.y gt 100. or D.y lt -100.)
  if (index[0] ne -1) then D.y[index] = float('NaN')
  store_data,sname,data={x:D.x,y:D.y},limit=limit, dlimit=dlimit
END

PRO eva_sitl_load_socs, probe=probe, input=input, pmdq=pmdq, filename=filename, $
  cdq_table = cdq_table, $
  mdq_table = mdq_table, $
  fom_table = fom_table

  @tplot_com.pro

  msn = 'th'; prefix to indicate mission name


  if ~keyword_set(filename) then filename = 'FOMStr_socs.sav'
  if ~keyword_set(input) then input='thm_archive'

  ; Specify which 4 probes should be used to calculate MDQs. No need to use this keyword for
  ; real MMS data. This keyword may be needed when using THEMIS data to generate MDQs.
  if ~keyword_set(pmdq)  then pmdq  = ['d','a','e','c']

  ; Specify which probe to be used to calculate TDNs and CDQs.
  if ~keyword_set(probe) then probe = ['d','a','e','c']

  prbs = probe
  pmax = n_elements(prbs)
  Npts = 8640L
  Ntdq = 32L
  ;///////////////////////// STEP 0: Load Tables ////////////////////////////////////
  if ~keyword_set(cdq_table) then begin
    weight = fltarr(Ntdq)
    offset = fltarr(Ntdq)
    weight[0] = 1.0
    cdq_table = {weight:weight, offset:offset}
  endif

  if ~keyword_set(mdq_table) then begin
    ; window array is multiplied to the four, sorted (in ascending order) data.
    ;win = [0.25,0.25,0.25,0.25]; average of the four spacecraft
    win = [0.10,0.20,0.30,0.40]; enhances the larger CDQ
    ;win = [0.00,0.00,0.00,1.00]; enhances the largest CDQ
    win /= total(win); normalize
    mdq_table = {window:win}
  endif

  if ~keyword_set(fom_table) then begin
    TargetBuffs = 360L; REQUIRED. (Long) The target number of 10s buffers to be selected.
    FOMAve      = 0   ; (FP) The current average FOM off-line.
    TargetRatio = 2   ; (FP) Only used if FOMAve is set. Allows selection as few as TargetBuffs/TargetRatio and as many as TargetBuffs*TargetRatio buffers.
    MinSegmentSize = 12 ; (Long) Default: 12 (Tail), Recommend:  6 (subsolar); Range: 1 to TargetBuffs allowed
    MaxSegmentSize = 60 ; (Long) Default: 60 (Tail), Recommend: 30 (subsolar); Range: 0 to >TargetBuffs allowed
    Pad            = 1  ; (Long) Default:  1 (Tail), Recommend:  0 (subsolar); Will add <Pad> buffers to begining and end of a segment so that the surrounding data can be kept.
    SearchRatio    = 1  ; (FP)   Default:  1 (Or TargetRatio if set); Range: 0.5 - 2.0; The ratio of TargetBuffs in the initial search. SearchBuffs = SearchRatio*TargetBuffs

    ;   FOMWindowSize    - OPTIONAL. (Long) The size, in number of 10 s buffers, of
    ;                      the FOM calculation window.
    ;                      DEFAULT: FOMWindowSize = MinSegemntSize-2*Pad
    ;                      RANGE: 1 to TargetBuffs allowed.
    ;                      NOTE: Making larger will favor large segment sizes.
    FOMWindowSize  = MinSegmentSize-2*Pad

    ;   FOMSlope         - OPTIONAL. (FP) Used in calculating FOM. 0 for averaging
    ;                      over a segment, 100 to weigh peaks higher.
    ;                      DEFAULT: 20
    ;                      RANGE: 0-100
    FOMSlope       = 20

    ;   FOMSkew          - OPTIONAL. (FP) Used in calculating FOM. 0 for averaging
    ;                      over a segment, 1 to weigh peaks higher.
    ;                      DEFAULT: 0 (Tail; See note)
    ;                      RECOMMEND: 0.5 (SubSolar)
    ;                      RANGE: 0-1
    ;                      NOTE: Set skew to low emphasize FOMBias
    FOMSkew        =  0.5

    ;   FOMBias          - OPTIONAL. (FP) Used in calculating FOM. 0 for favoring
    ;                      small segment, 1 for favoring large segemnts,
    ;                      DEFAULT: 1 (Tail; See note)
    ;                      RECOMMEND: 0.5 (SubSolar)
    ;                      RANGE: 0-1
    ;                      NOTE: FOMBias sets skew depending on segemnt size.
    FOMBias        =  0.5

    fom_table = {TargetBuffs:TargetBuffs, FOMAve:FOMAve, TargetRatio:TargetRatio, $
      MinSegmentSize:MinSegmentSize, MaxSegmentSize:MaxSegmentSize, Pad:Pad, SearchRatio:SearchRatio, $
      FOMWindowSize:FOMWindowSize, FOMSlope:FOMSlope, FOMSkew:FOMSkew, FOMBias:FOMBias}

  endif
  ;///////////////////////// STEP 1: TDN ////////////////////////////////////////////

  if strmatch(input, 'tdn_from_sc') then begin
    ;
    ; fetch TDN from SOC (To be coded later)
    ;
    ; set tstart
  endif

  if strmatch(input, 'thm_archive') then begin

    ; PREPARE tdn
    strdate = strmid(time_string(tplot_vars.options.trange[0]),0,10)
    tstart  = str2time(strdate); time [sec] since 00:00 of the day
    tdn_t   = 10.d*findgen(Npts) + tstart
    tdn_p   = fltarr(Npts, Ntdq, pmax); tdn from all probes combined
    tdn_v   = findgen(Ntdq)
    fake    = randomu(seed, Npts); this is used to fake TDN data

    ; Brms/|B|
    Mtdq  = 0
    coord = 'gsm'
    datatype = 'fgs'
    for p=0, pmax-1 do begin
      tpv = msn+prbs[p]+'_'+datatype+'_'+coord
      tn = tnames(tpv,c)
      if c ne 1 then thm_load_fgm,probe=prbs[p],level=2,coord=coord,verbose=1,datatype=datatype
      mms_load_socs_magcap, tpv
      get_data, tpv, data=D
      if n_tags(D) lt 2 then begin
        msg = tpv+' (to be used for TDN) is not available. MDQ/FOM will not be generated correctly.'
        rst = dialog_message(msg,/center)
      endif else begin
        BX     = D.y[*,0]
        BY     = D.y[*,1]
        BZ     = D.y[*,2]

        ;---------- Bob Ergun's sample program ----------
        dBx    = BX[1:*] - BX[0:*]
        dBy    = BY[1:*] - BY[0:*]
        dBz    = BZ[1:*] - BZ[0:*]
        db2    = dBx*dBx + dBy*dBy + dBz*dBz
        B2     = BX*BX + BY*BY + BZ*BZ
        trigR  = sqrt(dB2/B2)*100.d

        ;---------- THEMIS BZ Trigger ------------------
        scale_bz=30. ; (can play with different scale factor)
        q=top12((scale_bz)*BZ[0])  ;set first q value
        F=q       ;set IIR4 initial value
        NI=bytarr(n_elements(D.x)) ;initalize trigger value array
        NI(0)=0       ;set first trigger value
        for i=1,n_elements(D.x)-1 do begin
          q=top12((scale_Bz)*BZ(i))
          F=IIR4(q,F)
          NI(i)=top8(abs(q-F))
        endfor
        trigR = 10.0*NI
        ;------------------------------------------------------

        t      = D.x - tstart
        Nbuf   = floor(t/10.d); determine which buffer (each buffer is 10s) to add the value in
        for N=0,Npts-1 do begin; for each 10s buffer....
          temp = trigR[where(Nbuf eq N, count)]; extract 10s of data; if count=0, temp will be the last element of the data array
          csum = total(temp[reverse(sort(temp))],/cumulative); cumulative sum of the data in descending order
          if count ge 8 then begin
            tdn_p[N,Mtdq  ,p] = csum[7]/8.d; take 8 highest peaks and average (ignore if count < 8)
            tdn_p[N,Mtdq+1,p] = 1*tdn_p[N,Mtdq,p]; fake (to be deleted later)
            tdn_p[N,Mtdq+2,p] = 2*tdn_p[N,Mtdq,p]; fake (to be deleted later)
            tdn_p[N,Mtdq+3,p] = fake[N]*1.5*tdn_p[N,Mtdq,p]; fake (to be deleted later)
            tdn_p[N,Mtdq+4,p] = (1.d0-fake[N])*tdn_p[N,Mtdq,p]
            tdn_p[N,Mtdq+5,p] = (1.d0-fake[N])*tdn_p[N,Mtdq,p]
            tdn_p[N,Mtdq+6,p] = (1.d0-fake[N])*tdn_p[N,Mtdq,p]
            tdn_p[N,Mtdq+7,p] = (1.d0-fake[N])*tdn_p[N,Mtdq,p]
          endif else begin
            if (count gt 0 and count lt 8) then begin
              tdn_p[N,Mtdq  ,p] = csum[count-1]/count; take all and average
              tdn_p[N,Mtdq+1,p] = 1*tdn_p[N,Mtdq,p]; fake (to be deleted later)
              tdn_p[N,Mtdq+2,p] = 2*tdn_p[N,Mtdq,p]; fake (to be deleted later)
              tdn_p[N,Mtdq+3,p] = fake[N]*1.5*tdn_p[N,Mtdq,p]; fake (to be deleted later)
              tdn_p[N,Mtdq+4,p] = (1.d0-fake[N])*tdn_p[N,Mtdq,p]
              tdn_p[N,Mtdq+5,p] = (1.d0-fake[N])*tdn_p[N,Mtdq,p]
              tdn_p[N,Mtdq+6,p] = (1.d0-fake[N])*tdn_p[N,Mtdq,p]
              tdn_p[N,Mtdq+7,p] = (1.d0-fake[N])*tdn_p[N,Mtdq,p]
            endif
          endelse
        endfor; for N=0, Npts-1
      endelse; if n_tags
    endfor; for p=0,pmax-1

    ; Nrms/|N| (To be coded)

    ; Epara (To be coded)

    ; STORE tdn
    for p=0,pmax-1 do begin
      store_data,msn+prbs[p]+'_socs_tdn',data={x:tdn_t, y:tdn_p[*,*,p], v:tdn_v}
    endfor
  endif

  ;///////////////////////// STEP 2: CDQ ////////////////////////////////////////////

  if strmatch(input, 'cdq_from_sc') then begin
    ;
    ; fetch CDQ from SOC (To be coded later)
    ;
    ; set tstart
  endif else begin; create CDQ from TDN generated in STEP 1
    for p=0,pmax-1 do begin
      get_data,msn+prbs[p]+'_socs_tdn',data=D
      cdq = mms_burst_cdq(D.y, cdq_table.weight, cdq_table.offset)
      store_data,msn+prbs[p]+'_socs_cdq',data={x:D.x, y:cdq};, psym_hist:1} (see mplot)
      options,   msn+prbs[p]+'_socs_cdq','psym', 10
    endfor
  endelse


  ;///////////////////////// STEP 3: MDQ ////////////////////////////////////////////

  t1 = tnames(msn+pmdq[0]+'_socs_cdq',c1)
  t2 = tnames(msn+pmdq[1]+'_socs_cdq',c2)
  t3 = tnames(msn+pmdq[2]+'_socs_cdq',c3)
  t4 = tnames(msn+pmdq[3]+'_socs_cdq',c4)
  if c1 and c2 and c3 and c4 then begin
    get_data,t1, data=D1
    get_data,t2, data=D2
    get_data,t3, data=D3
    get_data,t4, data=D4
    mdq = mms_burst_mdq(D1.y, D2.y, D3.y, D4.y, window=mdq_table.window)
    store_data,msn+'s_socs_mdq',data={x:D1.x, y:mdq}
    options,   msn+'s_socs_mdq','psym', 10
  endif

  ;///////////////////////// STEP 4: FOM ////////////////////////////////////////////
  tn = tnames(msn+'s_socs_mdq', exist)
  if exist then begin
    print, 'EVA: creating FOM .... '
    get_data,msn+'s_socs_mdq',data=D

    ;generate FOMStr
    mms_burst_fom, D.y, TargetBuffs, FOMAve=fom_table.FOMAve, TargetRatio=fom_table.TargetRatio, $
      MinSegmentSize=fom_table.MinSegmentSize, $
      MaxSegmentSize=fom_table.MaxSegmentSize, Pad=fom_table.Pad, $
      SearchRatio=fom_table.SearchRatio, FOMWindowSize=fom_table.FOMWindowSize, $
      FOMSlope=fom_table.FOMSlope, FOMSkew=fom_table.FOMSkew, FOMBias=fom_table.FOMBias, $
      FOMStr=FOMStr
    unix_FOMStr = FOMStr
    numcycles=n_elements(D.x)
    str_element,/add,unix_FOMStr,'NumCycles',numcycles
    str_element,/add,unix_FOMStr,'TimeStamps',D.X; UNIX TIME
    str_element,/add,unix_FOMStr,'CycleStart',D.X[0]
    str_element,/add,unix_FOMStr,'AlgVersion','$Revision:1.5$'
    str_element,/add,unix_FOMStr,'SourceID',['mms_load_socs']
    str_element,/add,unix_FOMStr,'metadataevaltime',systime(/utc)
    ;unix_FOMStr.fom = (unix_FOMStr.fom < 256)
    mms_convert_fom_unix2tai, unix_FOMStr, FOMStr
    save, FOMStr, filename=filename

    fom   = fltarr(numcycles)
    for i=0,unix_FOMStr.nsegs-1 do begin; for each segment
      fom[unix_FOMStr.start[i]:unix_FOMStr.stop[i]] = unix_FOMStr.FOM[i]
    endfor
    store_data,msn+'s_socs_fom',data={x:D.x, y:fom}
    options,   msn+'s_socs_fom','psym', 10
  endif
END
