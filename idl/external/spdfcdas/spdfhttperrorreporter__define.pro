;
; NOSA HEADER START
;
; The contents of this file are subject to the terms of the NASA Open 
; Source Agreement (NOSA), Version 1.3 only (the "Agreement").  You may 
; not use this file except in compliance with the Agreement.
;
; You can obtain a copy of the agreement at
;   docs/NASA_Open_Source_Agreement_1.3.txt
; or 
;   https://cdaweb.gsfc.nasa.gov/WebServices/NASA_Open_Source_Agreement_1.3.txt.
;
; See the Agreement for the specific language governing permissions
; and limitations under the Agreement.
;
; When distributing Covered Code, include this NOSA HEADER in each
; file and include the Agreement file at 
; docs/NASA_Open_Source_Agreement_1.3.txt.  If applicable, add the 
; following below this NOSA HEADER, with the fields enclosed by 
; brackets "[]" replaced with your own identifying information: 
; Portions Copyright [yyyy] [name of copyright owner]
;
; NOSA HEADER END
;
; Copyright (c) 2010-2017 United States Government as represented by the 
; National Aeronautics and Space Administration. No copyright is claimed 
; in the United States under Title 17, U.S.Code. All Other Rights Reserved.
;
;

;+
; This class represents an object that is used to report HTTP errors.
;
; @copyright Copyright (c) 2010-2017 United States Government as represented
;     by the National Aeronautics and Space Administration. No
;     copyright is claimed in the United States under Title 17,
;     U.S.Code. All Other Rights Reserved.
;
; @author B. Harris
;-


;+
; Creates an SpdfHttpErrorReporter object.
;
; @returns reference to an SpdfHttpErrorReporter object.
;-
function SpdfHttpErrorReporter::init
    compile_opt idl2

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfHttpErrorReporter::cleanup
    compile_opt idl2

end


;+
; This procedure is called when an HTTP error occurs.  This default
; implementation merely prints some diagnostic information.
;
; @param responseCode {in} {type=int}
;            the HTTP response code of the request causing the error.
; @param responseHeader {in} {type=string}
;            the HTTP response header of the request causing the error.
; @param responseFilename {in} {type=string}
;            the name of an error response file sent when the error
;            occurred.
;-
pro SpdfHttpErrorReporter::reportError, $
    responseCode, responseHeader, responseFilename
    compile_opt idl2

    print, "An HTTP Error has occurred."
    print, !error_state.msg
    print, 'HTTP response code = ', responseCode
    print, 'HTTP response header = ', responseHeader
    if n_elements(responseFilename) ne 0 then begin

        print, 'HTTP response filename = ', responseFilename
        self->printResponse, responseFilename
    endif
end


;+
; This procedure prints some diagnostic information from the given
; HTTP error response file.  It only recognizes the "typical" error
; response from the CDAS web services.
;
; @param responseFilename {in} {type=string}
;            the name of an error response file sent when the error
;            occurred.
;-
pro SpdfHttpErrorReporter::printResponse, $
    responseFilename
    compile_opt idl2

    if strlen(responseFilename) eq 0 then return

    print, 'HTTP Error Response'

    response = obj_new('IDLffXMLDOMDocument', filename=responseFilename)

    pElements = response->getElementsByTagName('p')

    for i = 0, pElements->getLength() - 1 do begin

        pNode = pElements->item(i)
        pAttributes = pNode->getAttributes()
        pClassAttribute = pAttributes->getNamedItem('class')

        if obj_valid(pClassAttribute) then begin

            pClassValue = pClassAttribute->getNodeValue()
            pLastChild = pNode->getLastChild()

            if obj_valid(pLastChild) then begin

                pLastChildValue = pLastChild->getNodeValue()

                print, pClassValue, ': ', pLastChildValue
            endif else begin

                print, pClassValue
            endelse
        endif
    endfor

    obj_destroy, response
end


;+
; Defines the SpdfHttpErrorReporter class.
;
;-
pro SpdfHttpErrorReporter__define
    compile_opt idl2
    struct = { SpdfHttpErrorReporter, $
        notused:'' $ ; not used but makes idldoc happy
    }
end
