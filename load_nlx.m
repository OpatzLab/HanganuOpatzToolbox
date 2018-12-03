function [TimeStamps, signal, fs] = load_nlx(File, ExtractMode, ExtractModeArray)
% Load neuralynx file (.nlx) to matlab (.mat)
% from Sebastian Bitzenhofer 2017-10, revised by Mattia 2018-12

% Input 
% file:             - full file path as a string (es.
%                   'U:\Recording_data_4_2015_09_21\OptoTwins\2015-12-09_09-15-42\CSC17.ncs')
% ExtractModeArray: - [] for full trace; 
%                   - [start_time end_time] in milliseconds or samples (see below)
%                   if you only want to load a part of the signal
% ExtractMode:      - 1 for full trace; 
%                   - 2 if your [start_time end_time] is in samples
%                   - 3 if your [start_time end_time] is in milliseconds

%Output 
% TimeStamps:       - TimeStamps of samples as row vector (milliseconds or samples)
% signal:           - signal as row vector (microvolt)
% fs:               - sampling frequency

FieldSelectionArray     = [1 0 0 0 1]; % TimeStamps, ChannelNumbers, SampleFrequencies, NumberValidSamples, Samples
ExtractHeaderValue      = 1;

if ExtractMode == 1
    [TimeStamps, signal, Header] = Nlx2MatCSC(File, FieldSelectionArray, ExtractHeaderValue, ...
        ExtractMode, ExtractModeArray); % load signal and time vector, and the file header
    ADBitVolts = str2double(Header{contains(Header, 'ADBitVolts')}(length('-ADBitVolts ') : end)); % extract converting factor from header
    fs = str2double(Header{contains(Header, 'SamplingFrequency')}(length('-SamplingFrequency ') : end)); % extract sampling freq from header
    signal = reshape(signal, 1, []) .* ADBitVolts * 10 ^ 6; % rectify signal and adjust it to microVolt
    TimeStamps = linspace(TimeStamps(1), TimeStamps(end) + 511 / fs * 10 ^ 6, ...
        length(signal)) / 10 ^ 3; %adjust to msec; very small errors indtroduced due to imperfect sampling of the neuralynx system 
%    (examples tested with ~1 wrong timestamp in 1.5 hour recording leading to 2 ms difference in total duration)
    
elseif ExtractMode == 2
    ExtractModeArrayCorr(1) = floor(ExtractModeArray(1) / 512); % convert to neuralynx samples (512 by 512)
    ExtractModeArrayCorr(2) = ceil(ExtractModeArray(2) / 512); % convert to neuralynx samples (512 by 512)
    [~, signal, Header] = Nlx2MatCSC(File, FieldSelectionArray, ExtractHeaderValue, ...
        ExtractMode, ExtractModeArrayCorr); % load signal and time vector, and the file header
    TimeStamps = [];
    ADBitVolts = str2double(Header{contains(Header, 'ADBitVolts')}(length('-ADBitVolts ') : end)); % extract converting factor from header
    fs = str2double(Header{contains(Header, 'SamplingFrequency')}(length('-SamplingFrequency ') : end)); % extract sampling freq from header
    signal = reshape(signal, 1, []) .* ADBitVolts * 10 ^ 6; % rectify signal and adjust it to microVolt
    
elseif ExtractMode == 4
    ExtractModeArrayCorr(1) = (ExtractModeArray(1) -100) * 10 ^ 3; % convert to seconds 
    ExtractModeArrayCorr(2) = (ExtractModeArray(2) + 100) * 10 ^ 3; % convert to seconds 
    [TimeStamps, signal, Header] = Nlx2MatCSC(File, FieldSelectionArray, ExtractHeaderValue, ...
        ExtractMode, ExtractModeArrayCorr); % load signal and time vector, and the file header
    ADBitVolts = str2double(Header{contains(Header, 'ADBitVolts')}(length('-ADBitVolts ') : end)); % extract converting factor from header
    fs = str2double(Header{contains(Header, 'SamplingFrequency')}(length('-SamplingFrequency ') : end)); % extract sampling freq from header
    signal = reshape(signal, 1, []) .* ADBitVolts * 10 ^ 6; % rectify signal and adjust it to microVolt
    TimeStamps = linspace(TimeStamps(1), TimeStamps(end) + 511 / fs * 10 ^ 6, ...
        length(signal)) / 10 ^ 3; %adjust to msec; very small errors indtroduced due to imperfect sampling of the neuralynx system 
%    (examples tested with ~1 wrong timestamp in 1.5 hour recording leading to 2 ms difference in total duration)
end

% correct for unprecise loading of Nlx2Mat with ExtractModeArray
if ExtractMode == 2
    samplecorrect1 = ExtractModeArray(1) - ExtractModeArrayCorr(1) * 512 + 1;
    samplecorrect2 = length(signal) - (ExtractModeArrayCorr(2) * 512 - ExtractModeArray(2)) - 512;
    signal = signal(samplecorrect1 : samplecorrect2);
elseif ExtractMode == 4
    timecorrect1 = find(TimeStamps >= ExtractModeArray(1), 1);
    timecorrect2 = find(TimeStamps >= ExtractModeArray(2), 1);
    TimeStamps = TimeStamps(timecorrect1 : timecorrect2);
    signal = signal(timecorrect1 : timecorrect2);
end

