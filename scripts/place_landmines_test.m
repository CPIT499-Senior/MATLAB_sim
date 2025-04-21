% place_landmines_test.m

scriptFolder = fileparts(mfilename('fullpath'));
addpath(fullfile(scriptFolder, '..', 'functions'));

region = jsondecode(fileread(fullfile(scriptFolder, '..', 'data', 'scan_region.json')));
[topLeftX, topLeftY, zone] = deg2utm(region.topLeft(1), region.topLeft(2));
[bottomRightX, bottomRightY, ~] = deg2utm(region.bottomRight(1), region.bottomRight(2));

imgSourceFolder = fullfile(scriptFolder, '..', 'data', 'images');
imgTargetFolder = fullfile(scriptFolder, '..', 'data', 'frames_for_detection');
if ~exist(imgTargetFolder, 'dir')
    mkdir(imgTargetFolder);
end

imgFiles = dir(fullfile(imgSourceFolder, '*.jpg'));
if numel(imgFiles) < 10
    error("❌ Need at least 10 images in data/images/.");
end
randImgs = imgFiles(randperm(numel(imgFiles), 10));

% Place mines along vertical line (middle of scan path)
xMid = (topLeftX + bottomRightX) / 2;
yVals = linspace(topLeftY, bottomRightY, 10);

mines = [];
for i = 1:10
    mine.utm_x = xMid;
    mine.utm_y = yVals(i);
    [mine.lat, mine.lon] = utm2deg(mine.utm_x, mine.utm_y, zone);
    mine.image = sprintf('frame_%04d.jpg', i-1);

    % Copy real image to frames_for_detection
    src = fullfile(imgSourceFolder, randImgs(i).name);
    dst = fullfile(imgTargetFolder, mine.image);
    copyfile(src, dst);

    mines = [mines; mine];
end

% Save mines
outPath = fullfile(scriptFolder, '..', 'data', 'mines.json');
fid = fopen(outPath, 'w');
fwrite(fid, jsonencode(mines, 'PrettyPrint', true));
fclose(fid);

fprintf("✅ 10 landmines placed along path and saved to: %s\n", outPath);
