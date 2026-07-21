function fMRIPrep_PreProcess_ConvertToBV
homedir = cd;
%%
prompt = {'Do you want to smooth your data?','Enter the size of the smoothing kernel (in mm):','what size functional voxels do you want (in mm):'};
dlgtitle = 'Smooth Data';
dims = [1 50];
definput = {'Yes (1) or No (0)','MM size (FWHM). Put 0 if you are not smoothing','2 mm is suggested (voxels are 2 mm^3 native).'};
answer = inputdlg(prompt,dlgtitle,dims,definput);
%
smoothdata = str2num(answer{1});
blurkernel = str2num(answer{2});
res = str2num(answer{3});
%% Select folder with func outputs of fMRIprep
disp(['******************' ...
      'Select the func folder output by fmriprep' ...
      '******************']);
pause(5); clc;
funcfolder = uigetdir(homedir);
[parentfolder] = fileparts(funcfolder);
%% CD to parent folder and make BV directory
cd(parentfolder)
mkdir('BV');
BVfolder = fullfile(parentfolder,'BV');
cd(BVfolder)
% Use BV folder to identify the save directory.
savedir = BVfolder(1:strfind(BVfolder,'fmriprep')-1);
% make relevant BV folders
switch smoothdata
case 0
    mkdir(['ProcessedData_Unsmoothed']);
    VTCLoc = fullfile(BVfolder,'/ProcessedData_Unsmoothed');
case 1
    smoothedfoldername = ['ProcessedData_Smoothed_' num2str(blurkernel) 'FWHM'];
    mkdir(['ProcessedData_Smoothed_' num2str(blurkernel) 'FWHM']);
    VTCLoc = fullfile(BVfolder,smoothedfoldername);
end

%
mkdir('VMR')
mkdir('MDM')
mkdir('SDM')
mkdir('PRT')

% link new directories with path location.
%PRTLoc = %fullfile(BVfolder,'/PRT');
disp(['******************' ...
      'Select the folder with PRTs for each run of data' ...
      '******************']);
pause(5); clc;
PRTOrig = uigetdir();
PRTLoc = fullfile(BVfolder,'/PRT');
copyfile(PRTOrig,PRTLoc,'f');
VMRLoc = fullfile(BVfolder,'/VMR');
MDMLoc = fullfile(BVfolder,'/MDM');
SDMLoc = fullfile(BVfolder,'/SDM');
%% Get name of PRT files
cd(PRTLoc)
TmpPRTs = dir('*.prt');
% use this function to search for details about input params.
%tmpprtfile.help('CreateSDM')
% based on experimental features (hard-coded for now) we will need to set
% up the following params prior to creating the fMRI SDM.
params = [];
% length of exp (volumes)
cd(funcfolder);
niftidir = dir('*desc-preproc_bold.nii.gz*');
V = spm_vol(fullfile(funcfolder,niftidir(1).name));
[image,~] = spm_read_vols(V);
params.nvol = size(image,4);
% throw out first condition (0 = no).
params.rcond = 0;
% TR length in ms.
params.prtr = floor(V(1).private.timing.tspace*1000);
clear V image niftidir
% now let's loop through PRTs and output the SDM.
for prti = 1:size(TmpPRTs,1)
    tmpprtfile = BVQXfile(fullfile(PRTLoc,TmpPRTs(prti).name));
    %tmpprtfile.FileVersion = 3; tmpprtfile.ParametricWeights = 1;
    tmpsdm = tmpprtfile.CreateSDM(params);
    fMRISDMStruct.Run(prti).tmpsdm = tmpsdm;
    [~,tmpfilename,~] = fileparts(TmpPRTs(prti).name);
    tmpsdm.SaveAs([tmpfilename '.sdm']);
    movefile([tmpfilename '.sdm'],SDMLoc,'f');
    tmpVTCrunloc = fullfile(VTCLoc, ['Run' num2str(prti)]);
    mkdir(tmpVTCrunloc);
    tmpprtfile.SaveAs(fullfile(tmpVTCrunloc,TmpPRTs(prti).name));
    clear tmpsdm tmpprtfile
