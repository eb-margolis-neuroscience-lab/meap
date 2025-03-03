## usage examples:
# python waveform_extract_order_spiketimes.py --raw True /path/to/spyking_circus_files/20190809_11h22m58s
#
## example for spyking circus directory that uses PHY subdirectory:
# python waveform_extract_order_spiketimes.py --raw True --phy_dir True /path/to/spyking_circus_files/20240201_14h34m13s


from os import path
import argparse

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

import json
                                                

Fs=20000  # sample frequency Hz
nCh=64  # number of recording electrode channels
GOOD_CLUST_MIN_SPIKES = 10

# SAMPLE_WINDOW_WIDTH sets the time range. at 20000 Hz, 121 samples is 6 milliseconds. 
# The PRE_SAMPLES sets the time range before the spike detection (zero time). 
# 30 samples is 1.5 milliseconds before the spike threshold event.
SAMPLE_WINDOW_WIDTH = 121  # 401  
PRE_SAMPLES = 30  # 200 = 10msec


def get_raw_data(med64_bin_path):
    """
    Opens modat.bin raw med64 physiology file. Returns a numpy matrix
    64 x N dimensions. Where 64 is the channels 0 to 63 and N is the 
    int16 amplitude of each channel in 20 kHz samples
    """
    with open(med64_bin_path, "rb") as file:
        bin_data = np.fromfile(file, dtype=np.int16)  # np.int16  or np.short
        
    bin_length = bin_data.shape[0]
    data_duration_sec = bin_length / (Fs * nCh)
    print(f'Data duration {round(data_duration_sec / 60, 1)} minutes')
    
    return np.reshape(bin_data, (nCh, -1), order='F')


def get_window(midpoint, width, pre_samples=None):
    """
    NEW
    takes the midpoint sample of a desired window width and 
    returns the start and end samples for that window.
    Importantly, this will block the window from starting 
    below zero. All values are treated and returned as 
    integers, so they can be used as indices.
    """
    if pre_samples is None:
        # use the half width
        midpoint = int(midpoint)
        half_width = int(width/2)
        if (midpoint - half_width) <= 0:
            min_point = 0
            max_point = width
        else:
            min_point = midpoint - half_width
            max_point = midpoint + half_width
        return (min_point, max_point)  

    if pre_samples is not None:
        midpoint = int(midpoint)
        pre_samples = int(pre_samples)
        post_samples = int(width - pre_samples - 1)
        
        if (midpoint - pre_samples) <= 0:
            min_point = 0
            max_point = width
        else:
            min_point = midpoint - pre_samples
            max_point = midpoint + post_samples
        return (min_point, max_point)  
    

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

    
def convert_spike_freq(unit_spike_times, Fs):
    """
    Takes spike times from phy in samples and converts to sec
    using Fs -- frequency per sec
    """
    new_times = dict()
    for unit in unit_spike_times:
        new_times[unit] = np.array(unit_spike_times[unit]) / Fs
    return new_times


def get_raw_phy_spike_waves(matrix_data, unit_spike_times, unit_list, \
                            sample_window_width, pre_samples):
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
        raw_waves[int(unit)] = np.ndarray((spike_num, sample_window_width))
        
    for unit, ch in unit_list:
        spike_times = unit_spike_times[unit]
        for i, time in enumerate(spike_times):
            min_point, max_point = get_window(time, sample_window_width, pre_samples)
            try:
                raw_spike_waveform = matrix_data[ch][min_point:(max_point+1)]
            except IndexError:
                print(f'matrix_data Index Out of Range for channel: {ch}, range:({min_point}, {max_point})')
            try:
                raw_waves[int(unit)][i] = raw_spike_waveform
            except ValueError:
                print(f'MyValueError: raw_spike_waveform shape {raw_spike_waveform.shape}')
    return raw_waves


