function spike_matrix = getSpikeMatrixKlusta(animal_name, resultsKlusta, save_data, repeatCalc, output_folder, cut)
% by Mattia 19.02

% computes sparse spike_matrix starting from the output of sorted Klusta
% file. if cut==1, cuts periods of silence (> 500 ms of no spikes across all channels)
% to speed up further computations. Make sure to not use the cut version to e.g.
% compute spike-tiling coefficients that go above 500ms

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

        % this part of the code eliminates parts of the matrix in which there
        % are at least 500ms of no spiking across all channels. this can reduce
        % quite substantially the size of the matrix (and hence calculation
        % time) , while not affecting any Xcorr computed for intervals < 500 ms
        if cut == 1 
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
            catch
                spike_matrix = [];
            end
        end
        spike_matrix = sparse(spike_matrix); % save matrix as sparse matrix
        
        if save_data == 1
            save(strcat(output_folder, animal_name, 'spike_matrix'), 'spike_matrix')
        end
    else
        spike_matrix = [];
    end
end