#!/usr/bin/env python
# coding: utf-8

## VERSION NOTE: observable_nwb is modified from observable_v2 such that it will process nwb PHY files of spikes instead of the .mat spikes output from EasySort

# incorportates the jupyter notebook code as of 2023-02-13
# previous version titled med64_qq_fr_new_filetypes.py saved 2021-10-12 13:35

# ## Exports Med64 Data to QQ D3 Data for Observable Notebook ##

import os, re
import yaml
import csv
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import scipy.io
from scipy import signal, stats

import numpy as np
import matplotlib.pyplot as plt
import statsmodels.api as sm

import pandas as pd
from functools import partial
from collections.abc import Iterable


# meappy module
from med64_data import *
from phy_2_nwb import load_spiketime_clust_arr
from meappy.parameter_yaml import USER, USER_PATHS

from matplotlib import cm
cmap = cm.get_cmap('tab20')


MAX_SAMPLES = 32  # default when no df for get_max_samples(df, MAX_D3_ROWS)
MAX_D3_ROWS = 10000 # local constant used in num_new_points()


from med64_data import *


def find_better_expt_files(data_dir):
    files = os.listdir(data_dir)

    re_units = re.compile(r'^EBM_betterResults.*')
    re_tx = re.compile(r'^treatmentinfo.*')
    re_expr_id = re.compile(r"([0-9]{3}_[0-9]{2}h[0-9]{2}m[0-9]{2}s)\.['csv|mat']{3}")

    unit_files = dict()
    tx_files = dict()

    for file in files:
        expr_id = re_expr_id.findall(file)
        if expr_id:
            units_file = re_units.findall(file)
            if units_file:
                unit_files[expr_id[0]] = units_file[0]
            tx_file = re_tx.findall(file)
            if tx_file:
                tx_files[expr_id[0]] = tx_file[0]
    expt_list = sorted(list(unit_files.keys()))

    print('FOUND Data FILES:')
    print('Experiment IDs: \n\t' + '\n\t'.join(expt_list))
    print('Units Files: \n\t' + '\n\t'.join(unit_files.values()))
    print('Treatment Files: \n\t' + '\n\t'.join(tx_files.values()))
    
    return expt_list, tx_files, unit_files




# ### Firing Rate Calc
def mean_firing_rates(units_data, tx_times):
    """
    get firing rate of a units in Hz
    depricated
    """
    num_units = len(units_data)
    start_time_sec = list(tx_times.values())[0]
    end_time_sec = list(tx_times.values())[-1]
    duration_s = end_time_sec - start_time_sec
    
    mean_firing_rate_hz = dict()
    all_unit_activity_count = 0
    for (id, data) in units_data.items():
        timestamps = data['timestamps']
        activity_count = timestamps.shape[0]
        mean_firing_rate_hz[id] = activity_count / duration_s
        all_unit_activity_count += activity_count
        
    all_unit_mean_fr_hz = all_unit_activity_count / duration_s / num_units
    return all_unit_mean_fr_hz, mean_firing_rate_hz


# ## Next cell needs following get_tx_ranges() code executed first
def get_mean_firing_by_tx(units_data, tx_times):
    """
    get mean firing rate of units in Hz for each treatment (tx)
    """
    tx_range = get_tx_ranges(tx_times)
    print(f"tx_range: {tx_range},   tx_times {tx_times}")
    tx_mean_firing_rate_hz = dict()
    for tx in tx_range.keys():
        tx_mean_firing_rate_hz[tx] = {}
    for (unit_id, data) in units_data.items():
        for (tx, [start_time, end_time]) in tx_range.items():
            timestamps = data['timestamps']
            duration = end_time - start_time
            activity_count = [ts for ts in units_data[unit_id]['timestamps'] if 
                 (ts > start_time) and (ts < end_time)]
            tx_mean_firing_rate_hz[tx][unit_id] = len(activity_count)/duration
    print(f"tx_mean_firing_rate_hz: {tx_mean_firing_rate_hz.keys()}")
    return tx_mean_firing_rate_hz


