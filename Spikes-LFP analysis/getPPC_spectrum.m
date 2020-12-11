function PPC = getPPC_spectrum(animal_name, folder4Klusta, LFP, filters, fs, save_data, repeatCalc, output_folder)
% by Mattia 10/20
% computes PPC starting from LFP (CAR or not) and output of Klusta. PPC is
% computed with respect to the LFP of the same channel where the spike is
% detected.
% this script is thought to compute baseline PPC, wherein the LFP that is
% fed only consists of baseline activity, and the spikes that occur after
% that are deleted

if exist(strcat(output_folder, animal_name, '.mat'), 'file') && repeatCalc == 0
    load(strcat(output_folder, animal_name, '.mat'))
else
    % load sua info
    load(strcat(folder4Klusta, animal_name, '/SUAinfo')) % load the saved SUA stuff
    SUAinfo = SUAinfo{1};
    % initialize PPC
    PPC = NaN(size(SUAinfo, 2), 1);
    % extract channels where units are detected (PPC is computed on the LFP
    % of that channel)
    channels = extractfield(SUAinfo, 'channel');
    % normalize channels to be in the 1 to 16 range
    % this is a quick fix that works only if there are max 32 channels in
    % the recording
    if max(channels) > 16
        channels = channels - 16;
    end
    % loop over channels where at least one unit is detected
    for channel = channels
        units_ch = find(channels == channel);
        % loop over the different frequency bands
        for filt = 1 : numel(filters) - 1
            signal_filtered = ZeroPhaseFilter(LFP(channel, :), fs, [filters(filt) filters(filt + 1)]);
            % loop over the unit of that channel
            for unit = units_ch
                % extract spike times
                spikes = round(SUAinfo(unit).Timestamps / (32000 / fs));
                % only take baseline spikes
                spikes(spikes > size(LFP, 2)) = [];
                % extract phases
                SignalPhase = angle(hilbert(signal_filtered));
                SpikePhases = SignalPhase(spikes);
                % compute PPC
                PPC(unit, filt) = getPPC(SpikePhases);
            end
        end
    end
    % save stuff      
    if save_data == 1
        if ~ exist(output_folder, 'dir')
            mkdir(output_folder);
        end
        save(strcat(output_folder, animal_name), 'PPC')    
    end   
end
end