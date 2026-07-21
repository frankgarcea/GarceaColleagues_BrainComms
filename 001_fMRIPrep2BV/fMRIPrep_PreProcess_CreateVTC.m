function [Params] = fMRIPrep_PreProcess_CreateVTC(Params)
%try
%% Create VTC folder within the Processed Data Folder.
if Params.CreateVTC
    Params.BBox = [54    44    55; 236   181   201];
    %% If we are working on VTC creation without prior moving of func data, we need user input.
    if Params.MoveFunc == 0
        % Let's get the func folder in the instance in which the user does
        % not indicate they want to move func data.
        promptVTCgoal = {'Do you want to create VTCs from files in an already-created functional folder?'};
        dlgtitle = 'VTC Creation - User Input Required';
        dims = [1 100];
        definputexpnames = {'Yes (1) or No (0)'};
        vtclocationinfo = inputdlg(promptVTCgoal,dlgtitle,dims,definputexpnames);
        % this would indicate the user wants to create VTCs within an
        % already-created functional folder. We need to ask them for folder
        % names and locations.
        if str2double(vtclocationinfo(1)) == 1
            % ask the user to provide experiment names.
            promptexpnames = {'Provide the number of fMRI experiment names in your derivatives folder.'};
            dlgtitle = 'List fMRI Experiment Names';
            dims = [1 100];
            definputexpnames = {'e.g., 1, 2, 3, 7'};
            Params.NrOfExps = inputdlg(promptexpnames,dlgtitle,dims,definputexpnames);
        end
        % Now that we have established the number of fMRI experiments, ask
        % the user for input regarding the names and if/where the folders
        % live.
        for expi = 1:str2double(Params.NrOfExps{1})
            % let's ask the user to provide info about the exp name and if a
            % BV processed data folder already exists.
            promptexpnames = {['Provide the name of fMRI experiment ' num2str(expi) '.']};
            dlgtitle = 'List the fMRI Experiment Name';
            dims = [1 100];
            definputexpnames = {'e.g., TAFP'};
            fmriexppromp = inputdlg(promptexpnames,dlgtitle,dims,definputexpnames);
            Params.ExpNames(expi).Name = cell2mat(fmriexppromp(1));
            % if the BV processed folder already exists, find the folder.
            uiwait(msgbox({['Please select the previously created folder where the ' Params.ExpNames(expi).Name ' processed data live.']}));
            Params.ExpNames(expi).FolderPath = uigetdir;
        end
    end
    %% Main loop doing VTC creation.
    for expi = 1:str2double(Params.NrOfExps{1})
        tmpexpname = []; tmpexpname = Params.ExpNames(expi).Name;
        % if the experiment does not have 'Rest' in the name, we proceed.

        if contains(lower(tmpexpname),'rest') == 0
            % let's get user input regarding VTC smoothing.
            % if move func was not selected it means we need to ask for
            % user-defined inputs. if not, it already exists in the Params structure.
            if Params.MoveFunc == 0
            promptVTCsmooth = {['If you are smoothing ' tmpexpname ' VTCs, enter the smoothing kernel size (FWHM)'],'What size functional voxels do you want (in mm)?','Temporal High Pass Filter the VTCs (YES!)?'};
            dlgtitle = ['VTC Smoothing - User Input Required for ' tmpexpname ' VTC creation.'];
            dims = [1 100];
            definputexpnames = {'Enter smoothing kernel value in mm (6 is suggested); put 0 if not smoothing','Enter voxel size in mm (3 is the suggested mm size).','How many cycles (sines per cosine) do you want (2 is suggested)?'};
            vtcsmoothinfo = inputdlg(promptVTCsmooth,dlgtitle,dims,definputexpnames);
            Params.VTC.SmoothKernel = str2double(vtcsmoothinfo(1));
            Params.VTC.VoxelSize = str2double(vtcsmoothinfo(2));
            Params.VTC.THPF = str2double(vtcsmoothinfo(3));
            end

            % Let's create the VTC folder in the processed data folder.
            if Params.VTC.SmoothKernel == 0
                % in this case, we do not smooth
                unsmoothedfoldername = 'ProcessedData_Unsmoothed';
                %Params.VTC(expi).FolderName = unsmoothedfoldername;
                VTCLoc = fullfile(Params.ExpNames(expi).FolderPath,unsmoothedfoldername);
                if isfolder(VTCLoc) == 0
                    mkdir(VTCLoc);
                end
            elseif Params.VTC.SmoothKernel > 0
                % in this case, we smooth
                smoothedfoldername = ['ProcessedData_Smoothed_' num2str(Params.VTC.SmoothKernel) 'FWHM'];
                %Params.VTC(expi).FolderName = smoothedfoldername;
                VTCLoc = fullfile(Params.ExpNames(expi).FolderPath,smoothedfoldername);
                if isfolder(VTCLoc) == 0
                    mkdir(VTCLoc);
                end
            end
            
            %% Now let's CD to the funcdicoms folder to make VTCs
            tmpfuncdicomsfolder = []; tmpfuncdicomsfolder = fullfile(Params.ExpNames(expi).FolderPath,'/FuncDicoms');
            cd(tmpfuncdicomsfolder);
            for subi = 1:length(Params.Subs2process)
                subID = [];
                % let's get the subject ID.
                if Params.Subs2process(subi) < 10
                    subID = ['sub-00' num2str(Params.Subs2process(subi))];
                elseif Params.Subs2process(subi) > 9 && Params.Subs2process(subi) < 100
                    subID = ['sub-0' num2str(Params.Subs2process(subi))];
                elseif Params.Subs2process(subi) > 99
                    subID = ['sub-' num2str(Params.Subs2process(subi))];
                end
                % now let's set a temporary subject folder variable and cd there.
                tmpsubfolder = []; tmpsubfolder = fullfile(tmpfuncdicomsfolder,subID);
                cd(tmpsubfolder);

                % get session information.
                sessiondir = dir('*ses*');

                % let's loop through session information to get the anatomical files.
                % we'll then use this to copy the data to the process data folder.
                for sessioni = 1:size(sessiondir,1)
                    % create a new variable
                    sessionID = [];
                    sessionID = sessiondir(sessioni).name;
                    %
                    rundirectory = [];
                    rundirectory= filterdir('run',sessionID);
                    %if length(rundirectory) ~= 1
                    %    error('Expected exactly one run file.');
                    %end
                    % if the session folder has an 'run' folder we move forward.
                    if contains(rundirectory(1).name,'run') == 1
                        for runi = 1:size(rundirectory,1)
                            tmprunfolder = []; tmprunfolder = fullfile(tmpsubfolder,sessionID,rundirectory(runi).name);
                            cd(tmprunfolder);
                            niftidir = dir('*desc-preproc_bold.nii.gz*');
                            if length(niftidir) ~= 1
                            error('Expected exactly one nifti file.');
                            end
                            tsvdir = dir('*tsv*');
                            if length(tsvdir) ~= 1
                            error('Expected exactly one TSV file.');
                            end
                            %if runi == 1
                                Params.fMRParams = [];
                                V = spm_vol(fullfile(tmprunfolder,niftidir(1).name));
                                [image,~] = spm_read_vols(V);
                                Params.fMRIParams.nvol = size(image,4);
                                % throw out first condition (0 = no).
                                Params.fMRIParams.rcond = 0;
                                % TR length in ms.
                                Params.fMRIParams.prtr = floor(V(1).private.timing.tspace*1000);
                                clear V image
                            %end

                            % let's copy this vtc file to the VTC folder in the
                            % ProcessedData folder.
                            tmpVTCrunloc = fullfile(VTCLoc,subID,sessionID,rundirectory(runi).name);
                            if isfolder(tmpVTCrunloc) == 0
                                mkdir(tmpVTCrunloc);
                            end
                            copyfile(niftidir(1).name,tmpVTCrunloc,'f');
                            copyfile(tsvdir(1).name,tmpVTCrunloc,'f');

                            %% VTC creation, THPF-ing, and smoothing (blurring).
                            % if we're not smoothing, use these parameters.
                            if Params.VTC.SmoothKernel == 0
                                %% now that we've copied the files we can work in the BV VTC folder.
                                cd(tmpVTCrunloc)
                                % remove VTCs that may already live here.
                                vtcdir = dir('THPFGLM2');
                                if isempty(vtcdir) ~= 1
                                delete('*THPFGLM2*');
                                    %! rm *THPFGLM2*
                                end
                                tmpniftifolder = tmpVTCrunloc;
                                fMRIPrep_PreProcess_ConvertNiftiToVTC(tmpniftifolder,Params.fMRIParams,Params.VTC.VoxelSize);
                                delete('*.nii*');
                                %! rm *.nii*
                                % now let's find the VTC file and THP filter the data.
                                vtcfile = dir('*.vtc');

                                % parameters for THPF
                                %opts = []; opts.temp = 1; opts.temphp = 2; %opts.tempsc = 2;
                                % parameters from j weber.
                                opts = struct('temp', true, 'tempsc', Params.VTC.THPF);

                                % load in native VTC
                                nativeVTC = BVQXfile(fullfile(tmpVTCrunloc,vtcfile(1).name));

                                % create a filtered VTC
                                filteredVTC = nativeVTC.Filter(opts);

                                % file names for VTC and nifti file.
                                tmpunsmoothedtimecourse = [subID '_' sessionID '_task-' Params.ExpNames(expi).Name '_run-' num2str(runi) '_Unsmoothed_LTR_THPFGLM' num2str(opts.tempsc) 'c.vtc'];
                                
                                % don't save out nifti version so we don't
                                % need filename but keep it here if we need
                                % it down the road.
                                %tmpunsmoothedtimecoursenifti = ['Sub-' subID '_task-' taskID '_run-' num2str(runi) '_Unsmoothed_LTR_THPFGLM' num2str(opts.tempsc) 'c.nii'];

                                % now we'll erase the original VTC and then
                                % save out the THPF-ed VTC,
                                delete('*.vtc*'); delete('*rtv*');
                                %! rm *.vtc* *rtv*
                                
                                % if this dataset is in native space, change reference space
                                % index.
                                if Params.Anatomyspace == 2
                                    filteredVTC.ReferenceSpace = 1;
                                end
                               
                                % If the user provides the BBox size, this
                                % will check to see if the VTC to save out
                                % is the same size as the user provided
                                % BBox. If the user does not provide a
                                % BBox, the script will just save the VTC
                                % as is.
                                if isfield(Params,'BBox') == 1
                                    bbox = Params.BBox;
                                    %bbox = tmpvtc.BoundingBox;
                                    origVTCBbox = filteredVTC.BoundingBox;
                                    if sum(sum(bbox ~= origVTCBbox.BBox)) ~= 0
                                        filteredVTCReframe = filteredVTC.Reframe(bbox);
                                        % Save out reframed, blurred, and filtered VTC.
                                        filteredVTCReframe.SaveAs(tmpunsmoothedtimecourse);
                                        clear blurredVTCReframe
                                    end
                                elseif isfield(Params,'BBox') ~= 1
                                    filteredVTC.SaveAs(tmpsmoothedtimecourse);
                                end
                               
                                % if reframing the VTC, do it here.
                                %tmpvtc = BVQXfile('new:vtc');
                                %bbox = tmpvtc.BoundingBox;
                                
                                %filteredVTCReframe = filteredVTC.Reframe(bbox.BBox);
                                
                                %filteredVTCReframe.SaveAs(tmpunsmoothedtimecourse);

                                %save also a nifti formatted file (this is for connectivity analyses in Conn).
                                %NrOfVols = size(filteredVTC.VTCData,1);
                                %filteredVTC.ExportNifti(tmpunsmoothedtimecoursenifti,1,1:NrOfVols);
                                
                                % clear VTCs from workspace
                                clear nativeVTC filteredVTC filteredVTCReframe tmpvtc
                                
                                % cd to subject folder to go to next run.
                                cd(tmpsubfolder);
                            % if we're smoothing, we use these parameters.
                            elseif Params.VTC.SmoothKernel > 0
                                %% now that we've copied the files we can work in the BV VTC folder.
                                cd(tmpVTCrunloc)
                                % remove VTCs that may already live here.
                                vtcdir = dir('THPFGLM2');
                                if isempty(vtcdir) ~= 1
                                delete('*THPFGLM2*');%! rm *THPFGLM2*
                                end
                                tmpniftifolder = tmpVTCrunloc;
                                %Params.BBox = [54    44    55; 236   181   201];
                                fMRIPrep_PreProcess_ConvertNiftiToVTC(tmpniftifolder,Params.fMRIParams,Params.VTC.VoxelSize);
                                delete('*.nii*');%! rm *.nii*

                                % now let's find the VTC file and THP filter the data.
                                vtcfile = dir('*.vtc');
                                if isempty(vtcfile)
                                error('No VTC found.');
                                elseif length(vtcfile) > 1
                                warning('Multiple VTCs found. Using first.');
                                end
                                % load in native VTC
                                %nativeVTC = BVQXfile(fullfile(tmpVTCrunloc,vtcfile(1).name));

                                % parameters for THPF
                                %opts = []; opts.temp = 1; opts.temphp = 2; %opts.tempsc = 2;
                                % parameters from j weber.
                                opts = struct('temp', true, 'tempsc', Params.VTC.THPF);

                                % load in native VTC
                                nativeVTC = BVQXfile(fullfile(tmpVTCrunloc,vtcfile(1).name));

                                % create a filtered VTC
                                filteredVTC = nativeVTC.Filter(opts);
                                tempsc2save = opts.tempsc;

                                % now we'll erase the original VTC and then save out the THP
                                % filtered VTC
                                delete('*.vtc*');
                                delete('*rtv*');
                                %! rm *.vtc* *rtv*

                                % parameters for spatial smoothing
                                opts = []; opts.spat = 1; opts.spkern = [Params.VTC.SmoothKernel,Params.VTC.SmoothKernel,Params.VTC.SmoothKernel];

                                % run spatial smoothing with the blurkernel input.
                                blurredVTC = filteredVTC.Filter(opts);

                                tmpsmoothedtimecourse = [subID '_' sessionID '_task-' Params.ExpNames(expi).Name '_run-' num2str(runi) '_Smoothed_' num2str(Params.VTC.SmoothKernel) 'MM_FWHM_THPFGLM' num2str(tempsc2save) 'c.vtc'];
                                % don't save out nifti version so we don't
                                % need filename but keep it here if we need
                                % it down the road.
                                %tmpsmoothedtimecoursenifti = ['Sub-' subID '_task-' taskID '_run-' num2str(runi) '_Smoothed_' num2str(blurkernel) 'MM_FWHM_THPFGLM' num2str(tempsc2save) 'c.nii'];


                                % if this dataset is in native space,
                                % change reference space index.
                                if Params.Anatomyspace == 2
                                    blurredVTC.ReferenceSpace = 1;
                                end
                               
                                % If the user provides the BBox size, this
                                % will check to see if the VTC to save out
                                % is the same size as the user provided
                                % BBox. If the user does not provide a
                                % BBox, the script will just save the VTC
                                % as is.
                                if isfield(Params,'BBox') == 1
                                    bbox = Params.BBox;
                                    %bbox = tmpvtc.BoundingBox;
                                    origVTCBbox = blurredVTC.BoundingBox;
                                    if sum(sum(bbox ~= origVTCBbox.BBox)) ~= 0
                                        blurredVTCReframe = blurredVTC.Reframe(bbox);
                                        % Save out reframed, blurred, and filtered VTC.
                                        blurredVTCReframe.SaveAs(tmpsmoothedtimecourse);
                                        clear blurredVTCReframe
                                    end
                                %if this isn't a field then we don't care.
                                %in this case, just ssve it.
                                elseif isfield(Params,'BBox') ~= 1
                                    blurredVTC.SaveAs(tmpsmoothedtimecourse);
                                end
                                %elseif exist('Params.BBox') == 0
                                %    tmpvtc = BVQXfile('new:vtc');
                                %    bbox = tmpvtc.BoundingBox;
                                %    origVTCBbox = blurredVTC.BoundingBox;
                                %    if sum(sum(bbox.BBox ~= origVTCBbox.BBox)) ~= 0
                                %        blurredVTCReframe = blurredVTC.Reframe(bbox.BBox);
                                %        % Save out reframed, blurred, and filtered VTC.
                                %        blurredVTCReframe.SaveAs(tmpsmoothedtimecourse);
                                %        clear blurredVTCReframe
                                %    else
                                %        blurredVTC.SaveAs(tmpsmoothedtimecourse);
                                % end
                                    %blurredVTC.SaveAs(tmpsmoothedtimecourse);

                                % if we want to save out a nii version.
                                % NrOfVols = size(filteredVTC.VTCData,1);
                                % blurredVTC.ExportNifti(tmpsmoothedtimecoursenifti,1,1:NrOfVols);
                                
                                % clear VTCs from workspace
                                clear blurredVTC filteredVTC nativeVTC tmpvtc
                                
                                % cd to subject folder to go to next run.
                                cd(tmpsubfolder);
                            end
                        end
                    end
                end
            end
        end
    end
end
%catch
%uiwait(msgbox({'There was an error in the CreateVTC code.'}));
%cd(Params.HomeDirectory);
%end