% place_landmines.m
clc;

% === Load region and convert corners ===
region = jsondecode(fileread(fullfile('data', 'scan_region.json')));
[topLeftX, topLeftY, utmZone] = deg2utm(region.topLeft(1), region.topLeft(2));
[bottomRightX, bottomRightY, ~] = deg2utm(region.bottomRight(1), region.bottomRight(2));

% === Load thermal images ===
scriptFolder = fileparts(mfilename('fullpath'));
imgFolder = fullfile(scriptFolder, '..', 'data', 'images');
imgFiles = [ ...
    dir(fullfile(imgFolder, '*.jpg')); ...
    dir(fullfile(imgFolder, '*.JPG')); ...
    dir(fullfile(imgFolder, '*.jpeg')); ...
    dir(fullfile(imgFolder, '*.JPEG')); ...
    dir(fullfile(imgFolder, '*.png')); ...
    dir(fullfile(imgFolder, '*.PNG')) ...
];

if isempty(imgFiles)
    error("❌ No thermal images found in data/images");
end

% === Place random landmines inside region ===
N = 10;
mines = [];
fprintf("📍 Placing %d landmines:\n", N);
for i = 1:N
    mine.utm_x = rand() * (bottomRightX - topLeftX) + topLeftX;
    mine.utm_y = rand() * (bottomRightY - topLeftY) + topLeftY;
    [mine.lat, mine.lon] = utm2deg(mine.utm_x, mine.utm_y, utmZone);
    mine.image = imgFiles(randi(length(imgFiles))).name;
    mines = [mines; mine];
    fprintf("  🔴 Landmine %d at UTM [%.2f, %.2f]\n", i, mine.utm_x, mine.utm_y);
end

% === Save to JSON ===
outPath = fullfile(scriptFolder, '..', 'data', 'mines.json');
fid = fopen(outPath, 'w');
if fid == -1
    error("❌ Cannot open %s for writing.", outPath);
end
fwrite(fid, jsonencode(mines, 'PrettyPrint', true));
fclose(fid);

fprintf("✅ Saved landmines to %s\n", outPath);
