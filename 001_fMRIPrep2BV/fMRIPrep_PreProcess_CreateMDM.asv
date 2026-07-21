function [Params] = fMRIPrep_PreProcess_CreateMDM(Params)
%
if Params.CreateMDM
    % assuming we didn't just process the SDM file, let's get that
    % info.
    %
    % Let's get the func folder in the instance in which the user does
    % not indicate they want to move func data.
    promptMDMgoal = {'Do you want to create single-subject or group-level MDMs?', 'Will you use Mac, PC, or Linux for analysis?'};
    dlgtitle = 'MDM Creation - User Input Required';
    dims = [1 100];
    definputexpnames = {'Single (1) or Group (2) or Both (3)', 'Mac (1), PC (2), or Linux (3)?'};
    mdminfo = inputdlg(promptMDMgoal,dlgtitle,dims,definputexpnames);
    mdmgoal = str2double(mdminfo(1));
    computingplatform = str2double(mdminfo(2));
    if mdmgoal ~= 1; groupMDM = BVQXfile('new:mdm'); groupcounter = 0; end
    % this would indicate the user wants to create VTCs within an
    % already-created functional folder. We need to ask them for folder
    % names and locations.
    if Params.CreateSDM == 0
        % ask the user to provide experiment names.
        promptexpnames = {'Provide the number of fMRI experiment names in your derivatives folder.'};
        dlgtitle = 'List fMRI Experiment Names';
        dims = [1 100];
        definputexpnames = {'e.g., 1, 2, 3, 7'};
        Params.NrOfExps = inputdlg(promptexpnames,dlgtitle,dims,definputexpnames);
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
                uiwait(msgbox({['Please select the previously created VTC folder where the ' Params.ExpNames(expi).Name ' SDMs and processed VTCs live.']}));
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
    %% Main loop doing MDM creation.
    for expi = 1:size(Params.ExpNames,2)
        tmpexpname = []; tmpexpname = Params.ExpNames(expi).Name;
        % if the experiment does not have 'Rest' in the name, we proceed.
        if contains(lower(tmpexpname),'rest') == 0
            % let's first cd into the processed data folder.
            cd(Params.ExpNames(expi).FolderPath);
            % if an MDM folder doesn't exist in this dir, make it.
            if isfolder(fullfile(Params.ExpNames(expi).FolderPath,'MDM')) == 0
                mkdir(fullfile(Params.ExpNames(expi).FolderPath,'MDM'));
            end
            Params.MDMLoc(expi).Name = fullfile(Params.ExpNames(expi).FolderPath,'MDM');
            %% Now let's loop through subjects in the VTC directory.
            for subi = 1:length(Params.Subs2process)
                subID = [];
                if Params.Subs2process(subi) < 10
                    subID = ['sub-00' num2str(Params.Subs2process(subi))];
                elseif Params.Subs2process(subi) > 9 && Params.Subs2process(subi) < 100
                    subID = ['sub-0' num2str(Params.Subs2process(subi))];
                elseif Params.Subs2process(subi) > 99
                    subID = ['sub-' num2str(Params.Subs2process(subi))];
                end
                % now let's set a temporary subject folder variable and cd there.
                %if Params.MoveFunc == 0
                %    Params.VTC(expi).FolderName = fullfile(Params.ExpNames(expi).FolderPath,Params.VTC(expi).FolderName);
                %end
                tmpsubfolder = []; tmpsubfolder = fullfile(Params.ExpNames(expi).FolderPath,Params.VTC(expi).FolderName,subID);
                cd(tmpsubfolder);


                % get session information.
                sessiondir = dir('*ses*');

                % let's loop through session information to get SDMs.
                % we'll then use this to create MDMs.
                for sessioni = 1:size(sessiondir,1)
                    % create a new variable
                    sessionID = [];
                    sessionID = sessiondir(sessioni).name;
                    %
                    rundirectory = [];
                    rundirectory= filterdir('run',sessionID);
                    % if the session folder has an 'run' folder we move forward.
                    if contains(rundirectory(1).name,'run') == 1
                        for runi = 1:size(rundirectory,1)
                            tmprunfolder = []; tmprunfolder = fullfile(sessionID,rundirectory(runi).name);
                            cd(tmprunfolder);
                            % create MDM that will get saved out.
                            if runi == 1
                                MDM = BVQXfile('new:mdm');
                                MDM.RFX_GLM = 0;
                                MDM.PSCTransformation = 1;
                                MDM.zTransformation = 0;
                                MDM.SeparatePredictors = 0;
                                MDM.NrOfStudies = size(rundirectory,1);
                            end
                            % need to save out final VTC loc location
                            vtcdir = []; vtcdir = dir('*vtc*');
                            if isempty(vtcdir)
                                error('No VTC found.');
                            elseif length(vtcdir) > 1
                                warning('Multiple VTCs found. Using first.');
                            end
                            sdmdir =[]; sdmdir = dir('*sdm*');
                            if isempty(sdmdir)
                                error('No SDM found.');
                            elseif length(sdmdir) > 1
                                warning('Multiple SDMs found. Using first.');
                            end
                            %
                            tmpvtcpath = []; tmpvtcpath = fullfile(tmpsubfolder,tmprunfolder,vtcdir(1).name);
                            tmpsdmpath = []; tmpsdmpath = fullfile(tmpsubfolder,tmprunfolder,sdmdir(1).name);
                            % save out this info in MDM file.
                            MDM.XTC_RTC{runi,1} = tmpvtcpath; MDM.XTC_RTC{runi,2} = tmpsdmpath;

                            % if we're saving out a group-level MDM,
                            % start aggregating here.
                            if mdmgoal ~= 1
                                groupcounter = groupcounter + 1;
                                groupMDM.XTC_RTC{groupcounter,1} = tmpvtcpath;
                                groupMDM.XTC_RTC{groupcounter,2} = tmpsdmpath;
                            end

                            % if we're cycled through all runs, save
                            % out subject-level
                            if mdmgoal ~= 2 && runi == size(rundirectory,1)
                                subMDMfilename = [];
                                subMDMfilename = fullfile(Params.MDMLoc(expi).Name,[tmpexpname '_' subID '_ses-' num2str(sessioni) '.mdm']);
                                
                                if Params.CreateGLM == 1
                                    % default parameters.
                                    MDM.SeparatePredictors = 1;
                                    MDM.PSCTransformation = 1;
                                    
                                    % Now let's make the GLM.
                                    singleSubGLM = MDM.ComputeGLM;
                                    
                                    % let's create a subject GLM file name.
                                    subGLMfilename = [];

                                    % now let's get sub ID and create a file
                                    % name.
                                    if Params.Subs2process(subi) < 10
                                        subGLMfilename = fullfile([tmpexpname '_sub-00' num2str(Params.Subs2process(subi)) '_ses-' num2str(sessioni) '_PSC_FFX.glm']);
                                    elseif Params.Subs2process(subi) > 9 && Params.Subs2process(subi) < 100
                                        subGLMfilename = fullfile([tmpexpname '_sub-0' num2str(Params.Subs2process(subi)) '_ses-' num2str(sessioni) '_PSC_FFX.glm']);
                                    elseif Params.Subs2process(subi) > 99
                                        subGLMfilename = fullfile([tmpexpname '_sub-' num2str(Params.Subs2process(subi)) '_ses-' num2str(sessioni) '_PSC_FFX.glm']);
                                    end

                                    % save file now that we've got the name.
                                    if isfolder(fullfile(Params.ExpNames(expi).FolderPath,'GLM')) == 0
                                        mkdir(fullfile(Params.ExpNames(expi).FolderPath,'GLM'));
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
                                                MDM.XTC_RTC{runi,1} = newVTCname;
                                                MDM.XTC_RTC{runi,2} = newSDMname;
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
                                                MDM.XTC_RTC{runi,1} = newVTCname;
                                                MDM.XTC_RTC{runi,2} = newSDMname;
                                            end
                                    end

                                    % save file now that we've got the name.
                                    singleSubGLM.SaveAs(fullfile(Params.ExpNames(expi).FolderPath,'GLM',subGLMfilename));
                                    MDM.SaveAs(subMDMfilename);
                                end
                            end
                            cd(tmpsubfolder);
                        end
                    end
                end
                % if it is the last subject, let's save out the group MDM.
                if mdmgoal ~= 1 && Params.Subs2process(subi) == max(Params.Subs2process)
                    %for subi = 1:length(Params.Subs2process)
                    %    if subi == 1
                    %    tmpsubstring = []; tmpsubstring = ['Sub' num2str(Params.Subs2process(subi))];
                    %    elseif subi > 1
                    %    tmpsubstring = [tmpsubstring '_' ['Sub' num2str(Params.Subs2process(subi))]];
                    %    end
                    %end
                    tmpsubstring = []; tmpsubstring = ['Sub' num2str(Params.Subs2process(1)),'_ThroughTo_Sub' num2str(Params.Subs2process(end))];

                    groupMDMfilename = [];
                    groupMDMfilename = fullfile(Params.MDMLoc(expi).Name,[tmpexpname '_' tmpsubstring '_GroupAnalysis.mdm']);
                    %groupMDM.SaveAs(groupMDMfilename);
                    if Params.CreateGLM == 1
                        % hard-coded parameters.
                        groupMDM.PSCTransformation = 1;

                        % Assumption is that we want RFX.
                        groupMDM.RFX_GLM = 1;

                        %create GLM object.
                        groupRFXGLM = groupMDM.ComputeGLM;

                        % create empty file name.
                        groupGLMfilename = [];

                        % now let's get sub IDs and create a file name.
                        groupGLMfilename=fullfile([tmpexpname '_allsubs_N' num2str(length(Params.Subs2process)) '_PSC_RFX.glm']);

                        % find spaces and replace with underscores.
                        groupGLMfilename(strfind(groupGLMfilename,' ')) = '_';
                        groupGLMfilename(strfind(groupGLMfilename,'__')) = '';

                        % check if there is a GLM folder.
                        if isfolder(fullfile(Params.ExpNames(expi).FolderPath,'GLM')) == 0
                            mkdir(fullfile(Params.ExpNames(expi).FolderPath,'GLM'));
                        end

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
                                    groupMDM.XTC_RTC{runi,1} = newVTCname;
                                    groupMDM.XTC_RTC{runi,2} = newSDMname;
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
                                    groupMDM.XTC_RTC{runi,1} = newVTCname;
                                    groupMDM.XTC_RTC{runi,2} = newSDMname;
                                end
                        end
                        % save file now that we've got the name.
                        groupRFXGLM.SaveAs(fullfile(Params.ExpNames(expi).FolderPath,'GLM',groupGLMfilename));
                        groupMDM.SaveAs(groupMDMfilename);
                    end
                end
            end
        end
    end
end
