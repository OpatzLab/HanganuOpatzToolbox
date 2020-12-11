function [spike_matrix, clusters] = ...
    getSpikeMatrix(animal_name, resultsKlusta, output_folder, save_data, repeatCalc)
% by Mattia 08.20

% computes sparse spike_matrix starting from the output of sorted Klusta
% file. doesn't cuts periods of silence (> 500 ms of no spikes across all channels)
% this is the version for the Sequencing project (only one SUA info per
% animal)

% input:  animal_name (string, also known as animal_ID)
%         resultsKlusta (string, folder in which you have sorted SUA file)
%         save_data (1 for yes)
%         repeatCalc (0 to load already computed stuff)
%         output_folder (string, where to save the spike matrix)
% output: spike_matrix

if repeatCalc == 0 && exist(strcat(output_folder, animal_name, '.mat'), 'file')
    load(strcat(output_folder, animal_name, '.mat'))
else
    load(strcat(resultsKlusta, animal_name, '/SUAinfo')) % load the saved SUA stuff
    SUAinfo = SUAinfo{1};
    if isstruct(SUAinfo)
        if numel(fieldnames(SUAinfo)) > 0
            clusters = extractfield(SUAinfo, 'ClusterID'); % extract clusters
            for SUA = 1 : length(SUAinfo) % loop over single units
                spike_times = ceil(SUAinfo(SUA).Timestamps / 32); % ceil to avoid having a spike time at 0. round to millisecond
                if ~ isnan(spike_times)
                    spike_matrix(SUAinfo(SUA).ClusterID == clusters, spike_times) = 1; % set to 1 if a spike is present in this millisecond
                else
                    spike_matrix(SUAinfo(SUA).ClusterID == clusters, :) = 0;
                end
            end
        end
    else
        spike_matrix = NaN;
        clusters = NaN;
    end
    spike_matrix = sparse(spike_matrix);
    if save_data == 1
        save(strcat(output_folder, animal_name), 'spike_matrix', 'clusters')
    end
end
end