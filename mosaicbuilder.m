function [Mosaic,corners] = mosaicbuilder(Images)    
    x = 1;
    y = 1;
    border = 5;
    num_added = 0;
    mosaicsizeX = ceil(sqrt(size(Images,1))); % Enforce a square mosaic
%     mosaicsizeX = min(ceil(sqrt(size(Images,1))),15); % Maximum X-Axis number of Images = 15.
    mosaicsizeY = ceil(size(Images,1)/mosaicsizeX);
    patchX = size(Images,2);
    patchY = size(Images,3);
    % To ensure a white border, initialize the mosaic to 1
    out_image = ones(patchX*mosaicsizeX + border*(mosaicsizeX-1),patchY*mosaicsizeY + border*(mosaicsizeY-1));
    out_image = out_image'; % To account for how matlab displays images
    for(idx = 1:size(Images,1))
        corners(idx,1) = x;
        corners(idx,2) = y;
        Patch = squeeze(Images(idx,:,:));
        patch_length = size(Patch,1)-1;
        out_image(x:x+patch_length,y:y+patch_length) = Patch;
        y = y + patch_length + border + 1;
        num_added = num_added + 1;
        if num_added == mosaicsizeX
            num_added = 0;
            x = x + patch_length + border + 1;
            y = 1;
        end
    end
    Mosaic = out_image;
end