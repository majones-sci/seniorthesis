% This script allows a user to select and measure the distance between two points in an image 
% taken with a single Intel RealSense D405.

clc;

fx = 642.0322;%cameraInfo{1,1}.K(1); % Extract the focal length in x-direction
fy = 642.0322;%cameraInfo{1,1}.K(5); % Extract the focal length in y-direction
cx = 644.5947;%cameraInfo{1,1}.K(3); % Extract the x-coordinate of the principal point
cy = 369.6580;%cameraInfo{1,1}.K(6); % Extract the y-coordinate of the principal point

depth_data = adjusteddepthMatrix_L;

figure;
imshow(I3);
hold on; % Enable holding the plot for adding black dots

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
    dot_handle = plot(round(x), round(y), 'ko', 'MarkerFaceColor', 'k','MarkerSize', dot_size);
    dot_handles = [dot_handles; dot_handle];

    % Print the pixel location

    disp(['Pixel location: (' num2str(round(x)) ', ' num2str(round(y)) ')']);

end

 

% Display the matrix of pixel locations

disp('Matrix of pixel locations:');

disp(pixel_locations);




pixelX1 =pixel_locations(1,1) % Specify the x-coordinate of the pixel

pixelY1 =pixel_locations(1,2) % Specify the y-coordinate of the pixel

 

pixelX2 =pixel_locations(2,1) % Specify the x-coordinate of the pixel

pixelY2 =pixel_locations(2,2) % Specify the y-coordinate of the pixel

 

 

%Check Points to make sure they're not zero (or else the code will be very

%off bc the distance calculation will be wonky!

 

 

% Check if the value at (row_num, col_num) is 0

if depth_data(pixelY1, pixelX1) == 0

    disp("the value at this cell (Pixel 1) is 0");

    % Find the indices of all nonzero elements in the matrix

    [nz_row, nz_col] = find(depth_data~=0);

    % Calculate the distance between each nonzero element and the input cell

    dist = sqrt((nz_row - pixelY1).^2 + (nz_col - pixelX1).^2);

    % Find the index of the closest nonzero element

    [~, idx] = min(dist);

    % Get the value and indices of the closest nonzero element

    closest_val = depth_data(nz_row(idx), nz_col(idx));

    closest_row = nz_row(idx);

    closest_col = nz_col(idx);

    %set new pixel values

    pixelY1=closest_row

    pixelX1=closest_col

    % Print the value and cell number of the closest nonzero element

    fprintf("Closest nonzero value (for Pixel 2): %d at cell (%d,%d)\n", closest_val, closest_row, closest_col);

end

 

% Check if the value at (row_num, col_num) is 0

if depth_data(pixelY2, pixelX2) == 0

    disp("the value at this cell (Pixel 2) is 0");

    % Find the indices of all nonzero elements in the matrix

    [nz_row, nz_col] = find(depth_data~=0);

    % Calculate the distance between each nonzero element and the input cell

    dist = sqrt((nz_row - pixelY2).^2 + (nz_col - pixelX2).^2);

    % Find the index of the closest nonzero element

    [~, idx] = min(dist);

    % Get the value and indices of the closest nonzero element

    closest_val2 = depth_data(nz_row(idx), nz_col(idx));

    closest_row2 = nz_row(idx);

    closest_col2 = nz_col(idx);

    % Print the value and cell number of the closest nonzero element

    fprintf("Closest nonzero value for Pixel 2: %d at cell (%d,%d)\n", closest_val2, closest_row2, closest_col2);

    pixelY2=closest_row2

    pixelX2=closest_col2

end

%track final pixel locations
finalpixel_locations = [];
finalpixel_locations = [finalpixel_locations; pixelX1, pixelY1];
finalpixel_locations = [finalpixel_locations; pixelX2, pixelY2];


% Convert pixel coordinates to real-world xy coordinates

depthValue1 = double(depth_data(pixelY1, pixelX1))/ 10000; % Convert depth value to meters

x1 = (pixelX1 - cx) * depthValue1 / fx; % Compute x-coordinate in meters

y1 = (pixelY1 - cy) * depthValue1 / fy; % Compute y-coordinate in meters

z1 = double(depth_data(pixelY1, pixelX1)) /10000;

 

depthValue2 = double(depth_data(pixelY2, pixelX2))/10000; % Convert depth value from mm to meters

x2 = (pixelX2 - cx) * depthValue2 / fx; % Compute x-coordinate in meters

y2 = (pixelY2 - cy) * depthValue2 / fy; % Compute y-coordinate in meters

z2 = double(depth_data(pixelY1, pixelX1)) /10000;

 

%distance

point1 = [x1, y1, z1]; % Replace with the coordinates of your first point

 

point2 = [x2, y2, z2]; % Replace with the coordinates of your second point

 

% Calculate the Euclidean distance in mm

distance = sqrt((point2(1) - point1(1))^2 + (point2(2) - point1(2))^2 + (point2(3) - point1(3))^2);

