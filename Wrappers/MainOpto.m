
%% load experiment info and set a few variables for analysis

clear
% load experiments and generic stuff
experiments = 'your function here';
repeatCalc = 0;
save_data = 1;

% folders to save various results
folder4power_ramps = 'to save power of ramps';
folder4stim_props = 'to load stimulation properties';
folderSM = 'to load spike matrices';
folder4ramps = 'to save ramps stim stuff';
folder4pulses = 'to save pulses stim stuff';

%% compute all sort of computations, on an experiment by experiment basis

for exp_idx = 1 : size(experiments, 2)
    
    % select experiment
    experiment = experiments(exp_idx);    
    % compute power for ramps
    disp(['Computing Ramp Power stuff for animal ', experiment.animal_ID])
    for CSC = str2num(experiment.CSC)
        getStimulationPowerSingleRamps(experiment, CSC, save_data, repeatCalc, ...
            folder4stim_props, folder4power_ramps)
    end    
    % extract spike matrices for ramps
    disp(['Extracting spike matrices for animal ', experiment.animal_ID])
    SUAdata_ramps = getRampSpikeMatrix(experiment, save_data, repeatCalc, ...
        folder4ramps, folderSM, folder4stim_props);
    SUAdata_pulses = getPulseSpikeMatrix(experiment, save_data, repeatCalc, ...
        folder4pulses, folderSM, folder4stim_props);
end