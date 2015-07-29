
; for some reason, the JSON object returned by the server is
; an array of strings, with even indices (0, 2, 4, ..) containing
; file names (along with other JSON stuff) and odd indices (1, 3, 5, ..)
; containing file sizes (also along with other JSON stuff). This
; function parses out the filenames/filesizes from this array
; and returns an array of structs with the names and sizes
function mms_get_filename_size, json_object
    ; kludgy to deal with IDL's lack of a parser for json
    num_structs = n_elements(json_object)/2
    counter = 0
    remote_file_info = replicate({filename: '', filesize: 0l}, num_structs)

    for struct_idx = 0, n_elements(json_object)-1, 2 do begin
        ; even indices are filenames
        remote_file_info[counter].filename = (strsplit(json_object[struct_idx], '": "', /extract))[2]
        ; odd indices are filesizes
        remote_file_info[counter].filesize = (strsplit((strsplit(json_object[struct_idx+1], '": "', /extract))[1], '}', /extract))[0]
        counter += 1
    endfor
    return, remote_file_info
end