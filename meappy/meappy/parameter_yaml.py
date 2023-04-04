import yaml
import os
from datetime import datetime
import xlrd  ## deprecated
import openpyxl
import pathlib
import re, string
import sys, argparse

from meappy.configuration import USER_PATHS, USER, XL_TAB, XL_COLS, ROW_ID_LIST, COMPOSITE_ROW_ID, XLCOL
    # USER_PATHS, DEFAULT_USER, DEFAULT_XL_TAB, DEFAULT_XL_COLS
from meappy.meappy_data import get_test_data_path

DEFAULT_SLICE_TEMPLATE_PATH = ""
DEFAULT_PROTOCOL_TEMPLATE_PATH = "" 
DEFAULT_SAMPLE_FIELDS = ""

DESCRIPTION = """Create data folder and metadata from the experiment log

To use

    cd path/to/MED64_Data
    # edit MED64_ExperimentsForAnalysis.xls

    python /path/to/meap/meappy/meappy/parameter_yaml.py

Note that to to figure setup, edit `path/to/MED64_Data/configuration.py`

"""

def parse_arguments(argv):
    parser = argparse.ArgumentParser(description=DESCRIPTION)
    parser.add_argument(
        "--data_root", type=str, action="store", dest="data_root",
        help="""Select user paths configuration""", default=".")
    
    parser.add_argument(
        "--slice_template_path", type=str, action="store", dest="slice_template_path",
        help="""Path to slice_template.yaml to use as a template for slice paramters""",
        default=DEFAULT_SLICE_TEMPLATE_PATH)

    parser.add_argument(
        "--protocol_template_path", type=str, action="store", dest="protocol_template_path",
        help="""Path to slice_template.yaml to use as a template for protocol paramters""",
        default=DEFAULT_PROTOCOL_TEMPLATE_PATH)
    
    parser.add_argument(
        "--protocol_id", type=str, action="store", dest="protocol_id",
        help="""Select protocol (i.e. a tab in the MED64_ExperimentsForAnalysis.xls)""",
        default = None)

    parser.add_argument(
        "--fields", nargs="+", type=str, action="store", dest="XL_COLS",
        help="""Select meta data fieilds for each recording (i.e. columns in a tab in the MED64_ExperimentForAnalysis.xls) (Default: XL_COLS in configuration.py)""",
        default = DEFAULT_SAMPLE_FIELDS)

    parser.add_argument(
        "--sample_ids", nargs="+", type=str, action="store", dest="sample_ids",
        help="""Select recording ids (i.e. rows in tab in the MED64_ExperimentsForAnalysis.xls), default to all""",
        default = None)

    args = parser.parse_args()
    
    return args

def build_user_paths(args, user_paths=USER_PATHS):
    if args.user not in USER_PATHS.keys():
        raise KeyError(f"User {args.user} not in known USER_PATHS {USER_PATHS.keys()}")

    user_paths = USER_PATHS[args.user]
    user_paths["protocol_output"] = os.path.join(
        user_paths["base"], "experiment", user.protocol)
    user_paths["slice_template"] = os.path.join(
        user_paths["base"], args.slice_template_path)
    user_paths["protocol_template"] = os.path.join(
        user_paths["base"], args.protocol_template_path)


def set_output_paths(user=USER, user_paths=USER_PATHS, protocol_dir=r""):
    # write check for os paths
    output_path = os.path.join(user_paths[user]["output"], r"experiment", protocol_dir)
    user_paths[user]["protocol_output"] = os.path.join(output_path)


def set_input_paths(user=USER, user_paths=USER_PATHS):
    user_paths[user]["slice_template"] = os.path.join(
        user_paths[user]["meap"], r"doc/parameter_examples", r"slice_parameters.yaml"
    )
    user_paths[user]["protocol_template"] = os.path.join(
        user_paths[user]["meap"], r"doc/parameter_examples", r"protocol_parameters.yaml"
    )


