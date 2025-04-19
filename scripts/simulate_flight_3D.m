clc; close all;

addpath(fullfile(pwd, 'functions'));

% Load scan region and landmines
dataPath = 'data';
region = jsondecode(fileread(fullfile(dataPath, 'scan_region.json')));
mines = jsondecode(fileread(fullfile(dataPath, 'mines.json')));
thermalFolder = fullfile(dataPath, 'images'); 
detectedPath = fullfile(dataPath, 'detected_landmines.json');

% Load drone model
droneMesh = stlread(fullfile('assets', 'drone.stl'));

% Load map image
mapImage = im2double(flipud(imread(fullfile(dataPath, 'map_image.png'))));
[imgH, imgW, ~] = size(mapImage);

% UTM conversion
[topLeftX, topLeftY, utmZone] = deg2utm(region.topLeft(1), region.topLeft(2));
[bottomRightX, bottomRightY, ~] = deg2utm(region.bottomRight(1), region.bottomRight(2));

[xGrid, yGrid] = meshgrid(linspace(topLeftX, bottomRightX, imgW), linspace(topLeftY, bottomRightY, imgH));
zGrid = zeros(size(xGrid));

% Create flight path
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

% Initialize plot
figure('Name','Realistic Drone Simulation');
shg;
hold on; axis equal;
xlabel('X'); ylabel('Y'); zlabel('Altitude');
title('HIMA Realistic 3D Simulation');
surf(xGrid, yGrid, zGrid, mapImage, 'FaceColor','texturemap','EdgeColor','none');
view(45, 30);

% Drone params
alt = region.altitude;
coneAngle = 25;
droneScale = (bottomRightX - topLeftX) / 6000;
detected = {};
trailX = []; trailY = []; trailZ = [];

videoOut = VideoWriter('outputs/hima_simulation.avi');
videoOut.FrameRate = 30;
open(videoOut);

disp("🛫 Starting drone flight loop...");

for i = 1:size(path,1)
    x = path(i,1); y = path(i,2); z = alt;

    % Cone detection range
    h = alt; r = h * tand(coneAngle);
    [cx, cy, cz] = cylinder([0, r], 20);
    cz = -cz * h;
    surf(cx + x, cy + y, cz + z, 'FaceAlpha', 0.2, 'FaceColor','r','EdgeColor','none');

    % Check for detection
    for j = 1:length(mines)
        dx = abs(x - mines(j).utm_x);
        dy = abs(y - mines(j).utm_y);
        if dx <= r && dy <= r
            if ~any(cellfun(@(d) abs(d.x - mines(j).utm_x) < 1e-3 && abs(d.y - mines(j).utm_y) < 1e-3, detected))
                detected{end+1} = struct('x', mines(j).utm_x, 'y', mines(j).utm_y);

                imgFile = fullfile(thermalFolder, mines(j).image);
                if isfile(imgFile)
                    thermalIcon = imresize(imread(imgFile), [30 30]);
                else
                    thermalIcon = ones(30, 30, 3);
                end

                imgX = [mines(j).utm_x - 1, mines(j).utm_x + 1];
                imgY = [mines(j).utm_y - 1, mines(j).utm_y + 1];
                [tx, ty] = meshgrid(imgX, imgY);
                surf(tx, ty, zeros(2), 'CData', thermalIcon, 'FaceColor','texturemap', 'EdgeColor','none', 'FaceAlpha', 0.9);
            end
        end
    end

    % Draw drone
    scaledVerts = droneMesh.Points * droneScale + [x y z];
    dronePatch = patch('Faces', droneMesh.ConnectivityList, 'Vertices', scaledVerts, 'FaceColor', [0 0.4 1], 'EdgeColor', 'none');

    % Trail
    trailX(end+1) = x; trailY(end+1) = y; trailZ(end+1) = z;
    plot3(trailX, trailY, trailZ, 'b-', 'LineWidth', 1.2);

    campos([x+80, y+80, z+160]);
    camtarget([x, y, z]);
    drawnow;

    frame = getframe(gcf);
    if ~isempty(frame.cdata)
        writeVideo(videoOut, frame);
    end

    delete(dronePatch);
end

close(videoOut);

% Save detection results
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


close(videoOut);
disp("✅ HIMA realistic simulation complete.");