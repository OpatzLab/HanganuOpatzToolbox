function PRB2folder(probetype, folder2save)

% by Mattia. moves the PRB file in the same file in which the .DAT file
% will be created 

% INPUT:
%   probetype      - as a string. obviously need to add other probes here
%   folder2save    - string, where you also save the .DAT file

% the "PRBfolder" in which you have all the PRB files has to be in a folder
% that is not on the MATLAB path, or you will be negated the permission to
% move the file!

if ~exist(folder2save)
    mkdir(folder2save)
end

PRBfolder = 'Q:\Personal\Mattia\PFCmicro\klusta standard files'; % do not change this

if strcmp(probetype, '4shank')
    copyfile(strcat(PRBfolder, filesep, 'A4x4-100-125.prb'), folder2save)
end
if strcmp(probetype, '16_50m')
    copyfile(strcat(PRBfolder, filesep, 'A1x16-50-703.prb'), folder2save)
end


end