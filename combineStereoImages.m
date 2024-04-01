%This function takes the depth data from a stereoimage pair and combines
%fills depth data holes in the left image with data rom the right image.

function combinedImage = combineStereoImages(leftImage, rightImage, disparityMatrix)
    % Step 1: Save the data of the left image
    combinedImage = leftImage;
    
    % Step 2: Find the appropriate shift over of the right image
    [rows, cols] = size(leftImage);
    shiftedRightImage = zeros(rows, cols);
    
    for r = 1:rows
        for c = 1:cols
            % Calculate the disparity value for the current pixel
            disparity = disparityMatrix(r, c);
            
            % Calculate the corresponding column in the right image
            shifted_c = round(c - disparity); % Round to the nearest integer
            
            % Check if the shifted column is within the valid range
            if shifted_c >= 1 && shifted_c <= cols
                shiftedRightImage(r, c) = rightImage(r, shifted_c);
            else
                % Set to zero if the shifted column is outside the valid range
                shiftedRightImage(r, c) = 0;
            end
        end
    end
    
    % Step 3: Fill in any holes present in the left image with the right data from the right image
    % Use the shifted right image to fill the holes in the left image
    holes = (leftImage == 0);
    combinedImage(holes) = shiftedRightImage(holes);
end
