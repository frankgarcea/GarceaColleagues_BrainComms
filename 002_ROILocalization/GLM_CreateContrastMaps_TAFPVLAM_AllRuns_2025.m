function [TalPeak] = GLM_CreateContrastMaps_TAFPVLAM_AllRuns_2025

% select a sample VTC
uiwait(msgbox({'Please select a sample VTC'}));
SampleVTC = BVQXfile('*.vtc');

% Select folder where subject GLMs live.
uiwait(msgbox({'Please select the folder where subject GLMs live'}));
GLMDirectory = uigetdir();

% Find all 'glm' files within the folder.
SubGLMDir = dir(fullfile(GLMDirectory,'*glm'));

% Find all 'VMP' files within the folder.
uiwait(msgbox({'Please select the folder where subject VMPs live'}));
VMPDirectory = uigetdir();
SubVMPDir = dir(fullfile(VMPDirectory,'sub*'));

% Select folder where subject GLMs live.
uiwait(msgbox({'Please select the folder where subject LMFG spheres live'}));
MSKdirectory = uigetdir();

% Find all 'glm' files within the folder.
SubMSKDir = dir(fullfile(MSKdirectory,'*msk'));

% Select folder to save out VMPs.
%uiwait(msgbox({'Please select the folder to save out contrast maps.'}));
%VMPOutputDirectory = uigetdir();

expstring = input('What is the name of the experiment?','s');

