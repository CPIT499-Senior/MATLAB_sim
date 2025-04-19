# detect_landmines.py

import os
import json
from ultralytics import YOLO
import cv2

# Load YOLO model
model = YOLO("models/best.pt")

# Directories
image_dir = "data/images"
output_json = "data/detected_landmines.json"
scan_region_path = "data/scan_region.json"

# Load GPS boundaries
with open(scan_region_path, 'r') as f:
    scan_region = json.load(f)

top_left = scan_region["topLeft"]      # [lat, lon]
bottom_right = scan_region["bottomRight"]  # [lat, lon]

# Convert lat/lon to UTM
import utm
topLeftX, topLeftY, zone, _ = utm.from_latlon(*top_left)
bottomRightX, bottomRightY, _, _ = utm.from_latlon(*bottom_right)

utmWidth = abs(bottomRightX - topLeftX)
utmHeight = abs(bottomRightY - topLeftY)

# Run detection
results = []
for fname in os.listdir(image_dir):
    if not fname.lower().endswith(".jpg"):
        continue

    path = os.path.join(image_dir, fname)
    img = cv2.imread(path)
    h, w = img.shape[:2]

    detections = model(path)[0].boxes.xywh.cpu().numpy()  # [x_center, y_center, w, h]

    for (cx, cy, _, _) in detections:
        # Normalize
        relX = cx / w
        relY = cy / h

        utm_x = topLeftX + relX * utmWidth
        utm_y = topLeftY + relY * utmHeight

        lat, lon = utm.to_latlon(utm_x, utm_y, zone, northern=True)
        results.append({
            "lat": lat,
            "lon": lon
        })

# Save to JSON
with open(output_json, "w") as f:
    json.dump(results, f, indent=2)

print(f"✅ Saved {len(results)} detected landmines to {output_json}")