def get_ordered_raw_phy_spike_waves(matrix_data, unit_spike_times, unit_list, \
                            sample_window_width, pre_samples):
    """
    modified from get_raw_phy_spike_waves() to return a dict with 
    spike time at beginning of each waveform. spiketime will be in int
    with 20kHz per sample.
    
    unit_list is list of units
    return dict of channels. value of each item is numpy array with dims 
    (num_spikes, raw_wave_sample_size)
    """
    
    # clust_info_data has clust, chan
    # unit_spike_times replaces amp_spikes_map
    # unit_list replaces chan_list
    ## todo: change `unit` to `chan`
    
    raw_waves = dict()
    raw_times = dict()
    
    # allocate arrays
    for unit, ch in unit_list:
        spike_num = len(unit_spike_times[unit])
        raw_waves[int(unit)] = np.ndarray((spike_num, sample_window_width))
        raw_times[int(unit)] = np.ndarray((spike_num, 1))

    for unit, ch in unit_list:
        spike_times = unit_spike_times[unit]
        for i, time in enumerate(spike_times):
            min_point, max_point = get_window(time, sample_window_width, pre_samples)
            try:
                raw_spike_waveform = matrix_data[ch][min_point:(max_point+1)]
            except IndexError:
                print(f'matrix_data Index Out of Range for channel: {ch}, range:({min_point}, {max_point})')
            try:
                raw_waves[int(unit)][i] = raw_spike_waveform
                raw_times[int(unit)][i] = time
                # raw_waves[int(unit)][WAVES][i] = raw_spike_waveform
            except ValueError:
                print(f'MyValueError: raw_spike_waveform shape {raw_spike_waveform.shape}')
                
    times_waves = dict()
    times_waves['waves'] = raw_waves
    times_waves['times'] = raw_times
    
    return times_waves


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


