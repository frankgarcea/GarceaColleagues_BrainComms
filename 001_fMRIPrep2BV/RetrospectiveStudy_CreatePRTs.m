function [PRT] = RetrospectiveStudy_CreatePRTs


%% Gather basic information needed to begin PRT creation.
prompt = {'Did you drop volumes in your fMRI anaylsis?','Enter the subject IDs that you want to analyze.','Right Hand Movements','Right Foot Movements','Left Hand Movements', 'Left Foot Movements', 'Tongue Movements','Boston Naming','Verb Generation','VF Category','VF Letters','Definition Naming','Picture Naming','Sentence Completion'};
dlgtitle = 'User Provided PRT Input Parameters';
dims = [1 75];
definput = {'Put 0 if no; otherwise provide # of vols dropped.','E.g., 1, 3, 5, 8, or 1:15,22,45:50','Yes (1) or No (0)','Yes (1) or No (0)','Yes (1) or No (0)','Yes (1) or No (0)','Yes (1) or No (0)','Yes (1) or No (0)','Yes (1) or No (0)','Yes (1) or No (0)','Yes (1) or No (0)','Yes (1) or No (0)','Yes (1) or No (0)','Yes (1) or No (0)'};
answer = inputdlg(prompt,dlgtitle,dims,definput);

% Basic experimental parameters that will route future analysis.
PRT.Subs2process = str2num(answer{2});
PRT.Right.HandMove.Create = str2double(answer{3});
PRT.Right.FootMove.Create = str2double(answer{4});
PRT.Left.HandMove.Create = str2double(answer{5});
PRT.Left.FootMove.Create = str2double(answer{6});
PRT.TongueMove.Create = str2double(answer{7});
PRT.BostonNaming.Create = str2double(answer{8});
PRT.VerbGeneration.Create = str2double(answer{9});
PRT.VFCategory.Create = str2double(answer{10});
PRT.VFLetters.Create = str2double(answer{11});
PRT.DefinitionNaming.Create = str2double(answer{12});
PRT.PictureNaming.Create = str2double(answer{13});
PRT.SentenceCompletion.Create = str2double(answer{14});

% onset and offset times are uniform within a task
% typically it is the case that odd rows are resting phases (baseline).
% task comes on at the even rows/phases.


% If you want to drop the first N number of volumes, use this variable.
% If you don't want to drop N volumes, keep the variable set to 0.
PRT.RemoveFirstNVolumes = str2num(answer{1});

%% Motor Tasks.
%% Create Onset and Offset times for left hand move.
PRT.Left.HandMove.Time = [
    20	50
    70	100
    120	150];

% Baseline
PRT.Left.HandMove.Baseline = [0	20
    50	70
    100	120
    150	170];

%% Create Onset and Offset times for right hand move.
PRT.Right.HandMove.Time = [
    20	50
    70	100
    120	150];

% Baseline
PRT.Right.HandMove.Baseline = [0	20
    50	70
    100	120
    150	170];

%% Create Onset and Offset times for left foot move.
PRT.Left.FootMove.Time = [
    20	50
    70	100
    120	150];

% Baseline
PRT.Left.FootMove.Baseline = [0	20
    50	70
    100	120
    150	170];

%% Create Onset and Offset times for right foot move.
PRT.Right.FootMove.Time = [
    20	50
    70	100
    120	150];

% Baseline
PRT.Right.FootMove.Baseline = [0	20
    50	70
    100	120
    150	170];

%% Create Onset and Offset times for tongue movements.
PRT.TongueMove.Time = [
    20	50
    70	100
    120	150];

% Baseline
PRT.TongueMove.Baseline = [0	20
    50	70
    100	120
    150	170];

%% Language Tasks
% Create Onset and Offset times for Boston Naming Test.
PRT.BostonNaming.Time = [30	60
    90	120
    150	180];

% Baseline
PRT.BostonNaming.Baseline = [0	30
    60	90
    120	150
    180	210];

% Create Onset and Offset times for the Verb Generation Test.
PRT.VerbGeneration.Time = [30	60
    90	120
    150	180];

% Baseline
PRT.VerbGeneration.Baseline = [0	30
    60	90
    120	150
    180	210];

% Create Onset and Offset times for the Verbal Fluency Category Test.
PRT.VFCategory.Time = [30	60
    90	120
    150	180];

% Baseline
PRT.VFCategory.Baseline = [0	30
    60	90
    120	150
    180	210];

