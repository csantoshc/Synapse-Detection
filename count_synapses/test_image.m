%========================================================================%
%    CLASSIFIES AN IMAGE USING A TRAINED CLASSIFIER                      %
%                                                                        %
%    Author: Saket Navlakha                                              %
%    Date  : September 2012                                              %
%                                                                        %
%========================================================================%

function [num_pos,Synapse_Props] = test_image(I,Model,use_viz,thr)
%TEST_IMAGE applies the learned classifier to the input image to identify
%putative synapses. Assumes that I = imcomplement(mat2gray(cdata)).

tic;


%% Parameters.
num_histogram_bins = 16;
bw_thresh = 0.10;            % lower value -> keep less.
min_synapse_size = 300;      % min # of segment pixels for synapses. 300
max_synapse_size = 60*60;    % max # of segment pixels for synapses. 60*60
min_synapse_perimeter = 90;  % min # of segment pixels for synapse perimeter. 90
patch_size = 75;             % size of the patch taken around the centroid.


%% Main function.

% Segment the image.
Iadjusted = adapthisteq(I,'cliplimit',0.2);
[L,n] = bwlabel(1-(Iadjusted > bw_thresh));

% Create label matrix; filter regions based on size and perimeter; classify
% the remaining.
Region = regionprops(L,'PixelIdxList','Area','Perimeter');
for i=1:n
    if Region(i).Area < min_synapse_size || Region(i).Area > max_synapse_size || Region(i).Perimeter < min_synapse_perimeter
        L(Region(i).PixelIdxList) = 0;  
    end
end

% Recompute regions and store centroids.
[L,n] = bwlabel(L);    
Region = regionprops(L,'Centroid','PixelIdxList','Area','Perimeter','MajorAxisLength');
num_pos = 0;
Synapse_Props = []; % num synapses x 3 matrix (major,perim,area).
for i=1:n    
    c = Region(i).Centroid;

    x = round(c(1));
    y = round(c(2));

    % Get patch around centroid.
    Iw = get_patch_around_centroid(I,x,y,patch_size);
    Base = zeros(size(L));
    Base(Region(i).PixelIdxList) = 1;   
    Is = get_patch_around_centroid(Base,x,y,patch_size);  % includes only the segment of interest.
    
    [Patch,Segment] = process_patch(Iw,Is);
    
    % Compute featurse of the patch.
    MR8_feat = compute_MR8_features(Patch,num_histogram_bins);
    MR8_feat = reshape(MR8_feat,1,(num_histogram_bins+1)*8);
    HOG_feat = HoG(Patch,[9,10,6,1,0.2])';
    BW_feat = compute_BW_features(Patch,Segment);

    Features = [MR8_feat HOG_feat BW_feat];

    % Classify the patch; for now assume classifier is SVM.        
    [Prediction,~,Prob] = svmpredict(0,Features,Model,'-b 1');    
    %[Prediction,Score] = predict(Model,Features);   

    % Filter low-confidence predictions. Prob(1) is the score for the
    % positive class. Prob(2) is for the negative class. Doing
    % 'Predictions == 0' is the same as thr=0.5

    if Prob(1) < thr
        L(Region(i).PixelIdxList) = 0;
    else
        num_pos = num_pos + 1;
        Synapse_Props(num_pos,:) = [Region(i).MajorAxisLength, Region(i).Perimeter, Region(i).Area];
        %Synapse_Props(num_pos,:) = [Region(i).Perimeter];        
    end         
    
%     Prob(1)
%     figure,imshow(Patch,[min(Patch(:)),max(Patch(:))])
%     figure,imshow(Segment)
%     pause;
%     close all;


end

% Show visualization.
if (use_viz)
    figure,imshow(I), hold on
    Lrgb = label2rgb(bwlabel(L),'jet','w','shuffle');
    himage = imshow(Lrgb);
    set(himage,'AlphaData',0.3);
    %figure,imshow(I);
    fprintf('Num predictions: %i\n', n)
    fprintf('Num negative: %i\n',n-num_pos)
    fprintf('Num positive: %i\n',num_pos)   
end


end

