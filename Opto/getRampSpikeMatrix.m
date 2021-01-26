function SUAdata = getRampSpikeMatrix(experiment, save_data, repeatCalc, ...
    folder2save, folderSM, folder4stim_props)

% by Mattia 10/20
% create a spike matrix (actually a tensor) for ramp classic stimulations
% this script arbitrarily divides the 9s stim period in pre 
% (3s) stim (3s), taking into account the (low) possibility of light 
% artifact mistaken for spikes even after sorting

% inputs:       - experiment: the usual structure (will be used for loading
%                             and saving
%               - save_data: binary
%               - repeatCalc: binary
%               - folder2save: string - where to save results
%               - folderSM: folder where spike matrices (for whole rec) are saved
%               - folder4stim_props: folder containing info about
%                                    stimulation properties in our usual
%                                    format
% output:       - SUAdata: structure with spike matrix, modulation index
%                          and respective pvalue


pre_time = 1 : 2990;
stim_time = 3005 : 5995;

if exist([folder2save, experiment.animal_ID], ...
        'file') && repeatCalc == 0
    load([folder2save, experiment.animal_ID])
else
    % load SUA spike matrix (assumes the loaded variable is called spike_matrix)
    load([folderSM, experiment.animal_ID])
    % load stimulation properties (assumes the loaded variable is called
    % StimulationProperties
    load([folder4stim_props, experiment.animal_ID, '\StimulationProperties'])
    % extract info about ramps
    RampInfo = StimulationProperties(strcmp(StimulationProperties(:, 8), 'ramp'), :);
    % these are in timestamps, convert them to ms & add/subtract 3s
    RampStart = round(cat(1, RampInfo{:, 10})) / 32 - 3000;
    % extract indeces of ramp sup
    ramps = str2num(experiment.ramps) - min(str2num(experiment.ramps)) + 1;
    % initialize matrix (n_ramps x n_units x time)
    ramp_spike_matrix = zeros(numel(ramps), size(spike_matrix, 1), 9000);
    % allocate spike matrix ramp-by-ramp
    for stim_idx = 1 : numel(ramps)
        stim_period = round(RampStart(ramps(stim_idx)) : RampStart(ramps(stim_idx)) + 8999);
        ramp_spike_matrix(stim_idx, :, :) = spike_matrix(:, stim_period);
    end
    % compute spikes in pre-during-post periods
    pre = sum(sum(ramp_spike_matrix(:, :, pre_time), 3)); % light artifact
    during = sum(sum(ramp_spike_matrix(:, :, stim_time), 3)); % light artifact
    pre_single_ramp = sum(ramp_spike_matrix(:, :, pre_time), 3); % light artifact
    during_single_ramp = sum(ramp_spike_matrix(:, :, stim_time), 3); % light artifact
    % compute simple paired rank-sum test
    pvalue = zeros(1, length(pre));
    for unit = 1 : length(pre)
        pvalue(unit) = signrank(pre_single_ramp(:, unit), ...
            during_single_ramp(:, unit));
    end
    % put everything in a structure
    OMI = (during - pre) ./ (during + pre);
    SUAdata.ramp_spike_matrix = ramp_spike_matrix;
    SUAdata.OMI = OMI;
    SUAdata.pvalue = pvalue;
    
    % save stuff
    if save_data == 1
        if ~ exist(folder2save)
            mkdir(folder2save);
        end
        save(strcat(folder2save, experiment.animal_ID), 'SUAdata')
        
    end
end