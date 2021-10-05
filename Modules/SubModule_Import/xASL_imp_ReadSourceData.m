function x = xASL_imp_ReadSourceData(x)
%xASL_imp_ReadSourceData Read source data
%
% FORMAT: x = xASL_imp_ReadSourceData(x)
%
% INPUT:
%   x        - Struct containing pipeline environment parameters, useful when only initializing ExploreASL/debugging (REQUIRED, STRUCT)
%
% OUTPUT:
%   x                         - Struct containing pipeline environment parameters, useful when only initializing ExploreASL/debugging
%   x.modules.import.matches  - Matched files/directories
%   x.modules.import.tokens   - Tokens of files/directories
%
% -----------------------------------------------------------------------------------------------------------------------------------------------------
% DESCRIPTION:    Read source data.
%
% -----------------------------------------------------------------------------------------------------------------------------------------------------
% EXAMPLE:        n/a
% __________________________________
% Copyright 2015-2021 ExploreASL


    %% Check if directories are files are supposed to be matched
    if x.modules.import.imPar.bMatchDirectories
        strLookFor = 'Directories';
    else
        strLookFor = 'Files';
    end
    
    
    %% Start with defining the subjects, visits, sessions (i.e. BIDS runs) and scans (i.e. ScanTypes) by listing or typing
    
    % Recursively scan the directory tree using regular exspressions at each directory level. Use ()-brackets to extract tokens
    % that will be used to identify subjects, sessions and scans. In the loop below it is possible to translate the tokens
    % to more convenient strings before using them in destination paths.
    
    % Run the regexp search function
    [x.modules.import.matches, x.modules.import.tokens] = xASL_adm_FindByRegExp(...
        x.modules.import.imPar.RawRoot, x.modules.import.imPar.folderHierarchy, 'StripRoot', true, 'Match', strLookFor,'IgnoreCase',true);
    
    % Print feedback if there are no matching files
    if isempty(x.modules.import.matches)
        warning('No matching files, skipping...');
        return;
    end
    
    % Copy the columns into named vectors. This construction allows for arbitrary directory hierarchies.
    
    % Make sure to select the columns that correspond to the folder ordering defined using the regular expressions above.
    
    % Define Subjects (vSubjectIDs: cell vector with extracted subject IDs (for all visits, sessions and scans)
    x.modules.import.listsIDs.vSubjectIDs = x.modules.import.tokens(:,x.modules.import.imPar.tokenOrdering(1));


end



