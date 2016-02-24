%========================================================================%
%    NORMALIZES, ORIENTS, & CROPS A RAW INPUT PATCH                      %
%                                                                        %
%    Author: Saket Navlakha                                              %
%    Date  : September 2012                                              %
%                                                                        %   
%      -- Oct 2012: now uses segment to determine angle of rotation.     %
%                                                                        %
%========================================================================%


function [Patch,Segment] = process_patch(Patch,Segment,croppix)
%PROCESS_PATCH normalizes, orients, and crops the raw input patch. Also
%crops the segment.


%% Parameters.
% crop_down = 8; % crop dimensions (e.g. 76x76 -> 61x61).
% crop_down = 13; % crop dimensions (e.g. 125x125 -> 101x101).
crop_down = croppix;


%% Main function.

% Normalize the patch: subtract mean, divide by std.
Patch = (Patch-mean(Patch(:))) ./ std(Patch(:));     

% Re-orient the patch so it's vertically aligned: first, determine
% angle of rotation, and second, interpolate the rotation.

% Old: based on intensity only.
%BW = edge(Patch,'canny',0.5); % higher number -> keep less. prev = 0.4. 

% New: based on intensity and segment.
PatchSeg = Patch;
PatchSeg(Segment==0) = 0; % only keep pixels values of the segment.
BW = edge(PatchSeg,'canny',0.60); % higher number -> keep less.

% Determine angle of rotation.
[H,Theta,Rho] = hough(BW);
Peak = houghpeaks(H);   
angle = Theta(Peak(:,2)); % 1 is peak rho; 2 is peak theta.

Patch = rotate_vertical(Patch,angle);
Segment = rotate_vertical(Segment,angle);

% Crop down to deal with boundary problem after rotation.
Patch = Patch(crop_down:end-crop_down,crop_down:end-crop_down);
Segment = Segment(crop_down:end-crop_down,crop_down:end-crop_down);

end



function Patch = rotate_vertical(Patch,angle)
%ROTATE_VERTICAL uses the hough transform and ba_interp2 to orient and
%interpolate the image so that the major axis of the main component is
%aligned vertically.

%% Parameters.
method = 'cubic'; % interpolation method; alternatives = 'linear','nearest'


%% Main function.

grid = size(Patch,1)-1; % should be 75 if the patches are 76x76.
angle = 180/(360-angle);

[Dx Dy] = meshgrid(-grid/2:1:grid/2, -grid/2:1:grid/2);

R = [cos(pi/angle) sin(pi/angle); -sin(pi/angle) cos(pi/angle)];
RD = R * [Dx(:)'; Dy(:)']+grid/2;
RDx = reshape(RD(1,:), size(Dx));%+grid/2;
RDy = reshape(RD(2,:), size(Dy));%+grid/2;

Patch = ba_interp2(Patch, RDx, RDy, method);

end