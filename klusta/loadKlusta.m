function [SUAinfo, features] = loadKlusta(animal, PRMfolder, DATfolder, save_data, directory2save)
% by Mattia 25/01

filenamekwik = strcat(PRMfolder, animal, filesep, animal, '.kwik'); % name kwik file
filenamekwx = strcat(PRMfolder, animal, filesep, animal, '.kwx'); % name kwix file

TimeStamps = double(hdf5read(filenamekwik, '/channel_groups/0/spikes/time_samples')); % timestamps for all detected spikes
RecordingBreaks = find(diff(TimeStamps) < 0); % only useful if you have more than one recording per animal
Clusters = hdf5read(filenamekwik, '/channel_groups/0/spikes/clusters/main'); % assign a cluster to every spike
FeatureMask = hdf5read(filenamekwx, '/channel_groups/0/features_masks'); % load the three features on every channel for every spike

filePattern = fullfile(DATfolder, '*.dat');
DATfiles = dir(filePattern);

for DATfile_idx = 1 : numel(DATfiles)
    
    DATfile = DATfiles(DATfile_idx).name;
    gwfparams.file = strcat(DATfolder, filesep, DATfile);                                 % path to your DAT file
    gwfparams.fileName = DATfile;                                                         % DAT file name
    gwfparams.dataType = 'int16';                                                         % Data type of .dat file (there should be no need ot change this)
    gwfparams.nCh = 16;                                                                   % Number of channels that were clustered
    gwfparams.wfWin = [-119 120];                                                           % Number of samples before and after spiketime to include in waveform
    gwfparams.nWf = 500;                                                                  % Number of waveforms per unit to pull out
    if DATfile_idx == 1
        if numel(RecordingBreaks) > 0
            gwfparams.spikeTimes = TimeStamps(1 : RecordingBreaks(DATfile_idx));              % Vector of cluster spike times (in samples) same length as .spikeClusters
            gwfparams.spikeClusters = Clusters(1 : RecordingBreaks(DATfile_idx));             % Vector of cluster IDs (Phy nomenclature) same length as .spikeTimes 
        else
            gwfparams.spikeTimes = TimeStamps;             
            gwfparams.spikeClusters = Clusters;            
        end
    elseif DATfile_idx == numel(DATfiles)
        gwfparams.spikeTimes = TimeStamps(RecordingBreaks(DATfile_idx - 1)...
            : end);
        gwfparams.spikeClusters = Clusters(RecordingBreaks(DATfile_idx - 1)...
            : end);
    else
        gwfparams.spikeTimes = TimeStamps(RecordingBreaks(DATfile_idx - 1)...
            : RecordingBreaks(DATfile_idx));
        gwfparams.spikeClusters = Clusters(RecordingBreaks(DATfile_idx - 1)...
            : RecordingBreaks(DATfile_idx));
    end
        
    WaveForms = getWaveForms(gwfparams);                                                  % function from CortexLab extracting Waveforms for each cluster                                                                         
    WaveForms.waveFormsMean = WaveForms.waveFormsMean - mean(WaveForms.waveFormsMean, 3); % zero-center the mean Waveforms
    SUA = struct;
    countSUA = 0;
    fs = 32000;
    refractory_period = fs * 2 * 10 ^-3; % two ms in timestamps
    
    for idxCluster = 1 : length(WaveForms.unitIDs) % loop over clusters
    
        ClusterType = hdf5read(filenamekwik, strcat( '/channel_groups/0/clusters/main/',  ...
            num2str(WaveForms.unitIDs(idxCluster)), '/cluster_group')); % 0 for noise, 1 for MUA and 2 for SUA

        if ClusterType == 2 % if SUA

            countSUA = countSUA + 1;
            [~, SUA(countSUA).channel] = min(min(WaveForms.waveFormsMean(idxCluster, :, :), [], 3)); % channel is the one with biggest negativity
                                                                                                     % in the average mask
            SUA(countSUA).Timestamps = gwfparams.spikeTimes(gwfparams.spikeClusters == ...
                WaveForms.unitIDs(idxCluster));                                                      % timestamps when spike occurs
            SUA(countSUA).ClusterID = WaveForms.unitIDs(idxCluster);                                 % to check stuff in phy, you never know
            SUA(countSUA).Waveform = squeeze(WaveForms.waveFormsMean(idxCluster, ...
                SUA(countSUA).channel, :));                                                          % for further analysis, i.e. distinguishing PYR and IN
            SUA(countSUA).Amplitudes = squeeze(FeatureMask(1, SUA(countSUA).channel * 3 - 1, ...
                Clusters == WaveForms.unitIDs(idxCluster)));                                         % the second feature, on the best channel (see above). for cluster quality assesment
            SUA(countSUA).RPV = nnz(diff(gwfparams.spikeTimes) < refractory_period);                 % refractory period violations. for cluster quality assesment
            SUA(countSUA).MeanWaveFeatures = getSpikeFeatures(SUA(countSUA).Waveform);               % for SUA clustering
            features(countSUA, :) = SUA(countSUA).MeanWaveFeatures;
            SUA(countSUA).file = strip(strip(strip(strip(DATfile, 'right', 't'), ...
                'right', 'a'), 'right', 'd'), 'right', '.');
        end


    end
    
    SUAinfo{DATfile_idx} = SUA;
end


if save_data == 1
    if ~exist(directory2save)
        mkdir(directory2save)
    end
    save(strcat(directory2save, filesep, animal), 'SUAinfo')
end