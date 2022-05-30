disp('test example for nt_zapline()');
disp('MEG, 5 line noise components');

clear
fname='../data/example5/example_data.mat';

% check for NoiseTools
try, nt_greetings; catch, disp('You must download NoiseNools from http://audition.ens.fr/adc/NoiseTools/'); return; end

% check for data
if ~exist(fname, 'file');
    disp([fname, ' not found'])
    disp('You must download from')
    disp('http://audition.ens.fr/adc/NoiseTools/DATA/example_data.mat');
    disp('and adjust paths');
    return
end

% load data
load(fname, 'meg', 'sr');
x=meg;
x=x(:,:,1);

x=nt_demean(x);

% parameters
FLINE=50/sr; % line frequency
NREMOVE=6; % number of components to remove

% this helps slightly for this dataset:
p.nkeep=50; % reduce dimensionality before DSS to avoid overfitting

tic; nt_zapline(x,FLINE,NREMOVE,p); toc;

set(gcf, 'PaperPositionMode', 'auto');
print ('-dtiff', 'example5.tif');