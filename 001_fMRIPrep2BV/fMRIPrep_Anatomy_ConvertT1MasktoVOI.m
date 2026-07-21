function fMRIPrep_Anatomy_ConvertT1MasktoVOI
% mask brain
[file,path] = uigetfile('*.nii.gz',['select your .nii file']);
MaskBrain = spm_vol(fullfile(path,file));
[mask,XYZ] = spm_read_vols(MaskBrain);
%vox2keep = mask==1;

%find lesion vox
maskvox = find(mask==1);
xyzcoords = XYZ(:,maskvox)';

% Create VOI and save it out.
voi = BVQXfile('new:voi');
voi.ReferenceSpace = 'MNI';
voi.FileVersion= 4;
voi.VOI(1).Voxels = xyzcoords;
voi.VOI(1).Name = input('what is the subject name/file name?','s');
voi.VOI(1).Color = [255 0 0];
voi.VOI(1).NrOfVoxels = size(xyzcoords,1);
voi.SaveAs;