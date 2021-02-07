%% BIDS testing script

% 1. DICOM2BIDS
% 2. BIDS2legacy
% 3. ExploreASL

%% 0. Admin

clc

DirExploreASL = '/Users/henk/ExploreASL/ExploreASL';
cd(DirExploreASL);

addpath(fullfile('Development', 'BIDS'));

ROOT = '/Users/henk/ExploreASL/ASL/TestBIDS';
ListFolders = xASL_adm_GetFileList(ROOT, '^rawdata$', 'FPListRec', [0 Inf], 1);

for iList=1:numel(ListFolders)
    %% 1. DICOM2BIDS
    
    
    %% 2. BIDS2Legacy
    DerivativesDir = fullfile(fileparts(ListFolders{iList}), 'derivatives');
    if ~isunix
        warning('Here we expect a unix-ish system');
    end
    if exist(DerivativesDir, 'dir')
        diary('off');
        fclose('all'); % ensure that no file is locked
        system(['rm -rf ' DerivativesDir]);
    end

    xASL_bids_BIDS2Legacy(ListFolders{iList});
    
    %% 3. Run ExploreASL
    PathDataPar = fullfile(DerivativesDir, 'ExploreASL', 'DataPar.json');
    ExploreASL_Master(PathDataPar, 1, 1);
    
end