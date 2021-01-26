function SUAdata_pulses = getPulseSpikeMatrix(experiment, save_data, repeatCalc, ...
    folder2save, folderSM, folder4stim_props)
% by Mattia 10/20
% create a spike matrix (actually a tensor) for pulses stimulations
% this script arbitrarily creates a matrix of 100ms centered around the 
% pulse, and consideres an 8ms window for pre and stim periods in which to
% count spikes to determine if the unit is responding or not. These values
% are tritated on PFC experiments of P8-10 mice, but are obviously
% arbitrary (they are not set in stone!).

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

% divide the 100ms stim period in pre (40-47) and stim (51-58). I leave out
% the 4ms in the middle to avoid potential artifacts
pre_time = 40 : 47;
stim_time = 51 : 58;

if exist([folder2save, experiment.animal_ID], ...
        'file') && repeatCalc == 0
    load([folder2save, experiment.animal_ID])
else
    % load SUA spike matrix (assumes the loaded variable is called spike_matrix)
    load([folderSM, experiment.animal_ID])
    % load stimulation properties (assumes the loaded variable is called
    % StimulationProperties
    load([folder4stim_props, experiment.animal_ID, '\StimulationProperties'])
    % extract info about pulses
    PulsesInfo = StimulationProperties(strcmp(StimulationProperties(:, 8), 'squareFreq'), :);
    % these are in timestamps, convert them to ms
    PulseStart = round(cat(1, PulsesInfo{:, 12})) / 32;
    % extract indeces of pulses sup
    pulses = str2num(experiment.pulses);
    % initialize matrix (n_pulses x n_units x time) -> there are 12 pulses
    % per sweep, hence the multiplicative factor
    % !!!!!! this ugly hard-coded part was written with 4Hz pulses
    % stimulations in mind, if you use a different frequency, you might
    % have a different amount of pulses, so adjust the multiplicative
    % factor !!!!!!
    pulses_spike_matrix = zeros(numel(pulses) * 12, size(spike_matrix, 1), 100);
    % allocate spike matrix pulse-by-pulse sweep
    for stim_idx = 1 : numel(pulses)
        % loop over single pulses in a sweep
        for pulse_idx = 1 : 12
            stim_period = round(PulseStart(pulses(stim_idx), pulse_idx) - 49 : ...
                PulseStart(pulses(stim_idx), pulse_idx) + 50);
            pulses_spike_matrix((stim_idx - 1) * 12 + pulse_idx, :, :) = spike_matrix(:, stim_period);
        end
    end
    % compute spikes in pre-during-post periods
    pre = sum(sum(pulses_spike_matrix(:, :, pre_time), 3));
    during = sum(sum(pulses_spike_matrix(:, :, stim_time), 3));
    pre_single_pulses = sum(pulses_spike_matrix(:, :, pre_time), 3):
    during_single_pulses = sum(pulses_spike_matrix(:, :, stim_time), 3);
    % compute simple paired rank-sum test
    pvalue = zeros(1, length(pre));
    for unit = 1 : length(pre)
        pvalue(unit) = signrank(pre_single_pulses(:, unit), ...
            during_single_pulses(:, unit));
    end
    % put everything in a structure
    OMI = (during - pre) ./ (during + pre);
    SUAdata_pulses.pulse_spike_matrix = pulses_spike_matrix;
    SUAdata_pulses.OMI = OMI;
    SUAdata_pulses.pvalue = pvalue;
    
    % save stuff
    if save_data == 1
        if ~ exist(folder2save)
            mkdir(folder2save);
        end
        save(strcat(folder2save, experiment.animal_ID), 'SUAdata_pulses')
        
    end
end