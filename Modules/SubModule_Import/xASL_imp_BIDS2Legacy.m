function [x] = xASL_imp_BIDS2Legacy(x)
%xASL_imp_BIDS2Legacy BIDS2LEGACY conversion script which calls xASL_bids_BIDS2Legacy.
%
% FORMAT: [x] = xASL_imp_BIDS2Legacy(x);
%
% INPUT:
%   x             - Struct containing pipeline environment parameters, useful when only initializing ExploreASL/debugging
%
% OUTPUT:
%   x             - Struct containing pipeline environment parameters, useful when only initializing ExploreASL/debugging
%
% -----------------------------------------------------------------------------------------------------------------------------------------------------
% DESCRIPTION:    BIDS to Legacy conversion script which calls xASL_bids_BIDS2Legacy.
%
% 1. Go through all studies
% 2. Convert only those containing raw data
% - 1. Clean the old data
% - 2. Run the legacy conversion: Check if a dataPar is provided, otherwise use the defaults
% 3. Overwrite DataParPath
%
% -----------------------------------------------------------------------------------------------------------------------------------------------------
% EXAMPLE:        n/a
% __________________________________
% Copyright 2015-2021 ExploreASL


    %% 1. Start with checking dataset_description.json & rawdata
    [Fpath, Ffile, Fext] = fileparts(x.DataParPath);
    if ~strcmp([Ffile Fext], 'dataset_description.json')
        error('Input argument should be dataset_description.json, invalid input');
    end
    [x.StudyRoot, Ffile] = fileparts(Fpath);
    if ~strcmp(Ffile, 'rawdata')
        error('Invalid folder in which dataset_description.json was found, should be /rawdata');
    end
    
    %% 2.1 Clean the old data
    dirDerivatives = fullfile(x.StudyRoot, 'derivatives');
    % Note that we cannot remove derivatives here! This can potentially
    % contain output from other pipelines...
    
    % Also the cleaning of old data is done properly in xASL_bids_BIDS2Legacy

    %% 2.2 Run the legacy conversion: Check if a dataPar is provided, otherwise use the defaults
    fListDataPar = xASL_adm_GetFileList(x.StudyRoot,'(?i)(^dataPar.*\.json$)', 'FPList', [], 0);
    if isempty(fListDataPar)
        fprintf('There is no dataPar.json file in the study root directory. Default settings will be used...\n');
        % Fill the dataPars with default parameters
        dataPar = xASL_bids_BIDS2Legacy(x.StudyRoot, 1, []);
    else
        % Fill the dataPars with the provided parameters
        dataPar = spm_jsonread(fListDataPar{1});
        dataPar = xASL_bids_BIDS2Legacy(thisRootFolder, 1, dataPar);
    end

    
    %% 3. Overwrite DataParPath
    x.DataParPath = dataPar.x.DataParPath;


%     %% 1. Go through all studies
%     ListFolders = xASL_adm_GetFileList(x.StudyRoot, '^.+$', 'FPListRec', [0 Inf], 1);
%     for iList=1:numel(ListFolders)
%         %% 2. Convert only those containing raw data
%         [thisRootFolder,thisFolderName,~] = xASL_fileparts(ListFolders{iList});
%         if strcmp(thisFolderName,'rawdata') && exist(ListFolders{iList},'dir')
%             
%             %% 2.1 Clean the old data
%             if exist(fullfile(ListFolders{iList}, 'derivatives'), 'dir')
%                 fprintf('Delete existing derivatives folders...\n');
%                 diary('off');
%                 fclose('all'); % ensure that no file is locked
%                 xASL_delete(fullfile(ListFolders{iList}, 'derivatives'),true);
%             end
% 
%             %% 2.2 Run the legacy conversion: Check if a dataPar is provided, otherwise use the defaults
%             fListDataPar = xASL_adm_GetFileList(x.StudyRoot,'(?i)(^dataPar.*\.json$)', 'FPList', [], 0);
%             if length(fListDataPar) < 1
%                 fprintf('There is no dataPar.json file in the study root directory. Default settings will be used...\n');
%                 % Fill the dataPars with default parameters
%                 dataPar = xASL_bids_BIDS2Legacy(thisRootFolder, 1, []);
%             else
%                 % Fill the dataPars with the provided parameters
%                 dataPar = spm_jsonread(fListDataPar{1});
%                 dataPar = xASL_bids_BIDS2Legacy(thisRootFolder, 1, dataPar);
%             end
%         end
%     end
%     
%     %% 3. Overwrite DataParPath
%     x.DataParPath = dataPar.x.DataParPath;
    
    
end


