disp('test example for nt_zapline()');
disp('FieldTrip example data: Monkey ECoG');

clear
fname='../DATA/example1/data.mat';

% check for NoiseTools
try, nt_greetings; catch, disp('You must download NoiseNools from http://audition.ens.fr/adc/NoiseTools/'); return; end

% check for data
if ~exist(fname, 'file');
    disp([fname, ' not found']);
    disp('Download from ')
    disp('ftp://ftp.fieldtriptoolbox.org/pub/fieldtrip/tutorial/monkey_ecog/data.mat');
    disp('and adjust paths');
    return
end

% load data
load(fname, 'data_1');
sr=data_1.fsample;
x=data_1.trial{1}';

% apply nt_zapline
FLINE=50/sr; % line frequency
NREMOVE=4; % number of components to remove
tic; nt_zapline(x,FLINE,NREMOVE); toc;

set(gcf, 'PaperPositionMode', 'auto');
print ('-dtiff', 'example1.tif');
