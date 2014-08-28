;+
;WIDGET Procedure:
;  RECORDER
;PURPOSE:
; Widget tool that records streaming data from a server (host) and can save it to a file
; or send to a user specified routine. This tool runs in the background.
; Author:
;    Davin Larson - April 2011
;
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2014-02-02 16:52:16 -0800 (Sun, 02 Feb 2014) $
; $LastChangedRevision: 14125 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tools/misc/recorder.pro $
;
;-

PRO recorder_event, ev   ; recorder

    widget_control, ev.top, get_uvalue= info   ; get all widget ID's
    wids = info.wids
    localtime=1

    CASE ev.id OF                         ;  Timed events
    wids.base:  begin
        if info.hfp gt 0 then begin
            eofile =0
            treceived = systime(1)
            buffer= bytarr(info.maxsize)  ; uintarr(info.maxsize)
            b=buffer[0]
            for i=0L,n_elements(buffer)-1 do begin
                flag = file_poll_input(info.hfp,timeout=0)
                if flag eq 0 then break
                if eof(info.hfp) then begin
                    widget_control,wids.host_text,get_value=hostname
                    widget_control,wids.host_port,get_value=hostport
                    dprint,dlevel=1,'Connection to Host: '+hostname[0]+':'+hostport[0]+' broken. ',i
                    eofile = 1
                    break
                endif
                readu,info.hfp,b
                buffer[i] = b
            endfor
            if i gt 0 then begin
                buffer = buffer[0:i-1]
                if keyword_set(info.dfp) then writeu,info.dfp, buffer  ;swap_endian(buffer,/swap_if_little_endian)
                flush,info.dfp
;                printdat,/hex,buffer,output=msg
                msg = string(/print,i,buffer[0:(i < 128)-1],format='(i5 ," bytes: ", 128(" ",Z02))')
                msg = time_string(treceived,tformat='hh:mm:ss - ',local=localtime) + msg
;                if widget_info(/button_set,wids.proc_button) then begin
;                    widget_control,wids.proc_name,get_value = proc_name
;                    if keyword_set(proc_name) then call_procedure,proc_name[0],buffer,time=treceived
;                endif
            endif else begin
                buffer=0
                msg =time_string(treceived,tformat='hh:mm:ss - No data available',local=localtime)
            endelse
                if widget_info(/button_set,wids.proc_button) then begin
                    widget_control,wids.proc_name,get_value = proc_name
                    if keyword_set(proc_name) then call_procedure,proc_name[0],buffer,time=treceived
                endif
            widget_control,wids.output_text,set_value=msg
            dprint,dlevel=5,msg,/no_check
            widget_control,wids.poll_int,get_value = poll_int
            poll_int = float(poll_int)
            if 1 then begin
                poll_int = poll_int - (systime(1) mod poll_int)  ; sample on regular boundaries
            endif

            if not keyword_set(eofile) then WIDGET_CONTROL, wids.base, TIMER=poll_int else widget_control,wids.host_button,timer=2
        endif
        return
    end
    wids.host_button : begin
        widget_control,ev.id,get_value=status
        widget_control,wids.host_text, get_value=server_name
        widget_control,wids.host_port, get_value=server_port
        server_n_port = server_name+':'+server_port
        case status of
        'Connect to': begin
            WIDGET_CONTROL, ev.id, set_value = 'Connecting',sensitive=0
            WIDGET_CONTROL, wids.host_text, sensitive=0
            WIDGET_CONTROL, wids.host_port, sensitive=0
            dprint,dlevel=2,'Opening server:','"'+server_n_port+'"'
            socket,hfp,/get_lun,server_name,fix(server_port),error=error ,/swap_if_little_endian,connect_timeout=10
            if keyword_set(error) then begin
                dprint,dlevel=0,!error_state.msg   ;strmessage(error)
                widget_control, wids.output_text, set_value=!error_state.msg
                WIDGET_CONTROL, ev.id, set_value = 'Failed:',sensitive=1
                WIDGET_CONTROL, wids.host_text, sensitive=1
                WIDGET_CONTROL, wids.host_port, sensitive=1
            endif else begin
                info.hfp = hfp
                WIDGET_CONTROL, wids.base, TIMER=1    ; , set_uvalue=hfp
                WIDGET_CONTROL, ev.id, set_value = 'Disconnect',sensitive=1
            endelse
        end
        'Disconnect': begin
            WIDGET_CONTROL, ev.id, set_value = 'Closing'  ,sensitive=0
            WIDGET_CONTROL, wids.host_text, sensitive=1
            WIDGET_CONTROL, wids.host_port, sensitive=1
            msg = 'Disconnected from server:"'+server_n_port+'"'
            widget_control, wids.output_text, set_value=msg
            dprint,dlevel=2,msg
            free_lun,info.hfp
            info.hfp =0
            wait,1
            WIDGET_CONTROL, ev.id, set_value = 'Connect to',sensitive=1
        end
        else: begin
            WIDGET_CONTROL, wids.host_text, sensitive=1
            WIDGET_CONTROL, wids.host_port, sensitive=1
            WIDGET_CONTROL, ev.id, set_value = 'Connect to',sensitive=1
            dprint,'Error Recovery'
        end
        endcase
    end
    wids.dest_button: begin
        widget_control,ev.id,get_value=status

        widget_control,wids.dest_text, get_value=filename
        case status of
        'Write to': begin
            if keyword_set(info.dfp) then begin
                free_lun,info.dfp
                info.dfp = 0
            endif
            WIDGET_CONTROL,   ev.id       , set_value = 'Opening' ,sensitive=0
            widget_control, wids.dest_text, get_value = fileformat,sensitive=0
            filename = time_string(systime(1),tformat = fileformat[0])
            widget_control, wids.dest_text, set_uvalue = fileformat,set_value=filename
            if keyword_set(filename) then begin
                dprint,dlevel=3,'Opening file: ',filename
                file_open,'u',filename, unit=dfp,dlevel=4
                info.dfp = dfp
                info.filename= filename
                widget_control, wids.dest_flush, sensitive=1
            endif
