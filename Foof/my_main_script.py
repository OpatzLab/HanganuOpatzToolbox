# -*- coding: utf-8 -*-
"""
Created on Mon Apr 16 11:49:39 2018

@author: mchini
"""

import scipy.io as scio
from fooof import FOOOF
import numpy as np
import matplotlib.pyplot as plt

## set your path and variable names here

path_load = "Q:\\Personal\\Mattia\\PyrProject\\analysis\\fooof-opatzlab\\data\\" ## 
name_file_spectra = "NeoDlxCheta" # JunDlxCheta NeoDlxArchT NeoDlxCheta
name_matlab_variable_spectra = 'PowerSpectra' # the name of the 
name_file_freqs = "freqs"
name_matlab_variable_freqs = 'freq'


spectra = scio.loadmat(path_load + name_file_spectra)[name_matlab_variable_spectra]
freqs = np.squeeze(scio.loadmat(path_load + name_file_freqs)[name_matlab_variable_freqs])

spectra_pre = spectra[:, :, 0]
spectra_post = spectra[:, :, 1]
## set variable values

freq_range = [1, 100]
peak_width_limits=[1, 5]
max_n_peaks = 20


peaks_params_pre = np.zeros((np.shape(spectra_pre)[0], max_n_peaks, 3))
background_params_pre = np.zeros((np.shape(spectra_pre)[0], 2))
peaks_params_post = np.zeros((np.shape(spectra_post)[0], max_n_peaks, 3))
background_params_post = np.zeros((np.shape(spectra_post)[0], 2))

for spectra_idx in np.arange(0, np.shape(spectra_pre)[0]):
    
    fm = FOOOF(max_n_peaks=max_n_peaks, peak_width_limits=peak_width_limits)
        
    fm.fit(freqs, np.squeeze(spectra_pre[spectra_idx, :]), freq_range)
    peaks_param = fm.peak_params_
    peaks_params_pre[spectra_idx, 0 : np.shape(peaks_param)[0], 0 : np.shape(peaks_param)[1]] = peaks_param
    background_params_pre[spectra_idx, :] = fm.background_params_
    
    fm.fit(freqs, np.squeeze(spectra_post[spectra_idx, :]), freq_range)
    peaks_param = fm.peak_params_
    peaks_params_post[spectra_idx, 0 : np.shape(peaks_param)[0], 0 : np.shape(peaks_param)[1]] = peaks_param
    background_params_post[spectra_idx, :] = fm.background_params_



#results_peaks = dict([(name_file_to_be_saved_peaks, peaks_params)])
#results_background = dict([(name_file_to_be_saved_background, background_params)])

#scio.savemat(path_save + name_file_to_be_saved_peaks, results_peaks)
#scio.savemat(path_save + name_file_to_be_saved_background, results_background)

power_pre = np.sum(peaks_params_pre[:, :, 1] * peaks_params_pre[:, :, 2], 1)
power_post = np.sum(peaks_params_post[:, :, 1] * peaks_params_post[:, :, 2], 1)
power_4_plot = np.concatenate((power_pre, power_post))

f, ax = plt.subplots()
ax.scatter(power_pre, power_post)
ax.set(xlim=(min(power_4_plot)-1, max(power_4_plot)+1), ylim=(min(power_4_plot)-1, max(power_4_plot)+1))
ax.plot(ax.get_xlim(), ax.get_ylim())
plt.title('power')

background_4_plot = np.concatenate((background_params_pre[:, 1], background_params_post[:, 1]))

f, ax = plt.subplots()
ax.scatter(background_params_pre[:, 1], background_params_post[:, 1])
ax.set(xlim=(min(background_4_plot) - 1, max(background_4_plot) + 1), ylim=(min(background_4_plot) - 1, max(background_4_plot) + 1))
ax.plot(ax.get_xlim(), ax.get_ylim())
plt.title('1/f slope')