% Create Onset and Offset times for the Verbal Fluency Letter Test.
PRT.VFLetters.Time = [30	60
    90	120
    150	180];

% Baseline
PRT.VFLetters.Baseline = [0	30
    60	90
    120	150
    180	210];

% Create Onset and Offset times for the Definition Naming Test.
PRT.DefinitionNaming.Time = [20	54
    74	108
    128	162
    182	216];

% Baseline
PRT.DefinitionNaming.Baseline = [0	20
    54	74
    108	128
    162	182
    216	236];

% Create Onset and Offset times for the Picture Naming Test.
PRT.PictureNaming.Time = [20	50
    70	100
    120	150];

PRT.PictureNaming.Baseline = [0	20
    50	70
    100	120
    150	170];

% Create Onset and Offset times for the Picture Naming Test.
PRT.SentenceCompletion.Time = [20	40
60	80
100	120
140	160
180	200
220	240];

PRT.SentenceCompletion.Baseline = [0	20
40	60
80	100
120	140
160	180
200	220
240	260];

%% now loop through subjects and create PRTs.
for subi = 1:length(PRT.Subs2process)
    % let's get the sub ID variable.
    subID = [];
    if PRT.Subs2process(subi) < 10
        subID = ['sub-00' num2str(PRT.Subs2process(subi))];
    elseif PRT.Subs2process(subi) > 9 && PRT.Subs2process(subi) < 99
        subID = ['sub-0' num2str(PRT.Subs2process(subi))];
    elseif PRT.Subs2process(subi) > 99
        subID = ['sub-' num2str(PRT.Subs2process(subi))];
    end

    % now let's loop through tests and create single-sub PRTs.
    if isfolder(subID) == 0
        mkdir(subID);
    end
    % get path to save PRTs.
    PRT.PRTSavePath = fullfile(cd,subID);

    % if user indicated they want to create a RH move PRT.
    if PRT.Right.HandMove.Create == 1
        PRT.RemoveFirstNSeconds = [];
        % TR length is hard-coded based off feedback from Madalina.
        PRT.RemoveFirstNSeconds = PRT.RemoveFirstNVolumes * 2;
        tmpprt = [];
        tmpprt = BVQXfile('new:prt');
        % main task 'on'
        tmpprt.Cond(1).ConditionName = {'RightHandMove'};
        tmpprt.Cond(1).NrOfOnOffsets = size(PRT.Right.HandMove.Time,1);
        tmpprt.Cond(1).OnOffsets = (PRT.Right.HandMove.Time-PRT.RemoveFirstNSeconds)*1000;
        tmpprt.Cond(1).Weights = ones(size(PRT.Right.HandMove.Time,1),1);
        tmpprt.Cond(1).Color = [0 255 0];

        % 'off' portion of the run.
        tmpprt.Cond(2).ConditionName = {'ControlBlock'};
        tmpprt.Cond(2).NrOfOnOffsets = size(PRT.Right.HandMove.Baseline,1);
        tmpprt.Cond(2).OnOffsets = (PRT.Right.HandMove.Baseline-PRT.RemoveFirstNSeconds)*1000;
        if tmpprt.Cond(2).OnOffsets(1,1) < 0; tmpprt.Cond(2).OnOffsets(1,1) = 0; end
        tmpprt.Cond(2).Weights = ones(size(PRT.Right.HandMove.Baseline,1),1);
        tmpprt.Cond(2).Color = [255 0 0];

        tmpprt.SaveAs(fullfile(PRT.PRTSavePath,[subID '_RightHandMove_Run1.prt']));
    end

    % if user indicated they want to create a RF move PRT.
    if PRT.Right.FootMove.Create == 1
        PRT.RemoveFirstNSeconds = [];
        % TR length is hard-coded based off feedback from Madalina.
        PRT.RemoveFirstNSeconds = PRT.RemoveFirstNVolumes * 2000;
        tmpprt = [];
        tmpprt = BVQXfile('new:prt');
        tmpprt.Cond(1).ConditionName = {'RightFootMove'};
        tmpprt.Cond(1).NrOfOnOffsets = size(PRT.Right.FootMove.Time,1);
        tmpprt.Cond(1).OnOffsets = (PRT.Right.FootMove.Time-PRT.RemoveFirstNSeconds)*1000;
        tmpprt.Cond(1).Weights = ones(size(PRT.Right.FootMove.Time,1),1);
        tmpprt.Cond(1).Color = [0 255 0];

        % 'off' portion of the run.
        tmpprt.Cond(2).ConditionName = {'ControlBlock'};
        tmpprt.Cond(2).NrOfOnOffsets = size(PRT.Right.FootMove.Baseline,1);
        tmpprt.Cond(2).OnOffsets = (PRT.Right.FootMove.Baseline-PRT.RemoveFirstNSeconds)*1000;
        if tmpprt.Cond(2).OnOffsets(1,1) < 0; tmpprt.Cond(2).OnOffsets(1,1) = 0; end
        tmpprt.Cond(2).Weights = ones(size(PRT.Right.FootMove.Baseline,1),1);
        tmpprt.Cond(2).Color = [255 0 0];

        tmpprt.SaveAs(fullfile(PRT.PRTSavePath,[subID '_RightFootMove_Run1.prt']));
    end

    % if user indicated they want to create a LF move PRT.
    if PRT.Left.FootMove.Create == 1
        PRT.RemoveFirstNSeconds = [];
        % TR length is hard-coded based off feedback from Madalina.
        PRT.RemoveFirstNSeconds = PRT.RemoveFirstNVolumes * 2000;
        tmpprt = [];
        tmpprt = BVQXfile('new:prt');
        tmpprt.Cond(1).ConditionName = {'LeftFootMove'};
        tmpprt.Cond(1).NrOfOnOffsets = size(PRT.Left.FootMove.Time,1);
        tmpprt.Cond(1).OnOffsets = (PRT.Left.FootMove.Time-PRT.RemoveFirstNSeconds)*1000;
        tmpprt.Cond(1).Weights = ones(size(PRT.Left.FootMove.Time,1),1);
        tmpprt.Cond(1).Color = [0 255 0];

        % 'off' portion of the run.
        tmpprt.Cond(2).ConditionName = {'ControlBlock'};
        tmpprt.Cond(2).NrOfOnOffsets = size(PRT.Left.FootMove.Baseline,1);
        tmpprt.Cond(2).OnOffsets = (PRT.Left.FootMove.Baseline-PRT.RemoveFirstNSeconds)*1000;
        if tmpprt.Cond(2).OnOffsets(1,1) < 0; tmpprt.Cond(2).OnOffsets(1,1) = 0; end
        tmpprt.Cond(2).Weights = ones(size(PRT.Left.FootMove.Baseline,1),1);
        tmpprt.Cond(2).Color = [255 0 0];

        tmpprt.SaveAs(fullfile(PRT.PRTSavePath,[subID '_LeftFootMove_Run1.prt']));
    end

    % if user indicated they want to create a LH move PRT.
    if PRT.Left.HandMove.Create == 1
        PRT.RemoveFirstNSeconds = [];
        % TR length is hard-coded based off feedback from Madalina.
        PRT.RemoveFirstNSeconds = PRT.RemoveFirstNVolumes * 2000;
        tmpprt = [];
        tmpprt = BVQXfile('new:prt');
        tmpprt.Cond(1).ConditionName = {'LeftHandMove'};
        tmpprt.Cond(1).NrOfOnOffsets = size(PRT.Left.HandMove.Time,1);
        tmpprt.Cond(1).OnOffsets = (PRT.Left.HandMove.Time-PRT.RemoveFirstNSeconds)*1000;
        tmpprt.Cond(1).Weights = ones(size(PRT.Left.HandMove.Time,1),1);
        tmpprt.Cond(1).Color = [0 255 0];

        % 'off' portion of the run.
        tmpprt.Cond(2).ConditionName = {'ControlBlock'};
        tmpprt.Cond(2).NrOfOnOffsets = size(PRT.Left.HandMove.Baseline,1);
        tmpprt.Cond(2).OnOffsets = (PRT.Left.HandMove.Baseline-PRT.RemoveFirstNSeconds)*1000;
        if tmpprt.Cond(2).OnOffsets(1,1) < 0; tmpprt.Cond(2).OnOffsets(1,1) = 0; end
        tmpprt.Cond(2).Weights = ones(size(PRT.Left.HandMove.Baseline,1),1);
        tmpprt.Cond(2).Color = [255 0 0];

        tmpprt.SaveAs(fullfile(PRT.PRTSavePath,[subID '_LeftHandMove_Run1.prt']));
    end

    % if user indicated they want to create a Tongue move PRT.
    if PRT.TongueMove.Create == 1
        PRT.RemoveFirstNSeconds = [];
        % TR length is hard-coded based off feedback from Madalina.
        PRT.RemoveFirstNSeconds = PRT.RemoveFirstNVolumes * 2000;
        tmpprt = [];
        tmpprt = BVQXfile('new:prt');
        tmpprt.Cond(1).ConditionName = {'TongueMove'};
        tmpprt.Cond(1).NrOfOnOffsets = size(PRT.TongueMove.Time,1);
        tmpprt.Cond(1).OnOffsets = (PRT.TongueMove.Time-PRT.RemoveFirstNSeconds)*1000;
        tmpprt.Cond(1).Weights = ones(size(PRT.TongueMove.Time,1),1);
        tmpprt.Cond(1).Color = [0 255 0];

        % 'off' portion of the run.
        tmpprt.Cond(2).ConditionName = {'ControlBlock'};
        tmpprt.Cond(2).NrOfOnOffsets = size(PRT.TongueMove.Baseline,1);
        tmpprt.Cond(2).OnOffsets = (PRT.TongueMove.Baseline-PRT.RemoveFirstNSeconds)*1000;
        if tmpprt.Cond(2).OnOffsets(1,1) < 0; tmpprt.Cond(2).OnOffsets(1,1) = 0; end
        tmpprt.Cond(2).Weights = ones(size(PRT.TongueMove.Baseline,1),1);
        tmpprt.Cond(2).Color = [255 0 0];

        tmpprt.SaveAs(fullfile(PRT.PRTSavePath,[subID '_TongueMove_Run1.prt']));
    end


    %% Language Tasks
    % if user indicated they want to create a Boston Naming PRT.
    if PRT.BostonNaming.Create == 1
        PRT.RemoveFirstNSeconds = [];
        % TR length is hard-coded based off feedback from Madalina.
        PRT.RemoveFirstNSeconds = PRT.RemoveFirstNVolumes * 3000;
        tmpprt = [];
        tmpprt = BVQXfile('new:prt');
        tmpprt.Cond(1).ConditionName = {'BostonNaming'};
        tmpprt.Cond(1).NrOfOnOffsets = size(PRT.BostonNaming.Time,1);
        tmpprt.Cond(1).OnOffsets = (PRT.BostonNaming.Time-PRT.RemoveFirstNSeconds)*1000;
        tmpprt.Cond(1).Weights = ones(size(PRT.BostonNaming.Time,1),1);
        tmpprt.Cond(1).Color = [0 255 0];

        % 'off' portion of the run.
        tmpprt.Cond(2).ConditionName = {'ControlBlock'};
        tmpprt.Cond(2).NrOfOnOffsets = size(PRT.BostonNaming.Baseline,1);
        tmpprt.Cond(2).OnOffsets = (PRT.BostonNaming.Baseline-PRT.RemoveFirstNSeconds)*1000;
        if tmpprt.Cond(2).OnOffsets(1,1) < 0; tmpprt.Cond(2).OnOffsets(1,1) = 0; end
        tmpprt.Cond(2).Weights = ones(size(PRT.BostonNaming.Baseline,1),1);
        tmpprt.Cond(2).Color = [255 0 0];

        tmpprt.SaveAs(fullfile(PRT.PRTSavePath,[subID '_BostonNaming_Run1.prt']));
    end

    % if user indicated they want to create a Verb Generation PRT.
    if PRT.VerbGeneration.Create == 1
        PRT.RemoveFirstNSeconds = [];
        % TR length is hard-coded based off feedback from Madalina.
        PRT.RemoveFirstNSeconds = PRT.RemoveFirstNVolumes * 3000;
        tmpprt = [];
        tmpprt = BVQXfile('new:prt');
        tmpprt.Cond(1).ConditionName = {'VerbGeneration'};
        tmpprt.Cond(1).NrOfOnOffsets = size(PRT.VerbGeneration.Time,1);
        tmpprt.Cond(1).OnOffsets = (PRT.VerbGeneration.Time-PRT.RemoveFirstNSeconds)*1000;
        tmpprt.Cond(1).Weights = ones(size(PRT.VerbGeneration.Time,1),1);
        tmpprt.Cond(1).Color = [0 255 0];

        % 'off' portion of the run.
        tmpprt.Cond(2).ConditionName = {'ControlBlock'};
        tmpprt.Cond(2).NrOfOnOffsets = size(PRT.VerbGeneration.Baseline,1);
        tmpprt.Cond(2).OnOffsets = (PRT.VerbGeneration.Baseline-PRT.RemoveFirstNSeconds)*1000;
        if tmpprt.Cond(2).OnOffsets(1,1) < 0; tmpprt.Cond(2).OnOffsets(1,1) = 0; end
        tmpprt.Cond(2).Weights = ones(size(PRT.VerbGeneration.Baseline,1),1);
        tmpprt.Cond(2).Color = [255 0 0];

        tmpprt.SaveAs(fullfile(PRT.PRTSavePath,[subID '_VerbGeneration_Run1.prt']));
    end

    % if user indicated they want to create a VF Category PRT.
    if PRT.VFCategory.Create == 1
        PRT.RemoveFirstNSeconds = [];
        % TR length is hard-coded based off feedback from Madalina.
        PRT.RemoveFirstNSeconds = PRT.RemoveFirstNVolumes * 3000;
        tmpprt = [];
        tmpprt = BVQXfile('new:prt');
        tmpprt.Cond(1).ConditionName = {'VFCategory'};
        tmpprt.Cond(1).NrOfOnOffsets = size(PRT.VFCategory.Time,1);
        tmpprt.Cond(1).OnOffsets = (PRT.VFCategory.Time-PRT.RemoveFirstNSeconds)*1000;
        tmpprt.Cond(1).Weights = ones(size(PRT.VFCategory.Time,1),1);
        tmpprt.Cond(1).Color = [0 255 0];

        % 'off' portion of the run.
        tmpprt.Cond(2).ConditionName = {'ControlBlock'};
        tmpprt.Cond(2).NrOfOnOffsets = size(PRT.VFCategory.Baseline,1);
        tmpprt.Cond(2).OnOffsets = (PRT.VFCategory.Baseline-PRT.RemoveFirstNSeconds)*1000;
        if tmpprt.Cond(2).OnOffsets(1,1) < 0; tmpprt.Cond(2).OnOffsets(1,1) = 0; end
        tmpprt.Cond(2).Weights = ones(size(PRT.VFCategory.Baseline,1),1);
        tmpprt.Cond(2).Color = [255 0 0];

        tmpprt.SaveAs(fullfile(PRT.PRTSavePath,[subID '_VFCategory_Run1.prt']));
    end

    % if user indicated they want to create a VF Category PRT.
    if PRT.VFLetters.Create == 1
        PRT.RemoveFirstNSeconds = [];
        % TR length is hard-coded based off feedback from Madalina.
        PRT.RemoveFirstNSeconds = PRT.RemoveFirstNVolumes * 3000;
        tmpprt = [];
        tmpprt = BVQXfile('new:prt');
        tmpprt.Cond(1).ConditionName = {'VFLetters'};
        tmpprt.Cond(1).NrOfOnOffsets = size(PRT.VFLetters.Time,1);
        tmpprt.Cond(1).OnOffsets = (PRT.VFLetters.Time-PRT.RemoveFirstNSeconds)*1000;
        tmpprt.Cond(1).Weights = ones(size(PRT.VFLetters.Time,1),1);
        tmpprt.Cond(1).Color = [0 255 0];

        % 'off' portion of the run.
        tmpprt.Cond(2).ConditionName = {'ControlBlock'};
        tmpprt.Cond(2).NrOfOnOffsets = size(PRT.VFLetters.Baseline,1);
        tmpprt.Cond(2).OnOffsets = (PRT.VFLetters.Baseline-PRT.RemoveFirstNSeconds)*1000;
        if tmpprt.Cond(2).OnOffsets(1,1) < 0; tmpprt.Cond(2).OnOffsets(1,1) = 0; end
        tmpprt.Cond(2).Weights = ones(size(PRT.VFLetters.Baseline,1),1);
        tmpprt.Cond(2).Color = [255 0 0];

        tmpprt.SaveAs(fullfile(PRT.PRTSavePath,[subID '_VFLetters_Run1.prt']));
    end

    % if user indicated they want to create a VF Category PRT.
    if PRT.DefinitionNaming.Create == 1
        PRT.RemoveFirstNSeconds = [];
        % TR length is hard-coded based off feedback from Madalina.
        PRT.RemoveFirstNSeconds = PRT.RemoveFirstNVolumes * 2000;
        tmpprt = [];
        tmpprt = BVQXfile('new:prt');
        tmpprt.Cond(1).ConditionName = {'DefinitionNaming'};
        tmpprt.Cond(1).NrOfOnOffsets = size(PRT.DefinitionNaming.Time,1);
        tmpprt.Cond(1).OnOffsets = (PRT.DefinitionNaming.Time-PRT.RemoveFirstNSeconds)*1000;
        tmpprt.Cond(1).Weights = ones(size(PRT.DefinitionNaming.Time,1),1);
        tmpprt.Cond(1).Color = [0 255 0];

        % 'off' portion of the run.
        tmpprt.Cond(2).ConditionName = {'ControlBlock'};
        tmpprt.Cond(2).NrOfOnOffsets = size(PRT.DefinitionNaming.Baseline,1);
        tmpprt.Cond(2).OnOffsets = (PRT.DefinitionNaming.Baseline-PRT.RemoveFirstNSeconds)*1000;
        if tmpprt.Cond(2).OnOffsets(1,1) < 0; tmpprt.Cond(2).OnOffsets(1,1) = 0; end
        tmpprt.Cond(2).Weights = ones(size(PRT.DefinitionNaming.Baseline,1),1);
        tmpprt.Cond(2).Color = [255 0 0];

        tmpprt.SaveAs(fullfile(PRT.PRTSavePath,[subID '_DefinitionNaming_Run1.prt']));
    end
    % if user indicated they want to create a VF Category PRT.
    if PRT.PictureNaming.Create == 1
        PRT.RemoveFirstNSeconds = [];
        % TR length is hard-coded based off feedback from Madalina.
        PRT.RemoveFirstNSeconds = PRT.RemoveFirstNVolumes * 2000;
        tmpprt = [];
        tmpprt = BVQXfile('new:prt');
        tmpprt.Cond(1).ConditionName = {'PictureNaming'};
        tmpprt.Cond(1).NrOfOnOffsets = size(PRT.PictureNaming.Time,1);
        tmpprt.Cond(1).OnOffsets = (PRT.PictureNaming.Time-PRT.RemoveFirstNSeconds)*1000;
        tmpprt.Cond(1).Weights = ones(size(PRT.PictureNaming.Time,1),1);
        tmpprt.Cond(1).Color = [0 255 0];

        % 'off' portion of the run.
        tmpprt.Cond(2).ConditionName = {'ControlBlock'};
        tmpprt.Cond(2).NrOfOnOffsets = size(PRT.PictureNaming.Baseline,1);
        tmpprt.Cond(2).OnOffsets = (PRT.PictureNaming.Baseline-PRT.RemoveFirstNSeconds)*1000;
        if tmpprt.Cond(2).OnOffsets(1,1) < 0; tmpprt.Cond(2).OnOffsets(1,1) = 0; end
        tmpprt.Cond(2).Weights = ones(size(PRT.PictureNaming.Baseline,1),1);
        tmpprt.Cond(2).Color = [255 0 0];

        tmpprt.SaveAs(fullfile(PRT.PRTSavePath,[subID '_PictureNaming_Run1.prt']));
    end
    % if user indicated they want to create a VF Category PRT.
    if PRT.SentenceCompletion.Create == 1
        PRT.RemoveFirstNSeconds = [];
        % TR length is hard-coded based off feedback from Madalina.
        PRT.RemoveFirstNSeconds = PRT.RemoveFirstNVolumes * 2000;
        tmpprt = [];
        tmpprt = BVQXfile('new:prt');
        tmpprt.Cond(1).ConditionName = {'SentenceCompletion'};
        tmpprt.Cond(1).NrOfOnOffsets = size(PRT.SentenceCompletion.Time,1);
        tmpprt.Cond(1).OnOffsets = (PRT.SentenceCompletion.Time-PRT.RemoveFirstNSeconds)*1000;
        tmpprt.Cond(1).Weights = ones(size(PRT.SentenceCompletion.Time,1),1);
        tmpprt.Cond(1).Color = [0 255 0];

        % 'off' portion of the run.
        tmpprt.Cond(2).ConditionName = {'ControlBlock'};
        tmpprt.Cond(2).NrOfOnOffsets = size(PRT.SentenceCompletion.Baseline,1);
        tmpprt.Cond(2).OnOffsets = (PRT.SentenceCompletion.Baseline-PRT.RemoveFirstNSeconds)*1000;
        if tmpprt.Cond(2).OnOffsets(1,1) < 0; tmpprt.Cond(2).OnOffsets(1,1) = 0; end
        tmpprt.Cond(2).Weights = ones(size(PRT.SentenceCompletion.Baseline,1),1);
        tmpprt.Cond(2).Color = [255 0 0];

        tmpprt.SaveAs(fullfile(PRT.PRTSavePath,[subID '_SentenceCompletion_Run1.prt']));
    end
end
