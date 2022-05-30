disp('test example for nt_zapline()');
disp('MEG data with large near-DC fluctuations');

clear
fname='../data/example3/data1.mat';

% check for NoiseTools
try, nt_greetings; catch, disp('You must download NoiseNools from http://audition.ens.fr/adc/NoiseTools/'); return; end

% check for data
if ~exist(fname, 'file');
    disp([fname, ' not found'])
    disp('You must download from')
    disp('http://audition.ens.fr/adc/NoiseTools/DATA/data1.mat');
    disp('and adjust paths');
    return
end

% load data
load(fname, 'data', 'sr');
x=double(data);

x=nt_demean(x);

% parameters
FLINE=60/sr; % line frequency
NREMOVE=2; % number of components to remove

tic; nt_zapline(x,FLINE,NREMOVE); toc;

set(gcf, 'PaperPositionMode', 'auto');
print ('-dtiff', 'example3.tif');
