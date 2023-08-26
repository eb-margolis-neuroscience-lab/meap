import os, shutil, csv
import numpy as np
from scipy.io import savemat

try:
    from waveform import (Fs, PhyPaths, PhyData, get_raw_data, 
                          get_phy_spikes_list, get_raw_phy_spike_waves)
    from meappy.configuration import USER_PATHS, USER, XL_COLS

except:
    waveform_dir = '.waveform'  # relative module path for ipynb import
    waveform_import_str = (f'from {waveform_dir} import (Fs, PhyPaths, PhyData, ' + \
                           f'get_raw_data, get_phy_spikes_list, get_raw_phy_spike_waves)')
    exec(waveform_import_str)
        

def write_int_array_to_tsv(filepath, data_array):
    """ Writes to a TSV file a two dimensional array as integers
    serperated by tabs
    Params:
        filepath: string, full file path to saved file
        data_array: np.ndarray, 2D array of integers
    Returns: None
    """
    header = "unit\tchannel"
    np.savetxt(filepath, data_array, fmt='%i', delimiter="\t", 
               header=header, comments='')
    print(f'Data written to {filepath}')
    return None
    
    
def filter_good_clusters(phy_spike_data, phy_spk_clust_data, good_clust_ids, return_seconds=True):
    """
    Iterates through list of channel numbers (int)
    must use spike clusters, as the templates are not updated with 
    slices and merging of clusters.
    
    Params:
        phy_spike_data: np.ndarray, 1D array of all spikes as sample numbers.
            PHY spike_times
        phy_spk_clust_data: np.ndarray, 1d array with same shape as phy_spike_data.
            Corresponds to cluster ID of each spike in phy_spike_data. PHY spk_clust
        good_clust_ids: np.ndarray, 1D array of cluster IDs to keep. 
            PHY clust_info filtered for 'good'.
        return_seconds: bool, default True. Converts the raw PHY output from sample 
            number to time in seconds. Set to True to return the sample number instead.
       
    Returns:
        unit_spike_times: dict, keys are cluster number, values are list of spike
            times in seconds or as sample number (seconds * sampling_rate)
    """
    if return_seconds:
        samples_to_seconds = 1 / Fs  # 20kHz sampling Frequency
        phy_spike_data = phy_spike_data * samples_to_seconds
        
    good_clust_index = np.in1d(phy_spk_clust_data, good_clust_ids)
    
    good_spiketimess = phy_spike_data[good_clust_index].reshape(-1, 1)
    good_clusts = phy_spk_clust_data[good_clust_index].reshape(-1, 1)
    
    good_spiketime_clust = np.hstack((good_spiketimess, good_clusts))
    return good_spiketime_clust


def write_float_int_array_to_tsv(filepath, data_array):
    """ Writes to a TSV file a two dimensional array as floats
    in first column and tabs in second column. Separated by tabs
    Params:
        filepath: string, full file path to saved file
        data_array: np.ndarray, 2D array with 2 columns of floats and integers
    Returns: None
    """
    header = "timestamp\tunit"
    np.savetxt(filepath, data_array, fmt='%.9e \t %i', delimiter="\t", 
               header=header, comments='')
    print(f'Data written to {filepath}')
    return None


def load_spiketime_clust_arr(filepath, header=True):
    """
    Loads tsv file with spiketimes. outputs an ndarray.
    """
    if header:
        skip = 1
    else:
        skip = 0
    arr = np.loadtxt(filepath, delimiter="\t", dtype=float, skiprows=skip)
    spiketimes = arr[:, 0]
    clusts = arr[:, 1].astype(int)
    return spiketimes, clusts
    
    
def load_int_arr(filepath, header=True):
    if header:
        skip = 1
    else:
        skip = 0
    arr = np.loadtxt(filepath, delimiter="\t", dtype=int, skiprows=skip)
    return arr


def read_tx_file(tx_filename):
    """
    Returns: dict of treatement label string as key and 
    float of beginning timestamp as value.
    """
    tx_times = dict()
    with open(tx_filename) as csvDataFile:
        csvReader = csv.DictReader(csvDataFile)
        for row in csvReader:
            tx_times[row["label"]] = float(row["begin"])
    return tx_times


def extract_phy_data(phy_dir):
    phy_paths = PhyPaths(phy_dir)
    phy_data = PhyData(phy_paths)
    
    good_clust = phy_data.clust_info['group'] == 'good'  # not contain !='noise' 'NaN'
    clust_chan = phy_data.clust_info[good_clust][['cluster_id', 'ch']].to_numpy()  
    
    good_clust_ids = clust_chan[:,0]
    spiketime_clust = filter_good_clusters(phy_data.spike_times, phy_data.spk_clust, 
                                good_clust_ids, return_seconds=True)
    return spiketime_clust, clust_chan


def main(phy_dir, med64_bin_path=None, export_path=None):
    """
    Using data transformed from PHY to TSV tab seperated values formatted data.
    Takes one, two or three positional arguments.
    Params:
        phy_dir: str, The directory path of the PHY formatted spike sorter output
        med64_bin_path: str, Path with filename of raw med64 modat data
        export_filename: str, filename used to export to tsv files into phy_dir
    """
    # set filepaths
    print(f'PHY data directory name is \n\t{phy_dir}')
    phy_paths = PhyPaths(phy_dir)
    phy_data = PhyData(phy_paths)
    
    if med64_bin_path is not None:
        print("Waveform export not yet implimented for TSV format")
    
    if export_path is None:
        export_path = phy_data
    print(f'Files exported to directory: \n\t{export_path}')
        
    # get and format data
    spiketime_clust, clust_chan = extract_phy_data(phy_dir)

    # write array  unit_electrode units_ts
    clust_chan_filepath = os.path.join(export_path, "unit_electrode.tsv")
    spiketime_clust_filepath = os.path.join(export_path, "units_ts.tsv")
    
    write_int_array_to_tsv(clust_chan_filepath, clust_chan)
    write_float_int_array_to_tsv(spiketime_clust_filepath, spiketime_clust)

    
if __name__ == '__main__':
    """
    Conversion code for PHY files to NWB file formats
    This script reads in a PHY formatted data directory of spike sorter output. 
    usage: in command line type 'python phy_2_nwb.py <phy_data_directory>' 
    Params:
        Arg 1: str, PHY data directory path
        Arg 2: str, optional, Raw modat.bin data file path
        Arg 3: str, optional, Export file path. Default is PHY dir path
    """
    import sys, argparse

    user_paths = USER_PATHS[USER]
    export_path = user_paths['phy_export']
    
    if len(sys.argv) < 2:
        raise ValueError('Missing PHY data directory path required first parameter')
    phy_dir = sys.argv[1]
    if len(sys.argv) >= 3:
        med64_bin_path = sys.argv[2]
    if len(sys.argv) == 3:
        main(phy_dir, med64_bin_path=med64_bin_path)
    if len(sys.argv) >= 4:
        export_path = sys.argv[3]
        main(phy_dir, med64_bin_path=med64_bin_path, export_path=export_path)
    else:
        main(phy_dir, export_path=export_path)
