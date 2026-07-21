function fMRIPrep_Anatomy_ConvertVOItoNIfTI_Current
%% Gather basic information needed to begin moving and processing data.
prompt = {'How many VOIs do you want to convert to Nii?','Is the VOI a single region? Or is it a complex VOI? Or is there a folder with multiple VOIs?'};
dlgtitle = 'User Provided VOI Convert Analysis Parameters';
dims = [1 75];
definput = {'','single (1), complex (2), folder with multiple (3)'};
answer = inputdlg(prompt,dlgtitle,dims,definput);

Params.NumberofRegions = answer{1};
Params.VOIType = answer{2};

% get ROI names.
tempprompt = [];
definputexpnames = [];
for expi = 1:str2double(Params.NumberofRegions)
    tempprompt{expi,1} = ['Provide the VOI name'];
    definputexpnames{expi,1} = [''];
end
dlgtitle = 'List VOI Info';
dims = [1 100];
regionprompt = inputdlg(tempprompt,dlgtitle,dims,definputexpnames);

for roi = 1:str2double(Params.NumberofRegions)

    TempRegionName = regionprompt{roi};

    switch Params.VOIType
        case '1'
            uiwait(msgbox({['Please select the single ' regionprompt{roi} ' VOI file.']}));
            % load in VOI file from BV
            [file,path] = uigetfile('*.voi');
            VOI = BVQXfile(fullfile(path,file));
        case '2'
            uiwait(msgbox({['Please select the complex ' regionprompt{roi} ' VOI file.']}));
            % load in VOI file from BV
            %VOI = BVQXfile('*.voi');
            [file,path] = uigetfile('*.voi');
            VOI = BVQXfile(fullfile(path,file));
        case '3'
            if roi == 1
            uiwait(msgbox({['Please select the folder with mutiple ' regionprompt{roi} ' VOI files in it.']}));
            Params.VOI(roi).Folder = uigetdir();
            % find all unique subjects.
            Params.VOI(roi).Directory = dir(fullfile(Params.VOI(roi).Folder,'*sub*'));
            %Params.SubVMPDirectory = SubVMPDirectory;
            else
               Params.VOI(roi).Folder = strrep(Params.VOI(1).Folder,regionprompt{1},regionprompt{roi});
               Params.VOI(roi).Directory = dir(fullfile(Params.VOI(roi).Folder,'*sub*'));
            end
    end
    %
    if roi == 1
        % load in T1 anatomical file from fmriprep
        uiwait(msgbox({'Please select any nii MNI space anatomical file output from fMRIprep'}));
        [file,path] = uigetfile('*.nii',['select your .nii file']);
        V = spm_vol(fullfile(path,file));
        [image,XYZ] = spm_read_vols(V);

        % get output folder.
        uiwait(msgbox({['Please select a folder where you want to save out the converted VOI file']}));
        Params.OutputFolder = uigetdir();
    end

    switch Params.VOIType
        case {'1', '2'}
            for voii = 1:size(VOI.VOI,2)
                % find MNI coords from the VOI file.
                voxels2label = VOI.VOI(voii).Voxels;

                % create new array of zeros.
                newroimap = zeros([size(image,1),size(image,2),size(image,3)]);

                % find the intersection between the MNI coords from VOI and an anatomical
                % image.
                [~,intersectionmap,~] = intersect(XYZ',voxels2label,'rows');

                % give new ROI map a 1 where there are MNI coords from the VOI file.
                newroimap(intersectionmap) = 1;

                % ask for filename and save out ROI map as NIfTI file.
                fileoutname = [VOI.VOI(voii).Name '.nii']; %input('name of ROI file to save out (including .nii)?','s');
                if isfolder(fullfile(Params.OutputFolder,[TempRegionName '_Nii'])) == 0
                    mkdir(fullfile(Params.OutputFolder,[TempRegionName '_Nii']));
                end

                V.fname = fullfile(Params.OutputFolder,[TempRegionName '_Nii'],fileoutname);
                X = spm_write_vol(V,newroimap);

                % clear tmp labels and iterate across ROI files.
                clear newroimap intersectionmap voxels2label
            end
        case '3'
            for subi = 1:size(Params.VOI(roi).Directory,1)
                % find MNI coords from the VOI file.
                VOI = BVQXfile(fullfile(Params.VOI(roi).Directory(subi).folder,Params.VOI(roi).Directory(subi).name));
                for voii = 1:size(VOI.VOI,2)
                    voxels2label = VOI.VOI(voii).Voxels;

                    % create new array of zeros.
                    newroimap = zeros([size(image,1),size(image,2),size(image,3)]);

                    % find the intersection between the MNI coords from VOI and an anatomical
                    % image.
                    [~,intersectionmap,~] = intersect(XYZ',voxels2label,'rows');

                    % give new ROI map a 1 where there are MNI coords from the VOI file.
                    newroimap(intersectionmap) = 1;

                    % ask for filename and save out ROI map as NIfTI file.
                    fileoutname = [Params.VOI(roi).Directory(subi).name '.nii']; %input('name of ROI file to save out (including .nii)?','s');
                    
                    if isfolder(fullfile(Params.OutputFolder,[TempRegionName '_Nii'])) == 0
                        mkdir(fullfile(Params.OutputFolder,[TempRegionName '_Nii']));
                    end

                    V.fname = fullfile(Params.OutputFolder,[TempRegionName '_Nii'],fileoutname);
                    X = spm_write_vol(V,newroimap);

                    % clear tmp labels and iterate across ROI files.
                    clear newroimap intersectionmap voxels2label
                end
            end
    end
end
