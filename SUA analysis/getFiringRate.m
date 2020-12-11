function firing_rate = getFiringRate(animal_name, spike_matrix, repeatCalc, save_data, output_folder)
% by Mattia 08.20
% helper function to compute and save firing rate
% spike matrix is assumed to be in ms

if exist(strcat(output_folder, animal_name, '.mat'), 'file') && repeatCalc == 0
    load(strcat(output_folder, animal_name, '.mat'))
else    
    spike_matrix = full(spike_matrix);
    firing_rate = sum(spike_matrix, 2) / (length(spike_matrix) / 1000);    
    if save_data == 1
        if ~ exist(output_folder, 'dir')
            mkdir(output_folder);
        end
        save(strcat(output_folder, animal_name), 'firing_rate')
    else
        disp('Firing rate not saved!')
    end    
end
end