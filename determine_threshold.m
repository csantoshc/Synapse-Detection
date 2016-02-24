%========================================================================%
%    DETERMINES THE THRESHOLD TO APPLY TO EACH SAMPLE                    %
%                                                                        %
%    Author: Saket Navlakha                                              %
%    Date  : August 2013                                                 %
%                                                                        %
%========================================================================%

function Output = determine_threshold(dir,F,L,M,F2,L2,M2,Model_SRE_61_imqual)
%DETERMINE_THRESHOLD selects the threshold for each sample that maximizes
%its F-score using cross-validation.
sample_idx = 1;
%% Parameters.
num_features = size(F,2);
%% Main function.
if ~exist(fullfile(fileparts(dir),'sample_thresholds.txt'),'file')
    out_file = fopen(fullfile(fileparts(dir),'sample_thresholds.txt'),'w');
    fprintf(out_file,'#Sample Relevant NotRelevant AUCPR Prec Recall Thr F1\n');  
end
out_file = fopen(fullfile(fileparts(dir),'sample_thresholds.txt'),'r');
formatSpec = '%s %d %d %f %f %f %f %f';
column_names = textscan(out_file,'%s',8); % Get the column headers
sample_analysis = textscan(out_file,formatSpec); % Get the numbers from analysis previously done, if any
out_file = fopen(fullfile(fileparts(dir),'sample_thresholds.txt'),'w');

column_names{1} = column_names{1}';
%%
[~,curr_sample,~] = fileparts(dir);

%% 1. Extract features relevant to sample (for x-val) and features not
% relevant to sample (for building the model).

% Preallocate array sizes.
idx = strcmp(M,curr_sample);
num_relevant = length(find(idx == 1));
num_notrelevant = length(find(idx == 0));    
%     num_relevant = 0; num_notrelevant = 0;
%     for i=1:length(F)
%         if strcmp(M{i},curr_sample),  % same sample.
%             num_relevant = num_relevant + 1;
%         else % different sample.
%             num_notrelevant = num_notrelevant + 1;
%         end
%     end
if num_relevant ~= 0
    F_relevant = zeros(num_relevant,num_features);       L_relevant = zeros(num_relevant,1);       relevant_idx = 1;
    F_notrelevant = zeros(num_notrelevant,num_features); L_notrelevant = zeros(num_notrelevant,1); notrelevant_idx = 1;

    F_relevant = F(idx,:);
    L_relevant = L(idx,:);
    clear tempF tempL
    tempF = F; tempL = L;
    tempF(idx,:) = [];
    tempL(idx,:) = [];
    F_notrelevant = tempF;
    L_notrelevant = tempL;
    clear tempF tempL

%     for i=1:length(F)
%         if strcmp(M{i},curr_sample) % same sample.
%             F_relevant(relevant_idx,:) = F(i,:);
%             L_relevant(relevant_idx,:) = L(i,:);
%             relevant_idx = relevant_idx + 1;
%         else                        % different sample.
%             F_notrelevant(notrelevant_idx,:) = F(i,:);
%             L_notrelevant(notrelevant_idx,:) = L(i,:);
%             notrelevant_idx = notrelevant_idx + 1;    
%         end
%     end
elseif num_relevant == 0 %% suggests sample was obtained after MODEL has been constructed.
    idx = strcmp(M2,curr_sample);
    num_relevant = length(find(idx == 1));
    F_relevant = zeros(num_relevant,num_features);       L_relevant = zeros(num_relevant,1);       relevant_idx = 1;
    F_notrelevant = zeros(num_notrelevant,num_features); L_notrelevant = zeros(num_notrelevant,1); notrelevant_idx = 1;

    F_relevant = F2(idx,:);
    L_relevant = L2(idx,:);
    F_notrelevant = F;
    L_notrelevant = L;
end


%% 2. Build model and apply to sample.

% Build model using features from notrelevant.
if num_relevant ~= 0
    Model = svmtrain(L_notrelevant,F_notrelevant,'-b 1 -c 8.0 -g 0.5 -q'); 
    % c = 8.0; g = 0.5 for SRE
    % c = 32.0; g = 0.125 for Npas4
else
    Model = Model_SRE_61_imqual;
end
% Make predictions for features from relevant.
[~,~,Probs] = svmpredict(L_relevant,F_relevant,Model,'-b 1');

% Compute F-score.
[X,Y,T,AUCPR] = perfcurve(L_relevant,Probs(:,1),1,'xCrit','PPV','yCrit','TPR'); % AUC-PR
F1 = 2.*X.*Y ./ (X+Y);
[max_f1,max_f1_idx] = max(F1);


%% 3. Output results and store output structure.

fprintf('#Sample=%s, Relevant=%i, NotRelevant=%i\n', curr_sample, size(F_relevant,1), size(F_notrelevant,1));
fprintf('\t AUCPR=%.3f, Prec=%.3f, Recall=%.3f, Thr=%.3f, F1=%.3f\n', AUCPR, X(max_f1_idx), Y(max_f1_idx), T(max_f1_idx), max_f1);
if isempty(sample_analysis{1})
    idx = 1;
else
    if ismember(curr_sample,sample_analysis{1}) % Has this sample been previously analysed
        [~,idx] = ismember(curr_sample,sample_analysis{1}); % if yes, overwrite the result
    else
        idx = size(sample_analysis{1},1) + 1; % if no, append new data to existing data
    end
end
sample_analysis{1,1}{idx} = curr_sample;
sample_analysis{1,2}(idx,1) = size(F_relevant,1);
sample_analysis{1,3}(idx,1) = size(F_notrelevant,1); 
sample_analysis{1,4}(idx,1) = AUCPR; 
sample_analysis{1,5}(idx,1) = X(max_f1_idx); 
sample_analysis{1,6}(idx,1) = Y(max_f1_idx); 
sample_analysis{1,7}(idx,1) = T(max_f1_idx);
sample_analysis{1,8}(idx,1) = max_f1;

Output{sample_idx,1} = curr_sample;
Output{sample_idx,2} = Model;
Output{sample_idx,3} = AUCPR;
Output{sample_idx,4} = X;
Output{sample_idx,5} = Y;
Output{sample_idx,6} = T;
Output{sample_idx,7} = F1;    
Output{sample_idx,8} = max_f1;
Output{sample_idx,9} = max_f1_idx;
Output{sample_idx,10} = T(max_f1_idx);
    
fprintf(out_file,'%s %s %s %s %s %s %s %s\n',column_names{1}{1,:}); 
for i = 1:size(sample_analysis{1},1)
    fprintf(out_file,'%s %d %d %0.3f %0.3f %0.3f %0.3f %0.3f\n',sample_analysis{1,1}{i},sample_analysis{1,2}(i,1),sample_analysis{1,3}(i,1),sample_analysis{1,4}(i,1),sample_analysis{1,5}(i,1),sample_analysis{1,6}(i,1),sample_analysis{1,7}(i,1),sample_analysis{1,8}(i,1));
end

fclose(out_file);
clear out_file
toc;
end
