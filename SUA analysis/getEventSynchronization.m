function ES = getEventSynchronization(animal_name, spike_matrix, maxLag, repeatCalc, save_data, output_folder)
% as in Quian Quiroga et al., 2002

if exist(strcat(output_folder, animal_name, '.mat'), 'file') && repeatCalc == 0
    load(strcat(output_folder, animal_name, '.mat'))
else
    
    % get full matrix
    spike_matrix = full(spike_matrix);
    % extract spike times
    [rows, cols] = find(spike_matrix);
    % initialize matrix
    ESsym = zeros(size(spike_matrix, 1));
    ESasym = zeros(size(spike_matrix, 1));
    
    for unit1 = 1 : size(spike_matrix, 1)
        % get spike time of single unit
        spike_times1 = cols(rows == unit1);
        parfor unit2 = unit1 + 1 : size(spike_matrix, 1)
            % get spike time of single unit
            spike_times2 = cols(rows == unit2);
            J1 = 0; J2 = 0;
            for idx = 1 : numel(spike_times1)
                difference = spike_times2 - spike_times1(idx);
                J1 = J1 + ...
                    nnz(difference > 0 & difference < maxLag) + ...
                    0.5 * nnz(difference == 0);
                J2 = J2 + ...
                    nnz(difference < 0 & difference > - maxLag) + ...
                    0.5 * nnz(difference == 0);
            end
            ESsym(unit1, unit2) = (J1 + J2) / (numel(spike_times1) * numel(spike_times2));
            ESasym(unit1, unit2) = (J1 - J2) / (numel(spike_times1) * numel(spike_times2));
        end
    end
    % fix lower half of the matrix
    ESsym = ESsym + ESsym';
    ESasym = ESasym - ESasym';
    
    % save stuff
    if save_data == 1
        ES.ESsym = ESsym;
        ES.ESasym = ESasym;
        if ~ exist(output_folder, 'dir')
            mkdir(output_folder);
        end
        save(strcat(output_folder, animal_name), 'ES')
    else
        disp('ES not saved!')
    end
end

end