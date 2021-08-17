function xASL_bids_AddGeneratedByField(x, pathJSONin, pathJSONout)
%xASL_bids_AddGeneratedByField Add the generated by field to the struct.
%
% FORMAT:     xASL_bids_AddGeneratedByField(x, pathJSONin[, pathJSONout])
% 
% INPUT:      x           - ExploreASL x struct (STRUCT, REQUIRED)
%             pathJSONin  - Path to input JSON file (STRING, REQUIRED)
%             pathJSONout - Path to output JSON file (STRING, OPTIONAL)
%   
% OUTPUT:     n/a
%                         
% -----------------------------------------------------------------------------------------------------------------------------------------------------
% DESCRIPTION: Add the generated by field to the struct.
% 
% -----------------------------------------------------------------------------------------------------------------------------------------------------
% EXAMPLE:     xASL_bids_AddGeneratedByField(x, pathJSONin, pathJSONout);
% __________________________________
% Copyright 2015-2021 ExploreASL


    % If only one path is provided, then overwrite original file
    if nargin<3
        pathJSONout = pathJSONin;
    end

    % Check if input JSON exists
    if xASL_exist(pathJSONin,'file')==2
        % Load JSON file
        thisJSON = spm_jsonread(pathJSONin);
        % Add "GeneratedBy" field
        thisJSON.GeneratedBy = struct;
        thisJSON.GeneratedBy.Name = 'ExploreASL';
        thisJSON.GeneratedBy.Version = x.Version;
        spm_jsonwrite(pathJSONout, thisJSON);
    else
        warning('Adding the "GeneratedBy" JSON field failed...');
    end

end



