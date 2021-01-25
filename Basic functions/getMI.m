function [MI, rows] = getMI(values1, values2)
% by Mattia, 09/20
% simple helper function to compute modulation index (normalize "paired" values in the -1 to 1 range)
% inputs: - values1 & 2 -> vector with values to use to compute MI
% output: modulation index for the given values

% important: - if the inputs take negative AND positive values, 
%			   the behavior of the function is erratic (i.e. 
%			   normalization between -1 and 1 fails).
%			 - if the inputs take negative OR positive values, 
%			   the normalization succeeds

% take only real values if input is complex
if ~isreal(values1) || ~isreal(values2)
    values1 = real(values1);
    values2 = real(values2);
end

% compute MI
MI = (values1 - values2) ./ (values1 + values2);
end