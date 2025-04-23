% create_sample_region.m - Define region bounds for scan (from Flutter app)

% Construct the path to the region JSON file
regionPath = fullfile('..', 'data', 'scan_region.json');

% Check if the file exists
if ~isfile(regionPath)
    errordlg("Region coordinates not received from Flutter. Terminating run.", "Missing File");
    return;
end

% Load and decode the JSON content
try
    region = jsondecode(fileread(regionPath));
catch
    errordlg("Failed to read or decode scan_region.json", "Read Error");
    return;
end

% Validate required fields in the region structure
requiredFields = {'topLeft', 'bottomRight', 'altitude', 'step'};
for i = 1:numel(requiredFields)
    if ~isfield(region, requiredFields{i})
        errordlg(['scan_region.json is missing required field: ', requiredFields{i}], "Invalid Format");
        return;
    end
end

% Re-save the validated region to ensure formatting consistency
jsonText = jsonencode(region);
fid = fopen(regionPath, 'w');
if fid == -1
    errordlg("Unable to write region data.", "Write Error");
    return;
end
fwrite(fid, jsonText, 'char');
fclose(fid);

disp("Region received from Flutter and saved to scan_region.json");
