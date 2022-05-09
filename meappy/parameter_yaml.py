import yaml
import os
from IPython.display import display
from datetime import datetime 
import xlrd
import pathlib

from configuration import (USER_PATHS, USER, XL_TAB, XL_COLS, 
    ROW_ID_LIST)

## ipywidget display settings for jupyter lab notebook
# import ipywidgets as widgets
# from ipywidgets import Layout
# ext_text = Layout(width='800px')
# ext_xlrow = Layout(width='1200px',  height='40px')


def set_output_paths(user=USER, user_paths=USER_PATHS, protocol_dir = r''):
    # write check for os paths
    output_path = os.path.join(
        user_paths[user]['output'],
        r'experiment',
        protocol_dir)
    user_paths[user]['protocol_output'] = os.path.join(
        output_path)


def set_input_paths(user=USER, user_paths=USER_PATHS):
    user_paths[user]['slice_template'] = os.path.join(
        user_paths[user]['meap'],
        r'parameter_examples',
        r'slice_parameters.yaml')
    user_paths[user]['protocol_template'] = os.path.join(
        user_paths[user]['meap'],
        r'parameter_examples',
        r'protocol_parameters.yaml')


def set_user(user_name, user_paths=USER_PATHS):
    if user_name not in user_paths:
        raise KeyError(f'User {user_name} not in known USER_PATHS {USER_PATHS.keys()}')
    set_input_paths(user_name)
    set_output_paths(user_name, protocol_dir=XL_TAB)
    return user_name


def get_date_param(date_str):
    date_dt = datetime.strptime(date_str,'%Y%m%d')
    date_param = datetime.strftime(date_dt, '%Y-%m-%d')
    return date_param


def get_time_param(time_str):
    time_dt = datetime.strptime(time_str,'%Hh%Mm%Ss')
    time_param = datetime.strftime(time_dt,'%I:%M:%S %p')
    return time_param


def xl_to_slice_params(xl, slice_param_template):
    slice_params = slice_param_template

    date_str = xl['date']
    time_str = xl['slice_time']
    slice_id = date_str + '_' + time_str

    slice_params['slice_metadata']['date'] = get_date_param(date_str)
    slice_params['slice_metadata']['time'] = get_time_param(time_str)
    slice_params['slice_metadata']['notes'] = 'Channels: ' + xl['notes_issues'] + '\nMisc: ' + xl['notes']
    slice_params['slice_metadata']['region'] = xl['region']
    slice_params['slice_metadata']['type'] = xl['experiment_type']
    slice_params['slice_metadata']['protocol'] = XL_TAB
    slice_params['slice_metadata']['cut_by'] = xl['cut_by']
    slice_params['slice_metadata']['run_by'] = xl['run_by']
    slice_params['slice_metadata']['recording_site'] = '[dorsal, medial, ventral]'

    unit_timestamps_filename = slice_id + '_units_ts.mat'
    treatments_filename = slice_id + '_treatments.csv'
    electrode_filename = slice_id + '_unit_electrode.csv'
    image_filename = slice_id + '.jpg'
    slice_params['paths']['base'] = r'experiment'
    slice_params['paths']['protocol'] = XL_TAB
    slice_params['paths']['slice'] = slice_id
    slice_params['paths']['unit'] = unit_timestamps_filename
    slice_params['paths']['treatment'] = treatments_filename
    slice_params['paths']['photo'] = image_filename
    return slice_params


def xl_to_protocol_params(researchers, protocol_param_template):
    """ Most of these parameters are manually set in the protocol_parameters.yaml
    """
    protocol_params = protocol_param_template
    protocol_params['protocol_metadata']['researchers'] = researchers
    protocol_params['protocol_metadata']['protocol'] = XL_TAB
    return protocol_params


def mkdir_slice(slice_id=''):
    protocol_dir_path = pathlib.Path(USER_PATHS[USER]['protocol_output'])
    slice_dir_path = protocol_dir_path / slice_id
    slice_dir_path.mkdir(mode=511, parents=True, exist_ok=True)


def create_slice_params(xl):
    with open(USER_PATHS[USER]['slice_template'], 'r') as file:
        slice_param_template = yaml.safe_load(file)
    slice_params = xl_to_slice_params(xl, slice_param_template)
    slice_params_dump = yaml.dump(slice_params, sort_keys=False, indent=4, default_flow_style=False)
    slice_dump_filepath = pathlib.Path(USER_PATHS[USER]['protocol_output']) / \
                        slice_params['paths']['slice'] / \
                        r'slice_parameters.yaml' 
    mkdir_slice(slice_params['paths']['slice'])
    with open(slice_dump_filepath, 'w', encoding = "utf-8") as yaml_file:
        yaml_file.write(slice_params_dump)


