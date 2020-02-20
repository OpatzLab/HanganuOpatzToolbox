function PRM2folder(animal, DATfolder_animal, PRMfolder)

if ~ exist(PRMfolder)
    mkdir(PRMfolder)
end

filePattern = fullfile(DATfolder_animal, '*.dat');
DATfiles = dir(filePattern);

filePattern = fullfile(DATfolder_animal, '*.prb');
PRBfile = dir(filePattern);


str1 = strcat('experiment_name = ''', animal, '''');
str2 = strcat('prb_file = ''', DATfolder_animal, '/', PRBfile.name, '''');
str3 = 'traces = dict(';
str5 = '    sample_rate = 32000,';
str6 = '    n_channels = 16,';
str7 = '    dtype = ''int16'',';
str8 = ')';
str9 = 'spikedetekt = dict(';
str9bis = '    threshold_strong_std_factor = 6,';
str10 = '    threshold_weak_std_factor = 4.5,';
str11 = ')';
str12 = 'klustakwik2 = dict(';
str13 = '    num_starting_clusters = 100,';
str14 = ')';

stringDAT = '    raw_data_files=[';

% note that since the PRM will be open in python the folders have to be
% separated by a forward slash (/) and not a backslash (\)
for idxDAT = 1 : numel(DATfiles)
    stringDAT = strcat(stringDAT, '''', DATfolder_animal, '/', DATfiles(idxDAT).name, ''',');
end
stringDAT = strcat(stringDAT, '],');

str4 = stringDAT;

fid = fopen(strcat(PRMfolder, filesep, 'klusta.prm'), 'wt');
fprintf(fid, '%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s', ...
    str1, str2, str3, str4, str5, str6, str7, str8, str9, str9bis, str10, ...
    str11, str12, str13, str14);
fclose(fid);

end