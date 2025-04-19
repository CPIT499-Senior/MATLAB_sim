% place_landmines_test.m
clc;

% Get full path to the current script folder
scriptFolder = fileparts(mfilename('fullpath'));

% Add functions path (for deg2utm, etc.)
addpath(fullfile(scriptFolder, '..', 'functions'));

% Load scan region
region = jsondecode(fileread(fullfile(scriptFolder, '..', 'data', 'scan_region.json')));
[topLeftX, topLeftY, zone] = deg2utm(region.topLeft(1), region.topLeft(2));
[bottomRightX, bottomRightY, ~] = deg2utm(region.bottomRight(1), region.bottomRight(2));

% Load images (case-insensitive, all types)
imgFolder = fullfile(scriptFolder, '..', 'data', 'images');
imgFiles1 = dir(fullfile(imgFolder, '*.jpg'));
imgFiles2 = dir(fullfile(imgFolder, '*.JPG'));
imgFiles3 = dir(fullfile(imgFolder, '*.jpeg'));
imgFiles4 = dir(fullfile(imgFolder, '*.JPEG'));
imgFiles5 = dir(fullfile(imgFolder, '*.png'));
imgFiles6 = dir(fullfile(imgFolder, '*.PNG'));
imgFiles = [imgFiles1; imgFiles2; imgFiles3; imgFiles4; imgFiles5; imgFiles6];

if numel(imgFiles) < 3
    error("❌ Need at least 3 thermal images in data/images.");
end

% Place 3 landmines along the center X path
xMid = (topLeftX + bottomRightX) / 2;
yVals = linspace(topLeftY, bottomRightY, 3);
mines = [];

for i = 1:3
    mine.utm_x = xMid;
    mine.utm_y = yVals(i);
    [mine.lat, mine.lon] = utm2deg(mine.utm_x, mine.utm_y, zone);
    mine.image = imgFiles(i).name;
    mines = [mines; mine];
end

% Save to JSON file
outPath = fullfile(scriptFolder, '..', 'data', 'mines.json');
outDir = fileparts(outPath);
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

fid = fopen(outPath, 'w');
if fid == -1
    error("❌ Could not open %s for writing. Check folder permissions.", outPath);
end

fwrite(fid, jsonencode(mines, 'PrettyPrint', true));
fclose(fid);

fprintf("✅ Test mines saved to: %s\n", outPath);
