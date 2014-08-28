This directory contains the following:

1. spdfcdas - 25 Files

Release 1.7.10.6 of the CDAS Web Services IDL Library
<http://cdaweb.gsfc.nasa.gov/WebServices/REST/CdasIdlLibrary.html> 
that was deployed on March 5, 2014

Add the following to spdfcdawebchooser.pro: 
RESOLVE_ROUTINE, 'spdf_virtual_funcs', /COMPILE_FULL_FILE
also, commended tvimage since there is already a SPEDAS function with this name

2. spdf_cdawlib - 9 files

Modified version of CDAWlib
release 2014/03/03 
ftp://cdaweb.gsfc.nasa.gov/pub/software/cdawlib/source/

Modifications are the following:
a. Added spdf_ in front of the file names and changed any caps to lowercase
b. Changed the main function of each file to match the filename 
c. Added pro spdf_virtual_funcs at the end of spdf_virtual_funcs.pro
b. Removed pro BREAK_MYSTRING from spdf_read_mycdf.pro since there is already a separate file with this

Add the following to spdf_virtual_funcs.pro:
pro spdf_virtual_funcs 
end

3. For all the above files (25+9) the following text was replaced
for all occurrences (when spdf_ was not already present):

Before After
	
plotmaster    spdf_plotmaster
read_mycdf    spdf_read_mycdf
hsave_struct    spdf_hsave_struct
list_mystruct    spdf_list_mystruct
tagindex    spdf_tagindex
break_mystring    spdf_break_mystring
replace_bad_chars    spdf_replace_bad_chars
virtual_funcs	spdf_virtual_funcs
version    spdf_version (with care, only in spdfcdawebchooser.pro is needed)




	
	
	