def set_user(user_name, user_paths=USER_PATHS):
    if user_name not in user_paths:
        raise KeyError(f"User {user_name} not in known USER_PATHS {USER_PATHS.keys()}")
    set_input_paths(user_name)
    set_output_paths(user_name, protocol_dir=XL_TAB)
    return user_name


def get_date_param(date_str):
    date_dt = datetime.strptime(date_str, "%Y%m%d")
    date_param = datetime.strftime(date_dt, "%Y-%m-%d")
    return date_param


def get_time_param(time_str):
    time_dt = datetime.strptime(time_str, "%Hh%Mm%Ss")
    time_param = datetime.strftime(time_dt, "%I:%M:%S %p")
    return time_param


def xl_to_slice_params_v0(xl, slice_param_template):
    """
    DEPRECATED
    """
    slice_params = slice_param_template

    date_str = xl["date"]
    time_str = xl["slice_time"]
    slice_id = date_str + "_" + time_str

    slice_params["slice_metadata"]["date"] = get_date_param(date_str)
    slice_params["slice_metadata"]["time"] = get_time_param(time_str)
    slice_params["slice_metadata"]["notes"] = (
        "Channels: " + xl["notes_issues"] + "\nMisc: " + xl["notes"]
    )
    slice_params["slice_metadata"]["region"] = xl["region"]
    slice_params["slice_metadata"]["type"] = xl["experiment_type"]
    slice_params["slice_metadata"]["protocol"] = XL_TAB
    slice_params["slice_metadata"]["cut_by"] = xl["cut_by"]
    slice_params["slice_metadata"]["run_by"] = xl["run_by"]
    slice_params["slice_metadata"]["recording_site"] = "[dorsal, medial, ventral]"

    unit_timestamps_filename = slice_id + "_units_ts.mat"
    treatments_filename = slice_id + "_treatments.csv"
    electrode_filename = slice_id + "_unit_electrode.csv"
    image_filename = slice_id + ".jpg"
    slice_params["paths"]["base"] = r"experiment"
    slice_params["paths"]["protocol"] = XL_TAB
    slice_params["paths"]["slice"] = slice_id
    slice_params["paths"]["unit"] = unit_timestamps_filename
    slice_params["paths"]["treatment"] = treatments_filename
    slice_params["paths"]["photo"] = image_filename
    return slice_params


def xl_to_protocol_params(researchers, protocol_param_template):
    """Most of these parameters are manually set in the protocol_parameters.yaml"""
    protocol_params = protocol_param_template
    protocol_params["protocol_metadata"]["researchers"] = researchers
    protocol_params["protocol_metadata"]["protocol"] = XL_TAB
    return protocol_params


def mkdir_slice(slice_id=""):
    protocol_dir_path = pathlib.Path(USER_PATHS[USER]["protocol_output"])
    slice_dir_path = protocol_dir_path / slice_id
    slice_dir_path.mkdir(mode=511, parents=True, exist_ok=True)


def create_slice_params_v0(xl):
    """
    Deprecated
    """
    with open(USER_PATHS[USER]["slice_template"], "r") as file:
        slice_param_template = yaml.safe_load(file)
    slice_params = xl_to_slice_params(xl, slice_param_template)
    slice_params_dump = yaml.dump(
        slice_params, sort_keys=False, indent=4, default_flow_style=False
    )
    slice_dump_filepath = (
        pathlib.Path(USER_PATHS[USER]["protocol_output"])
        / slice_params["paths"]["slice"]
        / r"slice_parameters.yaml"
    )
    mkdir_slice(slice_params["paths"]["slice"])

    with open(slice_dump_filepath, "w", encoding="utf-8") as yaml_file:
        yaml_file.write(slice_params_dump)
        print(f"Parameter slice params written to: {slice_dump_filepath}")


def create_protocol_parms(researchers):
    with open(USER_PATHS[USER]["protocol_template"], "r") as file:
        protocol_param_template = yaml.safe_load(file)
    protocol_params = xl_to_protocol_params(researchers, protocol_param_template)
    protocol_params_dump = yaml.dump(
        protocol_params, sort_keys=False, indent=4, default_flow_style=False
    )
    protocol_dump_file = (
        pathlib.Path(USER_PATHS[USER]["protocol_output"]) / r"protocol_parameters.yaml"
    )
    mkdir_slice()
    with open(protocol_dump_file, "w", encoding="utf-8") as yaml_file:
        yaml_file.write(protocol_params_dump)
    print(f"Parameter protocol written to: {protocol_dump_file}")


