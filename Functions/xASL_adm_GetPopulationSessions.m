function [nSessions, bSessionsMissing] = xASL_adm_GetPopulationSessions(x)
% xASL_adm_GetPopulationSessions(x) obtain number of Sessions by determining amount of input files present in the Population folder
% FORMAT: [nSessions, bSessionsMissing] = xASL_adm_GetPopulationSessions(x)
%
% INPUT:
%   x                   - struct containing statistical pipeline environment parameters (REQUIRED)
%
% OUTPUT:
%   nSessions           - Maximum amount of sessions present in Population folder
%   bSessionsMissing    - Boolean to show if no sessions can be found in the Population folder
% -----------------------------------------------------------------------------------------------------------------------------------------------------
% DESCRIPTION: This function looks for the maximum amount of sessions that
% are present in selected processed files present in the Population folder.
%
%   1. Determine which files to look for in the Population folder
%   2. Obtain list of session files in the Population folder
%   3. Determine unique amount of session numbers present in list
%   4. Set nSessions as highest unique session number 
%   5. Check and provide warning of number of sesssions differs per subject

%% 1. Administration
currentSubjectRegExp = x.subject_regexp;
if strcmp(currentSubjectRegExp(1), '^')
    currentSubjectRegExp = currentSubjectRegExp(2:end);
end
if strcmp(currentSubjectRegExp(end), '$')
    currentSubjectRegExp = currentSubjectRegExp(1:end-1);
end
% 2. Look for processed files from which to determine the amount of sessions present
SessionList = xASL_adm_GetFileList(x.D.PopDir,['^' x.S.InputDataStr '_' currentSubjectRegExp '_ASL_\d*\.nii$'], 'FPList', [0 Inf]);

%% 3. Obtain nSessions
if isempty(SessionList) % If no files found, search for subject files instead of session files
    if isempty(xASL_adm_GetFileList(x.D.PopDir,'^qCBF.*\.nii', 'FPList', [0 Inf]))
        fprintf('%s\n','No session or subject files found');
        return;
    end
    nSessions = 1;
    bSessionsMissing = 1;
else % If files found, continue with defining sessions from SessionList
    IndexStart = cellfun(@(y) regexp(y,'ASL_\d+\.(nii|nii\.gz)'), SessionList);
    
    for iSession = 1:numel(SessionList)
        StringLoc = IndexStart(iSession); % String location
        NewList{iSession,1} = SessionList{iSession}(1,StringLoc:end); % create a cell array containings characters of all session numbers present
    end
    
    UniqueSessions = unique(cell2mat(NewList),'rows'); % determine unique session numbers
    % 4. define nSessions as highest unique session number
    nSessions = size(UniqueSessions,1); 
    bSessionsMissing = 0;
    NewList = cellstr(NewList);
    for oSession = 1:nSessions
        CountSessionNumbers(oSession)= sum(~cellfun('isempty',strfind(NewList,num2str(oSession)))); % Counts amount of individual session numbers
    end
    
    % 5. Check and provide warning of number of sesssions differs per subject
    CompareSessions = ones(1,size(CountSessionNumbers,2)) .* nSessions; % create an array to check differences in sessions per subject with maximum amount of sessions
    if ~isequal(CountSessionNumbers,CompareSessions) % Check if amount of sessions is similar for each subject and provide warning if not
        warning('Amount of Sessions differs between Subjects');
    end
end

end