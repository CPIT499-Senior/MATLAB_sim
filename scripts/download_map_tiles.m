% download_map_tiles.m - Downloads satellite tiles from MapTiler and stitches them

% Load scan region configuration
scanPath = fullfile('..', 'data', 'scan_region.json');
if ~isfile(scanPath)
    errordlg("scan_region.json not found.", "Missing File");
    return;
end

% Decode region file
try
    region = jsondecode(fileread(scanPath));
catch
    errordlg("Failed to read or parse scan_region.json", "Read Error");
    return;
end

% MapTiler API and tile settings
apiKey = 'ab2lsvlzfavhhf4Ie90A';
zoom = 18;
tileSize = 640;
mapStyle = 'satellite';

% Convert top-left and bottom-right coordinates to tile indices
[~, ~, tileX1, tileY1] = latlon_to_tile(region.topLeft(1), region.topLeft(2), zoom);
[~, ~, tileX2, tileY2] = latlon_to_tile(region.bottomRight(1), region.bottomRight(2), zoom);

% Loop through tiles to download and stitch them
xTiles = tileX1:tileX2;
yTiles = tileY1:tileY2;
stitchedImg = [];
for y = yTiles
    rowImg = [];
    for x = xTiles
        tileCenter = tile_to_latlon(x + 0.5, y + 0.5, zoom);
        url = sprintf('https://api.maptiler.com/maps/%s/static/%f,%f,%d/%dx%d.png?key=%s', ...
            mapStyle, tileCenter(2), tileCenter(1), zoom, tileSize, tileSize, apiKey);
        try
            tileImg = webread(url);
        catch
            warning("Failed to download tile (%d, %d): %s", x, y, url);
            tileImg = ones(tileSize, tileSize, 3);  % fallback tile
        end
        rowImg = [rowImg, tileImg];
    end
    stitchedImg = [stitchedImg; rowImg];
end

% Save final stitched image to disk
destPath = fullfile('..', 'data', 'map_image.png');
try
    imwrite(stitchedImg, destPath);
catch
    errordlg("Failed to write map_image.png", "Write Error");
    return;
end
fprintf("Stitched satellite map saved: %s\n", destPath);

% Convert lat/lon to tile coordinates and pixel positions
function [px, py, tileX, tileY] = latlon_to_tile(lat, lon, zoom)
    n = 2^zoom;
    lat_rad = deg2rad(lat);
    px = (lon + 180) / 360 * n * 256;
    py = (1 - log(tan(lat_rad) + sec(lat_rad)) / pi) / 2 * n * 256;
    tileX = floor(px / 256);
    tileY = floor(py / 256);
end

% Convert tile indices back to lat/lon for map centering
function latlon = tile_to_latlon(x, y, zoom)
    n = 2^zoom;
    lon = x / n * 360 - 180;
    lat_rad = atan(sinh(pi * (1 - 2 * y / n)));
    lat = rad2deg(lat_rad);
    latlon = [lat, lon];
end
