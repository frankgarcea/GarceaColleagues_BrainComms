function [Params] = fMRIPrep_PostProcess_Move_Rename_FuncData(Params)
if Params.MoveFunc
    % Select folder with func outputs of fMRIprep
    uiwait(msgbox({'Select the derivatives folder with data output by fmriprep'}));
    Params.FuncFolder = uigetdir();
    Params.ParentFolder = fileparts(Params.FuncFolder);
    %% if multiple experiments exist within the derivatives folder, ask user for the names.
    promptexpnames = {'How many fMRI experiments in your derivatives folder do you want to move?'};
    dlgtitle = 'List fMRI Experiment Names';
    dims = [1 100];
    definputexpnames = {'e.g., 1, 2, 3, 7'};
    Params.NrOfExps = inputdlg(promptexpnames,dlgtitle,dims,definputexpnames);
    % Now that we have established the number of fMRI experiments, ask the user
    % for input regarding the names and if/where the folders live.
    for expi = 1:str2double(Params.NrOfExps{1})
        % let's ask the user to provide info about the exp name and if a
        % BV processed data folder already exists.
        promptexpnames = {['Provide the name of fMRI experiment ' num2str(expi) '.'],'Does a processed folder for the fMRI experiment already exist?'};
        dlgtitle = 'List the fMRI Experiment Name';
        dims = [1 100];
        definputexpnames = {'','(Yes = 1; No = 0)'};
        fmriexppromp = inputdlg(promptexpnames,dlgtitle,dims,definputexpnames);
        Params.ExpNames(expi).Name = cell2mat(fmriexppromp(1));
        Params.ExpNames(expi).Folderexist = str2double(fmriexppromp{2});

        % now let's select the folder where your resting
        if Params.ExpNames(expi).Folderexist == 1
            uiwait(msgbox({['Please select the previously created folder where the ' Params.ExpNames(expi).Name ' processed data live.']}));
            Params.ExpNames(expi).FolderPath = uigetdir;
            % else if the folder doesn't exist, let's make it.
        elseif Params.ExpNames(expi).Folderexist == 0
            % if the folder doesn't exists, let's create it.
            % Make experiment folder in the home directory folder.
            if contains(lower(Params.ExpNames(expi).Name),'rest') ~= 1
                % Let's get the user's name.
                promptexpnames = {['Please provide your name']};
                dlgtitle = 'User Defined Input: Name';
                dims = [1 100];
                Params.PersonName = inputdlg(promptexpnames,dlgtitle,dims);
                Params.PersonName = cell2mat(Params.PersonName);
                Params.NameCheck = 1;
                % check if project-level folder exists; if not, make it.
                if isfolder(fullfile(Params.HomeDirectory,[Params.PersonName '_BV_' Params.ExpNames(expi).Name])) == 0
                    mkdir(Params.HomeDirectory,[Params.PersonName '_BV_' Params.ExpNames(expi).Name]);
                end
                % check if func dicoms folder exists; if not, make it.
                if isfolder(fullfile([Params.HomeDirectory,'/' Params.PersonName '_BV_' Params.ExpNames(expi).Name],'FuncDicoms')) == 0
                    mkdir([Params.HomeDirectory,'/' Params.PersonName '_BV_' Params.ExpNames(expi).Name],'FuncDicoms');
                end
                % check if anatomy folder exists; if not, make it.
                if isfolder(fullfile([Params.HomeDirectory,Params.PersonName '_BV_' Params.ExpNames(expi).Name],'Anatomy')) == 0
                    mkdir([Params.HomeDirectory,'/' Params.PersonName '_BV_' Params.ExpNames(expi).Name],'Anatomy');
                end
                % save a path to the processed data folder.
                Params.ExpNames(expi).FolderPath = fullfile(Params.HomeDirectory,[Params.PersonName '_BV_' Params.ExpNames(expi).Name]);
                % If we're working with rest we don't use BV, so use a
                % different folder format.
            elseif contains(lower(Params.ExpNames(expi).Name),'rest') == 1
                if isfield(Params,'NameCheck') == 0
                    promptexpnames = {['Please provide your name']};
                    dlgtitle = 'User Defined Input: Name';
                    dims = [1 100];
                    Params.PersonName = inputdlg(promptexpnames,dlgtitle,dims);
                    Params.PersonName = cell2mat(Params.PersonName);
                    Params.NameCheck = 1;
                end
                % check if project-level folder exists; if not, make it.
                if isfolder(fullfile(Params.HomeDirectory,[Params.PersonName '_' Params.ExpNames(expi).Name])) == 0
                    mkdir(fullfile(Params.HomeDirectory,[Params.PersonName '_' Params.ExpNames(expi).Name]));
                end
                % check if a derivatives folder exists; if not, make it.
                if isfolder(fullfile(Params.HomeDirectory,fullfile(Params.PersonName,Params.ExpNames(expi).Name,'derivatives'))) == 0
                    mkdir(fullfile(Params.HomeDirectory,[Params.PersonName '_' Params.ExpNames(expi).Name],'derivatives'));
                end
                Params.ExpNames(expi).FolderPath = fullfile(Params.HomeDirectory,[Params.PersonName '_' Params.ExpNames(expi).Name]);
            end
        end
    end

    %% now that we've set up our folder structure, let's move data.
    promppsubnamechange = {'Do you want to change the subject ID of the data you move?'};
    dlgtitle = 'Change Subject ID';
    dims = [1 100];
    definputexpnames = {'Yes (1) or No (0)'};
    Params.ChangeSubID = str2double(inputdlg(promppsubnamechange,dlgtitle,dims,definputexpnames));

    
    for expi = 1:size(Params.ExpNames,2)
        tmpexpname = []; tmpexpname = Params.ExpNames(expi).Name;
        % ask what to change subject ID to.
            if Params.ChangeSubID == 1
                changesubnumberpropt = {'Enter a specific value to add to each subject ID.'};
                dlgtitle = 'Change Subject ID';
                dims = [1 100];
                definputexpnames = {'e.g., if you put 1000 and sub ID is 1, the new sub ID is 1001.'};
                Params.SubIDValChange = str2double(inputdlg(changesubnumberpropt,dlgtitle,dims,definputexpnames));
            end
            
            % ask what to change exp name to 
            if Params.ChangeSubID == 1
                changesubnumberpropt = {'Enter a specific name to change the experiment.'};
                dlgtitle = 'Change Exp Name';
                dims = [1 100];
                definputexpnames = {'e.g., resting'};
                Params.NameChange = cell2mat(inputdlg(changesubnumberpropt,dlgtitle,dims,definputexpnames));
            % if the user doesn't want to change the name, keep it as is.
            elseif Params.ChangeSubID == 0
                Params.NameChange = tmpexpname;
            end
        
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
            
            if Params.ChangeSubID == 1
                subID = ['sub-' num2str(Params.Subs2process(subi) + Params.SubIDValChange)];
            end

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
                functionaldirectory = [];
                functionaldirectory= filterdir('func');
                % if the session folder has an 'func' folder we move forward.
                if isempty(functionaldirectory) == 0 %contains(functionaldirectory.name,'func') == 1
                    tmpfuncfolder = []; tmpfuncfolder = fullfile(tmpsubfolder,sessionID,functionaldirectory(1).name);
                    cd(tmpfuncfolder);
                    if contains(lower(tmpexpname),'rest') == 0
                        Params.PathToSaveFunc = fullfile(Params.HomeDirectory,['/' Params.PersonName '_BV_' tmpexpname],'FuncDicoms');
                        % now that we're in the functional folder let's copy the data.
                        niftidir = dir('*desc-preproc_bold.nii.gz*');
                        tsvdir = dir('*tsv*');
                        for funcfilei = 1:size(niftidir,1)
                            currnifti = [];
                            currnifti = niftidir(funcfilei).name;
                            currtsvi = [];
                            currtsvi = tsvdir(funcfilei).name;
                            if contains(currnifti,tmpexpname) == 1
                                tmprunlookup = []; tmprunlookup = strfind(currnifti,'run-');
                                tmprunID = []; tmprunID = str2double(currnifti(tmprunlookup+4));
                                if isfolder(fullfile(Params.PathToSaveFunc,subID,sessionID,['run' num2str(tmprunID)])) == 0
                                    mkdir(fullfile(Params.PathToSaveFunc,subID,sessionID,['run' num2str(tmprunID)]));
                                end
                                copyfile(currnifti,fullfile(Params.PathToSaveFunc,subID,sessionID,['run' num2str(tmprunID)]),'f');
                                copyfile(currtsvi,fullfile(Params.PathToSaveFunc,subID,sessionID,['run' num2str(tmprunID)]),'f');
                            end
                        end
                    elseif contains(lower(tmpexpname),'rest') == 1
                        % get path to move your functional data.
                        Params.PathToSaveFunc = fullfile(Params.ExpNames(expi).FolderPath,'derivatives/');
                        
                        % if the folder doesn't exist, make it.
                        if isfolder(fullfile(Params.PathToSaveFunc,subID,sessionID,'func/')) == 0
                            mkdir(fullfile(Params.PathToSaveFunc,subID,sessionID,'func/'));
                        end
                        
                        % find all nifti data with rest in the name.
                        niftidir = dir([ '*' tmpexpname '*']);
                        for funcfilei = 1:size(niftidir,1)
                            %tempname = niftidir(funcfilei).name;
                            tmprunlookup = []; tmprunlookup = strfind(niftidir(funcfilei).name,'run-');
                            tmprunID = []; tmprunID = str2double(niftidir(funcfilei).name(tmprunlookup+4));
                            % create temp variable.
                            tempfilename = niftidir(funcfilei).name;
                          
                            % create basic new file name.
                            newfilename = [subID '_' sessionID '_task-' Params.NameChange '_run-' num2str(tmprunID)];
                            
                            % we know this because run is the last part of
                            % the file and we know from above that 5 past
                            % the end of run is where the rest of the file
                            % name is particular.
                            newfilename = [newfilename tempfilename(tmprunlookup+5:end)];
                            % now copy the file into a new func folder
                            % within the derivates folder.
                            copyfile(niftidir(funcfilei).name,fullfile(Params.PathToSaveFunc,subID,sessionID,'func/',newfilename),'f')
                        end
                    end
                    cd(tmpsubfolder);
                end
                cd(tmpsubfolder);
            end
            cd(tmpsubfolder);
        end
    end
end