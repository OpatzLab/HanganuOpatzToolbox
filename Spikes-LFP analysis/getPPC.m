function [PPC]=getPPC(Spikephases)
% by Mattia
% input
% SpikePhases - vector of phases, with respect
% to the frequency band of interest

SpikephasesMatrix=repmat(Spikephases,length(Spikephases),1);
DotProd=cos(SpikephasesMatrix-SpikephasesMatrix');
DotProd(logical(eye(size(DotProd))))=0; 
SumDotProd=sum(sum(DotProd));
PPC=SumDotProd/(length(Spikephases)*(length(Spikephases)-1));

end