end
%% Select folder with anat outputs of fMRIprep
anatfolder = [parentfolder,'/anat'];
cd(anatfolder);
MNIbrain = dir('*MNI152NLin2009cAsym_desc-preproc_T1w.nii.gz*');
copyfile(MNIbrain.name,VMRLoc,'f');
%% CD to func folder to begin.
cd(funcfolder);
% get path to unsmoothed time series data.
rundir = dir('*desc-preproc_bold.nii.gz*');
% get path to TSV file with confounds.
tsvdir = dir('*tsv*');

for runi = 1:size(rundir,1)
    tmpfilename  = []; tmpfilename = rundir(runi).name;
    subID = []; subID = tmpfilename(strfind(tmpfilename,'sub')+4:strfind(tmpfilename,'_')-1);
    taskID = []; taskID = tmpfilename(strfind(tmpfilename,'task-')+5:strfind(tmpfilename,'run-')-2);
    taskID(1) = upper(taskID(1));
    runID = []; runID = tmpfilename(strfind(tmpfilename,'run-')+4:strfind(tmpfilename,'_space')-1);

    tmpVTCrunloc = []; tmpVTCrunloc = fullfile(VTCLoc, ['Run' num2str(runi)]);

    % copy the TSV run file
    copyfile(tsvdir(runi).name,tmpVTCrunloc,'f');
    
    % let's determine whether or not to smooth
    switch smoothdata
        case 0
            %copyfile(rundir(runi).name,tmpVTCrunloc,'f');
            movefile(rundir(runi).name,tmpVTCrunloc,'f');
            %% now that we've copied the files we can work in the BV VTC folder.
            cd(tmpVTCrunloc)
            tmpniftifolder = tmpVTCrunloc;
            fMRIPrep2BV_FG(tmpniftifolder,params,smoothdata,res);
            ! rm *.nii*
            cd(funcfolder);
            opts = []; opts.temp = 1; opts.tempsc = 2; %opts.temphp = 2; 
            nativeVTC = BVQXfile(fullfile(funcfolder,rundir(runi).name));

        case 1
            movefile(rundir(runi).name,tmpVTCrunloc,'f');
            cd(tmpVTCrunloc)
            tmpniftifolder = tmpVTCrunloc;
            fMRIPrep2BV_FG(tmpniftifolder,params,smoothdata,res);
            ! rm *.nii*
            cd(funcfolder);
            % smooth your data using the system call to run AFNI.
            [filepath] = fileparts(pwd); userinfo = strfind(filepath,'User'); 
            slashlocation = strfind(filepath,'/'); afnidirectory = filepath(slashlocation(1):slashlocation(3));
            system([afnidirectory 'abin/3dmerge -1blur_fwhm ' num2str(blurkernel) ' -doall -prefix ' 'Sub-' subID '_task-' taskID '_run-' num2str(runi) '_Smoothed_' num2str(blurkernel) 'MM_FWHM.nii' ' ' rundir(runi).name]);
            tmpsmoothedtimecourse  = []; tmpsmoothedtimecourse = ['Sub-' subID '_task-' taskID '_run-' num2str(runi) '_Smoothed_' num2str(blurkernel) 'MM_FWHM.nii'];
            %copyfile(tmpsmoothedtimecourse,tmpVTCrunloc,'f');
            movefile(tmpsmoothedtimecourse,tmpVTCrunloc,'f');
    end
end
cd(VTCLoc)
rundir = dir('Run*');
%%
for runi = 1:size(rundir,1)
tmprundir = []; tmprundir = rundir(runi).name;
cd(tmprundir);
%% now that we have VTCs let's create single-sub SDMs
runvtcdir = []; runvtcdir = dir('*vtc*');
runtsvdir = []; runtsvdir = dir('*tsv*');

