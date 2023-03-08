# configuration.py

from os import path
from pathlib import Path


_HOME = Path.home()
# examples of home paths for Windows and Mac OS:
# C:\Users\\fieldslab2\
# /Users/walter

meappy_path = Path( __file__ ).parent.absolute()
meap_path = meappy_path.parent.parent.absolute()
base_path = meap_path.parent.absolute()
data_base_path = path.join(_HOME, 'Data')
        # /med64/experiment/VTA_NMDA/20211005_17h33m55s
    
params_examples = path.join(meap_path, 'parameter_examples')  # for out-of-box examples using github repo
params_path = path.join(data_base_path, 'meap/experiment_log')

# box shared directory
box_base_path = path.join(_HOME, '/Library/CloudStorage/Box-Box')
box_output_path = path.join(box_base_path, 'meap_output')

expt_xl_file = 'MED64_ExperimentsForAnalysis.xlsx'

# These configuration files can be set up for each computer
# use python dataclasses
USER_PATHS = {
    "meappy_data": {
        "base": base_path,
        "meap": meap_path,
        "output": path.join(data_base_path, 'meap'),  # path.join(base_path, 'meap_output'),
        "exp_xlsx": path.join(params_path, expt_xl_file), # path.join(params_path, expt_xl_file), 
        "params_template": params_path,
        "data_dir": path.join(data_base_path, 'med64/experiment/VTA_NMDA/20211005_17h33m55s'),
        "phy_export": path.join(data_base_path, 'meap/experiment'),
    },
    "elayne": {
        "meap": r"C:\Users\fieldslab2\Desktop\Lab\MatLab\Python_Code\meap",
        "output": r"C:\Users\fieldslab2\Desktop\Lab\MatLab\Python_Code\meap_yaml_output",
        "exp_xlsx": r"C:\Users\fieldslab2\Desktop\Lab\MED64_Exp\MED64_ExperimentsForAnalysis.xls",
        "data_dir": r"C:\Users\\fieldslab2\\Desktop\\Lab\\MatLab\\MED64_Data\\experiment\\",
        "product_dir": r"C:\Users\\fieldslab2\\Desktop\\Lab\\MatLab\\MED64_Data\\product\\",
    },
}

USER = "meappy_data"  #"walter"  #  'elayne'  # walter_box
COMPOSITE_ROW_ID = ('Date', 'Slice #')  # These are column names of row info used to create composite row_id


XL_TAB = "VTA_EM1_Dose_Response"  #'LHb' # 'VTA_NMDA_Apamin' #'VTA_NMDA'
# 'HbL' # 'HB_139_DAMGO'

# [('date', 'Date'), ('cut_by', 'Cut by'), ('run_by', 'Run by'), ('region', 'Recording  Region'), ('project', 'Slice Location'), ('experiment_type', 'Project'), ('drugs_dose_used', 'Experiment Type'), ('vendor_batch', 'Drugs Used'), ('slice_time', 'Vendor/Batch'), ('is_photo_saved', 'Slice #'), ('notes_issues', 'Photo saved'), ('is_exported', 'Notes/Problems/Issues'), ('is_sorted', 'Exported?'), ('notes', 'Analyzed?')]


XLCOL = {'date': 'date',
    'cut_by': 'cut_by',
    'run_by': 'run_by',
    'region': 'recording__region',
    'slice_location': 'slice_location',
    'project': 'project',
    'experiment_type': 'experiment_type',
    'drugs_dose_used': 'drugs_used',
    'vendor_batch': 'vendor_batch',
    'slice_time': 'slice',
    'is_photo_saved': 'photo_saved',
    'notes_issues': 'notes_problems_issues',
    'is_exported': 'exported',
    'is_sorted': 'analyzed',
    'notes': 'notes'
}


XL_COLS = [
    "date",
    "cut_by",
    "run_by",
    "region",
    "slice_location",
    "project",
    "experiment_type",
    "drugs_dose_used",
    "vendor_batch",
    "slice_time",
    "is_photo_saved",
    "notes_issues",
    "is_exported",
    "is_sorted",
    "notes",
]

# XL_COLS_old = [
#     "date",
#     "cut_by",
#     "run_by",
#     "region",
#     "project",
#     "experiment_type",
#     "drugs_dose_used",
#     "vendor_batch",
#     "slice_time",
#     "is_photo_saved",
#     "notes_issues",
#     "is_exported",
#     "is_sorted",
#     "notes",
# ]

# ROW_ID_LIST = ['20211006_15h58m38s', '20211005_17h33m55s'] #, '20211006_15h58m38s']  # NMDA_Apamin
# ROW_ID_LIST = ['20200825_12h24m37s', '20200825_13h36m25s'] # LHb
ROW_ID_LIST = [
    "20211105_15h48m31s",
    "20211109_15h09m07s",
    "20211109_17h18m41s",
    "20211110_15h00m50s",
    "20211122_13h47m47s",
    "20211130_17h27m13s",
    "20211202_18h13m40s",
    "20211202_14h49m06s",
]  # VTA_EM1_Dose_Response

# Analysis Paths
# for v1 NWB file format
protocol_dir = r"HB_139_DAMGO"
slice_dir = r"825_12h24m37s"  # '20200825_12h24m37s'

# use empty strings for data v0 format
# protocol_dir = '' #r'HB_139_DAMGO'
# slice_dir = '' #r'825_12h24m37s'  # '20200825_12h24m37s'


## QQ configurations
# what do I need the params for?
# old: /Users/walter/Data/med64/experiment/VTA_NMDA/20211005_17h33m55s

############
# NEXT.... #
############
