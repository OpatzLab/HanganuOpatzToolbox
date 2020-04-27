# -*- coding: utf-8 -*-
"""
Created on Mon Apr 16 11:49:39 2018

@author: mchini
"""

import scipy.io as scio
from fooof import FOOOF
import numpy as np

## set your path and variable names here

path_load = "Q:\\Personal\\Mattia\\PyrProject\\analysis\\fooof-opatzlab\\test_data\\" ## the folder where you have the files you want to analyze
path_save = "Q:\\Personal\\Mattia\\PyrProject\\analysis\\fooof-opatzlab\\test_data\\" ## the folder where you want to save your data
name_file_spectra = "spectra" # the name of your .mat file with the power spectra
name_matlab_variable_spectra = 'Spectrumpost' # the name of the 
name_file_freqs = "freqs"
name_matlab_variable_freqs = 'freqs'
name_file_to_be_saved_peaks = 'demo_results_peaks'
name_file_to_be_saved_background = 'demo_results_background'


spectra = scio.loadmat(path_load + name_file_spectra)[name_matlab_variable_spectra]
freqs = np.squeeze(scio.loadmat(path_load + name_file_freqs)[name_matlab_variable_freqs])

## set variable values

freq_range = [4, 50]
peak_width_limits=[1.0, 3.0]
max_n_peaks = 100
plot = 0


peaks_params = np.zeros((np.shape(spectra)[0], max_n_peaks, 3))
background_params = np.zeros((np.shape(spectra)[0], 2))

for spectra_idx in np.arange(0, np.shape(spectra)[0]):
    fm = FOOOF(max_n_peaks=max_n_peaks, peak_width_limits=peak_width_limits)
    if plot == 0:
        fm.fit(freqs, np.squeeze(spectra[spectra_idx, :]), freq_range)
    else:
        fm.report(freqs, np.squeeze(spectra[spectra_idx, :]), freq_range)
           
    peaks_param = fm.peak_params_
    peaks_params[spectra_idx, 0 : np.shape(peaks_param)[0], 0 : np.shape(peaks_param)[1]] = peaks_param
    background_params[spectra_idx, :] = fm.background_params_

results_peaks = dict([(name_file_to_be_saved_peaks, peaks_params)])
results_background = dict([(name_file_to_be_saved_background, background_params)])

scio.savemat(path_save + name_file_to_be_saved_peaks, results_peaks)
scio.savemat(path_save + name_file_to_be_saved_background, results_background)