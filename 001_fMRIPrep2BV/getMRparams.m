function [Params] = fMRIPrep_GetMRParameters

subdir = dir('*sub*')

for subi = 1:size(subdir,1)


    subanatniftijson = dir(fullfile(subdir(subi).folder,subdir(subi).name,'ses-1','anat','*T1w.json'));
    jsonString = fileread(fullfile(subanatniftijson.folder,subanatniftijson.name));
    data = jsondecode(jsonString);

    Params.HeadCoilSize{subi,1} = data.ReceiveCoilName;

    Params.Anat.TR{subi,1} = data.RepetitionTime;
    Params.Anat.TE{subi,1} = data.EchoTime;
    Params.Anat.FlipAngle{subi,1} = data.FlipAngle;
    Params.Anat.Matrix{subi,1} = data.AcquisitionMatrixPE;
    Params.Anat.VoxelSize(subi,1) = data.SliceThickness;

    clear data jsonString subanatnifti subanatniftijson

    %
    subfMRIniftijson = dir(fullfile(subdir(subi).folder,subdir(subi).name,'ses-1','func','*resting_run-01_bold.json'));

    jsonfMRIString = fileread(fullfile(subfMRIniftijson.folder,subfMRIniftijson.name));

    fMRIdata = jsondecode(jsonfMRIString);

    Params.fMRI.FlipAngle{subi,1} = fMRIdata.FlipAngle;

    Params.fMRI.TR{subi,1} = fMRIdata.RepetitionTime;

    Params.fMRI.TE{subi,1} = fMRIdata.EchoTime;

    Params.fMRI.Matrix{subi,1} = fMRIdata.AcquisitionMatrixPE;

    Params.fMRIData.Slices(subi,1) = size(fMRIdata.SliceTiming,1);

    Params.fMRIData.VoxelSize(subi,1) = fMRIdata.SliceThickness;

    clear fMRIdata jsonfMRIString subfMRIniftijson

end
