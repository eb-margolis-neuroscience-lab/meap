import os
import numpy as np
from scipy.io import savemat

from waveform import (PhyPaths, PhyData, get_raw_data, 
                      get_phy_spikes_list, get_raw_phy_spike_waves)


def phy_2_nwb(unit_spike_times):
    """
    create structure of nwb format from the PHY formatted unit spike times.
    waveform currently has a placeholder of all zeros in correct ndarray size
    """
    nwb = dict()
    for u in unit_spike_times.keys():
        nwb[u] = dict([('timestamps', np.array(unit_spike_times[u])), 
                       ('waveform', np.zeros((60,1)))])
    return nwb


def build_units_struct(units_data):
    """
    build matlab style data structure from a unit_data dict
    """
    num_units = len(units_data)
    units = sorted(units_data.keys())
    
    dt = np.dtype([('ts', object), ('mWave', object)])

    ts_obj = units_data[units[0]]['timestamps'].astype(np.float64)[np.newaxis, :]
    mw_obj = units_data[units[0]]['waveform'] 
    x = np.array([(ts_obj, mw_obj)], 
                 dtype=dt)

    for u in units[1:]:
        ts_obj = units_data[u]['timestamps'][np.newaxis, :]
        mw_obj = units_data[u]['waveform'] 
        x2 = np.array([(ts_obj, mw_obj)], 
                     dtype=dt)
        x = np.concatenate((x, x2))

    new_mat = dict([('Unit', x[np.newaxis, :])])
    return new_mat


def _validate(units_mat, condition_str, valid_result, message='Invalid export data structure'):
    if not eval(condition_str) == valid_result:
        raise TypeError(f'{message}: {condition_str} should be {valid_result}')
    else:
        return True

    
def validate_units_data(units_mat, header=False):
    if header:
        _validate(units_mat, "list(units_mat.keys())", 
                  ['__header__', '__version__', '__globals__', 'Unit'])
        if not b'MATLAB 5.0 MAT-file' in units_mat['__header__']:
            raise TypeError(f'Invalid export data structure: header error')
    _validate(units_mat, "units_mat['Unit'].dtype", 
              [('ts', 'O'), ('mWave', 'O')])
    _validate(units_mat, "type(units_mat['Unit'])", np.ndarray)
    _validate(units_mat, "type(units_mat['Unit']['ts'])", np.ndarray)
    _validate(units_mat, "type(units_mat['Unit']['mWave'])", np.ndarray)
    _validate(units_mat, "units_mat['Unit']['ts'].dtype", object)
    _validate(units_mat, "units_mat['Unit']['mWave'].dtype", object)
    _validate(units_mat, "len(units_mat['Unit']['ts'].shape)", 2)
    _validate(units_mat, "len(units_mat['Unit']['mWave'].shape)", 2)
    _validate(units_mat, "units_mat['Unit']['ts'].shape[0]", 1)
    _validate(units_mat, "units_mat['Unit']['mWave'].shape[0]" ,1)
    _validate(units_mat, "units_mat['Unit']['mWave'].shape[0]", 1) # add extra dimension here
    _validate(units_mat, "units_mat['Unit']['ts'][0].dtype", object)
    _validate(units_mat, "units_mat['Unit']['mWave'][0].dtype", object)
    _validate(units_mat, "type(units_mat['Unit']['ts'][0])", np.ndarray)
    _validate(units_mat, "type(units_mat['Unit']['ts'][0][0])", np.ndarray)
    _validate(units_mat, "type(units_mat['Unit']['ts'][0][0][0])", np.ndarray)
    _validate(units_mat, "type(units_mat['Unit']['mWave'][0])", np.ndarray)
    _validate(units_mat, "type(units_mat['Unit']['mWave'][0][0])", np.ndarray)
    _validate(units_mat, "units_mat['Unit']['ts'][0][0].shape[0]", 1)
    _validate(units_mat, "units_mat['Unit']['mWave'][0][0].shape", (60, 1))
    _validate(units_mat, "units_mat['Unit']['ts'][0][0].dtype", np.float64)
    _validate(units_mat, "units_mat['Unit']['ts'][0][0][0].dtype", np.float64)
    _validate(units_mat, "units_mat['Unit']['mWave'][0][0].dtype", np.float64)
    return 'valid'


def write_units_data(units_mat, export_path):
    """
    mdict is units_data to export matlab tile
    export_path is the unit_filename to write the data to
    """    
    if validate_units_data(units_mat) == 'valid':
        savemat(export_path, units_mat)
        print(f"Valid data structure. Wrote file: {export_path}")
    else:
        print("Invalid data structure. File not written")
    return None
    
    
def export_units_data(units_data, export_path):
    # write_units_data(units_data, unit_filename)  # not valid
    data_key = 'Unit'
    units_mat = build_units_struct(units_data)
    write_units_data(units_mat, export_path)  # valid , use to validate at end

    
def write_tx_times(tx_times, tx_filename):
    """
    holder function to pass tests
    """
    pass


def main(phy_dir, med64_bin_path=None, export_filename='export_phy_2_nwb.mat'):
    """
    Using data transformed from PHY to NWB (EasySort) formatted data.
    Takes one, two or three positional arguments. 
    phy_dir : The directory path of the PHY formatted spike sorter output
    med64_bin_path : Path with filename of raw med64 modat data
    export_filename : filename used to export to NWB.mat file into phy_dir
    """
    phy_paths = PhyPaths(phy_dir)
    phy_data = PhyData(phy_paths)
    
    unit_spike_times = get_phy_spikes_list(phy_data.spike_times, phy_data.spk_clust)
    unit_list = sorted(list(unit_spike_times.keys()))

    signal_clust = phy_data.clust_info['group']!='noise'
    clust_chan = phy_data.clust_info[signal_clust][['cluster_id', 'ch']].to_numpy()  

    if med64_bin_path is not None:
        matrix_data = get_raw_data(med64_bin_path)
        raw_waves = get_raw_phy_spike_waves(matrix_data, unit_spike_times, 
                                            unit_list=clust_chan, sample_window_width=61)
        print(f'Raw modat datafile contains {type(raw_waves)} type data')
    else:
        print(f'No data file provided for raw modat data. Zeros for waveform output')

    phy_nwb_units = phy_2_nwb(unit_spike_times)
    phy_2_mat = build_units_struct(phy_nwb_units) 
    
    export_filepath = os.path.join(phy_dir, export_filename)    
    export_units_data(phy_nwb_units, export_filepath)
    
    
if __name__ == '__main__':
    """
    Conversion code for PHY files to NWB file formats
    This script reads in a PHY formatted data directory of spike sorter output. 
    usage: in command line type 'python phy_2_nwb.py <phy_data_directory>' 
    """
    import sys, argparse
    
    if len(sys.argv) < 2:
        raise ValueError('Please provide PHY data directory.')
    phy_dir = sys.argv[1]
    print(f'PHY data directory name is \n\t{phy_dir}')
    if len(sys.argv) >= 3:
        med64_bin_path = sys.argv[2]
        print(f'Raw modat data filename is \n\t{med64_bin_path}')
        main(phy_dir, med64_bin_path=med64_bin_path)
    else:
        main(phy_dir)
    
#  python phy_2_nwb.py /Users/walter/Data/phy_elyssa_drive/SN_test_10/20211109_15h09m07s.modat.GUI /Users/walter/Data/latest_modat/20211105_15h48m31s.modat.bin