def get_firing_rate_df(df_d3, mean_firing_by_tx):
    """
    create new dataframe with firing rate data formatted to qq dataframe
    """
    firing_rate_df = pd.DataFrame(columns = (df_d3.columns.tolist() + ['Firing Rate']))
    df_index = 0
    for tx in mean_firing_by_tx.keys():
        for unit in mean_firing_by_tx[tx].keys():
            fr = mean_firing_by_tx[tx][unit]
            nan_cols = firing_rate_df.columns.shape[0] - 4
            firing_rate_df.loc[df_index] = ([np.nan, unit, tx] + [np.nan] * nan_cols + [fr])
            df_index += 1
    return firing_rate_df


def get_nwb_data(unit_filename, tx_filename):
    """
    This reads new nwb file types using load_spiketime_clust_arr 
    from phy_2_nwb module
    """
    print(f"get_nwb_data with file: {unit_filename}")
    units_data = load_spiketime_clust_arr(unit_filename)
    units_data = units_data_nwb_2_mat_format(units_data)
    tx_times = read_tx_file(tx_filename)
    print(f"get_nwb_data tx_times are: {tx_times}")
    return units_data, tx_times


#  next line is to create from raw file input
def get_mean_firing_rates(unit_files, tx_files):
    units_data, tx_times = get_nwb_data(unit_files, tx_files)    
    mean_firing_by_tx = get_mean_firing_by_tx(units_data, tx_times)
    return mean_firing_by_tx


# # A more accurate versoin of get_tx_ranges  
# * Use this when I have time to modify the d3 code to display it.
# * Also, check if there are timestamps beyond the "TTX off" and allow for arbitrary end time to last range

# import operator

# def get_tx_ranges(tx_times):
#     tx_ranges = {}
#     sorted_tx_times = sorted(tx_times.items(), key=operator.itemgetter(1))
#     prev_tx = None
#     prev_time = None
#     for tx, time in sorted_tx_times:
#         if (prev_tx != None) and (prev_time != time):
#             tx_ranges[prev_tx.strip()] = [prev_time, time]
#         prev_tx = tx
#         prev_time = time
#     return tx_ranges
# THIS IS ACCURATE VERSION DONT DELETE


def get_tx_ranges(tx_times):
    all_times = sorted(list(tx_times.values()))
    last_time_index = len(all_times) - 1
    tx_range = dict()
    for tx, time in tx_times.items():
        time_index = all_times.index(time)
        if time_index == last_time_index:
            break
        next_time = all_times[time_index + 1]
        if time >= next_time:
            continue
        tx_range[tx.strip()] = [time, next_time]
    return tx_range


# ### Speed up get_timestamp_...
# by using lookup in a table generated by array functions instead of loops
def get_timestamp_tx(ts, tx_range):
    for tx, times in tx_range.items():
        if (ts >= times[0]) & (ts < times[1]):
            return tx
    return 'No Tx'
        
def get_timestamp_begin(ts, tx_range):
    for tx, times in tx_range.items():
        if (ts >= times[0]) & (ts < times[1]):
            return times[0]
    return np.nan   
    
def get_timestamp_end(ts, tx_range):
    for tx, times in tx_range.items():
        if (ts >= times[0]) & (ts < times[1]):
            return times[1]
    return np.nan 

def units_data_nwb_2_mat_format(units_data):
    """
    Many functions in this code were originally written to take .mat
    formatted data. So this converts the NWB from PHY spike time data
    and reformats it as this code expects.
    """
    nwb_data = dict()
    ts_array = units_data[0]
    id_array = units_data[1]
    for unit_id in np.unique(id_array):
        ts_index_array = np.where(id_array == unit_id)
        timestamps = ts_array[ts_index_array]
        nwb_data[unit_id] = {'timestamps': "test", 'waveform': None}
        nwb_data[unit_id]['timestamps'] = timestamps
    return nwb_data


