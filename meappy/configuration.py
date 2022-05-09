# configuration.py

# These configuration files can be set up for each computer
# use python dataclasses
USER_PATHS = {'elayne': {'meap': r'C:\Users\fieldslab2\Desktop\Lab\MatLab\Python_Code\meap',
                         'output': r'C:\Users\fieldslab2\Desktop\Lab\MatLab\Python_Code\meap_yaml_output',
                         'exp_xlsx': r'C:\Users\fieldslab2\Desktop\Lab\MatLab\Python_Code\meap\parameter_examples\MED64 Experiments_cols.xls'
                        },
              'walter': {'meap': r'/Users/walter/Src/meap',
                         'output': r'/Users/walter/Src/meap_yaml_output',
                         'exp_xlsx': r'/Users/walter/Src/meap/parameter_examples/MED64 Experiments_cols.xls'
                        },
             }

USER = 'walter' # 'walter' # 'elayne'

XL_TAB = 'HbL' # 'NMDA_Apamin' #'VTA_NMDA' 
		# 'HbL' # 'HB_139_DAMGO'

XL_COLS = ['date', 'cut_by', 'run_by', 'region', 'project',\
        'experiment_type', 'drugs_dose_used', 'vendor_batch',\
        'slice_time', 'is_photo_saved', 'notes_issues', 'is_exported',\
        'is_sorted', 'notes']

# ROW_ID_LIST = ['20211006_15h58m38s', '20211005_17h33m55s'] #, '20211006_15h58m38s']  
ROW_ID_LIST = ['20200825_12h24m37s', '20200825_13h36m25s'] # LHb
