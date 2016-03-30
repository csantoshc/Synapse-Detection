%========================================================================%
%    GUI TOOL TO GENERATE TRAINING DATA                                  %
%                                                                        %
%    Author: Saket Navlakha                                              %
%    Date  : May 2013                                                    %
%    
%    Edited: Santosh Chandrasekaran
%========================================================================%

function build_training_data_from_segments(dataDir, savingDirname)
tic;
%BUILD_TRAINING_DATA_FROM_SEGMENTS iterates through training images:
    %segments image, asks user to label segments, and stores segments and
    %binary window to file. Uses 'adapthisteq' and only one threshold for
    %segmentation.

    % Using min_synapse_size = 300 for good samples and 100 for bad samples.
    % Remember to change output directory depending on good/bad sample.
%% Parameters
bw_thresh = 0.10;            % lower value -> keep less.
min_synapse_size = 300;      % min # of segment pixels for synapses.
max_synapse_size = 60*60;    % max # of segment pixels for synapses.
min_synapse_perimeter = 90;  % min # of segment pixels for synapse perimeter.
patch_size = 125;            % size of the patch taken around the centroid. previously was 75
num_images_per = 10;         % number of images per sample to label.
% Features and final analysis are done on 61x61 pixel patches. Change in
% 'process_patch.m '
%% Main function.
allfiles = dir(dataDir);
if isempty(allfiles)
    disp(['Error:' dataDir ' not found'])
    return
end
imgfolderidx = [allfiles(:).isdir];
Imagedirs = {allfiles(imgfolderidx).name};
Imagedirs(ismember(Imagedirs,{'.','..'})) = [];
Imagedirs = Imagedirs';
if isempty(Imagedirs)
    disp('Error: No image folders detected')
    return
end

% Iterate through each folder (or equivalently, sample)
directories = 1:length(Imagedirs);
for dirs = directories
    srcdir=fullfile(dataDir,Imagedirs{dirs});
    fprintf('Current sample is %s\n', Imagedirs{dirs})


    % Checks case of '.tif' vs. '.TIF'

    imagefiles = dir([srcdir '\*.TIF']);
    if isempty(imagefiles)
        imagefiles = dir([srcdir '\*.tif']);
        if isempty(Imagedirs)
            disp('Error: No images (TIFF files) detected')
            return
        end
    end

    % Interval for which to select images to label.
    interval = floor(length(imagefiles) / num_images_per);   

    for ii=1:length(imagefiles)

    %     Just consider 'num_images_per' images.
        if mod(ii,interval) ~= 0
            continue
        end 
        % Read in image.
        fprintf('Current image is %s\n',imagefiles(ii).name)
        Iname = [srcdir '\' imagefiles(ii).name];
        I = imcomplement(mat2gray(imread(Iname)));  
        %figure,imshow(I);

        % Segment the image.
        Iadjusted = adapthisteq(I,'cliplimit',0.2);
        [L,n] = bwlabel(1-(Iadjusted > bw_thresh));

        %figure,imshow(I)
        %figure,imshow(L)

        % Filter regions based on size and perimeter; create label matrix.
        Region = regionprops(L,'PixelIdxList','Area','Perimeter');
        for i=1:n
            if Region(i).Area < min_synapse_size || Region(i).Area > max_synapse_size || Region(i).Perimeter < min_synapse_perimeter
                L(Region(i).PixelIdxList) = 0;
            end
        end

        % Recompute regions and store centroids.
        [L,n] = bwlabel(L);    
        Region = regionprops(L,'Centroid','PixelIdxList');
        Cents = zeros(n,2); % Centroid of each region.
        figure,imshow(I), hold on    
        for i=1:n
            c = Region(i).Centroid;
            Cents(i,:) = c;
            text_x = c(1)+25;
            text_y = c(2);
            if text_x >= size(I,2)
                text_x = c(1)-25;
            end
            text(text_x,text_y, sprintf('%.0f',i), ...
                'Clipping', 'on', ...
                'Color', 'k', ...
                'FontWeight', 'bold', ...
                'FontSize', 12,'HorizontalAlignment','center');
            scatter(c(1),c(2),20,'r.');
    %         scatter(c(1),c(2),'r.');
        end

        % Show label matrix.
    %     Lrgb = label2rgb(L,'jet','w','shuffle');
    %     himage = imshow(Lrgb);
    %     set(himage,'AlphaData',0.3); % 0.4    
    %     pause;


        % Ask user to provide ids for positive synapses.
        ids = inputdlg(sprintf('Image: %s (%i-%i segments)\nEnter pos synapse ids separated by commas (0 for none; -2 to skip; -1 to quit): ',imagefiles(ii).name,ii,n));
        ids = regexp(ids,',','split');

        if (str2double(ids{1}(1)) == -1) % quit.
            close all;
            return;
        elseif (str2double(ids{1}(1)) == -2) % skip.
            close all;
            continue;
        else
            pos_ids = zeros(1,length(ids{1}));
            for i=1:length(ids{1})
                pos_ids(i) = str2double(ids{1}(i));
            end

            % Save all pos and neg synapses; then continue to next image.
            for i=1:n

                % Get window around centroid.
                cent = Cents(i,:);
                x = round(cent(1));
                y = round(cent(2));

                Iw = get_patch_around_centroid(I,x,y,patch_size);
                Base = zeros(size(L));
                Base(Region(i).PixelIdxList) = 1;   
                Is = get_patch_around_centroid(Base,x,y,patch_size);  % includes only the segment of interest.
                Is_all = get_patch_around_centroid(L,x,y,patch_size); % includes other components nearby.

                if ismember(i,pos_ids) % save as positive.
                    found = 'pos';       
                    %figure,imshow(Iw)
                    %figure,imshow(Is)
                    %pause;

                else % save as negative.
                    found = 'neg';                    
                end

                filename = [fileparts(savingDirname) '_' imagefiles(ii).name(1:end-4) '_' found '_' num2str(x) '_' num2str(y) '.mat'];
                save(filename,'Iw','Is','Is_all');
            end

            close all;
        end
    end
end
toc;
end



