function [NiftiPaths, ASLContext] = xASL_bids_MergeNifti(NiftiPaths, seqType)
%xASL_bids_MergeNifti Take a list of NIfTI files and concatenates 3D/4D files into a 4D sequence if possible
%
% FORMAT: NiftiPaths = xASL_bids_MergeNifti(NiftiPaths, seqType)
% 
% INPUT:
%   NiftiPaths - cell containing list of strings with full paths of the files (REQUIRED)
%   seqType    - Type of the file - can be 'M0' or 'ASL' (REQUIRED)
%
% OUTPUT:
% NiftiPaths   - return either the same list of files if nothing was done or the path to the newly created file
% ASLContext   - ASL context, for example [deltam,m0] (CHAR ARRAY)
%
% -----------------------------------------------------------------------------------------------------------------------------------------------------
% DESCRIPTION: This function takes a list of M0 or ASL4D files and concatenates them together in a longer 4D volume if possible
%              following certain patterns: works only with 3D and 4D files; all files in the list must have the same size of the
%              first three dimensions; files are generarily sorted according to the last number in the filename and outputted
%              to M0.nii or ASL4D.nii; first JSON is taken and renamed, all other JSONs and NIIs are deleted after merging;
%              M0*_parms.m or ASL*_parms.mat is renamed to M0_parms.m or ASL4D_parms.m; M0 files are checked if the field 
%              PhaseEncodingAxis is consistent through all the volumes, if not the nothing is merged; this is applied to a generic case
%              and 3 other specific Siemens scenarios are implemented:
%
%              - i) All NII files have two volumes, then simply concatenate according to the last number.
%              - ii) Two files with a single volume each are merged according to the last number in the file name.
%              - iii) Multiple files with each containing a single volume are sorted to tags ASL4D_x_x_Y and controls ASL4D_Y and merged in the order
%                   of the last number in the filename (Y) alternating the tags and controls
%
%              This function performs the following steps in subfunctions:
%
%              1. xASL_bids_MergeNifti_M0Files Generic merging of M0 files
%              2. xASL_bids_MergeNifti_GEASLFiles Merge GE ASL files and extract scan order from DICOM tags
%              3. xASL_bids_MergeNifti_SiemensASLFiles Merge Siemens ASL files with specific filename pattern
%              4. xASL_bids_MergeNifti_AllASLFiles Merge any ASL files
%              5. xASL_bids_MergeNifti_Merge Merge NiftiPaths & save to pathMerged
%              6. xASL_bids_MergeNifti_Delete Delete NiftiPaths and associated JSONs
%              7. xASL_bids_MergeNifti_RenameParms Find *_parms.m files in directory and shorten to provided name
%
% EXAMPLE:     n/a
%
% -----------------------------------------------------------------------------------------------------------------------------------------------------
% __________________________________
% Copyright 2015-2020 ExploreASL, JP


%% Admin
if nargin < 1 || isempty(NiftiPaths)
	error('Requires a list of files as input');
end

if nargin < 2 || isempty(seqType)
	error('Files type need to be provided as M0 or ASL');
else
	if ~strcmp(seqType, 'M0') && ~strcmp(seqType, 'ASL')
		error('seqType must be either M0 or ASL');
	end
end

% Fallback
ASLContext = '';

if length(NiftiPaths)>1
	switch (seqType)
    case 'M0'
        % Merges the M0 files
        pathOut = xASL_bids_MergeNifti_M0Files(NiftiPaths);

    case 'ASL'
		% Run the GE merging procedure first, that returns an empty path if not all conditions are met
		[pathOut,ASLContext] = xASL_bids_MergeNifti_GEASLFiles(NiftiPaths);
		
        % Merges Siemens ASL file if they have the known pattern of filenames
		if isempty(pathOut)
			pathOut = xASL_bids_MergeNifti_SiemensASLFiles(NiftiPaths);
		end

        % Generic merging of ASL4D files for non-Siemens, or Siemens files with an unknown pattern
        if isempty(pathOut)
            % If the previous Siemens merging didn't merge them already
            pathOut = xASL_bids_MergeNifti_AllASLFiles(NiftiPaths);
        end
	end
end

% If the merging worked, return the merged path
if ~isempty(pathOut)
	NiftiPaths = {pathOut};
end

end


