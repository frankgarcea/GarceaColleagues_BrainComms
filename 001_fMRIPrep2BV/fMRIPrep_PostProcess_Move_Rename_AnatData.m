function [Params] = fMRIPrep_PostProcess_Move_Rename_AnatData(Params)

%% Moving anatomical data - create folder structure
if Params.MoveFunc == 0
    promptexpnames = {['Please provide your name']};
    dlgtitle = 'User Defined Input: Name';
    dims = [1 100];
    Params.PersonName = inputdlg(promptexpnames,dlgtitle,dims);
    Params.PersonName = cell2mat(Params.PersonName);
end

%% Ask if we want to change subject ID.
if Params.MoveFunc == 0
    promppsubnamechange = {'Do you want to change the subject ID of the data you move?'};
    dlgtitle = 'Change Subject ID';
    dims = [1 100];
    definputexpnames = {'Yes (1) or No (0)'};
    Params.ChangeSubID = str2double(inputdlg(promppsubnamechange,dlgtitle,dims,definputexpnames));
    %% ask what to change subject ID to.
    if Params.ChangeSubID == 1
        changesubnumberpropt = {'Enter a specific value to add to each subject ID.'};
        dlgtitle = 'Change Subject ID';
        dims = [1 100];
        definputexpnames = {'e.g., if you put 1000 and sub ID is 1, the new sub ID is 1001.'};
        Params.SubIDValChange = str2double(inputdlg(changesubnumberpropt,dlgtitle,dims,definputexpnames));
    end
