function PPC = getPPC_PLV(LFP, MUA, fs, fsMUA, bands, threshold)
% by Mattia: compute Pairwise Phase Consistency (PPC) and Phase Locking Value (PLV)
%            read Vinck et al. (2010) for why PPC is preferrable over PLV
%
% input:
%       LFP :                    entire signal
%       MUA :                    not downsampled!
%       fs :                     sampling frequency for LFP
%       fsMUA :                  sampling frequency for MUA (should be ~ 32000)
%       threshold :              for spike detection, for example 5
%       bands :                  LFP frquency bands at which you want to
%                                calculate calculate the PPC, for example
%                                [4 12; 12 30; 30 48; 52 100]

% output:
%      PPC :                     PPC (1 x length(bands) vector)
%      PLV :                     structure with: 
%                                                   - details : spike phases for the specific frequency band
%                                                   - p: p value of Rayleigh test
%                                                   - phase_rad: mean phase in radians
%                                                   - rvl: mean vector length (a measure of the "locking strength")

% dependencies:
%      peakfinder function : should already be in the toolbox, otherwise go to https://goo.gl/pFzMPo
%      computePPC : should already be in the toolbox
%% 

downsampling_factor = fsMUA / fs; % get scaling factor for MUA timepoints -> LFP timepoints
recordingMUA = ZeroPhaseFilter(MUA, 32000, [500 5000]); % filter MUA using standard frequency band
thr = std(recordingMUA) * threshold; % calculate threshold for 
[SpikeTimestamps, ~] = peakfinderOpto(recordingMUA, thr / 2, -thr, -1, false); % find spike timestamps
clearvars recordingMUA MUA % clear heavy variables that are not useful anymore
SpikeTimestamps = round(SpikeTimestamps / downsampling_factor); % scale spike timestamps from fsMUA to fs
SpikeTimestamps(SpikeTimestamps == 0) = 1; 

num_bands = length(bands) - 1; % calculate number of frequency bands
PPC = zeros(1, num_bands); % initialize variable

for band_idx = 1 : num_bands
    
    band = [bands(band_idx) bands(band_idx + 1)]; % define frequency band
    Signal_filtered = ZeroPhaseFilter(LFP, fs, band); % filter signal
    Signal_phase = angle(hilbert(Signal_filtered)); % calculate phase of the signal with hilbert
    Spikephases = Signal_phase(SpikeTimestamps); % extract phases of spikes 
    
    if numel(Spikephases) > 30 % set a minimum amount of required spikes
        
        PPC(band_idx) = computePPC(Spikephases); % compute PPC
        
        PLV.details{band_idx, 1} = Spikephases; % collect spike phase for the specific frequency band
        PLV.p{band_idx, 1} = circ_rtest(Spikephases'); % Rayleigh test, small p indicates departure from uniformity
        PLV.phase_rad{band_idx, 1} = circ_mean(Spikephases'); % mean resultant vector/preferred phase
        PLV.rvl{band_idx, 1} = circ_r(Spikephases'); % resultant vector length/Spike_Phase
        
    else
        
        PPC(band_idx, 1) = NaN;
        PLV.p(band_idx, 1) = NaN;
        PLV.details(band_idx, 1) = NaN;
        PLV.phase_rad(band_idx, 1) = NaN;
        PLV.rvl(band_idx, 1) = NaN;
    end
    
end

end