function Tcoeff = getTCstimSingleLags(animal_name, ...
    spike_matrix, lags, repeat_calc, save_data, output_folder, stim_period, clusters)

%% By Mattia 01.20
% computes spike time tiling coefficient as in Cutts et al., 2014, for 
% cumulative bins (that are shifted by the single lags that are received as
% input).
% requires spike matrices from which to compute the CCHs.
% standard maxLag is 100ms

maxLag = max(lags);
if iscell(stim_period)
    stim_period = cell2mat(stim_period);
end

if exist(strcat(output_folder, animal_name, '_', num2str(maxLag), '_', stim_period, ...
        '.mat'), 'file') && repeat_calc == 0
    load(strcat(output_folder, animal_name, '_', num2str(maxLag), '_', stim_period, '.mat'))    
else
    if size(spike_matrix, 1) > 1
        disp(['calculating Tiling Coefficient for animal ', num2str(animal_name)])
        [TilingCoeff, TilingCoeffB2A] = fastTC(spike_matrix, lags);
    else
        TilingCoeff = [];
        TilingCoeffB2A = [];
    end
    if save_data == 1
        Tcoeff.TilingCoeff = TilingCoeff;
        Tcoeff.TilingCoeffB2A = TilingCoeffB2A;
        Tcoeff.num_pairs = size(TilingCoeff, 1);
        Tcoeff.lags = lags;
        Tcoeff.clusters = clusters;        
        if ~ exist(output_folder, 'dir')
            mkdir(output_folder);
        end
        save(strcat(output_folder, animal_name, '_', num2str(maxLag), '_', stim_period), 'Tcoeff')
    else
        disp('Tcoeff not saved!')
    end
end

clear TilingCoeff_animal TilingCoeff_animalB2A spike_matrix spikesstruct

end
