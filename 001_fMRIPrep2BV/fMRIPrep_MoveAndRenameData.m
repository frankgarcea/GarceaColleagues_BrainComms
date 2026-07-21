function [Params] = fMRIPrep_MoveAndRenameData

% This is the homedirectory variable that will be used for future calls.
Params.HomeDirectory = pwd;

%% Gather basic information needed to begin moving and processing data.
prompt = {'Enter the subject IDs that you want to analyze.','Move and rename anatomical (T1w) files?','Move and rename functional (fMRI) files?'};
dlgtitle = 'User Provided (f)MRI Analysis Parameters';
dims = [1 75];
definput = {'E.g., 1, 3, 5, 8, or 1:15,22,45:50','Yes (1) or No (0)','Yes (1) or No (0)'};
answer = inputdlg(prompt,dlgtitle,dims,definput);


% Basic experimental parameters that will route future analysis.
Params.Subs2process = str2num(answer{1});
Params.MoveAnat = str2double(answer{2});
Params.MoveFunc = str2double(answer{3});


%% Let's get user-provided info about anatomical files before we start.
if Params.MoveAnat == 1 || Params.MoveFunc == 1 || Params.CreateVTC == 1
anatprompt = {'Is the T1w anatomy in normal space (MNI; Tal) or native space?'};
anatinput = {'Normal Space (1) or Native Space (2)'};
dlgtitle = 'Anatomical Parameters';
dims = [1 75];
anatanswer = inputdlg(anatprompt,dlgtitle,dims,anatinput);
Params.Anatomyspace = str2double(anatanswer);
end

% Move functional Data to new processed data folder.
if Params.MoveFunc
[Params] = fMRIPrep_PostProcess_Move_Rename_FuncData(Params);
end

% Move anatomical Data to new processed data folder.
if Params.MoveAnat
[Params] = fMRIPrep_PostProcess_Move_Rename_AnatData(Params);
end        

% go back home
cd(Params.HomeDirectory)
