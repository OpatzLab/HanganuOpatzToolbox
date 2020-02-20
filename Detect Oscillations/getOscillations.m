function [oscillations] = getOscillations(experiment, signal, fs, freq_band, rel_thresholds, ...
    abs_thresholds, durations, save_data, repeatCalc, results_folder, channel, verbose)
%    by Mattia based on buszaki code:
%    https://github.com/buzsakilab/buzcode/blob/master/detectors/detectEvents/bz_FindRipples.m
%    similar to getRipples but includes also an absolute threshold to make
%    comparisons across ages more consistent

%    Oscillations are detected using the normalized squared signal (NSS) by
%    thresholding the baseline, merging neighboring events, thresholding
%    the peaks (abs and rel), and discarding events with short duration.

%   inputs:
%           - experiment: as usual
%           - signal: on which to detect oscillations -> 1 x whatever
%           - fs: sampling frequency of signal (standard: 1000 Hz) -> 1000
%           - freq_band : frequencies in which to detect ripples (4-20
%               Hz is standard) -> [4 20]
%           - rel_thresholds: thresholds for oscillations beginning/end 
%               and peak, in multiples of the stdev (standard = [2 5]);
%           - abs_threshold: absolute peak threshold
%           - durations: min inter-oscillation interval and max oscillation
%               duration, in ms (standard = [1000 500]).
%           - save_data: as usual
%           - repeatCalc: as usual

if repeatCalc == 0 && exist(strcat(results_folder, experiment.animal_ID, '.mat'), 'file')
    load(strcat(results_folder, experiment.animal_ID))
    oscillations = oscillations(channel);
else
    % create a vector of timestamps (will be used to indicate where ripples
    % are)
    timestamps = (1 : length(signal))';
    
    % filter signal to oscillations freq band
    signal = ZeroPhaseFilter(signal, fs, freq_band);
    
    % set parameter
    windowLength = fs / 2;
    % create square normalized filter with length of windowLength
    window = ones(windowLength, 1) / windowLength;
    
    % Square and normalize signal
    squaredSignal = signal .^ 2;
    % changed confusing part of buszaki code; seems to give exactly the same
    % results using a more straightforward and readable syntax. it's just
    % passing the signal through a square filter
    convolvedSignal = conv(squaredSignal, window, 'same'); clear squaredSignal
    stdev = std(convolvedSignal);
    normSignal = (convolvedSignal - mean(convolvedSignal)) / stdev; 
    
    % Detect oscillations by thresholding normalized squared signal
    thresholded = normSignal > rel_thresholds(1) | convolvedSignal > abs_thresholds(1);
    start = find(diff(thresholded) > 0);
    stop = find(diff(thresholded) < 0);
    
    % Set a stop to last oscillation if it is incomplete (end with end of
    % recording)
    if length(stop) == length(start) - 1
        stop(end + 1) = length(thresholded);
    end
    % Set a start to first oscillation if it is incomplete (starts with
    % beginning of recording)
    if length(stop) - 1 == length(start)
        start(2 : end + 1) = start;
        start(1) = 1;
    end
    % Correct special case when both first and last oscillations are incomplete
    if start(1) > stop(1)
        start(2 : end + 1) = start;
        start(1) = 1;
        stop(end + 1) = length(thresholded);
    end
    firstPass = [start',stop'];
    if verbose > 0
        if isempty(firstPass)
            disp('Detection by thresholding failed');
            return
        else
            disp(['After detection by thresholding: ' num2str(length(firstPass)) ' events.']);
        end
    end
    
    % Merge oscillations if inter-oscillation period is too short
    minInterOscSamples = durations(1) / 1000 * fs;
    secondPass = [];
    oscillation = firstPass(1,:);
    for i = 2 : size(firstPass, 1)
        if firstPass(i,1) - oscillation(2) < minInterOscSamples
            % Merge
            oscillation = [oscillation(1) firstPass(i,2)];
        else
            secondPass = [secondPass ; oscillation];
            oscillation = firstPass(i,:);
        end
    end
    secondPass = [secondPass ; oscillation];
    if verbose > 0
        if isempty(secondPass)
            disp('Oscillation merge failed');
            return
        else
            disp(['Oscillation merge: ' num2str(length(size(secondPass, 1))) ' events.']);
        end
    end
    
    % Discard oscillations with a relative peak power < rel_thresholds(2)
    % and absolute peak power < abs_thresholds(2)
    thirdPass = [];
    peakNormalizedPower = [];
    peakAbsPower = [];
    for i = 1 : size(secondPass, 1)
        maxValue_rel = max(normSignal([secondPass(i, 1) : secondPass(i, 2)]));
        maxValue_abs = max(convolvedSignal([secondPass(i, 1) : secondPass(i, 2)]));
        if maxValue_rel > rel_thresholds(2) || maxValue_abs > abs_thresholds(2)
            thirdPass = [thirdPass ; secondPass(i, :)];
            peakNormalizedPower = [peakNormalizedPower ; maxValue_rel];
            peakAbsPower = [peakAbsPower ; maxValue_abs];
            
        end
    end
    if verbose > 0
        if isempty(thirdPass)
            disp('Peak thresholding failed.');
            return
        else
            disp(['After peak thresholding: ' num2str(size(thirdPass, 1)) ' events.']);
        end
    end
    
    % Detect negative peak position for each oscillation
    peakPosition = zeros(size(thirdPass,1),1);
    for i = 1 : size(thirdPass, 1)
        [~, minIndex] = min(signal(thirdPass(i, 1) : thirdPass(i, 2)));
        peakPosition(i) = minIndex + thirdPass(i,1) - 1;
    end
    
    if ~ isempty(thirdPass)
        % Discard oscillations that are too short
        oscillations = [timestamps(thirdPass(:,1)) timestamps(peakPosition) ...
            timestamps(thirdPass(:,2)) peakNormalizedPower];
        duration = oscillations(:,3) - oscillations(:,1);
        oscillations(duration < durations(2), :) = NaN;
        oscillations = oscillations((all((~ isnan(oscillations)), 2)), :);
        if verbose > 0
            disp(['After duration test: ' num2str(size(oscillations, 1)) ' events.']);
        end
        
        %% put into a structure
        
        osc = oscillations; clear oscillations
        
        oscillations.timestamps = osc(:, [1 3]);
        oscillations.peaks = osc(:, 2); % peaktimes
        oscillations.peakNormedPower = osc(:, 4); % amplitudes
        oscillations.stdev = stdev;
        oscillations.durations = duration;
        oscillations.peakAbsPower = peakAbsPower;
        oscillations.nnz_norm = nnz(normSignal > rel_thresholds(1)) / length(signal);
        oscillations.nnz_abs = nnz(convolvedSignal > abs_thresholds(1)) / length(signal);
    else
        oscillations.timestamps = NaN;
        oscillations.peaks = NaN; % peaktimes
        oscillations.peakNormedPower = NaN; % amplitudes
        oscillations.stdev = NaN;
        oscillations.durations = NaN;
        oscillations.peakAbsPower = NaN;
        oscillations.nnz_norm = NaN;
        oscillations.nnz_abs = NaN;
    end
    
    if save_data == 1
        save(strcat(strcat(results_folder, experiment.animal_ID)), 'oscillations')
    else
        if verbose > 0
            disp('Data not saved!')
        end
    end
end