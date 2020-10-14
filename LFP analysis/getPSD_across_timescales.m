function [PSD, PSD_slow, PSD_fast, freqs, freqs_slow, freqs_fast, time_slow, time_fast] = ...
    getPSD_across_timescales(LFP, fs, freq2analyze, slow_freqs, fast_freqs, folder2save, animal_name, save_data)
% from Mattia 06.20
% compute power spectra:
% 1. down to very low frequencies using multitapers of different length, 
% adjusting it to freq range and averaging over windows
% 2 & 3, without averaging over windows but with single window length.
% These are nice because you have a direct way to look at how power changes
% over time (since all the windows have the same length).
% IMPORTANT: for 2 & 3, for most applications it is better to take the
%            median instead of the mean across windows. It might seem
%            trivial, but it often has important effects. See for instance
%            "Measuring the average power of neural oscillations" 
%            (Izhikevich et al., 2018).

% input:    - LFP: channels x time
%                  keep the sampling rate low to save time!
%           - fs: sampling rate of LFP signal
%           - freq2analyze: frequencies to analyze (generally log spaced)
%                           ex: logspace(-2, log10(50), 20). these are the
%                           ones for multi-taper analysis
%           - slow_freqs: single window power, for slow frequencies
%           - fast_freqs: single window power, for fast frequencies
%           - folder2save: where to save stuff
%           - animal_name: string, for name of saved file
%           - save_data: 1=true, 0=false
% output:   - PSDstruct with the following fields: 
%               - PSD: multitaper PSD (channels * freqs)
%               - PSD_fast: single window PSD (window * freqs * channels)
%               - PSD_slow: single window PSD (window * freqs * channels)
%               - freqs: freqs relative to PSD
%               - freqs_fast: freqs relative to PSD_fast
%               - freqs_slow: freqs relative to PSD_slow
%               - time_fast: time at which windows of PSD_fast occurred
%               - time_slow: time at which windows of PSD_slow occurred


% Dependencies : Chronux Toolbox

% set sampling freq
params.Fs = fs;

% initialize two cells for PSD and frequencies
PSD = [];
freqs = [];

%%%%%%%%%% first compute for windows of different lengths %%%%%%%%%%

% compute PSD using chronux toolbox looping over freq bands
for freq_idx = 1 : length(freq2analyze) - 1
    % set freq band to analyze
    params.fpass = [freq2analyze(freq_idx) freq2analyze(freq_idx + 1)];
    % set window length as 10 times the slowest frequency
    window(1) = 1 / freq2analyze(freq_idx) * 10;
    % set window overlap as half window length
    window(2) = window(1) / 2;
    % actually compute the PSD
    [PSD_freq, ~, freqs_freq] = mtspecgramc(LFP', window, params);
    % average and concatenate
    PSD = cat(1, PSD, squeeze(nanmedian(PSD_freq)));
    freqs = cat(2, freqs, freqs_freq);
end

% transpose PSD to have it in a more usual format
PSD = PSD';


%%%%%%%%%% now compute for slow frequencies %%%%%%%%%%

% set freq band to analyze
params.fpass = slow_freqs;
params.pad = 0;
% make it a bit shorter or won't have enough points to correlate
window(1) = 1 / slow_freqs(1) * 4;
window(2) = window(1) / 2;
[PSD_slow, time_slow, freqs_slow] = mtspecgramc(LFP', window, params);


%%%%%%%%%% now compute for fast frequencies %%%%%%%%%%

% set freq band to analyze
params.fpass = fast_freqs;
window(1) = 1 / fast_freqs(1) * 10;
window(2) = window(1) / 2;
[PSD_fast, time_fast, freqs_fast] = mtspecgramc(LFP', window, params);

% put everything into a structure
PSDstruct.PSD = PSD;
PSDstruct.PSD_fast = PSD_fast;
PSDstruct.PSD_slow = PSD_slow;
PSDstruct.freqs = freqs;
PSDstruct.freqs_fast = freqs_fast;
PSDstruct.freqs_slow = freqs_slow;
PSDstruct.time_fast = time_fast;
PSDstruct.time_slow = time_slow;


if save_data == 1
    if ~ exist(folder2save, 'dir')
        mkdir(folder2save)
    end
    save(strcat(strcat(folder2save, animal_name)), 'PSDstruct')
end

end