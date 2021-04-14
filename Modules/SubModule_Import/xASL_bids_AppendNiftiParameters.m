function s = xASL_bids_AppendNiftiParameters(nii_files)
%xASL_bids_AppendNiftiParameters Append Nifti Parameters.
%
% FORMAT: s = xASL_bids_AppendNiftiParameters(nii_files)
% 
% INPUT:
%   nii_files  - List of NIFTI files.
%
% OUTPUT:
%   s          - String
%                         
% -----------------------------------------------------------------------------------------------------------------------------------------------------
% DESCRIPTION: Append Nifti Parameters.
% -----------------------------------------------------------------------------------------------------------------------------------------------------
% EXAMPLE:     s = xASL_bids_AppendNiftiParameters(nii_files);
% __________________________________
% Copyright 2015-2021 ExploreASL

    %% Append Nifti Parameters

    % This function outputs s = [FileName voxel size XYZ matrix size XYZ]
    s = [];

    if ischar(nii_files)
        nii_files = {nii_files};
    end

    for iNii=1:length(nii_files)
        [~, Ffile, Fext] = fileparts(nii_files{iNii});
        s = sprintf(',"%s"', [Ffile Fext]); % filename

        tempnii = xASL_io_ReadNifti(nii_files{iNii});
        s = [s sprintf(',%g', tempnii.hdr.pixdim(2:5) )]; % voxel size XYZ
        s = [s sprintf(',%g', tempnii.hdr.dim(2:5) )]; % matrix size XYZ
    end
    
end