%% ==========================================================================
%% ==========================================================================
function pathOut = xASL_bids_MergeNifti_M0Files(NiftiPaths)
%xASL_bids_MergeNifti_M0Files Generic merging of M0 files

bCheckConsistency = 1; % So far, no error was found and files can be concatenated
pathOut = ''; % Newly assigned path of a concatenated file
listEndNumber = zeros(length(NiftiPaths),1);

% Go through all JSONs
for iFile=1:length(NiftiPaths)
	[Fpath, Ffile] = xASL_fileparts(NiftiPaths{iFile});
	jsonParms = spm_jsonread(fullfile(Fpath, [Ffile, '.json']));
	
	% List the end number from the file name
	[iStart, iEnd] = regexp(Ffile,'\d*$');
	listEndNumber(iFile) = str2double(Ffile(iStart:iEnd));
	
	% Compare the PEAxis and PEDirection and check that it is the same for all of the M0-files
	if iFile == 1
		if isempty(jsonParms) || ~isfield(jsonParms,'PhaseEncodingAxis')
			strPEAxis = '';
		else
			strPEAxis = jsonParms.PhaseEncodingAxis;
		end
		
		if isempty(jsonParms) || ~isfield(jsonParms,'PhaseEncodingDirection')
			strPEDirection = '';
		else
			strPEDirection = jsonParms.PhaseEncodingDirection;
		end
	else
		if isempty(jsonParms) || ~isfield(jsonParms,'PhaseEncodingAxis')
			if ~isempty(strPEAxis)
				bCheckConsistency = 0;
			end
        elseif ~strcmp(strPEAxis,jsonParms.PhaseEncodingAxis)
				bCheckConsistency = 0;
		end
		
		if isempty(jsonParms) || ~isfield(jsonParms,'PhaseEncodingDirection')
			if ~isempty(strPEDirection)
				bCheckConsistency = 0;
			end
        elseif ~strcmp(strPEDirection,jsonParms.PhaseEncodingDirection)
				bCheckConsistency = 0;
		end
	end
end

% Check if there's no difference in AP-PA direction, if all are the same, then start merging
if bCheckConsistency
	[~, indexSortedFile] = sort(listEndNumber);
	pathOut = xASL_bids_MergeNifti_Merge(NiftiPaths, indexSortedFile, 'M0', 0);
	
	if ~isempty(pathOut)
		xASL_bids_MergeNifti_RenameParms(Fpath, 'M0');
		xASL_bids_MergeNifti_Delete(NiftiPaths);
		fprintf('Corrected dcm2niiX output for\n');
		fprintf('%s\n', pathOut);
	end
end


end

%% ==========================================================================
%% ==========================================================================
function [pathOut,ASLContext] = xASL_bids_MergeNifti_GEASLFiles(NiftiPaths)
%xASL_bids_MergeNifti_GEASLFiles merge any ASL files in alphabetical order, but also load and use the GE ASL 
% tags and save them to a correct ASL context
%
% Description: Uses the GE ImageType tag to sort out the files correctly and saves this order

% By default, the conversion did not work
pathOut = ''; 

% And ASLContext is empty
ASLContext = '';

% Goes through all files
for iFile=1:length(NiftiPaths)
	% For each file, finds the JSONs
	[jsonPath,jsonName,~] = fileparts(NiftiPaths{iFile});
	jsonPath = fullfile(jsonPath, [jsonName, '.json']);
		
	% Loads the JSON file
	if exist(jsonPath,'file')
		jsonPar = spm_jsonread(jsonPath);
	else
		fprintf('Warning: Non-existent JSON sidecar: %s\n',jsonPath) ;
		jsonPar = [];
	end
		
	% Finds the manufacturer of the file
	if ~isempty(jsonPar) && isfield(jsonPar,'Manufacturer')
		varManufacturer = jsonPar.Manufacturer;
	else
		varManufacturer = '';
	end
		
	% If GE is not identified or ImageType field doesn't exist, then exits
	if isempty(regexpi(varManufacturer,'GE')) || ~isfield(jsonPar,'ImageType')
		return;
	end
	
	% Starts looking for the correct image type
	imageType = xASL_bids_determineImageTypeGE(jsonPar);

	% If imageType is not identified for all scans, then skip this one
	if isempty(imageType)
		return;
	end
	
	% Save this to the ASL context
	if isempty(ASLContext)
		ASLContext = imageType;
	else
		ASLContext = [ASLContext,',',imageType];
	end
