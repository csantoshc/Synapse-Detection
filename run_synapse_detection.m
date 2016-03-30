%========================================================================%
%    WRAPPER FUNCTION THAT CALLS APPROPRIATE FUNCTIONS TO
%    BUILD FEATURES, DETERMINE THRESHOLD AND DETECT SYNAPSES                                                    %
%                                                                        %
%    Author: Santosh Chandrasekaran
%    Date  : August 2013                                                 %
%========================================================================%

%% Assumption - Each folder in the parent directory has images obtained from a unique sample
function run_synapse_detection(parentDir, trainingsetDir)

    disp('Building features for labeled synapses')
    [Features,Labels,Mapping] = build_features_samplewise(trainingsetDir);
    save(fullfile(parentDir,'Features_Labels.mat'))
    
% Load previously constructed features, labels and Model for cortical synapses
    load('Features_Label_SRE_125_61.mat')  

%% Assigning filepaths
    baseDir = pwd; % Current folder
    dataDir = fullfile(baseDir,parentDir);
    % Get all folders in the parent directory that contain images

    allfiles = dir(dataDir);
    imgfolderidx = [allfiles(:).isdir];
    Imagedirs = {allfiles(imgfolderidx).name};
    Imagedirs(ismember(Imagedirs,{'.','..'})) = [];
    Imagedirs = Imagedirs';
    
    % Iterate through each folder (or equivalently, sample)
    directories = 1:length(Imagedirs);
    for dirs = directories
        srcDir=fullfile(dataDir,Imagedirs{dirs});
        fprintf('Current sample is %s\n', Imagedirs{dirs})
        clear Output thresholds

        % Construct the  ROC curve
        disp('Generating ROC curves')
        Output = determine_threshold(srcDir,Features_SRE_61,Labels_SRE_61,Mapping_SRE_61,Features,Labels,Mapping,Model_SRE_61);
        
        % Extract the threshold and precision which gives 50% recall
        disp('Determining threshold at 50% recall')
        [threshold, precision] = get_threshold(Output);
        if exist(fullfile(parentDir,'Recall50.mat'),'file')
            load(fullfile(parentDir,'Recall50.mat'))
        end
        Recall50_thrprec(dirs).samplename = Imagedirs{dirs};
        Recall50_thrprec(dirs).thresholds = threshold;
        Recall50_thrprec(dirs).precisions = precision;
        save(fullfile(parentDir,'Recall50.mat'),'Recall50_thrprec')
        % Use the obtained threshold for the sample to detect synapses by using the Model
        disp('Analysing images at 50% recall')
        test_directory(Model_SRE_61,Recall50_thrprec(dirs).thresholds,srcDir)
    end
end