if __name__ == '__main__':
    # Command line of this code has a required argument of the path/to/expt_date_dir/
    # This code depends on the file structure. The default is for both the 
    # expt_date.modat.bin file and the expt_date.modal.GUI directory of PHY files to 
    # be in the same `expt_date` folder. However, sometimes the GUI dir is in a 
    # subdirectory call PHY. in that case, adding the --phy_dir flag will look 
    # in the correct place.
    # There is also a flag for toggling automatic displaying of waveforms.

    parser = argparse.ArgumentParser(description='waveform export')
    parser.add_argument(dest='expt_date_dir', action="store")
    parser.add_argument('--plots', '-p', action="store", dest='plots', default=True)
    parser.add_argument('--phy_dir', action="store", dest='phy_dir', default=False)
    parser.add_argument('--raw', action="store", dest='raw', default=False)
    args = parser.parse_args()
    print(f"Show plots: {args.plots}")
    print(f"save raw waveforms: {args.raw}")


    modat_path = args.expt_date_dir
    expt_id = path.basename(modat_path)


    bin_file = expt_id + '.modat.bin'
    phy_dir = expt_id + '.modat.GUI'
    med64_bin_path = path.join(modat_path, bin_file)
    
    if args.phy_dir:
        phy_path = path.join(modat_path, 'PHY', phy_dir) # for April2024 & raw_unfiltered_bin_files
        export_path = path.join(modat_path, 'PHY')
    else:
        phy_path = path.join(modat_path, phy_dir)
        export_path = modat_path
    
    wave_file = expt_id + '_waves.tsv'   
    wave_export_path = path.join(export_path, wave_file)
    raw_wave_file = expt_id + '_waves_raw.json'
    raw_wave_export_path  = path.join(export_path, raw_wave_file)
    
    # spike_times is just times, without mention of what unit
    phy_spike_times_path = path.join(phy_path, 'spike_times.npy')

    # spike template is same shape as spike_times, so probably assigns template to each spike
    # spike template range is from 0 to 152 (the first dimension of template, so probably unit id)
    phy_spk_template_path = path.join(phy_path, 'spike_templates.npy')
    phy_templ_idx_path = path.join(phy_path, 'template_ind.npy')

    # matrix of shape (U,I,J) where U appears to be the unit/cluster number, why are there still 2 more dims for template?
    # i think that the I (len = 61) is time before and after spike of 3ms (60 samples = 3ms), plotted peak is in center
    # J is len 36. could that be some version of electrodes?
    phy_spk_clust_path = path.join(phy_path, 'spike_clusters.npy')
    phy_spike_data = np.load(phy_spike_times_path)
    phy_spk_clust__data = np.load(phy_spk_clust_path)
    phy_clust_info_path = path.join(phy_path, 'cluster_info.tsv')
    clust_info_data = pd.read_csv(phy_clust_info_path, sep='\t')

    # clust_info_data['clust_info_data', 'ch', 'group']
    good_clust = (clust_info_data['group']=='good') & \
                (clust_info_data['n_spikes']>=GOOD_CLUST_MIN_SPIKES)
    clust_chan = clust_info_data[good_clust][['cluster_id', 'ch']].to_numpy() 

    
    # This step takes time
    matrix_data = get_raw_data(med64_bin_path)

    
    unit_spike_times = get_phy_spikes_list(phy_spike_data, phy_spk_clust__data)
    unit_spike_fs_times = convert_spike_freq(unit_spike_times, Fs)
    
    
    
    
    ### CHANGE FOR ORDERED
    times_waves = get_ordered_raw_phy_spike_waves(
        matrix_data, unit_spike_times, unit_list=clust_chan, 
        sample_window_width=SAMPLE_WINDOW_WIDTH, pre_samples=PRE_SAMPLES)

    raw_waves = times_waves['waves'] 
    raw_times = times_waves['times']
    
    print(f"Wave clusters found: {raw_waves.keys()}")

    # This needs to be updated to new times_waves format
    if args.plots == 'True':
        print(f"arg.plots is {args.plots}")
        for clust in range(clust_chan.shape[0]):
            plt.plot(np.mean(raw_waves[clust_chan[clust][0]][WAVES][:], axis=0))
            plt.show()
        print("plots done")
    else:
        print(f"arg.plots is {args.plots}, not 'True'")
        

    # new ordered times
    if True: #args.raw == 'True':
        print(f"exporting all raw waves as {raw_wave_export_path}")
        raw_waves_json = dict()
        raw_times_json = dict()
        for clust in times_waves['waves'].keys():
            raw_waves_json[int(clust)] = times_waves['waves'][clust].tolist() 
            raw_times_json[int(clust)] = times_waves['times'][clust].tolist() 
        print(type(raw_waves_json[int(clust)]))

        times_waves_json = {'waves': raw_waves_json,
                            'times': raw_times_json}

        raw_header = "Raw waves are in JSON format " \
            "{'clust_id': [nested list of 121 sample waveforms for clust_id]}. " \
            "All waveforms are 20kHz with the spike triggered at sample 31."
        
        raw_header = "Raw waves are in JSON format " \
            "{{'waves': {'clust_id': [nested list of 121 sample waveforms for clust_id]}}," \
            "{'times': {'clust_id': [list of times of each wave]}}}." \
            "All waveforms are 20kHz with the spike triggered at sample 31."
            
        with open(raw_wave_export_path, 'w') as fp:
            json.dump(times_waves_json, fp)



    waveforms = None
    for clust in range(clust_chan.shape[0]):
        mean_waveform = np.mean(raw_waves[clust_chan[clust][0]][:], axis=0)
        # Add the cluster number to the beginning of the waveform
        clust_id = clust_chan[clust][0]
        mean_waveform = np.concatenate(([clust_id], mean_waveform))
        if waveforms is None:
            waveforms = mean_waveform
        else:
            waveforms = np.vstack((waveforms, mean_waveform))
        if clust_chan.shape[0] == 1:
            waveforms = np.reshape(waveforms, (-1, SAMPLE_WINDOW_WIDTH))
        
        
    np.savetxt(wave_export_path, waveforms, fmt='%.6f', delimiter="\t", \
              header= f'Waveforms: rows are units; first column is PHY cluster id; columns are times at 20k Hz; Cluster IDs in order: {list(raw_waves.keys())}', \
              comments='# ')
    print(f"waveforms saved to: {wave_export_path}")
    