function [Params] = fMRIPrep_PreProcess_MovePRT(Params)
%try
%% Create VTC folder within the Processed Data Folder.
if Params.MovePRT
    if Params.CreateVTC == 0
        % Let's get the func folder in the instance in which the user does
        % not indicate they want to move func data.
        promptSDMgoal = {'Do you want to move PRTs to an already-created functional folder?'};
        dlgtitle = 'SDM Creation - User Input Required';
        dims = [1 100];
        definputexpnames = {'Yes (1) or No (0)'};
        vtclocationinfo = inputdlg(promptSDMgoal,dlgtitle,dims,definputexpnames);
        % this would indicate the user wants to create VTCs within an
        % already-created functional folder. We need to ask them for folder
        % names and locations.
        if str2double(vtclocationinfo(1)) == 1
            % ask the user to provide experiment names.
            promptexpnames = {'Provide the number of fMRI experiment names in your derivatives folder.'};
            dlgtitle = 'List fMRI Experiment Names';
            dims = [1 100];
            definputexpnames = {'e.g., 1, 2, 3, 7'};
            Params.NrOfExps = inputdlg(promptexpnames,dlgtitle,dims,definputexpnames);
        end
        % Now that we have established the number of fMRI experiments, ask
        % the user for input regarding the names and if/where the folders
        % live.
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
            if contains(lower(Params.ExpNames(expi).Name),'rest') == 0
                uiwait(msgbox({['Please select the previously created folder where the ' Params.ExpNames(expi).Name ' processed VTCs live.']}));
                Params.VTC(expi).FolderName = uigetdir;
                Params.ExpNames(expi).FolderPath = fileparts(Params.VTC(expi).FolderName);
                % pare this down to the folder name only. not the path
                % and folder name together (this complicates things
                % later).
                [~,Params.VTC(expi).FolderName,~] = fileparts(Params.VTC(expi).FolderName);
            elseif contains(lower(Params.ExpNames(expi).Name),'rest') == 1
                uiwait(msgbox({['Please select the ' Params.ExpNames(expi).Name ' folder.']}));
                Params.VTC(expi).FolderName = uigetdir;
                Params.ExpNames(expi).FolderPath = Params.VTC(expi).FolderName;
            end
        end
    end

    %% Getting PRT files.
    for expi = 1:size(Params.ExpNames,2)
        tmpexpname = []; tmpexpname = Params.ExpNames(expi).Name;
        % if the experiment does not have 'Rest' in the name, we proceed.
        if contains(lower(tmpexpname),'rest') == 0
            % let's make a PRT folder if it doesn't already exist
            if isfolder(fullfile(Params.ExpNames(expi).FolderPath,[tmpexpname '_PRTs'])) == 0
                mkdir(fullfile(Params.ExpNames(expi).FolderPath,[tmpexpname '_PRTs']));
            end
            Params.PRT(expi).FolderStorage = fullfile(Params.ExpNames(expi).FolderPath,[tmpexpname '_PRTs']);
            % Let's ask the user to point us to the PRTs.
            %% Gather basic information needed to begin moving and processing data.
            prompt = {'Enter the number of runs per subject that you are copying.'};
            dlgtitle = 'User Provided PRT Copy Parameters';
            dims = [1 75];
            definput = {'If all subs did 4 runs, put 4; otherwise list the number of runs per subject.'};
            PRTanswer = inputdlg(prompt,dlgtitle,dims,definput);

            %
            uiwait(msgbox({['Please the subject ' tmpexpname ' PRT files you wish to copy.']}));
            [Params.PRT(expi).PRTNames,Params.PRT(expi).FolderPath] = uigetfile('*.prt', 'MultiSelect', 'on');
            % now let's copy the PRTs to the processed data folder.
            %for prti = 1:size(Params.PRT(expi).PRTNames,2)
            %    copyfile(fullfile(Params.PRT(expi).FolderPath,cell2mat(Params.PRT(expi).PRTNames(prti))),fullfile(Params.ExpNames(expi).FolderPath,[tmpexpname '_PRTs']),'f');
            %end

            % Create subject and run variables here.    
            Params.PRTCopy(expi).Subs = Params.Subs2process;
            Params.PRTCopy(expi).Runs = str2num(PRTanswer{1});
            % now let's copy the PRTs to the processed data folder.
            for subi = 1:length(Params.Subs2process)
                subID = [];
                % let's get the subject ID.
                if Params.Subs2process(subi) < 10
                    subID = ['sub-00' num2str(Params.Subs2process(subi))];
                elseif Params.Subs2process(subi) > 9 && Params.Subs2process(subi) < 99
                    subID = ['sub-0' num2str(Params.Subs2process(subi))];
                elseif Params.Subs2process(subi) > 99
                    subID = ['sub-' num2str(Params.Subs2process(subi))];
                end
                % loop through runs
                cumulativePRT = 0;
                for runi = 1:Params.PRTCopy(expi).Runs(subi)
                    cumulativePRT = cumulativePRT + 1;
                    %tmpPRTname = [tmpexpname '_' subID '_' sessionID '_Run' num2str(runi) '.prt'];
                    copyfile(fullfile(Params.PRT(expi).FolderPath,cell2mat(Params.PRT(expi).PRTNames(cumulativePRT))),fullfile(Params.PRT(expi).FolderStorage,[tmpexpname '_Sub' num2str(Params.Subs2process(subi)) '_Run' num2str(runi) '.prt']),'f');
                end
            end
        end
    end
end
              