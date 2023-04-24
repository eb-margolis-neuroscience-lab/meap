# configuration.py

from os import path
from pathlib import Path


# System relative paths
# examples of home paths for Windows and Mac OS:
# C:\Users\\fieldslab2\
# /Users/walter
_HOME = Path.home()
meappy_path = Path( __file__ ).parent.absolute()
meap_path = meappy_path.parent.parent.absolute()
# meap_parent_path = meap_path.parent.absolute()

meap_parent_path = Path( __file__ ).parent.parent.parent.parent.absolute()

# Data dir relative path
data_path = path.join(_HOME, 'Data')
        # example:  /med64/experiment/VTA_NMDA/20211005_17h33m55s
experiment_xls_path = path.join(data_path, 'meap/experiment_log')
LOG_FILE = path.join(data_path, 'meap/experiment/log_file.txt') 

# Repo dir relative paths
params_examples = path.join(meap_path, 'doc/parameter_examples/')  # for out-of-box examples using github repo

# box shared directory paths
box_path = path.join(_HOME, '/Library/CloudStorage/Box-Box')
box_output_path = path.join(box_path, 'meap_output')

expt_xl_file = 'MED64_ExperimentsForAnalysis.xlsx'

PARAM_TEMPLATE_DIR = r"doc/parameter_examples"
SLICE_PARAM_TEMPLATE = r"slice_parameters.yaml"
PROTOCOL_PARAM_TEMPLATE = r"protocol_parameters.yaml"

## for parse_arguments()
# DEFAULT_SLICE_TEMPLATE_PATH = path.join(PARAM_TEMPLATE_DIR, SLICE_PARAM_TEMPLATE)
# DEFAULT_PROTOCOL_TEMPLATE_PATH = path.join(PARAM_TEMPLATE_DIR, PROTOCOL_PARAM_TEMPLATE)
# DEFAULT_SAMPLE_FIELDS = ""  # select by field and value. examples: date=20200101, cut_by@AS


# These configuration paths can be set for specific computers. The default path will 
# write to directories relative to the home directory of the user, or relative to the 
# location of the MEAP git repo used to run the code.


USER = "default"

USER_PATHS = {
    "default": {
        "meap": meap_path,
        "output": path.join(data_path, 'meap'),  
        "exp_xlsx": path.join(experiment_xls_path, expt_xl_file), 
        "data_dir": path.join(data_path, 'med64/experiment/VTA_NMDA/20211005_17h33m55s'),
        "phy_export": path.join(data_path, 'meap/experiment'),
        ## for parse_arguments()
        "slice_template_path": path.join(PARAM_TEMPLATE_DIR, SLICE_PARAM_TEMPLATE),
        "protocol_template_path": path.join(PARAM_TEMPLATE_DIR, PROTOCOL_PARAM_TEMPLATE),
        "sample_fields": None, # select by field and value. examples: date=20200101, cut_by@AS
        "protocol_ids": None, # select specific protocol ids to process
        "log_file": LOG_FILE,
    },
    "elayne": {
        "meap": r"C:\Users\fieldslab2\Desktop\Lab\MatLab\Python_Code\meap",
        "output": r"C:\Users\fieldslab2\Desktop\Lab\MatLab\Python_Code\meap_yaml_output",
        "exp_xlsx": r"C:\Users\fieldslab2\Desktop\Lab\MED64_Exp\MED64_ExperimentsForAnalysis.xls",
        "data_dir": r"C:\Users\\fieldslab2\\Desktop\\Lab\\MatLab\\MED64_Data\\experiment\\",
        "product_dir": r"C:\Users\\fieldslab2\\Desktop\\Lab\\MatLab\\MED64_Data\\product\\",
    },
}


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
}  #  (name used in parameter yaml files): (col name in xls file; spaces replaced with underscores)

XL_COLS = list(XLCOL.keys())

COMPOSITE_ROW_ID = ('Date', 'Slice #')  # These are column names of row info used to create composite row_id
