function [TCA2B, TCB2A] = fastTC(spike_matrix, lags)
%% by Mattia

% inputs:
% spike_matrix: units * time 
% lags: single lags at which you want the coeff to be computed
% units as the spike_matrix

% output:
% Tiling Coefficient: given a matrix with a, b, c ... k-1, k units, the output will be
% in the form of ab, ac, ad ..., ak-1, ak, bc, bd ... kk-2, kk-1
% Tiling CoefficientB2A: as above but from B to A, not from A to B -> ba,
% bc, bd ....

% this version is like the cumulative one (not single bins) but does not
% need "sequential" values for lags, you don't give maxlag, but rather a
% series of lags

if issparse(spike_matrix)
    spike_matrix = full(spike_matrix);
end
% this serves to correct a 1ms mismatch in lags between this version and
% the standard one (from which the core of the script is taken)
lags = lags + 1;
% create another matrix that will be used to compute correlations in the
% other direction
spike_matrix_B2A = spike_matrix;
% "extend" matrix to be able to accept shifted spikes (max shift is maxLag)
spike_matrix(:, end + max(lags)) = 0;
% same as above, in a different direction
spike_matrix_B2A = [zeros(size(spike_matrix_B2A, 1), max(lags)) spike_matrix_B2A];
% compute number of units
num_units = size(spike_matrix, 1);
% compute number of spikes for every unit
n_spikes = sum(spike_matrix, 2);
% sparsify both matrices
spike_matrix = sparse(spike_matrix);
spike_matrix_B2A = sparse(spike_matrix_B2A);
% find rows and columns of non-zero entries in both matrices
[row, col] = find(spike_matrix > 0);
[row_B2A, col_B2A] = find(spike_matrix_B2A > 0);
% initialize matrix to detect (B2A) coincidences
coincidences = zeros(num_units, num_units, numel(lags));
coincidences_negative = coincidences;
% initialize matrix that counts amount of "tiled" time
tot_time = zeros(num_units, 2 * numel(lags));

% loop over all lags
lag_idx = 1;
for lag = lags
    % create two row vectors in which you don't change the value (spikes
    % occur always on the same unit) but have lenght such as the col
    % shifted to create the sparse matrix
    row_lag = repmat(row, lag, 1);
    row_lag_B2A = repmat(row_B2A, lag, 1);
    % set these variables just because you can't overwrite col and col_B2A
    % that will be used again inside the loop
    col_shifted = col;
    col_shifted_B2A = col_B2A;
    % shift all "spikes" by lag you want to analyze for
    for lag2add = 2 : lag
        col_shifted = vertcat(col_shifted, col + lag2add - 1);
        col_shifted_B2A = vertcat(col_shifted_B2A, col_B2A - lag2add + 1);
    end
    % create sparse matrix with these shifted spikes
    spike_matrix_lag = flip(sparse(row_lag, col_shifted, 1, num_units, size(spike_matrix, 2)), 1);
    spike_matrix_lag = spones(spike_matrix_lag);
    % compute number of coincidences as product of the two matrices
    coincidences(:, :, lag_idx) = flipud(full(spike_matrix_lag * spike_matrix'));
    % compute "tiled time" (normalization factor) as the number of non-zero entries
    % for every unit on the receiving end - hence the flipping
    % compute "tiled time" (normalization factor) as the number of non-zero entries
    % for every unit (both directions)
    tot_time(:, numel(lags) - lag_idx + 1) = flip(full(sum(spike_matrix_lag, 2)));
    tot_time(:, numel(lags) + lag_idx) = flip(full(sum(spike_matrix_lag, 2)));
    % all the same as above
    spike_matrix_lag_B2A = flip(sparse(row_lag_B2A, col_shifted_B2A, 1, num_units, size(spike_matrix_B2A, 2)), 1);
    spike_matrix_lag_B2A = spones(spike_matrix_lag_B2A);
    coincidences_negative(:, :, lag_idx) = flipud(full(spike_matrix_lag_B2A * spike_matrix_B2A'));
    % adjust lag index
    lag_idx = lag_idx + 1;
end
% concatenate positive and negative coincidences into a matrix. the
% negative ones are flipped so that they start with -maxlag and end with
% lag = 0. note that both pos and neg coinc have lag = 0, so one gets
% deleted
big_coincidences = cat(3, flip(coincidences_negative, 3), ...
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
coefficients = reshape(coefficients(:), [], numel(lags) * 2, 1);
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
% n_units*n_units-1 matrix, the tril of it corresponds to the B2A indexes.
% Then you just have to rearrange the order (the part that is done with
% sort(rows). Hard to exaplain with words, easier to code
triangle = ~ tril(ones(num_units - 1, num_units));
[rows, ~] = find(triangle);
[~, rows] = sort(rows);
indexes = find(triangle);
indexes = indexes(rows);
TCA2B = coefficients(indexes, :);
% same (specular) for the other direction
triangle = tril(ones(num_units - 1, num_units));
TCB2A = coefficients(triangle > 0, :);
end