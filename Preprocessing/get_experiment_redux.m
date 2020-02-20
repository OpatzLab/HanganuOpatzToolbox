function experiments = get_experiment_redux(klusta)
% function creates the selected experiment plus correlated parameters from
% the specified excel file
% input variable optional (vector),  if not defined: all experiments are selected, 
% if defined: selected experiments will be used

if nargin < 1
    klusta = 0;
end

Path = 'YOUR EXCEL FILE HERE';
ExcelSheet = 'InfoandDevMil';
xlRange = 'A1:DZ1000';
[~, ~, InfoandDevMil] = xlsread(Path, ExcelSheet, xlRange); % Import recording summary from excel sheet

[~, idxC_n_experiment] = find(strcmp(InfoandDevMil, 'n_experiment'));
[~, idxC_animalID] = find(strcmp(InfoandDevMil, 'animal_ID'));
[~, idxC_Exp_type] = find(strcmp(InfoandDevMil, 'Exp_type'));
[~, idxC_Alive_recording] = find(strcmp(InfoandDevMil, 'Alive recording'));
[~, idxC_Path] = find(strcmp(InfoandDevMil, 'Path'));
[~, idxC_Age] = find(strcmp(InfoandDevMil, 'Age'));
[~, idxC_IUEconstruct] = find(strcmp(InfoandDevMil, 'construct'));
[~, idxC_IUEarea] = find(strcmp(InfoandDevMil, 'target'));
[~, idxC_IUEage] = find(strcmp(InfoandDevMil, 'age (E)'));
[~, idxC_HPreversal] = find(strcmp(InfoandDevMil, 'HP reversal'));
[~, idxC_ageGroup] = find(strcmp(InfoandDevMil, 'Age Group'));
[~, idxC_ramp] = find(strcmp(InfoandDevMil, 'ramp'));
[~, idxC_baseline] = find(strcmp(InfoandDevMil, 'baseline'));
[~, idxC_PL] = find(strcmp(InfoandDevMil, 'PFC_PL'));
[~, idxC_klusta] = find(strcmp(InfoandDevMil, 'Klusta'));


for row = 6:1000
    if (klusta > 0 && InfoandDevMil{row,  idxC_klusta} == klusta) || klusta == 0
        if isa(InfoandDevMil{row,  idxC_n_experiment}, 'numeric') && ~isnan(InfoandDevMil{row, idxC_n_experiment})
            if isnumeric(InfoandDevMil{row, idxC_animalID})
                InfoandDevMil{row, idxC_animalID}  =  num2str(InfoandDevMil{row, idxC_animalID});
            end
            experiments(InfoandDevMil{row,  idxC_n_experiment}).animal_ID = InfoandDevMil{row,  idxC_animalID};
            experiments(InfoandDevMil{row,  idxC_n_experiment}).Exp_type = InfoandDevMil{row,  idxC_Exp_type};
            experiments(InfoandDevMil{row,  idxC_n_experiment}).name = InfoandDevMil{row,  idxC_Alive_recording};
            experiments(InfoandDevMil{row,  idxC_n_experiment}).path = InfoandDevMil{row,  idxC_Path};
            experiments(InfoandDevMil{row,  idxC_n_experiment}).age = InfoandDevMil{row,  idxC_Age};
            experiments(InfoandDevMil{row,  idxC_n_experiment}).IUEconstruct = InfoandDevMil{row,  idxC_IUEconstruct};
            experiments(InfoandDevMil{row,  idxC_n_experiment}).IUEarea = InfoandDevMil{row,  idxC_IUEarea};
            experiments(InfoandDevMil{row,  idxC_n_experiment}).IUEage = InfoandDevMil{row,  idxC_IUEage};
            experiments(InfoandDevMil{row,  idxC_n_experiment}).AgeGroup = InfoandDevMil{row,  idxC_ageGroup};
            experiments(InfoandDevMil{row,  idxC_n_experiment}).HPreversal = InfoandDevMil{row,  idxC_HPreversal};
            experiments(InfoandDevMil{row,  idxC_n_experiment}).ramp = str2num(InfoandDevMil{row,  idxC_ramp});
            experiments(InfoandDevMil{row,  idxC_n_experiment}).baseline = InfoandDevMil{row,  idxC_baseline};
            experiments(InfoandDevMil{row,  idxC_n_experiment}).PL = InfoandDevMil{row,  idxC_PL};
            experiments(InfoandDevMil{row,  idxC_n_experiment}).Klusta = InfoandDevMil{row,  idxC_klusta};
            try
                experiments(InfoandDevMil{row,  idxC_n_experiment}).PL = str2num(InfoandDevMil{row,  idxC_PL});
            end
            try
                experiments(InfoandDevMil{row,  idxC_n_experiment}).HPreversal = str2num(InfoandDevMil{row,  idxC_HPreversal});
            end
        end
    end
end