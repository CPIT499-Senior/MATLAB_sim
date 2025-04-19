% download_map_tiles.m - Downloads a satellite image from MapTiler

clc;

% Load region
scanPath = fullfile('..', 'data', 'scan_region.json');
if ~isfile(scanPath)
    error("❌ Region file not found.");
end
region = jsondecode(fileread(scanPath));
centerLat = mean([region.topLeft(1), region.bottomRight(1)]);
centerLon = mean([region.topLeft(2), region.bottomRight(2)]);

% MapTiler API
apiKey = 'ab2lsvlzfavhhf4Ie90A';  % ✅ Use your own key
zoom = 18; tileSize = 640; mapStyle = 'satellite';

url = sprintf( ...
    'https://api.maptiler.com/maps/%s/static/%f,%f,%d/%dx%d.png?key=%s', ...
    mapStyle, centerLon, centerLat, zoom, tileSize, tileSize, apiKey);

% Save image
destPath = fullfile('..', 'data', 'map_image.png');
if isfile(destPath), delete(destPath); end

try
    websave(destPath, url);
    fprintf("✅ Satellite map saved: %s\n", destPath);
catch ME
    fprintf("❌ Failed to download satellite map: %s\n", ME.message);
end
