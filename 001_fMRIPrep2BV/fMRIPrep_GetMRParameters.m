function [Params] = fMRIPrep_GetMRParameters

homedir = cd;
uiwait(msgbox({'Select the BIDS folder with subject data subfolders'}));
BIDSdirectory = uigetdir;

%% Gather basic information needed to begin moving and processing data.
prompt = {'What is the name of the fMRI experiment to look for in the BIDS folder'};
dlgtitle = 'User Provided (f)MRI Experiment Name';
dims = [1 75];
definput = {''};
expname = inputdlg(prompt,dlgtitle,dims,definput);

% cd to BIDS directory.
cd(BIDSdirectory);
subdir = dir('*sub*')

h = waitbar(0,'reading in subject parameters...');

for subi = 1:size(subdir,1)


    subanatniftijson = dir(fullfile(subdir(subi).folder,subdir(subi).name,'ses-1','anat','*T1w.json'));
    jsonString = fileread(fullfile(subanatniftijson.folder,subanatniftijson.name));
    data = jsondecode(jsonString);

    Params.HeadCoilSize{subi,1} = data.ReceiveCoilName;

    Params.SubID{subi,1} = subdir(subi).name;

    Params.Anat.TR{subi,1} = data.RepetitionTime;
    Params.Anat.TE{subi,1} = data.EchoTime;
    Params.Anat.FlipAngle{subi,1} = data.FlipAngle;
    Params.Anat.Matrix{subi,1} = data.AcquisitionMatrixPE;
    Params.Anat.VoxelSize(subi,1) = data.SliceThickness;

    clear data jsonString subanatnifti subanatniftijson

    % now let's loop through session data to get 
    subfolderloc = fullfile(subdir(subi).folder,subdir(subi).name);
    sessiondir = dir(fullfile(subfolderloc,'ses-*'));
    check = 0;
    for sessioni = 1:size(sessiondir,1)

        subfMRIniftijson = dir(fullfile(subdir(subi).folder,subdir(subi).name, num2str(sessiondir(sessioni).name), 'func',['*' cell2mat(expname) '_run-01_bold.json']));


        if isempty(subfMRIniftijson) ~= 1
            check = 1;
            jsonfMRIString = fileread(fullfile(subfMRIniftijson.folder,subfMRIniftijson.name));

            fMRIdata = jsondecode(jsonfMRIString);

            Params.fMRI.FlipAngle{subi,1} = fMRIdata.FlipAngle;
            Params.fMRI.TR{subi,1} = fMRIdata.RepetitionTime;
            Params.fMRI.TE{subi,1} = fMRIdata.EchoTime;
            Params.fMRI.Matrix{subi,1} = fMRIdata.AcquisitionMatrixPE;
            Params.fMRI.Slices(subi,1) = size(fMRIdata.SliceTiming,1);
            Params.fMRI.VoxelSize(subi,1) = fMRIdata.SliceThickness;

            clear fMRIdata jsonfMRIString subfMRIniftijson

        elseif isempty(subfMRIniftijson) == 1 && check == 0 % else if the directory is empty
            Params.fMRI.FlipAngle{subi,1} = 999;
            Params.fMRI.TR{subi,1} = 999;
            Params.fMRI.TE{subi,1} = 999;
            Params.fMRI.Matrix{subi,1} = 999;
            Params.fMRI.Slices(subi,1) = 999;
            Params.fMRI.VoxelSize(subi,1) = 999;
        end

        h = waitbar(subi/size(subdir,1),h,'reading in subject MR parameters...');
    end
end
cd(homedir);

close all force
