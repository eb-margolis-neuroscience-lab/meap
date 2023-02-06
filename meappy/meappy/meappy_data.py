import os, shutil


_ROOT = os.path.abspath(os.path.dirname(__file__))
_TEMP_DIR = 'temp_test_data'
_README_DESCRIPTION = """# MEAP Temporary Test Data   
This directory is generated from data in the meappy/data directory using
code in phy_2_nwb.py. See the notebook "meap/notebooks/compare_phy_nwb.ipynb"
for details.
"""
    
    
def get_example_data_path(path):
    return os.path.join(_ROOT, 'data', path)
    
    
def write_readme(path, text):
    file_path = os.path.join(path, "readme.txt")
    text_file = open(file_path, "w")
    text_file.write(text)
    text_file.close()
    
    
def get_test_data_path(root=_ROOT, temp_dir=_TEMP_DIR):
    """
    Returns path of the temporary test data directory in the root directory.
    If temp test directory not found, it creates one and returns it's path.
    """
    path_temp_data = os.path.join(root, temp_dir)
    filelist = os.listdir(root)
    if temp_dir in filelist:
        return path_temp_data
    else:
        try:
            os.mkdir(path_temp_data)
            write_readme(path_temp_data, _README_DESCRIPTION)
            return path_temp_data
        except:
            print(f'Error creating directory {path_temp_data}')

            
def cleanup_test_data(root=_ROOT, temp_dir=_TEMP_DIR):
    """
    Recursively removes the temporary test data directories and all files in the 
    directory.
    """
    path_temp_data = os.path.join(root, temp_dir)

    filelist = os.listdir(root)
    if 'temp_test_data' in filelist:
        print(f'Removing temporary directory: {path_temp_data}')
        try:
            shutil.rmtree(path_temp_data)
        except:
            print(f'Error deleting directory {path_temp_data}')
    else:
        print(f'Temporary directory not found: {path_temp_data}')
