function [spike_matrix, clusters] = ...
    getSpikeMatrixBaseline(animal_name, experiments, resultsKlusta, save_data, repeatCalc, output_folder)
% by Mattia 02.19

% computes sparse spike_matrix on baseline data only, starting from the output of sorted Klusta
% file. doesn't cuts periods of silence (> 500 ms of no spikes across all channels)

% input:  animal_name (string, also known as animal_ID)
%         resultsKlusta (string, folder in which you have sorted SUA file)
%         save_data (1 for yes)
%         repeatCalc (0 to load already computed stuff)
%         output_folder (string, where to save the spike matrix)
% output: spike_matrix

if repeatCalc == 0 && exist(strcat(output_folder, animal_name, 'spike_matrix.mat'), 'file')
    load(strcat(output_folder, animal_name, 'spike_matrix.mat'))    
else
    load(strcat(resultsKlusta, animal_name)) % load the saved SUA stuff
    exp_animal = structfind(experiments, 'animal_ID', animal_name); % find all experiments that belong to the animal
    for exp_idx = 1 : length(exp_animal) % loop over exp to find the one with baseline
        experiment = experiments(exp_animal(exp_idx));
        if experiment.baseline == 1
            load(strcat(resultsKlusta, experiment.animal_ID)) % load basic SUA stuff
            SUAinfo = SUAinfo{exp_idx};
        end
    end
    if isstruct(SUAinfo)
        if numel(fieldnames(SUAinfo)) > 0
            clusters = extractfield(SUAinfo, 'ClusterID'); % extract clusters
            for SUA = 1 : length(SUAinfo) % loop over single units
                spike_times = ceil(SUAinfo(SUA).Timestamps / 32); % ceil to avoid having a spike time at 0. round to millisecond
                if ~ isnan(spike_times)
                    spike_matrix(SUAinfo(SUA).ClusterID == clusters, spike_times) = 1; % set to 1 if a spike is present in this millisecond
                end
            end
        end
    else
        spike_matrix = NaN;
        clusters = NaN;
    end
    spike_matrix = sparse(spike_matrix); % save matrix as sparse matrix
    if save_data == 1
        save(strcat(output_folder, animal_name, 'spike_matrix'), 'spike_matrix', 'clusters')
    end
end
end