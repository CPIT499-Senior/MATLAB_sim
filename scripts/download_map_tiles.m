% download_map_tiles.m - Downloads satellite tiles from MapTiler and stitches them

% Load scan region
scanPath = fullfile('..', 'data', 'scan_region.json');
if ~isfile(scanPath)
    error("❌ Region file not found.");
end
region = jsondecode(fileread(scanPath));

% MapTiler setup
apiKey = 'ab2lsvlzfavhhf4Ie90A';  % ✅ Replace with your own key
zoom = 18;
tileSize = 640;
mapStyle = 'satellite';

% Convert region corners to pixel coordinates (approx)
[centerX, centerY, tileX1, tileY1] = latlon_to_tile(region.topLeft(1), region.topLeft(2), zoom);
[~, ~, tileX2, tileY2] = latlon_to_tile(region.bottomRight(1), region.bottomRight(2), zoom);

xTiles = tileX1:tileX2;
yTiles = tileY1:tileY2;

stitchedImg = [];
for y = yTiles
    rowImg = [];
    for x = xTiles
        tileCenter = tile_to_latlon(x + 0.5, y + 0.5, zoom);  % Center of tile
        url = sprintf( ...
            'https://api.maptiler.com/maps/%s/static/%f,%f,%d/%dx%d.png?key=%s', ...
            mapStyle, tileCenter(2), tileCenter(1), zoom, tileSize, tileSize, apiKey);

        try
            tileImg = webread(url);
        catch
            warning("⚠️ Failed to download tile (%d, %d): %s", x, y, url);
            tileImg = ones(tileSize, tileSize, 3);
        end


        rowImg = [rowImg, tileImg];
    end
    stitchedImg = [stitchedImg; rowImg];
end

% Save final stitched image
destPath = fullfile('..', 'data', 'map_image.png');
imwrite(stitchedImg, destPath);
fprintf("✅ Stitched satellite map saved: %s\n", destPath);


% --- Helper functions ---
function [px, py, tileX, tileY] = latlon_to_tile(lat, lon, zoom)
    n = 2^zoom;
    lat_rad = deg2rad(lat);
    px = (lon + 180) / 360 * n * 256;
    py = (1 - log(tan(lat_rad) + sec(lat_rad)) / pi) / 2 * n * 256;
    tileX = floor(px / 256);
    tileY = floor(py / 256);
end

function latlon = tile_to_latlon(x, y, zoom)
    n = 2^zoom;
    lon = x / n * 360 - 180;
    lat_rad = atan(sinh(pi * (1 - 2 * y / n)));
    lat = rad2deg(lat_rad);
    latlon = [lat, lon];
end
