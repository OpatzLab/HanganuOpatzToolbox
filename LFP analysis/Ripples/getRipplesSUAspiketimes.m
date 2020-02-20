function SUAdata = getRipplesSUAspiketimes(experiment, RespArea, save_data, repeatCalc)
% by Mattia
% get SUA spike times with respect to ripples
% usual inputs

if strcmp(RespArea, 'HP')
    folder2save = 'Q:\Personal\Mattia\SharpProject\results\ripples SUA\';
    folderSUAspiketimes = 'Q:\Personal\Mattia\SharpProject\results\SUA Klusta\';
else
    folder2save = 'Q:\Personal\Mattia\SharpProject\results\PFC ripples SUA\';
    folderSUAspiketimes = 'Q:\Personal\Mattia\SharpProject\results\PFC SUA Klusta\';
end

ripples_results_folder = 'Q:\Personal\Mattia\SharpProject\results\ripples\';

if exist(strcat(folder2save, experiment.animal_ID, '.mat'), 'file') && repeatCalc == 0
    load(strcat(folder2save, experiment.animal_ID))
else
    if exist(strcat(folderSUAspiketimes, experiment.animal_ID, '.mat'), 'file')
        display(['calculating spiketimes for ', experiment.animal_ID])
        load(strcat(folderSUAspiketimes, experiment.animal_ID, '.mat'))        
        if ~ isempty(fieldnames(SUAinfo{1}))
            SUA = SUAinfo{1};
            load(strcat(ripples_results_folder, experiment.animal_ID)) % load info about ripples
            
            for idx = 1 :  size(SUA, 2)
                if ~ isnan(SUA(idx).Timestamps)
                    try
                        spikes(idx, round(SUA(idx).Timestamps / 32)) = 1; % swithc to ms
                    catch
                        SUA(idx).Timestamps(SUA(idx).Timestamps == 0) = 1; % to avoid problems with indexing
                        spikes(idx, ceil(SUA(idx).Timestamps / 32)) = 1; % swithc to ms
                    end
                    channels(idx) = SUA(idx).channel;
                else
                    spikes(idx, :) = 0;
                end
            end
            
            firing_rate = sum(spikes, 2) / length(spikes);
            n_ripples = numel(ripples.peaks); % count number of detected SWRs
            participating_units = zeros(idx, n_ripples);
            ripples_spike_matrix = zeros(n_ripples, idx, 1501); % n_SWR x n_units x time (6s)
            idx = 0;
            ripples_start = ripples.timestamps(:, 1);            
            
            if ~ isempty(ripples_spike_matrix) && n_ripples > 1 % just to check that stuff is not empty
                for ripple = ripples_start'
                    idx = idx + 1;
                    peri_ripple = ripple - 500 : ripple + 1000; % save from 500ms before to 1000ms after
                    peri_ripple = peri_ripple(peri_ripple > 0 & peri_ripple < length(spikes));
                    if ~ isempty(peri_ripple)
                        ripples_spike_matrix(idx, :, peri_ripple(1) - ripple + 501 : ...
                            peri_ripple(1) - ripple + 500 + length(peri_ripple)) = ...
                            spikes(:, peri_ripple);
                        [rows, ~] = find(spikes(:, peri_ripple));
                        participating_units(unique(rows), idx) = 1;
                    end
                end                
                SUAdata.SWRs_spike_matrix = ripples_spike_matrix;
                SUAdata.channels = channels;
                SUAdata.firing_rate = firing_rate;
                SUAdata.participating_units = participating_units;
            else
                SUAdata.SWRs_spike_matrix = [];
                SUAdata.channels = [];
                SUAdata.firing_rate = [];
                SUAdata.participating_units = [];
            end
            if save_data == 0
                disp('DATA NOT SAVED!');
            elseif save_data==1
                save(strcat(folder2save, experiment.animal_ID), 'SUAdata')
            end
        else
            disp(['empty sorted data for animal ' experiment.animal_ID])
            SUAdata.SWRs_spike_matrix = [];
            SUAdata.channels = [];
            SUAdata.OMI = [];
            SUAdata.pvalue = [];
        end
    else
        disp(['no sorted data for animal ' experiment.animal_ID])
        SUAdata.SWRs_spike_matrix = [];
        SUAdata.channels = [];
        SUAdata.OMI = [];
        SUAdata.pvalue = [];
    end
end