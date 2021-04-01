function spike_matrix = getMUASpikeMatrix(animal_name, ...
    resultsMUA, output_folder, save_data, repeatCalc, area)
% by Mattia 03.21

% computes spike_matrix starting from the output of detected MUA
% timestamps (where no SUA is available)

% input:  animal_name (string, also known as animal_ID)
%         resultsMUA (string, folder in which you have detected MUA)
%         save_data (1 for yes)
%         repeatCalc (0 to load already computed stuff)
%         output_folder (string, where to save the spike matrix)
% output: spike_matrix

if repeatCalc == 0 && exist([output_folder, animal_name, '_', area, '.mat'], 'file')
    load([output_folder, animal_name, '_', area, '.mat'])
else
    load([resultsMUA, animal_name, '_', area]) % load the saved MUA stuff
    for channel = 1 : length(MUA) % loop over single units
        spike_times = ceil(MUA(channel).timestamps / 32); % ceil to avoid having a spike time at 0. round to millisecond
        spike_matrix(channel, spike_times) = 1; % set to 1 if a spike is present in this millisecond
    end
    if save_data == 1
        save([output_folder, animal_name, '_', area], 'spike_matrix')
    end
end
end