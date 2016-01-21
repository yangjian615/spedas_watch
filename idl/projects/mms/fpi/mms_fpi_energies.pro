;+
; PROCEDURE:
;         mms_fpi_energies
;
; PURPOSE:
;         Returns the hard coded energies for the FS FPI spectra
;
; NOTE:
;         Expect this routine to be made obsolete after adding the energies to the CDF
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-12-22 11:25:52 -0800 (Tue, 22 Dec 2015) $
;$LastChangedRevision: 19645 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/fpi/mms_fpi_energies.pro $
;-
function mms_fpi_energies, species
    if undefined(species) || (species ne 'i' && species ne 'e') then begin
        dprint, dlevel = 1, "Error, species type ('i' or 'e') required for FPI energies"
        return, -1
    endif

    des_energies = [11.66161217, $
        14.95286673, $
        19.17301144, $
        24.58420677, $
        31.52260272, $
        40.41922083, $
        51.82672975, $
        66.45377773, $
        85.20901465, $
        109.2575384, $
        140.0932726, $
        179.63177, $
        230.3292099, $
        295.3349785, $
        378.6873127, $
        485.5641602, $
        622.6048397, $
        798.322484, $
        1023.632885, $
        1312.532598, $
        1682.968421, $
        2157.952275, $
        2766.99073, $
        3547.917992, $
        4549.246205, $
        5833.179086, $
        7479.476099, $
        9590.4072, $
        12297.10598, $
        15767.71584, $
        20217.83525, $
        25923.91101]

    dis_energies = [11.32541789, $
        14.54730661, $
        18.68576787, $
        24.00155096, $
        30.82958391, $
        39.60007608, $
        50.86562406, $
        65.33602881, $
        83.92301755, $
        107.7976884, $
        138.4642969, $
        177.8550339, $
        228.4517655, $
        293.4424065, $
        376.9217793, $
        484.1496135, $
        621.8819424, $
        798.7967759, $
        1026.04087, $
        1317.932043, $
        1692.861289, $
        2174.451528, $
        2793.045997, $
        3587.62007, $
        4608.236949, $
        5919.201968, $
        7603.114233, $
        9766.070893, $
        12544.35193, $
        16113.00665, $
        20696.88294, $
        26584.79405]

    if species eq 'i' then return, dis_energies else return, des_energies
end