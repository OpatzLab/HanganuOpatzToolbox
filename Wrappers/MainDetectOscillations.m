
%% clean up and set global variables

clear

% variables for loading mouse stuff
klusta = 1;
experiments = get_experiment_redux(klusta);
repeatCalc = 0;
save_data = 0;
folder2save = 'YOUR FOLDER HERE'; % folder in which to save stuff

% variables for oscillation detection
fs = 32000; % from data
downsampling_factor = 320; % downsample for LFP analysis
fs_LFP = fs / downsampling_factor;
high_cut = fs / downsampling_factor / 2; % nyquist
ExtractMode = 1; % extract from neuralynx into matlab
freq_band = [4 20]; % frequencies on which to detect oscillations
rel_thresholds = [1 2]; % relative low/peak threshold for oscillation detection (stDev)
abs_thresholds = [5 10]; % absolute low/peak threshold for oscillation detection (microV)
durations = [1000 300]; % min inter-osc duration and min osc duration
verbose = 0;

%% find oscillations and their properties

for exp_idx = 1 : length(experiments)
    
    experiment = experiments(exp_idx);
        
    if experiment.baseline == 1
        disp(['analyzing mouse ' experiment.animal_ID ' - number ' num2str(exp_idx)])
        % load signal
        parfor (channel = 1 : 16, 3)
            disp(strcat('loading channel n°', num2str(channel)));
            file_to_load = strcat(experiment.path, experiment.name, '\CSC', num2str(channel + 16), '.ncs');
            [~, signal, ~] = load_nlx_Modes(file_to_load, ExtractMode, []);
            signal = ZeroPhaseFilter(signal, fs, [0 high_cut]);
            LFP(channel, :) = signal(1 : downsampling_factor : end);
        end
        % CAR
        LFP = LFP - median(LFP);
        % detect oscillations on all channels
        for channel = 1 : 16
            [oscillations(channel)] = getOscillations(experiment, LFP(channel, :), fs_LFP, freq_band, rel_thresholds, ...
                abs_thresholds, durations, save_data, 1, folder2save, channel, verbose);
            time_in_osc(channel) = sum(oscillations(channel).durations) ./ length(LFP);
        end
        clearvars signal LFP 
        % save stuff
        save(strcat(folder2save, experiment.animal_ID), 'oscillations')
        disp(['age ', num2str(experiment.age), ' time in oscillations ', num2str(nanmedian(time_in_osc))])
        clearvars oscillations
    end
end
