function fMRIPrep_Anatomy_MaskT1Anatomy
% mask brain
[file,path] = uigetfile('*.nii.gz',['select your .nii file']);
MaskBrain = spm_vol(fullfile(path,file));
[mask,~] = spm_read_vols(MaskBrain);
vox2remove = mask==0;

% MNI brain
[file,path] = uigetfile('*.nii.gz',['select your .nii file']);
MNIBrain = spm_vol(fullfile(path,file));
[t1anat,~] = spm_read_vols(MNIBrain);
t1anat(vox2remove) = 0;

% cerebellum template brain
% [file,path] = uigetfile('*.nii.gz',['select your .nii file']);
% Cerebellum = spm_vol(fullfile(path,file));
% [cerebellummap,XYZ] = spm_read_vols(Cerebellum);
% XYZ = XYZ';
% cerebellumremove = cerebellummap>0;
% XYZremove = XYZ(cerebellumremove,:);
% 
% [A,B,C] = intersect(XYZremove,T1xyz,'rows');
% 
% t1anat(C) = 0;



fileoutname = input('what is the name of your file? make sure to include .nii ','s');
MNIBrain.fname = fullfile(cd,fileoutname);
X = spm_write_vol(MNIBrain,t1anat);
