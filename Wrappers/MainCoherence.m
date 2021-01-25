
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
downsampling_factor = 100; % downsample for LFP analysis
fs_LFP = fs / downsampling_factor;
high_cut = fs / downsampling_factor / 2; % nyquist
ExtractMode = 1; % extract from neuralynx into matlab

% coherence variables
win_length = 8; % window length for coherence (in seconds)
overlap = 4; % window overlap for coherence (in seconds)
nfft = 2^13; % number of points for power spectrum (coherence)

% folders to save various results
folder4Coh = 'whatever/';

%% compute all sort of computations, on an experiment by experiment basis

for exp_idx = 1 : size(experiments, 2)
    
    % select experiment
    experiment = experiments(exp_idx);
    
    % load and filter first signal
    disp(['loading LFP 1 for animal number ' num2str(exp_idx)])
    parfor (channel = 1 : 16, cores)
        file_to_load = [experiment.path, experiment.name, '\CSC', num2str(channel), '.ncs'];
        [~, signal, ~] = load_nlx_Modes(file_to_load, ExtractMode, []);
        signal = ZeroPhaseFilter(signal, fs, [0 high_cut]);
        LFP1(channel, :) = signal(1 : downsampling_factor : end);
    end
    clear signal
    
    % load and filter second signal
    disp(['loading LFP 2 for animal number ' num2str(exp_idx)])
    parfor (channel = 17 : 32, cores)
        file_to_load = [experiment.path, experiment.name, '\CSC', num2str(channel), '.ncs'];
        [~, signal, ~] = load_nlx_Modes(file_to_load, ExtractMode, []);
        signal = ZeroPhaseFilter(signal, fs, [0 high_cut]);
        LFP2(channel - 16, :) = signal(1 : downsampling_factor : end);
    end
    clear signal
    
    % average the two signals (depending on your experimental paradigm, 
    % scientific question and/or electrode configuration, you might want to
    % skip this part and compute coherence between each pair of channels
    % and or selected pairs of channels
    LFP1 = median(LFP1);
    LFP2 = median(LFP2);
    
    % compute coherence
    disp(['computing coherence for animal number ' num2str(exp_idx)])
    getCoherence(LFP1, LFP2, fs_LFP, win_length, overlap, nfft, folder4Coh, ...
        experiment.animal_ID, repeatCalc, save_data)
    clear LFP1 LFP2    
end