def build_df(units_data, tx_times):
    tx_range = get_tx_ranges(tx_times)
    time_tx = partial(get_timestamp_tx, tx_range = tx_range)
    time_begin = partial(get_timestamp_begin, tx_range = tx_range)
    time_end = partial(get_timestamp_end, tx_range = tx_range)

    # print(type(list(units_data.values())[1]))
    # for i in range(4):
    #     print(units_data[0]['timestamps'][i])
 
    # units_data from .mat is a dict with 54 elements, 
    # keys are units as int 0,1, etc
    # each value has a dict with 2 keys ['timestamps', 'waveform']
        # inside 'timestamps' are values in an np.ndarray of np.float64
        # these are time in sec.




    # print(len(units_data[0]), len(units_data[1])) 
    # print(np.unique(units_data[1], return_counts=True))
    # for i in range(0,400,100):
    #     print(units_data[1][i])
    # units_data from nwb is tuple with 2 np.ndarrya of 8k rows if np.floats
    # tuple element 0 is times in sec., element 1 looks like unit numbers 
    # if DEBUGGING_NWB:
        # nwb_data = dict()
        # ts_array = units_data[0]
        # id_array = units_data[1]
        # for unit_id in np.unique(id_array):
        #     ts_index_array = np.where(id_array == unit_id)
        #     timestamps = ts_array[ts_index_array]
        #     # print(unit_id, len(timestamps))
        #     nwb_data[unit_id] = {'timestamps': "test", 'waveform': None}
        #     nwb_data[unit_id]['timestamps'] = timestamps
        #     # print(len(nwb_data[unit_id]['timestamps']))

        # units_data = units_data_nwb_2_mat_format(units_data)

        # print(type(list(nwb_data.values())[1]))
        # probe_unit = np.unique(id_array)[0]
        # print(probe_unit)
        # for i in range(4):
        #     print(nwb_data[probe_unit]['timestamps'][i])

        # for (unit_id, data) in units_data.items():
        #     print(unit_id)



    df = None
    # for loop over units
    for unit_id in list(units_data.keys()):
        timestamps = units_data[unit_id]['timestamps']

        unit_df = pd.DataFrame(timestamps, columns=['timestamp'])
        unit_df['unit'] = unit_id
        if isinstance(df, pd.DataFrame):
            df = df.append(unit_df, ignore_index=True)
        else:
            df = unit_df
    
    # end loop over units
    df['tx'] = df['timestamp'].map(lambda x: time_tx(x))
    df['begin'] = df['timestamp'].map(lambda x: time_begin(x))
    df['end'] = df['timestamp'].map(lambda x: time_end(x))

    ts_groups = df.groupby(by = ['unit', 'tx'])
    df['group_idx'] = ts_groups['timestamp'].cumcount()+1
    
    ts_groups = df.groupby(by = ['unit', 'tx'])
    df['cum_dist'] = ts_groups['group_idx'].apply(lambda df: df/df.count())
    print(f"DF Columns for tx: {df.columns}")
    print(f"DF tx unique: {df['tx'].unique()}") 
    return df


def add_anchors(df):
    anchors_begin = df[['unit', 'tx', 'begin', 'end']].drop_duplicates()
    anchors_begin.dropna(inplace=True)
    anchors_end = anchors_begin.copy()
    
    anchors_begin['cum_dist'] = 1
    anchors_begin['timestamp'] = anchors_begin['end']

    anchors_end['cum_dist'] = 0
    anchors_end['timestamp'] = anchors_end['begin']
    
    return pd.concat([df, anchors_begin, anchors_end], axis=0, ignore_index=True)


