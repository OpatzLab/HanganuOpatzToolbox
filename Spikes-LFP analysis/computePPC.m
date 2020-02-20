function PPC = computePPC(phases)
% by Mattia: computes PPC given a vector of phases. It is in vectorized 
% form and therefore not easy to read. For an explanation of
% the computation steps, see Vinck et al (2010)

% INPUT
%   phases :              - vector of phases (in radians)

% OUTPUT
%   PPC :                 - PPC

SpikephasesMatrix = repmat(phases, length(phases), 1);
DotProd = cos(SpikephasesMatrix - SpikephasesMatrix');
DotProd(logical(eye(size(DotProd)))) = 0; 
SumDotProd = sum(sum(DotProd));
PPC = SumDotProd / (length(phases) * (length(phases) - 1));

end
