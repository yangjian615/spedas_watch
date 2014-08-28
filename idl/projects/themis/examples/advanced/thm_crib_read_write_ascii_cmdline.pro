
;+
; Name: thm_crib_read_write_ascii_cmdline
;
; Purpose:crib to demonstrate use of the read_ascii_cmdline and 
;    the write_ascii_cmdline IDL procedures
;
;
; SEE ALSO: idl/ssl_general/misc/write_ascii_cmdline.pro 
;           idl/ssl_general/misc/write_ascii.pro 
;           idl/ssl_general/misc/read_ascii_cmdline.pro
;           and read_ascii.pro in the lib subdirectory of the idl distribution
;
; To run type 'thm_crib_read_write_ascii_cmdline'
; 
;-

PRO thm_crib_read_write_ascii_cmdline
 

    ;**************************************************************
    ; This section shows examples of writing ascii files
    ;**************************************************************

    ; create some data to write
    data = dindgen(3,10)
    filename = 'test_simple.txt'
        
    ; simplest example of writing data. 
    ; in this case there is no header information and data is an array of 
    ; double precision data
    print, ' '
    print, 'Start of examples to write ascii data.'
    print, 'Note: Files written by write_ascii_cmdline will be examined '
    print, '      more closely in the read ascii section of this crib.'
    print, 'Example 1 - writing a simple array of data.'
    write_ascii_cmdline, data, filename
    print, 'Type .c to continue.'
    print, ' '
    stop
    
    ; same as above but includes header
    filename = 'test_header.txt'
    header = ['This is a sample header', 'It is an array of strings']
    print, 'Example 2 - writing a simple array of data with header information.'
    write_ascii_cmdline, data, filename, header=header
    print, 'Type .c to continue.'
    print, ' '
    stop    

    ; same as above but includes a count of the records written to the 
    ; file
    filename='test_nrec.txt'
    print, 'Example 3 - writing data and header and checking the number of records written.'
    write_ascii_cmdline, data, filename, header=header, nrec=nrec
    print, 'The number of data records written to the file is: ', nrec
    print, 'The number of records includes only the data and not the header.'
    print, 'In this example the number of records should be 10.'
    print, 'Type .c to continue.'
    print, ' '
    stop    

    ; This example shows writing an ascii file using a data structure
    ; The data structure is of the form returned by read_ascii.
    ; Ex:
    ; {field01:[col1], field02:[col2], ...} where colx is a 1-D array of
    ; nrows. All colx's must be of the same size or nrows.  
    filename= 'test_struc.txt'
    dates = ['2008-12-27','2008-12-28','2008-12-29','2008-12-30','2008-12-31'] 
    sdata = {date:dates, x:data[0,0:4], y:data[1,0:4], z:data[2,0:4]}
    print, 'Example 4 - writing a data structure
    write_ascii_cmdline, sdata, filename, header=header, nrec=nrec 
    print, 'The number of data records written from the data structure is: ', nrec
    print, 'In this example the number of records should be 5.'
    print, ' '
    print, 'Done with writing ascii examples.'
    print, 'Type .c to continue.'
    print, ' '
    stop
        
    ;**************************************************************
    ; This section shows examples of reading ascii files
    ;**************************************************************
    
    ; Read the simple test file created with a 3x10 double precision array.
    ; This file does not have header information
    print, 'Reading example 1 - simple data array
    data = read_ascii_cmdline('test_simple.txt')
    print, 'The data structure returned should have 3 fields (or columns)'
    print, 'and each field is a 1-d array of floats of length 10.'
    help, data, /struc
    print, 'Type .c to continue.'
    print, ' '
    stop
    
    ; Read the simple test file that has header information. In this case the
    ; starting line of data must be specified.
    print, 'Read example 2 - simple data array with header information.'
    data = read_ascii_cmdline('test_header.txt', start_line=2)
    print, 'The results should be the same as noted in the previous example.'
    help, data, /struc
    print, 'Type .c to continue.'
    print, ' '
    stop
    
    ; Read the simple test file that has header information and return the 
    ; header along with the data structure.
    print, 'Read example 2 - simple data array this time returning the header information.'
    data = read_ascii_cmdline('test_header.txt', start_line=2, header=header)
    print, 'The header information returned is: '
    print, header[0]
    print, header[1]
    print, 'Type .c to continue.'
    print, ' '
    stop
    
    ; Read the test file that used a data structure. 
    print, 'Read example 4 - a file that was written with a data structure.'
    data = read_ascii_cmdline('test_struc.txt', start_line=2, header=header)
    print, 'The data structure returned should be four fields of type float of length 5.'
    help, data, /struc
    print, 'Note that the first tag within the structure is of type float even though'
    print, 'the data type written to the file was of type string.'
    print, 'If the data structure contains different data types and no data type parameter'
    print, 'is provided the procedure will default to float.'
    print, 'Type .c to continue.'
    print, ' '
    stop
    
    ; Read the test file that used a data structure and provide field type 
    ; information
    print, 'Read example 4 - data structure with field data types defined.'
    field_types = ['string', 'double', 'double', 'double'] 
    data = read_ascii_cmdline('test_struc.txt', start_line=2, header=header, field_types=field_types)
    print, 'When field type information is provided the data structure should contain'
    print, 'data types defined by field_types = [string, double, double, double]:'
    help, data, /struc
    print, 'Type .c to continue.'
    print, ' '
    stop
        
    ; Read the test file that used a data structure and provide field type 
    ; information specified as a IDL data type (long)
    print, 'Read example 4 - data structure with data types defined by an array of longs.'
    field_types = Long([7,5,5,5]) 
    data = read_ascii_cmdline('test_struc.txt', start_line=2, header=header, field_types=field_types)
    print, 'In IDL data types can be defined by a variable of type long. See IDL documentation.'
    print, 'In this example the data structure types should match the previous example.'
    help, data, /struc
    print, 'Type .c to continue.'
    print, ' '
    stop
    
    ; Read the test file using a data structure and provide field types and 
    ; field names. The routine defaults to field names field01, field02, etc...
    ; The user can provide an array of strings containing the names of each
    ; field.
    print, 'Read example 4 - data structure, and specifying field types and field names.'
    field_names=['date', 'x', 'y', 'z']
    data = read_ascii_cmdline('test_struc.txt', start_line=2, header=header, $
           field_types=field_types, field_names=field_names)
    print, 'The data structure returned should now contains the names defined by the parameter'
    print, 'field_names=[date, x, y, z].'
    help, data, /struc
    print, ' '
    print, 'This is the end of the read ascii examples'
    print, ' ' 
    print, 'NOTE:
    print, 'The read_ascii_cmdline can also take an ascii template structure as a parameter.'
    print, 'Ascii template structures can be generated by the IDL GUI ascii_template.'
    print, 'For Example:   myTemplate = ascii_template(filename)
    print, '               data=read_ascii_cmdline(filename, template=myTemplate)
    print, 'See ascii_template and/or read_ascii for more details.'
    print, 'Type .c to exit the procedure.'  
    print, ' '     
    stop
    
END