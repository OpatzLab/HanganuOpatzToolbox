% Load neuralynx file (.nlx) to matlab (.mat)
% Sebastian Bitzenhofer 2017-10

function [TimeStamps, Samples, fs] = load_nlx_Modes(File,ExtractMode,ExtractModeArray)

%Input 
%file: file path and name as string
%ExtractModeArray: []-full trace; [start_time end_time] in milliseconds

%Output 
%TimeStamps: TimeStamps of samples as row vector in
%milliseconds [1xlength samples]
%Samples: samples as row vector in microvolt [1xlength samples]
%fs: samples recorded per second [1x1] 

FieldSelectionArray     = [1 0 0 0 1]; %TimeStamps, ChannelNumbers, SampleFrequencies, NumberValidSamples, Samples
ExtractHeaderValue      = 1;

if ExtractMode==1
    [TimeStamps, Samples, Header] = Nlx2MatCSC(File, FieldSelectionArray, ExtractHeaderValue, ExtractMode, ExtractModeArray);
    %rearray and adjust
    ADBitVolts=str2double(Header{~cellfun('isempty', strfind(Header,'-ADBitVolts '))}(length('-ADBitVolts '):end));
    fs=str2double(Header{~cellfun('isempty', strfind(Header,'-SamplingFrequency '))}(length('-SamplingFrequency '):end));
    Samples=reshape(Samples,1,size(Samples,1)*size(Samples,2)).*ADBitVolts*10^6; % Adjust to microVolt
    TimeStamps=linspace(TimeStamps(1),TimeStamps(end)+511/fs*10^6,length(Samples))/10^3; %adjust to msec; very small errors indtroduced due to imperfect sampling of the neuralynx system (examples tested with ~1 wrong timestamp in 1.5 hour recording leading to 2 ms difference in total duration)
    
elseif ExtractMode==2
    ExtractModeArrayCorr(1)=floor(ExtractModeArray(1)/512);
    ExtractModeArrayCorr(2)=ceil(ExtractModeArray(2)/512);
    [~, Samples, Header] = Nlx2MatCSC(File, FieldSelectionArray, ExtractHeaderValue, ExtractMode, ExtractModeArrayCorr);
    TimeStamps=[];
    %rearray and adjust
    ADBitVolts=str2double(Header{~cellfun('isempty', strfind(Header,'-ADBitVolts '))}(length('-ADBitVolts '):end));
    fs=str2double(Header{~cellfun('isempty', strfind(Header,'-SamplingFrequency '))}(length('-SamplingFrequency '):end));
    Samples=reshape(Samples,1,size(Samples,1)*size(Samples,2)).*ADBitVolts*10^6; % Adjust to microVolt
    
elseif ExtractMode==4
    ExtractModeArrayCorr(1)=(ExtractModeArray(1)-100)*10^3;
    ExtractModeArrayCorr(2)=(ExtractModeArray(2)+100)*10^3;
    [TimeStamps, Samples, Header] = Nlx2MatCSC(File, FieldSelectionArray, ExtractHeaderValue, ExtractMode, ExtractModeArrayCorr);
    %rearray and adjust
    ADBitVolts=str2double(Header{~cellfun('isempty', strfind(Header,'-ADBitVolts '))}(length('-ADBitVolts '):end));
    fs=str2double(Header{~cellfun('isempty', strfind(Header,'-SamplingFrequency '))}(length('-SamplingFrequency '):end));
    Samples=reshape(Samples,1,size(Samples,1)*size(Samples,2)).*ADBitVolts*10^6; % Adjust to microVolt
    TimeStamps=linspace(TimeStamps(1),TimeStamps(end)+511/fs*10^6,length(Samples))/10^3; %adjust to msec; very small errors indtroduced due to imperfect sampling of the neuralynx system (examples tested with ~1 wrong timestamp in 1.5 hour recording leading to 2 ms difference in total duration)
end

%correct for unprecise loading of Nlx2Mat with ExtractModeArray
if ExtractMode==2
    samplecorrect1=ExtractModeArray(1)-ExtractModeArrayCorr(1)*512+1;
    samplecorrect2=length(Samples)-(ExtractModeArrayCorr(2)*512-ExtractModeArray(2))-512;
    Samples=Samples(samplecorrect1:samplecorrect2);
elseif ExtractMode==4
    timecorrect1=find(TimeStamps>=ExtractModeArray(1),1);
    timecorrect2=find(TimeStamps>=ExtractModeArray(2),1);
    TimeStamps=TimeStamps(timecorrect1:timecorrect2);
    Samples=Samples(timecorrect1:timecorrect2);
end

