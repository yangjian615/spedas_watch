;+
; 
; FUNCTION:
;         mms_feeps_sector_masks
;         
; PURPOSE:
;         Returns the FEEPS sectors to mask due to sunlight contamination
; 
; OUTPUT:
;         Hash table containing the sectors to mask for each spacecraft and sensor ID
;         
; EXAMPLE:
;     ; to get the masks for MMS1, top sensor = 1:
;     IDL> masks = mms_feeps_sector_masks()
;     
;     ; note the concatenation: mms+probe#+imask+[t or b]+sensorID
;     IDL> mms1_top_sensor1 = masks['mms1imaskt1']
;     IDL> mms1_top_sensor1
;         2       3       4       5       6      20      21
;     
;     
; NOTES:
;     Will only work in IDL 8.0+, due to the hash table data structure
;     
;     Based on code from Drew Turner, 2/1/2016
;        Modifications: 
;          dindgen -> indgen (egrimes, 2/11/2016)
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-08-02 14:21:23 -0700 (Tue, 02 Aug 2016) $
; $LastChangedRevision: 21591 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/feeps/mms_feeps_sector_masks.pro $
;-


function mms_feeps_sector_masks
    masks = hash()
    masks['mms1imaskt1'] = [2, 3, 4, 5, 6, 20, 21]
    masks['mms1imaskt2'] = [11, 12]
    masks['mms1imaskt3'] = [22, 23, 24, 25, 26, 27, 28, 31, 32]
    masks['mms1imaskt4'] = [20, 23, 24, 25]
    masks['mms1imaskt5'] = [0, 1, 4, 5, 6, 7, 42, 43, 44, 45, 46, 47, 55, 56, 57, 58, 59, 60]
    masks['mms1imaskt9'] = []
    masks['mms1imaskt10'] = []
    masks['mms1imaskt11'] = [9, 10, 44, 45, 46, 51, 52]
    masks['mms1imaskt12'] = []
    masks['mms1imaskb1'] = [22, 23, 24, 25, 26, 27, 28, 39, 40, 41, 42, 43, 44, 45]
    masks['mms1imaskb2'] = [33, 38, 39, 40, 41, 42, 43, 44, 45]
    masks['mms1imaskb3'] = [14, 15, 16, 17, 18, 19, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49]
    masks['mms1imaskb4'] = [20, 21, 22, 23, 24, 25, 26, 27, 28, 38, 47]
    masks['mms1imaskb5'] = [40, 41, 42, 45, 49, 50, 51, 52, 53, 54, 55, 56, 57]
    masks['mms1imaskb9'] = []
    masks['mms1imaskb10'] = [33, 35, 36, 37, 38, 53]
    masks['mms1imaskb11'] = [37, 38, 39, 40, 41, 42, 43, 44, 45, 46]
    masks['mms1imaskb12'] = [35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 47, 48, 49, 53, 54, 55, 56]

    ; MMS 2
    masks['mms2imaskt1'] = [32, 33, 34]
    masks['mms2imaskt2'] = []
    masks['mms2imaskt3'] = []
    masks['mms2imaskt4'] = [6, 7, 21, 22, 23, 24, 25, 26, 27, 28, 29]
    masks['mms2imaskt5'] = indgen(64) ;[]
    masks['mms2imaskt9'] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 53, 54, 58, 59, 60, 61, 62, 63]
    masks['mms2imaskt10'] = [13, 14, 15, 43, 44]
    masks['mms2imaskt11'] = []
    masks['mms2imaskt12'] = [47, 48, 49, 50, 51, 52]
    masks['mms2imaskb1'] = []
    masks['mms2imaskb2'] = [38, 39, 40, 41, 42, 43, 44, 45, 46, 47]
    masks['mms2imaskb3'] = [19, 22, 23, 24, 25, 26, 27, 28, 29, 30, 39]
    masks['mms2imaskb4'] = [21, 27, 28]
    masks['mms2imaskb5'] = [40, 41, 52, 53, 54]
    masks['mms2imaskb9'] = [35, 36, 37, 38]
    masks['mms2imaskb10'] = [31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54]
    masks['mms2imaskb11'] = [39, 40, 41, 42, 43, 44, 45, 46, 47]
    masks['mms2imaskb12'] = [33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46]
    
    ; MMS 3
    masks['mms3imaskt1'] = [5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
    masks['mms3imaskt2'] = indgen(64) ;[14, 15, 16, 28, 29, 30, 31, 32, 33, 34, 35, 36]
    masks['mms3imaskt3'] = [5, 6, 7, 8, 11, 12, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31]
    masks['mms3imaskt4'] = [4, 5, 6, 7, 8, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 49, 50, 51]
    masks['mms3imaskt5'] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 32, 33, 34, 37, 39, 40, 41, 42, 43, 44, 45, 46, 47, 57, 58, 59, 60, 61, 62, 63]
    masks['mms3imaskt9'] = [14, 15, 16, 57, 58, 59, 60, 61, 62, 63]
    masks['mms3imaskt10'] = []
    masks['mms3imaskt11'] = [4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56]
    masks['mms3imaskt12'] = indgen(64) ;[33, 34, 35, 36, 54, 55, 56, 57]
    masks['mms3imaskb1'] = [20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43]
    masks['mms3imaskb2'] = indgen(64) ;[29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42]
    masks['mms3imaskb3'] = [18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48]
    masks['mms3imaskb4'] = [19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 47, 50, 51, 52]
    masks['mms3imaskb5'] = indgen(64) ;[36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61]
    masks['mms3imaskb9'] = [53, 54, 55, 56, 57]
    masks['mms3imaskb10'] = [47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59]
    masks['mms3imaskb11'] = [34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46]
    masks['mms3imaskb12'] = [33, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57]

    ; MMS 4
    masks['mms4imaskt1'] = indgen(64)
    masks['mms4imaskt2'] = indgen(64) ;[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 58, 59, 60, 61, 62, 63]
    masks['mms4imaskt3'] = [19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 57, 58, 59]
    masks['mms4imaskt4'] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 59, 60, 61, 62, 63]
    masks['mms4imaskt5'] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 41, 43, 44, 45, 46, 47, 48, 49, 56, 57, 58, 59, 60, 61, 62]
    masks['mms4imaskt9'] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63]
    masks['mms4imaskt10'] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 30, 31, 32, 33, 34, 35, 36, 37, 42, 59, 60, 61, 62, 63]
    masks['mms4imaskt11'] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63]
    masks['mms4imaskt12'] = [0, 1, 2, 3, 4, 5, 8, 9, 10, 11, 12, 13, 14, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63]
    masks['mms4imaskb1'] = [0, 1, 2, 3, 4, 6, 7, 9, 10, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63]
    masks['mms4imaskb2'] = indgen(64)
    masks['mms4imaskb3'] = [18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 39, 40, 41]
    masks['mms4imaskb4'] = indgen(64)
    masks['mms4imaskb5'] = indgen(64) ;[40, 41, 50, 52, 53, 54, 55, 56]
    masks['mms4imaskb9'] = [31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 53, 54, 55, 56]
    masks['mms4imaskb10'] = indgen(64) ;[0, 1, 2, 3, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61]
    masks['mms4imaskb11'] = indgen(64)
    masks['mms4imaskb12'] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63]
    return, masks
end