disp('test example for nt_zapline()');
disp('EEG, resting state data from Trujillo et al doi: 10.3389/fnins.2017.00425');

clear
fname='../data/example2/EEG_Cat_Study4_Resting_S1.bdf';

% check for NoiseTools
try, nt_greetings; catch, disp('You must download NoiseNools from http://audition.ens.fr/adc/NoiseTools/'); return; end

% check for data
if ~exist(fname, 'file');
    disp([fname, ' not found'])
    disp('You must download from')
    disp('https://doi.org/10.18738/T8/ANS9Q1');
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
x=x(:,1:66);

x=nt_demean(x);

% parameters
FLINE=60/sr; % line frequency
NREMOVE=3; % number of components to remove

tic; nt_zapline(x,FLINE,NREMOVE); toc;

set(gcf, 'PaperPositionMode', 'auto');
print ('-dtiff', 'example2.tif');