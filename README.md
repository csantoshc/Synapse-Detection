# Synapse Detection
Using SVM to detect EPTA-stained synapses in electron microscopy images

Features_label_SRE_125_61.mat contains
  
  1. Features and Labels of 1665 synapses and 10441 non-synapse objects that were manually labeled.
  2. Model_SRE_61 is the classifier built from these features and used for synapse detection

Building the training set involves manually labeling selected objects in the images as synapses or non-synapses. Then, the program crops out a patch of the image surrounding each object. The size of this patch can be defined by the user in the variable ‘patch_size’. Currently, it is set at 125 x 125 pixels. Following this, while building features during the analysis, each object is rotated and cropped down further defined by the variable ‘crop_down’. Currently, this is set to get a final patch of 61 x 61 pixels in process_patch.m. Ensure that both trainingset and testset images are subjected to same treatment, i.e., the parameters are the same.

    bw_thresh = 0.10;            % threshold for selecting objects in binary image
    min_synapse_size = 300;      % min # of segment pixels for synapses.
    max_synapse_size = 60*60;    % max # of segment pixels for synapses.
    min_synapse_perimeter = 90;  % min # of segment pixels for synapse perimeter.
    patch_size = 125;            % size of the patch taken around the centroid. previously was 75

Setting up the required packages

1.  Designate a root folder. In this example, let it be E:\EMImages.
2.  Download and copy the Tools folder into the root folder, as in E:\EMImages\Tools.
    Alternatively, download and copy the files from the websites listed below into the Tools folder.
    a. The ba_interpolation package, available here -       
        http://www.mathworks.com/matlabcentral/fileexchange/20342-image-interpolation-bainterp2
    b. MR8 filter bank, available here - http://www.robots.ox.ac.uk/~vgg/research/texclass/filters.html
    c. HoG descriptors, available here - http://www.mathworks.com/matlabcentral/fileexchange/33863-histograms-of-oriented-gradients
    d. LibSVM, available here - http://www.csie.ntu.edu.tw/~cjlin/libsvm/
    e. the RFS filter - http://www.robots.ox.ac.uk/~vgg/research/texclass/

3.  Run the script load_packages.m. This will compile all the required MEX files. (Type ‘load_packages’ in the command window and hit     ‘Enter’).

Analysis of images for synapse detection

1.  Folder structure – All images from a single sample is stored in a specific folder. The folders of different samples are in one parent directory which resides in the root folder (here – E:\EMImages) where all the packages have been installed.

2.  Labeling the synapses -

    This step lets the user manually label synapses across all samples and save the labeled images in a single folder Program to be       used – build_training_data_from_segments.m While calling the function,
    
i.  Specify the parent folder containing all samples.

ii. Name a new folder where the program will store all the labeled objects, e.g. ‘trainingset_P1839’. It should be called like            this -

        >> build_training_data_from_segments(‘P-1839’,'trainingset_P1839');

3.  Analyzing the images -
    Program to be used run_synapse_detection.m It should be called like this –


        >> run_synapse_detection(‘P-1839’,'trainingset_P1839');
    
i.  Parent folder is P-1839

ii. The second argument would be the folder you created to store your labeled images (step 2.ii). Here, it would be trainingset_P1839.     This is used by build_features_samplewise to build the feature set for the labeled objects.

iii.The confidence threshold will be determined that will proved a recall of 50%. This is done by generating the ROC curves in the         function determine_threshold and then using get_threshold to choose the appropriate threshold.

iv. Then, the function test_directory will go through all samples individually that are part of the parent folder and analyze all the     images in each sample folder to detect synapses based on the threshold.

Building your own Model: In case you want to build your own Model from scratch do the following

In Matlab,

    >> [Features,Labels,Mapping] = build_features_samplewise(trainingsetDir)
    >> libsvmwrite('Examples.txt',Labels,sparse(Features));

Then in python do a grid search,

    $ ./grid.py Examples.txt
    
This will take a while, maybe 24 hours, depending how fast your computer is and how many examples you have. It will output the values of the two parameters ('c' and 'g'). You can read more about what these parameters mean here: http://www.csie.ntu.edu.tw/~cjlin/libsvm/

Now that you have 'c' and 'g', go back to MATLAB and train the classifier using these values as shown below,

    >> Model = svmtrain(Labels,Features,'-b 1 -c 32.0 -g 0.125 -q');
