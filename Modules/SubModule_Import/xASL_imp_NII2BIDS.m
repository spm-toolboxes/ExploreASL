function x = xASL_imp_NII2BIDS(x, imPar)
%xASL_imp_NII2BIDS Run the NII2BIDS conversion.
%
% FORMAT: x = xASL_imp_NII2BIDS(x, imPar, studyPath, studyParPath)
% 
% INPUT:
%   x               - ExploreASL x structure (REQUIRED, STRUCT)
%   imPar           - JSON file with structure with import parameters (REQUIRED, STRUCT)
%
% OUTPUT:
%   x               - ExploreASL x structure (STRUCT)
%                         
% -----------------------------------------------------------------------------------------------------------------------------------------------------
% DESCRIPTION: Run the NII2BIDS conversion.
%
% 1. Load the study parameters + dataset description
% 2. Create the study description output and verify that all is there
% 3. Go through all subjects and check all the M0 and ASLs and modify the JSONs
%
% -----------------------------------------------------------------------------------------------------------------------------------------------------
% EXAMPLE:     xASL_imp_NII2BIDS(x, imPar, studyPath, studyParPath);
%
% __________________________________
% Copyright 2015-2021 ExploreASL


    %% Run the NII2BIDS conversion
    
    % We may need to restart the logging
    diary(fullfile(x.dir.DatasetRoot,'derivatives','ExploreASL','xASL_module_Import.log'));
    
    % Print feedback
    fprintf('\n================================== NIFTI to BIDS CONVERSION ==================================\n');
    
    % We do not iterate over subjects anymore, since this is done in xASL_Iteration now
    iSubject = strcmp(x.SUBJECT,x.SUBJECTS);
    subjectName = x.SUBJECTS{iSubject};
    
    % Check if the temp folder exists
    existTempRoot = xASL_exist(fullfile(x.dir.DatasetRoot,'derivatives','ExploreASL','temp'),'dir');
    if ~existTempRoot
        error('The temp directory does not exist. Please run DICOM to NIfTI on your sourcedata first...');
    end

    % Loads the general configuration necessary for the conversion and BIDS saving
	bidsPar = xASL_bids_Config();
	
	%% 1. Load the study parameters + dataset description
	if ~exist(x.dir.studyPar,'file')
		warning('Study-par file is not provided.');
		studyPar = struct;
	else
		studyPar = xASL_io_ReadDataPar(x.dir.studyPar, true);
	end
	
	% The name always has to be assigned
	if ~isfield(studyPar,'Name')
		studyPar.Name = imPar.studyID;
	end
	
	%% 2. Create the study description output and verify that all is there
	datasetDescription = xASL_bids_CreateDatasetDescriptionTemplate(studyPar, x.Version);
	
	% Make the output directory and save the description
    if xASL_exist(imPar.BidsRoot,'dir')
        fprintf('The rawdata BIDS directory exists already...\n');
    else
        xASL_adm_CreateDir(imPar.BidsRoot);
    end
	
	spm_jsonwrite(fullfile(imPar.BidsRoot,[bidsPar.datasetDescription.filename '.json']),datasetDescription);
	
	%% 3. Go through all subjects and check all the M0 and ASLs and modify the JSONs
	% This step should be completely automatic, just taking the info filled above and using it to convert to full BIDS.
    
	% Go through all subjects
	listSubjectsSessions = xASL_adm_GetFileList(imPar.TempRoot,[],false,[],true);
    for iSubjectSession = 1:length(listSubjectsSessions)
        % Only run it for the current subject (maybe we can do this more elegantly in the future)
        if ~isempty(regexpi(listSubjectsSessions{iSubjectSession},subjectName))
            x = xASL_imp_NII2BIDS_Subject(x,imPar,bidsPar,studyPar,listSubjectsSessions{iSubjectSession});
        end
    end
    
    % Copy log files
    importMetaFiles = xASL_adm_GetFileList(imPar.TempRoot,'^import.+$');
    for importFile=1:size(importMetaFiles,1)
        [~,thisFileMeta,thisExtensionMeta] = xASL_fileparts(importMetaFiles{importFile,1});
        xASL_Copy(importMetaFiles{importFile,1},fullfile(x.dir.DatasetRoot,[thisFileMeta thisExtensionMeta]));
    end
    
    % Delete temp folder
    % xASL_delete(imPar.TempRoot, true);
    
    % Update x.opts.DatasetRoot
    x = xASL_imp_UpdateDatasetRoot(x);

end



