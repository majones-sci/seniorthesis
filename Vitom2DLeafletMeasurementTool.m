
% This Code is based on the demo developed by anonymous user ImageAnalyst. The demo was shared with
% the Matlab Community on January 9th, 2014. Link to Matlab discussion thread: 
% https://nl.mathworks.com/matlabcentral/answers/111945-how-do-i-measure-a-distance-in-real-world-with-a-picture-in-matlab
% ImageAnalyst (2014) spatial_calibration_demo.m [Matlab]. https://nl.mathworks.com/matlabcentral/answers/111945-how-do-i-measure-a-distance-in-real-world-with-a-picture-in-matlab
% Additional sources: OpenAI. (2023). ChatGPT (Version 2.5) [Large language model]. https://chat.openai.com/chat

function Vitom2DLeafletMeasurementTool()
% This demo allows you to spatially calibrate your image and then make distance or area measurements.

global originalImage;
% Check that user has the Image Processing Toolbox installed.
clc;    % Clear the command window.
close all;  % Close all figures (except those of imtool.)
workspace;  % Make sure the workspace panel is showing.
format long g;
format compact;
fontSize = 20;

hasIPT = license('test', 'image_toolbox');
if ~hasIPT
	% User does not have the toolbox installed.
	message = sprintf('Sorry, but you do not seem to have the Image Processing Toolbox.\nDo you want to try to continue anyway?');
	reply = questdlg(message, 'Toolbox missing', 'Yes', 'No', 'Yes');
	if strcmpi(reply, 'No')
		% User said No, so exit.
		return;
	end
end

% Read in a standard MATLAB gray scale demo image.

button = menu('Select your image', 'Select from computer', 'Exit');
switch button
	case 1
		% Get the name of the file that the user wants to use.
		defaultFileName = fullfile(cd, '*.*');
		[baseFileName, folder] = uigetfile(defaultFileName, 'Select an image file');
		if baseFileName == 0
			% User clicked the Cancel button.
			return;
		end
	case 2
		return;
end

% Get the full filename, with path prepended.
fullFileName = fullfile(folder, baseFileName);
% Check if file exists.
if ~exist(fullFileName, 'file')
	% File doesn't exist -- didn't find it there.  Check the search path for it.
	fullFileName = baseFileName; % No path this time.
	if ~exist(fullFileName, 'file')
		% Still didn't find it.  Alert user.
		errorMessage = sprintf('Error: %s does not exist in the search path folders.', fullFileName);
		uiwait(warndlg(errorMessage));
		return;
	end
end
% Read in the chosen image.
originalImage = imread(fullFileName);
% Get the dimensions of the image.
% numberOfColorBands should be = 1.
[rows, columns, numberOfColorBands] = size(originalImage);
% Display the original gray scale image.
figureHandle = figure;
subplot(1,1, 1);
imshow(originalImage, []);
axis on;
title('Original Grayscale Image', 'FontSize', fontSize);
% Enlarge figure to full screen.
set(gcf, 'units','normalized','outerposition',[0 0 1 1]);
% Give a name to the title bar.
set(gcf,'name','Demo by ImageAnalyst','numbertitle','off')

message = sprintf('First you will be doing spatial calibration.');
reply = questdlg(message, 'Calibrate spatially', 'OK', 'Cancel', 'OK');
if strcmpi(reply, 'Cancel')
	% User said Cancel, so exit.
	return;
end
button = 1; % Allow it to enter loop.

while button ~= 4
	if button > 1
		% Let them choose the task, once they have calibrated.
		button = menu('Select a task', 'Calibrate', 'Measure Distance', 'Remeasure Image','Exit');
	end
	switch button
		case 1
			success = Calibrate();
			% Keep trying if they didn't click properly.
			while ~success
				success = Calibrate();
			end
			% If they get to here, they clicked properly
			% Change to something else so it will ask them
			% for the task on the next time through the loop.
			button = 99;
		case 2
			DrawLine();
        case 3
            RemeasureImage();
		otherwise
			close(figureHandle);
			break;
	end
end

end

