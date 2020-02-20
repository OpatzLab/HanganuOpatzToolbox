function createBAT(animals, BATfolder, PRMfolder)

% by Mattia. creates the lynux script that you can use to run clustering on
% all your files.

% INPUT:
%   animals      - see main script, you can easily rewrite it with
%                  experiments if this suits better your needs
%   BATfolder    - string, where you will find the BAT file (lynux script)
%   PRMfolder    - string, the main folder in which you store PRM files

% IMPORTANT: change the str2 line to the directory in which you have saved
% THE installation files of Anaconda.

% When this has run, you will find a BAT file that you simply need to
% double click to start the clustering process.

if ~exist(BATfolder)
    mkdir(BATfolder)
end

space = ' '; % MATLAB has some problems in concatenating strings with spaces at the end..

% these lines here below activate the anaconda shell and klusta
str1 = '@echo off';
str2 = 'call C:\Users\mchini\AppData\Local\Continuum\anaconda3\Scripts\activate.bat'; % change this to where you have your Anaconda path
str3 = ['cd', space, PRMfolder];
str4 = 'call activate klusta';

% loop over animals, appending the information about where to find the PRM
% files. The other lines are just linux jergon for waiting until an
% instance is done before starting another one.
for animal_idx = 1 : length(animals)
    
    animal = animals{animal_idx};
    str5 = ['cd', space, animal];
    str6 = 'START /wait klusta klusta.prm';
    str7 = strcat('cd..');
    if animal_idx == 1
        % this creates the BAT file
        BATfile = strcat(BATfolder, animal, '.bat');
        fid = fopen(BATfile, 'wt'); % the BAT file will have the name of the first animal
        fprintf(fid, '%s\n%s\n%s\n%s\n%s\n%s\n%s', ...
            str1, str2, str3, str4, str5, str6); % write strings as char
%         fclose(fid);        
    else
        fprintf(fid, '%s\n%s\n%s\n', ...
            str7, str5, str6); % append to BAT file. no need to rewrite the
                               % first lines.
    end
end
fclose(fid);        
end