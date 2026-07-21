function VLAMDifferenceAnalysis
% load in tool VLAM map (untresholded)
uiwait(msgbox({['Please select the first VLAM map. This is the one you want to focus on.']}));
[file,path] = uigetfile('*.nii',['select your .nii file']);
V = spm_vol(fullfile(path,file));
ToolVLAMMap = spm_read_vols(V);
ToolVLAMMapWork = ToolVLAMMap;
% get significant voxels.
ToolVLAMMapWorkSig = ToolVLAMMapWork<=-1.645;

% load in place VLAM map (untresholded)
uiwait(msgbox({['Please select the second VLAM map.']}));
[file,path] = uigetfile('*.nii',['select your .nii file']);
V = spm_vol(fullfile(path,file));
PlaceVLAMMap = spm_read_vols(V);
PlaceVLAMMapWork = PlaceVLAMMap;
% get significant voxels.
PlaceVLAMMapWorkSig = PlaceVLAMMapWork<=-1.645;

% Find overlap between maps
OverlapVox = ToolVLAMMapWorkSig + PlaceVLAMMapWorkSig;
OverlapVox(OverlapVox<1) = 0; OverlapVox(OverlapVox>=1) = 1;
OverlapVoxLookup = OverlapVox==1;

% vectorize difference map.
RealDiffMap = ToolVLAMMapWork - PlaceVLAMMapWork;
RealDiffMap(OverlapVoxLookup~=1) = 0;
%RealDiffMapVector =  reshape(RealDiffMap,[size(RealDiffMap,1)*size(RealDiffMap,2)*size(RealDiffMap,3),1]);

% vectorize VLAM maps
ToolVLAMMapWorkVector = reshape(ToolVLAMMapWork,[size(ToolVLAMMapWork,1)*size(ToolVLAMMapWork,2)*size(ToolVLAMMapWork,3),1]);
PlaceVLAMMapWorkVector = reshape(PlaceVLAMMapWork,[size(PlaceVLAMMapWork,1)*size(PlaceVLAMMapWork,2)*size(PlaceVLAMMapWork,3),1]);

% reset the random number generator
rng('default');

h = waitbar(0,'Looping through iterations');
for iteri = 1:1000
    % scramble the vector of VLAM z-values.
    ToolVLAMMapWorkVectorScram = ToolVLAMMapWorkVector(randperm(size(ToolVLAMMapWorkVector,1)));
    PlaceVLAMMapWorkVectorScram = PlaceVLAMMapWorkVector(randperm(size(PlaceVLAMMapWorkVector,1)));
    % put random difference scores in a column, then aggregate.
    TempDiffMap = ToolVLAMMapWorkVectorScram-PlaceVLAMMapWorkVectorScram;
    RandDiffMap(:,iteri) = TempDiffMap(OverlapVoxLookup==1);%ToolVLAMMapWorkVectorScram-PlaceVLAMMapWorkVectorScram;
    waitbar(iteri/1000,h,'Looping through iterations');
    clear ToolVLAMMapWorkVectorScram PlaceVLAMMapWorkVectorScram TempDiffMap
end
close all force

% get basic stats and compute z-scores.
PermutedDiffMapMean = mean(RandDiffMap,2);
PermutedDiffMapSTD= std(RandDiffMap,0,2);
ZMapVector = (RealDiffMap(OverlapVoxLookup==1) - PermutedDiffMapMean)./PermutedDiffMapSTD;
clear RandDiffMap

% select Tool VLAM map to remove non-significant data.
%uiwait(msgbox({['Please select the first VLAM map to restrict the analysis.']}));
%[file,path] = uigetfile('*.nii',['select your .nii file']);
%V = spm_vol(fullfile(path,file));
%ToolVLAMMapThreshold = spm_read_vols(V);
%ToolVLAMMapThresholdWork = ToolVLAMMapThreshold;
%RemoveVox = ToolVLAMMapThresholdWork>=0;

% reshape vector to 3D map and save out.
ZMapNew = zeros([size(ToolVLAMMapWork,1),size(ToolVLAMMapWork,2),size(ToolVLAMMapWork,3)]);
ZMapNew(OverlapVoxLookup==1) = ZMapVector;
%ZMap = reshape(ZMapVector,[size(ToolVLAMMapWork,1),size(ToolVLAMMapWork,2),size(ToolVLAMMapWork,3)]);
%ZMap(RemoveVox) = 0;
fileoutname = input('name of cluster extent cleaned file (include .nii)?','s');
V.fname = fullfile(cd,fileoutname);
spm_write_vol(V,ZMapNew);

