function Tcoeff = getTCstimSingleLags(animal_name, ...
    spike_matrix, lags, repeat_calc, save_data, output_folder, stim_period, clusters)

%% By Mattia 01.20
% just a wrapper for any spike-tiling coefficient function 
% it is used in the example script "MainSpikeTilingCoefficient.m"

% inputs:
% - animal_name (string): to save/loda stuff
% - spike_matrix (2D matrix): as computed by getSpikeMatrixKlusta
% - lags (array): lags (in ms) for which to compute spike-tiling coefficient
% - repeat_calc (0 or 1): 0=no, 1=yes
% - save_data (0 or 1): 0=no, 1=yes
% - output_folder (string): main folder to save results
% - stim_period (string): 'baseline' or 'stim' (for opto part - not included in examples)
% - clusters (array): in this example it is included because it is a piece of info that can
%                     can come in handy for later analysis


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
