% place_landmines_test.m - Final version with 5x2 landmine grid and image assignment

scriptFolder = fileparts(mfilename('fullpath'));
addpath(fullfile(scriptFolder, '..', 'functions'));

% Load region info
region = jsondecode(fileread(fullfile(scriptFolder, '..', 'data', 'scan_region.json')));
[topLeftX, topLeftY, zone] = deg2utm(region.topLeft(1), region.topLeft(2));
[bottomRightX, bottomRightY, ~] = deg2utm(region.bottomRight(1), region.bottomRight(2));

% Setup image paths
imgSourceFolder = fullfile(scriptFolder, '..', 'data', 'images');
imgTargetFolder = fullfile(scriptFolder, '..', 'data', 'frames_for_detection');
if ~exist(imgTargetFolder, 'dir')
    mkdir(imgTargetFolder);
end

% Get real thermal image files
imgFiles = dir(fullfile(imgSourceFolder, '*.jpg'));
if numel(imgFiles) < 10
    error("❌ Need at least 10 images in data/images/");
end
randImgs = imgFiles(randperm(numel(imgFiles), 10));  % Pick 10 random images

% Prepare 5x2 grid placement of landmines
xVals = linspace(topLeftX, bottomRightX, 5);
yVals = linspace(topLeftY, bottomRightY, 2);

mines = [];
idx = 1;
for i = 1:length(xVals)
    for j = 1:length(yVals)
        if idx > 10, break; end
        mine.utm_x = xVals(i);
        mine.utm_y = yVals(j);
        [mine.lat, mine.lon] = utm2deg(mine.utm_x, mine.utm_y, zone);
        mine.image = sprintf('frame_%04d.jpg', idx-1);

        % Copy the corresponding thermal image
        src = fullfile(imgSourceFolder, randImgs(idx).name);
        dst = fullfile(imgTargetFolder, mine.image);
        copyfile(src, dst);

        mines = [mines; mine];
        idx = idx + 1;
    end
end

% Save landmines to JSON
outPath = fullfile(scriptFolder, '..', 'data', 'mines.json');
fid = fopen(outPath, 'w');
fwrite(fid, jsonencode(mines, 'PrettyPrint', true));
fclose(fid);

fprintf("✅ 10 landmines placed in 5x2 grid and saved to: %s\n", outPath);
