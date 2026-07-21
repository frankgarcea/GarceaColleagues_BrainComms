function fMRIPrep_Anatomy_ConvertLesiontoVOI
%% now select your nii file
uiwait(msgbox({['Please select a directory of lesion files.']}));
[lesionpath] = uigetdir();

lesiondirectory = dir(fullfile(lesionpath,'*nii*'));

uiwait(msgbox({['Please select a folder to save out lesion VOI files.']}));
[outputdirectory] = uigetdir();


for subi = 1:size(lesiondirectory,1)
templesionfile = fullfile(lesiondirectory(subi).folder,lesiondirectory(subi).name);
    
tmpsubnum = str2double(lesiondirectory(subi).name(strfind(lesiondirectory(subi).name,'sub-')+4:min(strfind(lesiondirectory(subi).name,'_')-1)));

V = spm_vol(templesionfile);
[lesion,XYZ] = spm_read_vols(V);

%find lesion vox
lesionvox = find(lesion>=1);
xyzcoords = XYZ(:,lesionvox)';

voi = BVQXfile('new:voi');
voi.ReferenceSpace = 'MNI';
voi.FileVersion = 4;
voi.VOI(1).Voxels = xyzcoords;
%voi.VOI(subi).Name = lesiondirectory(subi).name;
voi.VOI(1).Color = [255 0 subi];
voi.VOI(1).NrOfVoxels = size(xyzcoords,1);

namecheck = isnan(tmpsubnum);

switch namecheck
    case 0
if tmpsubnum < 10
    voi.VOI(1).Name = ['sub-00' num2str(tmpsubnum) '_MNILesion'];
elseif tmpsubnum > 9 && tmpsubnum < 99
    voi.VOI(1).Name = ['sub-0' num2str(tmpsubnum) '_MNILesion'];
elseif tmpsubnum > 99
    voi.VOI(1).Name = ['sub-' num2str(tmpsubnum) '_MNILesion'];
end
    case 1
        voi.VOI(1).Name = lesiondirectory(subi).name;
end
voi.SaveAs(fullfile(outputdirectory,[voi.VOI(1).Name '.voi']));
clear voi
end
