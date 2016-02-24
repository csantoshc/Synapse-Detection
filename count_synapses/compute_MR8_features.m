%========================================================================%
%    COMPUTES MAXIMUM RESPONSE (MR8) TEXTURE FEATURES                    %
%                                                                        %
%    Author: Saket Navlakha                                              %
%    Date  : September 2012                                              %
%                                                                        %
%========================================================================%

function Features = compute_MR8_features(I,num_histogram_bins)
%%COMPUTE_MR8_FEATURES computes the normalized MR8 features histograms.

% Create filter bank.
I_texture = MR8fast(I)';

% Get max and min values along each dimension; used to make equally-sized
% and spaced-histograms.
max_texture = max(I_texture);
min_texture = min(I_texture);

if size(max_texture,2) ~= 8 || size(min_texture,2) ~= 8
    error('Expected 8 texture dimensions but found %i,%i',size(max_texture,2),size(min_texture,2))
end

% Define boundaries of the histogram for each response.
texture_bins = zeros(num_histogram_bins+1,8); %num+1 because it defines the edges.
for i=1:8
    texture_bins(:,i) = (min_texture(i) : (max_texture(i)-min_texture(i))/num_histogram_bins : max_texture(i));
end

% Compute histogram for each response.
Features = zeros(8,num_histogram_bins+1);
for i=1:8
    h = histc(I_texture(:,i),texture_bins(:,i));
    Features(i,:) = h ./ sum(h);
end    

end