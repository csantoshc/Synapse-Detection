% This script saves the filepaths to the required packages to generate features and use 
% SVM. Also, compiles the required C scripts and generates MEX files

%% Adding the filepaths to the package folders

baseDir = pwd; % Make sure the current directory is the one where the Tools folder is
baseToolsDir = fullfile(baseDir,'Tools');
if ~exist(baseToolsDir,'dir') && ~exist(fullfile(baseDir,'count_synapses'),'dir')
    disp('Error: Set current directory to the one where the Tools folder is located')
    break
end

addpath(genpath(baseDir))
% addpath(genpath(baseToolsDir))
% addpath(genpath(fullfile(baseDir,'count_synapses')))
% addpath(genpath(fullfile(baseToolsDir,'ba_interpolation','ba_interpolation')))
% addpath(genpath(fullfile(baseToolsDir,'HoG')))
% addpath(genpath(fullfile(baseToolsDir,'libsvm-3.12','libsvm-3.12')))
savepath
%% Compiling the C files

mex(fullfile(baseToolsDir,'anigaussm','anigauss_mex.c'),fullfile(baseToolsDir,'anigaussm','anigauss.c'),'-output','anigauss')
mex('-O',fullfile(baseToolsDir,'ba_interpolation','ba_interpolation','ba_interp2.cpp'))
mex(fullfile(baseToolsDir,'HoG','HoG.cpp'))

libsvmMfilepath = fullfile(baseToolsDir,'libsvm-3.12','libsvm-3.12','matlab');
mex('CFLAGS="\$CFLAGS -std=c99"','-largeArrayDims',fullfile(libsvmMfilepath,'libsvmread.c'))
mex('CFLAGS="\$CFLAGS -std=c99"','-largeArrayDims',fullfile(libsvmMfilepath,'libsvmwrite.c'))
mex('CFLAGS="\$CFLAGS -std=c99"','-largeArrayDims',fullfile(libsvmMfilepath,'svmtrain.c'),fullfile(fileparts(libsvmMfilepath),'svm.cpp'),fullfile(libsvmMfilepath,'svm_model_matlab.c'))
mex('CFLAGS="\$CFLAGS -std=c99"','-largeArrayDims',fullfile(libsvmMfilepath,'svmpredict.c'),fullfile(fileparts(libsvmMfilepath),'svm.cpp'),fullfile(libsvmMfilepath,'svm_model_matlab.c'))

clear all