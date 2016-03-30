%========================================================================%
%    DETERMINES THRESHOLD AND PRECISION AT 50% RECALL                    %
%                                                                        %
%    Author: Saket Navlakha & Santosh Chandrasekaran                     %
%    Date  : September 2013
%                                                                        %
%========================================================================%

function [Threshold, Precision] = get_threshold(Output)
% GET_THRESHOLD
% Searches for the threshold at which the algorithm gives a recall of 50%
% Input is the result of building ROC curves for that sample using the
% script determine_threshold.
% Gives back the threshold and precision at 50% recall

for ii=1:size(Output,1)
    Precisions = Output{ii,4};
    Recall = Output{ii,5};
    Thresholds = Output{ii,6};

    % Get index when recall is roughly 50%.
%     idx = find(Recall > 0.492 & Recall < 0.502,1,'first');
    [~,idx] = min(abs(Recall - 0.500));
    fprintf('%s\tthr=%.3f\tprec=%.3f\trecall=%.3f\n', Output{ii,1}, Thresholds(idx), Precisions(idx), Recall(idx));
    Threshold = Thresholds(idx);
    Precision = Precisions(idx);
end
end

