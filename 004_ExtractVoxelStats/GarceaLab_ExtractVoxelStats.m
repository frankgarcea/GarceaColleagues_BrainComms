function [VoxelStats] = GarceaLab_ExtractVoxelStats
%% set up parameters
%thresh = input('what is your voxel threshold to determine significance?');
tempprompt = {'Provide a threshold value.','Are you analyzing cortical or subcortical areas or both?'};
definputexpnames = {'1.645','Cortical (1), Subcortical (2), Both 1 and 2 (3), White Matter Tracts (4), All of the above (5)?'};
dlgtitle = 'Extract Voxel statistics -- input parameters';
dims = [1 100];
prompt= inputdlg(tempprompt,dlgtitle,dims,definputexpnames);
thresh = str2double(prompt{1});
analysistype = str2double(prompt{2});
%% first map
uiwait(msgbox({['Please select your stat map (e.g., VLAM map). It should be a .nii file.']}));
[file,path] = uigetfile('*.nii','select run1 map 1');
Volume1 = spm_vol(fullfile(path,file));
[SubMap1,~] = spm_read_vols(Volume1);
statmap = reshape(SubMap1,[size(SubMap1,1)*size(SubMap1,2)*size(SubMap1,3),1]);
% get rid of Inf from brain map.
statmap(statmap==Inf) = 0; statmap(statmap==-Inf) = 0;
% Do you want to exclude voxels if they don't reach a significance level?
datadirection = input('what is the direction of data?','s');
removevox = input('remove sub-threshold voxels? 1 for yes, 2 for no');
if removevox == 1
    threshold = thresh;%input('what threshold?');
    switch datadirection
        case 'positive'
    %threshold = 1.645; % whatever value you want.
    mapindices = statmap>=threshold;
    statmap(mapindices~=1) = 0;
        case 'negative'
    %threshold = -1.645; % whatever value you want.
    mapindices = statmap<=threshold;
    statmap(mapindices~=1) = 0;        
    end