def create_protocol_parms(researchers):
    with open(USER_PATHS[USER]['protocol_template'], 'r') as file:
        protocol_param_template = yaml.safe_load(file)
    protocol_params = xl_to_protocol_params(researchers, protocol_param_template)
    protocol_params_dump = yaml.dump(protocol_params, sort_keys=False, indent=4, default_flow_style=False)
    protocol_dump_file = pathlib.Path(USER_PATHS[USER]['protocol_output']) / r'protocol_parameters.yaml'
    mkdir_slice()
    with open(protocol_dump_file, 'w', encoding = "utf-8") as yaml_file:
        yaml_file.write(protocol_params_dump)


def mock_excel():
    """Create mock excel row data for dev and testing.
    Alternative code is for including widgets in Jupyter Notebooks
    """
    example_excel_row = ('20220211\tEVD\tEVD\tVTA\t\tDose/Response\t'
        'EM2 (1pM,10pM,100pM,1nM,10nM,100nM); CTAP (1uM)\tZadina\t15h24m23s\tY\t'
        'Chs:28,33,34,35,36,37,41,42,43,47,46,50,51,54. Maybe:27,26,25,44,52,45\t'
        'Y\tY\tGabazine in all solutions. Started, ran until 1pM EM2, stopped. Washed out and restarted form baseline (computer was lacking memory)')

    xl_row = example_excel_row
    # xl_row = widgets.Text(value=example_excel_row, disabled=False, layout=ext_xlrow, display='flex',
    #     flex_flow='column', flex_wrap='wrap')

    xl_cols = ['date', 'cut_by', 'run_by', 'region', 'project',\
        'experiment_type', 'drugs_dose_used', 'vendor_batch',\
         'slice_time', 'is_photo_saved', 'notes_issues', 'is_exported',\
         'is_sorted', 'notes']
    xl = dict(zip(xl_cols, xl_row.split("\t")))
    # print('\nExcel Experiments [tab: ' + XL_TAB + ']')
    # pprint(xl.items())
    return xl


def get_researcher_list(ws, col_list):
    """collects the list of all researchers in cut_by and run_by columns of a sheet
    """
    researchers = set()
    for n in range(ws.nrows):
        if n == 0:
            continue
        for col in col_list:
            researchers.add(ws.row(n)[col].value)
    researchers = [r for r in researchers if r != '']
    return researchers


def get_xl_data(tab_name, row_id_list=None):
    """Fetch and format Excel notebook of experimental data
    """
    def values(row):
        return [cell.value for cell in row]

    xls_file = USER_PATHS[USER]['exp_xlsx']
    wb = xlrd.open_workbook(xls_file)

    tab_names = [sh.name for sh in wb.sheets()]

    if tab_name not in tab_names:
        raise KeyError(f'"{tab_name}" is not found in this excel file.\nTabs Found:\n{tab_names}')
    ws = wb.sheet_by_name(tab_name)


    xl_cols = values(ws.row(0))
    xl_cols_new = XL_COLS
    if len(xl_cols) != len(xl_cols_new):
        raise IndexError(f'Excel file column names do not match expected\n{list(zip(xl_cols_new, xl_cols))}')
    xl_cols_new = xl_cols_new # change to xl_cols_new if prefered
    date_col_name = xl_cols_new[0]
    slice_time_col_name = xl_cols_new[8]
    cut_by_index = xl_cols_new.index('cut_by') 
    run_by_index = xl_cols_new.index('run_by') 

    researchers = get_researcher_list(ws, [cut_by_index, run_by_index])

    xl = dict()
    for n in range(ws.nrows):
        if n == 0:
            continue
        if ws.row(n)[0].value == r'':
            continue
        xl_row_values = values(ws.row(n))
        xl_row_dict = dict(zip(xl_cols_new, xl_row_values))
        row_id = str(int(xl_row_dict[date_col_name])) + '_' + str(xl_row_dict[slice_time_col_name])
        xl[row_id] = xl_row_dict
        xl[row_id][date_col_name] = str(int(xl[row_id][date_col_name]))

    if row_id_list is None:
        return list(xl.values())
    if not set(row_id_list) <= set(xl.keys()):
        raise KeyError(f'{row_id_list} not in {list(xl.keys())}')
    return {row:xl[row] for row in row_id_list} , researchers


def main():
    """for development and testing, use:
    `xl = mock_excel()`
    """
    user = set_user(USER)
    print(USER_PATHS[user]['protocol_output'])

    xl, researchers = get_xl_data(XL_TAB, ROW_ID_LIST)
    for row_id in ROW_ID_LIST:
        create_slice_params(xl[row_id])
    create_protocol_parms(researchers)


if __name__ == '__main__':
    main()

