clc; clear; close all;
addpath(fullfile(pwd, 'functions'));
addpath(fullfile(pwd, 'scripts'));

disp("Starting HIMA Simulation Pipeline...");

%% Step 0: Read input from Flask
inputFile = fullfile(pwd, 'input.json');
if ~isfile(inputFile)
    errordlg("input.json not found. Please provide input from the Flutter or Flask interface.", "Missing File");
    return;
end

try
    inputData = jsondecode(fileread(inputFile));
    disp("Input received from Flask:");
    disp(inputData);
catch
    errordlg("Failed to read or decode input.json. Please check the file format.", "Invalid Input");
    return;
end

%% Check if region file exists before creating region
regionPath = fullfile(pwd, 'data', 'scan_region.json');
if ~isfile(regionPath)
    errordlg("scan_region.json not found. Please send region from Flutter first.", "Missing File");
    return;
end

%% Check if images folder exists
imageFolder = fullfile(pwd, 'data', 'images');
if ~isfolder(imageFolder)
    errordlg("data/images folder is missing. Please place thermal landmine images there.", "Missing Folder");
    return;
end

%% Step 1: Create scan region
disp("Creating scan region...");
try
    run(fullfile('scripts', 'create_sample_region.m'));
catch ME
    errordlg("Failed to create scan region: " + ME.message, "Script Error");
    return;
end

%% Step 2: Download satellite map
disp("Downloading satellite map...");
try
    run(fullfile('scripts', 'download_map_tiles.m'));
catch ME
    errordlg("Failed to download satellite map: " + ME.message, "Script Error");
    return;
end

%% Step 3: Place landmines and assign images
disp("Placing 10 landmines and assigning images from /data/images...");
try
    run(fullfile('scripts', 'place_landmines.m'));
catch ME
    errordlg("Failed to place landmines: " + ME.message, "Script Error");
    return;
end

%% Step 4: Simulate drone flight
disp("Simulating drone flight...");
try
    run(fullfile('scripts', 'simulate_flight_3D.m'));
catch ME
    errordlg("Drone simulation failed: " + ME.message, "Simulation Error");
    return;
end

%% Step 5: Run YOLO detection
disp("Running YOLO detection on drone-collected thermal images...");
try
    py.runpy.run_path(fullfile(pwd, 'python', 'detect_landmine.py'));
    disp("YOLO landmine detection complete. Check console for details.");
catch ME
    errordlg("YOLO detection failed: " + ME.message, "Detection Error");
    return;
end

%% Step 6: Gather actual outputs

% Safe path
safePathFile = fullfile(pwd, 'data', 'result.json');
if isfile(safePathFile)
    try
        resultData = jsondecode(fileread(safePathFile));
        if isfield(resultData, 'safe_path')
            output.safePath = resultData.safe_path;
        else
            errordlg("'safe_path' field not found in result.json", "Missing Field");
            return;
        end
    catch
        errordlg("Failed to read or parse result.json", "File Error");
        return;
    end
else
    errordlg("result.json (safe path) not found", "Missing File");
    return;
end

% Detected landmines
detectedMinesFile = fullfile(pwd, 'data', 'detected_landmines.json');
if isfile(detectedMinesFile)
    try
        detectedData = jsondecode(fileread(detectedMinesFile));
        output.landmineCount = length(detectedData);
        output.detectedLandmines = detectedData;
    catch
        errordlg("Failed to read or parse detected_landmines.json", "File Error");
        return;
    end
else
    errordlg("detected_landmines.json not found", "Missing File");
    return;
end

%% Step 7: Save result for Flask
disp("Saving result.json for Flask...");
try
    resultOutPath = fullfile(pwd, 'result.json');
    fid = fopen(resultOutPath, 'w');
    if fid == -1
        errordlg("Unable to write result.json", "Write Error");
        return;
    end
    fwrite(fid, jsonencode(output), 'char');
    fclose(fid);
    disp("result.json saved successfully.");
catch err
    errordlg("Failed to write result.json: " + err.message, "Write Error");
    return;
end

disp("HIMA full simulation completed.");
