clc; clear; close all;
addpath(fullfile(pwd, 'functions'));
disp("🚀 Starting HIMA Simulation Pipeline...");

%% Step 1: Create Scan Region
disp("📍 Creating scan region...");
run(fullfile('scripts', 'create_sample_region.m'));

%% Step 1.5: Place Landmines
disp("🧨 Placing random landmines...");
run(fullfile('scripts', 'place_landmines.m'));

%% Step 2: Landmine Detection (YOLOv8)
disp("💣 Detecting landmines...");
try
    script_path = fullfile(pwd, 'python', 'detect_landmine.py');
    py.runpy.run_path(script_path);
    disp("✅ Landmine detection complete.");
catch ME
    disp("❌ Python detection failed:");
    disp(ME.message);
end

%% Step 3: Download Satellite Map
disp("🗺️ Downloading satellite map...");
run(fullfile('scripts', 'download_map_tiles.m'));

%% Step 4: 3D Drone Simulation
disp("🛸 Simulating drone flight...");
addpath(fullfile(pwd, 'scripts'));
simulate_flight_3D;

disp("✅ HIMA simulation finished.");