function [spectrum, freq] = pWelchSpectrum(signal, windowSize, overlap, nfft, fs, maxFreq)

%% Calculate powerSpectrum using pWelch's method
%       By Joachim, updated by Mattia

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

[spectrum, freq] = pwelch(signal, hanning(windowSize*fs), overlap*fs, nfft, fs); % calculate power spectrum

if ~isempty(maxFreq)
    freq = freq(freq <= maxFreq)'; % crop the frequency vector to maxFreq
    spectrum = spectrum(1 : length(freq))'; % crop the power spectrum to maxFreq
end

end