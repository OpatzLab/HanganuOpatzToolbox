function spike_matrix = getMUASpikeMatrix(animal_name, ...
    resultsMUA, output_folder, save_data, repeatCalc, area)
% by Mattia 03.21

% computes spike_matrix with 1ms resolution, starting from the output of 
% detected MUA timestamps (e.g. when no SUA is available/needed)

% if you would like to have all your MUA spikes put into the same spike
% matrix, then you should combine the MUA structure that is outputted by
% getMUAspiketimes on a channel-by-channel basis, into one big structure,
% where every entry of the structure corresponds to one channel

% simple example to achieve what I mention here above
% for channel = 1 : 16 % assuming your probe has 16 channels, and you want to combine all of them
%     [timestamps, ~] = getMUAspiketimes(x0,x1,x2,x3);
%     MUA(channel).timestamps = timestamps;
% end
% the MUA that you obtain in this manner can then be fed to this function
% (it is what you should load on the line that has the comment "load the
% saved MUA stuff"

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
        if ~isnan(MUA(channel).timestamps)
            spike_times = ceil(MUA(channel).timestamps / 32); % ceil to avoid having a spike time at 0. round to millisecond
            spike_matrix(channel, spike_times) = 1; % set to 1 if a spike is present in this millisecond
        else
            spike_matrix(channel, 1) = NaN;
        end
    end
    if save_data == 1
        save([output_folder, animal_name, '_', area], 'spike_matrix')
    end
end
end