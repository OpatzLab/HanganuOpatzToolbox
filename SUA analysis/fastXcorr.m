function Xcorr = fastXcorr(spike_matrix, maxLag, autocorr)
%% by Mattia
%% compute cross correlation for sparse binary matrices (orders of magnitude faster than matlab xcorr)

% inputs:
% spike_matrix: units * time 
% maxLag: the maximum lag for which xcorr will be computed. in the same
% units as the spike_matrix
% autocorr: 1 if you also want to compute autocorrelations, 0 if you don't

% output:
% Xcorr: given a matrix with a, b, c ... k-1, k units, the output will be
% in the form of aa, ab, ac ..., ak-1, ak, ba, bb, bc ... kk-1, kk

%%

spike_matrix(:, end + maxLag) = 0;
num_units = size(spike_matrix, 1);
spike_matrix = sparse(spike_matrix);
[row, col] = find(spike_matrix);
x_corr = zeros(num_units, num_units, maxLag + 1);

for lag = 1 : maxLag + 1
    
    matrix_shifted = flip(sparse(row, col + lag - 1, 1, num_units, size(spike_matrix, 2)), 1);
    x_corr(:, :, lag) = full(matrix_shifted * spike_matrix');
    
end
clearvars -except x_corr num_units autocorr

idx = 0;

if autocorr == 1
    for iUnit1 = 1 : num_units
        
        for iUnit2 = iUnit1 : num_units
            
            idx = idx + 1;
            Xcorr(idx, :) = cat(1, flip(squeeze(x_corr(end - iUnit1 + 1, iUnit2, :))), ...
                squeeze(x_corr(end - iUnit2 +  1, iUnit1, 2 : end)));
            
        end
    end
    
else
    for iUnit1 = 1 : num_units
        
        for iUnit2 = iUnit1 + 1 : num_units
            idx = idx + 1;
            Xcorr(idx, :) = cat(1, flip(squeeze(x_corr(end - iUnit1 + 1, iUnit2, :))), ...
                squeeze(x_corr(end - iUnit2 +  1, iUnit1, 2 : end)));
            
        end
    end
end

end