% create MDM that will get saved out.
if runi == 1
MDM = BVQXfile('new:mdm');
MDM.RFX_GLM = 0;
MDM.PSCTransformation = 1;
MDM.zTransformation = 0;
MDM.SeparatePredictors = 0;
MDM.NrOfStudies = size(rundir,1);
end
% link PRT and VTC.
tmpVTC = BVQXfile(runvtcdir.name);
tmpVTC.NameOfLinkedPRT = {TmpPRTs(runi).name};%TmpPRTs(runi).name;
tmpVTC.SaveAs(runvtcdir.name);
%
tmprunconfounds = runtsvdir.name;

%
[~,NameFile,~] = fileparts(runtsvdir.name);

% use this to identify underscores in the TSV file.
%underscoreloc = strfind(NameFile,'_');

% strfind to ID the subject ID.
subID = tmprunconfounds(strfind(NameFile,'sub')+4:strfind(NameFile,'_')-1);

% strfind to ID the session ID
%sessionID = tmprunconfounds(strfind(NameFile,'ses')+4:underscoreloc(2)-1);

% strfind to ID the session ID
%taskID = tmprunconfounds(strfind(NameFile,'task')+5:underscoreloc(3)-1);
taskID = tmprunconfounds(strfind(tmprunconfounds,'task-')+5:strfind(tmprunconfounds,'run-')-2);
taskID(1) = upper(taskID(1));

% strfind to ID the session ID
%runID = tmprunconfounds(strfind(NameFile,'run'):underscoreloc(4)-1);
runID = tmprunconfounds(strfind(tmprunconfounds,'run-')+4:strfind(tmprunconfounds,'_desc')-1);

% create empty runconfound variable
runconfounds = [];

% use tsvread to import tsvfile
[runconfounds,header] = tsvread(tmprunconfounds);

% get raw values
rawconfounds = runconfounds{1, 1};

% get rid of first row, which is header info.
rawconfounds(1,:)= [];

% header info stored here.
headerinfo = runconfounds{1, 2};

% create new variable that is empty.
tmpsdmmatrix = [];

%headervariables = {'trans_x','trans_y','trans_z','rot_x','rot_y','rot_z','dvars','framewise_displacement','cosine00','white_matter','csf'};
headervariables = {'cosine00','trans_x','trans_y','trans_z','rot_x','rot_y','rot_z'}; %,'framewise_displacement','dvars'}; % cosine00
variableorder = [];
counter = 0;
for regressorsi = 1:size(headervariables,2)
    index = []; curregressor = [];
    curregressor = headervariables(regressorsi);
    index = strfind(header,curregressor);
    index = find(~cellfun(@isempty,index));
    %if ~contains('cosine',curregressor) == 1
        for indexi = 1:length(index)
            % if this is not a cosine predictor
            if length(cell2mat(curregressor)) == length(cell2mat(header(index(indexi))))
                counter = counter + 1;
                variableorder.matrixcolumn(counter) = index(indexi);
                variableorder.headername(counter) = header(index(indexi));
            end
        end
    %elseif  contains('cosine',curregressor) == 1
    %   for indexi = 1:length(index)
    %       counter = counter + 1;
    %       variableorder.matrixcolumn(counter) = index(indexi);
    %       variableorder.headername(counter) = header(index(indexi));
    %   end
    %end
end
tmpsdmmatrix = rawconfounds(:,variableorder.matrixcolumn);


% find any NAN values and make them zero. This may be questionable.
tmpsdmmatrix(isnan(tmpsdmmatrix)) = 0;

% add constant of 1 to the end of the SDM matrix.
%tmpsdmmatrix(:,end+1) = 1;

% randomly select colors for conditions in the SDM.
colorconditions = [];
for condi = 1:size(tmpsdmmatrix,2)
    colorconditions(condi,:) = randperm(255,3);
