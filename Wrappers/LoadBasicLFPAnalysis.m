
%% load experiment info and set a few variables for analysis

clear
% load experiments and generic stuff
experiments = 'your function to load experiments';
repeatCalc = 0;
save_data = 1;

% folders where you saved various results
folder4osc = 'your_folder_here';
folder4PSD = 'your_folder_here';
folder4STTC = 'your_folder_here';
folder4firing = 'your_folder_here';
folder4ES = 'your_folder_here';
folder4Coh = 'your_folder_here';
folder4PPC = 'your_folder_here';

% initialize variables
condition = NaN(size(experiments, 2), 1);
condSUA = [];
time_in_osc = condition;
num_osc = condition; 
IOI = condition; 
duration = condition;
amplitude = condition;
weight = condition;
age = condition;
% you might have to change the 2nd dimension of the initialized variables
% here, if your PSDs were computed with a different number of points
Power = NaN(numel(experiments), 152);
PowerSlow = NaN(numel(experiments), 2615); 
PowerFast = NaN(numel(experiments), 502);

%% load results that you previously computed

for exp_idx = 1 : size(experiments, 2)
    
    % select experiment
    experiment = experiments(exp_idx);
    % load condition & weight & age
    condition(exp_idx) = strcmp(experiment.Exp_type, 'WT');
    weight(exp_idx) = experiment.weight;
    age(exp_idx) = experiment.age;
    % load oscillation properties
    load(strcat(folder4osc, experiment.animal_ID));
    % extract osc timestamps
    timestamps = extractfield(oscillations, 'timestamps');
    % if you don't have len_rec (edited in the last version of
    % getOscillations), the length of the recording shouldn't too hard to
    % compute anyway
    time_in_osc(exp_idx) = sum(oscillations.durations) ./ oscillations.len_rec;
    % compute number of oscillations / min
    num_osc(exp_idx) = size(oscillations.durations, 1) / (max(timestamps) / (60*1000));
    % compute inter-osc-interval
    IOI(exp_idx) = nanmedian(oscillations.timestamps(2 : end, 1) - ...
        oscillations.timestamps(1 : end - 1, 2));
    duration(exp_idx) = nanmedian(oscillations.durations);
    amplitude(animal_idx) = nanmedian(oscillations.peakAbsPower);
    % load PSD
    load(strcat(folder4PSD, experiment.animal_ID));
    Power(exp_idx, :) = nanmedian(PSDstruct.PSD);
    PowerSlow(exp_idx, :) = nanmedian(nanmedian(PSDstruct.PSD_slow), 3);
    PowerFast(exp_idx, :) = nanmedian(nanmedian(PSDstruct.PSD_fast), 3);
end
    
%% plot a few things

% this script is plotting the various parameters as a function of
% "condition". if your data does not have such a variable, but you rather
% plot as a function of age or weight, just replace the two variables

% create nice colormap
YlGnBu = cbrewer('seq', 'YlGnBu', 100); 
% extract number of conditions
num_cond = nnz(unique(condition));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%% plot osc properties %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% plot time in active periods as a function of condition
figure; violinplot(time_in_osc, condition)
title('Time in active periods')
xlabel('Condition'); ylabel('Proportion of active periods')
xticklabels({'Cond0', 'Cond1'})
set(gca, 'FontSize', 14); set(gca, 'FontName', 'Arial');
% plot number of active periods as a function of condition
figure; violinplot(num_osc, condition)
title('Number of active periods')
xlabel('Condition'); ylabel('Number of active periods')
xticklabels({'Cond0', 'Cond1'})
set(gca, 'FontSize', 14); set(gca, 'FontName', 'Arial');
% plot log of duration as a function of condition
figure; violinplot(log10(duration), condition)
title('Duration of active periods')
xlabel('Condition'); ylabel('Log of Duration')
xticklabels({'Cond0', 'Cond1'})
set(gca, 'FontSize', 14); set(gca, 'FontName', 'Arial');
% plot amplitude of active periods as a function of condition
figure; violinplot(amplitude, condition)
title('Amplitude of active periods')
xlabel('Condition'); ylabel('Amplitude (microV)')
xticklabels({'Cond0', 'Cond1'})
set(gca, 'FontSize', 14); set(gca, 'FontName', 'Arial');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% plot power stuff %%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% these PSd plots plot the mean of the PSDs across conditions and the
% standard error of the mean using "boundedline"

% overall power
figure; hold on
for cond_idx = 1 : num_cond
    cond2plot = condition(cond_idx);
    boundedline(PSDstruct.freqs, nanmedian(Power(condition == cond_idx, :)), ...
        std(Power(condition == cond_idx, :)) ./ sqrt(nnz(condition == cond_idx)), ...
    'cmap', YlGnBu(round(100 / (num_cond + 1) * cond_idx), :))
end
% put everything on a log-scale (better for visualizazion)
set(gca, 'YScale', 'log'); set(gca, 'XScale', 'log')
% set title and labels
title('Baseline power spectrum'); ylabel('Power (microV)'); xlabel('Frequency (Hz)')
set(gca, 'TickDir', 'out'); set(gca, 'FontSize', 14); set(gca, 'FontName', 'Arial')

% fast frequencies
figure; hold on
for cond_idx = 1 : num_cond
    cond2plot = condition(cond_idx);
    boundedline(PSDstruct.freqs_fast, nanmedian(PowerFast(condition == cond_idx, :)), ...
        std(PowerFast(condition == cond_idx, :)) ./ sqrt(nnz(condition == cond_idx)), ...
    'cmap', YlGnBu(round(100 / (num_cond + 1) * cond_idx), :))
end
% put everything on a log-scale (better for visualizazion)
set(gca, 'YScale', 'log'); set(gca, 'XScale', 'log')
% set title and labels
title('Baseline power spectrum'); ylabel('Power (microV)'); xlabel('Frequency (Hz)')
set(gca, 'TickDir', 'out'); set(gca, 'FontSize', 14); set(gca, 'FontName', 'Arial')

% slow frequencies
figure; hold on
for cond_idx = 1 : num_cond
    cond2plot = condition(cond_idx);
    boundedline(PSDstruct.freqs_slow, nanmedian(PowerSlow(condition == cond_idx, :)), ...
        std(PowerSlow(condition == cond_idx, :)) ./ sqrt(nnz(condition == cond_idx)), ...
    'cmap', YlGnBu(round(100 / (num_cond + 1) * cond_idx), :))
end
% put everything on a log-scale (better for visualizazion)
set(gca, 'YScale', 'log'); set(gca, 'XScale', 'log')
% set title and labels
title('Baseline power spectrum'); ylabel('Power (microV)'); xlabel('Frequency (Hz)')
set(gca, 'TickDir', 'out'); set(gca, 'FontSize', 14); set(gca, 'FontName', 'Arial')
