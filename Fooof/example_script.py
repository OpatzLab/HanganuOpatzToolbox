# -*- coding: utf-8 -*-
'''
Created on Mon Apr 16 11:49:39 2018

@author: mchini
'''

import scipy.io as scio
from fooof import FOOOF
import numpy as np

## set your path and variable names here
# folder where you have the files you want to analyze
# for instance, you can use the example data in Fooof/example data
# change to your folder here, but keep the forward slash '/' do not replace with '\'
path_load = 'D:/HanganuOpatzToolbox/Fooof/example data/'
# folder where you want to save your data
path_save = 'D:/HanganuOpatzToolbox/Fooof/output/'
# name of your .mat file(s) with the power spectra
# can be more than one, easier if you don't change the name of the
# matlab variable. if you do, take care of that in the next variable
name_file_spectra = ['PSD1', 'PSD2']
# name of the matlab variable in the .mat file 
# if different between recordings, name this something like
# ['var1', 'var2']
# this variable should be a matrix in which the various power spectra are
# present in the form (num_power_spectra * freq)
name_matlab_variable_spectra = 'PSD' 
# name of your .mat file with the freq vector
name_file_freqs = 'freq'
# name of the matlab variable in the .mat file
name_matlab_variable_freqs = 'freq'
# name of the output .mat file for peaks and backgroud results
names_file_to_be_saved_peaks = ['example_peaks1.mat', 'example_peaks2.mat']
names_file_to_be_saved_background = ['example_background1.mat', 'example_background2.mat']

## set variable values
# see original paper and/or github page for what these parameters mean
freq_range = [4, 50]
peak_width_limits=[1.0, 3.0]
max_n_peaks = 100
plot = 0
fm = FOOOF(max_n_peaks=max_n_peaks, peak_width_limits=peak_width_limits)

for name_file_spectrum, name_peaks, name_backgroud in zip(
        name_file_spectra, names_file_to_be_saved_peaks, names_file_to_be_saved_background):
    
    spectra = scio.loadmat(path_load + name_file_spectrum)[name_matlab_variable_spectra]
    freqs = np.squeeze(scio.loadmat(path_load + name_file_freqs)[name_matlab_variable_freqs])
    
    

    peaks_params = np.zeros((np.shape(spectra)[0], max_n_peaks, 3))
    background_params = np.zeros((np.shape(spectra)[0], 2))
    
    for spectra_idx in range(np.shape(spectra)[0]):
        
        if plot == 0:
            fm.fit(freqs, np.squeeze(spectra[spectra_idx, :]), freq_range)
        else:
            fm.report(freqs, np.squeeze(spectra[spectra_idx, :]), freq_range)
    
        peaks_param = fm.peak_params_
        peaks_params[spectra_idx, 0 : np.shape(peaks_param)[0], 0 : np.shape(peaks_param)[1]] = peaks_param
        background_params[spectra_idx, :] = fm.background_params_
    
    results_peaks = dict([('peaks', peaks_params)])
    results_background = dict([('background', background_params)])
    
    scio.savemat(path_save + name_peaks, results_peaks)
    scio.savemat(path_save + name_backgroud, results_background)
    
    