%% load experiments and set a few variable

klusta = 1;
experiments = get_experiment_redux(klusta);
lags = [5, 10, 20, 50, 100, 500]; % single lags for which to compute tiling coeff
repeat_calc = 0;
save_data = 1;
stim_period = 'baseline';
output_folder = 'YOUR FOLDER HERE'; % where to save
output_folderTilCum = 'YOUR FOLDER HERE'; % where to save
output_folderGH = 'YOUR FOLDER HERE'; % where to save
resultsKlusta = 'YOUR FOLDER HERE'; % folder in which you have SUA files
output_folder_SM = 'YOUR FOLDER HERE'; % where to save spike matrix

% Extract unique animals from the experiment list. animals are the "unit"
% around which the rest is calculated
% If you do not have multiple "experiments" (i.e. recordings) for
% the same animal, this part of the code might have redundant parts for
% you.

animals = extractfield(experiments, 'animal_ID');
animals = animals(~cellfun('isempty', animals));
animals = unique(cellfun(@num2str, animals, 'un', 0));

%% compute xCorr and/or Tiling Coefficient

for animal_idx = 1 : length(animals)
    
    animal_name = cell2mat(animals(animal_idx)); % extract name of the animal
    % load spike matrix
    [spike_matrix, clusters] = getSpikeMatrixKlustaBaseline(animal_name, ...
        experiments, resultsKlusta, save_data, repeat_calc, output_folder_SM);
    % compute spike-tiling coefficient
    getTCstimSingleLags(animal_name, spike_matrix, ...
        lags, repeat_calc, save_data, output_folder, stim_period, clusters);
    disp(['animal ', animal_name, ' pairs ', num2str(Tcoeff.num_pairs)])    
end
