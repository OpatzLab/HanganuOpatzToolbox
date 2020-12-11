
%% load experiment info and set a few variables for analysis

clear
% load experiments and generic stuff
experiments = 'Load your experiments';
repeatCalc = 0;
save_data = 1;

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
slow_freqs = [0.01 4]; % slow frequencies
fast_freqs = [1 50]; % fast frequencies

% PPC variables
filters = [0.01 : 0.05 : 1 1 : 1 : 48];

% tiling, coherence and ES variables
lagsTC = [1, 5, 10, 50, 100, 500, 1000, 5000, 10000]; % single lags for which to compute tiling coeff
downsampSM = 2; % downsampling factor for ES and Coh
maxLagES_Coh = 20; % max lag for ES and Coh (2 * 20 = 40ms)


% folders to save various results
folder4osc = 'Q:\Personal\Mattia\SEQproject\results\oscillations single channels\';
folder4PSD = 'Q:\Personal\Mattia\SEQproject\results\PSD timescales\';
folder4StimProp = 'Q:\Personal\Mattia\SEQproject\results\StimulationPropertiesBaselinePeriods\';
folder4Klusta = 'Q:\Personal\Mattia\SEQproject\results\klusta output\';
folder4SpikeMatrix = 'Q:\Personal\Mattia\SEQproject\results\spike matrices\';
folder4STTC = 'Q:\Personal\Mattia\SEQproject\results\STTC\';
folder4firing = 'Q:\Personal\Mattia\SEQproject\results\FiringRate\';
folder4ES = 'Q:\Personal\Mattia\SEQproject\results\ES\';
folder4Coh = 'Q:\Personal\Mattia\SEQproject\results\Coh\';
folder4PPC = 'Q:\Personal\Mattia\SEQproject\results\PPC\';

%% compute all sort of computations, on an experiment by experiment basis

for exp_idx = 1 : size(experiments, 2)
    
    % select experiment
    experiment = experiments(exp_idx);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%% LFP analysis %%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % load signal and filter for LFP
    disp(['loading LFP for animal number ' num2str(exp_idx)])
    parfor (channel = 1 : 16, 4)
        file_to_load = [experiment.path, experiment.name, '\CSC', num2str(channel), '.ncs'];
        [~, signal, ~] = load_nlx_Modes(file_to_load, ExtractMode, []);
        signal = ZeroPhaseFilter(signal, fs, [0 high_cut]);
        LFP(channel, :) = signal(1 : downsampling_factor : end);
    end
    % take median of all channels
    LFP4osc = median(LFP);
    % detect oscillations
    disp(['detecting oscillations for animal number ' num2str(exp_idx)])
    getOscillations(experiment, LFP4osc, fs_LFP, freq_band, rel_thresholds, ...
        abs_thresholds, durations, save_data, repeatCalc, folder4osc, 1, verbose);
    % Common Average Rereference (CAR)
    LFP = LFP - median(LFP);
    % compute PSDs
    disp(['computing PSD for animal number ' num2str(exp_idx)])
    getPSD_across_timescales(LFP, fs_LFP, freq2analyze, slow_freqs, fast_freqs, ...
        folder4PSD, experiment.animal_ID, save_data);
    % clear large variables that are not gonna be used
    clear LFP4osc signal
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%% SUA analysis %%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % load spike matrix
    disp(['loading spike matrix for animal number ' num2str(exp_idx)])
    spike_matrix = getSpikeMatrix(experiment.animal_ID, folder4Klusta, folder4SpikeMatrix, save_data, repeatCalc);
    % extract first stimulation and convert it to mS (used for SUA)
    FirstStim = round((StimulationProperties{1, 10} - 1000) / 32);
    % only take baseline part of spike matrix
    spike_matrix = spike_matrix(:, 1 : FirstStim);
    % firing rate
    getFiringRate(experiment.animal_ID, spike_matrix, repeatCalc, save_data, folder4firing);
    % PPC spectrum
    disp(['computing PPC spectrum for animal number ' num2str(exp_idx)])
    getPPC_spectrum(experiment.animal_ID, folder4Klusta, LFP, filters, fs_LFP, save_data, repeatCalc, folder4PPC);
    clear LFP
    % spike-time tiling coefficient
    disp(['computing STTC for animal number ' num2str(exp_idx)])
    getTCstimSingleLags(experiment.animal_ID, spike_matrix, lagsTC, repeatCalc, save_data, folder4STTC);
    % downsample spike matrix for Coh and ES
    numRows = floor(size(spike_matrix, 2) ./ downsampSM);
    spike_matrix = full(spike_matrix);
    spike_matrix_ds = squeeze(mean(reshape(spike_matrix(:, 1 : numRows * downsampSM), ...
        size(spike_matrix, 1), downsampSM, []), 2));
    % Event Synchronization
    disp(['computing ES for animal number ' num2str(exp_idx)])
    getEventSynchronization(experiment.animal_ID, spike_matrix_ds, maxLagES_Coh, repeatCalc, save_data, folder4ES);
    % Spike Coherence
    disp(['computing Coh for animal number ' num2str(exp_idx)])
    SpikeTimeCoh(experiment.animal_ID, spike_matrix_ds, maxLagES_Coh, repeatCalc, save_data, folder4Coh);
    
end