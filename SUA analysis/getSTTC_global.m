function Tcoeff = getSTTC_global(animal_name, ...
    spike_matrix, lags, repeat_calc, save_data, output_folder)

%% By Mattia 04.21
% this function computes the GLOBAL (standard) STTC, not the directed
% version that is computed by other similar functions

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


% convert lags to seconds
lags = lags / 1000;

if exist([output_folder, animal_name, '.mat'], 'file') && repeat_calc == 0
    load([output_folder, animal_name])    
else
    if size(spike_matrix, 1) > 1
        length_rec = [0 size(spike_matrix, 2) / 1000];
        num_units = size(spike_matrix, 1);
        STTC = NaN(num_units * (num_units - 1) / 2, numel(lags));
        for lag_idx = 1 : numel(lags)
            pair_idx = 1;
            for unit1 = 1 : num_units
                spikes1 = find(spike_matrix(unit1, :)) / 1000;
                num_spikes1 = numel(spikes1);
                for unit2 = unit1 + 1 : num_units
                    spikes2 = find(spike_matrix(unit2, :)) / 1000;
                    num_spikes2 = numel(spikes2);
                    STTC(pair_idx, lag_idx) =  getSTTC(num_spikes1, num_spikes2, ...
                        lags(lag_idx), length_rec, spikes1, spikes2);
                    pair_idx = pair_idx + 1;
                end
            end
        end
    else
        STTC = [];
    end
    if save_data == 1
        Tcoeff.TilingCoeff = STTC;
        Tcoeff.num_pairs = size(STTC, 1);
        Tcoeff.lags = lags;
        if ~ exist(output_folder, 'dir')
            mkdir(output_folder);
        end
        save(strcat(output_folder, animal_name), 'Tcoeff')
    else
        disp('Tcoeff not saved!')
    end
end

clear TilingCoeff_animal TilingCoeff_animalB2A spike_matrix spikesstruct

end