# ## Export QQ data for d3 Linked Brushing Cross-filtering
def data_to_qq(unit_files, tx_files):
    units_data, tx_times = get_nwb_data(unit_files, tx_files)
    print(f"data_to_qq: tx_times: {tx_times}")
    df = build_df(units_data, tx_times)
    df = add_anchors(df)

    df = df[df['tx'] != 'No Tx'] # drop times outside treatment time ranges
    df['x_plot'] = (df['timestamp']-df['begin'])/(df['end']-df['begin'])
    
    # sort zero anchors to beginning of dataframe
    df.sort_values(by=['unit', 'x_plot'], inplace=True)
    
    return df


def get_max_samples(df, max_d3_rows):
    """Returns the max samples per unit per treatment for d3 observable total_rows
    Older versions of this code returned the constant MAX_SAMPLES = 10000.
    """
    max_samples = round(max_d3_rows / df.unit.unique().size / df.tx.unique().size)
    return max_samples


def downsample_data(df, max_d3_rows):
    """downsamples the data in each unit so that the max total size of data will
    work in d3 plot. If more units, then data per unit is larger.
    """
    max_samples = get_max_samples(df, max_d3_rows)
    df_downsampled = None

    downsample_groups = df.groupby(by=['unit', 'tx'])

    for by, grp in downsample_groups:
    #     if (by[0] == 5): # & (by[1] == 'DAMGO 500nM On'):
        grp.sort_values(by='x_plot', inplace=True)
        samples = grp.shape[0]
        downsample_rate = round(np.floor(samples / max_samples))
        downsample_rate = 1 if downsample_rate < 1 else downsample_rate
        if isinstance(df_downsampled, pd.DataFrame):
            df_downsampled = df_downsampled.append(grp.iloc[:-1:downsample_rate])
        else:
            df_downsampled = grp.iloc[:-1:downsample_rate] # don't add anchor here
        # add final anchor now, because downsampling could have excluded it
        df_downsampled = df_downsampled.append(grp.iloc[-1:])
#         print(downsample_rate, samples)
#         print(grp.iloc[::downsample_rate])
#         print(grp.iloc[::downsample_rate].shape)
#         print(df_downsampled.shape)
    return df_downsampled

    
def groups_with_gaps(group_activity, num_segments): 
    gap_groups = []
    for i, v in group_activity:
#     if i[0] < 3:
#         print(i)
        spikes = v.timestamp.values
        begin = v.iloc[0,:]['begin']
        end = v.iloc[0,:]['end']
        segments = np.linspace(begin, end, num_segments)
        prev_seg = segments[0]
        is_gap = False
        for seg in segments[1:]:
            gap_activity = [s for s in spikes if ((s > prev_seg) & (s < seg))]
#             print(len(gap_activity))
            if len(gap_activity) == 0:
                is_gap = True
        if is_gap:
            gap_groups.append(i)
    return gap_groups
    

def activity_gaps_unit_tx(df, d3_sample_threshold):
    """return list of tuples with (unit, tx) for unit with gaps in
    activity that will not have enough points on d3 lines
    The arg d3_sample_threshold is expected to be the output from get_max_samples()"""
    num_segments = int(d3_sample_threshold/2)
    group_activity = df.groupby(by=['unit', 'tx'])[['timestamp', 'begin', 'end']]
    return groups_with_gaps(group_activity, num_segments)


def euclidist(xy_array):
    """Takes array of x,y coord and calculates the euclidean distance between 
    successive pairs.
    returns array of distances. first is zero, to maintain same length as coord array.
    """
#     min_dist = 1.5 / len(xy_array)
    dist = np.array([0])
    prev_row = xy_array[0]
    for row in xy_array[1:]:
        x_diff = row[0] - prev_row[0]
        y_diff = row[1] - prev_row[1]
        dist = np.append(dist, np.sqrt(x_diff**2 + y_diff**2))
        prev_row = row
#     num_new_points = np.floor(np.array(dist / min_dist))
    return dist