%=====================================================================
function success = Calibrate()
global lastDrawnHandle;
global calibration;
try
	success = false;
	instructions = sprintf('Left click to anchor first endpoint of line.\nRight-click or double-left-click to anchor second endpoint of line.\n\nAfter that I will ask for the real-world distance of the line.');
	title(instructions);
	msgboxw(instructions);

	[cx, cy, rgbValues, xi,yi] = improfile(1000);
	% rgbValues is 1000x1x3.  Call Squeeze to get rid of the singleton dimension and make it 1000x3.
	rgbValues = squeeze(rgbValues);
	distanceInPixels = sqrt( (xi(2)-xi(1)).^2 + (yi(2)-yi(1)).^2);
	if length(xi) < 2
		return;
	end
	% Plot the line.
	hold on;
	lastDrawnHandle = plot(xi, yi, 'y-', 'LineWidth', 2);

	% Ask the user for the real-world distance.
	userPrompt = {'Enter real world units (e.g. microns):','Enter distance in those units:'};
	dialogTitle = 'Specify calibration information';
	numberOfLines = 1;
	def = {'mm', '10'};
	answer = inputdlg(userPrompt, dialogTitle, numberOfLines, def);
	if isempty(answer)
		return;
	end
	calibration.units = answer{1};
	calibration.distanceInPixels = distanceInPixels;
	calibration.distanceInUnits = str2double(answer{2});
	calibration.distancePerPixel = calibration.distanceInUnits / distanceInPixels;
	success = true;
	
	message = sprintf('The distance you drew is %.2f pixels = %f %s.\nThe number of %s per pixel is %f.\nThe number of pixels per %s is %f',...
		distanceInPixels, calibration.distanceInUnits, calibration.units, ...
		calibration.units, calibration.distancePerPixel, ...
		calibration.units, 1/calibration.distancePerPixel);
	uiwait(msgbox(message));
catch ME
	errorMessage = sprintf('Error in function Calibrate().\nDid you first left click and then right click?\n\nError Message:\n%s', ME.message);
	fprintf(1, '%s\n', errorMessage);
	WarnUser(errorMessage);
end

return;	% from Calibrate()
end

%=====================================================================
% --- Executes on button press in DrawLine.
function success = DrawLine()
try
    global lastDrawnHandle;
    global calibration;
    fontSize = 14;

    instructions = sprintf('Click on multiple points. Right-click, double-left-click, or press ''q'' to finish.\nPress ''d'' to delete the last point.');
    title(sprintf('Click on points'));
    msgboxw(instructions);

    % Initialize arrays to store clicked points
    xPoints = [];
    yPoints = [];

    while true
        [x, y, button] = ginput(1);

        % Check for right-click, double-left-click, or 'q' key to finish
        if button == 3 || (button == 1 && numel(xPoints) >= 2 && xPoints(end) == x && yPoints(end) == y) || (button == 113)  % ASCII code for 'q'
            break;
        end

        % Check for 'd' key to delete the last point
        if button == 100  % ASCII code for 'd'
            if ~isempty(xPoints)
                xPoints(end) = [];
                yPoints(end) = [];
                delete(lastDrawnHandle);  % Remove the last drawn point
                %lastDrawnHandle = plot(xPoints, yPoints, 'yo', 'MarkerSize', 8);
                lastDrawnHandle = plot(x, y, 'yo', 'MarkerSize', 8, 'LineWidth', 2);
            end
        else
            xPoints = [xPoints, x];
            yPoints = [yPoints, y];

            % Plot the point
            hold on;
            %lastDrawnHandle = plot(x, y, 'yo', 'MarkerSize', 8);
            lastDrawnHandle = plot(x, y, 'yo', 'MarkerSize', 8, 'LineWidth', 2);
        end
    end

    % Calculate distances between adjacent points
    distances = sqrt(diff(xPoints).^2 + diff(yPoints).^2);
    totalDistance = sum(distances);

    distances_real = distances * calibration.distancePerPixel;
    totalDistance_real = totalDistance * calibration.distancePerPixel;

    % Display distances
    txtInfo = sprintf('Distances between points:\n');
    for i = 1:length(distances)
        txtInfo = [txtInfo, sprintf('Segment %d: %.1f %s\n', i, distances_real(i), calibration.units)];
    end
    txtInfo = [txtInfo, sprintf('Total Distance: %.1f %s', totalDistance_real, calibration.units)];

    msgboxw(txtInfo);

catch ME
    errorMessage = sprintf('Error in function DrawLine().\n\nError Message:\n%s', ME.message);
    fprintf(1, '%s\n', errorMessage);
    WarnUser(errorMessage);
end
end  % from DrawLine()



%=====================================================================

% RemeasureImage function -- allows user to take another measurement
% without having to reselect the image.
function RemeasureImage()
    global originalImage;
    global lastDrawnHandle;
    global calibration;

    % Clear previous markings
    if ~isempty(lastDrawnHandle)
        delete(lastDrawnHandle);
    end

    % Hold the current axis properties
    hold on;

    % Display the original gray scale image.
    imshow(originalImage, []);
    axis on;
    title('Original Grayscale Image', 'FontSize', 20);

    % Reset calibration data
    calibration = struct('units', '', 'distanceInPixels', 0, 'distanceInUnits', 0, 'distancePerPixel', 0);

    % Release the hold on the axis
    hold off;

    % Inform the user that they can proceed with calibration
    message = sprintf('You can now proceed with re-measuring your image. Select the "Calibrate" button to re-calibrate your image, then click "Draw Line".');
    msgboxw(message);
end

%=====================================================================
function msgboxw(message)
	uiwait(msgbox(message));
end
%=====================================================================
function WarnUser(message)
	uiwait(msgbox(message));
end
