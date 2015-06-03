mms_init, local_data_dir='/Volumes/MMS/data/mms/'

timespan, '2015-05-06/23:10:00', 12, /hour

mms_load_dsp, sc = 'mms3', data_type='epsd'

options, ['mms3_dsp_lfe_x', 'mms3_dsp_lfe_y', 'mms3_dsp_lfe_z', $
         'mms3_dsp_mfe_x', 'mms3_dsp_mfe_y', 'mms3_dsp_mfe_z'], $
         'ylog', 1

options, ['mms3_dsp_lfe_x', 'mms3_dsp_lfe_y', 'mms3_dsp_lfe_z', $
         'mms3_dsp_mfe_x', 'mms3_dsp_mfe_y', 'mms3_dsp_mfe_z'], $
         'zlog', 1
         
ylim, ['mms3_dsp_lfe_x', 'mms3_dsp_lfe_y', 'mms3_dsp_lfe_z'], 10, 10000

ylim, ['mms3_dsp_mfe_x', 'mms3_dsp_mfe_y', 'mms3_dsp_mfe_z'], 100, 100000
     
tplot, ['mms3_dsp_lfe_x', 'mms3_dsp_lfe_y', 'mms3_dsp_lfe_z', $
         'mms3_dsp_mfe_x', 'mms3_dsp_mfe_y', 'mms3_dsp_mfe_z']

; Now lets do bspec

mms_load_dsp, sc = 'mms3', data_type='bpsd'

options, ['mms3_dsp_lfb_x', 'mms3_dsp_lfb_y','mms3_dsp_lfb_z'], 'ylog', 1

options, ['mms3_dsp_lfb_x', 'mms3_dsp_lfb_y','mms3_dsp_lfb_z'], 'zlog', 1

ylim, ['mms3_dsp_lfb_x', 'mms3_dsp_lfb_y','mms3_dsp_lfb_z'], 10, 10000


window, 1

tplot, ['mms3_dsp_lfb_x', 'mms3_dsp_lfb_y','mms3_dsp_lfb_z'], window=1

end