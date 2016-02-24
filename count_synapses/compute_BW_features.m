%========================================================================%
%    COMPUTES SHAPE FEATURES                                             %
%                                                                        %
%    Author: Saket Navlakha                                              %
%    Date  : October 2012                                                %
%                                                                        %
%========================================================================%

function Features = compute_BW_features(Patch,Segment)
%COMPUTE_BW_FEATURES computes 10 shape features for the segment.


%% BWorig: ignores the segment, only uses the patch.
% Icomp = imcomplement(Patch);
% bwthresh = max(max(Icomp))*0.5;
% [L,n] = bwlabel((Icomp > bwthresh));

%% BW1: using only the segment.
%[L,n] = bwlabel(Segment);

%% BW2: using a thinned version of the segment.
%L = bwmorph(Segment,'thin');
%[L,n] = bwlabel(L);



%% BW3: using both the patch and the segment.
PP = Patch;
PP(Segment==0) = 0; % only keep pixels values of the segment.
Icomp = imcomplement(PP);
bwthresh = max(max(Icomp))*0.6;
[L,n] = bwlabel((Icomp > bwthresh));


% Compute region properties.   
Region = regionprops(L,'Solidity','Perimeter','Orientation','EquivDiameter',...
                       'Area','Eccentricity','ConvexArea','MajorAxisLength',...
                       'MinorAxisLength','Extent');

% Get the two largest regions.
first_ind = -1;
first_area = -1;
second_ind = -1;
second_area = -1;

st = zeros(1,n);
for k=1:n
    st(k) = Region(k).Area;

    if Region(k).Area > first_area
        % curr first becomes second. k becomes first.
        second_ind = first_ind;
        second_area = first_area;

        first_ind = k;
        first_area = Region(k).Area;
        
    elseif Region(k).Area > second_area
        % second becomes k.
        second_ind = k;
        second_area = Region(k).Area;
    end
end    

% % Error checking.
% largest_ind = -1;
% largest_area = -1;
% for k=1:n
%     if Region(k).Area > largest_area
%         largest_area = Region(k).Area;
%         largest_ind = k;
%     end
% end
% 
% [~,ind] = max(st); % Region(ind) is the largest.
% 
% if (ind ~= largest_ind)
%     if st(ind) ~= largest_area
%         error('wtf?')
%     end
% end
% 
% if ind ~= first_ind && st(ind) ~= first_area
%     error('wtf2?')
% end
    
% If there's only one component, duplicate the first.
if second_ind == -1
    second_ind = first_ind;
end

% Create normalized feature vector.
Features = [Region(first_ind).Solidity, ...          % ratio, no need to normalize.
        Region(first_ind).Perimeter / (61*61), ...   % overkill, but ok.      
        (Region(first_ind).Orientation+90) / 180, ...% angle, make it between 0-180 instead of -90 and 90.
        Region(first_ind).EquivDiameter / (sqrt(61*61/pi)*2), ... % max diameter of circle with same area as the whole region
        Region(first_ind).Area / (61*61), ...        % max area
        Region(first_ind).Eccentricity, ...          % ratio, no need to normalize. 
        Region(first_ind).ConvexArea / (61*61), ...  % max area.
        Region(first_ind).MajorAxisLength / (61*sqrt(2)+5), ...     % max diagonal distance from NW to SE; +5 is buffer.
        Region(first_ind).MinorAxisLength / (61*sqrt(2)+5), ...     % max diagonal distance from NW to SE; +5 is buffer.
        Region(first_ind).Extent, ...                % ratio, no need to normalize.
        Region(second_ind).Solidity, ...             
        Region(second_ind).Perimeter / (61*61), ...
        (Region(second_ind).Orientation+90) / 180, ...
        Region(second_ind).EquivDiameter / (sqrt(61*61/pi)*2), ...
        Region(second_ind).Area / (61*61), ...
        Region(second_ind).Eccentricity, ...
        Region(second_ind).ConvexArea / (61*61), ...
        Region(second_ind).MajorAxisLength / (61*sqrt(2)+5), ...
        Region(second_ind).MinorAxisLength / (61*sqrt(2)+5), ...
        Region(second_ind).Extent];

end