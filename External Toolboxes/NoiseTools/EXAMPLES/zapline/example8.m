disp('test example for nt_zapline()');
disp('MEG, 5 line noise components');

clear
fname='../data/example8/data_plosone_EEG/data_EEG/sujet01/2008-10-27_LENA_0001.eeg';

% check for NoiseTools
try, nt_greetings; catch, disp('You must download NoiseNools from http://audition.ens.fr/adc/NoiseTools/'); return; end

% check for data
if ~exist(fname, 'file');
    disp([fname, ' not found'])
    disp('You must download from')
    disp('https://datadryad.org/resource/doi:10.5061/dryad.v9f16');
    disp('and adjust paths');
    return
end

% check for FieldTrip
try, ft_version; catch, disp('You must download FieldTrip from http://www.fieldtriptoolbox.org'); return; end

% load data
h=ft_read_header(fname);
sr=h.Fs;
x=ft_read_data(fname);
x=x';
x=x(1:100000,:);

x=nt_demean(x);

% parameters
FLINE=50/sr; % line frequency
NREMOVE=4; % number of components to remove

tic; nt_zapline(x,FLINE,NREMOVE); toc;


set(gcf, 'PaperPositionMode', 'auto');
print ('-dtiff', 'example8.tif');