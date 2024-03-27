%This code allows a user to split an image from the Vitom 3D exoscope.
%Images sent from the Vitom 3D are stacked and must be split for stereo
%image analysis.

% Specify the directory containing the input images
inputDirectory = '/Users/melissajones/Documents/ES91r/11_13_2023_3DImages/';

% Get a list of all JPG files in the directory
imageFiles = dir(fullfile(inputDirectory, 'Ch2_*.JPG'));

% Loop through each image
for idx = 1:numel(imageFiles)
    % Load the current image
    inputImage = imread(fullfile(inputDirectory, imageFiles(idx).name));

    % Get the dimensions of the input image
    [height, width, ~] = size(inputImage);

    % Calculate the mid-point
    midPoint = floor(height / 2);

    % Split the image into top and bottom halves
    topHalf = inputImage(1:midPoint, :, :);
    bottomHalf = inputImage(midPoint+1:end, :, :);

    % Create new file names for the halves
    baseFileName = imageFiles(idx).name(1:end-4); % Remove the '.JPG' extension
    topHalfFileName = sprintf('top_half_%s.jpg', baseFileName);
    bottomHalfFileName = sprintf('bottom_half_%s.jpg', baseFileName);

    % Save the top and bottom halves as separate images
    imwrite(topHalf, fullfile(inputDirectory, topHalfFileName));
    imwrite(bottomHalf, fullfile(inputDirectory, bottomHalfFileName));
    
    fprintf('Image %d processed\n', idx);
end

disp('All images processed and split!');
