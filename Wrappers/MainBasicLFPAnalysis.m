
%% load experiment info and set a few variables for analysis

clear
% load experiments and generic stuff
experiments = get_experiment_redux;
repeatCalc = 0;
save_data = 1;
% the number of CPU cores to use to load signal. Unless you are doing
% nothing else on your computer, do not use all of them. Otherwise you will
% end with no processing power for anything else
cores = 2; 

% loading and filtering variables
fs = 32000; % from data
downsampling_factor = 320; % downsample for LFP analysis
fs_LFP = fs / downsampling_factor;
high_cut = fs / downsampling_factor / 2; % nyquist
ExtractMode = 1; % extract from neuralynx into matlab

% oscillation detection variables
freq_band = [4 20]; % frequencies on which to detect oscillations
rel_thresholds = [1 2]; % relative low/peak threshold for oscillation detection (stDev)
abs_thresholds = [50 100]; % absolute low/peak threshold for oscillation detection (microV)
durations = [1000 300]; % min inter-osc duration and min osc duration
verbose = 0;

% PSD variables
freq2analyze = logspace(-2, log10(50), 20); % frequencies to analyze with wndows of different length
slow_freqs = [0.01 4]; % slow frequencies (0.01 is the digital filter of our recordings, unless you changed it!)
fast_freqs = [1 50]; % fast frequencies

% folders to save various results
folder4osc = 'Q:\Personal\Mattia\SEQproject\results\oscillations single channels\';
folder4PSD = 'Q:\Personal\Mattia\SEQproject\results\PSD timescales\';
folder4StimProp = 'Q:\Personal\Mattia\SEQproject\results\StimulationPropertiesBaselinePeriods\';

%% compute all sort of computations, on an experiment by experiment basis

for exp_idx = 1 : size(experiments, 2)
    
    % select experiment
    experiment = experiments(exp_idx);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%% LFP analysis %%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % load signal and filter for LFP
    disp(['loading LFP for animal number ' num2str(exp_idx)])
    parfor (channel = 1 : 16, cores)
        file_to_load = [experiment.path, experiment.name, '\CSC', num2str(channel), '.ncs'];
        [~, signal, ~] = load_nlx_Modes(file_to_load, ExtractMode, []);
        signal = ZeroPhaseFilter(signal, fs, [0 high_cut]);
        LFP(channel, :) = signal(1 : downsampling_factor : end);
    end
    
    %%%% this is here as an example of how to limit baseline analysis to
    %%%% pre opto periods, in case your file has opto stimulations. you can
    %%%% delete this part if you are only recording baseline
    
    % load stimulation properties
    load([folder4StimProp, experiment.animal_ID, '/StimulationProperties'])
    % extract first stimulation and convert it to samp freq used for LFP
    FirstStim = round((StimulationProperties{1, 10} - fs) / downsampling_factor);
    % only take baseline part of LFP
    LFP = LFP(:, 1 : FirstStim);
    % take median of all channels
    LFP4osc = median(LFP);
    % detect oscillations
    disp(['detecting oscillations for animal number ' num2str(exp_idx)])
    getOscillations(experiment, LFP4osc, fs_LFP, freq_band, rel_thresholds, ...
        abs_thresholds, durations, save_data, repeatCalc, folder4osc, 1, verbose);
    clear LFP4osc
    % CAR
    LFP = LFP - median(LFP);
    % compute PSDs
    disp(['computing PSD for animal number ' num2str(exp_idx)])
    getPSD_across_timescales(LFP, fs_LFP, freq2analyze, slow_freqs, fast_freqs, folder4PSD, experiment.animal_ID, save_data);
    clear LFP signal    
end