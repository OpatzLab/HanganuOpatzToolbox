function [Xcorr, XcorrGH, PosPvalues, NegPvalues, num_pairs] = ...
    computeXcorrHGonly(animal_name, spike_matrix, autocorr, max_lag, repeat_calc, save_data, output_folder)
%% By Mattia 01.02.19
% computes cross-correlograms (CCH) and their "significance" values
% as in English et al., 2017.
% requires spike matrices from which to compute the CCHs.
% standard maxLag is 30ms

% define the hollowed gaussian window
HG = gausswin(101, 99 / 20); % gaussian window of 100ms with stdev of 10ms as in English et al 2017
HG((end + 1) / 2) = HG((end + 1) / 2) * 0.4; % partially hollow the window as explained in Stark and Abeles 2009
HG = HG / sum(HG); % normalize the partially hollowed gaussian kernel



if exist(strcat(output_folder, animal_name, '_', num2str(max_lag), 'ms_Xcorr.mat')) && repeat_calc == 0
    load(strcat(output_folder, animal_name, '_', num2str(max_lag), 'ms_Xcorr.mat'))
else
    if size(spike_matrix, 1) > 1
        Xcorr = fastXcorr(spike_matrix, max_lag, autocorr);
    else
        Xcorr = [];
    end
    if save_data == 1
        if ~ exist(output_folder)
            mkdir(output_folder);
        end
        save(strcat(output_folder, animal_name, '_', num2str(max_lag), 'ms_Xcorr.mat'), 'Xcorr')
    else
        disp('Xcorr not saved!')
    end
end

if exist(strcat(output_folder, animal_name, '_', num2str(max_lag), 'ms_surrogates.mat')) && repeat_calc == 0
    load(strcat(output_folder, animal_name, '_', num2str(max_lag), 'ms_surrogates.mat'))
    XcorrGH = surrogates.XcorrGH;
    PosPvalues = surrogates.PosPvalues;
    NegPvalues =  surrogates.NegPvalues;
    try
        Pcausal =  surrogates.Pcausal;
    catch
        Pcausal =  NaN(size(PosPvalues, 1), 1);
    end
    num_pairs = size(XcorrGH, 1);
else
    if numel(spike_matrix) > 0
        disp(strcat('calculating surrogates for animal_', num2str(animal_name)))
        NegPvalues = zeros(size(Xcorr));
        XcorrGH = zeros(size(Xcorr));
        
        halfXcorr = ceil(size(Xcorr, 2) / 2);
        Pcausal = zeros(size(Xcorr, 1), halfXcorr - 1);

        for ST_idx = 1 : size(Xcorr, 1) % ST = spike train
            XcorrGH(ST_idx, :) = conv(Xcorr(ST_idx, :), HG, 'same'); % convolve with hollowed gaussian
            matrixX = zeros(max(Xcorr(ST_idx, :)) - 1, size(Xcorr(ST_idx, :), 2)); % initialize matrix of "x" values
            % as defined in English et al., 2017
            % briefly: x values here are the number of observed "coincident" spikes in
            % the cross correlogram histogram (CCH) that will be used to compute the
            % probability (pvalue) of observing that number of spikes x, given a
            % certain surrogate, that in our case is the CCH convolved with a hollowed
            % gaussian window. creating this matrix of "x" values (matrixX) allows us to
            % factorize the computation and save decades of computational time.
            % basically, it allows us to compute the summation from x=0 to x=n-1
            % without a loop.
            % matrixX has the same number of columns as the CCH. the number of rows
            % is equal to the maximum number of observed spikes in the CCH - 1 (the
            % n-1) of the summation. the entries of matrixX are equal to n-1 if that
            % particular column has a maximum number of spikes that is equal to the row
            % value, otherwise it is set to NaN. This is because we would not go there
            % with the summation, given that x only goes until n-1. We still fill the
            % entry with a NaN so that we can factorize its computation. However, we
            % then have to factorize this matrix, and given that the factorize
            % function of matlab cannot handle NaN, we create a matrix (matrixfactorial) that is equal to
            % this one, but in which we replace NaN with 0s. This is because 0! is 1,
            % and this matrix divides another matrix, so dividing for a bunch of 1s does
            % not affect the result. We can not to the same for matrixX because this
            % matrix, on the other hand, will go through a subtraction.
            
            for row_idx = 1 : size(matrixX, 1)
                matrixX(row_idx, :) = Xcorr(ST_idx, :) - ...
                    (size(matrixX, 1) - row_idx) - 1; % fill the matrix with n-1
            end
            matrixX(matrixX <= 0) = NaN; % as explained above, if n-1 is < 0, replace with NaN
            matrixX = flipud(matrixX);
            matrixfactorial = matrixX;
            matrixfactorial(isnan(matrixfactorial)) = 0; % create matrix that can be factorized
            secondTerm = - 0.5 * (exp(- XcorrGH(ST_idx, :)) .* XcorrGH(ST_idx, :) .^ ...
                (Xcorr(ST_idx, :))) ./ factorial(Xcorr(ST_idx, :)); 
            % just a random variable name. it's the second term of
            % the equation of English et al., 2017
            firstTerm = nansum((exp(- XcorrGH(ST_idx, :)) .* XcorrGH(ST_idx, :) ... % first term
                .^ matrixX) ./ factorial(matrixfactorial), 1);
            % as above
            NegPvalues(ST_idx, :) = firstTerm + secondTerm; % pvalues of observing a peak < than in CCH. not present
            % in English et al., 2017 but it is a logical corollary
            
            % the following part is actually correctly coded but not
            % currently in use since this parameter has weird non-linear
            % effects when the number of spikes is low (as pretty much
            % always in neonatal conditions - WORKS FOR ADULT DATA THOUGH!)
            
%             secondTermCausal = - 0.5 * (exp(- flip(Xcorr(ST_idx, 1 : halfXcorr - 1))) .* ...
%                 flip(Xcorr(ST_idx, 1 : halfXcorr - 1)) .^ (Xcorr(ST_idx, halfXcorr + 1 : end))) ...
%                 ./ factorial(Xcorr(ST_idx, halfXcorr + 1 : end)); 
%             % just a random variable name. it's the second term of the
%             % "causal" equation of English et al., 2017
%             firstTermCausal = nansum((exp(- flip(Xcorr(ST_idx, 1 : halfXcorr - 1))) .* ...
%                 flip(Xcorr(ST_idx, 1 : halfXcorr - 1)) .^ matrixX(:, halfXcorr + 1 : end)) ...
%                 ./ factorial(matrixfactorial(:, halfXcorr + 1 : end)), 1);
%             % as above
%             Pcausal(ST_idx, :) = 1 - firstTermCausal + secondTermCausal;
        end
        PosPvalues = 1 - NegPvalues; % pvalues of observing a peak > than in CCH, as in English et al., 2017
        num_pairs = size(XcorrGH, 1);
    else
        XcorrGH = [];
        PosPvalues = [];
        NegPvalues = [];
        num_pairs = 0;
%         Pcausal = [];
    end
    if save_data == 1
        
        surrogates.XcorrGH = XcorrGH;
        surrogates.PosPvalues = PosPvalues;
        surrogates.NegPvalues = NegPvalues;
%         surrogates.Pcausal = Pcausal;
        
        if ~ exist(output_folder)
            mkdir(output_folder);
        end
        save(strcat(output_folder, animal_name, '_', num2str(max_lag), 'ms_surrogates.mat'), 'surrogates')
    else
        disp('Xcorr surrogates not saved!')
    end
end

end
