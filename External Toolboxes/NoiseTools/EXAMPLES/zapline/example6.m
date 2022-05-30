disp('test example for nt_zapline()');
disp('MEG, 5 line noise components');

clear
fname='../data/example6/fig_9_data.mat';

% check for NoiseTools
try, nt_greetings; catch, disp('You must download NoiseNools from http://audition.ens.fr/adc/NoiseTools/'); return; end

% check for data
if ~exist(fname, 'file');
    disp([fname, ' not found'])
    disp('You must download from')
    disp('http://audition.ens.fr/adc/NoiseTools/DATA/figures_deCheveigne_Arzounian_2018/fig_9_data.mat');
    disp('and adjust paths');
    return
end

% load data
load(fname, 'x', 'sr');

x=nt_demean(x);

% parameters
FLINE=50/sr; % line frequency
NREMOVE=1; % number of components to remove

tic; nt_zapline(x,FLINE,NREMOVE); toc;

set(gcf, 'PaperPositionMode', 'auto');
print ('-dtiff', 'example6.tif');
