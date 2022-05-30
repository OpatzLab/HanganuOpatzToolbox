% Example of line noise removal using ZapLine toolbox. 
%
% de Cheveigné, A. (2020). ZapLine: A simple and effective method to remove 
% power line artifacts. NeuroImage, 207, 116356.
%
% IMPORTANT NOTE: LFP must contain more than 1 channel.

clear
clc

% load data
% zapline wants 2d array m_timepoints x n_channels 
fname='put_here_path_to\\your_lfp_file.mat';
lfp = load(fname);
x = lfp.lfp.'; % transpose if needed 

fs = 1000; % data sampling frequency, Hz 
line_f = 50; % line noise frequency, Hz

% zapline parameters
fline=line_f/fs; % line moise frequency
nremove=2; % number of components to remove

x = nt_demean(x);
tic; yy = nt_zapline(x,fline,nremove); toc;

%tic; nt_zapline(x,fline,nremove); toc; % uncomment that if you want
%zapline figure output

% save results
lfp_denoised = yy.';
save('put_here_path_to\\output_file.mat', 'lfp_denoised');