end

% create new SDM file using BVQX tools
TempSDM = BVQXfile('new:sdm');
TempSDM.SDMMatrix = tmpsdmmatrix;
TempSDM.RTCMatrix = [];
TempSDM.IncludesConstant = 0;
%TempSDM.PredictorNames = [{'Translation BV-X [mm]'}  {'Translation BV-Y [mm]'} {'Translation BV-Z [mm]'} {'Rotation BV-X [deg]'} {'Rotation BV-Y [deg]'} {'Rotation BV-Z [deg]'} {'DVARS'} {'FD'}];
TempSDM.PredictorNames = variableorder.headername;
TempSDM.PredictorColors = colorconditions;
TempSDM.NrOfPredictors = size(TempSDM.PredictorColors,1);
%TempSDM.SaveAs([taskID '_Sub' subID '_Run' runID '_SCCTBL_3DMC_FD_DVARS.sdm']);
outputname = [NameFile 'ConfoundRegressors.sdm'];
TempSDM.SaveAs(fullfile(SDMLoc,outputname));

fMRISDM = BVQXfile('new:sdm');
PRTModeledSDM = fMRISDMStruct.Run(runi).tmpsdm;
ConfoundSDM = TempSDM;

fMRISDM.NrOfPredictors = (PRTModeledSDM.NrOfPredictors-PRTModeledSDM.IncludesConstant) + (ConfoundSDM.NrOfPredictors-ConfoundSDM.IncludesConstant) + 1; % plus 1 for constant (vec of 1s).
fMRISDM.NrOfDataPoints = PRTModeledSDM.NrOfDataPoints;
fMRISDM.FirstConfoundPredictor = (PRTModeledSDM.NrOfPredictors-PRTModeledSDM.IncludesConstant) + 1;
fMRISDM.RTCMatrix = PRTModeledSDM.RTCMatrix;
fMRISDM.SDMMatrix = [PRTModeledSDM.RTCMatrix,ConfoundSDM.SDMMatrix];
% add constant.
fMRISDM.SDMMatrix(:,end+1) = 1;
% erase constant from list of predictors in the fMRI SDM.
PRTModeledSDM.PredictorNames(size(PRTModeledSDM.PredictorNames,2)) = [];
fMRISDM.PredictorNames = [PRTModeledSDM.PredictorNames ConfoundSDM.PredictorNames 'Constant'];
fMRISDM.PredictorColors = [PRTModeledSDM.PredictorColors;ConfoundSDM.PredictorColors];
fMRISDM.SaveAs(fullfile(VTCLoc,tmprundir,[taskID '_Sub' subID '_Run' runID '.sdm']));

% need to save out final VTC loc location
[~,subfoldername] = fileparts(VTCLoc);
%
tmpvtcpath = []; tmpvtcpath = fullfile(savedir,'BV',subfoldername,tmprundir,runvtcdir.name);
%tmpvtcpath = fullfile(VTCLoc,tmprundir,runvtcdir.name);
tmpsdmpath = []; tmpsdmpath = fullfile(savedir,'BV',subfoldername,tmprundir,[taskID '_Sub' subID '_Run' runID '.sdm']);
%tmpsdmpath = fullfile(VTCLoc,tmprundir,[taskID '_Sub' subID '_Run' runID '.sdm']);
MDM.XTC_RTC{runi,1} = tmpvtcpath; MDM.XTC_RTC{runi,2} = tmpsdmpath;
cd(VTCLoc)
end

% now save out MDM and we're done.
MDM.SaveAs(fullfile(MDMLoc,[taskID '_Sub' subID '.mdm']));

% cd back to home dir
cd(savedir)
movefile(BVfolder,savedir,'f');
end

