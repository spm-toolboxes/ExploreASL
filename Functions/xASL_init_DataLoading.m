function [x] = xASL_init_DataLoading(x)
%xASL_init_DataLoading Load dataset by adding relevant fields to xASL x struct
%
% FORMAT: [x] = xASL_init_DataLoading(x)
% 
% INPUT:
%   x          - ExploreASL x structure (STRUCT, REQUIRED)
%
% OUTPUT:
%   x          - ExploreASL x structure
%                         
% -----------------------------------------------------------------------------------------------------------------------------------------------------
% DESCRIPTION:    Load dataset by adding relevant fields to xASL x struct.
%
% -----------------------------------------------------------------------------------------------------------------------------------------------------
% EXAMPLE:        [x] = xASL_init_DataLoading(x);
% __________________________________
% Copyright 2015-2021 ExploreASL


    %% Data loading
    
    % Skip this step if we still need to run the import (first initialization)
    if (x.opts.bProcessData || x.opts.bOnlyLoad) && ~x.opts.bImportData
        % Check if a root directory was defined
        if ~isfield(x.D,'ROOT') || isempty(x.D.ROOT)
            error('No root folder defined');
        end

        % Fix a relative path
        if strcmp(x.D.ROOT(1), '.')
            cd(x.D.ROOT);
            x.D.ROOT = pwd;
        end
        
        % Make sure that the derivatives folder exists (otherwise we can not load a dataset)
        if ~xASL_exist(fullfile(x.dir.DatasetRoot,'derivatives'))
            % This warning is also printed if a user tries to "only load" a dataset with a descriptive JSON file. 
            % Since this behavior will be discontinued (only directories from now on), I do not see a problem with this for now.
            warning('Dataset can not be loaded, there is no derivatives directory, try to run the import first...');
        end

        % Define study subjects/parameters for this pipeline run
        x = xASL_init_DefineStudyData(x);


        % Remove lock dirs from previous runs, if ExploreASL is not running in parallel
        if x.opts.nWorkers==1
            x = xASL_init_RemoveLockDirs(x);
        end

        % Define & print settings
        x = xASL_init_PrintCheckSettings(x);
    end


end


