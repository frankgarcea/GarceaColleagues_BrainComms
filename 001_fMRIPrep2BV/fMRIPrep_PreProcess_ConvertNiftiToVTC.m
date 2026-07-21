function fMRIPrep_PreProcess_ConvertNiftiToVTC(tmpniftifolder,params,res)
% Requirements:
% - Neuroelf v1.1 in matpab path (https://neuroelf.net/)

%% Settings
% Processed data folder
dataFolder = tmpniftifolder;

% Subject ID
% sub ID without the 'sub' -- e.g., 'sub-008' becomes '008'
slashloc = strfind(tmpniftifolder,'/');
subloc = strfind(tmpniftifolder,'sub');
slashvalue = min(slashloc(find(slashloc>subloc)));

% subloc + 4 is the first character of sub ID after 'sub-'
% slash value minus 1 is the last character of sub ID
subjectID = tmpniftifolder(subloc+4:slashvalue-1);

% Reference Space
% 3 - TAL, 4 - MNI
rSpace = 4;

% Resolution time (in milliseconds)
tr = params.prtr;

% Spatial Resolution (units are anat image voxels)
% Example:
% anat image with 1x1x1 mm, func image with 2x2x2 mm --> res = 2
% anat image with 1x1x1 mm, func image with 3x3x3 mm --> res = 3
%res = 2;

% Find files in dataFolder
%smoothdata = 2;
fmridirectory = [];
%switch smoothdata
%    case 0
        % unsmoothed
        fmridirectory = dir(fullfile(dataFolder,['sub-' subjectID '*desc-preproc_bold.nii.gz']));
%    case 1
        % smoothed
%        fmridirectory = dir(fullfile(dataFolder,['*Smooth*']));
%end


% Iterate on the func files
for fileIDX = 1:length(fmridirectory)

    % Load VTC
    %if res == 3
    %    bbox = [57, 52, 59; 231, 172, 197];
        % this bbox will give you voxel sizes in the same format/size as the
        % default BV size (58x40x46).
        % Y Z X are the dimensions.
     %   vtc = importvtcfromanalyze({fullfile(fmridirectory(fileIDX).folder,fmridirectory(fileIDX).name)},bbox,res);
    %else
    % default BBox
    %params.BBox = [57, 52, 59; 231, 172, 197];
    
    % adjusted Bbox for MNI space.
    %params.BBox = [54    44    55; 236   181   201];
    
    vtc = importvtcfromanalyze({fullfile(fmridirectory(fileIDX).folder,fmridirectory(fileIDX).name)},[],res);
    %vtc = importvtcfromanalyze({fullfile(fmridirectory(fileIDX).folder,fmridirectory(fileIDX).name)},params.BBox,res);
    %end
    
  
    % Change reference space
    vtc.ReferenceSpace = rSpace;

    % Change TR
    vtc.TR = tr;

    % Find run id
    aux = strsplit(fmridirectory(fileIDX).name,'_');

    % Add .prt (needs to be in the same folder of the func)
    vtc.NameOfLinkedPRT = 'protocol-example.prt';

    % Save VTC
    removeextension = strfind(fmridirectory(fileIDX).name,'.nii');
    vtc.SaveAs(fullfile(dataFolder,[fmridirectory(fileIDX).name(1:removeextension) 'vtc']));

    % Close VTC
    vtc.ClearObject;

    % Print
    %fprintf('saved func file %i \n',fileIDX);
end
end