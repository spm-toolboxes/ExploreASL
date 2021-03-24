function SliceTiming = xASL_quant_SliceTiming(x, inputIm)
%xASL_quant_SliceTiming Calculates a vector with the timings of slice readouts relative to the start of readout
%
% FORMAT: SliceTiming = xASL_quant_SliceTiming(x, inputIm)
%
% INPUT:
%   x            - struct containing pipeline environment parameters (REQUIRED)
%   inputIm      - path to the image or an image matrix used to calculated the number of slices to calculate the SliceTiming for (REQUIRED)
% OUTPUT:
%   SliceTiming  - a vector of slice times defining the start of readout per slices with respect to the start of the readout of the first slices
%                  with the length corresponding to the third dimension in inputIm
% -----------------------------------------------------------------------------------------------------------------------------------------------------
% DESCRIPTION: This function takes the x.SliceReadoutTime, which can be a vector (of start of readout per slices relative to the 
%              readout of the first slice) or scalar (with difference in readout times between two consecutives slices) and creates a vector
%              (of the relatives timings for each slices) out of it with the correct length corresponding to the number of slices in the inputIm. 
%              It also checks the x.readout_dim, and for 3D readouts it returns 0.
%              It loads the image from inputIm and calculates the SliceTiming according to the number of slices in the third dimension
%              If a path is given, it also checks if it can find a JSON sidecar, then it loads the JSON sidecar, and looks for SliceTiming inside it. If
%              SliceTiming/SliceReadoutTime is found in the JSON sidecar, it prioritize it over the value in the x-struct
%
% 0. Admin
% 1. ShortestTR
% 2. Assign the vector value
% -----------------------------------------------------------------------------------------------------------------------------------------------------
% EXAMPLE: SliceTiming = xASL_quant_SliceTiming(x, 32)
% __________________________________
% Copyright 2015-2021 ExploreASL

%% -----------------------------------------------------------------------------------------------------------------------------------------------------
%% 0.Admin
if nargin < 1 || isempty(x)
	error('The x-structure needs to be provided');
end

if nargin < 2 || isempty(inputIm) 
	error('The inputIm parameter needs to be provided');
end

% If a path is provided, then it needs to load the image to obtain its number of dimensions and it can also check the file JSON sidecar
% to see if a different SliceReadoutTime is no provided in the JSON than in the x-struct
if ischar(inputIm)
	% Loads the image information and obtains the number of slices
	imMatrix = xASL_io_ReadNifti(inputIm);
	nSlices = size(imMatrix.dat, 3);
	
	% Additionally, look for the JSON sidecar of the image file
	[Fpath, Ffile, ~] = xASL_fileparts(inputIm);
	pathJson = fullfile(Fpath, [Ffile, '.json']);
	
	% We need to look for the sidecar of the original file in case a resampled file was provided (with a prefix 'r')
	if ~xASL_exist(pathJson, 'file') && (Ffile(1) == 'r')
		pathJson = fullfile(Fpath, [Ffile(2:end), '.json']);
	end
	
	% Check if the JSON sidecar of the original file exists
	if xASL_exist(pathJson, 'file')
		parmsLocal = spm_jsonread(pathJson);
		% Loads the JSON file and converts it to the Legacy format
		parmsLocal = xASL_bids_parms2BIDS([], parmsLocal, 0);
		
		% Gets the SliceReadoutTime out of it
		if isfield(parmsLocal, 'Q') && isfield(parmsLocal.Q, 'SliceReadoutTime') && ~isempty(parmsLocal.Q.SliceReadoutTime)
			% If SliceReadoutTime differs from the x-struct version, but the JSON variant has the correct length, then replace it
			if ~isequal(parmsLocal.Q.SliceReadoutTime(:), x.Q.SliceReadoutTime(:)) &&...
					( (length(parmsLocal.Q.SliceReadoutTime) == 1) || (length(parmsLocal.Q.SliceReadoutTime) == nSlices))
				x.Q.SliceReadoutTime = parmsLocal.Q.SliceReadoutTime;
				warning(['Replacing the x-struct SliceReadoutTime with the one from: ' pathJson]);
			end
		end
	end
else
	% If an image matrix is given, the directly check the number of slices
	nSlices = size(inputIm, 3);
end

% The readout_dim needs to be provided
if ~isfield(x, 'readout_dim')
	error('x.readout_dim field is missing');
end

if strcmpi(x.readout_dim, '3D')
	% For 3D sequences, zero is returned
	SliceTiming = 0;
	return;
end

if ~strcmpi(x.readout_dim, '2D') 
	% It only works with 2D and 3D
	error(['Unknown x.readout_dim value:' x.readout_dim]);
end

% The SliceReadoutTime needs to be provided
if ~isfield(x, 'Q')
	error('x.Q field missing');
elseif ~isfield(x.Q, 'SliceReadoutTime') || isempty(x.Q.SliceReadoutTime)
	error('x.Q.SliceReadoutTime missing or invalid ');
end

%% -----------------------------------------------------------------------------------------------------------------------------------------------------
%% 1. ShortestTR
% If SliceReadoutTiem is specified as "shortestTR", it calculates it with the knowledge of TR and PLD
% If a scalar or vector is given for SliceReadoutTime, then this function doesn't do anything
x = xASL_quant_SliceTiming_ShortestTR(x);

%% -----------------------------------------------------------------------------------------------------------------------------------------------------
%% 2. Assign the vector value
% For 2D it either uses the vector or it replicates the scalar to the correct length
% Non-2D cases were solved in the admin

if length(x.Q.SliceReadoutTime) == 1
	SliceTiming = (0:1:(nSlices-1)) * x.Q.SliceReadoutTime;
elseif length(x.Q.SliceReadoutTime) == nSlices
	SliceTiming = x.Q.SliceReadoutTime;
else
	error('x.Q.SliceReadoutTime has to be a scalar or match the number of slices');
end

end