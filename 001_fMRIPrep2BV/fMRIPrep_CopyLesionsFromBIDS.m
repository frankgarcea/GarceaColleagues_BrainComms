function fMRIPrep_CopyLesionsFromBIDS

% Select folder where BIDS data live.
uiwait(msgbox({'Please select the folder where BIDS data live'}));
BIDSDirectory = uigetdir();

% Find all 'glm' files within the folder.
SubDir = dir(fullfile(BIDSDirectory,'*sub-*'));


% Select folder to copy lesions.
uiwait(msgbox({'Please select the folder to copy your lesions out to.'}));
LesionOutputDirectory = uigetdir();

for subi = 1:size(SubDir,1)
    % go into each subject's folder and copy the lesion file
    tempdir = dir(fullfile(SubDir(subi).folder,SubDir(subi).name,'ses-1','anat'));
    % if the lesion file exists in the subject directory, copy it. If not,
    % skip it.
    %if isempty(fullfile(SubDir(subi).folder,SubDir(subi).name,'ses-1','anat','*lesion*')) == 0
    for itemi = 1:size(tempdir,1)
        if contains(tempdir(itemi).name,'lesion') == 1
        copyfile(fullfile(SubDir(subi).folder,SubDir(subi).name,'ses-1','anat','*lesion*'),fullfile(LesionOutputDirectory),'f');
        end
    end
end
    
