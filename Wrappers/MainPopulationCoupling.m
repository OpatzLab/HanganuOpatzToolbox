%% load experiments and set a few variable
clearvars -except SUAtable

klusta = 1;
experiments = get_experiment_redux(klusta);
max_lag = 500; % max lag (in ms) for which spike-triggered population average will be computed
repeat_calc = 1; 
save_data = 1;
output_folder = 'YOUR FOLDER HERE'; % where to save pop coupling results
resultsKlusta = 'YOUR FOLDER HERE'; % folder in which you have SUA files
output_folder_SM = 'YOUR FOLDER HERE'; % where to save spike matrix
Gwindow = gausswin(101, 8.3); % gaussian window of 100ms with stdev of 12ms as in paper
Gwindow = Gwindow / sum(Gwindow); % normalize the gaussian kernel


% extract unique animals from the experiment list. animals are the "unit"
% around which the rest is calculated
animals = extractfield(experiments, 'animal_ID');
animals = animals(~cellfun('isempty', animals));
animals = unique(cellfun(@num2str, animals, 'un', 0));

%% compute stuff

for animal_idx = 1 : length(animals)
    disp(['analyzing/loading mouse n° ' num2str(animal_idx) ', there are still '...
        num2str(length(animals) - animal_idx) ' animals missing'])
    % extract name of the animal
    animal_name = cell2mat(animals(animal_idx));    
    % load spike matrix
    spike_matrix = getSpikeMatrixKlustaBaseline(animal_name, experiments, ...
        resultsKlusta, save_data, repeat_calc, output_folder_SM);
    % compute population coupling and spike-triggered population average
    [stPR, pop_coupling, pop_coupling_1sthalf, pop_coupling_2ndhalf] = ...
        get_stPR(spike_matrix, max_lag, animal_name, repeat_calc, save_data, output_folder);
end

