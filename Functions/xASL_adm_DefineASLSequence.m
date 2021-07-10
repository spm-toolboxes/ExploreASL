function [x] = xASL_adm_DefineASLSequence(x)
%xASL_adm_DefineASLSequence Obtain ASL sequence type for sequence-specific
%image processing
%
% FORMAT: [x] = xASL_adm_DefineASLSequence(x)
%
% INPUT:
%   x                - x structure containing all input parameters (REQUIRED)
%   x.Q.readoutDim   - dimensionality of readout (2D or 3D)
%   x.Q.Manufacturer - Either 'GE', 'Philips', 'Siemens'
% OUTPUT:
%   x               - x structure containing all output parameters
%   x.Sequence      - sequence type (readout)
% -----------------------------------------------------------------------------------------------------------------------------------------------------
% DESCRIPTION: This ExploreASL function tries to check what ASL sequence is
% being processed, if this was not already defined in x.Sequence.
% It does so by checking known combinations of readout dimensionality
% (x.Q.readoutDim) and Manufacturer, knowing the product sequences of the Manufacturers.
%
% EXAMPLE: x = xASL_adm_DefineASLSequence(x);
% -----------------------------------------------------------------------------------------------------------------------------------------------------
% Copyright 2015-2020 ExploreASL



if ~isfield(x.Q, 'readoutDim')
    warning('x.Q.readoutDim parameter missing, skipping determining ASL sequence');
end
if ~isfield(x.Q, 'Manufacturer')
    warning('x.Q.Manufacturer missing, skipping determining ASL sequence');
elseif  isempty(regexpi(x.Q.Manufacturer, 'Gold Standard Phantoms|GE|Philips|Siemens'))
    warning('Unknown Manufacturer specified in x.Q.Manufacturer');
elseif ~isempty(regexpi(x.Q.Manufacturer, 'Gold Standard Phantoms'))
    fprintf('%s\n', 'Digital Reference Object ASL-DRO detected');
end


% Obtain ASL sequence
if ~isfield(x,'Sequence') && isfield(x.Q,'readoutDim') && isfield(x.Q, 'Manufacturer')
    if strcmpi(x.Q.readoutDim,'2D')
       x.Sequence = '2D_EPI'; % assume that 2D is 2D EPI, irrespective of Manufacturer
    elseif strcmpi(x.Q.readoutDim,'3D') && ( ~isempty(regexpi(x.Q.Manufacturer,'Philips')) || ~isempty(regexpi(x.Q.Manufacturer,'Siemens')) )
           x.Sequence = '3D_GRASE'; % assume that 3D Philips or Siemens is 3D GRASE
    elseif strcmpi(x.Q.readoutDim,'3D') && ~isempty(regexpi(x.Q.Manufacturer,'GE'))
           x.Sequence = '3D_spiral'; % assume that 3D GE is 3D spiral
    elseif strcmpi(x.Q.readoutDim,'3D') && ~isempty(regexpi(x.Q.Manufacturer,'Gold Standard Phantoms'))
        x.Sequence = '3D_GRASE'; % assume that this is simulated 3D GRASE by the DRO
        fprintf('%s\n', 'Processing as if this is a 3D GRASE sequence');
        fprintf('%s\n', 'Though the acquisition is not simulated, this will assume acquisition of a single 3D volume');
        fprintf('%s\n', 'and intermediate amount of geometric distortion and smoothness');
    elseif strcmpi(x.Q.readoutDim,'2D') && ~isempty(regexpi(x.Q.Manufacturer,'Gold Standard Phantoms'))
        fprintf('%s\n', 'Processing as if this is a 2D EPI sequence');
        fprintf('%s\n', 'Though the acquisition is not simulated, this will assume acquisition of multi-slice 2D acquisitions');
        fprintf('%s\n', 'and heavy geometric distortion and minimal smoothness');
    end
end
if ~isfield(x,'Sequence')
    warning('No x.Sequence defined');
    fprintf('If there are multiple sequence types, this needs to be implemented yet here\n');
    fprintf('Otherwise, please define x.Sequence\n');
    fprintf('Setting x.Sequence=3D spiral to fool the pipeline here\n');
    fprintf('As this sequence doesnt have any susceptibility masks\n');
    fprintf('Note that this disables any masking of susceptibility signal dropout areas\n');
    x.Sequence = '3D_spiral';
    x.Q.readoutDim = '3D';
else
    fprintf('%s\n', [x.Sequence ' sequence detected']);
end


end