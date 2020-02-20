function nlx2DAT(animal, experiments, channels, folder2save)

% by Mattia 8.11.18 based on https://github.com/kwikteam/klusta/issues/48

% Convert .nlx files to .dat:
% - Estimate chunksize for the data (max allowed by memory)
% - Copy data from server to local disk
% - Write data to binary files
% - Remove copied data

%INPUT:
%   experiment      - as in the standard ROSA format, but generally just needs
%                     to have a .path (main folder for recordings) and a
%                     .name .name (name of the specific folder) attribute.
%                     You can also easily modify it to whatever else you prefer.
%   channels        - channels to include
%   fname           - output file name
%   folder2save     - output folder where the .dat file will be saved
%
%OUTPUT:
% .dat file in folder2save
%

% memsize = memory; % for memory mapping the files

% create output directory if it does not already exists
if ~ exist(folder2save, 'file')
    mkdir(folder2save);
end

% Define the maximum number of int16 storage entries (so that you don't
% exceed your RAM capacity)
% nints = round((memsize.MaxPossibleArrayBytes / 6) * 0.95);

% find all the experiments for the animal that you want to spike sort
experiments_animal = structfind(experiments, 'animal_ID', animal); 

% loop over the experiments
for experiment = experiments(experiments_animal)
    
%     disp(strcat('writing_experiment_', experiment.name))
    % load first file just to calculate the number of block in which you want
    % to partition your recording
    ExtractMode = 1;
    file_to_load = strcat(experiment.path, experiment.name, filesep, 'CSC', num2str(channels(1)), '.ncs');
    [~, temp, ~] = load_nlx_Modes(file_to_load, ExtractMode, []);
    clength = length(temp);
%     nintsdata = 2 * clength * numel(channels);
%     
%     % Partition size of data
%     nBlocks = ceil(nintsdata / nints);
%     blocksize = round(nints / numel(channels));
    
    % Create output file
    fname = experiment.name;
    fidout = fopen(fullfile(folder2save, sprintf('%s.dat', fname)), 'w');
    clear temp
    
    
    %% write data
    
%     fprintf('Saving block 000/000 -ch00')
%     for blockNR = 1 : nBlocks
        
        % Index for chunk
%         IDX(1) = (blockNR - 1) * blocksize + 1;
%         IDX(2) = blockNR * blocksize;
        
%         if IDX(2) > clength && blockNR == 1
%             IDX(2) = clength;
%         end
        
%         samples = zeros(length(channels), IDX(2) - IDX(1) + 1, 'int16');
        samples = zeros(length(channels), clength, 'int16');
%         fprintf('\t-ch01');
        for channel_idx = 1 : length(channels)
%             fprintf('\b\b%2d', channel_idx);
            file_to_load = strcat(experiment.path, experiment.name, filesep, 'CSC', ...
                num2str(channels(channel_idx)), '.ncs');
            [~, samples(channel_idx, :), ~] = load_nlx_Modes(file_to_load, ExtractMode, []);
        end
        
        fwrite(fidout, samples, 'int16');
        
%     end
    fclose(fidout);
end
end
