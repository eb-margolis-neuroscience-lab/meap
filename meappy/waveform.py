# This module copies and modifies code from bokeh_waveform.waveform_visualizer module

from os import path
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt


Fs=20000  # sample frequency Hz
nCh=64  # number of recording electrode channels


class PhyPaths:
    """
    Object containing file info for PHY files and 
    """
    def __init__(self, phy_dir):
        # spike_times is just times, without mention of what unit
        self.spike_times = path.join(phy_dir, 'spike_times.npy')

        # spike template is same shape as spike_times, 
        # so probably assigns template to each spike
        # spike template range is from 0 to 152 (the first dimension of template, 
        # so probably unit id)
        # self.spk_template = path.join(phy_dir, 'spike_templates.npy')
        # self.templ_idx = path.join(phy_dir, 'template_ind.npy')

        # matrix of shape (U,I,J) where U appears to be the unit/cluster number, 
        # why are there still 2 more dims for template?
        # i think that the I (len = 61) is time before and after spike 
        # spike duration of 3ms (60 samples = 3ms), 
        # plotted peak is in center
        # J is len 36. could that be some version of electrodes?
        # self.template = path.join(phy_dir, 'templates.npy')
        self.spk_clust = path.join(phy_dir, 'spike_clusters.npy')
        self.clust_info = path.join(phy_dir, 'cluster_info.tsv')

        
class PhyData:
    def __init__(self, phy_paths):
        self.spike_times = np.load(phy_paths.spike_times)
        self.spk_clust = np.load(phy_paths.spk_clust)
        # self.clust_info = pd.read_csv(phy_paths.clust_info, sep='\t')
    
    
def get_raw_data(med64_bin_path):
    """
    Opens modat.bin raw med64 physiology file. Returns a numpy matrix
    64 x N dimensions. Where 64 is the channels 0 to 63 and N is the 
    int16 amplitude of each channel in 20 kHz samples
    """
    with open(med64_bin_path, "rb") as file:
        bin_data = np.fromfile(file, dtype=np.int16)
        
    bin_length = bin_data.shape[0]
    data_duration_sec = bin_length / (Fs * nCh)
    print(f'Data duration {round(data_duration_sec / 60, 1)} minutes')
    
    return np.reshape(bin_data, (nCh, -1), order='F')


def get_window(midpoint, width):
    """takes the midpoint sample of a desired window width and 
    returns the start and end samples for that window.
    Importantly, this will block the window from starting 
    below zero. All values are treated and returned as 
    integers, so they can be used as indices.
    """
    midpoint = int(midpoint)
    half_width = int(width/2)
    if (midpoint - half_width) <= 0:
        min_point = 0
        max_point = width
    else:
        min_point = midpoint - half_width
        max_point = midpoint + half_width
    return (min_point, max_point)    


def get_source_dict(matrix_data, width_samples, midpoint_sample, active_chan):
    """
    Takes the number of samples around spike to be created width_samples, 
    The active channel to look at and the sample number of 
    the spike midpoint_sample, or the sample_time of the spike
    Returns the source_dict to be used as ColumnDataSource
    if active_chan = None, then returns matrix with all channels
    Creates dict with keys like 'amp_0', 'amp_1', ...
    """
    min_sample, max_sample = get_window(midpoint_sample, width_samples)
    
    num_samples = matrix_data.shape[1]
    max_time = num_samples / Fs
    times = np.linspace(0, max_time, num=num_samples)

    source_dict = dict(time=times[min_sample:max_sample])

    # NOTE: dict key 'amplitude' is only used for basic plot example. may be deleted otherwise.
    if not active_chan == None:
        amplitudes = matrix_data[active_chan]
        source_dict['amplitude'] = matrix_data[active_chan, min_sample:max_sample]
        key = 'amp_' + str(active_chan)
        source_dict[key] = matrix_data[active_chan, min_sample:max_sample]
    else:
        default_chan = 0
        amplitudes = matrix_data[default_chan]
        source_dict['amplitude'] = matrix_data[default_chan, min_sample:max_sample]
        for ch in range(nCh):
            key = 'amp_' + str(ch)
            source_dict[key] = matrix_data[ch, min_sample:max_sample]

    return source_dict


def get_phy_spikes_list(phy_spike_data, phy_spk_clust_data):
    """
    iterates through list of channel numbers (int)
    must use spike clusters, as the templates are not updated with 
    slices and merging of clusters.
    Returns as dict.
    """
    unit_spike_times = dict()
    for time, unit in zip(phy_spike_data, phy_spk_clust_data):
        if unit in unit_spike_times:
            unit_spike_times[unit].append(time)
        else:
            unit_spike_times[unit] = list([time])
    return unit_spike_times


def get_raw_phy_spike_waves(matrix_data, unit_spike_times, 
                            unit_list, sample_window_width):
    """
    unit_list is list of units
    return dict of channels. value of each item is numpy array with dims 
    (num_spikes, raw_wave_sample_size)
    """
    # clust_info_data has clust, chan
    # unit_spike_times replaces amp_spikes_map
    # unit_list replaces chan_list
    ## todo: change `unit` to `chan`
    raw_waves = dict()
    for unit, ch in unit_list:
        spike_num = len(unit_spike_times[unit])
        raw_waves[unit] = np.ndarray((spike_num, sample_window_width))
        
    for unit, ch in unit_list:
        spike_times = unit_spike_times[unit]
        for i, time in enumerate(spike_times):
            min_point, max_point = get_window(time, sample_window_width)
            try:
                raw_spike_waveform = matrix_data[ch][min_point:(max_point+1)]
            except IndexError:
                print(f'matrix_data Index Out of Range for channel: {ch}, \
                      range:({min_point}, {max_point})')
            raw_waves[unit][i] = raw_spike_waveform
    return raw_waves


def get_wave_source_dict(raw_waves, active_chan):
    """
    Takes the number of samples around spike to be created width_samples, 
    The active channel to look at and the sample number of 
    the spike midpoint_sample, or the sample_time of the spike
    Returns the source_dict to be used as ColumnDataSource
    if active_chan = None, then returns matrix with all channels
    Creates dict with keys like 'amp_0', 'amp_1', ...
    each value is a matrix of (spike_num, wave_samples)
    times are now in msec with spike peak at zero
    """    
    num_waves = raw_waves[active_chan].shape[0]
    num_samples = raw_waves[active_chan].shape[1]
    
    sample_milsec = num_samples / (Fs / 1000)
    half_sample_milsec = round(sample_milsec/2, 2)
    times = np.linspace(-half_sample_milsec, half_sample_milsec, num=num_samples)
    print(f'times length = {times.shape}')
    source_dict = dict(time=times)

    amplitudes = raw_waves[active_chan]
    source_dict['amplitude'] = raw_waves[active_chan][0, :]
    for k in range(num_waves):
        key = 'amp_' + str(k)
        source_dict[key] = raw_waves[active_chan][k, :]

    return source_dict

