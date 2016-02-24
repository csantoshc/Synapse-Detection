%========================================================================%
%    GETS IMAGE PATCH AROUND CENTROID X-Y                                %
%                                                                        %
%    Author: Saket Navlakha                                              %
%    Date  : August 2012                                                 %
%                                                                        %
%========================================================================%

function Iw = get_patch_around_centroid(I,x,y,patch_size)
%GET_PATCH_AROUND_CENTROID returns a patch_size x patch_size patch around
%the specified x,y coordinates in the image I.

[num_rows,num_cols] = size(I);

if (x == 0 || y == 0)
    error('not stored correctly')
end

% If patch_size is odd, then one side will have one additional pixel.
shift1 = ceil(patch_size/2);
shift2 = floor(patch_size/2);

% Compute the shift in the left-right direction (hard part is dealing with
% boundaries. In such cases, go as far to the boundary as possible, and
% then go further in the other direction to ensure that all patches are of
% equal size.
left = x-max(1,x-shift1);
right = min(num_cols,x+shift2)-x+(shift1-left);
if (right < shift2)
    left = left + (shift2-right); % can't go 37 down, take more from left.
end

up = y-max(1,y-shift1);
down = min(num_rows,y+shift2)-y+(shift1-up);
if (down < shift2)
    up = up + (shift2-down); 
end

Iw = I(y-up:y+down,x-left:x+right);

end