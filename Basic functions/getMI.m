function [MI, rows] = getMI(values1, values2, negative)
% by Mattia, 09/20
% simple helper function to compute modulation index
% inputs: - values1 & 2 -> vector with values to use to compute MI
%         - negatives   -> 1 to take out negative values, 0 not to do it
% output: modulation index for the given values

% take only real values if input is complex
if ~isreal(values1) || ~isreal(values2)
    values1 = real(values1);
    values2 = real(values2);
end
% take out mismatch between positive & negatives if it's needed
if negative > 0
    all_values = cat(2, values1, values2);
    % find negative values
    [rows, ~] = find(all_values < 0);
    % count how many times per row the value is negative (this is because
    % if both are negative, than you can keep that row)
    count = histcounts(rows, 1 : size(all_values, 1));
    % find rows where there is one negative (and the other is positive)
    to_delete = find(count == 1);
    values1(to_delete) = NaN;
    values2(to_delete) = NaN;
end
% compute MI
MI = (values1 - values2) ./ (values1 + values2);
end