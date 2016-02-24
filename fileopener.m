%========================================================================%
%  OPENS AND PARSES THE TEXT FILE THAT HAS DATA ABOUT DETECTED SYNAPSES  %                          
%                                                                        %
%    Author: Santosh Chandrasekaran                                      %
%                                                                        %
%========================================================================%

function [images, synapseindex, properties, num_pos] = fileopener(textfile,imagefiles,threshold)
% this function opens up the '_counts' textfile that was generated after analyzing
% all the images of a sample
% imagefiles is obtained from the '_Processed.mat' file that was generated after analyzing
% all the images of a sample - list of all image names for the sample
% Can be used to get the properties of all objects with any arbitrary
% confidence defined by threshold

    images = [];
    synapseindex = [];
    properties = [];
    out3 = fopen(textfile);
    tline = fgetl(out3);
    clear objectparams
    objectparams = textscan(out3,'%s %d %f %f %f %f'); % Read the file contents into a cell
    for count = 1:length(imagefiles)
        proceed2 = 'a';
        % Iterate through each image
        imagenames(count,:) = imagefiles(count).name;
        
        % All objects detected in any image
        allhits = find(strcmp(objectparams{1},imagenames(count,:)));
        if isempty(allhits)
            disp([textfile ' ' imagenames(count,:) ' This image was not found in the text file list of images'])
            proceed2 = input('Do you want to continue?','s');
        end
        if proceed2 == 'y'
            continue;
        elseif proceed2 == 'n'
            break;
        end
        
        % 3rd column in the text file/cell array = Confidence or Threshold
        % Find all objects with Confidence > user defined threshold
        putatives = find(objectparams{3}(allhits) >= threshold) + allhits(1) - 1;
        
        % Image name that has that object
        images = [images;repmat(imagenames(count,:),length(putatives),1)];       
        
        % object index in any image
        synapseindex = [synapseindex;(1:length(putatives))'];
        
        % 4,5 and 6 columns contain MajorAxis, Perimeter and Area
        % measurement of object respectively
        properties = [properties;objectparams{4}(putatives) objectparams{5}(putatives) objectparams{6}(putatives)];
        
        % No. of putative synapses in any given image
        num_pos(count) = length(putatives);
    end
    fclose(out3);
end