function [Params] = fMRIPrep_PreProcess_ConvertToBV_Current
%% This script was written by Frank Garcea (2022-04-12).
% Contact frank_garcea@urmc.rochester.edu if you have issues or find a bug.
%% The first assumption is that the CD is set to the home directory.
% This script will move the outputs of fMRIprep into a new folder for 
% analysis in BrainVoyager. There are several key assumptions that must be
% met for this script to work. You must keep the folder structure as such..
% /TAFPProject/BIDSData/derivativeswf
% 'TAFPProject' is the home directory that houses all of your project info.
% 'BIDSData' is the parent folder that houses your BIDS validated data.
% 'derivatives' within the BIDSData folder is where fMRIprep outputs live.
% If your data aren't organized in this way the script will not work.
%try
% directories containing useful code for analysis & plotting
%addpath(genpath([root_directory 'spm12']));
%addpath(genpath([root_directory 'GarceaLab/fMRIPrep']));

% This is the homedirectory variable that will be used for future calls.
Params.HomeDirectory = pwd;

%% Gather basic information needed to begin moving and processing data.
prompt = {'Enter the subject IDs that you want to analyze.','Move anatomical (T1w) files?','Move functional (fMRI) files?','Create VTCs?', 'Move PRTs?', 'Create SDMs?','Create MDMs?','Create GLMs?'};
dlgtitle = 'User Provided (f)MRI Analysis Parameters';
dims = [1 75];
definput = {'E.g., 1, 3, 5, 8, or 1:15,22,45:50','Yes (1) or No (0)','Yes (1) or No (0)','Yes (1) or No (0)','Yes (1) or No (0)','Yes (1) or No (0)','Yes (1) or No (0)','Yes (1) or No (0)'};
answer = inputdlg(prompt,dlgtitle,dims,definput);

% Basic experimental parameters that will route future analysis.
Params.Subs2process = str2num(answer{1});
Params.MoveAnat = str2double(answer{2});
Params.MoveFunc = str2double(answer{3});
Params.CreateVTC = str2double(answer{4});
Params.MovePRT = str2double(answer{5});
Params.CreateSDM = str2double(answer{6});
Params.CreateMDM = str2double(answer{7});
Params.CreateGLM = str2double(answer{8});
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% LETS GO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Let's get user-provided info about anatomical files before we start.
if Params.MoveAnat == 1 || Params.MoveFunc == 1 || Params.CreateVTC == 1
anatprompt = {'Is the T1w anatomy in normal space (MNI; Tal) or native space?'};
anatinput = {'Normal Space (1), Native Space (2), or Pediatric Space (3)'};
dlgtitle = 'Anatomical Parameters';
dims = [1 75];
anatanswer = inputdlg(anatprompt,dlgtitle,dims,anatinput);
Params.Anatomyspace = str2double(anatanswer);
end

% Move Functional Data to Processed Data Folder.
if Params.MoveFunc
[Params] = fMRIPrep_PreProcess_MoveFunctional(Params);
end

% Move Anatomical Data to Processed Data Folder.
if Params.MoveAnat
[Params] = fMRIPrep_PreProcess_MoveAnatomy(Params);
end        

% Create VTCs in Processed Data Folder.
if Params.CreateVTC
[Params] = fMRIPrep_PreProcess_CreateVTC(Params);
end

% Move PRTs to the Processed Data Folder.
if Params.MovePRT
[Params] = fMRIPrep_PreProcess_MovePRT(Params);
end

% Create SDMs in VTC Data Folder.
if Params.CreateSDM
[Params] = fMRIPrep_PreProcess_CreateSDM(Params);
end

% Create MDMs.
if Params.CreateMDM
[Params] = fMRIPrep_PreProcess_CreateMDM(Params);
end

% Create GLMs.
%if Params.CreateGLM
%[Params] = fMRIPrep_PreProcess_CreateGLM(Params);
%end
% go back home.
clc
cd(Params.HomeDirectory);

%catch
%    cd(Params.HomeDirectory);
%end