clc; clear; close all;
addpath(fullfile(pwd, 'functions'));
addpath(fullfile(pwd, 'scripts'));
addpath(fullfile(pwd, 'utils'));  % Just in case deg2utm or helpers are in utils

disp("🚀 Starting HIMA Simulation Pipeline...");

%% ✅ Step 0: Read input from Flask
inputFile = fullfile(pwd, 'input.json');
if isfile(inputFile)
    inputData = jsondecode(fileread(inputFile));
    disp("📥 Input received from Flask:");
    disp(inputData);
else
    disp("⚠️ input.json not found. Running with default behavior.");
    inputData = struct();
end

%% Step 1: Create scan region
disp("📍 Creating scan region...");
run(fullfile('scripts', 'create_sample_region.m'));

%% Step 2: Download satellite map
disp("🗺️ Downloading satellite map...");
run(fullfile('scripts', 'download_map_tiles.m'));

%% Step 3: Place landmines randomly and assign 10 real images
disp("🧨 Placing 10 landmines and assigning images from /data/images...");
run(fullfile('scripts', 'place_landmines_test.m'));

%% Step 4: Simulate drone flight (detects all landmines visually)
disp("🛸 Simulating drone flight (drone detects all 10 landmines)...");
run(fullfile('scripts', 'simulate_flight_3D.m'));

%% Step 5: Run YOLO detection on the 10 assigned landmine images
disp("💣 Running YOLO detection on drone-collected thermal images...");
try
    py.runpy.run_path(fullfile(pwd, 'python', 'detect_landmine.py'));
    disp("✅ YOLO landmine detection complete. Check console for details.");
catch ME
    disp("❌ YOLO detection failed:");
    disp(ME.message);
end

%% ✅ Step 6: Gather actual outputs

% Get safe path coordinates from result map
safePathFile = fullfile(pwd, 'data', 'result.json');
if isfile(safePathFile)
    resultData = jsondecode(fileread(safePathFile));
    if isfield(resultData, 'safe_path')
        output.safePath = resultData.safe_path;
    else
        warning("⚠️ 'safe_path' not found in result.json");
        output.safePath = [];
    end
else
    warning("⚠️ result.json (safe path) not found");
    output.safePath = [];
end

% Get number of detected landmines from detection output
detectedMinesFile = fullfile(pwd, 'data', 'detected_landmines.json');
if isfile(detectedMinesFile)
    detectedData = jsondecode(fileread(detectedMinesFile));
    output.landmineCount = length(detectedData);
    output.detectedLandmines = detectedData;
else
    warning("⚠️ detected_landmines.json not found");
    output.landmineCount = 0;
    output.detectedLandmines = [];
end

%% ✅ Step 7: Save result for Flask
disp("💾 Saving result.json for Flask...");
try
    resultOutPath = fullfile(pwd, 'result.json');
    fid = fopen(resultOutPath, 'w');
    fwrite(fid, jsonencode(output), 'char');
    fclose(fid);
    disp("✅ result.json saved successfully.");
catch err
    disp("❌ Failed to write result.json:");
    disp(err.message);
end

disp("✅ HIMA full simulation completed.");