;              wait,1
            WIDGET_CONTROL, ev.id, set_value = 'Close   ',sensitive =1
        end
        'Close   ': begin
            WIDGET_CONTROL, ev.id,          set_value = 'Closing',sensitive=0
            widget_control, wids.dest_flush, sensitive=0
            widget_control, wids.dest_text ,get_uvalue= fileformat,get_value=filename
            if info.dfp gt 0 then begin
                free_lun,info.dfp
                info.dfp =0
            endif
;            wait,1
            widget_control, wids.dest_text ,set_value= fileformat,sensitive=1
            WIDGET_CONTROL, ev.id, set_value = 'Write to',sensitive=1
            dprint,dlevel=3,'Closing file:',filename,no_check_events=1
        end
        else: begin
            dprint,'Invalid State'
        end
        endcase
    end
    wids.dest_flush: begin
        widget_control, wids.dest_text ,get_uvalue= fileformat,get_value=filename
        if info.dfp gt 0 then begin
            free_lun,info.dfp
            info.dfp =0
            info.filename= ''
        endif
        dprint,dlevel=3,'Closed file:',filename,get_check_events=cev,check_events=0
;        wait,1
        filename = time_string(systime(1),tformat = fileformat[0])
        widget_control, wids.dest_text, set_uvalue = fileformat,set_value=filename
        if keyword_set(filename) then begin
            file_open,'u',filename, unit=dfp,dlevel=4
            info.dfp = dfp
            info.filename= filename
            widget_control, wids.dest_flush, sensitive=1
        endif
        dprint,dlevel=3,'Opened file: '+info.filename,check_events=cev
        flush,info.dfp
    end
;    wids.host_text:  begin
;        widget_control,ev.id,get_value=value
;        dprint,'"'+value+'"'
;    end
    wids.proc_button: begin
;      printdat,ev & savetomain,ev
      widget_control,wids.proc_name,get_value=proc_name
      widget_control,wids.proc_name,sensitive = (ev.select eq 0)
      info.run_proc = ev.select
    end
    wids.done: begin   ;    'DONE' ;  close files here!
        if info.hfp gt 0 then begin
            fs = fstat(info.hfp)
            dprint,dlevel=1,'Closing '+fs.name
            free_lun,info.hfp
        endif
        if info.dfp gt 0 then begin
            fs = fstat(info.dfp)
            dprint,dlevel=1,'Closing '+fs.name
            free_lun,info.dfp
        endif
        WIDGET_CONTROL, ev.TOP, /DESTROY
        return
    end
    else: begin
        msg = string('Base ID is: ',wids.base)
        widget_control, wids.output_text, set_value=msg
        dprint,msg
        printdat,ev
        printdat,info
    end
    ENDCASE
    widget_control,wids.base,set_uvalue=info
END