end

% Merges all the files together
pathOut = xASL_bids_MergeNifti_Merge(NiftiPaths,1:length(NiftiPaths),'ASL4D',0);

% If this worked
if ~isempty(pathOut)
	% And adds the ASLContext to the JSON
	[jsonPath,jsonName,~] = fileparts(pathOut);
		
	jsonPar = spm_jsonread(fullfile(jsonPath, [jsonName, '.json']));
	jsonPar.ASLContext = ASLContext;
	jsonPar = rmfield(jsonPar,'ImageType');
	spm_jsonwrite(fullfile(jsonPath, [jsonName, '.json']),jsonPar);
	
	% And deletes the old files
	xASL_bids_MergeNifti_RenameParms(jsonPath,'ASL4D');
	xASL_bids_MergeNifti_Delete(NiftiPaths);
	
	fprintf('Corrected dcm2niiX output for GE files and found the correct scan order:\n');
	fprintf('%s\n', pathOut);
	fprintf('%s\n', ASLContext);
end

end


%% ==========================================================================
%% ==========================================================================
function pathOut = xASL_bids_MergeNifti_AllASLFiles(NiftiPaths)
%xASL_bids_MergeNifti_AllASLFiles Merge any ASL files
%
% Description: First rename the NIfTI and JSON files to 4 digit format & sort them

listEndNumber = zeros(length(NiftiPaths),1);
for iFile=1:length(NiftiPaths)
	[Fpath, Ffile] = xASL_fileparts(NiftiPaths{iFile});
	
	% List the end number from the file name
	[iStart, iEnd] = regexp(Ffile,'\d*$');
	listEndNumber(iFile) = str2double(Ffile(iStart:iEnd));
end
[~, indexSortedFile] = sort(listEndNumber);
pathOut = xASL_bids_MergeNifti_Merge(NiftiPaths,indexSortedFile,'ASL4D',0);

if ~isempty(pathOut)
	xASL_bids_MergeNifti_RenameParms(Fpath,'ASL4D');
	xASL_bids_MergeNifti_Delete(NiftiPaths);
	fprintf('Corrected dcm2niiX output for following files:\n');
	fprintf('%s\n', pathOut);
end

end


%% ==========================================================================
%% ==========================================================================
function pathOut = xASL_bids_MergeNifti_Merge(NiftiPaths,indexSortedFile,nameMerged,bAlternatingControlLabel)
%xASL_bids_MergeNifti_Merge Merge NiftiPaths & save to pathMerged
% 
% Description: % Save also the first JSON to pathMerged.JSON

bStatus = 1; % track if all went well
pathOut = '';
firstJSON = '';
% Start loading all the files
for iFile=1:length(NiftiPaths)
	tempIM = xASL_io_Nifti2Im(NiftiPaths{indexSortedFile(iFile)});
	
	% Merging only 3D and 4D files
	if length(size(tempIM))>4
		error('Dimensionality incorrect for this ASL NIfTI file');
	end
	
	% Compare size of the new file and if similar to the previous than concatenate, otherwise report an error
	if iFile == 1
		sizeFirst = size(tempIM);
		sizeFirst = sizeFirst(1:3);
	else
		sizeNew = size(tempIM);
		sizeNew = sizeNew(1:3);
		if ~isequal(sizeNew, sizeFirst)
			bStatus = 0;
		end
	end
	
	if bAlternatingControlLabel
		% Always interlace the two following files
		% For the first file, create the interleaved first volume
		if iFile == 1
			lengthFirst = size(tempIM,4);
			IM = zeros([sizeFirst,lengthFirst*2]);
			IM(:,:,:,1:2:end) = tempIM;
		elseif mod(iFile,2)
			% For odd files, create a new interleaved addition
			lengthFirst = size(tempIM,4);
			IM(:,:,:,end+1:end+2*lengthFirst) = zeros([sizeFirst,lengthFirst*2]);
			IM(:,:,:,end+2:2:end+2*lengthFirst) = tempIM;
		else
			% For even files - fill in the interleave spaces
			IM(:,:,:,end-2*lengthFirst+2:2:end) = tempIM;
		end
	else
		% Simply merge files in the order in which they come
		if iFile==1
			% Get the size of the first file
			IM = tempIM;
		else
			if bStatus
				IM(:,:,:,end+1:end+size(tempIM,4)) = tempIM;
			end
		end
	end
	
	% Check for the path to JSON if existing and keep only the first existing JSON
	if isempty(firstJSON)
		[Fpath, Ffile] = xASL_fileparts(NiftiPaths{indexSortedFile(iFile)});
		pathJSON = fullfile(Fpath,[Ffile '.json']);
		if exist(pathJSON, 'file')
			firstJSON = pathJSON;
		end
	end