for subi = 1:size(SubMSKDir)

    % hacky way to get subject ID from the SubGLMDir variable.
    subID = []; subID = SubMSKDir(subi).name(strfind(SubMSKDir(subi).name,'sub'):strfind(SubMSKDir(subi).name,'sub')+6);

    % load in subject MSK file.
    subMSKfile = []; subMSKfile = BVQXfile(fullfile(MSKdirectory,SubMSKDir(subi).name));
    subMSKcoords = subMSKfile.Coords('tal');

    % create subject GLM file name.
    GLMfilename = []; GLMfilename = [expstring '_' subID '_PSC_FFX.glm'];
    % create empty variable and load in subject GLM
    GLM = []; GLM = BVQXfile(fullfile(GLMDirectory,GLMfilename));%SubGLMDir(subi).name));

    % get number of runs.
    NrOfRuns = [];
    NrOfRuns = GLM.NrOfStudies;

    % get number of task predictors (total predictors minus confounds).
    NrOfTaskPredictors = [];
    NrOfTaskPredictors = GLM.NrOfPredictors-GLM.NrOfConfounds;

    % number of unique predictors per run.
    UniquePredictors = [];
    UniquePredictors = NrOfTaskPredictors/NrOfRuns;

    % set up tool contrast vector
    ToolContrastVec = []; PlaceContrastVec = [];
    ToolContrastVec = zeros(UniquePredictors,1);
    PlaceContrastVec = zeros(UniquePredictors,1);

    % create a confound vector (for motion and other params).
    ConfoundVec = [];
    ConfoundVec = zeros(GLM.NrOfConfounds,1);

    % set up 'zerovec' to exclude even/odd runs.
    ZeroVec = [];
    ZeroVec = zeros(UniquePredictors,1);

    % set up predictor name variable.
    PredictorNames = [];

    for condi = 1:UniquePredictors

        PredictorNames{condi,1} = GLM.SubjectPredictors{condi};

        % if this isn't empty -- if animal is in the name and scrambled isn't - we want to know.
        if contains(GLM.SubjectPredictors{condi},'Animal') == 1 && contains(GLM.SubjectPredictors{condi},'Scram') == 0
            PlaceContrastVec(condi,1) = -1;
        end

        % if this isn't empty -- if face is in the name and scrambled isn't - we want to know.
        if contains(GLM.SubjectPredictors{condi},'Face') == 1 && contains(GLM.SubjectPredictors{condi},'Scram') == 0
            PlaceContrastVec(condi,1) = -1;
        end

        % if this isn't empty -- if place is in the name - we want to know.
        if contains(GLM.SubjectPredictors{condi},'Place') == 1 && contains(GLM.SubjectPredictors{condi},'Scram') == 0
            PlaceContrastVec(condi,1) = 1;
        end

        % if this isn't empty -- if tool is in the name and scrambled isn't - we want to know.
        if contains(GLM.SubjectPredictors{condi},'Tool') == 1 && contains(GLM.SubjectPredictors{condi},'Scram') == 0
            PlaceContrastVec(condi,1) = -1;
        end

    end

    % Set the place condition to be equal to the number of non-place conditions
    % modeled in the contrast
    negativegoing = sum(PlaceContrastVec<0); positivegoing = sum(PlaceContrastVec>0);
    %if negativegoing > 0
    totalscore = negativegoing*positivegoing;

    %
    positivescoreval = totalscore/size(find(PlaceContrastVec>0),1);
    negativescoreval = (totalscore/size(find(PlaceContrastVec<0),1))*-1;
    
    %
    PlaceContrastVec(PlaceContrastVec==1) = positivescoreval;
    PlaceContrastVec(PlaceContrastVec==-1) = negativescoreval;%sum(ToolContrastVec==-1);

    % set up predictor name variable.
    PredictorNames = [];

    for condi = 1:UniquePredictors

        PredictorNames{condi,1} = GLM.SubjectPredictors{condi};

        % if this isn't empty -- if animal is in the name and scrambled isn't - we want to know.
        if contains(GLM.SubjectPredictors{condi},'Animal') == 1 && contains(GLM.SubjectPredictors{condi},'Scram') == 0
            ToolContrastVec(condi,1) = -1;
        end

        % if this isn't empty -- if face is in the name and scrambled isn't - we want to know.
        if contains(GLM.SubjectPredictors{condi},'Face') == 1 && contains(GLM.SubjectPredictors{condi},'Scram') == 0
            ToolContrastVec(condi,1) = -1;
        end

        % if this isn't empty -- if place is in the name - we want to know.
        if contains(GLM.SubjectPredictors{condi},'Place') == 1 && contains(GLM.SubjectPredictors{condi},'Scram') == 0
            ToolContrastVec(condi,1) = -1;
        end

        % if this isn't empty -- if tool is in the name and scrambled isn't - we want to know.
        if contains(GLM.SubjectPredictors{condi},'Tool') == 1 && contains(GLM.SubjectPredictors{condi},'Scram') == 0
            ToolContrastVec(condi,1) = 1;
        end

    end

    % Set the tool condition to be equal to the number of non-tool conditions
    % modeled in the contrast
    negativegoing = sum(ToolContrastVec<0); positivegoing = sum(ToolContrastVec>0);
    %if negativegoing > 0
    totalscore = negativegoing*positivegoing;

    %
    positivescoreval = totalscore/size(find(ToolContrastVec>0),1);
    negativescoreval = (totalscore/size(find(ToolContrastVec<0),1))*-1;
    %elseif negativegoing == 0;
    %positivescoreval = 1;
    %negativescoreval = 0;
    %end


    %
    ToolContrastVec(ToolContrastVec==1) = positivescoreval;
    ToolContrastVec(ToolContrastVec==-1) = negativescoreval;%sum(ToolContrastVec==-1);

    %     if sum(ToolContrastVec) == 0
    %         % Let's create our predictor vector based on the number of runs.
    %         switch NrOfRuns
    %             case 1
    %                 %
    %                 ToolContrastVecOdd = [ToolContrastVec;ConfoundVec];
    %
    %             case 2
    %                 %
    %                 ToolContrastVecEven = [ZeroVec;ToolContrastVec;ConfoundVec];
    %                 ToolContrastVecOdd = [ToolContrastVec;ZeroVec;ConfoundVec];
    %
    %                 %
    %             case 3
    %                 %
    %                 ToolContrastVecEven = [ZeroVec;ToolContrastVec;ZeroVec;ConfoundVec];
    %                 ToolContrastVecOdd = [ToolContrastVec;ZeroVec;ToolContrastVec;ConfoundVec];
    %                 %
    %             case 4
    %                 %
    %                 ToolContrastVecEven = [ZeroVec;ToolContrastVec;ZeroVec;ToolContrastVec;ConfoundVec];
    %                 ToolContrastVecOdd = [ToolContrastVec;ZeroVec;ToolContrastVec;ZeroVec;ConfoundVec];
    %                 %
    %             case 5
    %                 %
    %                 ToolContrastVecEven = [ZeroVec;ToolContrastVec;ZeroVec;ToolContrastVec;ZeroVec;ConfoundVec];
    %                 ToolContrastVecOdd = [ToolContrastVec;ZeroVec;ToolContrastVec;ZeroVec;ToolContrastVec;ConfoundVec];
    %                 %
    %             case 6
    %                 %
    %                 ToolContrastVecEven = [ZeroVec;ToolContrastVec;ZeroVec;ToolContrastVec;ZeroVec;ToolContrastVec;ConfoundVec];
    %                 ToolContrastVecOdd = [ToolContrastVec;ZeroVec;ToolContrastVec;ZeroVec;ToolContrastVec;ZeroVec;ConfoundVec];
    %                 %
    %             case 7
    %                 %
    %                 ToolContrastVecEven = [ZeroVec;ToolContrastVec;ZeroVec;ToolContrastVec;ZeroVec;ToolContrastVec;ZeroVec;ConfoundVec];
    %                 ToolContrastVecOdd = [ToolContrastVec;ZeroVec;ToolContrastVec;ZeroVec;ToolContrastVec;ZeroVec;ToolContrastVec;ConfoundVec];
    %                 %
    %             case 8
    %                 %
    %                 ToolContrastVecEven = [ZeroVec;ToolContrastVec;ZeroVec;ToolContrastVec;ZeroVec;ToolContrastVec;ZeroVec;ToolContrastVec;ConfoundVec];
    %                 ToolContrastVecOdd = [ToolContrastVec;ZeroVec;ToolContrastVec;ZeroVec;ToolContrastVec;ZeroVec;ToolContrastVec;ZeroVec;ConfoundVec];
    %                 %
    %         end

    % now let's concatenate our confound vector (zeros) with the tool
    % predictor vector. first, let's repmat the vector N number of times
    % depending on the number of runs. Then let's append the ConfoundVec to the
    % end of it to make a long vector that is equal to GLM.NrOfPredictors
    ToolContrastVecAllRuns = [repmat(ToolContrastVec,NrOfRuns,1);ConfoundVec];
    PlaceContrastVecAllRuns = [repmat(PlaceContrastVec,NrOfRuns,1);ConfoundVec];

    %if NrOfRuns > 1
        % bark at the user if these numbers aren't identical.
    %    if GLM.NrOfPredictors ~= length(ToolContrastVecEven)
    %        disp('YOUR TOOLCONTRASTVECEVEN IS WRONG')
    %        pause
    %    end

        % bark at the user if these numbers aren't identical.
        if GLM.NrOfPredictors ~= length(ToolContrastVecAllRuns)
            disp('YOUR TOOLCONTRASTVECALLRUNS IS WRONG')
            pause
        end
    %end

    % bark at the user if these numbers aren't identical.
    %if GLM.NrOfPredictors ~= length(ToolContrastVecOdd)
    %    disp('YOUR TOOLCONTRASTVECODD IS WRONG. QUIT THIS SCRIPT & TALK TO FRANK.')
    %    pause
    %end

    NrOfRowsToBlank = size(ToolContrastVec,1);
    for runi = 1:NrOfRuns
        RemoveRun = []; RemoveRun = ToolContrastVecAllRuns;
        if runi == 1
            % get our data we want to remove before localization.
            RemoveRun(1:NrOfRowsToBlank) = 0;
            localizemap = GLM.FFX_tMap(RemoveRun);
            voxels = localizemap.Map(1).VMPData(subMSKfile.Mask==1);
            voxind = find(voxels==max(voxels));
            if size(voxind,1) > 1
                disp('check this out');
                pause
            end
            TalPeak.Sub(subi).Run(runi).Coordinates(1:3) = subMSKcoords(voxind,:);
            TalPeak.Sub(subi).Run(runi).Beta =  voxels(voxind);
            % now make independent VOI and MSK
            tempIndependentVOI = BVQXfile('new:voi');
            tempIndependentVOI.AddSphericalVOI(TalPeak.Sub(subi).Run(runi).Coordinates(1:3),3);
            tempIndependentMSK = tempIndependentVOI.CreateMSK(SampleVTC);

            % now get the data to extract betas after localization.
            TestRun = ToolContrastVecAllRuns;
            TestRun(NrOfRowsToBlank+1:end) = 0;
            TestMap = GLM.FFX_tMap(TestRun);
            TalPeak.Sub(subi).Betas(1,runi) = mean(TestMap.Map(1).VMPData(tempIndependentMSK.Mask==1));

            % new bit to get the place values from the tempIndependentMSK
            % defined from the tool effect.
            VMPSubID = SubMSKDir(subi).name(1:7);
            SubSpecificVMPPath = dir(fullfile(VMPDirectory,VMPSubID,'*All*.vmp'));
            SubSpecificVMP = BVQXfile(fullfile(SubSpecificVMPPath(1).folder,SubSpecificVMPPath(1).name));
            TalPeak.Sub(subi).PlaceBetasNew(1,runi) = mean(SubSpecificVMP.Map(1).VMPData(tempIndependentMSK.Mask==1));

            % now do the same for places.
            TestRun = PlaceContrastVecAllRuns;
            TestRun(NrOfRowsToBlank+1:end) = 0;
            TestMap = GLM.FFX_tMap(TestRun);
            TalPeak.Sub(subi).ControlBetas(1,runi) = mean(TestMap.Map(1).VMPData(tempIndependentMSK.Mask==1));
        elseif runi > 1
            RowsToRemove = (NrOfRowsToBlank*runi)-(NrOfRowsToBlank-1):(NrOfRowsToBlank*runi);
            RemoveRun(RowsToRemove) = 0;
            %RemoveRun(1:NrOfRowsToBlank) = 0;
            localizemap = GLM.FFX_tMap(RemoveRun);
            voxels = localizemap.Map(1).VMPData(subMSKfile.Mask==1);
            voxind = find(voxels==max(voxels));
            if size(voxind,1) > 1
                disp('check this out');
                pause
            end
            TalPeak.Sub(subi).Run(runi).Coordinates(1:3) = subMSKcoords(voxind,:);
            TalPeak.Sub(subi).Run(runi).Beta =  voxels(voxind);
            % now make independent VOI and MSK
            tempIndependentVOI = BVQXfile('new:voi');
            tempIndependentVOI.AddSphericalVOI(TalPeak.Sub(subi).Run(runi).Coordinates(1:3),3);
            tempIndependentMSK = tempIndependentVOI.CreateMSK(SampleVTC);

            %TestRun = ToolContrastVecAllRuns;
            RowsToKeep = (NrOfRowsToBlank*runi)-(NrOfRowsToBlank-1):(NrOfRowsToBlank*runi);
            TestRun = [repmat(zeros(size(ToolContrastVec,1),1),NrOfRuns,1);ConfoundVec];
            TestRun(RowsToKeep) = ToolContrastVec;
            TestMap = GLM.FFX_tMap(TestRun);
            TalPeak.Sub(subi).Betas(1,runi) = mean(TestMap.Map(1).VMPData(tempIndependentMSK.Mask==1));

            TestRun = [repmat(zeros(size(PlaceContrastVec,1),1),NrOfRuns,1);ConfoundVec];
            TestRun(RowsToKeep) = PlaceContrastVec;
            TestMap = GLM.FFX_tMap(TestRun);
            TalPeak.Sub(subi).ControlBetas(1,runi) = mean(TestMap.Map(1).VMPData(tempIndependentMSK.Mask==1));

            % new bit to get the place values from the tempIndependentMSK
            % defined from the tool effect.
            VMPSubID = SubMSKDir(subi).name(1:7);
            SubSpecificVMPPath = dir(fullfile(VMPDirectory,VMPSubID,'*All*.vmp'));
            SubSpecificVMP = BVQXfile(fullfile(SubSpecificVMPPath(1).folder,SubSpecificVMPPath(1).name));
            TalPeak.Sub(subi).PlaceBetasNew(1,runi) = mean(SubSpecificVMP.Map(1).VMPData(tempIndependentMSK.Mask==1));

        end
    end
    % get final mean beta.
    TalPeak.FinalBeta(subi,1) = mean(TalPeak.Sub(subi).Betas);
    TalPeak.FinalControlBeta(subi,1) = mean(TalPeak.Sub(subi).ControlBetas);
    TalPeak.FinalPlaceBetaNew(subi,1) = mean(TalPeak.Sub(subi).PlaceBetasNew);
    %elseif sum(ToolContrastVec) ~=0
    %    disp(fprintf('YOUR CONTRAST VALUES FOR %s ARE NOT BALANCED.', subID));
    %    pause(3);
    %end
    clear evenmap oddmap mapopts subID ToolContrastVecEven ToolContrastVecOdd ToolContrastVecAllRuns
end