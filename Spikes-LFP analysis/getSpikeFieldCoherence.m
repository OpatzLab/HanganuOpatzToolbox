function [SFC, medSFC, freq] = getSpikeFieldCoherence(LFP, MUA, fs, fsMUA, threshold, windowLength, nfft, maxFreq)
% by Mattia: computes Spike Filed Coherence (SFC) and median SFC.
%            based on this paper from Pascal Friese https://goo.gl/quC115
%
%% input:
%       LFP :                    entire signal
%       MUA :                    not downsampled!
%       fs :                     sampling frequency for LFP
%       fsMUA :                  sampling frequency for MUA (should be ~ 32000)
%       threshold :              for spike detection, for example 5
%       windowLength :           window around spike for which to compute power (in seconds)
%       nfft :                   number of points to use for FFT
%       maxFreq :                maximum frequency to include in the power spectrum
%                                (optional). Default is none.

% output:
%      SFC :                     spike field coherence
%      medSFC :                  median spike field coherence
%      freq :                    frequency vector at which power spectra are computed

% dependencies:
%      peakfinder function: should already be in the toolbox, otherwise go to https://goo.gl/pFzMPo

%% 

overlap = 0; % segments of LFP are not contiguous, using overlapping windows makes no sense
downsampling_factor = fsMUA / fs; % get scaling factor for MUA timepoints -> LFP timepoints
recordingMUA = ZeroPhaseFilter(MUA, 32000, [500 5000]); % filter MUA using standard frequency band
thr = std(recordingMUA) * threshold; % calculate threshold for 
[SpikeTimestamps, ~] = peakfinderOpto(recordingMUA, thr / 2, -thr, -1, false); % find spike timestamps
clearvars recordingMUA MUA % clear heavy variables that are not useful anymore
SpikeTimestamps = round(SpikeTimestamps / downsampling_factor); % scale spike timestamps from fsMUA to fs
SpikeTimestamps(SpikeTimestamps == 0) = 1; 

LFP_segments = zeros(length(SpikeTimestamps), windowLength * fs + 1); % preallocate variable for increased speed
powSpectrumBand = zeros(length(SpikeTimestamps), 128); % preallocate variable for increased speed

signal_filtered = ZeroPhaseFilter(LFP, fs, [1 100]); % filter LFP signal
clear LFP % clear heavy variables that are not useful anymore

for segment_idx = 1 : length(SpikeTimestamps) % loop through all detected spikes
    
    if SpikeTimestamps(segment_idx) - windowLength * fs / 2 > 0 && ...
            SpikeTimestamps(segment_idx) + windowLength * fs / 2 < length(signal_filtered) % make sure that your window is not exceeding
                                                                                           % signal limit (i.e. it does not start/end 
                                                                                           % before/after the beginning/end of the signal)
        
        signal =  signal_filtered(SpikeTimestamps(segment_idx) - windowLength * fs / 2 ...
            : SpikeTimestamps(segment_idx) + windowLength * fs / 2); % definte signal as the portion of signal that is centered around the spike
        LFP_segments(segment_idx, :) = signal; % save portion of signal for later calculations
        powSpectrumBand(segment_idx, :) = pWelchSpectrum(signal', windowLength, overlap, nfft, fs, maxFreq); % calculate power spectrum for
                                                                                                             % the portion of the signal
        
    end
    
end

powSpectrum = mean(powSpectrumBand); % average over single "signal portion" power spectra
meanLFP = mean(LFP_segments); % average over single "signal portion" LFPs -> mean LFP
[meanLFPpowSpectrum, freq] = pWelchSpectrum(meanLFP', windowLength, overlap, nfft, fs, maxFreq); % compute power spectrum of mean LFP
SFC = meanLFPpowSpectrum ./ powSpectrum; % compute SFC

powSpectrum = median(powSpectrumBand); % as above but using median and medianSpectrum 
medianLFP = median(LFP_segments);
medianLFPpowSpectrum = medianSpectrum(medianLFP', windowLength, overlap, nfft, fs, maxFreq);
medSFC = medianLFPpowSpectrum ./ powSpectrum';

end