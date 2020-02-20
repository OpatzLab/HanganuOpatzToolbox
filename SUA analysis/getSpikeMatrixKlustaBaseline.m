function [spike_matrix, clusters] = ...
    getSpikeMatrixKlustaBaseline(animal_name, experiments, resultsKlusta, save_data, repeatCalc, output_folder)
% by Mattia 19.02

% computes sparse spike_matrix starting from the output of sorted Klusta
% file. cuts periods of silence (> 500 ms of no spikes across all channels)
% to speed up further computations. Loads only baseline!

% input:  animal_name (string, also known as animal_ID)
%         resultsKlusta (string, folder in which you have sorted SUA file)
%         save_data (1 for yes)
%         repeatCalc (0 to load already computed stuff)
%         output_folder (string, where to save the spike matrix)
% output: spike_matrix (thought for computing xCorr)

if repeatCalc == 0 && exist(strcat(output_folder, animal_name, 'spike_matrix.mat'), 'file')
    load(strcat(output_folder, animal_name, 'spike_matrix.mat'))    
else
    load(strcat(resultsKlusta, animal_name)) % load the saved SUA stuff
    exp_animal = structfind(experiments, 'animal_ID', animal_name); % find all experiments that belong to the animal
    for exp_idx = 1 : length(exp_animal) % loop over exp to find the one with baseline
        experiment = experiments(exp_animal(exp_idx));
        if experiment.baseline == 1
            load(strcat(resultsKlusta, experiment.animal_ID)) % load basic SUA stuff
            try
                SUAinfo = SUAinfo{exp_idx};
            catch
                exp_types = extractfield(experiments(exp_animal), 'Exp_type');
                exp_idx = exp_idx - nnz(strcmp(exp_types, 'niet')) ...
                    - nnz(strcmp(exp_types, 'INN'));
                SUAinfo = SUAinfo{exp_idx};
            end
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
        
        % this part of the code eliminates parts of the matrix in which there
        % are at least 500ms of no spiking across all channels. this can reduce
        % quite substantially the size of the matrix (and hence calculation
        % time) , while not affecting any Xcorr computed for intervals < 500 ms
        
        try
            find_nnz = find(sum(spike_matrix)); % find time bins in which at least one channel has a spike
            intervals_nnz = find(diff(find_nnz) > 500); % find time bins that contain a spike between which there are > 500 ms
            
            % the next loop creates a matrix (to_delete) which contains parts of
            % the signal that are in this long intervals of spiking silence. it
            % does not contain the whole interval but only starts 250ms after the
            % interval and stops 250ms before. So that there are always at least
            % 500ms of "silence" between the two spikes before/after the interval.
            
            to_delete = [];
            for int_idx = 1 : length(intervals_nnz)
                try
                    to_delete = [to_delete find_nnz(intervals_nnz(int_idx) - 1) + 250 ...
                        : find_nnz(intervals_nnz(int_idx)) - 250];
                catch
                    to_delete = [to_delete 1 : find_nnz(intervals_nnz(int_idx)) - 250];
                end
            end
            spike_matrix(:, to_delete) = []; % delete silent periods
            spike_matrix = sparse(spike_matrix); % save matrix as sparse matrix
        catch
            spike_matrix = [];
            clusters = NaN;
        end
    else
        spike_matrix = NaN;
        clusters = NaN;
    end
    
    if save_data == 1
        save(strcat(output_folder, animal_name, 'spike_matrix'), 'spike_matrix', 'clusters')
    end
end
end