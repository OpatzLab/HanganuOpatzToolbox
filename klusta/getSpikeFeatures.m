function unit_features = getSpikeFeatures(waveform)
% by Mattia 01.19
% this functions extracts waveform features that should be useful for
% distinguishing PYR from IN. Not yet there in neonatal mice, but it should
% work for juvenile/adult. 
% input : waveform (thought for the output of klusta, not everything might
%         work for other formats)

% output : waveform features for IN vs PYR clustering

trough = min(waveform); % find the trough, aka the negativity peak of the spike
halfwave = round(length(waveform) / 2); 

[~, trough_timestamp, halfwidth] = findpeaks(-waveform, 'NPeaks', 1, 'MinPeakHeight', -trough - 1); % spike halfwidth
[peaks, peaks_timestamps] = findpeaks(waveform, 'MinPeakDistance', 10, 'NPeaks', 2, ...
    'MinPeakHeight', 0); % find the two positive peaks (doesn't always work)

if numel(peaks) == 1 % i.e. one of the "peaks" is the first or the last waveform point; correct for that
    if find(waveform == peaks) < halfwave % if the peak that was found is in the first half, the missing one is the last point
        peaks(2) = waveform(end);
        peaks_timestamps(2) = length(waveform);
    else                            % the inverse of above
        peaks(2) = waveform(1); 
        peaks_timestamps(2) = 1;
    end
end
if numel(peaks) == 0 % rare, but it happens
    peaks(1) = waveform(1);
    peaks_timestamps(2) = 1;
    peaks(2) = waveform(end);
    peaks_timestamps(2) = length(waveform);    
end

if max(peaks_timestamps) < trough_timestamp % i.e. the wave has a funny shape and it finds two peaks in the first half
    [peaks, peaks_timestamps] = findpeaks(waveform, ...
        'MinPeakDistance', 5, 'NPeaks', 1, 'MinPeakProminence', 10);
    [peaks(2), peaks_timestamps(2)] = max(waveform(trough_timestamp + 1 : end));
    peaks_timestamps(2) = peaks_timestamps(2) + trough_timestamp;
end

peaks = peaks - trough; % set both peaks to positive

% since the above method for finding the two positive peaks is not always
% optimal, here there is an alternative one. Peaks are defined as the
% closest points to the trough (one left and one right) in which the first
% derivative of the waveform is 0. That is the last/first point
% before/after the trough in which the waveform is flat. 
% NOTE TO EVERYONE: YOU MIGHT NOT NEED THIS. STILL IN BETA!!

derWaveform = diff(waveform); % first derivative of the waveform
alt_peaks_timestamps(1) = find(derWaveform(1 : halfwave) > 0.1, 1, 'last');
alt_peaks(1) = waveform(alt_peaks_timestamps(1));
alt_peaks_timestamps(2) = find(derWaveform(halfwave + 5 : end) < 0.1, 1) + halfwave + 5;
alt_peaks(2) = waveform(alt_peaks_timestamps(2));
alt_peaks = alt_peaks - trough; % set both peaks to positive

try
    unit_features(1) = halfwidth / 32; % spike halfwidth in ms
    unit_features(2) = (peaks(2) - peaks(1)) / sum(peaks); % asimmetry index as in Sirota et al. 2008
    unit_features(3) = (peaks_timestamps(2) - trough_timestamp) / 32; % trough to peak in ms
    unit_features(4) = (alt_peaks(2) - alt_peaks(1)) / sum(alt_peaks); % asimmetry index as in Sirota et al. 2008
    unit_features(5) = (alt_peaks_timestamps(2) - trough_timestamp) / 32; % trough to peak in ms
catch
    unit_features(1 : 5) = NaN;
end


end