disp('test example for nt_zapline()');
disp('MEG, epoched data');

clear
fname='../data/example4/data3.mat';

% check for NoiseTools
try, nt_greetings; catch, disp('You must download NoiseNools from http://audition.ens.fr/adc/NoiseTools/'); return; end

% check for data
if ~exist(fname, 'file');
    disp([fname, ' not found'])
    disp('You must download from')
    disp('http://audition.ens.fr/adc/NoiseTools/DATA/data3.mat');
    disp('and adjust paths');
    return
end

% load data
load(fname, 'data', 'sr');
x=data;
x=x(:,:,1:10);

x=nt_demean(x);

% parameters
FLINE=50/sr; % line frequency
NREMOVE=2; % number of components to remove

tic; nt_zapline(x,FLINE,NREMOVE); toc;

set(gcf, 'PaperPositionMode', 'auto');
print ('-dtiff', 'example4.tif');
