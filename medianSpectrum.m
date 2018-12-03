function [spectrum, freq] = medianSpectrum(signal, windowSize, overlap, nfft, fs, maxFreq)

%% Calculate median power spectrum using matlab pwelch on single windows
%       By Mattia

%       This function replaces the last step of welch's method (mean) with
%       a median. If you are unsure why this is preferrable to the mean,
%       see ("Measuring the average power of neural oscillations",
%       Izhikevich et al., 2018)

%       INPUTS:
%       signal: ´        signal in row vector
%       windowSize:      windowSize in sec (2)
%       overlap:         overlap of consecutive windows in sec (0)
%       nfft:            number of points to use for FFT
%       fs:              sampling frequency (in Hz)
%       maxFreq:         maximum frequency to include in the power spectrum
%                        (optional). Default is none.

%       OUTPUT:
%       spectrum:        power spectrum
%       freq:            frequency vector (in Hz) at which the
%                        corresponding power spectrum has been computed

if nargin < 6
    maxFreq = [];
end

overlap = overlap * fs;
window_length = windowSize * fs;
n_windows = floor((length(signal) - 1) / window_length);

spectrum = zeros(n_windows, floor(nfft / 2 + 1));

for window_idx = 1 : n_windows
    Window = (window_idx - 1) * window_length + 1 : window_idx * window_length + 1;
    [spectrum(window_idx, :), freq] = pwelch(signal(Window), hanning(window_length), ...
        overlap, nfft, fs);
end

if n_windows > 1
    spectrum = median(spectrum);
end

if ~isempty(maxFreq) && n_windows > 0
    freq = freq(freq <= maxFreq)';
    spectrum = spectrum(1 : length(freq))';
else
    freq = NaN;
    spectrum = NaN;
end

end