end
statmap = abs(statmap);
thresh = abs(thresh);
%% now let's select the cortical or subcortical parcellation atlas.
switch analysistype
    case 1
        %% second map
        uiwait(msgbox({['Please select the atlas file located here: ' ...
            'Garcealab>Resources>Atlas>HarvardOxford>Cortical>tpl-MNI152NLin2009cAsym_res-01_atlas-HOCPAl_desc-th25_dseg.nii.']}));
        [file,path] = uigetfile('*.nii','select run1 map 2');
        Volume2 = spm_vol(fullfile(path,file));
        [SubMap2,~] = spm_read_vols(Volume2);
        RegionLabels = {'LeftFrontalPole','RightFrontalPole', 'LeftInsularCortex','LeftInsularCortex','LeftSupFrontGyrus','RightSupFrontGyrus','LeftMidFrontGyrus', 'RightMidFrontGyrus', ...
            'LeftIFGTriang','RightIFGTriang','LeftIFGOperc','RightIFGOperc','LeftPreCentralGyrus', 'RightPreCentralGyrus','LeftTemporalPole', 'RightTemporalPole','LeftSTGAnt','RightSTGAnt', ...
            'LeftSTGPost','RightSTGPost','LeftMTGAnt','RightMTGAnt','LeftMTGPost','RightMTGPost','LeftMTGTempParOcc','RightMTGTempParOcc','LeftITGAnt','RightITGAnt','LeftITGPost','RightITGPost', ...
            'LeftITGTempParOcc','RightITGTempParOcc','LeftPostCentralGyrus','RightPostCentralGyrus','LeftSPL','RightSPL','LeftSMGAnt','RightSMGAnt','LeftSMGPost','RightSMGPost','LeftAG','RightAG', ...
            'LeftLOCSup','RightLOCSup', 'LeftLOCInf', 'RightLOCInf','LeftIntraCalcarine','RightIntraCalcarine','LeftFrontMedial','RightFrontMedial','LeftSMA','RightSMA','LeftSubcallosal','RightSubcallosal', ...
            'LeftParacingulate','RightParacingulate','LeftCingGyrusAnt', 'RightCingGyrusAnt', 'LeftCingGyrusPost','RightCingGyrusPost', 'LeftPrecuneous','RightPrecuneous','LeftCunealCortex','RightCunealCortex', ...
            'LeftOrbitoFrontal','RightOrbitoFrontal','LeftPHGAnt','RightPHGAnt','LeftPHGPost','RightPHGPost','LeftLingualGyrus','RightLingualGyrus','LeftFusiformAnt','RightFusiformAnt', ...
            'LeftFusiformPost','RightFusiformPost', 'LeftFusiformTempOcc','RightFusiformTempOcc','LeftFusiformOcc','RightFusiformOcc','LeftFrontalOperc','RightFrontalOperc', 'LeftCentralOperc','RightCentralOperc', ...
            'LeftParietalOperc','RightParietalOperc', 'LeftPlanumPolare','RightPlanumPolare','LeftHeschlsGyrus','RightHeschlsGyrus','LeftPlanumTemporale','RightPlanumTemporale','LeftSupraCalcarine','RightSupraCalcarine', ...
            'LeftOccipitalPole','RightOccipitalPole'};

        broadmanmap = reshape(SubMap2,[size(SubMap2,1)*size(SubMap2,2)*size(SubMap2,3),1]);
        %% let's loop through brodmann areas to get coordinates
        brodmanregions = unique(broadmanmap);
        counter = 0;
        VoxelStats = [];
        % main loop
        for broadmani = 1:length(brodmanregions)
            if brodmanregions(broadmani)>0
                %% get voxelwise coordinates for each brodmann area
                %counter = counter + 1;
                tmpvoxindices = find(broadmanmap==brodmanregions(broadmani));
                if size(find(statmap(tmpvoxindices)>=thresh),1) > 0
                    counter = counter + 1;
                    VoxelStats.broadman(counter).data = statmap(tmpvoxindices);
                    %% let's get the peak coordinate in each broadman ROI.
                    tmpdata = VoxelStats.broadman(counter).data;
                    descendingpeaks = sortrows(tmpdata,'descend');
                    peakvalue = descendingpeaks(1);
                    voxelindex = find(statmap(tmpvoxindices) == peakvalue);
                    [I,J,K] = ind2sub([size(SubMap2,1),size(SubMap2,2),size(SubMap2,3)],tmpvoxindices(voxelindex));
                    peakvox = [I,J,K];
                    %% simple transformation from voxel space to coordinate space
                    % ensure both maps are in the same space.
                    if abs(Volume1.private.mat(1,4)) ~= abs(Volume2.private.mat(1,4))
                        disp('Transformation between X dimensions across your maps are not the same');
                    end
                    if abs(Volume1.private.mat(2,4)) ~= abs(Volume2.private.mat(2,4))
                        disp('Transformation between Y dimensions across your maps are not the same');
                    end
                    if abs(Volume1.private.mat(3,4)) ~= abs(Volume2.private.mat(3,4))
                        disp('Transformation between Z dimensions across your maps are not the same');
                    end
                    % Convert from voxel space to mm space (MNI) space.
                    mnicoord(:,1) = peakvox(:,1) - abs(Volume1.private.mat(1,4));
                    mnicoord(:,2) = peakvox(:,2) - abs(Volume1.private.mat(2,4));
                    mnicoord(:,3) = peakvox(:,3) - abs(Volume1.private.mat(3,4));
                    mnicoordsize = size(mnicoord,1);
                    % if the peak value occupies more than one voxel, take the mean
                    % of peak voxel coordinates for reporting. This can be changed
                    % to whatever you'd like.
                    if size(mnicoord,1) > 1; mnicoord = ceil(mean(mnicoord)); end
                    %% Now calculate stats that we need for our excel file.
                    VoxelStats.ROIStats(counter,1) = size(VoxelStats.broadman(counter).data,1);
                    VoxelStats.ROIStats(counter,2) = size(find(VoxelStats.broadman(counter).data>thresh),1);
                    VoxelStats.ROIStats(counter,3) = brodmanregions(broadmani);%str2double(RegionLabels(brodmanregions(broadmani),1)); %cell2mat(RegionLabels(brodmanregions(broadmani)));%brodmanregions(broadmani);
                    VoxelStats.ROIStats(counter,4) = mnicoord(1);
                    VoxelStats.ROIStats(counter,5) = mnicoord(2);
                    VoxelStats.ROIStats(counter,6) = mnicoord(3);
                    VoxelStats.ROIStats(counter,7) = peakvalue;
                    VoxelStats.ROIStats(counter,8) = mnicoordsize;
                    clear tmpvoxindices mnicoord mnicoordsize
                end
            end
        end

        VoxelStats.ROINames = RegionLabels(VoxelStats.ROIStats(:,3));
        OutputArray = [VoxelStats.ROINames',num2cell(VoxelStats.ROIStats)];
        columnNames = {'RegionName', 'TotalVoxelsinROI', 'SigVoxelsinROI','RegionNumber','PeakX','PeakY','PeakZ','PeakStatValue','NumVoxelsinPeak'};
        dataTable = array2table(OutputArray, 'VariableNames', columnNames);
        dataTable.Properties.VariableNames = columnNames;
        % write out data in excel
        tempprompt{1} = ['Provide an output file name.'];
        definputexpnames{1} = [''];
        dlgtitle = 'List the Output file name.';
        dims = [1 100];
        outputprompt = inputdlg(tempprompt,dlgtitle,dims,definputexpnames);
        %outputfilename = input('Provide an output file name ','s');
        writetable(dataTable,[outputprompt{1} '.VoxelStats.with.' num2str(thresh) '.threshold.Cortical.xlsx']);


    case 2
        %% second map
        uiwait(msgbox({['Please select the atlas file located here: ' ...
            'Garcealab>Resources>Atlas>HarvardOxford>Subcortical>tpl-MNI152NLin2009cAsym_res-01_atlas-HOSPA_desc-th25_dseg.nii']}));
        [file,path] = uigetfile('*.nii','select run1 map 2');
        Volume2 = spm_vol(fullfile(path,file));
        [SubMap2,~] = spm_read_vols(Volume2);
        RegionLabels = {'LeftCerebralWhiteMatter', 'LeftCerebralCortex', 'LeftLateralVentrical', 'LeftThalamus', 'LeftCaudate', 'LeftPutamen', 'LeftPallidum', 'Brain-stem', 'LeftHippocampus', 'LeftAmygdala', ...
            'LeftAccumbens', 'RightCerebralWhiteMatter', 'RightCerebralCortex', 'RightLateralVentricle', 'RightThalamus', 'RightCaudate', 'RightPutamen', 'RightPallidum', 'RightHippocampus', 'RightAmygdala', 'RightAccumbens'};

        broadmanmap = reshape(SubMap2,[size(SubMap2,1)*size(SubMap2,2)*size(SubMap2,3),1]);
        %% let's loop through brodmann areas to get coordinates
        brodmanregions = unique(broadmanmap);
        counter = 0;
        VoxelStats = [];
        % main loop
        for broadmani = 1:length(brodmanregions)
            if brodmanregions(broadmani)>0
                %% get voxelwise coordinates for each brodmann area
                %counter = counter + 1;
                tmpvoxindices = find(broadmanmap==brodmanregions(broadmani));
                if size(find(statmap(tmpvoxindices)>=thresh),1) > 0
                    counter = counter + 1;
                    VoxelStats.broadman(counter).data = statmap(tmpvoxindices);
                    %% let's get the peak coordinate in each broadman ROI.
                    tmpdata = VoxelStats.broadman(counter).data;
                    descendingpeaks = sortrows(tmpdata,'descend');
                    peakvalue = descendingpeaks(1);
                    voxelindex = find(statmap(tmpvoxindices) == peakvalue);
                    [I,J,K] = ind2sub([size(SubMap2,1),size(SubMap2,2),size(SubMap2,3)],tmpvoxindices(voxelindex));
                    peakvox = [I,J,K];
                    %% simple transformation from voxel space to coordinate space
                    % ensure both maps are in the same space.
                    if abs(Volume1.private.mat(1,4)) ~= abs(Volume2.private.mat(1,4))
                        disp('Transformation between X dimensions across your maps are not the same');
                    end
                    if abs(Volume1.private.mat(2,4)) ~= abs(Volume2.private.mat(2,4))
                        disp('Transformation between Y dimensions across your maps are not the same');
                    end
                    if abs(Volume1.private.mat(3,4)) ~= abs(Volume2.private.mat(3,4))
                        disp('Transformation between Z dimensions across your maps are not the same');
                    end
                    % Convert from voxel space to mm space (MNI) space.
                    mnicoord(:,1) = peakvox(:,1) - abs(Volume1.private.mat(1,4));
                    mnicoord(:,2) = peakvox(:,2) - abs(Volume1.private.mat(2,4));
                    mnicoord(:,3) = peakvox(:,3) - abs(Volume1.private.mat(3,4));
                    mnicoordsize = size(mnicoord,1);
                    % if the peak value occupies more than one voxel, take the mean
                    % of peak voxel coordinates for reporting. This can be changed
                    % to whatever you'd like.
                    if size(mnicoord,1) > 1; mnicoord = ceil(mean(mnicoord)); end
                    %% Now calculate stats that we need for our excel file.
                    VoxelStats.ROIStats(counter,1) = size(VoxelStats.broadman(counter).data,1);
                    VoxelStats.ROIStats(counter,2) = size(find(VoxelStats.broadman(counter).data>thresh),1);
                    VoxelStats.ROIStats(counter,3) = brodmanregions(broadmani);%str2double(RegionLabels(brodmanregions(broadmani),1)); %cell2mat(RegionLabels(brodmanregions(broadmani)));%brodmanregions(broadmani);
                    VoxelStats.ROIStats(counter,4) = mnicoord(1);
                    VoxelStats.ROIStats(counter,5) = mnicoord(2);
                    VoxelStats.ROIStats(counter,6) = mnicoord(3);
                    VoxelStats.ROIStats(counter,7) = peakvalue;
                    VoxelStats.ROIStats(counter,8) = mnicoordsize;
                    clear tmpvoxindices mnicoord mnicoordsize
                end
            end
        end

        VoxelStats.ROINames = RegionLabels(VoxelStats.ROIStats(:,3));

        OutputArray = [VoxelStats.ROINames',num2cell(VoxelStats.ROIStats)];
        columnNames = {'RegionName', 'TotalVoxelsinROI', 'SigVoxelsinROI','RegionNumber','PeakX','PeakY','PeakZ','PeakStatValue','NumVoxelsinPeak'};
        dataTable = array2table(OutputArray, 'VariableNames', columnNames);
        dataTable.Properties.VariableNames = columnNames;
        % write out data in excel
        tempprompt{1} = ['Provide an output file name.'];
        definputexpnames{1} = [''];
        dlgtitle = 'List the Output file name.';
        dims = [1 100];
        outputprompt = inputdlg(tempprompt,dlgtitle,dims,definputexpnames);
        %outputfilename = input('Provide an output file name ','s');
        writetable(dataTable,[outputprompt{1} '.VoxelStats.with.' num2str(thresh) '.threshold.Subcortical.xlsx']);
    case 3
        %% second map
        uiwait(msgbox({['Please select the atlas file located here: ' ...
            'Garcealab>Resources>Atlas>HarvardOxford>Cortical>tpl-MNI152NLin2009cAsym_res-01_atlas-HOCPAl_desc-th25_dseg.nii']}));
        [file,path] = uigetfile('*.nii','select run1 map 2');
        Volume2 = spm_vol(fullfile(path,file));
        [SubMap2,~] = spm_read_vols(Volume2);
        RegionLabelsCortical = {'LeftFrontalPole','RightFrontalPole', 'LeftInsularCortex','LeftInsularCortex','LeftSupFrontGyrus','RightSupFrontGyrus','LeftMidFrontGyrus', 'RightMidFrontGyrus', ...
            'LeftIFGTriang','RightIFGTriang','LeftIFGOperc','RightIFGOperc','LeftPreCentralGyrus', 'RightPreCentralGyrus','LeftTemporalPole', 'RightTemporalPole','LeftSTGAnt','RightSTGAnt', ...
            'LeftSTGPost','RightSTGPost','LeftMTGAnt','RightMTGAnt','LeftMTGPost','RightMTGPost','LeftMTGTempParOcc','RightMTGTempParOcc','LeftITGAnt','RightITGAnt','LeftITGPost','RightITGPost', ...
            'LeftITGTempParOcc','RightITGTempParOcc','LeftPostCentralGyrus','RightPostCentralGyrus','LeftSPL','RightSPL','LeftSMGAnt','RightSMGAnt','LeftSMGPost','RightSMGPost','LeftAG','RightAG', ...
            'LeftLOCSup','RightLOCSup', 'LeftLOCInf', 'RightLOCInf','LeftIntraCalcarine','RightIntraCalcarine','LeftFrontMedial','RightFrontMedial','LeftSMA','RightSMA','LeftSubcallosal','RightSubcallosal', ...
            'LeftParacingulate','RightParacingulate','LeftCingGyrusAnt', 'RightCingGyrusAnt', 'LeftCingGyrusPost','RightCingGyrusPost', 'LeftPrecuneous','RightPrecuneous','LeftCunealCortex','RightCunealCortex', ...
            'LeftOrbitoFrontal','RightOrbitoFrontal','LeftPHGAnt','RightPHGAnt','LeftPHGPost','RightPHGPost','LeftLingualGyrus','RightLingualGyrus','LeftFusiformAnt','RightFusiformAnt', ...
            'LeftFusiformPost','RightFusiformPost', 'LeftFusiformTempOcc','RightFusiformTempOcc','LeftFusiformOcc','RightFusiformOcc','LeftFrontalOperc','RightFrontalOperc', 'LeftCentralOperc','RightCentralOperc', ...
            'LeftParietalOperc','RightParietalOperc', 'LeftPlanumPolare','RightPlanumPolare','LeftHeschlsGyrus','RightHeschlsGyrus','LeftPlanumTemporale','RightPlanumTemporale','LeftSupraCalcarine','RightSupraCalcarine', ...
            'LeftOccipitalPole','RightOccipitalPole'};

        broadmanmap = reshape(SubMap2,[size(SubMap2,1)*size(SubMap2,2)*size(SubMap2,3),1]);
        %% let's loop through brodmann areas to get coordinates
        brodmanregions = unique(broadmanmap);
        counter = 0;
        VoxelStats = [];
        % main loop
        for broadmani = 1:length(brodmanregions)
            if brodmanregions(broadmani)>0
                %% get voxelwise coordinates for each brodmann area
                %counter = counter + 1;
                tmpvoxindices = find(broadmanmap==brodmanregions(broadmani));
                if size(find(statmap(tmpvoxindices)>=thresh),1) > 0
                    counter = counter + 1;
                    VoxelStats.broadman(counter).data = statmap(tmpvoxindices);
                    %% let's get the peak coordinate in each broadman ROI.
                    tmpdata = VoxelStats.broadman(counter).data;
                    descendingpeaks = sortrows(tmpdata,'descend');
                    peakvalue = descendingpeaks(1);
                    voxelindex = find(statmap(tmpvoxindices) == peakvalue);
                    [I,J,K] = ind2sub([size(SubMap2,1),size(SubMap2,2),size(SubMap2,3)],tmpvoxindices(voxelindex));
                    peakvox = [I,J,K];
                    %% simple transformation from voxel space to coordinate space
                    % ensure both maps are in the same space.
                    if abs(Volume1.private.mat(1,4)) ~= abs(Volume2.private.mat(1,4))
                        disp('Transformation between X dimensions across your maps are not the same');
                    end
                    if abs(Volume1.private.mat(2,4)) ~= abs(Volume2.private.mat(2,4))
                        disp('Transformation between Y dimensions across your maps are not the same');
                    end
                    if abs(Volume1.private.mat(3,4)) ~= abs(Volume2.private.mat(3,4))
                        disp('Transformation between Z dimensions across your maps are not the same');
                    end
                    % Convert from voxel space to mm space (MNI) space.
                    mnicoord(:,1) = peakvox(:,1) - abs(Volume1.private.mat(1,4));
                    mnicoord(:,2) = peakvox(:,2) - abs(Volume1.private.mat(2,4));
                    mnicoord(:,3) = peakvox(:,3) - abs(Volume1.private.mat(3,4));
                    mnicoordsize = size(mnicoord,1);
                    % if the peak value occupies more than one voxel, take the mean
                    % of peak voxel coordinates for reporting. This can be changed
                    % to whatever you'd like.
                    if size(mnicoord,1) > 1; mnicoord = ceil(mean(mnicoord)); end
                    %% Now calculate stats that we need for our excel file.
                    VoxelStats.ROIStats(counter,1) = size(VoxelStats.broadman(counter).data,1);
                    VoxelStats.ROIStats(counter,2) = size(find(VoxelStats.broadman(counter).data>thresh),1);
                    VoxelStats.ROIStats(counter,3) = brodmanregions(broadmani);%str2double(RegionLabels(brodmanregions(broadmani),1)); %cell2mat(RegionLabels(brodmanregions(broadmani)));%brodmanregions(broadmani);
                    VoxelStats.ROIStats(counter,4) = mnicoord(1);
                    VoxelStats.ROIStats(counter,5) = mnicoord(2);
                    VoxelStats.ROIStats(counter,6) = mnicoord(3);
                    VoxelStats.ROIStats(counter,7) = peakvalue;
                    VoxelStats.ROIStats(counter,8) = mnicoordsize;
                    clear tmpvoxindices mnicoord mnicoordsize
                end
            end
        end
        %
        VoxelStats.ROINames = RegionLabelsCortical(VoxelStats.ROIStats(:,3));
        OutputArray = [VoxelStats.ROINames',num2cell(VoxelStats.ROIStats)];
        columnNames = {'RegionName', 'TotalVoxelsinROI', 'SigVoxelsinROI','RegionNumber','PeakX','PeakY','PeakZ','PeakStatValue','NumVoxelsinPeak'};
        dataTableCortical = array2table(OutputArray, 'VariableNames', columnNames);
        dataTableCortical.Properties.VariableNames = columnNames;
       
        %% now get the subcortical atlas
        uiwait(msgbox({['Please select the atlas file located here: ' ...
            'Garcealab>Resources>Atlas>HarvardOxford>Subcortical>tpl-MNI152NLin2009cAsym_res-01_atlas-HOSPA_desc-th25_dseg.nii']}));
        [file,path] = uigetfile('*.nii','select run1 map 2');
        Volume2 = spm_vol(fullfile(path,file));
        [SubMap2,~] = spm_read_vols(Volume2);
        RegionLabelsSubcortical = {'LeftCerebralWhiteMatter', 'LeftCerebralCortex', 'LeftLateralVentrical', 'LeftThalamus', 'LeftCaudate', 'LeftPutamen', 'LeftPallidum', 'Brain-stem', 'LeftHippocampus', 'LeftAmygdala', ...
            'LeftAccumbens', 'RightCerebralWhiteMatter', 'RightCerebralCortex', 'RightLateralVentricle', 'RightThalamus', 'RightCaudate', 'RightPutamen', 'RightPallidum', 'RightHippocampus', 'RightAmygdala', 'RightAccumbens'};
        
        broadmanmap = reshape(SubMap2,[size(SubMap2,1)*size(SubMap2,2)*size(SubMap2,3),1]);
        %% let's loop through brodmann areas to get coordinates
        brodmanregions = unique(broadmanmap);
        counter = 0;
        VoxelStats = [];
        % main loop
        for broadmani = 1:length(brodmanregions)
            if brodmanregions(broadmani)>0
                %% get voxelwise coordinates for each brodmann area
                %counter = counter + 1;
                tmpvoxindices = find(broadmanmap==brodmanregions(broadmani));
                if size(find(statmap(tmpvoxindices)>=thresh),1) > 0
                    counter = counter + 1;
                    VoxelStats.broadman(counter).data = statmap(tmpvoxindices);
                    %% let's get the peak coordinate in each broadman ROI.
                    tmpdata = VoxelStats.broadman(counter).data;
                    descendingpeaks = sortrows(tmpdata,'descend');
                    peakvalue = descendingpeaks(1);
                    voxelindex = find(statmap(tmpvoxindices) == peakvalue);
                    [I,J,K] = ind2sub([size(SubMap1,1),size(SubMap1,2),size(SubMap1,3)],tmpvoxindices(voxelindex));
                    peakvox = [I,J,K];
                    %% simple transformation from voxel space to coordinate space
                    % ensure both maps are in the same space.
                    if abs(Volume1.private.mat(1,4)) ~= abs(Volume2.private.mat(1,4))
                        disp('Transformation between X dimensions across your maps are not the same');
                    end
                    if abs(Volume1.private.mat(2,4)) ~= abs(Volume2.private.mat(2,4))
                        disp('Transformation between Y dimensions across your maps are not the same');
                    end
                    if abs(Volume1.private.mat(3,4)) ~= abs(Volume2.private.mat(3,4))
                        disp('Transformation between Z dimensions across your maps are not the same');
                    end
                    % Convert from voxel space to mm space (MNI) space.
                    mnicoord(:,1) = peakvox(:,1) - abs(Volume2.private.mat(1,4));
                    mnicoord(:,2) = peakvox(:,2) - abs(Volume2.private.mat(2,4));
                    mnicoord(:,3) = peakvox(:,3) - abs(Volume2.private.mat(3,4));
                    mnicoordsize = size(mnicoord,1);
                    % if the peak value occupies more than one voxel, take the mean
                    % of peak voxel coordinates for reporting. This can be changed
                    % to whatever you'd like.
                    if size(mnicoord,1) > 1; mnicoord = ceil(mean(mnicoord)); end
                    %% Now calculate stats that we need for our excel file.
                    VoxelStats.ROIStats(counter,1) = size(VoxelStats.broadman(counter).data,1);
                    VoxelStats.ROIStats(counter,2) = size(find(VoxelStats.broadman(counter).data>thresh),1);
                    VoxelStats.ROIStats(counter,3) = brodmanregions(broadmani);%str2double(RegionLabels(brodmanregions(broadmani),1)); %cell2mat(RegionLabels(brodmanregions(broadmani)));%brodmanregions(broadmani);
                    VoxelStats.ROIStats(counter,4) = mnicoord(1);
                    VoxelStats.ROIStats(counter,5) = mnicoord(2);
                    VoxelStats.ROIStats(counter,6) = mnicoord(3);
                    VoxelStats.ROIStats(counter,7) = peakvalue;
                    VoxelStats.ROIStats(counter,8) = mnicoordsize;
                    clear tmpvoxindices mnicoord mnicoordsize
                end
            end
        end

        VoxelStats.ROINames = RegionLabelsSubcortical(VoxelStats.ROIStats(:,3));

        OutputArray = [VoxelStats.ROINames',num2cell(VoxelStats.ROIStats)];
        columnNames = {'RegionName', 'TotalVoxelsinROI', 'SigVoxelsinROI','RegionNumber','PeakX','PeakY','PeakZ','PeakStatValue','NumVoxelsinPeak'};
        dataTableSubcortical = array2table(OutputArray, 'VariableNames', columnNames);
        dataTableSubcortical.Properties.VariableNames = columnNames;
        dataTable = vertcat(dataTableCortical,dataTableSubcortical);
        % write out data in excel
        tempprompt = {'Provide an output file name.'};
        definputexpnames = {''};
        dlgtitle = 'List the Output file name.';
        dims = [1 100];
        outputprompt = inputdlg(tempprompt,dlgtitle,dims,definputexpnames);
        %outputfilename = input('Provide an output file name ','s');
        writetable(dataTable,[outputprompt{1} '.VoxelStats.with.' num2str(thresh) '.threshold.CorticalSubcortical.xlsx']);
    case 4
        %% second map
        uiwait(msgbox({['Please select the DSI folder located here: ' ...
            'Garcealab>Resources>Atlas>DSI/']}));
        DSIpath = uigetdir();
        DSIfiles = dir(fullfile(DSIpath,'*.nii'));
        
        RegionLabelsDSI = {'LeftArcuateFasciculus', 'LeftExtremeCapsule', 'LeftFrontalAslantTract', 'LeftIFOF', 'LeftILF', 'LeftSLF', 'LeftUncinateFasciculus','WhiteMatterBottleneck'};
        counter = 0;
        for mapi = 1:size(DSIfiles,1)

            Volume2 = spm_vol(fullfile(DSIfiles(mapi).folder,DSIfiles(mapi).name));
            [SubMap2,XYZ] = spm_read_vols(Volume2);


            % get MNI coordinates of tract voxels equal to 1.
            temptractvox = XYZ(:,find(SubMap2==1))';

            % use the XYZ transformation matrix to bring MNI coordinates into
            % voxel coordinates at the resolution of the statistical map.
            statmapvox = [temptractvox(:,1) + abs(Volume1.mat(1,4)),temptractvox(:,2) + abs(Volume1.mat(2,4)),temptractvox(:,3) + abs(Volume1.mat(3,4))];

            % now convert the XYZ voxels into linear indices using the size of
            % the stat map. Simple.
            tmpvoxindices = sub2ind([Volume1.dim(1),Volume1.dim(2),Volume1.dim(3)],statmapvox(:,1),statmapvox(:,2),statmapvox(:,3));

            % Check whether there is overlap between the white matter pathway
            % and the statmap. If so, move forward.
            if size(find(statmap(tmpvoxindices)>=thresh),1) > 0
                counter = counter + 1;
                VoxelStats.broadman(counter).data = statmap(tmpvoxindices);
                %% let's get the peak coordinate in each broadman ROI.
                tmpdata = VoxelStats.broadman(counter).data;
                descendingpeaks = sortrows(tmpdata,'descend');
                peakvalue = descendingpeaks(1);
                voxelindex = find(statmap(tmpvoxindices) == peakvalue);
                [I,J,K] = ind2sub([size(SubMap1,1),size(SubMap1,2),size(SubMap1,3)],tmpvoxindices(voxelindex));
                peakvox = [I,J,K]
                %% simple transformation from voxel space to coordinate space
                % ensure both maps are in the same space.
                % Convert from voxel space to mm space (MNI) space.
                mnicoord(:,1) = peakvox(:,1) - abs(Volume1.private.mat(1,4));
                mnicoord(:,2) = peakvox(:,2) - abs(Volume1.private.mat(2,4));
                mnicoord(:,3) = peakvox(:,3) - abs(Volume1.private.mat(3,4));
                mnicoordsize = size(mnicoord,1);
                % if the peak value occupies more than one voxel, take the mean
                % of peak voxel coordinates for reporting. This can be changed
                % to whatever you'd like.
                if size(mnicoord,1) > 1; mnicoord = ceil(mean(mnicoord)); end
                %% Now calculate stats that we need for our excel file.
                VoxelStats.ROIStats(counter,1) = size(VoxelStats.broadman(counter).data,1);
                VoxelStats.ROIStats(counter,2) = size(find(VoxelStats.broadman(counter).data>thresh),1);
                VoxelStats.ROIStats(counter,3) = mapi;%str2double(RegionLabels(brodmanregions(broadmani),1)); %cell2mat(RegionLabels(brodmanregions(broadmani)));%brodmanregions(broadmani);
                VoxelStats.ROIStats(counter,4) = mnicoord(1);
                VoxelStats.ROIStats(counter,5) = mnicoord(2);
                VoxelStats.ROIStats(counter,6) = mnicoord(3);
                VoxelStats.ROIStats(counter,7) = peakvalue;
                VoxelStats.ROIStats(counter,8) = mnicoordsize;
                clear tmpvoxindices mnicoord mnicoordsize
            end
        end

        VoxelStats.ROINames = RegionLabelsDSI(VoxelStats.ROIStats(:,3));

        OutputArray = [VoxelStats.ROINames',num2cell(VoxelStats.ROIStats)];
        columnNames = {'RegionName', 'TotalVoxelsinROI', 'SigVoxelsinROI','RegionNumber','PeakX','PeakY','PeakZ','PeakStatValue','NumVoxelsinPeak'};
        dataTable = array2table(OutputArray, 'VariableNames', columnNames);
        dataTable.Properties.VariableNames = columnNames;
        % write out data in excel
        temppromptnew{1} = ['Provide an output file name.'];
        definputexpnames{1} = [' '];
        dlgtitle = 'List the Output file name.';
        dims = [1 100];
        outputprompt = inputdlg(temppromptnew,dlgtitle,dims,definputexpnames);
        %outputfilename = input('Provide an output file name ','s');
        writetable(dataTable,[outputprompt{1} '.VoxelStats.with.' num2str(thresh) '.threshold.DSITracts.xlsx']);
end

