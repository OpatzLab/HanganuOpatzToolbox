function [ripples] = getRipples(experiment, signal, fs, freq_band, thresholds, durations, save_data, repeatCalc)
%    by Mattia based on buszaki code:
%    https://github.com/buzsakilab/buzcode/blob/master/detectors/detectEvents/bz_FindRipples.m

%    Ripples are detected using the normalized squared signal (NSS) by
%    thresholding the baseline, merging neighboring events, thresholding
%    the peaks, and discarding events with excessive duration.
%    Thresholds are computed as multiples of the standard deviation of
%    the NSS.

%   inputs:
%           - experiment: as usual
%           - signal: on which to detect ripples (HP reversal) -> 1 x whatever
%           - fs: sampling frequency of signal (standard: 1000 Hz) -> 1000
%           - freq_band : frequencies in which to detect ripples (100-200
%               Hz is standard) -> [100 200]
%           - thresholds: thresholds for ripple beginning/end and peak, in
%               multiples of the stdev (standard = [2 5]);
%           - durations: min inter-ripple interval and max ripple duration,
%               in ms (standard = [100 300]).
%           - save_data: as usual
%           - repeatCalc: as usual

results_folder = 'Q:\Personal\Mattia\SharpProject\results\ripples\';

if repeatCalc == 0 && exist(strcat(results_folder, experiment.animal_ID, '.mat'), 'file')
    load(strcat(results_folder, experiment.animal_ID))
else
    % create a vector of timestamps (will be used to indicate where ripples
    % are)
    timestamps = (1 : length(signal))';
    
    % filter signal to ripple freq band
    signal = ZeroPhaseFilter(signal, fs, freq_band);
    
    % set parameter
    windowLength = fs / fs * 11;
    % create square normalized filter with length of windowLength
    window = ones(windowLength, 1) / windowLength;
    
    % Square and normalize signal
    squaredSignal = signal .^ 2;
    % changed confusing part of buszaki code; seems to give exactly the same
    % results using a more straightforward and readable syntax. it's just
    % passing the signal through a square filter
    convolvedSignal = conv(squaredSignal, window, 'same'); clear squaredSignal
    stdev = std(convolvedSignal);
    normSignal = (convolvedSignal - mean(convolvedSignal)) / stdev; clear convolvedSignal
    
    % Detect ripple periods by thresholding normalized squared signal
    thresholded = normSignal > thresholds(1);
    start = find(diff(thresholded) > 0);
    stop = find(diff(thresholded) < 0);
    
    % Exclude last ripple if it is incomplete
    if length(stop) == length(start) - 1
        start = start(1 : end - 1);
    end
    % Exclude first ripple if it is incomplete
    if length(stop) - 1 == length(start)
        stop = stop(2 : end);
    end
    % Correct special case when both first and last ripples are incomplete
    if start(1) > stop(1)
        stop(1) = [];
        start(end) = [];
    end
    firstPass = [start',stop'];
    if isempty(firstPass)
        disp('Detection by thresholding failed');
        return
    else
        disp(['After detection by thresholding: ' num2str(length(firstPass)) ' events.']);
    end
    
    % Merge ripples if inter-ripple period is too short
    minInterRippleSamples = durations(1) / 1000 * fs;
    secondPass = [];
    ripple = firstPass(1,:);
    for i = 2:size(firstPass,1)
        if firstPass(i,1) - ripple(2) < minInterRippleSamples
            % Merge
            ripple = [ripple(1) firstPass(i,2)];
        else
            secondPass = [secondPass ; ripple];
            ripple = firstPass(i,:);
        end
    end
    secondPass = [secondPass ; ripple];
    if isempty(secondPass)
        disp('Ripple merge failed');
        return
    else
        disp(['After ripple merge: ' num2str(length(secondPass)) ' events.']);
    end
    
    % Discard ripples with a peak power < highThresholdFactor (thresholds(2))
    thirdPass = [];
    peakNormalizedPower = [];
    for i = 1 : length(secondPass)
        maxValue = max(normSignal([secondPass(i, 1) : secondPass(i, 2)]));
        if maxValue > thresholds(2)
            thirdPass = [thirdPass ; secondPass(i,:)];
            peakNormalizedPower = [peakNormalizedPower ; maxValue];
        end
    end
    if isempty(thirdPass)
        disp('Peak thresholding failed.');
        return
    else
        disp(['After peak thresholding: ' num2str(length(thirdPass)) ' events.']);
    end
    
    % Detect negative peak position for each ripple
    peakPosition = zeros(size(thirdPass,1),1);
    for i=1:size(thirdPass,1)
        [~, minIndex] = min(signal(thirdPass(i,1):thirdPass(i,2)));
        peakPosition(i) = minIndex + thirdPass(i,1) - 1;
    end
    
    % Discard ripples that are way too long
    ripples = [timestamps(thirdPass(:,1)) timestamps(peakPosition) ...
        timestamps(thirdPass(:,2)) peakNormalizedPower];
    duration = ripples(:,3)-ripples(:,1);
    ripples(duration > durations(2),:) = NaN;
    % Discard ripples that are too short
    ripples(duration < 20 , :) = NaN; % seems to be hard-coded in buz-code
    ripples = ripples((all((~ isnan(ripples)), 2)), :);
    disp(['After duration test: ' num2str(size(ripples,1)) ' events.']);
    
    %% put into a structure
    
    rips = ripples; clear ripples
    
    ripples.timestamps = rips(:, [1 3]);
    ripples.peaks = rips(:, 2); % peaktimes
    ripples.peakNormedPower = rips(:, 4); % amplitudes
    ripples.stdev = stdev;
    
    if save_data == 1
        save(strcat(strcat(results_folder, experiment.animal_ID)), 'ripples')
    else
        disp('Data not saved!')
    end
end