def mock_excel():
    """Create mock excel row data for dev and testing.
    Alternative code is for including widgets in Jupyter Notebooks
    """
    example_excel_row = (
        "20220211\tEVD\tEVD\tVTA\t\tDose/Response\t"
        "EM2 (1pM,10pM,100pM,1nM,10nM,100nM); CTAP (1uM)\tZadina\t15h24m23s\tY\t"
        "Chs:28,33,34,35,36,37,41,42,43,47,46,50,51,54. Maybe:27,26,25,44,52,45\t"
        "Y\tY\tGabazine in all solutions. Started, ran until 1pM EM2, stopped. Washed out and restarted form baseline (computer was lacking memory)"
    )

    xl_row = example_excel_row
    # xl_row = widgets.Text(value=example_excel_row, disabled=False, layout=ext_xlrow, display='flex',
    #     flex_flow='column', flex_wrap='wrap')

    xl_cols = [
        "date",
        "cut_by",
        "run_by",
        "region",
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
    xl = dict(zip(xl_cols, xl_row.split("\t")))
    # print('\nExcel Experiments [tab: ' + XL_TAB + ']')
    # pprint(xl.items())
    return xl


def get_researcher_list(ws, col_list):
    """collects the list of all researchers in cut_by and run_by columns of a sheet"""
    researchers = set()
    for n in range(ws.nrows):
        if n == 0:
            continue
        for col in col_list:
            researchers.add(ws.row(n)[col].value)
    researchers = [r for r in researchers if r != ""]
    return researchers


def get_xl_data(tab_name, row_id_list=None):
    """
    DEPRECATED
    Fetch and format Excel notebook of experimental data
    NOTE: the column names for slice_time_col_name (etc) should
    be moved to constants in configuration.py file
    """

    def values(row):
        return [cell.value for cell in row]

    xls_file = USER_PATHS[USER]["exp_xlsx"]
    wb = xlrd.open_workbook(xls_file)

    tab_names = [sh.name for sh in wb.sheets()]

    if tab_name not in tab_names:
        raise KeyError(
            f'"{tab_name}" is not found in this excel file.\nTabs Found:\n{tab_names}'
        )
    ws = wb.sheet_by_name(tab_name)

    xl_cols = values(ws.row(0))
    xl_cols_new = XL_COLS
    if len(xl_cols) != len(xl_cols_new):
        raise IndexError(
            f"Excel file column names do not match expected\n{list(zip(xl_cols_new, xl_cols))}"
        )
    xl_cols_new = xl_cols_new  # change to xl_cols_new if prefered
    date_col_name = xl_cols_new[0]
    slice_time_col_name = xl_cols_new[9]
    cut_by_index = xl_cols_new.index("cut_by")
    run_by_index = xl_cols_new.index("run_by")

    researchers = get_researcher_list(ws, [cut_by_index, run_by_index])

    xl = dict()
    for n in range(ws.nrows):
        if n == 0:
            continue
        if ws.row(n)[0].value == r"":
            continue
        xl_row_values = values(ws.row(n))
        xl_row_dict = dict(zip(xl_cols_new, xl_row_values))
        row_id = (
            str(int(xl_row_dict[date_col_name]))
            + "_"
            + str(xl_row_dict[slice_time_col_name])
        )
        xl[row_id] = xl_row_dict
        xl[row_id][date_col_name] = str(int(xl[row_id][date_col_name]))

    if row_id_list is None:
        return list(xl.values())
    if not set(row_id_list) <= set(xl.keys()):
        raise KeyError(f"{row_id_list} not in {list(xl.keys())}")
    return {row: xl[row] for row in row_id_list}, researchers


def clean_xl_col_names(sheet_data):
    """
    Gets and cleans the None values from an excel sheet object read by the openpyxl module.
    Args: 
        sheet_data: openpyxl object, tuple of worksheet cells from excel notebook
    Returns:
        values: list, values from worksheet data with all None values stripped from
        the terminal end.
    """
    values = [cell.value for cell in sheet_data]
    while values[-1] is None:
        values = values[:-1]
    return values


def check_xl_col_names(col_names, raw_columns):
    """Checks a list of excel workbook column names against the raw columns 
    read from a new worksheet. The raw_column names may contain extra None
    values at the end.
    """
    if col_names != clean_xl_col_names(raw_columns):
        raise ValueError(f'Columns of Experiment Spreadsheet tab must be \
        identical to other tabs.')
    return None


def read_xl_wb_indices(wb):
    """
    Column names will be checked against each other tab to verify column name 
    consistency. Will throw error if unexpected column names. 
    Skips the "Index" tab.
    """
    col_names = None
    
    for tab in wb.sheetnames:
        if tab == 'Index':
            continue
        sheet_data = wb[tab]
        new_col_names = sheet_data['1']
        if col_names is None:
            col_names = clean_xl_col_names(new_col_names)
        check_xl_col_names(col_names, new_col_names)
    return col_names


def verify_row_id_elements(ws):
    """Find and verify that columns used to create composite row_id are valid.
    """
    col_names = ws['1']
    row_id_elements = []
    for i, name in enumerate(col_names):
        if name.value == COMPOSITE_ROW_ID[0]:
            row_id_elements.append(i+1)  # (i+1) because openpyxl indexing starts at 1 not 0
        if name.value == COMPOSITE_ROW_ID[1]:
            row_id_elements.append(i+1)
    if len(row_id_elements) < 2:
        raise ValueError("Row_ID must be composed of two elements")
    return row_id_elements
            
    
def read_xl_sheet_rows(ws, col_names):
    """
    Reads rows in an excel workbook sheet.
    Args:
        ws: openpyxl worksheet, containing experiment data from one
        sheet of a workbook
        col_names: names of columns in worksheet to retrieve
    Return:
        rows: dict, values in rows returned
    """
    num_rows = ws.max_row
    num_cols = len(col_names)  # ws.max_column
    row_dict = dict()
    
    row_id_elements = verify_row_id_elements(ws)
    for r in range(2, num_rows):
        row_id = str(ws.cell(row=r, column=row_id_elements[0]).value) + "_" + \
                str(ws.cell(row=r, column=row_id_elements[1]).value)
        row_data = ws[str(r)]
        row_values = [cell.value for cell in row_data]
        if row_values[0] is not None:
            row_dict[row_id] = {alphanum(k):v.value for k,v in zip(col_names, row_data)}
    return row_dict


def get_xls_data(xls_file):
    """
    Gets the index data of an excel spreadsheet to use. 
    Args:
        xls_file: file path, of xlsx file with experiment protocols in tabs 
        and slice metadata in each row.
    Returns:
        dict, tab names keys with values as dicts with keys of row_IDs 
        corresponding to slice id and values of 
    """
    # Open Workbook
    wb = openpyxl.load_workbook(filename=xls_file, data_only=True)
    col_names = read_xl_wb_indices(wb)
    tab_dict = dict()
    for tab in wb.sheetnames: 
        if tab == 'Index':
            continue
        row_dict = read_xl_sheet_rows(wb[tab], col_names)
        tab_dict[tab] = row_dict    
    return col_names, tab_dict
    

def alphanum(str):
    pattern = re.compile('[\W]+') 
    return pattern.sub('', str.lower().replace("/", "_")
                       .replace("#", "").strip().replace(" ", "_"))
    
    
def clean_identifiers(name_list):
    """Takes a list of strings and returns a list of strings composed of only 
    alphanumeric and underscore. This is used to create code identifiers and 
    filenames from human readable strings by removing special characters and spaces.
    """
    clean_list = [alphanum(str) for str in name_list]
    return clean_list
    
        
def xl_to_slice_params(xl_dict, slice_param_template):
    """
    Fill in the slice parameter yaml dict to dump to yaml file
    REPLACE xl with row
    """
    slice_params = slice_param_template
    debug_list = [(n, d) for n, d in xl_dict.items()]
    
    # for tab_name, tab_dict in xl_dict.items():
    for tab_name, tab_dict in debug_list[1:3]:
        for row_name, xl in tab_dict.items():
            date_str = str(xl[XLCOL["date"]]).strip()
            time_str = xl[XLCOL["slice_time"]]
            
            try:
                slice_id = date_str + "_" + time_str
                slice_params["slice_metadata"]["date"] = get_date_param(date_str)
                slice_params["slice_metadata"]["time"] = get_time_param(time_str)
            except:
                raise ValueError(f'Date/Time format error in \
                tab: {tab_name}, row: {row_name}, time_str{time_str}, date_str: {date_str}')
            slice_params["slice_metadata"]["notes"] = (
                "Channels: " + str(xl[XLCOL["notes_issues"]]) + \
                "\nMisc: " + str(xl[XLCOL["notes"]])
            )
            slice_params["slice_metadata"]["region"] = xl[XLCOL["region"]]
            slice_params["slice_metadata"]["type"] = xl[XLCOL["experiment_type"]]
            slice_params["slice_metadata"]["protocol"] = XL_TAB
            slice_params["slice_metadata"]["cut_by"] = xl[XLCOL["cut_by"]]
            slice_params["slice_metadata"]["run_by"] = xl[XLCOL["run_by"]]
            slice_params["slice_metadata"]["recording_site"] = "[dorsal, medial, ventral]"

            unit_timestamps_filename = slice_id + "_units_ts.mat"
            treatments_filename = slice_id + "_treatments.csv"
            electrode_filename = slice_id + "_unit_electrode.csv"
            image_filename = slice_id + ".jpg"
            slice_params["paths"]["base"] = r"experiment"
            slice_params["paths"]["protocol"] = XL_TAB
            slice_params["paths"]["slice"] = slice_id
            slice_params["paths"]["unit"] = unit_timestamps_filename
            slice_params["paths"]["treatment"] = treatments_filename
            slice_params["paths"]["photo"] = image_filename
    return slice_params

    
def create_slice_params(xl_dict):
    """
    xl == tab_dict; xl_dict
    """   
    with open(USER_PATHS[USER]["slice_template"], "r") as file:
        slice_param_template = yaml.safe_load(file)
    slice_params = xl_to_slice_params(xl_dict, slice_param_template)
    slice_params_dump = yaml.dump(
        slice_params, sort_keys=False, indent=4, default_flow_style=False
    )
    slice_dump_filepath = (
        pathlib.Path(USER_PATHS[USER]["protocol_output"])
        / slice_params["paths"]["slice"]
        / r"slice_parameters.yaml"
    )
    mkdir_slice(slice_params["paths"]["slice"])

    with open(slice_dump_filepath, "w", encoding="utf-8") as yaml_file:
        yaml_file.write(slice_params_dump)
        print(f"Parameter slice params written to: {slice_dump_filepath}")
    
    
def test_square():
   n = 2
   assert n*n == 4
    

def main(argv):
    """for development and testing, use:
    `xl = mock_excel()`
    """

    args = parse_arguments(argv)

    user = set_user(USER)
    
    ## new to get all files
    xls_file = USER_PATHS[USER]["exp_xlsx"]
    col_names, tab_dict = get_xls_data(xls_file)
    # print(f'tab_dict keys: {tab_dict.keys()}')
    print(clean_identifiers(col_names))
    create_slice_params(tab_dict)
    
    ### old to read only one file ###
    # xl, researchers = get_xl_data(XL_TAB, ROW_ID_LIST)
    # for row_id in ROW_ID_LIST:
    #     created_slice_params_location = create_slice_params(xl[row_id])
    # created_protocol_params_location = create_protocol_parms(researchers)
    

if __name__ == "__main__":
    main(sys.argv)
