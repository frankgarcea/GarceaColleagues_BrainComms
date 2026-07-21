function [Params] = fMRIPrep_PreProcess_CreateGLM(Params)
% if we didn't already create MDMs, get user input.
% otherwise GLMs were created in the MDM script!
if Params.CreateMDM == 0
    promptGLMgoal = {'Do you want to create single-subject GLMs or group-level GLM?','Will you use Mac, PC, or Linux for analysis?'};
    dlgtitle = 'GLM Creation - User Input Required';
    dims = [1 100];
    definputexpnames = {'Single (1) or Group (2) or Both (3)', 'Mac (1), PC (2), or Linux (3)?'};
    glminfo = inputdlg(promptGLMgoal,dlgtitle,dims,definputexpnames);
    glmgoal = str2double(glminfo(1));
    computingplatform = str2double(glminfo(2));

    % Get user-defined input regarding the number of fMRI experiments
    promptexpnames = {'Provide the number of fMRI experiment names in your derivatives folder.'};
    dlgtitle = 'List fMRI Experiment Names';
    dims = [1 100];
    definputexpnames = {'e.g., 1, 2, 3, 7'};
    Params.NrOfExps = inputdlg(promptexpnames,dlgtitle,dims,definputexpnames);

    for expi = 1:str2double(Params.NrOfExps{1})
        % let's ask the user to provide info about the exp name and if a
        % BV processed data folder already exists.
        promptexpnames = {['Provide the name of fMRI experiment ' num2str(expi) '.']};
        dlgtitle = 'List the fMRI Experiment Name';
        dims = [1 100];
        definputexpnames = {'e.g., TAFP'};
        fmriexppromp = inputdlg(promptexpnames,dlgtitle,dims,definputexpnames);
        Params.ExpNames(expi).Name = cell2mat(fmriexppromp(1));

        %% let's select the MDM
        switch glmgoal
            case 1
                % Ask user to get the MDM files for GLM creation.
                uiwait(msgbox({['Please select the MDM files to create single-subject GLMs.']}));
                [Params.GLM.MDMNames,Params.GLM.MDMPath] = uigetfile('*.mdm', 'MultiSelect', 'on');

                % inelegant hack but it works for now.
                cd(Params.GLM.MDMPath);
                cd ..
                Params.ExpNames(expi).FolderPath = cd;

                % if an MDM folder doesn't exist in this dir, make it.
                if isfolder(fullfile(Params.ExpNames(expi).FolderPath,'GLM')) == 0
                    mkdir(fullfile(Params.ExpNames(expi).FolderPath,'GLM'));
                end

                NrOfMDMFiles = fullfile(Params.GLM.MDMPath,Params.GLM.MDMNames);

                % now let's loop through each unique MDM.
                for subi = 1:size(NrOfMDMFiles,1)

                    % let's load in first MDM
                    tmpMDM = NrOfMDMFiles(subi,:);

                    % create empty MDM object.
                    subMDM = [];
                    subMDM = BVQXfile(tmpMDM);

                    % default parameters.
                    subMDM.SeparatePredictors = 1;
                    subMDM.PSCTransformation = 1;

                    % make a new object.
                    singleSubGLM = [];
                    singleSubGLM = subMDM.ComputeGLM;

                    % let's create a subject GLM file name.
                    subGLMfilename = [];

                    % now let's get sub ID and create a file name.
                    [~,subname,~] = fileparts(Params.GLM.MDMNames(subi,:));

                    % now let's find subject ID from the subname variable.
                    if contains(subname,'Sub') == 1
                        startingposition = strfind(subname,'Sub');
                        % get starting position of sub, then add 3.
                        % this is when the first number starts.
                        % sub ID is this number to the end (length) of the
                        % subject label from the MDM file.
                        subID = [];
                        subID = subname(startingposition+3:length(subname));
                        subID = str2num(subID);
                        % sometimes we can't find sub ID because there is a
                        % space or underscore in the file name. assumption is that the
                        % subject Id will end right before the first space or underscore.
                        if isempty(subID) == 1
                            if contains(subname,' ')
                                spacefind = strfind(subname,' '); spacefind = spacefind(1);
                                subID = subname(startingposition+3:spacefind-1);
                                subID = str2num(subID);
                            elseif contains(subname,'_')
                                % usually the first underscore comes after
                                % the name of the exp (e.g.,
                                % catloc_sub016) thus we ignore the first.
                                underscorefind = strfind(subname,'_'); underscorefind = underscorefind(2);
                                subID = subname(startingposition+3:underscorefind-1);
                                subID = str2num(subID);
                            end
                        end
                        % if we're working with a lowercase 'sub', do this instead.
                    elseif contains(subname,'sub') == 1
                        startingposition = strfind(subname,'sub');
                        % get starting position of sub, then add 3.
                        % this is when the first number starts.
                        % sub ID is this number to the end (length) of the
                        % subject label from the MDM file.
                        subID = [];
                        subID = subname(startingposition+3:length(subname));
                        subID = str2num(subID);
                        % sometimes we can't find sub ID because there is a
                        % space or underscore in the file name. assumption is that the
                        % subject Id will end right before the first space or underscore.
                        if isempty(subID) == 1
                            if contains(subname,' ')
                                spacefind = strfind(subname,' '); spacefind = spacefind(1);
                                subID = subname(startingposition+3:spacefind-1);
                                subID = str2num(subID);
                            elseif contains(subname,'_')
                                underscorefind = strfind(subname,'_'); underscorefind = underscorefind(1);
                                subID = subname(startingposition+3:underscorefind-1);
                                subID = str2num(subID);
                            end
                        end
                    end
                    % now let's get a Sub GLM file name.
                    subGLMfilename = [];
                    if subID < 10
                        subGLMfilename = fullfile([Params.ExpNames(expi).Name '_sub-00' num2str(subID) '_PSC_FFX.glm']);
                    elseif subID > 9 && subID < 100
                        subGLMfilename = fullfile([Params.ExpNames(expi).Name '_sub-0' num2str(subID) '_PSC_FFX.glm']);
                    elseif subID > 99
                        subGLMfilename = fullfile([Params.ExpNames(expi).Name '_sub-' num2str(subID) '_PSC_FFX.glm']);
                    end

                    % Change path to VTCs and SDMs written into the
                    % GLM based on user-defined inputs.
                    switch computingplatform
                        case 1
                            % This will replace the VM path to the Mac
                            % path to open the GLM in BV on a Mac w/o issue.
                            oldstring = '/mnt/smdnas02/';
                            newstring = '/Volumes/';
                            for runi = 1:size(singleSubGLM.Study,2)
                                newVTCname = []; newSDMname = [];
                                newVTCname = strrep(singleSubGLM.Study(runi).NameOfAnalyzedFile,oldstring,newstring);
                                singleSubGLM.Study(runi).NameOfAnalyzedFile = newVTCname;
                                newSDMname = strrep(singleSubGLM.Study(runi).NameOfSDMFile,oldstring,newstring);
                                singleSubGLM.Study(runi).NameOfSDMFile = newSDMname;
                            end
                        case 2
                            % This will replace the VM path to the PC
                            % path to open the GLM in BV on a PC w/o issue.
                            oldstring = '/mnt/smdnas02/';
                            newstring = '\\smdnas02\';
                            for runi = 1:size(singleSubGLM.Study,2)
                                newVTCname = []; newSDMname = [];
                                newVTCname = strrep(singleSubGLM.Study(runi).NameOfAnalyzedFile,oldstring,newstring);
                                newVTCname = strrep(newVTCname,'/','\');
                                singleSubGLM.Study(runi).NameOfAnalyzedFile = newVTCname;
                                newSDMname = strrep(singleSubGLM.Study(runi).NameOfSDMFile,oldstring,newstring);
                                newSDMname = strrep(newSDMname,'/','\');
                                singleSubGLM.Study(runi).NameOfSDMFile = newSDMname;
                            end
                    end

                    % save file now that we've got the name.
                    singleSubGLM.SaveAs(fullfile(Params.ExpNames(expi).FolderPath,'GLM',subGLMfilename));
                end
            case 2
                % Ask user to get the group-level MDM file GLM creation.
                uiwait(msgbox({['Please select the group MDM file to create a group-subject GLMs.']}));
                [Params.GLM.MDMNames,Params.GLM.MDMPath] = uigetfile('*.mdm', 'MultiSelect', 'on');

                % find the number of MDMs selected.
                NrOfMDMFiles = fullfile(Params.GLM.MDMPath,Params.GLM.MDMNames);

                if isa(NrOfMDMFiles, "char")
                    NrOfMDMFiles = [ convertCharsToStrings(NrOfMDMFiles) ]
                end

                % now let's loop through unique MDMs selected.
                display(size(NrOfMDMFiles))
                for mdmi = 1:size(NrOfMDMFiles,2)

                    % let's load in first MDM
                    tmpMDM = NrOfMDMFiles(mdmi);

                    % create empty MDM object.
                    groupMDM = [];
                    groupMDM = BVQXfile(tmpMDM);

                    % default parameters.
                    groupMDM.PSCTransformation = 1;

                    % Assumption is that we want RFX.
                    groupMDM.RFX_GLM = 1;

                    %create GLM object.
                    groupRFXGLM = groupMDM.ComputeGLM;

                    % create empty file name.
                    groupGLMfilename = [];

                    % now let's get sub IDs and create a file name.
                    [~,MDMName,~] = fileparts(tmpMDMfile);

                    groupGLMfilename = MDMName;

                    % find spaces and replace with underscores.
                    groupGLMfilename(strfind(groupGLMfilename,' ')) = '_';
                    groupGLMfilename(strfind(groupGLMfilename,'__')) = '';

                    % Change path to VTCs and SDMs written into the
                    % GLM based on user-defined inputs.
                    switch computingplatform
                        case 1
                            % This will replace the VM path to the Mac
                            % path to open the GLM in BV on a Mac w/o issue.
                            oldstring = '/mnt/smdnas02/';
                            newstring = '/Volumes/';
                            for runi = 1:size(groupRFXGLM.Study,2)
                                newVTCname = []; newSDMname = [];
                                newVTCname = strrep(groupRFXGLM.Study(runi).NameOfAnalyzedFile,oldstring,newstring);
                                groupRFXGLM.Study(runi).NameOfAnalyzedFile = newVTCname;
                                newSDMname = strrep(groupRFXGLM.Study(runi).NameOfSDMFile,oldstring,newstring);
                                groupRFXGLM.Study(runi).NameOfSDMFile = newSDMname;
                            end
                        case 2
                            % This will replace the VM path to the PC
                            % path to open the GLM in BV on a PC w/o issue.
                            oldstring = '/mnt/smdnas02/';
                            newstring = '\\smdnas02\';
                            for runi = 1:size(groupRFXGLM.Study,2)
                                newVTCname = []; newSDMname = [];
                                newVTCname = strrep(groupRFXGLM.Study(runi).NameOfAnalyzedFile,oldstring,newstring);
                                newVTCname = strrep(newVTCname,'/','\');
                                groupRFXGLM.Study(runi).NameOfAnalyzedFile = newVTCname;
                                newSDMname = strrep(groupRFXGLM.Study(runi).NameOfSDMFile,oldstring,newstring);
                                newSDMname = strrep(newSDMname,'/','\');
                                groupRFXGLM.Study(runi).NameOfSDMFile = newSDMname;
                            end
                    end

                    % save file now that we've got the name.
                    groupRFXGLM.SaveAs(fullfile(Params.ExpNames(expi).FolderPath,'GLM',groupGLMfilename));
                end
        end
    end
end

