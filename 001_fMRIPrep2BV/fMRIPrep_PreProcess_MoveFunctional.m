function [Params] = fMRIPrep_PreProcess_MoveFunctional(Params)
%try
%% Moving functional data - create folder structure
if Params.MoveFunc
    % Select folder with func outputs of fMRIprep
    uiwait(msgbox({'Select the derivatives folder with data output by fmriprep'}));
    Params.FuncFolder = uigetdir();
    Params.ParentFolder = fileparts(Params.FuncFolder);
    %% if multiple experiments exist within the derivatives folder, ask user for the names.
    promptexpnames = {'Provide the number of fMRI experiment names in your derivatives folder.'};
    dlgtitle = 'List fMRI Experiment Names';
    dims = [1 100];
    definputexpnames = {'e.g., 1, 2, 3, 7'};
    Params.NrOfExps = inputdlg(promptexpnames,dlgtitle,dims,definputexpnames);

    % now let's create a repeated matrix to prompt the user to input exp
    % names.
    tempprompt = [];
    definputexpnames = [];
    for expi = 1:str2double(Params.NrOfExps{1})
        tempprompt{expi,1} = ['Provide the name of fMRI experiment ' num2str(expi) '.'];
        tempprompt{expi,2} = ['Does a BV processed folder for fMRI experiment ' num2str(expi) ' already exist?'];
        definputexpnames{expi,1} = [''];
        definputexpnames{expi,2} = ['(Yes = 1; No = 0)'];
    end
    dlgtitle = 'List the fMRI Experiment Name';
    dims = [1 100];
    fmriexppromp = inputdlg(tempprompt,dlgtitle,dims,definputexpnames);


    %promptexpnames.folderexist{expi} = ['Provide the name of fMRI experiment ' num2str(expi) '.']


    % Now that we have established the number of fMRI experiments, ask the user
    % for input regarding the names and if/where the folders live.
    for expi = 1:str2double(Params.NrOfExps{1})
        % let's ask the user to provide info about the exp name and if a
        % BV processed data folder already exists.
        %promptexpnames = {['Provide the name of fMRI experiment ' num2str(expi) '.'],'Does a BV processed folder for the fMRI experiment already exist?'};
        %dlgtitle = 'List the fMRI Experiment Name';
        %dims = [1 100];
        %definputexpnames = {'','(Yes = 1; No = 0)'};
        %fmriexppromp = inputdlg(promptexpnames,dlgtitle,dims,definputexpnames);
        Params.ExpNames(expi).Name = cell2mat(fmriexppromp(expi));
        Params.ExpNames(expi).Folderexist = str2double(fmriexppromp{expi+(str2double(Params.NrOfExps))});

        % Let's get VTC parameters before we start if you're making VTCs.
        if Params.CreateVTC == 1 && contains(lower(Params.ExpNames(expi).Name),'rest') == 0 && expi == 1
            promptVTCsmooth = {['If you are smoothing ' Params.ExpNames(expi).Name ' VTCs, enter the smoothing kernel size (FWHM)'],'What size functional voxels do you want (in mm)?','Temporal High Pass Filter the VTCs (YES!)?'};
            dlgtitle = ['VTC Smoothing - User Input Required for ' Params.ExpNames(expi).Name ' VTC creation.'];
            dims = [1 100];
            definputexpnames = {'Enter smoothing kernel value in mm (6 is suggested); put 0 if not smoothing','Enter voxel size in mm (3 is the suggested mm size).','How many cycles (sines per cosine) do you want (2 is suggested)?'};
            vtcsmoothinfo = inputdlg(promptVTCsmooth,dlgtitle,dims,definputexpnames);
            Params.VTC.SmoothKernel = str2double(vtcsmoothinfo(1));
            Params.VTC.VoxelSize = str2double(vtcsmoothinfo(2));
            Params.VTC.THPF = str2double(vtcsmoothinfo(3));
        end

        % if the BV processed folder already exists, find the folder.
        if Params.ExpNames(expi).Folderexist == 1
            uiwait(msgbox({['Please select the previously created folder where the ' Params.ExpNames(expi).Name ' processed data live.']}));
            Params.ExpNames(expi).FolderPath = uigetdir;
            % if this is a new project, let's find the user's name.
            [~,FolderName,~] = fileparts(Params.ExpNames(expi).FolderPath);
            FindUnderscore = min(strfind(FolderName,'_'));
            Params.PersonName = FolderName(1:FindUnderscore-1);

        elseif Params.ExpNames(expi).Folderexist == 0
            % if the folder doesn't exists, let's create it.
            % Make experiment folder in the home directory folder.
            if contains(lower(Params.ExpNames(expi).Name),'rest') ~= 1
                if expi == 1
                    % Let's get the user's name.
                    promptexpnames = {['Please provide your name']};
                    dlgtitle = 'User Defined Input: Name';
                    dims = [1 100];
                    Params.PersonName = inputdlg(promptexpnames,dlgtitle,dims);
                    Params.PersonName = cell2mat(Params.PersonName);
                    Params.NameCheck = 1;
                end
                % check if project-level folder exists; if not, make it.
                if isfolder(fullfile(Params.HomeDirectory,[Params.PersonName '_BV_' Params.ExpNames(expi).Name])) == 0
                    mkdir(Params.HomeDirectory,[Params.PersonName '_BV_' Params.ExpNames(expi).Name]);
                end
                % check if func dicoms folder exists; if not, make it.
                if isfolder(fullfile([Params.HomeDirectory,'/' Params.PersonName '_BV_' Params.ExpNames(expi).Name],'FuncDicoms')) == 0
                    mkdir([Params.HomeDirectory,'/' Params.PersonName '_BV_' Params.ExpNames(expi).Name],'FuncDicoms');
                end
                % check if anatomy folder exists; if not, make it.
                %if isfolder(fullfile([Params.HomeDirectory,Params.PersonName '_BV_' Params.ExpNames(expi).Name],'Anatomy')) == 0
                %    mkdir([Params.HomeDirectory,'/' Params.PersonName '_BV_' Params.ExpNames(expi).Name],'Anatomy');
                %end
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
    for expi = 1:size(Params.ExpNames,2)
        tmpexpname = []; tmpexpname = Params.ExpNames(expi).Name;
        for subi = 1:length(Params.Subs2process)
            % let's get the subject ID.
            subID = [];
            % let's get the subject ID.
            if Params.Subs2process(subi) < 10
                subID = ['sub-00' num2str(Params.Subs2process(subi))];
            elseif Params.Subs2process(subi) > 9 && Params.Subs2process(subi) < 100
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
                functionaldirectory = [];
                functionaldirectory= filterdir('func');
                if length(functionaldirectory) ~= 1
                error('Expected exactly one functional file.');
                end
                % if the session folder has an 'func' folder we move forward.
                if isempty(functionaldirectory) == 0 %contains(functionaldirectory.name,'func') == 1
                    tmpfuncfolder = []; tmpfuncfolder = fullfile(tmpsubfolder,sessionID,functionaldirectory(1).name);
                    cd(tmpfuncfolder);
                    if contains(lower(tmpexpname),'rest') == 0
                        if Params.ExpNames(expi).Folderexist == 0
                            Params.PathToSaveFunc = fullfile(Params.HomeDirectory,['/' Params.PersonName '_BV_' tmpexpname],'FuncDicoms');
                        elseif Params.ExpNames(expi).Folderexist == 1
                            Params.PathToSaveFunc = fullfile(Params.ExpNames(expi).FolderPath,'/FuncDicoms');
                        end
                        % now that we're in the functional folder let's copy the data.
                        niftidir = dir('*desc-preproc_bold.nii.gz*');
                        for funcfilei = 1:size(niftidir,1)
                            currnifti = [];
                            currnifti = niftidir(funcfilei).name;
                            %currtsvi = [];
                            %currtsvi = tsvdir(funcfilei).name;
                            if contains(lower(currnifti),lower(tmpexpname)) == 1
                                tmprunlookup = []; tmprunlookup = strfind(currnifti,'run-');
                                tmprunID = []; tmprunID = str2double(currnifti(tmprunlookup+5));
                                if isfolder(fullfile(Params.PathToSaveFunc,subID,sessionID,['run' num2str(tmprunID)])) == 0
                                    mkdir(fullfile(Params.PathToSaveFunc,subID,sessionID,['run' num2str(tmprunID)]));
                                end
                                copyfile(currnifti,fullfile(Params.PathToSaveFunc,subID,sessionID,['run' num2str(tmprunID)]),'f');
                                %copyfile(currtsvi,fullfile(Params.PathToSaveFunc,subID,sessionID,['run' num2str(tmprunID)]),'f');
                            end
                        end
                        %
                        tsvdir = dir('*tsv*');
                        for tsvfilei = 1:size(tsvdir,1)
                            currtsvi = [];
                            currtsvi = tsvdir(tsvfilei).name;
                            if contains(lower(currtsvi),lower(tmpexpname)) == 1
                                tmprunlookup = []; tmprunlookup = strfind(currtsvi,'run-');
                                tmprunID = []; tmprunID = str2double(currtsvi(tmprunlookup+5));
                                if isfolder(fullfile(Params.PathToSaveFunc,subID,sessionID,['run' num2str(tmprunID)])) == 0
                                    mkdir(fullfile(Params.PathToSaveFunc,subID,sessionID,['run' num2str(tmprunID)]));
                                end
                                %copyfile(currnifti,fullfile(Params.PathToSaveFunc,subID,sessionID,['run' num2str(tmprunID)]),'f');
                                copyfile(currtsvi,fullfile(Params.PathToSaveFunc,subID,sessionID,['run' num2str(tmprunID)]),'f');
                            end
                        end
                    elseif contains(lower(tmpexpname),'rest') == 1
                        if Params.ExpNames(expi).Folderexist == 0
                            Params.PathToSaveFunc = fullfile(Params.HomeDirectory,[Params.PersonName '_' Params.ExpNames(expi).Name],'derivatives/');
                        elseif Params.ExpNames(expi).Folderexist == 1
                            Params.PathToSaveFunc = fullfile(Params.ExpNames(expi).FolderPath,'/derivatives');
                        end
                        %
                        if isfolder(fullfile(Params.PathToSaveFunc,subID,sessionID,'/func')) == 0
                            mkdir(fullfile(Params.PathToSaveFunc,subID,sessionID,'/func'));
                        end
                        niftidir = dir([ '*' tmpexpname '*']);%('*rest*');
                        for funcfilei = 1:size(niftidir,1)
                            copyfile(niftidir(funcfilei).name,fullfile(Params.PathToSaveFunc,subID,sessionID,'/func'),'f')
                        end
                    end
                    cd(tmpsubfolder);
                end
                cd(tmpsubfolder);
            end
        end
    end
end
%catch
%uiwait(msgbox({'There was an error in the MoveFunctional code.'}));
%cd(Params.HomeDirectory);
%end
%end