%This code allows a user to click on two points of interest and returns the
%distance in mm between them. It employs checks to verify that select the 
% nearest nonzero point if a zero is selected. The image must be uploaded
% as a bag file.

bag = rosbag('Group2T1.bag'); % Load the bag file

% Extract depth image and camera info from a bag file
depthImageTopic = '/device_0/sensor_0/Depth_0/image/data'; % Specify the topic name of the depth image data in your bag file
cameraInfoTopic = '/device_0/sensor_0/Depth_0/info/camera_info'; % Specify the topic name of the camera info data in your bag file


depthImageMsgs = readMessages(select(bag, 'Topic', depthImageTopic));
cameraInfoMsgs = select(bag, 'Topic', cameraInfoTopic); % Select messages with the specified topic for camera info data

% Extractintrinsic camera calibration parameters from camera info data
cameraInfo = readMessages(cameraInfoMsgs); % Read the camera info messages
fx = cameraInfo{1,1}.K(1); % Extract the focal length in x-direction
fy = cameraInfo{1,1}.K(5); % Extract the focal length in y-direction
cx = cameraInfo{1,1}.K(3); % Extract the x-coordinate of the principal point
cy = cameraInfo{1,1}.K(6); % Extract the y-coordinate of the principal point


% Extract depth values from depth image data
depth_data = readImage(depthImageMsgs{2});



%Clicker Code 
rgb_topic = '/device_0/sensor_0/Color_0/image/data';
rgb_msgs = readMessages(select(bag, 'Topic', rgb_topic));
colormap = jet(256);  
rgb_data = readImage(rgb_msgs{20});
imshow(rgb_data);

% Initialize a matrix to store the pixel locations
pixel_locations = [];

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
        else
            disp('Matrix is already empty.');
        end
        continue;  % Skip to the next iteration of the loop
    end
    
    % Add the pixel location to the matrix
    pixel_locations = [pixel_locations; round(x), round(y)];
    
    % Print the pixel location
    disp(['Pixel location: (' num2str(round(x)) ', ' num2str(round(y)) ')']);
end

% Display the matrix of pixel locations
disp('Matrix of pixel locations:');
disp(pixel_locations);



% Convert pixel coordinates to real-world xy coordinates
pixelX1 =pixel_locations(1,1) % Specify the x-coordinate of the pixel
pixelY1 =pixel_locations(1,2) % Specify the y-coordinate of the pixel

pixelX2 =pixel_locations(2,1) % Specify the x-coordinate of the pixel
pixelY2 =pixel_locations(2,2) % Specify the y-coordinate of the pixel


%Check Points to make sure they're not zero (or else the measuremnt will be very
%off because the distance calculation will be wonky)!


% Check if the value at (row_num, col_num) is 0
if depth_data(pixelY1, pixelX1) == 0
    disp("the value at this cell is 0");
    
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
    
    % Set new pixel values
    pixelY1=closest_row
    pixelX1=closest_col
    
    % Print the value and cell number of the closest nonzero element
    fprintf("Closest nonzero value: %d at cell (%d,%d)\n", closest_val, closest_row, closest_col);
end


% Check if the value at (row_num, col_num) is 0
if depth_data(pixelY2, pixelX2) == 0
    disp("the value at this cell is 0");
    
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
    fprintf("Closest nonzero value: %d at cell (%d,%d)\n", closest_val, closest_row, closest_col);
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
