function fMRIPrep2BV_FG(tmpniftifolder,params,res,smoothdata)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%-------------------------------FMRIPREP2BV-------------------------------%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  ______________________________________________________________________
% |                                                                      |%
% |                                                                      |%
% |                           Example script                             |%
% |                                V0.1                                  |%
% |______________________________________________________________________|%
%
%
% Info
%
%
% Requirements:
% - Neuroelf v1.1 in matpab path (https://neuroelf.net/)
%

%clear, clc

% A set of neuroelf functions from its private folder
% This includes importvtcfromanalyze()
%addpath('func-neuroelf')

%% Settings
% Processed data folder 
%dataFolder = '/Users/fgarcea/Desktop/Test/OutputDir/derivatives/fmriprep/sub-10054/func';
%dataFolder = uigetdir;
dataFolder = tmpniftifolder;

% Subject ID
%subjectID = '10041';
%subjectID = tmpniftifolder(strfind(tmpniftifolder,'sub-'):strfind(tmpniftifolder,'/BV')-1)
% sub ID without the 'sub' -- e.g., 'sub-008' becomes '008'
slashloc = strfind(tmpniftifolder,'/');
subloc = strfind(tmpniftifolder,'sub');
slashvalue = min(slashloc(find(slashloc>subloc)));

% subloc + 4 is the first character of sub ID after 'sub-'
% slash value minus 1 is the last character of sub ID
subjectID = tmpniftifolder(subloc+4:slashvalue-1);
%tmpniftifolder(strfind(tmpniftifolder,'sub-')+4:strfind(tmpniftifolder,'/BV')-1);

%numeric version of subject ID
%subjectID = str2num(subjectIDstr);
%subjectID = tmpniftifolder(regexp(tmpniftifolder,'sub')+4:regexp(tmpniftifolder,'sub')+8);

% Reference Space
% 3 - TAL, 4 - MNI
rSpace = 4;

% Resolution time (in milliseconds)
tr = params.prtr;

% Spatial Resolution (units are anat image voxels)
% Example:
% anat image with 1x1x1 mm, func image with 2x2x2 mm --> res = 2
% anat image with 1x1x1 mm, func image with 3x3x3 mm --> res = 3
res = 2;

%% Do it

% Find files in dataFolder
%smoothdata = 2;
switch smoothdata
    case 0
    % unsmoothed
    D = dir(fullfile(dataFolder,['sub-' subjectID '*desc-preproc_bold.nii.gz']));
    case 1
    % smoothed
    D = dir(fullfile(dataFolder,['*Smooth*']));
end
%D = dir(fullfile(dataFolder,['sub-' subjectID '*desc-preproc_bold.nii.gz']));
%D = dir(fullfile(dataFolder,['sub-' subjectID '*scale.nii']));
%D = tmpniftifile;

% Iterate on the func files
for fileIDX = 1:length(D)

    % Load VTC
    vtc = importvtcfromanalyze({fullfile(D(fileIDX).folder,D(fileIDX).name)},[],res);

    % Change reference space
    vtc.ReferenceSpace = rSpace;
    
    % Change TR
    vtc.TR = tr;
    
    % Find run id
    aux = strsplit(D(fileIDX).name,'_');
    
    % Add .prt (needs to be in the same folder of the func)
    vtc.NameOfLinkedPRT = 'protocol-example.prt'; 

    % Save VTC
    removeextension = strfind(D(fileIDX).name,'.nii');
    vtc.SaveAs(fullfile(dataFolder,[D(fileIDX).name(1:removeextension) 'vtc']));
    
    % Close VTC
    vtc.ClearObject;

    % Print
    fprintf('saved func file %i \n',fileIDX);
    
end
