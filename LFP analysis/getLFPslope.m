function [slope, intercept] = getLFPslope(power_spectrum, freq, freq4slope, to_plot)
%% Calculate power law decay exponent (1/f slope)

% By Mattia, based on Gao et al., 2017: Inferring synaptic excitation/inhibition balance from field potentials.

% INPUTS:
% power_spectrum: ´      vector of LFP power as e.g. in the output of
%                        pWelchSpectrum
% freq:                  frequency vector corresponding to the power
%                        spectrum (has to have the same length)
% freq4slope:            frequencies at which to calculate the 1/f slope.
%                        In Gao et al., 30-50Hz and 40-60Hz are used.
%                        Ideally, it should be a portion of the power
%                        spectrum in which there are no bona-fide
%                        oscillations (the power spectrum is flat on the
%                        log-log scale). Input Example [30 50]
% to_plot:               to visually inspect the fit (1=yes, 0 or no input = no)

% OUTPUT:
% slope:                 power law decay exponent (1/f slope)
% intercept:             intercept of the fit. See Haller et al., 2018 on
%                        why this could be interesting (Parameterizing
%                        Neural Power Spectra)

if nargin < 4
    to_plot = 0;
end

% take the indeces to keep for fit
idx2keep = find(freq > freq4slope(1) & freq < freq4slope(2));
% take the log of both power spectrum and frequency vector
power_spectrum = log10(power_spectrum(idx2keep));
freq = log10(freq(idx2keep));
fit = robustfit(freq, power_spectrum);
slope = fit(2);
intercept = fit(1);

if to_plot > 0
    figure; hold on
    plot(freq, power_spectrum, 'linewidth', 3, 'DisplayName', 'input data')
    plot(freq, intercept + slope * freq, 'linewidth', 3, 'DisplayName', 'fit')
    ylabel('Log10 of frequency'); xlabel('Log10 of LFP power');
    set(gca, 'TickDir', 'out'); set(gca, 'FontSize', 12); set(gca, 'FontName', 'Arial')
    legend
end

end