distanceinmm = distance*1000;

% Display the result

fprintf('The Euclidean distance (in mm) between point 1 and point 2 is: %.2f\n', distanceinmm);


% For Data Analysis!
fprintf('The Euclidean distance (in mm) between point 1 and point 2 is: %.2f\n', distanceinmm);
fprintf('The Z value (in mm) of point 1  is: %.2f\n',point1(3)*1000);
fprintf('The Z value (in mm) of point 2  is: %.2f\n',point2(3)*1000);
disp(finalpixel_locations);
disp(pixel_locations);



depth_data = combinedImage2;
 
% Display the matrix of pixel locations

disp('Matrix of pixel locations:');

disp(pixel_locations);
%___

% Example of converting pixel coordinates to real-world xy coordinates

pixelX1 =pixel_locations(1,1) % Specify the x-coordinate of the pixel

pixelY1 =pixel_locations(1,2) % Specify the y-coordinate of the pixel

 

pixelX2 =pixel_locations(2,1) % Specify the x-coordinate of the pixel

pixelY2 =pixel_locations(2,2) % Specify the y-coordinate of the pixel

% Check if the value at (row_num, col_num) is 0

if depth_data(pixelY1, pixelX1) == 0

    disp("the value at this cell (Pixel 1) is 0");

    % Find the indices of all nonzero elements in the matrix

    [nz_row, nz_col] = find(depth_data~=0);

    % Calculate the distance between each nonzero element and the input cell

    dist = sqrt((nz_row - pixelY1).^2 + (nz_col - pixelX1).^2);

    % Find the index of the closest nonzero element

    [~, idx] = min(dist);

    % Get the value and indices of the closest nonzero element

    closest_val = depth_data(nz_row(idx), nz_col(idx));

    closest_row = nz_row(idx);

    closest_col = nz_col(idx);

    %set new pixel values

    pixelY1=closest_row

    pixelX1=closest_col

    % Print the value and cell number of the closest nonzero element

    fprintf("Closest nonzero value (for Pixel 2): %d at cell (%d,%d)\n", closest_val, closest_row, closest_col);

end

 

% Check if the value at (row_num, col_num) is 0

if depth_data(pixelY2, pixelX2) == 0

    disp("the value at this cell (Pixel 2) is 0");

    % Find the indices of all nonzero elements in the matrix

    [nz_row, nz_col] = find(depth_data~=0);

    % Calculate the distance between each nonzero element and the input cell

    dist = sqrt((nz_row - pixelY2).^2 + (nz_col - pixelX2).^2);

    % Find the index of the closest nonzero element

    [~, idx] = min(dist);

    % Get the value and indices of the closest nonzero element

    closest_val2 = depth_data(nz_row(idx), nz_col(idx));

    closest_row2 = nz_row(idx);

    closest_col2 = nz_col(idx);

    % Print the value and cell number of the closest nonzero element

    fprintf("Closest nonzero value for Pixel 2: %d at cell (%d,%d)\n", closest_val2, closest_row2, closest_col2);

    pixelY2=closest_row2

    pixelX2=closest_col2

end



% Convert pixel coordinates to real-world xy coordinates

depthValue1 = double(depth_data(pixelY1, pixelX1))/ 10000; % Convert depth value to meters

x1 = (pixelX1 - cx) * depthValue1 / fx; % Compute x-coordinate in meters

y1 = (pixelY1 - cy) * depthValue1 / fy; % Compute y-coordinate in meters

z1 = double(depth_data(pixelY1, pixelX1)) /10000;

 

depthValue2 = double(depth_data(pixelY2, pixelX2))/10000; % Convert depth value from mm to meters

x2 = (pixelX2 - cx) * depthValue2 / fx; % Compute x-coordinate in meters

y2 = (pixelY2 - cy) * depthValue2 / fy; % Compute y-coordinate in meters

z2 = double(depth_data(pixelY1, pixelX1)) /10000;

 

%distance

point1 = [x1, y1, z1]; % Replace with the coordinates of your first point

 

point2 = [x2, y2, z2]; % Replace with the coordinates of your second point

 

% Calculate the Euclidean distance in mm

distance = sqrt((point2(1) - point1(1))^2 + (point2(2) - point1(2))^2 + (point2(3) - point1(3))^2);

distanceinmm = distance*1000;

% Display the result

fprintf('The Euclidean distance (in mm) between point 1 and point 2 is: %.2f\n', distanceinmm);


% For Data Analysis!
fprintf('The Z value (in mm) of point 1  is: %.2f\n',point1(3));
fprintf('The Z value (in mm) of point 2  is: %.2f\n',point2(3));
%fprintf('The Euclidean distance (in mm) between point 1 and point 2 is: %.2f\n', distanceinmm);
%fprintf('The Euclidean distance (in mm) between point 1 and point 2 is: %.2f\n', distanceinmm);

%}