end
%% if we want to move anatomy in the absence of moving functional data.
% let's make sure the user doesn't want to move data to a func
% folder.
promptanatgoal = {'Do you want to copy anatomical files into an already-created functional folder?'};
dlgtitle = 'Anatomical Files - User Input Required';
dims = [1 100];
definputexpnames = {'Yes (1) or No (0)'};
moveanattofunc = inputdlg(promptanatgoal,dlgtitle,dims,definputexpnames);
%% this would indicate the user wants to link up anatomy with an
% already-created functional folder. If so, we need to ask them for
% folder names and locations.
if str2double(moveanattofunc(1)) == 1
    % select derivatives folder
    uiwait(msgbox({'Select the derivatives folder with data output by fmriprep'}));
    Params.FuncFolder = uigetdir();
    Params.ParentFolder = fileparts(Params.FuncFolder);

    % ask the user to provide experiment names.
    promptexpnames = {'Provide the number of fMRI experiment names in your derivatives folder.'};
    dlgtitle = 'List fMRI Experiment Names';
    dims = [1 100];
    definputexpnames = {'e.g., 1, 2, 3, 7'};
    Params.NrOfExps = inputdlg(promptexpnames,dlgtitle,dims,definputexpnames);
    % Now that we have established the number of fMRI experiments, ask the user
    % for input regarding the names and if/where the folders live.
    for expi = 1:str2double(Params.NrOfExps{1})
        % let's ask the user to provide info about the exp name and if a
        % BV processed data folder already exists.
        promptexpnames = {['Provide the name of fMRI experiment ' num2str(expi) '.']};
        dlgtitle = 'List the fMRI Experiment Name';
        dims = [1 100];
        definputexpnames = {'e.g., TAFP'};
        fmriexppromp = inputdlg(promptexpnames,dlgtitle,dims,definputexpnames);
        Params.ExpNames(expi).Name = cell2mat(fmriexppromp(1));
        % if the BV processed folder already exists, find the folder.
        uiwait(msgbox({['Please select the previously created folder where the ' [Params.PersonName '_' Params.ExpNames(expi).Name] ' processed data live.']}));
        Params.ExpNames(expi).FolderPath = uigetdir;
    end
    % now let's loop through experiments and copy anatomy.
    for expi = 1:size(Params.ExpNames,2)
        tmpexpname = []; tmpexpname = Params.ExpNames(expi).Name;
        for subi = 1:length(Params.Subs2process)
            % let's get the subject ID.
            subID = [];
            % let's get the subject ID.
            if Params.Subs2process(subi) < 10
                subID = ['sub-00' num2str(Params.Subs2process(subi))];
            elseif Params.Subs2process(subi) > 9 && Params.Subs2process(subi) < 99
                subID = ['sub-0' num2str(Params.Subs2process(subi))];
            elseif Params.Subs2process(subi) > 99
                subID = ['sub-' num2str(Params.Subs2process(subi))];
            end
            % now let's set a temporary subject folder variable and cd there.
            tmpsubfolder = []; tmpsubfolder = fullfile(Params.FuncFolder,subID);
            cd(tmpsubfolder);

            %let's search through session info to make sure we don't miss session
            %data. E.g., anatomical data could be from session 1 but functional
            % data can be from session 3).
            sessiondir = dir('*ses*');

            % let's loop through session information to get the anatomical files.
            % we'll then use this to copy the data to the process data folder.
            for sessioni = 1:size(sessiondir,1)
                % create a new variable
                sessionID = [];
                sessionID = sessiondir(sessioni).name;

                % let's cd into the session directory to find a func
                % folder.
                cd(sessionID);
                %
                anatomicaldirectory = [];
                anatomicaldirectory= filterdir('anat');
                % if the session folder has an 'func' folder we move forward.
                if isempty(anatomicaldirectory) == 0 %contains(anatomicaldirectory.name,'anat') == 1
                    tmpanatfolder = []; tmpanatfolder = fullfile(tmpsubfolder,sessionID,anatomicaldirectory(1).name);
                    cd(tmpanatfolder);

                    if Params.ChangeSubID == 1
                        subID = ['sub-' num2str(Params.Subs2process(subi) + Params.SubIDValChange)];
                    end

                    if contains(lower(tmpexpname),'rest') == 0
                        Params.PathToSaveAnat = fullfile(Params.HomeDirectory,['/' Params.PersonName '_BV_' tmpexpname],'Anatomy');
                        % now that we're in the anatomical folder let's copy the data.
                        switch Params.Anatomyspace
                            case 1
                                MNIbrain = dir('*MNI152NLin2009cAsym_desc-preproc_T1w.nii.gz*');
                                if isfolder(fullfile(Params.PathToSaveAnat,subID,sessionID)) == 0
                                    mkdir(fullfile(Params.PathToSaveAnat,subID,sessionID));
                                end
                                copyfile(MNIbrain.name,fullfile(Params.PathToSaveAnat,subID,sessionID),'f');
                            case 2
                                MNIbrain = dir('*desc-preproc_T1w.nii.gz*');
                                if isfolder(fullfile(Params.PathToSaveAnat,subID)) == 0
                                    mkdir(fullfile(Params.PathToSaveAnat,subID));
                                end
                                copyfile(MNIbrain.name,fullfile(Params.PathToSaveAnat,subID,sessionID),'f');
                        end
                    elseif contains(lower(tmpexpname),'rest') == 1
                        Params.PathToSaveAnat = fullfile(Params.HomeDirectory,['/' Params.PersonName '_' Params.ExpNames(expi).Name],'derivatives/');
                        if isfolder(fullfile(Params.PathToSaveAnat,subID,sessionID,'/anat')) == 0
                            mkdir(fullfile(Params.PathToSaveAnat,subID,sessionID,'/anat'));
                        end
                        niftidir = dir;
                        for anatfilei = 1:size(niftidir,1)
                            % create temporary name
                            tempname = niftidir(anatfilei).name;
                            % if the name does not start with . or ..
                            if startsWith(tempname,'.') == 0 && startsWith(tempname,'..') == 0
                                % the suffix is 5 after the start of ses
                                % because we know that session length is constant.
                                suffixvar = tempname(strfind(tempname,'ses')+5:length(tempname));
                                % create basic new file name.
                                newfilename = [subID '_' sessionID suffixvar];
                                % now copy the file into a new anat folder
                                % within the derivates folder.
                                copyfile(niftidir(anatfilei).name,fullfile(Params.PathToSaveAnat,subID,sessionID,'anat/',newfilename),'f');
                            end
                        end
                        cd(tmpsubfolder);
                    end
                    cd(tmpsubfolder);
                end
            end
        end
    end
end
