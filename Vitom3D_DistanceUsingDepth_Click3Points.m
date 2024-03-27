% Background
%{ 
This code has all of the information needed to calculate the disparity
matrix of 2 images taken using the Vitcom 3d stereo endoscope.

For analysis of a stereo image from an endoscope I used ImageSplitter to
cut the combined mages into left and right. K matrix values were obtained
from calibration session 1 (calibrationSessionendoscope1.mat). For true
values, data must be released from Karl Storz Company.
%}

%%  Setup
load('calibrationSessionEndoscope1.mat')

%% Step 1

%Taken from K matrix of endoscope calibration session

fx = 8.507609645148383e+03; % Extract the focal length in x-direction
fy = 4.260499129210713e+03; % Extract the focal length in y-direction
cx = 9.978250779119943e+02; % Extract the x-coordinate of the principal point
cy = 2.042990213368373e+02; % Extract the y-coordinate of the principal point

%calculating overall focal length
%f = (fx + fy)/2
f=fx %for the purpose of disparity map production, only the focal length in the x-direction was used.

%% Step 2: Calculate Disparity Matrix

% Rectify color Images
I3 = imread('top_half_Ch2_003_S.jpg');%imread('top_half__BCh2_009_S.jpg');  
I4 = imread('bottom_half_Ch2_003_S.jpg');%imread('bottom_half__BCh2_009_S.jpg'); 
[J3,J4] = rectifyStereoImages(I3,I4,calibrationSession.CameraParameters);

% Convert the images to grayscale
leftImageGray = rgb2gray(J3);
rightImageGray = rgb2gray(J4);

%{ 
Non Essential: Uncomment this the block of code if you would like to visualize the individual
images and stereoanaglyph.
figure;
imshow(leftImageGray);
figure;
imshow(rightImageGray);
stereoimg = stereoAnaglyph(J3,J4);
figure;
imshow(stereoimg);
figure;
imshow(stereoAnaglyph(I3,I4));
%}

disparityRange = [0 128];
disparityMapC = disparitySGM(leftImageGray,rightImageGray,"DisparityRange",disparityRange,"UniquenessThreshold",20);


%{
Non Essential: Uncomment this block of code if you would like to display the disparity map. Set the display range to the same value as the disparity range.
figure;
imshow(disparityMapC,disparityRange);
title("Disparity Map");
colormap jet;
colorbar;
%}

%% Step 3:

%{
Calculations of the depth matrix below follow the form:
Z = f * B / d 
where:
Z represents the depth matrix, which will store the estimated depth values.
f is a constant representing the focal length of the camera.
B is a constant representing the baseline between two stereo cameras.
d represents the disparity values, which are stored in the disparity_matrix variable.

%}

TranslationOfCamera2 = [-12.7382715579158,-0.00441617244792605,-0.396007803680120] %Obtained from the Calibration Session data.
B = norm(TranslationOfCamera2);
%disparity_matrix = disparityMapC;
disparity_matrix = Ddynamic;

% Convert disparity to depth
depth_matrix = (f * B) ./ disparity_matrix;

% Identify NaN values
nanIndices = isnan(depth_matrix);

% Replace NaN values with zeros
depth_matrix(nanIndices) = 0;

%convert depth to mm
%depth_matrix=depth_matrix.*0.44; %The depth matrix was scaled by comparing recorded and real world values.

%% Step 4: calculate depth using disparity matrix

figure;
imshow(I3);
hold on; % Enable holding the plot for adding black dots on selected points

% Initialize a matrix to store the pixel locations
pixel_locations = [];
dot_handles = []; % Store the handles of black dots for erasing

disp('Click on the image to retrieve pixel location. Press "d" to delete a pixel. Press "q" to quit.');

