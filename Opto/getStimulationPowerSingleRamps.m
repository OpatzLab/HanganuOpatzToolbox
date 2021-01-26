function [StimPowerRamps] = getStimulationPowerSingleRamps(experiment,...
    CSC, save_data, repeatCalc, folder4stim_props, folder2save)
% by Mattia, 01/21
% this script computes the power for individual stimulations of our 
% "classic" ramp optogenetic stimulations. It assumes a ramp length of 3s
% and a total stim time (pre + stim + post) of 9s.

% inputs:       - experiment: the usual structure (will be used for loading
%                             and saving
%               - CSC : channel to load and compute power for
%               - save_data: binary
%               - repeatCalc: binary
%               - folder2save: string - where to save results
%               - folder4stim_props: folder containing info about
%                                    stimulation properties in our usual
%                                    format
% output:       - StimPowerRamps: structure for power of various stim
%                                 epochs


ExtractMode = 2; % for extracting nlx data
fs = 32000; % sampling rate
% ugly fix to define stimulation periods (in ms) while leaving out 
% timepoints that might be contaminated by artifacts
pre = 1400 : 2800;
first_half = 3000 : 4400;
second_half = 4400 : 5800;
post = 6600 : 8000;
% parameters for pWelch
windowSize = 1;
overlap = 0.4;
nfft = 800;
maxFreq = 200;
pWelch_fs = 1000;
% extract ramp info
ramp_idx = 0;
ramps = str2num(experiment.ramps);
% file to load
file_to_load = strcat(experiment.path, experiment.name, filesep, 'CSC', num2str(CSC), '.ncs');

if repeatCalc == 0 && exist([folder2save, 'StimulationPowerSingleRamps\', ...
        experiment.name, filesep, num2str(CSC), '.mat'], 'file')
    load([folder2save, 'StimulationPowerSingleRamps\', ...
        experiment.name, filesep, num2str(CSC), '.mat'])
else
    % load stimulation properties (assumes that what is loaded is called
    % "StimulationProperties"
    load([folder4stim_props, experiment.animal_ID, '\StimulationProperties'])
    % pre-allocate variables
    Pre = zeros(numel(ramps), 161);
    Half1 = Pre; Half2 = Pre; Post = Pre;
    % loop over single ramps (no concatenation because of overlap)
    for ramp = ramps
        % set index
        ramp_idx = ramp_idx + 1;
        % define part of signal to load & load it
        stimStart = StimulationProperties{ramp, 10} - 3 * fs;
        stimEnd = StimulationProperties{ramp, 11} + 3 * fs;
        timepoins_to_load = round([stimStart stimEnd]);
        [~, signal, fs_load] = load_nlx_Modes(file_to_load, ExtractMode, timepoins_to_load);
        % filter & downsample to ms
        signal = ZeroPhaseFilter(signal, fs_load, [2 500]);
        signal = signal(1 : 32 : end);
        % compute all the pWelch stuff
        [Pre(ramp_idx, :) , ~, ~] = pWelchSpectrum(signal(pre), windowSize, ...
            overlap, nfft, pWelch_fs, 0.95, maxFreq);
        [Half1(ramp_idx, :) , ~, ~] = pWelchSpectrum(signal(first_half), windowSize, ...
            overlap, nfft, pWelch_fs, 0.95, maxFreq);
        [Half2(ramp_idx, :) , ~, ~] = pWelchSpectrum(signal(second_half), windowSize, ...
            overlap, nfft, pWelch_fs, 0.95, maxFreq);
        [Post(ramp_idx, :) , freq, ~] = pWelchSpectrum(signal(post), windowSize, ...
            overlap, nfft, pWelch_fs, 0.95, maxFreq);
    end
    % put everything in a structure
    StimPowerRamps.Half1 = Half1;
    StimPowerRamps.Half2 = Half2;
    StimPowerRamps.Post = Post;
    StimPowerRamps.Pre = Pre;
    StimPowerRamps.freq = freq;
    
    if save_data==1        
        if ~ exist([folder2save, experiment.animal_ID], 'dir')
            mkdir([folder2save, experiment.animal_ID]);
        end
        save([folder2save, experiment.animal_ID, '/', num2str(CSC)], 'StimPowerRamps');
    end
end
end