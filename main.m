clc; clear; close all;
addpath(fullfile(pwd, 'functions'));
addpath(fullfile(pwd, 'scripts'));

disp("🚀 Starting HIMA Simulation Pipeline...");

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

disp("✅ HIMA simulation finished.");
