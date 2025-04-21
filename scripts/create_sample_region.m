% create_sample_region.m - Define region bounds for scan (from app or default)

% Region corners (can be overridden by Flutter app later)
region.topLeft = [21.4858, 39.1920];       % [Latitude, Longitude]
region.bottomRight = [21.4825, 39.1982];   % [Latitude, Longitude]
region.altitude = 10;                      % Drone scan altitude in meters
region.step = 5;                           % Meters between lawnmower passes

% Save to JSON
regionPath = fullfile('..', 'data', 'scan_region.json');
jsonText = jsonencode(region);

fid = fopen(regionPath, 'w');
if fid == -1
    error("❌ Unable to write region data.");
end
fwrite(fid, jsonText, 'char'); fclose(fid);

disp("✅ Region saved to scan_region.json");