end

% If at the end and all went well
if bStatus
    fprintf('Warning: concatenating multiple NIfTIs & jsons as output from dcm2niiX\n');
    % Save the concatenated file to a given name
    pathOut = fullfile(Fpath,[nameMerged '.nii']);
    xASL_io_SaveNifti(NiftiPaths{indexSortedFile(1)}, pathOut, IM, [], 0);
    % Special treatment for Hadamard encoded files
    EchoTimes = cell(size(NiftiPaths,2),1);
    for iFileCheck = 1:size(NiftiPaths,2)
        % Get JSON
        [jsonPathX, jsonNameX] = xASL_fileparts(NiftiPaths{iFileCheck});
        if exist(fullfile(jsonPathX, [jsonNameX '.json']),'file')
            tmpCheckJSON = spm_jsonread(fullfile(jsonPathX, [jsonNameX '.json']));
            % Check EchoTimes
            if isfield(tmpCheckJSON,'SeriesDescription')
                isHadamardFME = ~isempty(regexp(char(tmpCheckJSON.SeriesDescription),'(Encoded_Images_Had)\d\d(_)\d\d(_TIs_)\d\d(_TEs)', 'once'));
                if isHadamardFME
                    if isfield(tmpCheckJSON,'EchoTime')
                        EchoTimes{iFileCheck,1} = tmpCheckJSON.EchoTime;
                    end
                end
            end
        end
    end
    % Add echo number array if it exists
    if sum(~cellfun(@isempty,EchoTimes))~=0
        fprintf('Merging the echo numbers of the Hadamard encoded sequence...\n');
        % Sort echo numbers
        if length(indexSortedFile)==length(EchoTimes)
            EchoTimesBackUp = EchoTimes;
            for iEchoNumber=1:length(EchoTimes)
                EchoTimes(indexSortedFile(iEchoNumber)) = EchoTimesBackUp(iEchoNumber,1);
            end
        end
        if ~issorted(cell2mat(EchoTimes))
            fprintf('Warning: echo times do not increase, resorting will be applied...\n');
            try
                EchoTimes = sortrows(EchoTimes',1)';
            catch
                fprintf('Sorting failed...\n');
            end
        end
        % Write changes to JSON
        structFirstJSON = spm_jsonread(firstJSON);
        structFirstJSON.EchoTime = EchoTimes;
        spm_jsonwrite(firstJSON, structFirstJSON);
    end
    % Copy the first JSON to this name
    if ~isempty(firstJSON)
        xASL_Copy(firstJSON,fullfile(Fpath,[nameMerged '.json']),1);
    end
else
	fprintf('Warning: Cannot concatenate multiple NIfTIs & jsons as output from dcm2niiX\n');
end


end


%% ==========================================================================
%% ==========================================================================
function xASL_bids_MergeNifti_Delete(NiftiPaths)
%xASL_bids_MergeNifti_Delete Delete NiftiPaths and associated JSONs

for iFile=1:length(NiftiPaths)
	[Fpath, Ffile] = xASL_fileparts(NiftiPaths{iFile});
	
	xASL_delete(NiftiPaths{iFile});
	
	pathJSON = fullfile(Fpath,[Ffile '.json']);
	% Delete JSONs
    xASL_delete(pathJSON); % already checks if exists before deleting
end


end


%% ==========================================================================
%% ==========================================================================
function xASL_bids_MergeNifti_RenameParms(Fpath,Fname)
%xASL_bids_MergeNifti_RenameParms Find *_parms.m files in directory and shorten to provided name

FileList = xASL_adm_GetFileList(Fpath, '^.*_parms\.mat$', 'List', [], false);

if ~isempty(FileList)
	xASL_Move(fullfile(Fpath, FileList{1}), fullfile(Fpath,[Fname '_parms.mat']));
end


end