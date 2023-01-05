function [spike_matrix, clusters] = getSpikeMatrix(animal_name, resultsKlusta, save_data, repeatCalc, output_folder)
% by Mattia 19.02

% computes sparse spike_matrix starting from the output of sorted Klusta
% file. doesn't cuts periods of silence (> 500 ms of no spikes across all channels)
% this is the version for the Sequencing project (only one SUA info per
% animal)

% input:  animal_name (string, also known as animal_ID)
%         resultsKlusta (string, folder in which you have sorted SUA file)
%         save_data (1 for yes)
%         repeatCalc (0 to load already computed stuff)
%         output_folder (string, where to save the spike matrix)
% output: spike_matrix; if SUAInfo is empty (no units) empty spike_matrix
% ([]) is returned.

if repeatCalc == 0 && exist(strcat(output_folder, animal_name, 'spike_matrix.mat'))    
    load(strcat(output_folder, animal_name, 'spike_matrix.mat'))
    
else
    load(strcat(resultsKlusta, animal_name)) % load the saved SUA stuff
    
    if ~isempty(fieldnames(SUAinfo{1})) % check that there are some units
    
        for exp_idx = 1 : length(SUAinfo) % loop over recordings
            SUAstruct = SUAinfo{exp_idx};
            if numel(fieldnames(SUAstruct)) > 0
                if exp_idx == 1 % if this is the first experiment
                    clusters = extractfield(SUAstruct, 'ClusterID'); % extract clusters
                    spike_matrix = zeros(numel(clusters), 1); % initialize an empty matrix for spikes
                else
                    new_clusters = extractfield(SUAstruct, 'ClusterID'); % some clusters might be present only in one recording and not in others, hence this line
                    clusters = cat(2, clusters, new_clusters(~ ismember(new_clusters, clusters))); % concatenate new clusters
                end
                begin_to_attach = size(spike_matrix, 2); % size of spike matrix before beginning to attach new experiment/recording
                for SUA = 1 : length(SUAstruct) % loop over single units

                    spike_times = ceil(SUAstruct(SUA).Timestamps / 32); % ceil to avoid having a spike time at 0. round to millisecond
                    row_SUA = find(SUAstruct(SUA).ClusterID == clusters); % define row of the single unit as the one that has corrisponding cluster ID in clusters
                    if ~ isnan(spike_times)
                        spike_matrix(row_SUA, begin_to_attach + spike_times) = 1; % set to 1 if a spike is present in this millisecond
                    end                    
                end
            end
        end
        spike_matrix = sparse(spike_matrix); % save matrix as sparse matrix        
        if save_data == 1
            save(strcat(output_folder, animal_name, 'spike_matrix'), 'spike_matrix', 'clusters')
        end
    else
        spike_matrix = [];
        clusters = [];
    end
end