def get_num_new_points(df, dist_array, max_d3_rows):
    """returns number of points to be added before each index of a
    distance array.
    Assumes total distance of 2 (between sqrt(2) and 2) for qq plot.
    Adjust this number to change density of new points added.
    """
    expected_total_dist = 2 #1.5
    min_dist = expected_total_dist / get_max_samples(df, max_d3_rows)
    return np.floor(np.array(dist_array / min_dist))


def interp_points(xy_array, num_new_points):
    x0, y0 = xy_array[0]
    new_points = None
    iterator = enumerate(num_new_points)
    for i, n in iterator:
        if (i != 0):
            if (n > 0):
                x0, y0 = xy_array[i - 1]
                x1, y1 = xy_array[i]
                # divide new points along longest of x or axes
                run = x0 - x1
                rise = y0 - y1
                if ((rise/run) < 1):
                    _x = np.linspace(x0, x1, num=int(n + 2))
                    _x = _x[1:-1]  # remove end points because they're not new points
                    _y = np.interp(_x, [x0, x1], [y0, y1])
                else:
                    _y = np.linspace(y0, y1, num=int(n + 2))
                    _y = _y[1:-1]  # remove end points because they're not new points
                    _x = np.interp(_y, [y0, y1], [x0, x1])
                interp_coords = np.column_stack((_x, _y))
                if not isinstance(new_points, np.ndarray):
                    new_points = interp_coords
                else:
                    new_points = np.vstack((new_points, interp_coords))
#     print("interpolating " + str(len(new_points)) + " new points")                    
    return new_points 


def get_interp_points_df(df_downsampled, interp_units, max_d3_rows):
    """Takes dataframe of processed points for d3 of qq plots.
    returns another df with same columns but interpolated 
    data points to fill in gaps in raw data. Interpolated points
    aid in selecting in interactive d3 charts.
    """
    tmp_downsampled_df = df_downsampled.iloc[0, :].copy()
    col_names = df_downsampled.columns
    # print(col_names)
    # print(col_names.to_list().index('cum_dist'))

    interp_points_for_df = None

    for unit, tx in interp_units:
#         print("Unit " + str(unit) + " " + tx)
        df_line = df_downsampled[(df_downsampled.unit==unit) & (df_downsampled.tx==tx)]
        xy_array = df_line[['x_plot', 'cum_dist']].to_numpy()
    #     line_euclidist = euclidist(df_line[['cum_dist', 'x_plot']].to_numpy())
        num_new_points = get_num_new_points(df_downsampled, euclidist(xy_array), max_d3_rows)
        new_points = interp_points(xy_array, num_new_points)
        if isinstance(new_points, Iterable):
        #     print("orig num points " + str(len(xy_array)))
        #     print(new_points)
            base_row = df_line.iloc[0:1,:].copy()
            base_row['timestamp'] = np.nan
            collect_rows = base_row  # remove this first dimension holding row after loop
        #     print(base_row.values)
            for x, y in new_points:
                x_index = col_names.to_list().index('x_plot')
                y_index = col_names.to_list().index('cum_dist')
                new_row = base_row.values
                new_row[0][x_index] = x
                new_row[0][y_index] = y 
                collect_rows = np.vstack((collect_rows, new_row))
            collect_rows = collect_rows[1:]
            if not isinstance(interp_points_for_df, np.ndarray):
                interp_points_for_df = collect_rows
            else:
                interp_points_for_df = np.vstack((interp_points_for_df, collect_rows))
        
    print("total interpolated points " + str(interp_points_for_df.shape))      
    interp_df = pd.DataFrame(data = interp_points_for_df, columns = col_names)

    return interp_df


def clean_column_header(df):
    """Removes column headers not needed for export.
    Changes name of x-value header."""
    df_d3 = df.copy()
    df_d3.drop(["begin", "end", "group_idx"], axis=1, inplace=True)
    df_d3.rename(columns={"x_plot": "x_idx"}, inplace=True)
    return df_d3


