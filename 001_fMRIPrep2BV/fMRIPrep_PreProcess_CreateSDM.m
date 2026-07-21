function [Params] = fMRIPrep_PreProcess_CreateSDM(Params)
%try
% Create SDMs in VTC Data Folder.
if Params.CreateSDM
    % If we are working on SDM creation without prior moving of func data,
    % then we need user input.
    if Params.MovePRT == 0
        % Let's get the func folder in the instance in which the user does
        % not indicate they want to move func data.
        promptSDMgoal = {'Do you want to create SDMs from VTCs in an already-created functional folder?'};
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
                uiwait(msgbox({['Please select the previously created VTC folder where the ' Params.ExpNames(expi).Name ' processed VTCs live.']}));
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

    %% Main loop doing SDM creation.
    for expi = 1:size(Params.ExpNames,2)
        tmpexpname = []; tmpexpname = Params.ExpNames(expi).Name;
        % if the experiment does not have 'Rest' in the name, we proceed.
        if contains(lower(tmpexpname),'rest') == 0
            % let's first cd into the processed data folder.
            cd(Params.ExpNames(expi).FolderPath);
            %% then let's search for our PRT directory
            tmpfoldercontent = []; tmpfoldercontent = dir(Params.ExpNames(expi).FolderPath);
            % loop through contents and find folder with PRT in name.
            for folderi = 1:size(tmpfoldercontent,1)
                if contains(tmpfoldercontent(folderi).name,[Params.ExpNames(expi).Name '_PRT'])
                    Params.PRT(expi).FolderStorage = fullfile(Params.ExpNames(expi).FolderPath,tmpfoldercontent(folderi).name);
                end
            end
            % Tell the user if we can't find a PRT folder.
            if isempty(Params.PRT(expi).FolderStorage) == 1
                uiwait(msgbox({['You do not have a PRT folder in the ' Params.ExpNames(expi).Name ' folder. Fix this ASAP.']}));
                return
            end
            %% Now that we have PRTs can can copy them into each sub's run-level VTC folder.
            % now let's loop through subjects in the functional directory.
            for subi = 1:length(Params.Subs2process)
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
                tmpsubfolder = []; tmpsubfolder = fullfile(Params.ExpNames(expi).FolderPath,Params.VTC(expi).FolderName,subID);
                cd(tmpsubfolder);

                % get session information.
                sessiondir = dir('*ses*');

                % let's loop through session information to get the anatomical files.
                % we'll then use this to copy the data to the process data folder.
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
                            % Run name may not be the same as the run number from list iterator
                            % Extract Run name
                            tmprunfolder = []; tmprunfolder = fullfile(sessionID,rundirectory(runi).name);
                            runID = str2double(extract(rundirectory(runi).name, digitsPattern));
                            cd(tmprunfolder);
                            % If we haven't moved prior functional data then we
                            % will not know these parameters, which are key for
                            % SDM creation.
                            % Do this for each run. Can't assume each run is same length/volume.
                            % so we compute it from the data.
                            vtcdir = dir('*.vtc');
                            if isempty(vtcdir)
                                error('No VTC found.');
                            elseif length(vtcdir) > 1
                                warning('Multiple VTCs found. Using first.');
                            end
                            tmpvtcpath = fullfile(vtcdir(1).name);
                            tmpvtc = BVQXfile(tmpvtcpath);
                            Params.fMRIParams.nvol = size(tmpvtc.VTCData,1);
                            % throw out first condition (0 = no).
                            Params.fMRIParams.rcond = 0;
                            % TR length in ms.
                            Params.fMRIParams.prtr = tmpvtc.TR;
                            clear vtcdir tmpvtcpath tmpvtc

                            % now we find and copy PRTs from the storage folder to
                            % this VTC folder.

                            tmpPRTname = []; tmpPRTname = [tmpexpname '_' subID '_' sessionID '_Run' num2str(runID) '.prt'];
                            %tempPRTdir = dir(fullfile(Params.PRT(expi).FolderStorage,[subID,sessionID,rundirectory(runi).name]));
                            copyfile(fullfile(Params.PRT(expi).FolderStorage,tmpPRTname),fullfile(Params.ExpNames(expi).FolderPath,Params.VTC(expi).FolderName,subID,sessionID,rundirectory(runi).name,tmpPRTname),'f');
                            %copyfile(fullfile(Params.PRT(expi).FolderStorage,tmpPRTname),fullfile(Params.ExpNames(expi).FolderPath,Params.VTC(expi).FolderName,subID,sessionID,rundirectory(runi).name),'f');

                            % get a list of VTCs and PRTs in this folder. There
                            % should only be one of each.
                            tmpprtdir = []; tmpprtdir = dir('*.prt');
                            if isempty(tmpprtdir)
                                error('No PRT found.');
                            elseif length(tmpprtdir) > 1
                                warning('Multiple PRTs found. Using first.');
                            end
                            tmpvtcdir = []; tmpvtcdir = dir('*.vtc');
                            if isempty(tmpvtcdir)
                                error('No PRT found.');
                            elseif length(tmpvtcdir) > 1
                                warning('Multiple VTCs found. Using first.');
                            end
                            % now open PRT and VTC in the current folder
                            tmpprt = BVQXfile(tmpprtdir(1).name);

                            % link the PRT to the VTC and save it out then clear!
                            tmpvtc = BVQXfile(tmpvtcdir(1).name);
                            tmpvtc.NameOfLinkedPRT = tmpprtdir(1).name;
                            tmpvtc.SaveAs(tmpvtcdir(1).name);
                            clear tmpvtc

                            tmpsdm = tmpprt.CreateSDM(Params.fMRIParams);
                            % create a temporary variable to house fMRI SDMs.
                            if runi == 1; fMRISDMStruct = []; end
                            % accumulate SDMs here.
                            fMRISDMStruct.Run(runi).tmpsdm = tmpsdm;
                            % get file name to save out SDM.
                            [~,tmpfilename,~] = fileparts(tmpprtdir(1).name);
                            % this will get overwritten later but save it for now.
                            tmpsdm.SaveAs([tmpfilename '.sdm']);

                            %% now that we have an fMRI predictor SDM created, let's get our confound predictors.
                            % let's find the TSV file in the current directory
                            runtsvdir = []; runtsvdir = dir('*tsv*');
                            if isempty(runtsvdir)
                                error('No PRT found.');
                            elseif length(runtsvdir) > 1
                                warning('Multiple VTCs found. Using first.');
                            end
                            tmprunconfounds = runtsvdir(1).name;
                            %[~,NameFile,~] = fileparts(runtsvdir(1).name);
                            % create empty runconfound variable
                            runconfounds = [];

                            % use tsvread to import tsvfile
                            [runconfounds,header] = fMRIPrep_PreProcess_ReadTSV(tmprunconfounds);

                            % bring up a GUI to select the confounds.
                            if exist('keepForAllRuns') == 0
                                [selectedVariables, keepForAllRuns] = SelectConfoundRegressorsGUI(header);
                            elseif keepForAllRuns ~=1
                                [selectedVariables, keepForAllRuns] = SelectConfoundRegressorsGUI(header);
                            end

                            % get raw values
                            rawconfounds = runconfounds{1, 1};

                            % get rid of first row, which is header info.
                            rawconfounds(1,:)= [];

                            % header info stored here.
                            headerinfo = runconfounds{1, 2};

                            % create new variable that is empty.
                            tmpsdmmatrix = [];

                            headervariables = selectedVariables;%{'trans_x','trans_y','trans_z','rot_x','rot_y','rot_z'};%'dvars','framewise_displacement'};
                            %headervariables = {'trans_x','trans_y','trans_z','rot_x','rot_y','rot_z','dvars','framewise_displacement','cosine00','white_matter','csf'};
                            %headervariables = {'cosine00','trans_x','trans_y','trans_z','rot_x','rot_y','rot_z'}; %,'framewise_displacement','dvars'}; % cosine00
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
                            if sum(sum(isnan(tmpsdmmatrix))) ~=0
                                %warning('NaNs found in your SDM matrix.');
                                tmpsdmmatrix(isnan(tmpsdmmatrix)) = 0;
                            end

                            % Ask user if they want to do spike regression.
                            fdIndex = find(strcmp(header,'framewise_displacement'));

                            % if keep for all runs exists and equals 1 and
                            % if fdIndex is not empty, and if
                            % DoSpikeRegression does not exist, then we
                            % want to ask the user if they want to do spike
                            % regression.
                            if exist('keepForAllRuns') == 1 && keepForAllRuns == 1 && isempty(fdIndex) == 0 && exist('DoSpikeRegression') == 0
                                promptSpikeRegressiongoal = {'Do you want to do spike regression?','If so, what is the FD value to censor'};
                                dlgtitle = 'Spike Regression - User Input Required';
                                dims = [1 100];
                                definputexpnames = {'Yes (1) or No (0)','Enter FD amount (0.5 is common)'};
                                SpikeRegressionInfo = inputdlg(promptSpikeRegressiongoal,dlgtitle,dims,definputexpnames);
                                DoSpikeRegression = str2double(SpikeRegressionInfo{1});
                            end
                            if exist('DoSpikeRegression') == 1 && DoSpikeRegression == 1 && isempty(fdIndex) == 0
                                %fdIndex = find(strcmp(header,'framewise_displacement'));
                                FDThreshold = str2double(SpikeRegressionInfo{2});
                                if isempty(fdIndex) == 0
                                    if ~isempty(fdIndex)
                                        FDVector = rawconfounds(:,fdIndex);
                                        % ensure numeric
                                        FDVector = double(FDVector);
                                        % replace NaNs
                                        FDVector(isnan(FDVector)) = 0;
                                        % identify bad TRs
                                        badTRs = find(FDVector > FDThreshold);
                                    else
                                        badTRs = [];
                                    end
                                    propbadTRs = ceil((length(badTRs)/size(tmpsdmmatrix,1))*100);
                                    disp(['FYI: You are censuring ' num2str(length(badTRs)) ' volumes (' num2str(propbadTRs)  '%) of ' subID '''s ' tmpexpname ' run ' num2str(runi)]);
                                    spikeRegressors = zeros(size(tmpsdmmatrix,1), length(badTRs));
                                    for spikei = 1:length(badTRs)
                                        spikeRegressors(badTRs(spikei), spikei) = 1;
                                    end
                                end
                                tmpsdmmatrix = [tmpsdmmatrix spikeRegressors];
                            end
                            %FDColumn = find(contains(variableorder.headername,'framewise_displacement'));
                            %SpikeRegressors = abs(tmpsdmmatrix(:,FDColumn)) > .5;
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
                            if DoSpikeRegression == 1
                                for spikei = 1:length(badTRs)
                                    TempSDM.PredictorNames{end+1} = ...
                                        sprintf('FDSpike_TR_%03d', badTRs(spikei));
                                end
                            end
                            TempSDM.PredictorColors = colorconditions;
                            TempSDM.NrOfPredictors = size(TempSDM.PredictorNames);%size(TempSDM.PredictorColors,1);
                            %TempSDM.SaveAs([taskID '_Sub' subID '_Run' runID '_SCCTBL_3DMC_FD_DVARS.sdm']);
                            %outputname = [tmpfilename '_ConfoundRegressors.sdm'];
                            %TempSDM.SaveAs(outputname);

                            % now we combine fMRI and confounds and save out SDM.
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
                            fMRISDM.SaveAs([tmpfilename '.sdm']);
                            % before ending the run cd back here.
                            cd(Params.ExpNames(expi).FolderPath);
                            cd(fullfile(tmpsubfolder));
                        end
                    end
                end
            end
        end
    end
end
% if there's an error let the user know.
% catch
%     uiwait(msgbox({'There was an error in the CreateSDM code.'}));
%     cd(Params.HomeDirectory);
% end
% end