while true
    % Wait for a mouse click
    [x, y, button] = ginput(1);

    % Check if the user pressed "q" to quit
    if button == 'q'
        break;
    end

    % Check if the user pressed "d" to delete a pixel
    if button == 'd'
        if ~isempty(pixel_locations)
            % Remove the last row from the matrix
            pixel_locations(end, :) = [];
            disp('Last pixel location removed.');
            % Erase the last black dot from the color image
            delete(dot_handles(end));
            dot_handles(end) = []; % Remove the handle from the list
            disp('Last pixel location and black dot removed.');
        else
            disp('Matrix is already empty.');
        end
        continue;  % Skip to the next iteration of the loop
    end

    % Add the pixel location to the matrix
    pixel_locations = [pixel_locations; round(x), round(y)];

    % Add a black dot on the color image
    dot_size = 2;
    dot_handle = plot(round(x), round(y), 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', dot_size);
    dot_handles = [dot_handles; dot_handle];

    % Print the pixel location
    disp(['Pixel location: (' num2str(round(x)) ', ' num2str(round(y)) ')']);
end


% Calculate distances between A, B, and C in pixels
if size(pixel_locations, 1) >= 3
    pixelA = pixel_locations(1, :);
    pixelB = pixel_locations(2, :);
    pixelC = pixel_locations(3, :);

    distanceAB_pixels = norm(pixelB - pixelA);
    distanceBC_pixels = norm(pixelC - pixelB);


   % Check 1: getting rid of zeros

   pixels = [pixelA; pixelB; pixelC];  % Assuming pixelA, pixelB, and pixelC are defined earlier
   %pixels
   fprintf('The original pixel locations are');
   pixels
   for i = 1:3
    pixelX = pixels(i, 1);
    pixelY = pixels(i, 2);
    
        if depth_matrix(pixelY, pixelX) == 0
            disp(['The value at this cell (Pixel ' num2str(i) ') is 0']);
        
            % Find the indices of all nonzero elements in the matrix
            [nz_row, nz_col] = find(depth_matrix ~= 0);
        
            % Calculate the distance between each nonzero element and the input cell
            dist = sqrt((nz_row - pixelY).^2 + (nz_col - pixelX).^2);
        
            % Find the index of the closest nonzero element
            [~, idx] = min(dist);
        
            % Get the value and indices of the closest nonzero element
            closest_val = depth_matrix(nz_row(idx), nz_col(idx));
            closest_row = nz_row(idx);
            closest_col = nz_col(idx);
        
            % Set new pixel values
            pixels(i, :) = [closest_col, closest_row];
        
            % Print the value and cell number of the closest nonzero element
            fprintf(['Closest nonzero value for Pixel ' num2str(i) ': %d at cell (%d,%d)\n'], closest_val, closest_row, closest_col);
        else
            disp('Not enough points (A, B, C) selected to calculate distances.');
        end
    end
%end 

fprintf('The new pixel locations (after check 1) are');
pixels
pixelA(1) = pixels(1,1);
pixelA(2) = pixels(1,2);
pixelB(1) = pixels(2,1);
pixelB(2) = pixels(2,2);
pixelC(1) = pixels(3,1);
pixelC(2) = pixels(3,2);

%Add the new points to the image (helps to visualize where the used versus
%selected points are.

    % Add a red dot on the color image over the new pixel locations
    dot_size = 3;
    dot_handle = plot(pixelA(1), pixelA(2), 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', dot_size);
    dot_handles = [dot_handles; dot_handle];

    dot_size = 3;
    dot_handle = plot(pixelB(1), pixelB(2), 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', dot_size);
    dot_handles = [dot_handles; dot_handle];

    dot_size = 3;
    dot_handle = plot(pixelC(1), pixelC(2), 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', dot_size);
    dot_handles = [dot_handles; dot_handle];

%calculate depth value
depthValueA = double(depth_matrix(pixelA(2), pixelA(1)))
depthValueB = double(depth_matrix(pixelB(2), pixelB(1))) 
depthValueC = double(depth_matrix(pixelC(2), pixelC(1)))


% Check 2: Checking + Fixing the middle number (do this first)

values = [depthValueA, depthValueB, depthValueC];  % Replace with your three values
threshold = 100;

% Check if value2 is an outlier
if abs(values(2) - values(1)) > threshold && abs(values(2) - values(3)) > threshold
    % Check if value1 and value3 are outliers
    if abs(values(1) - values(3)) > threshold
        fprintf('Check 2: The depth value of the middle point could not be changed because ponts A and C are both outliers');
    else
        % Set value2 to the average of value1 and value3
        result = (values(1) + values(3)) / 2;
        values(2) = result;
        fprintf('Check 2: The depth value of the middle point was changed to: %s\n', num2str(result));
    end
else 
     fprintf('Check 2: The depth value of the middle point was not changed');
end

% Distance calculations - Convert pixel coordinates to real-world xy coordinates
    %depthValueA = double(depth_matrix(pixelA(2), pixelA(1))) %/ 10000; % Convert depth value to meters
    xA = (pixelA(1) - cx) * depthValueA / fx;
    yA = (pixelA(2) - cy) * depthValueA / fy;

    %depthValueB = double(depth_matrix(pixelB(2), pixelB(1))) %/ 10000;
    xB = (pixelB(1) - cx) * depthValueB / fx;
    yB = (pixelB(2) - cy) * depthValueB / fy;

    %depthValueC = double(depth_matrix(pixelC(2), pixelC(1))) %/ 10000;
    xC = (pixelC(1) - cx) * depthValueC / fx;
    yC = (pixelC(2) - cy) * depthValueC / fy;

    % Calculate the Euclidean distance in millimeters
    distanceAB_mm = sqrt((xB - xA)^2 + (yB - yA)^2);
    distanceBC_mm = sqrt((xC - xB)^2 + (yC - yB)^2);
    totalDistance_mm = distanceAB_mm + distanceBC_mm;


% Check 3: If the middle number is good, but one of the edges (A or C) is
% bad, do this (multiply the reasonable line segment by two)

number1 = distanceAB_mm;
number2 = distanceBC_mm;

if number1 <= 40 && number2 <= 40
    % If neither number is bigger than 40, add them
    result = number1 + number2;
    fprintf('Check 3 passed: AB and BC were both less than 40 mm');
elseif number1 > 40 && number2 <= 40
    % If only number1 is bigger than 40, return 2 times the smaller one
    result = 2 * min(number1, number2);
    fprintf('Check 3 error: Distance AB was greater than 40 mm. New distance = BC x 2');
elseif number2 > 40 && number1 <= 40
    % If only number2 is bigger than 40, return 2 times the smaller one
    result = 2 * min(number1, number2);
    fprintf('Check 3 error: Distance BC was greater than 40 mm. New distance = AB x 2');
else
    % If both numbers are bigger than 40, return the specified message
    fprintf('Check 3 error: distance could not be calculated because both distances AB and BC are greater than 40 mm');
end


% Display the distances in millimeters
    fprintf('Distance between A and B (calculated without check 3): %.2f mm\n', distanceAB_mm);
    fprintf('Distance between B and C (calculated without check 3): %.2f mm\n', distanceBC_mm);
    fprintf('The total Distance (A to B + B to C) calculated without check 3 is: %.2f mm\n', totalDistance_mm);
    fprintf('The updated total distance (including all 3 checks) is: %s\n', result); % Convert the result to a string for display


else
    disp('Not enough points (A, B, C) selected to calculate distances.');
end