def pad_data(df):
    """This pads the data with empty columns all filled with NaN values.
    This is the format currently used by the d3 chart."""
    df_d3 = df.copy()
    tx_list = df_d3.tx.unique()

    for tx in tx_list: 
        df_d3[tx] = df_d3[['tx', 'cum_dist']].apply(
            lambda df, tx: df['cum_dist'] if (df['tx']==tx) else np.nan,
            axis=1, tx=tx)
    return df_d3


def export_d3_data(df_d3, expt_id):
    print(expt_id)
    save_csv_filepath_dir = '/Users/walter/Src/meap/notebooks/obs_crossfilter_plots_data/'
        # '/Users/walter/Data/margolis/observable/'
#     save_csv_filepath = save_csv_filepath_dir + 'qq_for_d3_10K_interp_' + expt_id + '.csv'

    # d3_cum_fr_10K_interp => d3_nwb1_
    save_csv_filepath = save_csv_filepath_dir + 'd3_nwb1_' + expt_id + '.csv'

    df_d3.to_csv(save_csv_filepath, index = False)

    print('\tSaved ' + save_csv_filepath)


def export_from_filelist(expt_list, datafile_args, interp=True, max_d3_rows=MAX_D3_ROWS):
    """
    expt_list is list of tuples with [(slice_id, unit_filepath), ...]
    """
    for slice_id, unit_file in expt_list:
        df = data_to_qq(unit_file, datafile_args)
        print(f"data_to_qq: {df['tx'].unique()}")
        df_downsampled = downsample_data(df, max_d3_rows)
        if interp:
            interp_units = activity_gaps_unit_tx(df, get_max_samples(df, max_d3_rows))
            interp_points_df = get_interp_points_df(df_downsampled, interp_units, max_d3_rows)
            df_d3 = df_downsampled.append(interp_points_df)
            # sort interpolated date into order of full dataframe
            df_d3.sort_values(by=['unit', 'x_plot'], inplace=True)
        df_d3 = clean_column_header(df_d3)
        df_d3 = pad_data(df_d3)

        print(f"export_from_filelist: datafile_args: {datafile_args}")
        mean_firing_by_tx = get_mean_firing_rates(unit_file, datafile_args) # get_mean_firing_by_tx(units_data, tx_times)
        firing_rate_df = get_firing_rate_df(df_d3, mean_firing_by_tx)
        df_d3 = firing_rate_df.append(df_d3)
        export_d3_data(df_d3, slice_id)


def file_attachment_list(expt_list):
#     save_csv_filepath_dir = '/Users/walter/Data/margolis/observable/'
    attach_list = "["
    for expt_id in expt_list:
        filename = "FileAttachment(\'d3_cum_fr_10K_interp_" + expt_id + ".csv\')"
        attach_list += filename + ",\n"
    attach_list += "]"
#     return attach_list
    print(attach_list)


def main():
    import warnings
    warnings.filterwarnings('ignore')


    # med64 data .mat input / Not Debugging NWB
    if not DEBUGGING_NWB:
        DATA_DIR = '/Users/walter/Data/med64/experiment/VTA_NMDA/20211005_17h33m55s/' # walter local
    else:
        # DATA_DIR = '/Users/walter/Data/z4/20190808_11h58m51s/' # walter local
        DATA_DIR = '/Users/walter/Data/z4/20190808_15h00m18s/' # walter local
    
    SLICE_PARAMS_FILE = 'slice_parameters.yaml'
    
    splice_params_filepath = os.path.join(DATA_DIR, SLICE_PARAMS_FILE)
    expt_list, tx_files, unit_files = find_expt_files(splice_params_filepath)

    export_from_filelist([(expt_list, unit_files)], tx_files, expt_list, 
                         max_d3_rows=MAX_D3_ROWS)
    

DEBUGGING_NWB = True
if not DEBUGGING_NWB:
    get_nwb_data = get_expt_data  # imported from med64_data.py for unit_ts.mat   

if __name__ == "__main__":
    main()

