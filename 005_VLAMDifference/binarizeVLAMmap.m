% read in nifti file.
[file,path] = uigetfile('*.nii','select run1 map 1');
Volume1 = spm_vol(fullfile(path,file));
[SubMap1,~] = spm_read_vols(Volume1);

% turn it into a vector.
statmap = reshape(SubMap1,[size(SubMap1,1)*size(SubMap1,2)*size(SubMap1,3),1]);

% make the map positive.
statmap = abs(statmap);

% find all values not equal to 0 and make it a 1 (binarize).
statmap(statmap~=0) = 1;

% turn the binarized vector into a 3D array.
finalmap = reshape(statmap,[size(SubMap1,1),size(SubMap1,2),size(SubMap1,3)]);

% save the map.
fname = [file '.Binarized.nii'];
Volume1.fname = fname;
spm_write_vol(Volume1,finalmap);