function [timestamps, amplitude] = getMUAspiketimes(signal, fs, FrequencyBandMUA, thr)
% by Mattia, based on an old Joachim's function
% INPUT
%   MUA :                 - unfiltered, not downsampled signal
%   fs :                  - sampling frequency in Hz (should be ~32000)
%   FrequencyBandMUA :    - the frequency at which you want to filter your
%                         signal (optional: default is 500 - 5000 Hz).
%                         Example: [300 5000]
%   thr :                 - the number of times to multiply the standard
%                         deviation of the signal to define the minimum
%                         amplitude at which a spike is detected
% OUTPUT
%   timestamps :          - spike timestamps (in timestamps, not
%                         milliseconds)
%   amplitude :           - spike amplitude (microVolts)

% DEPENDENCIES
%   peakfinder function: should already be in the toolbox, otherwise go to https://goo.gl/pFzMPo

%% define default values if FrequencyBandMUA or threshold parameters are not set
if nargin < 4    
    thr = 5;
    if nargin < 3 || isempy(FrequencyBandMUA)
        FrequencyBandMUA = [500 5000]; % the frequency band at which the signal will be filtered. This is a standard range
    end
end

%% filter signal and set threshold 

signalMUA = ZeroPhaseFilter(signal, fs, FrequencyBandMUA); % filter
threshold = std(signalMUA) * thr; % set threshold

%% detect all spikes in period window
[timestamps, amplitude] = peakfinder(signalMUA, threshold/2, ...
    -threshold, -1, false); % find peak with minimum amplitude = thr, minimum prominence = thr/2,
                            % look for minima and not maxima (spikes are
                            % negative deflections), do not include extreme
                            % points (beginning and end) of the signal in
                            % the search for spikes

end