PRO exec_proc_template,buffer,time=time
;    savetomain,buffer
;    savetomain,time

    dprint,/phelp,buffer,time_string(time)

    return
end





PRO recorder,base,ids=ids,host=host,port=port,destination=destination,exec_proc=exec_proc, $
          get_procbutton = get_procbutton,set_procbutton=set_procbutton, $ ;,directory=directory
          get_filename=get_filename
if ~(keyword_set(base) && widget_info(base,/managed) ) then begin
    if not keyword_set(host) then host = 'localhost'
    if not keyword_set(port) then port = '2022'
    port=strtrim(port,2)
    if not keyword_set(destination) then destination = 'STREAM_YYYYMMDD_hhmmss.dat'
    ids = create_struct('base', WIDGET_BASE(/COLUMN, title='Stream Recorder' ) )
    ids = create_struct(ids,'host_base',   widget_base(ids.base,/row, uname='HOST_BASE') )
    ids = create_struct(ids,'host_button', widget_button(ids.host_base, uname='HOST_BUTTON',value='Connect to') )
    ids = create_struct(ids,'host_text',   widget_text(ids.host_base,  uname='HOST_TEXT' ,VALUE=host ,/EDITABLE ,/NO_NEWLINE ) )
    ids = create_struct(ids,'host_port',   widget_text(ids.host_base,  uname='HOST_PORT',xsize=6, value=port   , /editable, /no_newline))
    ids = create_struct(ids,'poll_int' ,   widget_text(ids.host_base,  uname='POLL_INT',xsize=6,value='1',/editable,/no_newline))
;  if n_elements(directory) ne 0 then $
;    ids = create_struct(ids,'destdir_text',   widget_text(ids.base,  uname='DEST_DIRECTORY',xsize=40 ,/EDITABLE ,/NO_NEWLINE  ,VALUE=directory))
    ids = create_struct(ids,'dest_base',   widget_base(ids.base,/row, uname='DEST_BASE'))
    ids = create_struct(ids,'dest_button', widget_button(ids.dest_base, uname='DEST_BUTTON',value='Write to'))
    ids = create_struct(ids,'dest_text',   widget_text(ids.dest_base,  uname='DEST_TEXT',xsize=40 ,/EDITABLE ,/NO_NEWLINE  ,VALUE=destination))
    ids = create_struct(ids,'dest_flush',  widget_button(ids.dest_base,uname='DEST_FLUSH', value='Flush' ,sensitive=0))
    ids = create_struct(ids,'output_text', WIDGET_TEXT(ids.base, uname='OUTPUT_TEXT'))
;  if n_elements(exec_proc) ne 0 then begin
    ids = create_struct(ids,'proc_base',   widget_base(ids.base,/row, uname='PROC_BASE'))
    ids = create_struct(ids,'proc_base2',  widget_base(ids.proc_base ,/nonexclusive))
    ids = create_struct(ids,'proc_button', widget_button(ids.proc_base2,uname='PROC_BUTTON',value='Procedure:'))
    ids = create_struct(ids,'proc_name',   widget_text(ids.proc_base,xsize=35, uname='PROC_NAME', value = exec_proc,/editable, /no_newline))
;  endif
    ids = create_struct(ids,'done',        WIDGET_BUTTON(ids.base, VALUE='Done', UNAME='DONE'))
    info = {wids:ids, $
;      hostname:host, hostport:port, $
        hfp:0,  $
        fileformat:destination,  filename:'', $
        dfp:0 ,maxsize:2L^18, $
        pollinterval:1., $
        run_proc:1 }
    WIDGET_CONTROL, ids.base, SET_UVALUE=info
    WIDGET_CONTROL, ids.base, /REALIZE
    title = 'Stream Recorder ('+strtrim(ids.base,2)+')'
    widget_control, ids.base, base_set_title=title
    XMANAGER, 'recorder', ids.base,/no_block
    dprint,dlevel=2,'Started: '+title
    base = ids.base
endif else begin
    widget_control, base, get_uvalue= info   ; get all widget ID's
    ids = info.wids
    if size(/type,exec_proc) eq 7 then begin
        widget_control,ids.proc_name,set_value=exec_proc
    endif
endelse
get_procbutton = widget_info(ids.proc_button,/button_set)
widget_control,ids.dest_text,get_value=get_filename
get_filename = keyword_set(info.dfp) ? get_filename[0] : ''
;printdat,info
if n_elements(set_procbutton) eq 1 then widget_control,ids.proc_button,set_button=set_procbutton


END
