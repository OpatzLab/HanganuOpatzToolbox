function [spikePhase] = getPhaseLocking(signalFilt, spikeIndx)
%% By Joachim
% Calculates spike-LFP phaselocking
% dependencies
%     HilbertTransf (Located in Preproccessing)
% Inputs:
%       signalFilt: Filtered signal
%       spike_indx: spikeTimes as index for when they occurred during
%       signal
% Output:
%       spike_phase: vector containing the LFP phase at each spike

% NOTE: This script can be memory heavy if long signal
[~, signal_phase] = HilbertTransf(signalFilt);
spikePhase = signal_phase(spikeIndx);
end