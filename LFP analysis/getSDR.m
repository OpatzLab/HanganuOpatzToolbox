function SDR = getSDR(PSD1, PSD2, freqs, freq_bins)
% calculates Spectral Dependency Ratio according to Shajarisales et
% al., 2015, and as in Ramirez-Villegas et al., 2020

% inputs:       - PSD1 & 2: two power spectral density
%               - freqs : a frequency vector corresponding to PSD1 & 2.
%                         Leave it empty ([]) if you want to compute SIC on
%                         the entire frequency spectrum
%               - freq_bins : the frequency bins on which to compute PSD.
%                             Leave it empty ([]) if you want to compute
%                             SIC on the entire frequency spectrum
% output:       - SDR: PSD1->PSD2 in the first column, viceversa in the
%                      second column

if ~ isempty(freq_bins)
    SDR = NaN(numel(freq_bins) - 1, 2);
    for idx = 1 : numel(freq_bins) - 1
        freqs2analyze = freqs > freq_bins(idx) & freqs < freq_bins(idx + 1);
        SDR(idx, 1) = nanmean(PSD2(freqs2analyze)) / (nanmean(PSD1(freqs2analyze)) * ...
            nanmean(PSD2(freqs2analyze) ./ PSD1(freqs2analyze)));
        SDR(idx, 2) = nanmean(PSD1(freqs2analyze)) / (nanmean(PSD2(freqs2analyze)) * ...
            nanmean(PSD1(freqs2analyze) ./ PSD2(freqs2analyze)));
    end
else
    SDR(1, 1) = nanmean(PSD2) / (nanmean(PSD1) * nanmean(PSD2 ./ PSD1));
    SDR(1, 2) = nanmean(PSD1) / (nanmean(PSD2) * nanmean(PSD1 ./ PSD2));
end