%% TSVRead
function [varargout,header] = tsvread( varargin )
%[data, header, raw] = tsvread( file ) reads in text file with tab-seperated variables. default value for data is nan.
%alternative input/output option is suppluying header strings
%[col1, col2, col3, ..., header, raw] = tsvread( file, header1, header2, header3, ... )
%header is the first row (assumed to have header names) and raw is the imported text
%if a vector is supplied, this specifies the number rows to be imported.
%examples:
%[col1, col2,col3,header,raw] = tsvread( 'example.tsv', 'header1', 'header2', 'header3', 1:5 )
%will import data from example.tsv, and cols corresponding to header1,
%header2, header3, cols 1 t0 5.
%if no outputs are requested, then a portion of the rquested table is
%displayed -- good idea to see how the import and header requests are
%working!
%If there is a tsv file in local directory, then just running "tsvread" at
%the command line will read the newest tsv file and display first ten rows to screen.
%sak 9/2/11
if nargin == 0
    disp( 'importing most recent tsv file in local directory' );
    d = dir( '*.tsv' );
    [~,i] = sort( [d.datenum], 'descend' );
    fprintf( 'tsvread( ''%s'', 1:10 )\n', d(i(1)).name );
    eval( sprintf( 'tsvread( ''%s'', 1:10 )', d(i(1)).name ) );
    return;
end;

fid = fopen( varargin{1}, 'r' );
if nargout == 0
    fprintf( 'loading %s, and displaying sideways\n', varargin{1} );
end
varargin(1) = [];
stuff = textscan( fid, '%s', 'delimiter', '\n');
stuff = stuff{1};
fclose(fid);

numrows = 1:size(stuff,1);
ind = cellfun( 'isclass', varargin, 'double' );
if any( ind )
    numrows = varargin{ind};
    varargin(ind) = [];
    if numel(numrows) == 1
        numrows = 1:min(numrows, size( stuff, 1) );
    end
end
numrows = intersect( numrows, 1:size( stuff, 1 ) );
header = regexprep( regexp( stuff{1}, '[^\t]*\t', 'match' ), '\t', '' );
raw = repmat( {}, numel(numrows), numel(header) );
for i=numrows
    stuff{i}(end+1) = 9;
    tmp = regexprep( regexp( stuff{i}, '[^\t]*\t', 'match' ), '\t', '');
    raw(i,1:numel(tmp)) = tmp;
end
header = raw(1,:);
data = nan(size(raw));
for i=numrows
    for j=1:size( raw, 2 )
        if ~isempty( raw{i,j} )
            [a, count, errmsg] = sscanf( raw{i,j}, '%f' );
            if ~isempty( a )
                data(i,j) = a;
            end
        end
    end
end
%%
if numel( varargin ) == 0
    j=1:size(data, 2);
else
    j = [];
    for i=1:numel(varargin)
        j = [j, find( strncmp( header, varargin{i}, numel(varargin{i})) )];
    end
end
if nargout == 0
    disp( [ strvcat( header(j)), num2str( data(numrows,j)' ) ] );
    return;
end
if numel(varargin)==0
    varargout = {data, header, raw};
    varargout = varargout(1:nargout);
    return;
end
varargout = {};
for i=j
    varargout{end+1} = data( :, i );
end
varargout{end+1} = header(:,j);
varargout{end+1} = raw(:,j);
end
%% FMRIPrep2BV
function fMRIPrep2BV_FG(tmpniftifolder,params,smoothdata,res)
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
switch smoothdata
    case 0
        % unsmoothed
        fmridirectory = dir(fullfile(dataFolder,['sub-' subjectID '*desc-preproc_bold.nii.gz']));
    case 1
        % smoothed
        fmridirectory = dir(fullfile(dataFolder,['*Smooth*']));
end


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
        vtc = importvtcfromanalyze({fullfile(fmridirectory(fileIDX).folder,fmridirectory(fileIDX).name)},[],res);
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
    fprintf('saved func file %i \n',fileIDX);
end
end