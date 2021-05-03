function xASL_im_ReplaceLabel(pathNifti, LabelNumbersOld, LabelNumbersNew, pathNewNifti)
%xASL_im_ReassignLabel Replace labels in a NIfTI image (e.g. ROIs)
%
% FORMAT: xASL_im_ReplaceLabel(pathNifti, LabelNumbersOld, LabelNumbersNew, pathNewNifti)
%
% INPUT:
%   pathNifti           - path to NIfTI file (REQUIRED)
%                         NIfTI should be a single 3D volume
%   LabelNumbersOld     - scalar (single number) or vector (row of
%                         multiple numbers) referring to label
%                         values/numbers present in the original NIfTI
%                         image. Not all numbers have to be replaced (REQUIRED)
%   LabelNumbersNew     - same as LabelNumbersOld but replaced with the
%                         desired numbers. Must be equal in size with LabelNumbersOld (REQUIRED)
%   pathNewNifti        - path for new NIfTI file to be saved with replaced values. If
%                         not provided, the original NIfTI file will be
%                         overwritten (OPTIONAL, DEFAULT = same as
%                         pathNifti)
%
% OUTPUT:
%   NIfTI file with replaced label values/numbers
%
% -----------------------------------------------------------------------------------------------------------------------------------------------------
% DESCRIPTION: This function replaces label values/numbers inside a NIfTI
% image, by the following steps:
%
% 1. Load NIfTI
% 2. Replace numbers
% 3. Save NIfTI
%
% -----------------------------------------------------------------------------------------------------------------------------------------------------
% EXAMPLE: xASL_im_ReplaceLabel('./CICERO/subject/RPI/4V.nii', [1 2 4], [2 1 4], './CICERO/subject/RPI/4V_new.nii')
% EXAMPLE (same but overwrite original NIfTI: xASL_im_ReplaceLabel('./CICERO/subject/RPI/4V.nii', [1 2 4], [2 1 4])
% EXAMPLE (same but shorter): xASL_im_ReplaceLabel('./CICERO/subject/RPI/4V.nii', [1 2], [2 1])
% 
% __________________________________
% Copyright 2021-2021 ExploreASL


%% -------------------
%% Admin

if nargin<3 || isempty(LabelNumbersNew)
    error('No new label numbers assigned, skipping');
elseif ~isnumeric(LabelNumbersNew)
    error('LabelNumbersNew should be numeric');
elseif nargin<2 || isempty(LabelNumbersOld)
    error('No old label numbers assigned, skipping');
elseif ~isnumeric(LabelNumbersOld)
    error('LabelNumbersOld should be numeric');
elseif nargin<1 || isempty(pathNifti)
    error('pathNifti should be defined');
elseif ~ischar(pathNifti)
    error('pathNifti should be char array, a path to the NIfTI file');
elseif ~xASL_exist(pathNifti)
    error([pathNifti ' does not exist']);
end

if nargin<4 || isempty(pathNewNifti)
    warning(['Overwriting ' pathNifti]);
    pathNewNifti = pathNifti;
end

if size(LabelNumbersOld, 1)~=1
    error('LabelNumbersOld should be a row, not a column');
elseif size(LabelNumbersNew, 1)~=1
    error('LabelNumbersNew should be a row, not a column');
elseif ~isequal(size(LabelNumbersOld), size(LabelNumbersNew))
    LengthOld = length(LabelNumbersOld);
    LengthNew = length(LabelNumbersNew);
    fprintf('%s\n', ['LabelNumbersOld has size ' num2str(LengthOld)]);
    fprintf('%s\n', ['LabelNumbersNew has size ' num2str(LengthNew)]);
    error('LabelNumbersOld and LabelNumbersNew should have identical size');
end

    

%% -------------------
%% 1. Load NIfTI
Image = xASL_io_Nifti2Im(pathNifti);



%% -------------------
%% 2. Replace numbers
for iNumber=1:length(LabelNumbersOld)
    if sum(Image==LabelNumbersOld(iNumber))==0
        warning(['Number ' LabelNumbersOld(iNumber) ' could not be found, skipping!'])
    else
        Image(Image==LabelNumbersOld(iNumber)) = LabelNumbersNew(iNumber);
    end
end


%% -------------------
%% 3. Save NIfTI
xASL_io_SaveNifti(pathNifti, pathNewNifti, Image);


end