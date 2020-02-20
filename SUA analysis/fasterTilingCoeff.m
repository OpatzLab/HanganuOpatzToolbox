function [TCA2B, TCB2A] = fasterTilingCoeff(spike_matrix, maxLag)
%% by Mattia 01.20 - this version has an improved unwrapping part and is
% faster than the standard (fastTilingCoeff) one

% inputs:
% spike_matrix: units * time
% maxLag: the maximum lag for which xcorr will be computed. in the same
% units as the spike_matrix

% output:
% Tiling Coefficient: given a matrix with a, b, c ... k-1, k units, the output will be
% in the form of ab, ac, ad ..., ak-1, ak, bc, bd ... kk-2, kk-1
% Tiling CoefficientB2A: as above but from B to A, not from A to B -> ba,
% bc, bd ....

%%

if issparse(spike_matrix)
    spike_matrix = full(spike_matrix);
end
% create another matrix that will be used to compute correlations in the
% other direction
spike_matrix_B2A = spike_matrix;
% "extend" matrix to be able to accept shifted spikes (max shift is maxLag)
spike_matrix(:, end + maxLag) = 0;
% same as above, in a different direction
spike_matrix_B2A = [zeros(size(spike_matrix_B2A, 1), maxLag) spike_matrix_B2A];
% compute number of units
num_units = size(spike_matrix, 1);
% compute number of spikes for every unit
n_spikes = sum(spike_matrix, 2);
% sparsify both matrices
spike_matrix = sparse(spike_matrix);
spike_matrix_B2A = sparse(spike_matrix_B2A);
% find rows and columns of non-zero entries in both matrices
[row, col] = find(spike_matrix);
[row_B2A, col_B2A] = find(spike_matrix_B2A);
% initialize matrix to detect (B2A) coincidences
coincidences = zeros(num_units, num_units, maxLag + 1);
coincidences_negative = coincidences;
% initialize matrix that counts amount of "tiled" time ?
tot_time = zeros(num_units, 2 * maxLag + 1);

% loop over all lags
for lag = 1 : maxLag + 1
    % create two row vectors in which you don't change the value (spikes
    % occur always on the same unit) but have lenght such as the col
    % shifted to create the sparse matrix
    row_lag = repmat(row, lag, 1);
    row_lag_B2A = repmat(row_B2A, lag, 1);
    % shift all "spikes" by lag you want to analyze for
    if lag == 1
        col_shifted = col;
        col_shifted_B2A = col_B2A;
    else
        col_shifted = vertcat(col_shifted, col + lag - 1);
        col_shifted_B2A = vertcat(col_shifted_B2A, col_B2A - lag + 1);
    end
    % create sparse matrix with these shifted spikes
    spike_matrix_lag = flip(sparse(row_lag, col_shifted, 1, num_units, size(spike_matrix, 2)), 1);
    spike_matrix_lag = spones(spike_matrix_lag);
    % compute number of coincidences as product of the two matrices
    coincidences(:, :, lag) = flipud(full(spike_matrix_lag * spike_matrix'));
    % compute "tiled time" (normalization factor) as the number of non-zero entries
    % for every unit on the receiving end - hence the flipping
    tot_time(:, maxLag - lag + 2) = flip(full(sum(spike_matrix_lag, 2)));
    tot_time(:, maxLag + lag) = flip(full(sum(spike_matrix_lag, 2)));
    % all the same as above
    spike_matrix_lag_B2A = flip(sparse(row_lag_B2A, col_shifted_B2A, 1, num_units, size(spike_matrix_B2A, 2)), 1);
    spike_matrix_lag_B2A = spones(spike_matrix_lag_B2A);
    coincidences_negative(:, :, lag) = flipud(full(spike_matrix_lag_B2A * spike_matrix_B2A'));
end
% concatenate positive and negative coincidences into a matrix. the
% negative ones are flipped so that they start with -maxlag and end with
% lag = 0. note that both pos and neg coinc have lag = 0, so one gets
% deleted
big_coincidences = cat(3, flip(coincidences_negative(:, :, 2 : end), 3), ...
    coincidences);
% scale up the number of spikes to the same size as coincidence matrix, so
% that you can use it to normalize
n_spikes = repmat(n_spikes', size(big_coincidences, 1), 1, ...
    size(big_coincidences, 3));
% normalize
big_coincidences = big_coincidences ./ n_spikes;
% scale up the tot tiled time to the same size as coincidence matrix, so
% that you can use it to subtract (and divide) according to the formula
% STTC = (Pa-Tb)./(1-Pa*Tb)
% this piece of code is a bit messy, but basically I am first scaling up
% the matrix. To have it in the right order I have to vectorize it,
% transpose it, repeat it, reshape it and finally permute it...
% the final outcome is that for every lag there is a square matrix in which
% the value indicates the total amount of time tiled by the spike train on
% the "receiving" end. Everything is then normalized by the length of spike
% matrix (so you have a proportion)
% ex. for lag = 1, it will be [A, A, A; B, B, B; C, C, C], where the
% capital letters indicate the norm amount of time tiled by that spike train
tiled_time = 1 / length(spike_matrix) * permute(reshape(repmat(tot_time(:), 1, ...
    num_units)', num_units, num_units, []), [2, 1, 3]);
coefficients = (big_coincidences - tiled_time) ./ ...
    (1 - big_coincidences .* tiled_time);

% rectify and reshape them in the form that tcoeffs will be spit out
coefficients = reshape(coefficients(:), [], maxLag * 2 + 1, 1);
% get rid of the values that correspond to the tcoeff of each spike train
% to itself. they were originally on the diag of each (lag) matrix. so
% delete every *num_units + 1* row starting from the first one
coefficients(1 : num_units + 1 : end, :) = [];

% compute indexes that belong to A2B and those that belong to B2A (they are
% intermingled in the coefficient matrix as is now). Specifically.. the
% first num_units-1 are B2A, then 1 that is A2B, then num_units-2 that are
% B2A, 2 A2B, num_units-3 that are A2B .... 1 that is A2B, num_units-1 that
% is B2A.
% there is a simmetry with cycle = num_units. if you put in a
% n_units*n_units-1 matrix, the tril of it corresponds to the B2A indexes
TCA2B = coefficients(~ tril(ones(num_units - 1, num_units)), :);
TCB2A = coefficients(tril(ones(num_units - 1, num_units)) > 0, :);

end
