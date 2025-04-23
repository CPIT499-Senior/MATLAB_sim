% place_landmines.m - Randomly place 10 landmines on a 5x2 grid and assign thermal images

scriptFolder = fileparts(mfilename('fullpath'));
addpath(fullfile(scriptFolder, '..', 'functions'));

% Load scan region and convert to UTM
try
    region = jsondecode(fileread(fullfile(scriptFolder, '..', 'data', 'scan_region.json')));
catch
    errordlg("Failed to read or decode scan_region.json", "Read Error");
    return;
end

[topLeftX, topLeftY, zone] = deg2utm(region.topLeft(1), region.topLeft(2));
[bottomRightX, bottomRightY, ~] = deg2utm(region.bottomRight(1), region.bottomRight(2));

% Prepare image folders
imgSourceFolder = fullfile(scriptFolder, '..', 'data', 'images');
imgTargetFolder = fullfile(scriptFolder, '..', 'data', 'frames_for_detection');
if ~exist(imgTargetFolder, 'dir')
    mkdir(imgTargetFolder);
end

% Check for at least 10 images
imgFiles = dir(fullfile(imgSourceFolder, '*.jpg'));
if numel(imgFiles) < 10
    errordlg("Need at least 10 images in data/images/", "Insufficient Images");
    return;
end

% Pick 10 random images
randImgs = imgFiles(randperm(numel(imgFiles), 10));

% Create 5x2 landmine placement grid
xVals = linspace(topLeftX, bottomRightX, 5);
yVals = linspace(topLeftY, bottomRightY, 2);
mines = [];
idx = 1;

% Assign each image to a mine and save data
for i = 1:length(xVals)
    for j = 1:length(yVals)
        if idx > 10, break; end
        mine.utm_x = xVals(i);
        mine.utm_y = yVals(j);
        [mine.lat, mine.lon] = utm2deg(mine.utm_x, mine.utm_y, zone);
        mine.image = sprintf('frame_%04d.jpg', idx-1);
        src = fullfile(imgSourceFolder, randImgs(idx).name);
        dst = fullfile(imgTargetFolder, mine.image);
        copyfile(src, dst);
        mines = [mines; mine];
        idx = idx + 1;
    end
end

% Save to JSON
outPath = fullfile(scriptFolder, '..', 'data', 'mines.json');
fid = fopen(outPath, 'w');
if fid == -1
    errordlg("Failed to open mines.json for writing", "Write Error");
    return;
end
fwrite(fid, jsonencode(mines, 'PrettyPrint', true));
fclose(fid);

fprintf("10 landmines placed and saved to: %s\n", outPath);
