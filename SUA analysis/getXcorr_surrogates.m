function [Xcorr_surr99, Xcorr_surr1] = getXcorr_surrogates(spike_matrix, max_lag, jitter, nboots)

%% By Mattia

% - spike_matrix: neurons * spiketimes in ms
% - max_lag: in ms (20-30 ms is a meaningful range)
% - jitter: in ms (5-10 ms is a meaningful range), the smaller the jitter,
%       the more conservative is the surrogate set
% - nboots: the number of surrogate to calculate (200 - 5000 is a reasonable range). the higher the number, the
%       more accurate the surrogate set, but the longer the calculation
%       time

Xcorr_surr = zeros(size(spike_matrix, 1), 2 * max_lag + 1, nboots);
autocorr = 0;

for nboot = 1 : nboots
    lags = round(- (2 * jitter) .* rand(nnz(spike_matrix), 1) + jitter);
    [rows, columns] = find(spike_matrix);
    columns = columns + lags;
    columns(columns < 1) = 1;
    surrogate_spike_matrix = sparse(rows, columns, ones(1, nnz(spike_matrix)));
    Xcorr_surr(:, :, nboot) = fastXcorr(surrogate_spike_matrix, max_lag, autocorr);
end

Xcorr_surr_sorted_animal = sort(Xcorr_surr, 3);
percent99 = floor(nboots / 100 * 99);
percent1 = ceil(nboots / 100);
Xcorr_surr99 = Xcorr_surr_sorted_animal(:, :, percent99);
Xcorr_surr1 = Xcorr_surr_sorted_animal(:, :, percent1);

end
