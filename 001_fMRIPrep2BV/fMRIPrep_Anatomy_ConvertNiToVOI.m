function fMRIPrep_Anatomy_ConvertNiToVOI
%% now select your nii file
uiwait(msgbox({['Please select a directory of nifti files to convert to VOI.']}));
[lesionpath] = uigetdir();
lesiondirectory = dir(fullfile(lesionpath,'*nii*'));

uiwait(msgbox({['Please select a folder to save out VOI files.']}));
[outputdirectory] = uigetdir();

createmask = 1;
if createmask == 1
    uiwait(msgbox({['Please select a VTC to get BBox for Masks.']}));
VTC = BVQXfile('*.vtc');
uiwait(msgbox({['Please select a folder to save out MSK files.']}));
[maskdirectory] = uigetdir();
end

% loop through NII files and save out as VOIs.
for subi = 1:size(lesiondirectory,1)
    % read in file
    templesionfile = fullfile(lesiondirectory(subi).folder,lesiondirectory(subi).name);
    V = spm_vol(templesionfile);
    [lesion,XYZ] = spm_read_vols(V);

    %find lesion vox
    lesionvox = find(lesion>=1);
    xyzcoords = XYZ(:,lesionvox)';

    voi = BVQXfile('new:voi');
    voi.ReferenceSpace = 'MNI';
    voi.FileVersion= 4;
    voi.VOI(1).Voxels = xyzcoords;

    [~,b] = fileparts(lesiondirectory(subi).name);
    voi.VOI(1).Name = b;
    %end

    voi.VOI(1).Color = [255 0 subi];
    voi.VOI(1).NrOfVoxels = size(xyzcoords,1);
    voi.SaveAs(fullfile(outputdirectory,[voi.VOI(1).Name '.voi']));
    if createmask ==1
        msk = voi.CreateMSK(VTC);
        msk.SaveAs(fullfile(maskdirectory,[voi.VOI(1).Name '.msk']));
    end
    clear voi lesionvox xyzcoords templesionfile b msk
end
