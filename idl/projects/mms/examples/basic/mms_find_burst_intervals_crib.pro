;+
; PROCEDURE:
;         mms_find_burst_intervals_crib
;
; PURPOSE:
;         This crib sheet shows how to find the start/stop times of
;         MMS burst intervals from the burst segments bar
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-08-02 11:58:11 -0700 (Tue, 02 Aug 2016) $
;$LastChangedRevision: 21590 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_find_burst_intervals_crib.pro $
;-

trange = ['2015-10-16/13:00', '2015-10-16/14:00']

; Load the burst segments bar for October 16, 2015
mms_load_brst_segments, trange=trange

get_data, 'mms_bss_burst', data=burst_interval_data 

; in the bar, the start/stops of the intervals are marked by NaNs, so we can
; find them by searching for the indices that aren't finite
burst_interval_indices = where(~finite(burst_interval_data.Y))

; even indices are starts, odd are stops
start_indices = burst_interval_indices[where(burst_interval_indices mod 2 eq 0)]
end_indices = burst_interval_indices[where(burst_interval_indices mod 2 ne 0)]

; grab the times associated with these indices
start_bursts = burst_interval_data.X[start_indices]
end_bursts = burst_interval_data.X[end_indices]

; loop over the intervals, printing the start and stop
for interval_idx=0, n_elements(start_bursts)-1 do begin
  print, 'burst interval start: ' + time_string(start_bursts[interval_idx]) + ' - stop: ' + time_string(end_bursts[interval_idx])
endfor

end