%This code rectifies and combines two depth matrices in order to minimize
%the number of zeroes present. Coding support/debugging aided by ChatGPT. 
%% Reset Workspace
close all;
clear;
%%
%Step 1 - Get Left Image

%configure camera to the right pixel dimensions
config = realsense.config();
config.enable_stream(realsense.stream.depth,1280,720,realsense.format.z16,30);
config.enable_stream(realsense.stream.color,1280,720,realsense.format.rgb8,30);
% Make Pipeline object to manage streaming
pipe = realsense.pipeline();


    % Make Pipeline object to manage streaming
    pipe = realsense.pipeline();
    % Make Colorizer object to prettify depth output
    colorizer = realsense.colorizer();

    % Start streaming on an arbitrary camera with pre-specified settings
    profile = pipe.start(config);
    % Get streaming device's name
    dev = profile.get_device();
    name = dev.get_info(realsense.camera_info.name);

    % Get frames. We discard the first couple to allow
    % the camera time to settle
    for i = 1:5
        fs = pipe.wait_for_frames();
    end
    
    % Stop streaming
    pipe.stop();

    % Select depth frame
    depth = fs.get_depth_frame();
    % Get actual depth data
    depth_data = depth.get_data();
    % Convert depth data into a matrix
    depth_matrix_L = reshape(depth_data, [depth.get_width(), depth.get_height()]);
   
    % Colorize depth frame
    color = colorizer.colorize(depth);

    % Get actual data and convert into a format imshow can use
    % (Color data arrives as [R, G, B, R, G, B, ...] vector)
    data = color.get_data()
    depth_img_L = permute(reshape(data',[3,color.get_width(),color.get_height()]),[3 2 1])

    % Select color frame
    color_frame = fs.get_color_frame();
    
    % Get color data
    color_data = color_frame.get_data();
    
    % Convert color data into a format imshow can use
    color_img_L = permute(reshape(color_data', [3,color_frame.get_width(), color_frame.get_height()]),[3 2 1]);
 
    
    % Display depth image
    subplot(1, 2, 1);
    imshow(depth_img_L);
    colormap('gray');
    axis off;
    title(sprintf("Depth frame from %s", name));

    % Display RGB image
    subplot(1, 2, 2);
    imshow(color_img_L);
    title(sprintf("RGB frame from %s", name));

%%
%Step 2 - Get Right Image

%configure camera to the right pixel dimensions
config = realsense.config();
config.enable_stream(realsense.stream.depth,1280,720,realsense.format.z16,30);
config.enable_stream(realsense.stream.color,1280,720,realsense.format.rgb8,30);
% Make Pipeline object to manage streaming
pipe = realsense.pipeline();

    % Make Pipeline object to manage streaming
    pipe = realsense.pipeline();
    % Make Colorizer object to prettify depth output
    colorizer = realsense.colorizer();

    % Start streaming on an arbitrary camera with default settings
    %profile = pipe.start();
    profile = pipe.start(config);
    % Get streaming device's name
    dev = profile.get_device();
    name = dev.get_info(realsense.camera_info.name);

    % Get frames. We discard the first couple to allow
    % the camera time to settle
    for i = 1:5
        fs = pipe.wait_for_frames();
    end
    
    % Stop streaming
    pipe.stop();

    % Select depth frame
    depth = fs.get_depth_frame();
    % Get actual depth data
    depth_data = depth.get_data();
    % Convert depth data into a matrix
    depth_matrix_R = reshape(depth_data, [depth.get_width(), depth.get_height()]);
   
    % Colorize depth frame
    color = colorizer.colorize(depth);

    % Get actual data and convert into a format imshow can use
    % (Color data arrives as [R, G, B, R, G, B, ...] vector)
    data = color.get_data()
    depth_img_R = permute(reshape(data',[3,color.get_width(),color.get_height()]),[3 2 1])

    % Select color frame
    color_frame = fs.get_color_frame();
    
    % Get color data
    color_data = color_frame.get_data();
    
    % Convert color data into a format imshow can use
    color_img_R = permute(reshape(color_data', [3,color_frame.get_width(), color_frame.get_height()]),[3 2 1]);
 
    
    % Display depth image
    subplot(1, 2, 1);
    imshow(depth_img_R);
    colormap('gray');
    axis off;
    title(sprintf("Depth frame from %s", name));

    % Display RGB image
    subplot(1, 2, 2);
    imshow(color_img_R);
    title(sprintf("RGB frame from %s", name));
%% Get Matrices and Save Data
%Left
figure;
adjusteddepthMatrix_L = rotateAndMirror(depth_matrix_L);
imshow(adjusteddepthMatrix_L);

imwrite(color_img_L,"Leftcolor.png")
imwrite(depth_matrix_L,"Leftdepth.png")

%Right
figure;
adjusteddepthMatrix_R = rotateAndMirror(depth_matrix_R);
imshow(adjusteddepthMatrix_R);

imwrite(color_img_R,"Rightcolor.png")
imwrite(depth_matrix_R,"Rightdepth.png")

% Step 3: Rectify depth Images
I1 = adjusteddepthMatrix_L;
I2 = adjusteddepthMatrix_R; 
[J1,J2] = rectifyStereoImages(I1,I2,calibrationSession.CameraParameters);

%
figure
imshow(adjusteddepthMatrix_L)
figure
imshow(adjusteddepthMatrix_R)
stereoimg = stereoAnaglyph(J1,J2);
figure
imshow(stereoimg);
figure
imshow(stereoAnaglyph(I1,I2));

% Step 4: Rectify color Images
I3 = imread('Leftcolor.png');  
I4 = imread('Rightcolor.png'); 
[J3,J4] = rectifyStereoImages(I3,I4,calibrationSession.CameraParameters);

% Convert the images to grayscale
leftImageGray = rgb2gray(J3);
rightImageGray = rgb2gray(J4);

figure
imshow(leftImageGray)
figure
imshow(rightImageGray)
stereoimg = stereoAnaglyph(J3,J4);
figure
imshow(stereoimg);
figure
imshow(stereoAnaglyph(I3,I4));

disparityRange = [0 128];
disparityMapC = disparitySGM(leftImageGray,rightImageGray,"DisparityRange",disparityRange,"UniquenessThreshold",20);
%Display the disparity map. Set the display range to the same value as the disparity range.

figure
imshow(disparityMapC,disparityRange)
title("Disparity Map")
colormap jet
colorbar

% Step 5: Combine the Matrices to populate holes

combinedImage2 = combineStereoImages(J1, J2, disparityMapC)

figure;
imshow(combinedImage2);

save ImageTrial1.mat







%% ANALYSIS/COMPARISON

zeroLeft = sum(adjusteddepthMatrix_L(:) == 0);
zeroRight = sum(adjusteddepthMatrix_R(:) == 0);
zeroComb = sum(combinedImage2(:) == 0);

disp(zeroLeft); disp(zeroRight); disp(zeroComb);
disp((zeroLeft-zeroComb)/407040);

%%    
figure;
    % Display depth matrix Left
    subplot(2, 2, 1);
    imshow(adjusteddepthMatrix_L);
    colormap('jet');
    axis off;
    title(sprintf("Depth frame Left from %s", name));

    % Display RGB image
    subplot(2, 2, 2);
    imshow(adjusteddepthMatrix_R);
    colormap('jet');
    axis off;
    title(sprintf("Depth frame Right from %s", name));

    % Display depth image
    subplot(2, 2, 3);
    imshow(combinedImage2);
    colormap('jet');
    axis off;
    title(sprintf("Depth frame Combined from %s", name));

    % Display RGB image
    subplot(2, 2, 4);
    imshow(color_img_L);
    title(sprintf("RGB frame from %s", name));

    %suptitle('The combined image has', ((zeroLeft-zeroComb)/407040)*100 , 'less holes than the left image');
