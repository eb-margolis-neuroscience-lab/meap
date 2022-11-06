# configuration.py

# These configuration files can be set up for each computer
# use python dataclasses
USER_PATHS = {'elayne': {'meap': r'C:\Users\fieldslab2\Desktop\Lab\MatLab\Python_Code\meap',
                         'output': r'C:\Users\fieldslab2\Desktop\Lab\MatLab\Python_Code\meap_yaml_output',
                         'exp_xlsx': r'C:\Users\fieldslab2\Desktop\Lab\MED64_Exp\MED64_ExperimentsForAnalysis.xls',
                         'data_dir': r'C:\Users\\fieldslab2\\Desktop\\Lab\\MatLab\\MED64_Data\\experiment\\',
                         'product_dir': r'C:\Users\\fieldslab2\\Desktop\\Lab\\MatLab\\MED64_Data\\product\\'
                        },
                'walter': {'meap': r'/Users/walter/Src/meap',
                         'output': r'/Users/walter/Src/meap_yaml_output',
                         'exp_xlsx': r'/Users/walter/Src/meap/parameter_examples/MED64_ExperimentsForAnalysis.xls',
                         'data_dir': r'/Users/walter/Data/med64/experiment/',
                         'product_dir': r'/Users/walter/Data/med64/product/'
                        }, 
                'walter_box': {'meap': r'/Users/walter/Src/meap',
                         'output': r'/Users/walter/Src/meap_yaml_output',
                         'exp_xlsx': r'/Users/walter/Src/meap/parameter_examples/MED64_ExperimentsForAnalysis.xls',
                         'data_dir': r'/Users/walter/Library/CloudStorage/Box-Box/MED64_exampledata/structured_analysis_data/experiment/',
                         'product_dir': r'/Users/walter/Library/CloudStorage/Box-Box/MED64_exampledata/structured_analysis_data/product/'
                        },
                'walter_data-v0': {'meap': r'/Users/walter/Src/meap',
                         'output': r'/Users/walter/Src/meap_yaml_output',
                         'exp_xlsx': r'/Users/walter/Src/meap/parameter_examples/MED64_ExperimentsForAnalysis.xls',
                         'data_dir': r'/Users/walter/Data/margolis/MED64_exampledata_09-22/',
                         'product_dir': r'/Users/walter/Data/med64/product/'
                        }
             }

USER = 'walter' #  'elayne'

XL_TAB = 'VTA_EM1_Dose_Response'  #'LHb' # 'VTA_NMDA_Apamin' #'VTA_NMDA' 
		# 'HbL' # 'HB_139_DAMGO'
    
# [('date', 'Date'), ('cut_by', 'Cut by'), ('run_by', 'Run by'), ('region', 'Recording  Region'), ('project', 'Slice Location'), ('experiment_type', 'Project'), ('drugs_dose_used', 'Experiment Type'), ('vendor_batch', 'Drugs Used'), ('slice_time', 'Vendor/Batch'), ('is_photo_saved', 'Slice #'), ('notes_issues', 'Photo saved'), ('is_exported', 'Notes/Problems/Issues'), ('is_sorted', 'Exported?'), ('notes', 'Analyzed?')]
    
XL_COLS = ['date', 'cut_by', 'run_by', 'region', 'slice_location', 'project',\
        'experiment_type', 'drugs_dose_used', 'vendor_batch',\
        'slice_time', 'is_photo_saved', 'notes_issues', 'is_exported',\
        'is_sorted', 'notes']

XL_COLS_old = ['date', 'cut_by', 'run_by', 'region', 'project',\
        'experiment_type', 'drugs_dose_used', 'vendor_batch',\
        'slice_time', 'is_photo_saved', 'notes_issues', 'is_exported',\
        'is_sorted', 'notes']

# ROW_ID_LIST = ['20211006_15h58m38s', '20211005_17h33m55s'] #, '20211006_15h58m38s']  # NMDA_Apamin
# ROW_ID_LIST = ['20200825_12h24m37s', '20200825_13h36m25s'] # LHb
ROW_ID_LIST = ['20211105_15h48m31s', '20211109_15h09m07s', '20211109_17h18m41s', '20211110_15h00m50s', '20211122_13h47m47s', '20211130_17h27m13s', '20211202_18h13m40s', '20211202_14h49m06s']  # VTA_EM1_Dose_Response

# Analysis Paths
# for v1 NWB file format
protocol_dir = r'HB_139_DAMGO'
slice_dir = r'825_12h24m37s'  # '20200825_12h24m37s'

# use empty strings for data v0 format
# protocol_dir = '' #r'HB_139_DAMGO'
# slice_dir = '' #r'825_12h24m37s'  # '20200825_12h24m37s'
