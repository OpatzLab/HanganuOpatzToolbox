function CoherenceStuff = ...
    getCoherence(LFP1, LFP2, fs, win_length, overlap, nfft, ...
    folder2save, animal_name, repeatCalc, save_data)

% calculates Coherency and Coherence as in Nolte et al., 2004
% by Mattia, 01/21, adapted from a script of Joachim and Sebastian

% inputs:       - signal & 2: two signal between which you want to compute
%                             coherence and coherency
%               - fs : sampling frequency of the signals
%               - window_length : length of the window for coherence
%                                 calculation (in seconds)
%               - overlap : window overlap (in seconds)
%               - nfft: number of points for fft (better if a power of 2)
%               - folder2save: string - where to save results
%               - animal_name: string - to name the result file
%               - repeatCalc: binary
%               - save_data: binary
% output:       - coherence: contains 0-lag coherence
%               - coherency: coherence without 0-lag coherence
%               - coherence shuffled: coherence on shuffled data
%               - coherency shuffled: coherency on shuffled data


if repeatCalc == 0 && exist(strcat(folder2save, animal_name, '.mat'), 'file')
    load(strcat(folder2save, animal_name))
else
    % compute number of windows
    nWindows = floor(length(LFP1) / (fs * win_length));
    
    % cut the two signals to fit window length
    LFP1 = LFP1(1 : nWindows * win_length * fs);
    LFP2 = LFP2(1 : nWindows * win_length * fs);
    
    % create a shuffled version of one of the two signals
    signal_shuffled = reshape(LFP2, fs * win_length, nWindows);
    signal_shuffled = reshape(signal_shuffled(:, randperm(nWindows)), 1, []);
    
    % compute coherence and coherency on the two signals & on the shuffled one
    [Coherence, Coherency, freqs] = ...
        computeCoherence(LFP1, LFP2, win_length * fs, overlap * fs, nfft, fs);
    [CohShuff, CohyShuff, ~] = ...
        computeCoherence(LFP1, signal_shuffled, win_length * fs, overlap * fs, nfft, fs);
    
    % put stuff in a structure
    CoherenceStuff.Coherence = Coherence;
    CoherenceStuff.Coherency = Coherency;
    CoherenceStuff.freqs = freqs;
    CoherenceStuff.CohShuff = CohShuff;
    CoherenceStuff.CohyShuff = CohyShuff;
    
    % save everything
    if save_data == 1
        if ~ exist(folder2save, 'dir')
            mkdir(folder2save)
        end
        save(strcat(strcat(folder2save, animal_name)), 'CoherenceStuff')
    end
end
end

%% helper function that computes coherence
function [Coherence, Coherency, freqs] = ...
    computeCoherence(signal_1, signal_2, window_length, overlap, nfft, fs)
	% calculate psd and cpsd (cross power spectral density)
	[PSD1, ~] = pwelch(signal_1, hanning(window_length), overlap, nfft, fs);
	[PSD2, ~] = pwelch(signal_2, hanning(window_length), overlap, nfft, fs);
	[CPSD, freqs] = cpsd(signal_1, signal_2, hanning(window_length), overlap, nfft, fs);
	% compute coherence and coherency
	Coherence = CPSD ./ sqrt(PSD1 .* PSD2);
	Coherency = abs(imag(Coherence));
end