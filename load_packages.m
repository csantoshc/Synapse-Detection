% This script saves the filepaths to the required packages to generate features and use 
% SVM. Also, compiles the required C scripts and generates MEX files

%% Adding the filepaths to the package folders

baseDir = pwd; % Make sure the current directory is the one where the Tools folder is
baseDir = fullfile(baseDir,'Tools');

addpath(genpath(baseDir))
addpath(genpath(fullfile(baseDir,'ba_interpolation','ba_interpolation')))
addpath(genpath(fullfile(baseDir,'count_synapses')))
addpath(genpath(fullfile(baseDir,'HoG')))
addpath(genpath(fullfile(baseDir,'libsvm-3.12','libsvm-3.12')))
savepath
%% Compiling the C files

mex(fullfile(baseDir,'anigaussm','anigauss_mex.c'),fullfile(baseDir,'anigaussm','anigauss.c'),'-output','anigauss')
mex('-O',fullfile(baseDir,'ba_interpolation','ba_interpolation','ba_interp2.cpp'))
mex(fullfile(baseDir,'HoG','HoG.cpp'))

libsvmMfilepath = fullfile(baseDir,'libsvm-3.12','libsvm-3.12','matlab');
mex('CFLAGS="\$CFLAGS -std=c99"','-largeArrayDims',fullfile(libsvmMfilepath,'libsvmread.c'))
mex('CFLAGS="\$CFLAGS -std=c99"','-largeArrayDims',fullfile(libsvmMfilepath,'libsvmwrite.c'))
mex('CFLAGS="\$CFLAGS -std=c99"','-largeArrayDims',fullfile(libsvmMfilepath,'svmtrain.c'),fullfile(fileparts(libsvmMfilepath),'svm.cpp'),fullfile(libsvmMfilepath,'svm_model_matlab.c'))
mex('CFLAGS="\$CFLAGS -std=c99"','-largeArrayDims',fullfile(libsvmMfilepath,'svmpredict.c'),fullfile(fileparts(libsvmMfilepath),'svm.cpp'),fullfile(libsvmMfilepath,'svm_model_matlab.c'))

clear all