function synapsemosaic(parentDir,sample)
% This function displays a mosaic of all the detected synapses in a
% randomized manner; 1 for each 'sample'
    
    % For local computer
    baseDir = pwd;
    dataDir = fullfile(baseDir,parentDir);
    % Get all folders in the parent directory that contain images

    allfiles = dir(dataDir);
    imgfolderidx = [allfiles(:).isdir];
    Imagedirs = {allfiles(imgfolderidx).name};
    Imagedirs(ismember(Imagedirs,{'.','..'})) = [];
    Imagedirs = Imagedirs';

    for dirs = sample
        srcdir=fullfile(dataDir,Imagedirs{dirs});
        samplename = Imagedirs{dirs};

        clear spaces imagenames

        load(fullfile(fileparts(srcdir),[samplename '_Processed.mat']),'Hits','imagefiles','num_pos')        
        numofimages = length(find(num_pos>0)); % Selects images with atleast 1 synapse
        chosen = datasample(find(num_pos>0),numofimages,'Replace',false); % Randomizes the list of images
    
        if ~isempty(chosen)       
            num_added = 1;
            for(images = 1:length(chosen))
                imagenum = chosen(images);
                for ii = 1:num_pos(imagenum)
                    clear eval                    
                    Patch(num_added,:,:) = eval(['Hits{1,' num2str(imagenum) '}.Iw_' num2str(ii)]);                  
                    num_added = num_added + 1;       
                end
            end
            out_image = mosaicbuilder(Patch); 
            out_image = abs(min(min(out_image))) + out_image;
            out_image = out_image / max(max(out_image));    
            figure,imshow(out_image)
            hold off
        end

    end
end