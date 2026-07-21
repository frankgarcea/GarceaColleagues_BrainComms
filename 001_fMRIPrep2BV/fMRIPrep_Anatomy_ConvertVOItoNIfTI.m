function fMRIPrep_Anatomy_ConvertVOItoNIfTI

% load in VOI file from BV
VOI = BVQXfile('*.voi');

% load in T1 anatomical file from fmriprep
[file,path] = uigetfile('*.nii.gz',['select your .nii file']);
V = spm_vol(fullfile(path,file));
[image,XYZ] = spm_read_vols(V);

for voii = 1:size(VOI.VOI,2)
% find MNI coords from the VOI file.
voxels2label = VOI.VOI(voii).Voxels;

% create new array of zeros.
newroimap = zeros([size(image,1),size(image,2),size(image,3)]);

% fin the intersection between the MNI coords from VOI and an anatomical
% image.
[~,intersectionmap,~] = intersect(XYZ',voxels2label,'rows');


% give new ROI map a 1 where there are MNI coords from the VOI file.
newroimap(intersectionmap) = 1;

% ask for filename and save out ROI map as NIfTI file.
fileoutname = input('name of ROI file to save out (including .nii)?','s');
V.fname = fullfile(cd,fileoutname);
X = spm_write_vol(V,newroimap);

% clear tmp labels and iterate across ROI files.
clear newroimap intersectionmap voxels2label
end