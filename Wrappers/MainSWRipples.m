clear 

experiments = get_experiment_redux;
fs = 32000; % from data
save_data = 1;
downsampling_factor = 32; % downsample for LFP analysis
fs_LFP = fs / downsampling_factor;
high_cut = fs / downsampling_factor / 2; % nyquist
ExtractMode = 1; % extract from neuralynx into matlab
threshold = 7; % threshold sharp waves detection
thresholdMUA = 5; % for MUA detection
repeatCalc = 1;
min_distance = 40; % in ms
max_width = 50; % in ms
% channels for which to keep sharpwave data 
ch2keep = [1 4 7]; % in this case (reversal -3 from reversal +3 from reversal)
folder2save = 'YOUR FOLDER HERE';
animalIDs = extractfield(experiments, 'animal_ID');
animals = find(~ cellfun('isempty', animalIDs)); % clean the list
freq_band_ripples = [100 300]; % freq band in which you want to detect ripples
thresholds = [3 6]; % low/high threshold for ripple detection
durations = [100 300]; % min max duration for ripple detection

for n_animal = animals
    
    experiment = experiments(n_animal);
    reversal = experiment.HPreversal; % extract reversal ch from meta-data
    display(['analyzing mouse ' experiment.animal_ID ' - number ' num2str(n_animal)])
    
    parfor (channel = -3 : 3, 3)
        display(strcat('loading channel n°', num2str(reversal + channel)));        
        file_to_load = strcat(experiment.path, experiment.name, '\CSC', num2str(reversal + channel), '.ncs');
        [~, signal, ~] = load_nlx_Modes(file_to_load, ExtractMode, []);
        signal = ZeroPhaseFilter(signal, fs, [0 high_cut]);
        LFP(channel + 4, :) = signal(1 : downsampling_factor : end);
    end
    LFP = LFP - mean(LFP); % common average rereference
    % extract ripple stuff and save it
    getRipples(experiment, LFP(5, :), fs_LFP, freq_band_ripples, thresholds, durations, save_data, repeatCalc);
    % from here on: detect sharp waves
    diff_signal = LFP(1, :) - LFP(end, :); % signal on which to detect sharp waves
    thr_sw = mean(diff_signal) + threshold * std(diff_signal); % threshold for detection
    [amplitudes, timestamps, widths] = findpeaks(diff_signal, ...
        'MinPeakHeight', thr_sw, 'MinPeakDistance', min_distance, ...
        'MaxPeakWidth', max_width, 'MinPeakProminence', thr_sw / 2);
    
    % initialize variable
    sharpwaves = NaN(numel(timestamps), 3, 101);
    idx = 0;
    % keep signal around swr +- 50ms
    for timestamp = timestamps
        idx = idx + 1;
        try
            sharpwaves(idx, :, :) = LFP(ch2keep, ...
                timestamp - max_width : timestamp + max_width);
        catch
        end
    end
    % put SWR stuff in structure and save it
    sharpstruct = struct;
    sharpstruct.amplitudes = amplitudes;
    sharpstruct.timestamps = timestamps;
    sharpstruct.widths = widths;
    sharpstruct.sharpwaves = sharpwaves;
    sharpstruct.swr_rate = numel(timestamps) / (length(LFP) / (fs_LFP * 60)); % in occurrences per minute
    save(strcat(folder2save, experiment.animal_ID), 'sharpstruct')
    clear LFP 
end