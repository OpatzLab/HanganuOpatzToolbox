function Coh = SpikeTimeCoh(animal_name, spike_matrix, maxLag, repeatCalc, save_data, output_folder)
% by Mattia, 05/20
% as in Jang et al., 2020 Sciance Advances
% input:
% spike_matrix    : single units x time (assumed to be in ms)
% maxLag          : max lag for which coherence will be computed. In this
%                   version, downsamp_factor is outside this function

% output:
% coh_matrix      : symmetric matrix with max values of coherence within
%                   maxLag (single units x single units, NaN on diagonal)
% indeces         : indeces at which max coherence occurs
% norm_coh        : raw Coherence values (number of pairs x (2 * maxLag + 1)

if exist(strcat(output_folder, animal_name, '.mat'), 'file') && repeatCalc == 0
    load(strcat(output_folder, animal_name, '.mat'))
else
    % initialize matrices
    coh_matrix = NaN(size(spike_matrix, 1));
    indeces = NaN(size(spike_matrix, 1));
    norm_coh = NaN(size(spike_matrix, 1) * (size(spike_matrix, 1) - 1) / 2, 2 * maxLag + 1);
    
    idx = 1;
    for unit1 = 1 : size(spike_matrix, 1)
        % compute the auto-covariance and fft transform it
        covAA = fft(xcov(spike_matrix(unit1, :), spike_matrix(unit1, :), maxLag));
        for unit2 = unit1 + 1 : size(spike_matrix, 1)
            % compute covariance and fft transform it
            covAB = fft(xcov(spike_matrix(unit1, :), spike_matrix(unit2, :), maxLag));
            % compute the second auto-covariance
            covBB = fft(xcov(spike_matrix(unit2, :), spike_matrix(unit2, :), maxLag));
            % compute the coherence
            norm_coh(idx, :) = ifft(covAB ./ sqrt(covAA .* covBB));
            % extract max value and its index
            [coh_matrix(unit1, unit2), indeces(unit1, unit2)] = max(norm_coh(idx, :));
            % fix lower half of matrix
            coh_matrix(unit2, unit1) = coh_matrix(unit1, unit2);
            indeces(unit2, unit1) = indeces(unit1, unit2);
            idx = idx + 1;
        end
    end
    indeces = indeces - maxLag;
    % save stuff
    if save_data == 1
        Coh.coh_matrix = coh_matrix;
        Coh.indeces = indeces;
        Coh.norm_coh = norm_coh;
        if ~ exist(output_folder, 'dir')
            mkdir(output_folder);
        end
        save(strcat(output_folder, animal_name), 'Coh')
    else
        disp('Coh not saved!')
    end
end
end