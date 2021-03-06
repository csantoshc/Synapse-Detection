%========================================================================%
%    BUILDS FEATURE MATRIX FROM TRAINING IMAGES                          %
%                                                                        %
%    Author: Saket Navlakha                                              %
%    Date  : September 2012
%    
%    Edited: Santosh Chandrasekaran
%                                                                        %
%========================================================================%

function [Features,Labels,Mapping] = build_features_samplewise(Dir)
%BUILD_FEATURES builds a feature matrix for the training examples (both
%positive and negative sets). Also returns a mapping associating each
%feature vector with its sample.

% For grid search, in matlab do: 
%   >> libsvmwrite('Classifier1.txt',L1,sparse(F1));
% Then in python do:
%   $ ./grid.py Classifier1.txt

%% Parameters

srcdir = Dir;
num_histogram_bins = 16;
use_MR8 = 1;
use_HOG = 1;
use_Schmid = 0;
use_LM = 0;
use_BW = 1;

%%
% To determine the size of the Features vector, open one of the Patches and
% determine its size
type = 'pos';
matfiles = dir(sprintf('%s/*%s*.mat',srcdir,type));
I = load(sprintf('%s/%s',srcdir,matfiles(1).name),'Iw','Is');    
[Patch,~] = process_patch(I.Iw,I.Is);

num_of_orientation_bins = 9;
block_size = floor(size(Patch,1)/10); %block_size=6 for 61x61 pathces; block_size=10 for 101x101 patches

% size of HOG_feat = 324 for 61 pixels
% size of HOG_feat = 900 for 101 pixels
size_HOG = num_of_orientation_bins*(block_size^2);

%% Main function.

num_features = use_MR8*(num_histogram_bins+1)*8 + ...
               use_HOG*size_HOG + ...
               use_Schmid*(num_histogram_bins+1)*13 + ...
               use_LM*(num_histogram_bins+1)*48 + ...
               use_BW*10*2;

Features = zeros(1,num_features); % num_training x num_features.
Labels = zeros(1,1);              % num_training x 1.
Mapping = cell(1,1);              % num_training x 1.
row_id = 1;

% Make filter banks for the appropriate features.
if (use_Schmid), Filt_S  = makeSfilters;  end
if (use_LM),     Filt_LM = makeLMfilters; end


% Build features for each positive and negative example.
for types = {'pos','neg'}
    type = types{1};
    matfiles = dir(sprintf('%s/*%s*.mat',srcdir,type));
    label = q(type);
    
    tic;
    fprintf('Number of %s examples: %i\n', type, length(matfiles))
    
    for ii=1:size(matfiles)
        I = load(sprintf('%s/%s',srcdir,matfiles(ii).name),'Iw','Is');
        
        % Normalize, orient, and crop the patch.
        [Patch,Segment] = process_patch(I.Iw,I.Is);
                                
        if (use_MR8)
            MR8_feat = compute_MR8_features(Patch,num_histogram_bins);
            MR8_feat = reshape(MR8_feat,1,(num_histogram_bins+1)*8);
        else
            MR8_feat = [];
        end
        
        if (use_HOG)            
            HOG_feat = HoG(Patch,[num_of_orientation_bins,10,block_size,1,0.2])';%HOG(Patch)';oriented 
            %HOG_feat = HoG(Patch,[9,10,6,0,0.2])';%HOG(Patch)'; unoriented             
               
        else
            HOG_feat = [];
        end
        
        if (use_Schmid)
            Schmid_feat = compute_Schmid_features(Patch,Filt_S,num_histogram_bins);
            Schmid_feat = reshape(Schmid_feat,1,(num_histogram_bins+1)*13);
        else
            Schmid_feat = [];
        end
        
        if (use_LM)
            LM_feat = compute_LM_features(Patch,Filt_LM,num_histogram_bins);
            LM_feat = reshape(LM_feat,1,(num_histogram_bins+1)*48);
        else
            LM_feat = [];
        end
        
        if (use_BW) 
            BW_feat = compute_BW_features(Patch,Segment);
        else
            BW_feat = [];
        end
        
        % Store sample associated with feature vector.
        sample = regexp(matfiles(ii).name,'_','split');
        sample = sample{1};
        
        Features(row_id,:) = [MR8_feat, HOG_feat, Schmid_feat, LM_feat, BW_feat];
        Labels(row_id,:) = label;
        Mapping{row_id,:} = sample;
        
        row_id = row_id + 1;
    end
    toc;
end

end


function b = q(x)
    if (strcmp(x,'pos'))
        b = 1;
    elseif (strcmp(x,'neg'))
        b = 0;
    else
        error('not pos or neg??');
    end
end