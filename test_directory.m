%========================================================================%
%    COUNTS SYNAPSES IN A DIRECTORY OF IMAGES                            %
%                                                                        %
%    Author: Saket Navlakha                                              %
%    Date  : February 2013                                               %
%                                                                        %
%========================================================================%

function test_directory(Model,threshold,srcdir)

%TEST_DIRECTORY counts synapses in a directory of images.
%% Parameters
min_synapse_size = 300;      % min # of segment pixels for synapses.
max_synapse_size = 60*60;    % max # of segment pixels for synapses.
min_synapse_perimeter = 90;  % min # of segment pixels for synapse perimeter.
patch_size = 125;            % size of the patch taken around the centroid. previously was 75
%% Main function.
   
    chosenthreshold = threshold;
    start = tic;
    [~,samplename,~] = fileparts(srcdir);
    % Read images, check case of 'tif'.
    imagefiles = dir(fullfile(srcdir,'*.TIF'));
    if isempty(imagefiles)
        imagefiles = dir(fullfile(srcdir,'*.tif'));
    end
    
    if isempty(imagefiles) == 1
        sprintf('%s',srcdir)
        disp('No image files found. Continuing to next...')
    else
    
    % Open out file and write header.
        out = fopen(fullfile(fileparts(srcdir),[samplename '_counts.txt']),'w');
        fprintf(out,'#ImageName\tWindow\tConf\tMajorAx\tPerim\tArea\n');

        num_pos = zeros(length(imagefiles),1);
        clear num_pos Binaryimg Hits X Y
        for ii=1:length(imagefiles)
    %     for ii = 1:5  
            Iname = fullfile(srcdir,imagefiles(ii).name);
            I = imcomplement(mat2gray(imread(Iname)));

            [num_pos(ii),Binaryimg(ii,:,:),Hits{ii},X{ii},Y{ii}, minsize] = test_image(I,Model,out,imagefiles(ii).name,chosenthreshold,patch_size);
        end   

        % Final write to file and screen.
        fprintf(out,'#%s (%i images). %.2f, %.2f: Avg=%.3f, Std=%.3f\n',samplename,length(imagefiles),chosenthreshold,minsize,mean(num_pos),std(num_pos));
        fprintf('%s (%i images). %.2f, %.2f: Avg=%.3f, Std=%.3f\n',samplename,length(imagefiles),chosenthreshold,minsize,mean(num_pos),std(num_pos));

        %Save BWimage and X, Y of predicted synapses
         save(fullfile(fileparts(srcdir),[samplename  '_Processed.mat']),'imagefiles','num_pos','Binaryimg','Hits','X','Y')

        fclose(out);
        toc(start);
        clear num_pos Binaryimg Hits
    end
end

function [num_pos,Binaryimg,Hits,X,Y,min_synapse_size] = test_image(I,Model,out,image_name,chosenthreshold,patchsize)
%TEST_IMAGE applies the learned classifier to the input image to identify
%putative synapses. Assumes that I = imcomplement(mat2gray(cdata)).
tic;
%% Parameters.
threshold = chosenthreshold;
num_histogram_bins = 16;
num_of_orientation_bins = 9;
bw_thresh = 0.10;            % lower value -> keep less.
min_synapse_size = 300;      % min # of segment pixels for synapses. 300
max_synapse_size = 60*60;    % max # of segment pixels for synapses. 60*60
min_synapse_perimeter = 90;  % min # of segment pixels for synapse perimeter. 90
patch_size = patchsize;      % size of the patch taken around the centroid. previously 75, now 125

%% Main function.

% Segment the image.
Iadjusted = adapthisteq(I,'cliplimit',0.2);
[L,n] = bwlabel(1-(Iadjusted > bw_thresh));
X = [];
Y = [];
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
    
    block_size = floor(size(Patch,1)/10); %block_size=6 for 61x61 pathces; block_size=10 for 101x101 patches
    HOG_feat = HoG(Patch,[num_of_orientation_bins,10,block_size,1,0.2])';
    
    BW_feat = compute_BW_features(Patch,Segment);
%     size(HOG_feat)
    Features = [MR8_feat HOG_feat BW_feat];
%     size(Features)
    % Classify the patch using the SVM.
    [Prediction,~,Prob] = svmpredict(0,Features,Model,'-b 1');    
    
    if Prob(1) < threshold
        L(Region(i).PixelIdxList) = 0;        
    end
    
    % Write to file.
    fprintf(out,sprintf('%s\t%i\t%.2f\t%.2f\t%.2f\t%i\n',image_name,i,Prob(1),Region(i).MajorAxisLength,Region(i).Perimeter,Region(i).Area));

    % Prob(1) is score for positive class. Prob(2) is for negative class. 
    if Prob(1) >= threshold
        num_pos = num_pos + 1;  
        
        Iw = get_patch_around_centroid(I,x,y,patch_size);
        Base = zeros(size(L));
        Base(Region(i).PixelIdxList) = 1;   
        Is = get_patch_around_centroid(Base,x,y,patch_size);  % includes only the segment of interest.
        Is_all = get_patch_around_centroid(L,x,y,patch_size); % includes other components nearby.
        X(num_pos) = x;
        Y(num_pos) = y;
        Binaryimg = L;
        clear eval
        eval(['Hits.Iw_' num2str(num_pos) ' = Iw;']);
        eval(['Hits.Is_' num2str(num_pos) ' = Is;']);
        eval(['Hits.Is_all_' num2str(num_pos) ' = Is_all;']);
    end    

end
if num_pos == 0
    Binaryimg = zeros(1016,1024);
    Hits = [];
end

use_viz = 0;
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
