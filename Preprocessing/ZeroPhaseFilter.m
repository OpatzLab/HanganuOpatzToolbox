%% By Joachim Ahlbeck <3 (Adapted from Nicole Cichon <3<3) and improved by Kay Sieben and Samuel Reincke <3<3<3
function recording_filtered=ZeroPhaseFilter(recording_unfiltered,samplingrate,cutFrequencies)
%% Filter signal using filtfilt
% frequency = [low_cut high_cut]
% zp2sos is necessary if user is working with 3 outputs [b, a, k] instead
% of 2 outputs as it was common "before"
% for correct usage of butter outputs please look into "limitations" of help 
% for this function, ask Kay or Samuel for further questions...
    if length(cutFrequencies) ~= 2;
        disp('ZeroPhasefilter: ERROR! Wrong input for low/high cut')
    else
        low_cut     = cutFrequencies(1);
        high_cut    = cutFrequencies(2);
            if low_cut == 0;
                n                   = 3; 
                Wn                  = [high_cut]/(0.5*samplingrate);
                [b,a,k]             = butter(n,Wn,'low');
                [sos,g]             = zp2sos(b,a,k);
                recording_filtered  = (filtfilt(sos,g,recording_unfiltered));    
            elseif high_cut == 0;
                n                   = 3; 
                Wn                  = [low_cut]/(0.5*samplingrate);
                [b,a,k]             = butter(n,Wn,'high');
                [sos,g]             = zp2sos(b,a,k);
                recording_filtered  = (filtfilt(sos,g,recording_unfiltered)); 
            else
                n                   = 3;
                Wn                  = [low_cut high_cut]/(0.5*samplingrate);
                [b,a,k]             = butter(n,Wn);
                [sos,g]             = zp2sos(b,a,k);
                recording_filtered  = (filtfilt(sos,g,recording_unfiltered));
            end
    end
end