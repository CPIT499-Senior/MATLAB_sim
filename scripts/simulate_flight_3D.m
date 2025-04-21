% simulate_flight_3D.m

rootPath = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(rootPath, 'functions'));

dataPath = fullfile(rootPath, 'data');
assetPath = fullfile(rootPath, 'assets');
dronePath = fullfile(assetPath, 'drone.stl');

region = jsondecode(fileread(fullfile(dataPath, 'scan_region.json')));
mines = jsondecode(fileread(fullfile(dataPath, 'mines.json')));
detectedPath = fullfile(dataPath, 'detected_landmines.json');

% Load map image
rawMap = flipud(imread(fullfile(dataPath, 'map_image.png')));
mapImage = im2double(rawMap);
[imgH, imgW, ~] = size(mapImage);

[topLeftX, topLeftY, utmZone] = deg2utm(region.topLeft(1), region.topLeft(2));
[bottomRightX, bottomRightY, ~] = deg2utm(region.bottomRight(1), region.bottomRight(2));
[xGrid, yGrid] = meshgrid(linspace(topLeftX, bottomRightX, imgW), linspace(topLeftY, bottomRightY, imgH));
zGrid = zeros(size(xGrid));

xRange = topLeftX:region.step:bottomRightX;
path = [];
dir = 1;
for x = xRange
    if dir == 1
        path = [path; x, topLeftY; x, bottomRightY];
    else
        path = [path; x, bottomRightY; x, topLeftY];
    end
    dir = -dir;
end

figure('Name','HIMA Drone Simulation'); hold on; axis equal;
xlabel('X'); ylabel('Y'); zlabel('Altitude');
title('HIMA 3D Simulation');

surf(xGrid, yGrid, zGrid, 'CData', mapImage, 'FaceColor', 'texturemap', 'EdgeColor', 'none');
view(45, 30);

alt = region.altitude;
coneAngle = 25;  % You can increase this if needed
droneScale = (bottomRightX - topLeftX) / 6000;
detected = {};
trailX = []; trailY = []; trailZ = [];

droneMesh = stlread(dronePath);

for i = 1:size(path,1)
    x = path(i,1); y = path(i,2); z = alt;

    % Detection cone
    h = alt; r = h * tand(coneAngle);
    [cx, cy, cz] = cylinder([0, r], 20);
    cz = -cz * h;
    surf(cx + x, cy + y, cz + z, 'FaceAlpha', 0.2, 'FaceColor','r','EdgeColor','none');

    % Check if mines are within detection radius
    for j = 1:length(mines)
        dx = abs(x - mines(j).utm_x);
        dy = abs(y - mines(j).utm_y);
        if dx <= r && dy <= r
            already = any(cellfun(@(d) abs(d.x - mines(j).utm_x) < 1e-3 && abs(d.y - mines(j).utm_y) < 1e-3, detected));
            if ~already
                detected{end+1} = struct('x', mines(j).utm_x, 'y', mines(j).utm_y);
            end
        end
    end

    % Show drone
    scaledVerts = droneMesh.Points * droneScale + [x y z];
    dronePatch = patch('Faces', droneMesh.ConnectivityList, ...
                       'Vertices', scaledVerts, ...
                       'FaceColor', [1 0.4 0], ...
                       'EdgeColor', 'none');

    % Path trail
    trailX(end+1) = x; trailY(end+1) = y; trailZ(end+1) = z;
    plot3(trailX, trailY, trailZ, 'b-', 'LineWidth', 1.2);

    campos([x+80, y+80, z+160]);
    camtarget([x, y, z]);
    drawnow;

    delete(dronePatch);
end

% Save detections (for visual inspection)
outputList = [];
for k = 1:length(detected)
    [lat, lon] = utm2deg(detected{k}.x, detected{k}.y, utmZone);
    outputList(end+1).lat = lat;
    outputList(end).lon = lon;
end

fid = fopen(detectedPath, 'w');
fwrite(fid, jsonencode(outputList));
fclose(fid);

fprintf("✅ Saved %d detected landmines to %s\n", length(outputList), detectedPath);
disp("✅ HIMA realistic simulation complete.");
